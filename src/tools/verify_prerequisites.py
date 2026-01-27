"""Prerequisites verification tool for SQL transformation system.

Validates environment setup before running transformations:
- Database file existence and size
- Source data file availability
- PostGIS/VPN connectivity
- Python environment and dependencies

Usage:
    uv run python -m src.tools.verify_prerequisites
    uv run python -m src.tools.verify_prerequisites --skip-vpn
    uv run python -m src.tools.verify_prerequisites --verbose

Note: Uses ASCII-safe symbols for Windows compatibility.
"""

import subprocess
import sys
from pathlib import Path

import click
import duckdb
import yaml
from rich.console import Console

# Use plain ASCII symbols for Windows compatibility
# (avoiding Unicode encoding issues in Git Bash/cmd/PowerShell)
SYMBOL_OK = "[green]OK[/green]"
SYMBOL_ERROR = "[red]FAIL[/red]"
SYMBOL_WARNING = "[yellow]WARN[/yellow]"
SYMBOL_INFO = "[blue]INFO[/blue]"
SYMBOL_SKIP = "[dim]SKIP[/dim]"

console = Console()


def check_database_file(db_path: Path) -> tuple[bool, str]:
    """Check if database file exists and return size.

    Args:
        db_path: Path to DuckDB database file

    Returns:
        Tuple of (success, message)
    """
    if not db_path.exists():
        return False, f"Database not found at {db_path}"

    size_bytes = db_path.stat().st_size
    size_gb = size_bytes / (1024**3)

    return True, f"Found ({size_gb:.2f} GB)"


def create_database(db_path: Path) -> tuple[bool, str]:
    """Create DuckDB database with required extensions.

    Installs and loads:
    - SPATIAL extension (required for geospatial operations)
    - postgres_scanner extension (auto-loads, but we install explicitly)

    Args:
        db_path: Path where database should be created

    Returns:
        Tuple of (success, message)
    """
    try:
        # Ensure parent directory exists
        db_path.parent.mkdir(parents=True, exist_ok=True)

        # Create database (connecting creates the file)
        con = duckdb.connect(str(db_path))

        # Install SPATIAL extension (required for EPSG:27700 transformations)
        con.execute("INSTALL spatial;")
        con.execute("LOAD spatial;")

        # Install postgres_scanner (may auto-load, but explicit install ensures availability)
        # Note: As of DuckDB stable, postgres_scanner auto-loads when used
        # https://duckdb.org/docs/stable/core_extensions/postgres
        con.execute("INSTALL postgres_scanner;")

        con.close()

        size_mb = db_path.stat().st_size / (1024**2)
        return (
            True,
            f"Created successfully ({size_mb:.1f} MB) with SPATIAL and postgres_scanner extensions",
        )

    except Exception as e:
        return False, f"Failed to create database: {e!s}"


def check_source_files(sql_root: Path) -> tuple[bool, list[tuple[str, bool, str]]]:
    """Check existence of all source files defined in Bronze layer schema.

    Args:
        sql_root: Root directory containing SQL files

    Returns:
        Tuple of (all_exist, list of (file_path, exists, message))
    """
    bronze_schema_path = sql_root / "bronze" / "_schema.yaml"

    if not bronze_schema_path.exists():
        return False, [("_schema.yaml", False, "Schema file not found")]

    with bronze_schema_path.open() as f:
        schema = yaml.safe_load(f)

    results: list[tuple[str, bool, str]] = []
    all_exist = True

    for module_name, config in schema.items():
        source_files = config.get("source_files", [])

        for file_path_str in source_files:
            # Handle relative paths from project root
            file_path = Path(file_path_str)

            if not file_path.is_absolute():
                # Paths in schema are relative to project root (where pyproject.toml is)
                # sql_root is typically src/transformations/sql
                # So we need to go up 3 levels: sql -> transformations -> src -> project_root
                project_root = sql_root.parent.parent.parent
                file_path = project_root / file_path_str

            if file_path.exists():
                size_mb = file_path.stat().st_size / (1024**2)
                results.append((file_path_str, True, f"OK ({size_mb:.1f} MB)"))
            else:
                results.append((file_path_str, False, "NOT FOUND"))
                all_exist = False

    return all_exist, results


def check_postgis_connection(db_path: Path) -> tuple[bool, str]:
    """Test PostGIS connection via DuckDB ATTACH.

    Args:
        db_path: Path to DuckDB database file

    Returns:
        Tuple of (success, message)
    """
    try:
        # Use subprocess to test the connection
        # This approach allows us to capture stderr for IO errors
        cmd = [
            "duckdb",
            str(db_path),
            "-c",
            "ATTACH '' AS weca_postgres (TYPE POSTGRES, SECRET weca_postgres);",
        ]

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=10,
        )

        if result.returncode == 0:
            return True, "Connected successfully"

        # Check for specific error types
        error_output = result.stderr.lower()

        if "io error" in error_output or "connection" in error_output:
            return False, "VPN not connected or PostGIS unreachable"
        if "secret" in error_output:
            return False, "Secret 'weca_postgres' not configured"

        return False, f"Connection failed: {result.stderr[:100]}"

    except subprocess.TimeoutExpired:
        return False, "Connection timeout (VPN likely not connected)"
    except FileNotFoundError:
        return False, "duckdb CLI not found in PATH"
    except Exception as e:
        return False, f"Unexpected error: {e!s}"


def check_python_environment() -> tuple[bool, dict[str, str]]:
    """Check Python version and key dependencies.

    Returns:
        Tuple of (success, dict of component versions)
    """
    versions = {}
    success = True

    # Python version
    python_version = (
        f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    )
    versions["Python"] = python_version

    if sys.version_info < (3, 12):
        success = False

    # DuckDB version
    try:
        versions["DuckDB"] = duckdb.__version__
        # Check minimum version 1.4.0
        major, minor = map(int, duckdb.__version__.split(".")[:2])
        if major < 1 or (major == 1 and minor < 4):
            success = False
    except Exception as e:
        versions["DuckDB"] = f"Error: {e}"
        success = False

    # Rich version
    try:
        from importlib.metadata import version

        versions["Rich"] = version("rich")
    except Exception as e:
        versions["Rich"] = f"Error: {e}"

    # Click version
    try:
        from importlib.metadata import version as get_version

        versions["Click"] = get_version("click")
    except Exception as e:
        versions["Click"] = f"Error: {e}"

    return success, versions


@click.command()
@click.option(
    "--skip-vpn",
    is_flag=True,
    help="Skip PostGIS/VPN connection test",
)
@click.option(
    "--db-path",
    "-d",
    type=click.Path(path_type=Path),
    default=Path("data_lake/mca_env_base.duckdb"),
    help="Path to DuckDB database file",
)
@click.option(
    "--sql-root",
    "-s",
    type=click.Path(path_type=Path),
    default=Path("src/transformations/sql"),
    help="Root directory containing SQL files",
)
@click.option(
    "--verbose",
    "-v",
    is_flag=True,
    help="Show detailed output",
)
@click.option(
    "--create-if-missing",
    is_flag=True,
    help="Automatically create database if it doesn't exist (no prompt)",
)
def main(
    skip_vpn: bool,
    db_path: Path,
    sql_root: Path,
    verbose: bool,
    create_if_missing: bool,
) -> None:
    """Verify prerequisites for SQL transformation system.

    Checks:
    - Database file existence (offers to create if missing)
    - Source data files availability
    - PostGIS/VPN connectivity (optional)
    - Python environment and dependencies

    If database doesn't exist, you will be prompted to create it with
    required extensions (SPATIAL, postgres_scanner).
    """
    console.print("\n[bold]SQL Transformation Prerequisites Check[/bold]\n")

    all_checks_passed = True

    # 1. Check database file
    console.print("[bold cyan]1. Database File[/bold cyan]")
    db_success, db_message = check_database_file(db_path)

    if db_success:
        console.print(f"  {SYMBOL_OK} {db_path}: {db_message}")
    else:
        console.print(f"  {SYMBOL_ERROR} {db_message}")

        # Offer to create database if missing
        should_create = False

        if create_if_missing:
            # Auto-create without prompt
            should_create = True
            console.print(
                f"  {SYMBOL_INFO} Creating database automatically (--create-if-missing flag)"
            )
        else:
            # Interactive prompt
            console.print()
            user_response = click.prompt(
                "  Would you like to create the database now? (yes/no)",
                type=str,
                default="yes",
            ).lower()
            should_create = user_response in ["yes", "y"]

        if should_create:
            console.print(
                f"  {SYMBOL_INFO} Creating database with SPATIAL and postgres_scanner extensions..."
            )
            create_success, create_message = create_database(db_path)

            if create_success:
                console.print(f"  {SYMBOL_OK} {create_message}")
                db_success = True  # Mark as successful now
            else:
                console.print(f"  {SYMBOL_ERROR} {create_message}")
                all_checks_passed = False
        else:
            console.print(f"  {SYMBOL_INFO} Skipping database creation")
            all_checks_passed = False

    console.print()

    # 2. Check Python environment
    console.print("[bold cyan]2. Python Environment[/bold cyan]")
    env_success, versions = check_python_environment()

    for component, version in versions.items():
        status = SYMBOL_OK if "Error" not in version else SYMBOL_ERROR
        console.print(f"  {status} {component}: {version}")

    if not env_success:
        console.print(f"  {SYMBOL_WARNING} Python < 3.12 or DuckDB < 1.4.0")
        all_checks_passed = False

    console.print()

    # 3. Check source files
    console.print("[bold cyan]3. Source Data Files[/bold cyan]")
    files_success, file_results = check_source_files(sql_root)

    if not file_results:
        console.print(f"  {SYMBOL_INFO} No source files defined in Bronze schema")
    else:
        for file_path, exists, message in file_results:
            if verbose or not exists:
                status = SYMBOL_OK if exists else SYMBOL_ERROR
                console.print(f"  {status} {file_path}: {message}")

        summary_found = sum(1 for _, exists, _ in file_results if exists)
        summary_total = len(file_results)
        console.print(f"\n  Found {summary_found}/{summary_total} files")

    if not files_success:
        all_checks_passed = False

    console.print()

    # 4. Check PostGIS/VPN connection
    if not skip_vpn:
        console.print("[bold cyan]4. PostGIS Connection (VPN)[/bold cyan]")
        vpn_success, vpn_message = check_postgis_connection(db_path)

        if vpn_success:
            console.print(f"  {SYMBOL_OK} {vpn_message}")
        else:
            console.print(f"  {SYMBOL_WARNING} {vpn_message}")
            console.print(
                "  [dim]Note: VPN required for boundaries_federated module[/dim]"
            )
            # Don't fail overall check for VPN - it's optional
    else:
        console.print("[bold cyan]4. PostGIS Connection (VPN)[/bold cyan]")
        console.print(f"  {SYMBOL_SKIP} Skipped (--skip-vpn flag used)")

    console.print()

    # Summary
    console.rule("[bold]Summary")

    if all_checks_passed:
        console.print(
            f"\n{SYMBOL_OK} [bold green]All prerequisites satisfied![/bold green]"
        )
        console.print("\nReady to run:")
        console.print(
            "  [cyan]uv run python -m src.transformations all --dry-run[/cyan]"
        )
        sys.exit(0)
    else:
        console.print(
            f"\n{SYMBOL_ERROR} [bold red]Some prerequisites failed[/bold red]"
        )
        console.print("\nFix the issues above before running transformations.")
        console.print("\nSee [cyan]docs/VERIFICATION_PLAN.md[/cyan] for details.")
        sys.exit(1)


if __name__ == "__main__":
    main()
