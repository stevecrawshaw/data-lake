# EPC API Incremental Update - Implementation Plan

## Overview

Implement Python script to automatically update EPC certificate tables via API with incremental date-filtered queries. This **complements** the existing bulk download workflow by providing regular automated updates with only new records, avoiding the need to re-download the entire dataset.

## User Requirements Summary

- **Goal:** Update `raw_domestic_epc_certificates_tbl` and `raw_non_domestic_epc_certificates_tbl` with new records from EPC API
- **Scope:** All UK local authorities (nationwide)
- **Strategy:** Incremental updates (query records after latest LODGEMENT_DATE in tables)
- **Data Source:** API endpoints (NOT bulk downloads)
- **Update Method:** UPSERT by UPRN (overwrite existing, insert new)
- **Pagination:** Automatic with search-after cursor
- **File Strategy:** Single staging CSV per certificate type

## Implementation Steps

### 1. Create New Directory Structure

**Location:** `src/extractors/` (new directory for API data extraction scripts)

**Files to create:**
- `src/extractors/__init__.py` (empty module file)
- `src/extractors/epc_incremental_update.py` (main CLI entry point)
- `src/extractors/epc_api_client.py` (reusable API client class)
- `src/extractors/epc_models.py` (Pydantic config & validation models)

### 2. Implementation: `epc_models.py`

Create Pydantic configuration model for:
- Database paths and table names
- API endpoints and credentials (from .env)
- Pagination settings (page_size=5000)
- Schema JSON file paths
- Staging directory paths

**Key classes:**
```python
class EPCConfig(BaseModel):
    db_path: Path = Path("data_lake/mca_env_base.duckdb")
    username: str  # From .env EPC_USERNAME
    password: str  # From .env EPC_PASSWORD
    base_url: str = "https://epc.opendatacommunities.org"
    page_size: int = 5000
    ...

    @classmethod
    def from_env(cls) -> "EPCConfig":
        """Load credentials from .env file"""
```

### 3. Implementation: `epc_api_client.py`

Create reusable API client class with:

**Core methods:**
- `__init__(config: EPCConfig)` - Setup httpx client with Basic Auth headers
- `fetch_certificates(certificate_type: str, from_date: date, to_date: date) -> list[dict]`
- `_paginate_requests(endpoint: str, params: dict) -> list[dict]` - Handle search-after cursor
- `_parse_csv_response(response: httpx.Response) -> list[dict]` - Parse CSV to list of dicts

**Key implementation details:**
- Use httpx.Client with retry logic (3 retries on 5xx errors)
- Set timeout: 30s connect, 60s read
- Accept header: "text/csv" for CSV responses
- Extract `X-Next-Search-After` header for pagination
- Rich progress bar showing records downloaded
- Build API params: `from-month`, `from-year`, `to-month`, `to-year` from date objects

**Date parameter conversion:**
```python
params = {
    "from-month": from_date.month,
    "from-year": from_date.year,
    "to-month": to_date.month,
    "to-year": to_date.year,
    "size": config.page_size,
}
```

### 4. Implementation: `epc_incremental_update.py`

Main orchestration script with Click CLI.

**CLI commands:**
```bash
uv run python -m src.extractors.epc_incremental_update domestic
uv run python -m src.extractors.epc_incremental_update non-domestic
uv run python -m src.extractors.epc_incremental_update all
```

**CLI options:**
- `--dry-run` - Preview actions without database modifications
- `--from-date YYYY-MM-DD` - Override start date (default: day after max LODGEMENT_DATE)
- `--batch-size N` - Records per API request (default 5000, max 5000)
- `-v/--verbose` - Increase logging verbosity

**Core workflow functions:**

#### 4.1. `get_max_lodgement_date(db_path: Path, table_name: str) -> date | None`
- Connect to DuckDB read-only
- Query: `SELECT MAX(LODGEMENT_DATE) FROM {table_name}`
- Return None if table empty (triggers full load from 2008)

#### 4.2. `normalize_column_names(records: list[dict], schema_path: Path) -> list[dict]`
- Load schema JSON file
- Create lowercase → UPPERCASE mapping
- Transform all record keys
- **Critical:** Apply manual override for `ENVIRONMENTAL_IMPACT_CURRENT` → `ENVIRONMENT_IMPACT_CURRENT`

#### 4.3. `deduplicate_records(con: duckdb.DuckDBPyConnection, records: list[dict], temp_table: str) -> None`
- Use DuckDB's native relational API (no Polars needed)
- Create temp table from records list
- SQL deduplication: `SELECT * FROM temp_table QUALIFY ROW_NUMBER() OVER (PARTITION BY UPRN ORDER BY LODGEMENT_DATETIME DESC) = 1`
- Returns deduplicated relation

#### 4.4. `write_staging_csv(con: duckdb.DuckDBPyConnection, relation: duckdb.DuckDBPyRelation, output_path: Path) -> None`
- Use DuckDB's native `.write_csv()` method on relation
- Automatically handles type casting based on inferred schema
- Write to `data_lake/landing/automated/epc_{type}_incremental_{date}.csv`
- Example: `relation.write_csv(str(output_path))`

#### 4.5. `upsert_to_database(db_path: Path, staging_csv: Path, table_name: str, schema: dict) -> tuple[int, int]`
**UPSERT strategy using DuckDB's MERGE INTO statement:**
```sql
-- Create temp staging table from CSV
CREATE TEMP TABLE temp_staging AS
FROM read_csv('{staging_csv}', columns = {schema});

-- MERGE INTO for elegant upsert (insert new + update existing)
MERGE INTO {table_name} AS target
USING temp_staging AS source
ON target.UPRN = source.UPRN
WHEN MATCHED THEN
    UPDATE SET *  -- Update all columns with source data
WHEN NOT MATCHED THEN
    INSERT *;     -- Insert new records

-- Get counts
SELECT
    SUM(CASE WHEN merge_action = 'UPDATE' THEN 1 ELSE 0 END) AS updated,
    SUM(CASE WHEN merge_action = 'INSERT' THEN 1 ELSE 0 END) AS inserted
FROM (
    -- Re-run with RETURNING to get action counts
    -- Or query from staging vs existing
);

-- Cleanup
DROP TABLE temp_staging;
```
- Return tuple: (updated_count, inserted_count)
- Log operation details with breakdown

#### 4.6. `update_certificate_type(certificate_type: str, config: EPCConfig, dry_run: bool, from_date_override: date | None) -> None`
**Main orchestration flow:**
1. Get max lodgement date from database table
2. Calculate from_date = max_date + 1 day (or 2008-01-01 if empty)
3. Calculate to_date = today
4. Fetch records from API using client.fetch_certificates()
5. Normalize column names (lowercase → UPPERCASE)
6. Use DuckDB relational API to process:
   - Create relation from records
   - Filter: `.filter('UPRN IS NOT NULL')`
   - Deduplicate: SQL with `QUALIFY ROW_NUMBER() OVER (PARTITION BY UPRN ORDER BY LODGEMENT_DATETIME DESC) = 1`
7. Write staging CSV using `.write_csv()`
8. If dry_run: Log preview and skip database update
9. Else: UPSERT to database with MERGE INTO
10. Log summary: X records fetched, Y inserted, Z updated, new max date

### 5. Error Handling & Validation

**API errors:**
- 401 Unauthorized → Raise ValueError("Invalid EPC API credentials")
- 429 Rate Limit → Wait 60s and retry once
- 5xx Server Errors → Retry 3 times with exponential backoff
- Timeout → Log error and raise

**Data validation:**
- Filter records with missing/null UPRN
- Log count of skipped invalid records
- Validate date formats (LODGEMENT_DATE as DATE, LODGEMENT_DATETIME as string)

**Database errors:**
- Check database file exists before connecting
- Catch duckdb.IOException and raise RuntimeError with clear message
- Use read_only=True for query operations

### 6. Logging & Progress Tracking

**Setup Rich logging:**
```python
from rich.logging import RichHandler
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[RichHandler(rich_tracebacks=True)],
)
logger = logging.getLogger("epc_updater")
```

**Rich progress bar for API fetching:**
- Show spinner during requests
- Display record count incrementing
- Show time elapsed/remaining

**Log key events:**
- Start: "Updating {type} certificates from {from_date} to {to_date}"
- API: "Fetched {count} records from API in {time}s"
- Staging: "Wrote {count} records to {csv_path}"
- Upsert: "MERGE completed: {inserted} inserted, {updated} updated"
- Complete: "New max LODGEMENT_DATE: {max_date}"

**Git Bash note:** Add fallback to simple print() statements if Rich initialization fails in Git Bash environment

### 7. Testing Strategy

**Create:** `tests/test_epc_incremental_update.py`

**Test cases:**
1. `test_get_max_lodgement_date()` - Query max date from test database
2. `test_normalize_column_names()` - Verify lowercase → UPPERCASE mapping
3. `test_environment_impact_override()` - Verify ENVIRONMENTAL → ENVIRONMENT fix
4. `test_deduplicate_records()` - Keep latest per UPRN
5. `test_upsert_updates_existing()` - Verify UPSERT overwrites by UPRN
6. `test_upsert_inserts_new()` - Verify UPSERT adds new UPRNs
7. `test_dry_run_mode()` - Verify dry-run doesn't modify database
8. `test_fetch_with_pagination()` - Mock API responses with search-after

**Use pytest fixtures:**
- `test_db` - Temporary DuckDB with sample data
- `httpx_mock` - Mock API responses (pytest-httpx)

### 8. Configuration & Credentials

**Environment variables (.env):**
- `EPC_USERNAME` - API username (email)
- `EPC_PASSWORD` - API key/password
- `EPC_BASE_URL` - API base URL (default: https://epc.opendatacommunities.org)

**Schema JSON files (existing):**
- `src/schemas/epc_domestic_certificates_schema.json`
- `src/schemas/epc_non-domestic_certificates_schema.json`

**Note:** Domestic schema has known issue: `ENVIRONMENTAL_IMPACT_CURRENT` should be `ENVIRONMENT_IMPACT_CURRENT` - apply manual override in code.

### 9. Dependencies

**All dependencies already in pyproject.toml:**
- `duckdb>=1.4.0` - Database operations & relational API (replaces need for Polars)
- `httpx>=0.27.0` - HTTP client with retries
- `pydantic>=2.12.5` - Config validation
- `click>=8.3.1` - CLI framework
- `rich>=14.2.0` - Progress bars & logging (see Git Bash compatibility note below)
- `dotenv>=0.9.9` - Environment variables

**No new dependencies required.**

**Git Bash Compatibility Note:**
- Rich has [known color output issues](https://github.com/Textualize/rich/issues/988) with Git Bash on Windows
- **Workarounds:**
  1. Use `winpty python -m src.extractors.epc_incremental_update` (recommended for Git Bash)
  2. Use Windows Terminal or WSL instead of Git Bash
  3. Fallback to simple logging if Rich fails to detect proper terminal

### 10. File Structure Summary

```
src/
├── extractors/                               # NEW DIRECTORY
│   ├── __init__.py                          # NEW - Empty module file
│   ├── epc_incremental_update.py            # NEW - Main CLI entry point (~300 LOC)
│   ├── epc_api_client.py                    # NEW - API client class (~200 LOC)
│   └── epc_models.py                        # NEW - Pydantic models (~100 LOC)
├── schemas/
│   ├── epc_domestic_certificates_schema.json         # EXISTING - Reference for columns
│   └── epc_non-domestic_certificates_schema.json    # EXISTING - Reference for columns
└── manual_external_load.sql                  # EXISTING - Reference for deduplication pattern

data_lake/
├── landing/
│   └── automated/                            # Staging CSV output location
│       ├── epc_domestic_incremental_YYYY-MM-DD.csv   # NEW - Generated by script
│       └── epc_non_domestic_incremental_YYYY-MM-DD.csv  # NEW - Generated by script
└── mca_env_base.duckdb                       # EXISTING - Target database

tests/
└── test_epc_incremental_update.py            # NEW - Test suite (~200 LOC)

.env                                          # EXISTING - Contains EPC_USERNAME, EPC_PASSWORD
```

## Critical Implementation Points

### Column Name Mapping Issue
**Problem:** API returns lowercase keys (e.g., `lmk_key`), database expects UPPERCASE (e.g., `LMK_KEY`)

**Solution:**
```python
# Load schema JSON
schema_keys = load_schema(schema_path).keys()  # ['LMK_KEY', 'UPRN', ...]

# Create lowercase → UPPERCASE mapping
column_map = {k.lower(): k for k in schema_keys}

# Transform each record
normalized = {column_map.get(k.lower(), k.upper()): v for k, v in record.items()}

# CRITICAL: Manual override for known issue
if 'ENVIRONMENTAL_IMPACT_CURRENT' in normalized:
    normalized['ENVIRONMENT_IMPACT_CURRENT'] = normalized.pop('ENVIRONMENTAL_IMPACT_CURRENT')
```

### Date Range Calculation
```python
# Get latest date from database
max_date = get_max_lodgement_date(db_path, table_name)

# Calculate incremental start date
if max_date:
    from_date = max_date + timedelta(days=1)  # Day after latest
else:
    from_date = date(2008, 1, 1)  # API default start year

# End date is today
to_date = date.today()
```

### Pagination Loop
```python
all_records = []
search_after = None

while True:
    # Build params with cursor
    params = build_params(from_date, to_date, size=5000)
    if search_after:
        params["search-after"] = search_after

    # Fetch page
    response = client.get(endpoint, params=params)
    records = parse_csv_response(response)
    all_records.extend(records)

    # Check for next page
    search_after = response.headers.get("X-Next-Search-After")
    if not search_after:
        break  # Last page
```

### UPSERT Transaction
```python
# Use DuckDB transaction for atomicity
with duckdb.connect(str(db_path)) as con:
    # Load staging
    con.execute(f"CREATE TEMP TABLE temp_staging AS FROM read_csv('{staging_csv}', columns={schema})")

    # Delete conflicts
    deleted = con.execute(f"DELETE FROM {table_name} WHERE UPRN IN (SELECT DISTINCT UPRN FROM temp_staging)").fetchone()[0]

    # Insert all
    con.execute(f"INSERT INTO {table_name} SELECT * FROM temp_staging")
    inserted = con.execute("SELECT COUNT(*) FROM temp_staging").fetchone()[0]

    # Cleanup
    con.execute("DROP TABLE temp_staging")

    return inserted
```

## Key Design Decisions

1. **CSV vs JSON response:** CSV chosen for direct DuckDB compatibility and lower memory usage
2. **MERGE INTO vs DELETE+INSERT:** MERGE INTO chosen for elegant single-statement upsert without modifying table constraints
3. **DuckDB Relational API vs Polars:** DuckDB's native relational API chosen to avoid external DataFrame dependencies
4. **Single staging file:** Matches current manual load pattern, simpler cleanup
5. **Column mapping at runtime:** Flexible to schema changes, explicit override capability
6. **Complementary to bulk downloads:** This script supplements (not replaces) the existing bulk download workflow for incremental updates

## Example Usage

```bash
# Update domestic certificates with verbose logging
uv run python -m src.extractors.epc_incremental_update domestic -vv

# For Git Bash on Windows, use winpty:
winpty uv run python -m src.extractors.epc_incremental_update domestic -vv

# Dry-run to preview without database changes
uv run python -m src.extractors.epc_incremental_update non-domestic --dry-run

# Override start date for backfill
uv run python -m src.extractors.epc_incremental_update domestic --from-date 2025-11-01

# Update both types sequentially
uv run python -m src.extractors.epc_incremental_update all
```

## Expected Output

```
Updating domestic certificates from 2025-12-01 to 2026-01-02
Fetching certificates... ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100% 3,247 records
Normalized 3,247 records (lowercase → UPPERCASE)
Processing with DuckDB relational API:
  - Filtered 12 invalid records (missing UPRN)
  - Deduplicated to 3,235 unique UPRNs
Wrote staging CSV: data_lake/landing/automated/epc_domestic_incremental_2026-01-02.csv
MERGE INTO raw_domestic_epc_certificates_tbl:
  - Updated existing: 127
  - Inserted new: 3,108
New max LODGEMENT_DATE: 2025-12-15
Completed in 47.3s
```

**Note:** If colors don't appear in Git Bash, use `winpty` prefix or switch to Windows Terminal.

## Success Criteria

- [x] Script retrieves only records newer than latest LODGEMENT_DATE in tables
- [x] Uses API endpoints with date filtering (NOT bulk downloads)
- [x] Handles pagination automatically with search-after cursor
- [x] Normalizes column names from API (lowercase) to database (UPPERCASE)
- [x] Uses MERGE INTO for elegant upsert (insert new + update existing by UPRN)
- [x] Uses DuckDB's native relational API (no Polars dependency)
- [x] Supports dry-run mode for testing
- [x] Follows Python 3.13+ standards with type hints
- [x] Uses existing dependencies (no new packages)
- [x] Includes comprehensive test suite
- [x] Rich logging with Git Bash compatibility notes
- [x] Complements (not replaces) existing bulk download workflow

## Next Steps After Implementation

1. Run initial test with `--dry-run` to verify logic
2. Test with small date range (e.g., last week)
3. Verify MERGE INTO correctly updates existing records
4. Run full incremental update for both certificate types
5. Schedule for automated daily/weekly runs (via cron or Task Scheduler)

---

## Key Revisions from User Feedback

**Changes made to original plan based on user requirements:**

1. ✅ **Clarified purpose**: Script **complements** (not replaces) bulk downloads for regular incremental updates
2. ✅ **DuckDB Relational API**: Replaced Polars with DuckDB's native relational API (`con.from_df()`, `.filter()`, `.write_csv()`)
3. ✅ **MERGE INTO**: Replaced DELETE+INSERT with elegant MERGE INTO statement for upserts
4. ✅ **Git Bash compatibility**: Added notes about Rich library color issues in Git Bash with `winpty` workaround
5. ✅ **Deduplication**: Using DuckDB's `QUALIFY ROW_NUMBER()` clause instead of external DataFrame libraries

**Technical documentation consulted:**
- [DuckDB Relational API](https://github.com/context7/duckdb_stable/blob/main/guides/python/relational_api_pandas.md)
- [MERGE INTO statement](https://github.com/context7/duckdb_stable/blob/main/sql/statements/merge_into.md)
- [Rich Git Bash issues](https://github.com/Textualize/rich/issues/988)

**Benefits of revisions:**
- Fewer dependencies (no Polars needed)
- More elegant UPSERT with single SQL statement
- Better alignment with DuckDB-native operations
- Clear Git Bash usage guidance
