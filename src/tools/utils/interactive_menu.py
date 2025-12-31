"""Interactive UI components for schema comment editing.

This module provides Rich CLI components for navigating tables/views,
selecting columns, and editing field descriptions using questionary.
"""

import logging
from pathlib import Path
from typing import Literal

import questionary
from pydantic import BaseModel
from rich.console import Console
from rich.panel import Panel

from ..parsers.models import ColumnMetadata
from .session_manager import SessionManager

logger = logging.getLogger(__name__)


class FieldReviewAction(BaseModel):
    """Action result from field review UI.

    Attributes:
        action: User's chosen action
        new_description: New description if action='edit', None otherwise
    """

    action: Literal["edit", "keep", "skip", "save_quit", "quit_no_save", "back"]
    new_description: str | None = None


class InteractiveMenu:
    """Rich terminal UI for interactive schema editing."""

    def __init__(self, console: Console | None = None):
        """Initialize menu with Rich console.

        Args:
            console: Rich Console instance (creates new one if None)
        """
        self.console = console or Console()

    def display_welcome_banner(
        self, database_path: Path, stats: dict[str, int]
    ) -> None:
        """Show welcome screen with session info.

        Args:
            database_path: Path to database being reviewed
            stats: Progress statistics dict
        """
        is_resumed = stats.get("reviewed", 0) > 0 or stats.get("skipped", 0) > 0

        banner_text = "[bold blue]Schema Comment Editor"
        if is_resumed:
            banner_text += " - Resumed Session"
        else:
            banner_text += " - New Session"
        banner_text += "[/bold blue]"

        info_lines = [
            f"[cyan]Database:[/cyan] {database_path}",
            f"[cyan]Fields to review:[/cyan] {stats.get('total', 0)}",
        ]

        if is_resumed:
            reviewed = stats.get("reviewed", 0) + stats.get("confirmed", 0)
            skipped = stats.get("skipped", 0)
            info_lines.append(
                f"[green]Progress:[/green] {reviewed} reviewed, {skipped} skipped"
            )

        panel = Panel(
            "\n".join(info_lines),
            title=banner_text,
            border_style="blue",
        )

        self.console.print()
        self.console.print(panel)
        self.console.print()

    def display_progress_panel(self, stats: dict[str, int]) -> None:
        """Display progress panel using Rich Panel.

        Args:
            stats: Progress statistics dict
        """
        total = stats.get("total", 0)
        reviewed = stats.get("reviewed", 0) + stats.get("confirmed", 0)
        skipped = stats.get("skipped", 0)
        pending = stats.get("pending", 0)

        percent = 0 if total == 0 else int(reviewed / total * 100)

        progress_text = [
            f"[green]✓ Reviewed:[/green] {reviewed}/{total} ({percent}%)",
            f"[yellow]⊘ Skipped:[/yellow] {skipped}",
            f"[white]⊙ Pending:[/white] {pending}",
        ]

        panel = Panel(
            "\n".join(progress_text),
            title="[bold]Progress[/bold]",
            border_style="green",
        )

        self.console.print()
        self.console.print(panel)

    def select_entity(self, entities: list[tuple[str, str, int, int]]) -> str | None:
        """Show entity selection menu (tables/views).

        Args:
            entities: List of tuples (entity_name, entity_type, total_cols, pending_cols)

        Returns:
            Selected entity name or None if cancelled
        """
        if not entities:
            self.console.print("[yellow]No entities to review[/yellow]")
            return None

        # Format choices with progress indicators (plain text for questionary)
        choices = []
        for entity_name, entity_type, total_cols, pending_cols in entities:
            indicator = "✓" if pending_cols == 0 else "⊙"

            label = f"{indicator} {entity_name} ({entity_type}, {pending_cols}/{total_cols} pending)"
            choices.append({"name": label, "value": entity_name})

        # Add option to finish
        choices.append(questionary.Separator())
        choices.append({"name": "✓ Save & Quit", "value": "__SAVE_QUIT__"})
        choices.append({"name": "✗ Quit without saving", "value": "__QUIT_NO_SAVE__"})

        try:
            result = questionary.select(
                "Select entity to review:",
                choices=choices,
                use_shortcuts=True,
                instruction="(Use arrow keys, Enter to select)",
            ).ask()

            return result
        except KeyboardInterrupt:
            return "__SAVE_QUIT__"

    def select_column(
        self,
        entity_name: str,
        display_name: str,
        entity_type: str,
        columns: list[tuple[str, ColumnMetadata]],
        session: SessionManager,
    ) -> tuple[str, ColumnMetadata] | str:
        """Show column selection menu with status indicators.

        Args:
            entity_name: Full entity name for session tracking (with view: prefix if applicable)
            display_name: Display name without prefix for UI display
            entity_type: 'table' or 'view'
            columns: List of tuples (column_name, ColumnMetadata)
            session: SessionManager to check field status

        Returns:
            Tuple of (column_name, ColumnMetadata) or "__BACK__" if back/cancelled
        """
        if not columns:
            self.console.print("[yellow]No columns to review[/yellow]")
            return "__BACK__"

        # Format choices with status indicators (plain text for questionary)
        choices = []
        for col_name, col_meta in columns:
            status_obj = session.get_field_status(entity_name, col_name)

            if status_obj:
                if status_obj.status in ("reviewed", "confirmed"):
                    indicator = "✓"
                elif status_obj.status == "skipped":
                    indicator = "⊘"
                else:  # pending
                    indicator = "⊙"
            else:
                indicator = "⊙"

            label = f"{indicator} {col_name} ({col_meta.data_type}, {col_meta.source})"
            choices.append({"name": label, "value": (col_name, col_meta)})

        # Add navigation options
        choices.append(questionary.Separator())
        choices.append({"name": "← Back to entity list", "value": "__BACK__"})

        try:
            result = questionary.select(
                f"Select column in {entity_type} '{display_name}':",
                choices=choices,
                use_shortcuts=True,
                instruction="(Use arrow keys, Enter to select)",
            ).ask()

            return result
        except KeyboardInterrupt:
            return "__BACK__"

    def review_field(
        self,
        entity_name: str,
        entity_type: str,
        column_name: str,
        metadata: ColumnMetadata,
        existing_description: str,
    ) -> FieldReviewAction:
        """Interactive field review with edit/keep/skip/save/quit options.

        Args:
            entity_name: Table or view name
            entity_type: 'table' or 'view'
            column_name: Column name
            metadata: Column metadata
            existing_description: Current description

        Returns:
            FieldReviewAction with user's choice
        """
        # Display field info panel
        self._display_field_info(
            entity_name, entity_type, column_name, metadata, existing_description
        )

        # Prompt for action
        choices = [
            {"name": "Edit description", "value": "edit"},
            {"name": "Keep current description", "value": "keep"},
            {"name": "Skip for later", "value": "skip"},
            questionary.Separator(),
            {"name": "Save & Quit", "value": "save_quit"},
            {"name": "Quit without saving", "value": "quit_no_save"},
            {"name": "← Back", "value": "back"},
        ]

        try:
            action = questionary.select(
                "What would you like to do?",
                choices=choices,
                use_shortcuts=True,
            ).ask()

            if action == "edit":
                # Prompt for new description
                new_desc = questionary.text(
                    "Enter description:",
                    default=existing_description,
                    multiline=False,
                ).ask()

                if new_desc and new_desc.strip():
                    return FieldReviewAction(
                        action="edit", new_description=new_desc.strip()
                    )
                else:
                    self.console.print("[yellow]Empty description, skipping[/yellow]")
                    return FieldReviewAction(action="skip")

            return FieldReviewAction(action=action)

        except KeyboardInterrupt:
            return FieldReviewAction(action="save_quit")

    def _display_field_info(
        self,
        entity_name: str,
        entity_type: str,
        column_name: str,
        metadata: ColumnMetadata,
        existing_description: str,
    ) -> None:
        """Display field information panel.

        Args:
            entity_name: Table or view name
            entity_type: 'table' or 'view'
            column_name: Column name
            metadata: Column metadata
            existing_description: Current description
        """
        info_lines = [
            f"[cyan]Entity:[/cyan] {entity_name} ({entity_type})",
            f"[cyan]Column:[/cyan] {column_name}",
            f"[cyan]Type:[/cyan] {metadata.data_type}",
            f"[cyan]Source:[/cyan] {metadata.source} (confidence: {metadata.confidence:.2f})",
            "",
            "[yellow]Current Description:[/yellow]",
            f'[white]"{existing_description}"[/white]',
        ]

        panel = Panel(
            "\n".join(info_lines),
            title=f"[bold]Field Review: {column_name}[/bold]",
            border_style="cyan",
        )

        self.console.print()
        self.console.print(panel)
        self.console.print()

    def confirm_save_and_quit(self, reviewed_count: int) -> bool:
        """Confirm save and quit action.

        Args:
            reviewed_count: Number of fields reviewed so far

        Returns:
            True if user confirms, False otherwise
        """
        if reviewed_count == 0:
            return questionary.confirm(
                "No fields have been reviewed. Quit without saving?",
                default=False,
            ).ask()

        return questionary.confirm(
            f"Save progress ({reviewed_count} fields reviewed) and quit?",
            default=True,
        ).ask()

    def show_completion_summary(
        self, stats: dict[str, int], xml_path: Path | None = None
    ) -> None:
        """Display completion summary with statistics.

        Args:
            stats: Progress statistics dict
            xml_path: Path to generated XML file (if any)
        """
        total = stats.get("total", 0)
        reviewed = stats.get("reviewed", 0) + stats.get("confirmed", 0)
        skipped = stats.get("skipped", 0)

        summary_lines = [
            "[bold green]Session Complete![/bold green]",
            "",
            f"[green]✓ Reviewed:[/green] {reviewed}/{total} fields",
            f"[yellow]⊘ Skipped:[/yellow] {skipped} fields",
        ]

        if xml_path and xml_path.exists():
            summary_lines.append("")
            summary_lines.append(f"[cyan]XML output:[/cyan] {xml_path}")

        panel = Panel(
            "\n".join(summary_lines),
            title="[bold]Summary[/bold]",
            border_style="green",
        )

        self.console.print()
        self.console.print(panel)
        self.console.print()

    def show_error(self, message: str) -> None:
        """Display error message.

        Args:
            message: Error message to display
        """
        self.console.print(f"[red]Error:[/red] {message}")

    def show_info(self, message: str) -> None:
        """Display info message.

        Args:
            message: Info message to display
        """
        self.console.print(f"[cyan]ℹ[/cyan] {message}")

    def show_success(self, message: str) -> None:
        """Display success message.

        Args:
            message: Success message to display
        """
        self.console.print(f"[green]✓[/green] {message}")
