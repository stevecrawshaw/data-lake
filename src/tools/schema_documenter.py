"""Schema documentation CLI tool for DuckDB databases.

This tool generates SQL COMMENT statements for tables and columns by:
1. Parsing XML schema files for canonical metadata
2. Inferring descriptions from column names and data patterns
3. Mapping table comments to views automatically
"""

import logging
import sys
from pathlib import Path

# Fix Windows console encoding for Unicode characters
if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(
        sys.stdout.buffer, encoding="utf-8", errors="replace"
    )
    sys.stderr = io.TextIOWrapper(
        sys.stderr.buffer, encoding="utf-8", errors="replace"
    )

import click
import yaml
from rich.console import Console
from rich.logging import RichHandler
from rich.progress import Progress, SpinnerColumn, TextColumn

from .generators.comment_generator import CommentGenerator, save_comments_to_file
from .generators.view_mapper import ViewMapper
from .parsers.models import TableMetadata, ViewMetadata
from .parsers.schema_analyzer import SchemaAnalyzer
from .parsers.xml_parser import parse_xml_schema

# Initialize console for rich output
console = Console()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[RichHandler(console=console, rich_tracebacks=True)],
)
logger = logging.getLogger(__name__)


def merge_table_metadata(base: TableMetadata, override: TableMetadata) -> TableMetadata:
    """Merge table metadata with manual override priority.

    Args:
        base: Base table metadata (from external XML or inference)
        override: Override table metadata (from manual_overrides.xml)

    Returns:
        Merged TableMetadata with override taking precedence
    """
    # Create column lookups (case-insensitive)
    override_cols = {c.name.upper(): c for c in override.columns}
    base_cols = {c.name.upper(): c for c in base.columns}

    # Merge columns: override takes precedence
    merged_columns = []
    for col_name_upper, col in base_cols.items():
        if col_name_upper in override_cols:
            # Use override column
            merged_columns.append(override_cols[col_name_upper])
        else:
            # Keep base column
            merged_columns.append(col)

    # Add any new columns from override not in base
    for col_name_upper, col in override_cols.items():
        if col_name_upper not in base_cols:
            merged_columns.append(col)

    # Return merged metadata with override description and source
    return TableMetadata(
        name=base.name,
        description=override.description,
        columns=merged_columns,
        schema_name=base.schema_name,
        table_type=base.table_type,
        source="manual_override",
    )


@click.group()
@click.option(
    "--verbose",
    "-v",
    is_flag=True,
    help="Enable verbose logging (DEBUG level)",
)
@click.pass_context
def cli(ctx: click.Context, verbose: bool) -> None:
    """Schema documentation tool for DuckDB databases.

    Generate COMMENT statements for database tables and columns using:
    - XML schema files (canonical metadata)
    - Pattern matching (column name conventions)
    - Data analysis (statistical inference)
    - View-to-table mapping (automatic propagation)
    """
    ctx.ensure_object(dict)
    if verbose:
        logging.getLogger().setLevel(logging.DEBUG)
        logger.debug("Verbose logging enabled")


@cli.command()
@click.option(
    "--database",
    "-d",
    type=click.Path(exists=True, path_type=Path),
    required=True,
    help="Path to DuckDB database file",
)
@click.option(
    "--xml-schema",
    "-x",
    multiple=True,
    type=click.Path(exists=True, path_type=Path),
    help="XML schema file(s) with canonical metadata (can be specified multiple times)",
)
@click.option(
    "--config",
    "-c",
    type=click.Path(exists=True, path_type=Path),
    default="src/tools/config/settings.yaml",
    help="Configuration file path",
)
@click.option(
    "--output",
    "-o",
    type=click.Path(path_type=Path),
    help="Output SQL file path (overrides config)",
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Generate SQL without executing (output to console/file only)",
)
@click.option(
    "--tables",
    "-t",
    multiple=True,
    help="Filter specific tables (can be specified multiple times)",
)
@click.option(
    "--include-views/--no-views",
    default=True,
    help="Include views in documentation generation",
)
def generate(
    database: Path,
    xml_schema: tuple[Path, ...],
    config: Path,
    output: Path | None,
    dry_run: bool,
    tables: tuple[str, ...],
    include_views: bool,
) -> None:
    """Generate COMMENT statements for database schema.

    This command analyzes the database structure and generates SQL COMMENT
    statements based on XML schemas, pattern matching, and data analysis.

    Example:
        schema-doc generate -d data_lake/mca_env_base.duckdb \\
                           -x src/schemas/documentation/epc_domestic_schema.xml \\
                           --dry-run
    """
    console.print("[bold blue]Schema Documentation Generator[/bold blue]\n")
    logger.info(f"Database: {database}")
    logger.info(f"XML schemas: {len(xml_schema)}")
    logger.info(f"Dry run: {dry_run}")

    try:
        # Load configuration
        pattern_rules_path = Path("src/tools/config/pattern_rules.yaml")
        if not pattern_rules_path.exists():
            console.print("[red]Error: pattern_rules.yaml not found[/red]")
            sys.exit(1)

        all_tables: list[TableMetadata] = []

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            # Parse XML schemas if provided
            if xml_schema:
                task = progress.add_task("Parsing XML schemas...", total=len(xml_schema))
                for xml_path in xml_schema:
                    logger.info(f"Parsing XML: {xml_path}")
                    xml_tables = parse_xml_schema(xml_path)
                    all_tables.extend(xml_tables)
                    progress.advance(task)

            # Load manual overrides if present
            manual_overrides_path = Path("src/schemas/documentation/manual_overrides.xml")
            if manual_overrides_path.exists():
                logger.info("Loading manual schema overrides...")
                manual_tables = parse_xml_schema(manual_overrides_path)

                # Merge with priority: manual > external XML
                for manual_table in manual_tables:
                    existing_idx = next(
                        (i for i, t in enumerate(all_tables)
                         if t.name.upper() == manual_table.name.upper()),
                        None
                    )
                    if existing_idx is not None:
                        # Replace with manual override (has higher priority)
                        all_tables[existing_idx] = merge_table_metadata(
                            all_tables[existing_idx], manual_table
                        )
                    else:
                        # Add new table from manual overrides
                        all_tables.append(manual_table)

                console.print(f"[cyan]✓[/cyan] Loaded {len(manual_tables)} table(s) from manual overrides")

            # Analyze database schema for tables not in XML
            task = progress.add_task("Analyzing database schema...", total=None)
            analyzer = SchemaAnalyzer(
                database_path=database,
                pattern_rules_path=pattern_rules_path,
                enable_data_analysis=True,
            )

            xml_table_names = {t.name.upper() for t in all_tables}
            table_filter_list = list(tables) if tables else None

            inferred_tables = analyzer.analyze_database(
                table_filter=table_filter_list,
                min_confidence=0.5,
            )

            # Merge: prefer XML tables, add inferred for missing ones
            for inferred_table in inferred_tables:
                if inferred_table.name.upper() not in xml_table_names:
                    all_tables.append(inferred_table)

            progress.update(task, completed=True)

            # Map views if requested
            views: list[ViewMetadata] = []
            if include_views:
                task = progress.add_task("Mapping views...", total=None)
                mapper = ViewMapper(database_path=database)
                views = mapper.map_views(all_tables)
                progress.update(task, completed=True)

        # Generate SQL
        console.print(f"\n[green]✓[/green] Processed {len(all_tables)} tables")
        if views:
            console.print(f"[green]✓[/green] Processed {len(views)} views")

        # Determine output path
        if not output:
            output = Path("src/schemas/documentation/generated_comments.sql")

        # Generate comments
        generator = CommentGenerator(
            database_path=database if not dry_run else None,
            format="pretty",
        )

        if dry_run:
            # Save to file
            save_comments_to_file(
                output_path=output,
                tables=all_tables,
                views=views if views else None,
                format="pretty",
            )
            console.print(f"\n[green]✓[/green] Generated comments saved to: {output}")
            console.print("[yellow]Dry run: Comments not applied to database[/yellow]")
        else:
            # Apply to database
            console.print("\n[yellow]Applying comments to database...[/yellow]")
            stats = generator.apply_comments(
                tables=all_tables,
                views=views if views else None,
                force=False,
            )

            # Also save to file
            save_comments_to_file(
                output_path=output,
                tables=all_tables,
                views=views if views else None,
                format="pretty",
            )

            console.print(f"\n[green]✓[/green] Applied comments to database")
            console.print(f"  Tables updated: {stats['tables_updated']}")
            console.print(f"  Columns updated: {stats['columns_updated']}")
            console.print(f"  SQL saved to: {output}")

    except Exception as e:
        console.print(f"[red]Error: {e}[/red]")
        logger.exception("Generation failed")
        sys.exit(1)


@cli.command()
@click.option(
    "--database",
    "-d",
    type=click.Path(exists=True, path_type=Path),
    required=True,
    help="Path to DuckDB database file",
)
@click.option(
    "--input",
    "-i",
    type=click.Path(exists=True, path_type=Path),
    required=True,
    help="SQL file with COMMENT statements to apply",
)
@click.option(
    "--force",
    is_flag=True,
    help="Overwrite existing comments",
)
def apply(
    database: Path,
    input: Path,  # noqa: A002
    force: bool,
) -> None:
    """Apply COMMENT statements to database.

    Executes a SQL file containing COMMENT ON statements against the
    specified database.

    Example:
        schema-doc apply -d data_lake/mca_env_base.duckdb \\
                        -i src/schemas/documentation/generated_comments.sql
    """
    console.print("[bold blue]Applying Comments to Database[/bold blue]\n")
    logger.info(f"Database: {database}")
    logger.info(f"SQL file: {input}")

    try:
        import duckdb

        # Read SQL file
        sql_content = input.read_text(encoding="utf-8")

        # Apply to database
        with duckdb.connect(str(database)) as con:
            # Execute the SQL (which contains COMMENT ON statements)
            con.execute(sql_content)

        console.print(f"[green]✓[/green] Successfully applied comments from {input}")

    except Exception as e:
        console.print(f"[red]Error applying comments: {e}[/red]")
        logger.exception("Apply failed")
        sys.exit(1)


@cli.command()
@click.option(
    "--database",
    "-d",
    type=click.Path(exists=True, path_type=Path),
    required=True,
    help="Path to DuckDB database file",
)
@click.option(
    "--report",
    "-r",
    type=click.Path(path_type=Path),
    help="Output coverage report to file",
)
@click.option(
    "--min-coverage",
    type=float,
    default=0.8,
    help="Minimum acceptable coverage (0.0-1.0)",
)
def validate(
    database: Path,
    report: Path | None,
    min_coverage: float,
) -> None:
    """Validate comment coverage in database.

    Checks what percentage of tables and columns have comments and
    generates a coverage report.

    Example:
        schema-doc validate -d data_lake/mca_env_base.duckdb \\
                           --report coverage_report.txt \\
                           --min-coverage 0.9
    """
    logger.info(f"Validating comment coverage for: {database}")
    logger.info(f"Minimum coverage threshold: {min_coverage * 100}%")

    # TODO: Implement validation logic
    console.print("[yellow]⚠️  Validation not yet implemented[/yellow]")
    sys.exit(1)


@cli.command()
@click.option(
    "--database",
    "-d",
    type=click.Path(exists=True, path_type=Path),
    required=True,
    help="Path to DuckDB database file",
)
@click.option(
    "--output",
    "-o",
    type=click.Path(path_type=Path),
    required=True,
    help="Output file path (SQL format)",
)
@click.option(
    "--format",
    type=click.Choice(["pretty", "compact"]),
    default="pretty",
    help="SQL output format",
)
def export(
    database: Path,
    output: Path,
    format: str,  # noqa: A002
) -> None:
    """Export existing comments from database as SQL.

    Extracts all existing COMMENT ON statements from the database and
    saves them to a SQL file.

    Example:
        schema-doc export -d data_lake/mca_env_base.duckdb \\
                         -o backup_comments.sql \\
                         --format pretty
    """
    logger.info(f"Exporting comments from: {database}")
    logger.info(f"Output file: {output}")
    logger.info(f"Format: {format}")

    # TODO: Implement export logic
    console.print("[yellow]⚠️  Export not yet implemented[/yellow]")
    sys.exit(1)


@cli.command()
@click.option(
    "--database",
    "-d",
    type=click.Path(exists=True, path_type=Path),
    required=True,
    help="Path to DuckDB database file",
)
@click.option(
    "--resume",
    is_flag=True,
    help="Resume previous editing session",
)
@click.option(
    "--clear-session",
    is_flag=True,
    help="Clear existing session and start fresh",
)
def edit_comments(
    database: Path,
    resume: bool,
    clear_session: bool,
) -> None:
    """Launch interactive comment editor.

    Interactively review and edit comments for tables without XML schemas
    and views with fallback/computed columns. Progress is saved automatically
    and can be resumed later.

    Example:
        schema-doc edit-comments -d data_lake/mca_env_base.duckdb

        # Resume previous session
        schema-doc edit-comments -d data_lake/mca_env_base.duckdb --resume

        # Clear session and start over
        schema-doc edit-comments -d data_lake/mca_env_base.duckdb --clear-session
    """
    from .comment_editor import CommentEditor

    console.print("[bold blue]Interactive Schema Comment Editor[/bold blue]\n")

    try:
        editor = CommentEditor(database_path=database)

        if clear_session:
            editor.clear_session()

        editor.run(resume=resume)

    except Exception as e:
        console.print(f"[red]Error: {e}[/red]")
        logger.exception("Edit session failed")
        sys.exit(1)


if __name__ == "__main__":
    cli()
