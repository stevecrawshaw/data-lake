"""EPC API Incremental Update - Main CLI script.

This script incrementally updates EPC certificate tables via API with date-filtered queries.
"""

import json
import logging
from datetime import date, timedelta
from pathlib import Path

import click
import duckdb
import pyarrow as pa
from rich.console import Console
from rich.logging import RichHandler

from .epc_api_client import EPCAPIClient
from .epc_models import CertificateType, EPCConfig

# Setup logging with Rich
console = Console()
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[RichHandler(console=console, rich_tracebacks=True)],
)
logger = logging.getLogger(__name__)


def get_max_lodgement_date(db_path: Path, table_name: str) -> date | None:
    """Query max LODGEMENT_DATE from target table for incremental updates.

    Args:
        db_path: Path to DuckDB database
        table_name: Name of table to query

    Returns:
        Maximum lodgement date, or None if table is empty

    Raises:
        FileNotFoundError: If database file doesn't exist
        RuntimeError: If database connection fails
    """
    if not db_path.exists():
        msg = f"Database not found: {db_path}"
        raise FileNotFoundError(msg)

    try:
        with duckdb.connect(str(db_path), read_only=True) as con:
            result = con.execute(
                f"SELECT MAX(LODGEMENT_DATE) FROM {table_name}"
            ).fetchone()

            if result and result[0]:
                logger.info(f"Max LODGEMENT_DATE in {table_name}: {result[0]}")
                return result[0]
            else:
                logger.info(f"No records found in {table_name}, will start from 2008")
                return None

    except duckdb.CatalogException:
        logger.warning(f"Table {table_name} not found, will start from 2008")
        return None
    except duckdb.IOException as e:
        msg = f"Cannot connect to database: {e}"
        raise RuntimeError(msg) from e


def normalize_column_names(
    records: list[dict[str, str]], schema_path: Path
) -> list[dict[str, str]]:
    """Normalize column names from API (lowercase) to database (UPPERCASE).

    Args:
        records: List of records with API column names
        schema_path: Path to schema JSON file

    Returns:
        List of records with normalized column names

    Raises:
        FileNotFoundError: If schema file doesn't exist
    """
    if not schema_path.exists():
        msg = f"Schema file not found: {schema_path}"
        raise FileNotFoundError(msg)

    # Load schema
    with schema_path.open() as f:
        schema = json.load(f)

    # Create lowercase -> UPPERCASE mapping (replace hyphens with underscores)
    column_map = {k.lower().replace("-", "_"): k for k in schema.keys()}

    # Transform records (replace hyphens with underscores in API column names)
    normalized = []
    for record in records:
        normalized_record = {
            column_map.get(k.lower().replace("-", "_"), k.upper().replace("-", "_")): v
            for k, v in record.items()
        }

        # CRITICAL: Manual override for known schema issue
        if "ENVIRONMENTAL_IMPACT_CURRENT" in normalized_record:
            normalized_record["ENVIRONMENT_IMPACT_CURRENT"] = normalized_record.pop(
                "ENVIRONMENTAL_IMPACT_CURRENT"
            )
        if "ENVIRONMENTAL_IMPACT_POTENTIAL" in normalized_record:
            normalized_record["ENVIRONMENT_IMPACT_POTENTIAL"] = normalized_record.pop(
                "ENVIRONMENTAL_IMPACT_POTENTIAL"
            )

        normalized.append(normalized_record)

    logger.info(f"Normalized {len(normalized)} records (lowercase -> UPPERCASE)")
    return normalized


def write_staging_csv(
    records: list[dict[str, str]],
    output_path: Path,
    certificate_type: str,
) -> None:
    """Write records to staging CSV using DuckDB and PyArrow.

    Converts list of dictionaries to PyArrow Table for efficient processing,
    then uses DuckDB for filtering, deduplication, and CSV writing.

    Args:
        records: List of normalized records
        output_path: Path to write CSV file
        certificate_type: Type of certificate for logging
    """
    # Ensure staging directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Use DuckDB to write CSV from records
    con = duckdb.connect()

    # Create relation from records using PyArrow for efficiency
    arrow_table = pa.Table.from_pylist(records)
    rel = con.from_arrow(arrow_table)

    # Debug: log column names
    logger.debug(f"Columns in relation: {arrow_table.column_names}")

    # Filter out records with null UPRN
    initial_count = con.execute("SELECT COUNT(*) FROM rel").fetchone()[0]
    rel = rel.filter("UPRN IS NOT NULL AND UPRN != ''")
    filtered_count = con.execute("SELECT COUNT(*) FROM rel").fetchone()[0]

    if initial_count > filtered_count:
        logger.warning(
            f"Filtered {initial_count - filtered_count} records with missing UPRN"
        )

    # Deduplicate: keep latest per UPRN
    # Use LODGEMENT_DATE for ordering (API returns this column)
    dedup_query = """
        SELECT * FROM rel
        QUALIFY ROW_NUMBER() OVER (PARTITION BY UPRN ORDER BY LODGEMENT_DATE DESC) = 1
    """
    rel = con.sql(dedup_query)  # type: ignore[assignment]
    final_count = con.execute("SELECT COUNT(*) FROM rel").fetchone()[0]

    if filtered_count > final_count:
        logger.info(
            f"Deduplicated to {final_count} unique UPRNs "
            f"(removed {filtered_count - final_count} duplicates)"
        )

    # Write CSV
    rel.write_csv(str(output_path))
    logger.info(f"Wrote {final_count} records to {output_path}")

    con.close()


def upsert_to_database(
    db_path: Path,
    staging_csv: Path,
    table_name: str,
    schema_path: Path,
) -> tuple[int, int]:
    """UPSERT staging CSV into target table using MERGE INTO.

    Args:
        db_path: Path to DuckDB database
        staging_csv: Path to staging CSV file
        table_name: Name of target table
        schema_path: Path to schema JSON for type definitions

    Returns:
        Tuple of (inserted_count, updated_count)

    Raises:
        RuntimeError: If database operation fails
    """
    # Load schema for type definitions
    with schema_path.open() as f:
        schema = json.load(f)

    try:
        with duckdb.connect(str(db_path)) as con:
            # Create temp staging table
            logger.info("Creating temporary staging table...")
            con.execute(
                f"""
                CREATE TEMP TABLE temp_staging AS
                FROM read_csv('{staging_csv}', columns = {json.dumps(schema)})
            """
            )

            staging_count = con.execute("SELECT COUNT(*) FROM temp_staging").fetchone()[
                0
            ]
            logger.info(f"Loaded {staging_count} records into temp staging table")

            # Execute MERGE INTO
            logger.info(f"Executing MERGE INTO {table_name}...")

            # Count existing UPRNs that will be updated
            updated_count = con.execute(
                f"""
                SELECT COUNT(DISTINCT target.UPRN)
                FROM {table_name} AS target
                INNER JOIN temp_staging AS source ON target.UPRN = source.UPRN
            """
            ).fetchone()[0]

            # MERGE INTO statement
            con.execute(
                f"""
                MERGE INTO {table_name} AS target
                USING temp_staging AS source
                ON target.UPRN = source.UPRN
                WHEN MATCHED THEN
                    UPDATE SET *
                WHEN NOT MATCHED THEN
                    INSERT *
            """
            )

            inserted_count = staging_count - updated_count

            logger.info(
                f"MERGE completed: {inserted_count} inserted, {updated_count} updated"
            )

            # Cleanup
            con.execute("DROP TABLE temp_staging")

            return (inserted_count, updated_count)

    except duckdb.IOException as e:
        msg = f"Database operation failed: {e}"
        raise RuntimeError(msg) from e


def update_certificate_type(
    certificate_type: str,
    config: EPCConfig,
    dry_run: bool,
    from_date_override: date | None,
    verbose: int,
) -> None:
    """Update certificates for a specific type.

    Args:
        certificate_type: Type of certificate to update
        config: EPCConfig instance
        dry_run: If True, preview actions without database modifications
        from_date_override: Override start date (optional)
        verbose: Verbosity level for logging

    Raises:
        ValueError: If invalid certificate type
    """
    # Set logging level based on verbosity
    if verbose >= 2:
        logger.setLevel(logging.DEBUG)
    elif verbose == 1:
        logger.setLevel(logging.INFO)

    # Determine table and schema
    if certificate_type == CertificateType.DOMESTIC:
        table_name = config.domestic_table
        schema_path = config.domestic_schema
    elif certificate_type == CertificateType.NON_DOMESTIC:
        table_name = config.non_domestic_table
        schema_path = config.non_domestic_schema
    else:
        msg = f"Invalid certificate type: {certificate_type}"
        raise ValueError(msg)

    logger.info(f"\n{'=' * 60}")
    logger.info(f"Updating {certificate_type.upper()} certificates")
    logger.info(f"{'=' * 60}\n")

    # Step 1: Get max lodgement date
    if from_date_override:
        from_date = from_date_override
        logger.info(f"Using override start date: {from_date}")
    else:
        max_date = get_max_lodgement_date(config.db_path, table_name)
        if max_date:
            from_date = max_date + timedelta(days=1)
        else:
            from_date = date(2008, 1, 1)

    to_date = date.today()

    if from_date > to_date:
        logger.info("No new records to fetch (from_date > today)")
        return

    logger.info(f"Date range: {from_date} to {to_date}")

    # Step 2: Fetch from API
    with EPCAPIClient(config) as client:
        records = client.fetch_certificates(certificate_type, from_date, to_date)

    if not records:
        logger.info("No records returned from API")
        return

    logger.info(f"Fetched {len(records)} records from API")

    # Step 3: Normalize column names
    normalized_records = normalize_column_names(records, schema_path)

    # Step 4: Write staging CSV
    staging_filename = f"epc_{certificate_type}_incremental_{date.today()}.csv"
    staging_path = config.staging_dir / staging_filename

    write_staging_csv(normalized_records, staging_path, certificate_type)

    # Step 5: UPSERT to database (or preview if dry-run)
    if dry_run:
        logger.info("\n[DRY RUN] Would execute MERGE INTO:")
        logger.info(f"  Target table: {table_name}")
        logger.info(f"  Staging file: {staging_path}")
        logger.info(f"  Records to upsert: {len(normalized_records)}")
        logger.info("\nNo database changes made (dry-run mode)")
    else:
        inserted, updated = upsert_to_database(
            config.db_path, staging_path, table_name, schema_path
        )

        # Get new max date
        new_max_date = get_max_lodgement_date(config.db_path, table_name)
        logger.info(f"\nNew max LODGEMENT_DATE: {new_max_date}")

    logger.info(f"\n{'=' * 60}")
    logger.info(f"Completed {certificate_type.upper()} update")
    logger.info(f"{'=' * 60}\n")


@click.command()
@click.argument(
    "certificate_type",
    type=click.Choice(CertificateType.valid_types()),
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Preview actions without modifying database",
)
@click.option(
    "--from-date",
    type=click.DateTime(formats=["%Y-%m-%d"]),
    help="Override start date (default: day after max LODGEMENT_DATE)",
)
@click.option(
    "--batch-size",
    type=int,
    default=5000,
    help="Records per API request (max 5000)",
)
@click.option(
    "-v",
    "--verbose",
    count=True,
    help="Increase logging verbosity (-v for INFO, -vv for DEBUG)",
)
def main(
    certificate_type: str,
    dry_run: bool,
    from_date: str | None,
    batch_size: int,
    verbose: int,
) -> None:
    """Incrementally update EPC certificate tables from API.

    CERTIFICATE_TYPE: Type of certificates to update (domestic, non-domestic, or all)

    Examples:
        uv run python -m src.extractors.epc_incremental_update domestic -vv
        uv run python -m src.extractors.epc_incremental_update --dry-run
        uv run python -m src.extractors.epc_incremental_update all
    """
    try:
        # Load configuration
        config = EPCConfig.from_env()

        # Override batch size if specified
        if batch_size != 5000:
            config.page_size = min(batch_size, 5000)

        # Parse from_date if provided
        from_date_parsed: date | None = None
        if from_date:
            # Click DateTime returns datetime object, convert to date
            from_date_parsed = (
                from_date.date() if hasattr(from_date, "date") else from_date
            )  # type: ignore[union-attr]

        # Process certificate type(s)
        if certificate_type == CertificateType.ALL:
            update_certificate_type(
                CertificateType.DOMESTIC, config, dry_run, from_date_parsed, verbose
            )
            update_certificate_type(
                CertificateType.NON_DOMESTIC, config, dry_run, from_date_parsed, verbose
            )
        else:
            update_certificate_type(
                certificate_type, config, dry_run, from_date_parsed, verbose
            )

        logger.info("\nAll updates completed successfully")

    except Exception as e:
        logger.error(f"\nError: {e}", exc_info=verbose >= 2)
        raise click.Abort() from e


if __name__ == "__main__":
    main()
