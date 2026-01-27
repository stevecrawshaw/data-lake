"""CLI entry point for SQL transformation orchestration.

Usage:
    uv run python -m src.transformations all
    uv run python -m src.transformations bronze
    uv run python -m src.transformations silver gold
    uv run python -m src.transformations all --dry-run
    uv run python -m src.transformations bronze --validate
    uv run python -m src.transformations all -vv
"""

import logging
import sys
from pathlib import Path

import click
from rich.console import Console

from .models import TransformationConfig
from .orchestrator import TransformationOrchestrator

console = Console()
logger = logging.getLogger(__name__)


@click.command()
@click.argument(
    "layers",
    nargs=-1,
    type=click.Choice(["all", "bronze", "silver", "gold"], case_sensitive=False),
    required=True,
)
@click.option(
    "--db-path",
    "-d",
    type=click.Path(exists=True, path_type=Path),
    help="Path to DuckDB database file",
)
@click.option(
    "--sql-root",
    "-s",
    type=click.Path(exists=True, path_type=Path),
    help="Root directory containing SQL files",
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Preview execution plan without running SQL",
)
@click.option(
    "--validate",
    is_flag=True,
    help="Validate source files exist before execution (Bronze layer only)",
)
@click.option(
    "--verbose",
    "-v",
    count=True,
    help="Increase verbosity (-v for DEBUG, -vv for detailed DEBUG)",
)
def main(
    layers: tuple[str, ...],
    db_path: Path | None,
    sql_root: Path | None,
    dry_run: bool,
    validate: bool,
    verbose: int,
) -> None:
    """Execute SQL transformations for Medallion Architecture layers.

    LAYERS can be 'all' or any combination of 'bronze', 'silver', 'gold'.

    Examples:
        uv run python -m src.transformations all
        uv run python -m src.transformations bronze silver
        uv run python -m src.transformations all --dry-run
        uv run python -m src.transformations bronze --validate
    """
    # Configure logging level based on verbosity
    if verbose >= 2:
        logging.getLogger().setLevel(logging.DEBUG)
        logging.getLogger("src.transformations").setLevel(logging.DEBUG)
    elif verbose == 1:
        logging.getLogger("src.transformations").setLevel(logging.DEBUG)

    # Build configuration
    config_kwargs = {}
    if db_path:
        config_kwargs["db_path"] = db_path
    if sql_root:
        config_kwargs["sql_root"] = sql_root

    try:
        config = TransformationConfig(**config_kwargs)
    except Exception as e:
        console.print(f"[red]Configuration error: {e}[/red]")
        sys.exit(1)

    # Validate database exists
    if not config.db_path.exists():
        console.print(f"[red]Database not found: {config.db_path}[/red]")
        console.print("\nPlease specify a valid database path with --db-path")
        sys.exit(1)

    # Create orchestrator
    orchestrator = TransformationOrchestrator(config)

    try:
        # Discover modules
        modules = orchestrator.discover_modules()

        if not modules:
            console.print("[yellow]No SQL modules found[/yellow]")
            console.print(f"\nChecked directory: {config.sql_root}")
            console.print("\nTo get started, create SQL files in:")
            console.print(f"  - {config.sql_root}/bronze/")
            console.print(f"  - {config.sql_root}/silver/")
            console.print(f"  - {config.sql_root}/gold/")
            sys.exit(0)

        # Execute requested layers
        if "all" in layers:
            console.print(
                "[bold]Executing all layers (Bronze > Silver > Gold)[/bold]\n"
            )
            orchestrator.execute_all(dry_run=dry_run, validate=validate)
        else:
            # Execute each specified layer
            for layer in layers:
                console.rule(f"[bold blue]{layer.upper()} Layer")
                orchestrator.execute_layer(layer, dry_run=dry_run, validate=validate)

        # Success message
        if dry_run:
            console.print("[green]SUCCESS: Dry-run completed successfully[/green]")
        else:
            console.print(
                "[green]SUCCESS: All transformations completed successfully[/green]"
            )

    except Exception as e:
        console.print(f"\n[red]Error: {e}[/red]")
        if verbose:
            console.print_exception()
        sys.exit(1)


if __name__ == "__main__":
    main()
