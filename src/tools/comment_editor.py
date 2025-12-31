"""Interactive schema comment editor.

This module provides the main orchestration for interactively reviewing and
editing schema comments for tables and views that lack external documentation.
"""

import logging
import re
import sys
from pathlib import Path

from rich.console import Console

from .generators.view_mapper import ViewMapper
from .generators.xml_generator import ManualOverrideXMLGenerator
from .parsers.models import ColumnMetadata, TableMetadata, ViewMetadata
from .parsers.schema_analyzer import SchemaAnalyzer
from .utils.interactive_menu import InteractiveMenu
from .utils.session_manager import SessionManager

logger = logging.getLogger(__name__)


class CommentEditor:
    """Main orchestrator for interactive schema comment editing."""

    def __init__(
        self,
        database_path: Path,
        session_file: Path = Path(".schema_review_session.json"),
        xml_output: Path = Path("src/schemas/documentation/manual_overrides.xml"),
    ):
        """Initialize comment editor.

        Args:
            database_path: Path to DuckDB database
            session_file: Path to session state file
            xml_output: Path to output XML file
        """
        self.database_path = database_path
        self.session_file = session_file
        self.xml_output = xml_output

        self.session_manager = SessionManager(session_file)
        self.console = Console()
        self.menu = InteractiveMenu(self.console)

        # Loaded data (populated by load methods)
        self.tables: dict[str, TableMetadata] = {}
        self.views: dict[str, ViewMetadata] = {}
        self.existing_comments: dict[
            str, dict[str, str]
        ] = {}  # entity -> column -> desc

    def run(self, resume: bool = False) -> None:
        """Run the interactive comment editor.

        Args:
            resume: Whether to resume previous session
        """
        try:
            # Load or create session
            if resume or self.session_file.exists():
                self.session_manager.load_or_create(self.database_path)
            else:
                self.session_manager.load_or_create(self.database_path)

            # Load schema metadata
            self.console.print("[cyan]Loading database schema...[/cyan]")
            self.load_schema_metadata()

            # Parse existing comments
            self.console.print("[cyan]Parsing existing comments...[/cyan]")
            self.parse_generated_comments()

            # Filter fields for review
            self.console.print("[cyan]Identifying fields for review...[/cyan]")
            fields_to_review = self.filter_fields_for_review()

            if not fields_to_review:
                self.console.print(
                    "[yellow]No fields found for review. "
                    "All tables have XML schemas or views are fully mapped.[/yellow]"
                )
                return

            # Initialize session fields
            self._initialize_session_fields(fields_to_review)

            # Display welcome banner
            stats = self.session_manager.get_progress_stats()
            self.menu.display_welcome_banner(self.database_path, stats)

            # Start interactive session
            self.start_interactive_session()

            # Save and generate XML
            self.save_xml_output()

        except KeyboardInterrupt:
            self.console.print("\n[yellow]Interrupted. Saving session...[/yellow]")
            self.session_manager.save()
            self.console.print(
                "[green]Session saved. Resume with --resume flag.[/green]"
            )
            sys.exit(0)

        except Exception as e:
            logger.exception("Error during comment editing")
            self.console.print(f"[red]Error: {e}[/red]")

            # Try to save session
            try:
                self.session_manager.save()
                self.console.print("[green]Session saved.[/green]")
            except:
                self.console.print("[red]Could not save session![/red]")

            sys.exit(1)

    def load_schema_metadata(self) -> None:
        """Load database schema metadata (tables and views)."""
        # Use SchemaAnalyzer to get database structure
        pattern_rules_path = Path("src/tools/config/pattern_rules.yaml")
        analyzer = SchemaAnalyzer(
            database_path=self.database_path,
            pattern_rules_path=pattern_rules_path,
            enable_data_analysis=True,
        )

        # Get all tables (inferred)
        inferred_tables = analyzer.analyze_database(min_confidence=0.5)

        # Store tables by name
        for table in inferred_tables:
            self.tables[table.name] = table

        # Get views
        mapper = ViewMapper(database_path=self.database_path)
        views = mapper.map_views(inferred_tables)

        # Store views by name
        for view in views:
            self.views[view.name] = view

        logger.info(f"Loaded {len(self.tables)} tables and {len(self.views)} views")

    def parse_generated_comments(self) -> None:
        """Parse generated_comments.sql to extract existing descriptions."""
        comments_file = Path("src/schemas/documentation/generated_comments.sql")

        if not comments_file.exists():
            logger.warning(f"No existing comments file found at {comments_file}")
            return

        content = comments_file.read_text(encoding="utf-8")

        # Pattern for COMMENT ON COLUMN statements
        # Example: COMMENT ON COLUMN mca_env_base.table_name.column_name IS 'description';
        column_pattern = re.compile(
            r"COMMENT\s+ON\s+COLUMN\s+[\w.]+\.(\w+)\.(\w+)\s+IS\s+'([^']*(?:''[^']*)*)';",
            re.IGNORECASE,
        )

        matches = column_pattern.findall(content)

        for table_name, column_name, description in matches:
            # Unescape single quotes ('' -> ')
            description = description.replace("''", "'")

            if table_name not in self.existing_comments:
                self.existing_comments[table_name] = {}

            self.existing_comments[table_name][column_name] = description

        logger.info(f"Parsed comments for {len(self.existing_comments)} entities")

    def filter_fields_for_review(self) -> dict[str, list[ColumnMetadata]]:
        """Filter fields that need manual review.

        Returns:
            Dict mapping entity_name (or "view:entity_name") to list of columns
        """
        fields_to_review = {}

        # Tables: Include ALL columns where table.source != "xml"
        for table_name, table in self.tables.items():
            if table.source != "xml":
                # Include all columns
                if table.columns:
                    fields_to_review[table_name] = table.columns
                    logger.debug(
                        f"Table {table_name}: {len(table.columns)} columns to review"
                    )

        # Views: Include columns where source in ("fallback", "computed")
        for view_name, view in self.views.items():
            review_cols = [
                col for col in view.columns if col.source in ("fallback", "computed")
            ]

            if review_cols:
                # Prefix with "view:" to distinguish from tables
                fields_to_review[f"view:{view_name}"] = review_cols
                logger.debug(f"View {view_name}: {len(review_cols)} columns to review")

        total_fields = sum(len(cols) for cols in fields_to_review.values())
        logger.info(f"Total fields to review: {total_fields}")

        return fields_to_review

    def _initialize_session_fields(
        self, fields_to_review: dict[str, list[ColumnMetadata]]
    ) -> None:
        """Initialize session fields for all fields to review.

        Args:
            fields_to_review: Dict mapping entity_name to list of columns
        """
        for entity_name, columns in fields_to_review.items():
            for col in columns:
                # Get existing comment from generated_comments.sql
                # Remove "view:" prefix if present
                lookup_name = (
                    entity_name.replace("view:", "")
                    if entity_name.startswith("view:")
                    else entity_name
                )
                existing_desc = self.existing_comments.get(lookup_name, {}).get(
                    col.name, col.description
                )

                # Initialize in session if not already present
                self.session_manager.initialize_field(
                    entity_name=entity_name,
                    column_name=col.name,
                    original_description=existing_desc,
                    data_type=col.data_type,
                    confidence=col.confidence,
                    source=col.source,
                )

        self.session_manager.save()

    def start_interactive_session(self) -> None:
        """Launch interactive review session."""
        while True:
            # Show progress
            stats = self.session_manager.get_progress_stats()
            self.menu.display_progress_panel(stats)

            # Build entity list with progress
            entities = self._build_entity_list()

            if not entities:
                self.console.print("[green]All fields reviewed![/green]")
                break

            # Select entity
            selected_entity = self.menu.select_entity(entities)

            if selected_entity == "__SAVE_QUIT__":
                break
            elif selected_entity == "__QUIT_NO_SAVE__":
                if self.menu.confirm_save_and_quit(stats.get("reviewed", 0)):
                    sys.exit(0)
                else:
                    continue
            elif not selected_entity:
                continue

            # Review entity columns
            self._review_entity(selected_entity)

    def _build_entity_list(self) -> list[tuple[str, str, int, int]]:
        """Build list of entities with progress information.

        Returns:
            List of tuples (entity_name, entity_type, total_cols, pending_cols)
        """
        entities = []

        if not self.session_manager.state:
            return entities

        for entity_name, columns in self.session_manager.state.fields.items():
            entity_type = "view" if entity_name.startswith("view:") else "table"
            total_cols = len(columns)
            pending_cols = sum(1 for col in columns.values() if col.status == "pending")

            entities.append((entity_name, entity_type, total_cols, pending_cols))

        # Sort: pending first, then by name
        entities.sort(key=lambda x: (x[3] == 0, x[0]))

        return entities

    def _review_entity(self, entity_name: str) -> None:
        """Review columns in an entity.

        Args:
            entity_name: Table or view name (may have "view:" prefix)
        """
        entity_type = "view" if entity_name.startswith("view:") else "table"
        display_name = entity_name.replace("view:", "")

        # Get metadata
        if entity_type == "table":
            entity_meta = self.tables.get(display_name)
        else:
            entity_meta = self.views.get(display_name)

        if not entity_meta:
            self.menu.show_error(f"Entity not found: {display_name}")
            return

        # Build column list from session
        if not self.session_manager.state:
            return

        session_columns = self.session_manager.state.fields.get(entity_name, {})

        # Match with metadata
        columns_to_review = []
        for col_name, _field_status in session_columns.items():
            col_meta = entity_meta.get_column(col_name)
            if col_meta:
                columns_to_review.append((col_name, col_meta))

        while True:
            # Select column (use full entity_name for session tracking)
            selected = self.menu.select_column(
                entity_name,
                display_name,
                entity_type,
                columns_to_review,
                self.session_manager,
            )

            if selected == "__BACK__":
                # Back to entity list
                break

            # Defensive unpacking with validation
            if not isinstance(selected, tuple) or len(selected) != 2:
                self.menu.show_error(f"Invalid selection format: {type(selected)}")
                continue

            col_name, col_meta = selected

            # Get existing description
            existing_desc = self.existing_comments.get(display_name, {}).get(
                col_name, col_meta.description
            )

            # Review field
            action = self.menu.review_field(
                display_name, entity_type, col_name, col_meta, existing_desc
            )

            if action.action == "edit":
                self.session_manager.mark_reviewed(
                    entity_name, col_name, action.new_description
                )
                self.menu.show_success(f"Updated: {col_name}")

            elif action.action == "keep":
                self.session_manager.mark_confirmed(entity_name, col_name)
                self.menu.show_success(f"Confirmed: {col_name}")

            elif action.action == "skip":
                self.session_manager.mark_skipped(entity_name, col_name)
                self.menu.show_info(f"Skipped: {col_name}")

            elif action.action == "save_quit":
                return  # Exit column review and entity review

            elif action.action == "quit_no_save":
                sys.exit(0)

            elif action.action == "back":
                continue  # Back to column selection

    def save_xml_output(self) -> None:
        """Generate manual_overrides.xml from reviewed fields."""
        stats = self.session_manager.get_progress_stats()
        reviewed_count = stats.get("reviewed", 0) + stats.get("confirmed", 0)

        if reviewed_count == 0:
            self.console.print("[yellow]No fields reviewed. No XML generated.[/yellow]")
            return

        self.console.print("\n[cyan]Generating XML output...[/cyan]")

        try:
            generator = ManualOverrideXMLGenerator(output_path=self.xml_output)
            generator.generate_from_session(
                self.session_manager.state,
                self.tables,
                self.views,
            )

            self.menu.show_completion_summary(stats, self.xml_output)

        except Exception as e:
            logger.exception("Error generating XML")
            self.menu.show_error(f"Failed to generate XML: {e}")

    def clear_session(self) -> None:
        """Clear session file."""
        self.session_manager.clear_session()
        self.console.print("[green]Session cleared.[/green]")
