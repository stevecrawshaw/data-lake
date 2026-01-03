# Local Gov Environmental Analytics: Local Lakehouse

A standalone analytical stack for UK Local Government environmental data. This project utilizes a **"Local Lakehouse"** architecture powered by **DuckDB**.

## 🏗 Architecture

This project follows the **Medallion Architecture** (Bronze $\rightarrow$ Silver $\rightarrow$ Gold) adapted for a local filesystem context.

* **Landing Zone (Filesystem):** Raw storage for CSVs, Zips, and Parquet files.
* **Bronze Layer (Raw Views):** DuckDB views reading directly from the Landing Zone or connecting via Federation to PostGIS.
* **Silver Layer (Standardized):** Data cleaning, deduplication, and **Spatial Reprojection** (Standardizing to EPSG:27700).
* **Gold Layer (Analytical):** Aggregated metrics ready for BI or GIS reporting (e.g., "Flood Risk by Ward").

## 📂 Project Structure

```text
.
├── data_lake/                   # LOCAL ONLY (Added to .gitignore)
│   ├── landing/
│   │   ├── automated/           # Output from Python scripts (APIs)
│   │   └── manual/              # Drop zone for Humaniverse/ONS files
│   └── mca_env_base.duckdb         # Main database file
├── src/
│   ├── extractors/              # Python scripts for APIs & Scrapers
│   └── utility/                 # Helper scripts (unzipping, logging)
├── dbt_project/                 # SQL Transformations
│   ├── models/
│   ├── seeds/
│   └── profiles.yml
├── notebooks/                   # Jupyter notebooks for EDA
└── README.md
```

## Data Ingestion Strategy

We utilize three distinct strategies depending on the data source:

1. Federated PostGIS (Corporate Data)
    Source: Corporate PostGIS (Boundaries, Assets).

    Strategy: We attach the PostGIS instance directly to DuckDB using the postgres_scanner extension. Data are ingested with the src/boundaries_staging.sql script.

2. Automated Pipelines (APIs & Bulk Zips)
    Source: EPC Open Data, REST APIs with pagination.

    Strategy: Python scripts run monthly. To be implemented

3. Manual "Drop Zone" (bulk EPC)

### Strategy: Manual Download + Globbing

Protocol:

Download the file manually.

Drop into data_lake/landing/manual

Ingest with src/manual_external_load.sql

## 🔄 EPC Incremental Update Process

The project includes an automated EPC certificate update system that incrementally fetches new certificates from the EPC API and upserts them into the database using DuckDB's efficient `MERGE INTO` statement.

### How It Works

The incremental update process:

1. **Queries Database**: Finds the latest `LODGEMENT_DATE` in the target table
2. **Fetches from API**: Retrieves all certificates lodged since that date using cursor-based pagination
3. **Normalizes Columns**: Transforms API column names (lowercase with hyphens) to database format (UPPERCASE with underscores)
4. **Deduplicates**: Keeps only the latest certificate per UPRN (by `LODGEMENT_DATE`)
5. **Stages CSV**: Writes filtered records to `data_lake/staging/`
6. **Upserts to Database**: Uses `MERGE INTO` to atomically insert new records and update existing ones

**Key Features:**
- **Efficient CSV Processing**: Uses DuckDB's `read_csv()` + `UNION ALL BY NAME` for optimal performance
- **Automatic Pagination**: Handles API cursor-based pagination transparently
- **Deduplication**: Ensures one record per UPRN using SQL window functions
- **Atomic Updates**: Single transaction per batch using `MERGE INTO`
- **Progress Tracking**: Rich progress bars (when terminal supports it)

### Prerequisites

Environment variables in `.env` (or system environment):

```bash
EPC_USERNAME=your_api_username
EPC_PASSWORD=your_api_password
```

**Note:** Request credentials from [EPC Open Data Portal](https://epc.opendatacommunities.org/)

### Usage

#### Basic Update - Domestic Certificates

Fetch all new domestic EPC certificates since last update:

```bash
uv run python -m src.extractors.epc_incremental_update domestic
```

#### Update Non-Domestic Certificates

```bash
uv run python -m src.extractors.epc_incremental_update non-domestic
```

#### Update Both Certificate Types

```bash
uv run python -m src.extractors.epc_incremental_update all
```

#### Dry Run (Preview Only)

See what would be fetched without modifying the database:

```bash
uv run python -m src.extractors.epc_incremental_update domestic --dry-run
```

#### Override Start Date

Fetch certificates from a specific date (ignores database max date):

```bash
uv run python -m src.extractors.epc_incremental_update domestic --from-date 2024-01-01
```

#### Verbose Logging

Show detailed progress (`-v` for INFO, `-vv` for DEBUG):

```bash
# INFO level logging
uv run python -m src.extractors.epc_incremental_update domestic -v

# DEBUG level logging (shows API requests, SQL queries)
uv run python -m src.extractors.epc_incremental_update domestic -vv
```

#### Custom Batch Size

Adjust records per API request (max 5000):

```bash
uv run python -m src.extractors.epc_incremental_update domestic --batch-size 1000
```

### Common Workflows

#### Daily Automated Update

Recommended for production use:

```bash
# Updates both domestic and non-domestic
uv run python -m src.extractors.epc_incremental_update all -v
```

#### First-Time Setup

After initial bulk load from manual CSV:

```bash
# Dry run to check date range
uv run python -m src.extractors.epc_incremental_update domestic --dry-run -vv

# Execute update
uv run python -m src.extractors.epc_incremental_update domestic -v
```

#### Backfill Missing Date Range

If updates were paused and you need to catch up:

```bash
# Fetch from specific date
uv run python -m src.extractors.epc_incremental_update domestic --from-date 2025-01-01 -v
```

#### Debugging API Issues

Verbose logging for troubleshooting:

```bash
uv run python -m src.extractors.epc_incremental_update domestic -vv --dry-run
```

### Output

**Console Output Example:**

```
============================================================
Updating DOMESTIC certificates
============================================================

Date range: 2025-01-02 to 2025-01-03
Fetching certificates...
Page 1: Fetched ~4523 records (total: ~4523)
No more pages. Total records: ~4523
Combined 4523 records from 1 pages
Normalized 4523 records (lowercase -> UPPERCASE)
Deduplicated to 4501 unique UPRNs (removed 22 duplicates)
Wrote 4501 records to data_lake/staging/epc_domestic_incremental_2025-01-03.csv

Creating temporary staging table...
Loaded 4501 records into temp staging table
Executing MERGE INTO raw_domestic_epc_certificates_tbl...
MERGE completed: 4489 inserted, 12 updated

New max LODGEMENT_DATE: 2025-01-03
```

**Files Generated:**

- `data_lake/staging/epc_domestic_incremental_YYYY-MM-DD.csv` - Staging CSV (preserved for audit)
- Database table updated via `MERGE INTO` statement

### Configuration

Default settings in `src/extractors/epc_models.py`:

| Setting | Default | Description |
|---------|---------|-------------|
| `base_url` | `https://epc.opendatacommunities.org` | EPC API endpoint |
| `page_size` | `5000` | Records per API request (max) |
| `max_records_per_batch` | `1,000,000` | Safety limit per run |
| `staging_dir` | `data_lake/staging/` | CSV output directory |
| `domestic_table` | `raw_domestic_epc_certificates_tbl` | Target table |
| `non_domestic_table` | `raw_non_domestic_epc_certificates_tbl` | Target table |

### Error Handling

**401 Unauthorized**: Invalid credentials - check `.env` file

**429 Rate Limited**: Script automatically waits 60 seconds and retries

**Network Timeout**: Logs error and exits (safe to re-run)

**Duplicate UPRN Detection**: Automatically deduplicates by latest `LODGEMENT_DATE`

### Performance

**Typical Throughput:**
- ~5,000 records/minute from API
- ~10,000 records/second for MERGE INTO
- 1 million records: ~3-4 minutes total

**Optimization:**
- Uses DuckDB's native CSV parser (C++ optimized)
- UNION ALL BY NAME handles column alignment
- Window functions for deduplication
- Single transaction per batch

## Creating views

Views are created to manipulate data in data_lake/mca_env_base.duckdb using the src/create_views.sql script

## 🌍 Geospatial Standards

Critical: This project mixes Web data (Lat/Lon) with UK Gov data (Easting/Northing).

Input: Various (EPSG:4326, EPSG:27700).

Standardization: All tables in the Silver Layer are forced to British National Grid (EPSG:27700) to ensure accurate area and distance calculations.

Engine: Uses DuckDB spatial extension.

## 📝 Schema Documentation System

The project includes a sophisticated schema documentation tool that generates SQL `COMMENT` statements for all tables and columns in the DuckDB database. This ensures database metadata is discoverable and maintainable. This is of particular value when using AI Agents and MCPs to query the database, for example Motherduck MCP with Claude.

### How It Works

The schema documentation system uses a **multi-stage pipeline** to generate intelligent, context-aware descriptions:

#### 1. **XML Schema Parsing**

* Imports canonical metadata from curated XML files (e.g., `src/schemas/documentation/epc_domestic_schema.xml`)
* XML schemas provide authoritative descriptions for known datasets
* Supports multiple XML files for different data sources
* **Priority:** Highest (canonical source of truth)

#### 2. **Database Analysis**

* Queries DuckDB system tables (`duckdb_columns()`, `duckdb_tables()`, `duckdb_views()`)
* Identifies all tables, views, and columns requiring documentation
* Detects data types and constraints

#### 3. **Intelligent Pattern Matching**

* Infers descriptions from column naming conventions with confidence scoring
* **Suffix patterns:** `_cd` → "code", `_nm` → "name", `_dt` → "date", `_flag` → "flag (Y/N)"
* **Prefix patterns:** `current_` → "Current value of", `total_` → "Total", `max_` → "Maximum"
* **Exact matches:** `uprn` → "Unique Property Reference Number", `lsoa` → "Lower Layer Super Output Area code"
* Pattern rules defined in `src/tools/config/pattern_rules.yaml`
* **Priority:** Medium (heuristic-based inference)

#### 4. **View-to-Table Mapping**

* Parses view definitions to identify source tables
* Automatically propagates comments from base tables to views
* Handles multi-level view chains
* Only requires manual review for computed/fallback columns

#### 5. **Manual Overrides**

* Interactive editor generates `src/schemas/documentation/manual_overrides.xml`
* User edits take absolute precedence over all other sources
* Session persistence allows resuming review process
* **Priority:** Highest (user-verified metadata)

#### 6. **SQL Comment Generation**

* Produces executable `COMMENT ON TABLE` and `COMMENT ON COLUMN` statements
* Outputs to `src/schemas/documentation/generated_comments.sql`
* Can apply directly to database or save for review (dry-run mode)

### Priority Hierarchy

When multiple sources provide metadata for the same field:

```
Manual Overrides > External XML Schemas > Pattern Inference
```

### Usage Examples

#### Generate Comments (Dry Run)

Review generated SQL without applying to database:

```bash
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -x src/schemas/documentation/epc_domestic_schema.xml \
    --dry-run
```

Output: `src/schemas/documentation/generated_comments.sql`

#### Apply Comments to Database

Execute SQL COMMENT statements against the database:

```bash
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -x src/schemas/documentation/epc_domestic_schema.xml
```

#### Interactive Comment Editor

Launch Rich TUI to review and edit inferred descriptions:

**Requirements:** PowerShell (Windows) for proper terminal rendering

```bash
# Start new session
uv run python -m src.tools.schema_documenter edit-comments \
    -d data_lake/mca_env_base.duckdb

# Resume previous session
uv run python -m src.tools.schema_documenter edit-comments \
    -d data_lake/mca_env_base.duckdb --resume

# Clear session and start over
uv run python -m src.tools.schema_documenter edit-comments \
    -d data_lake/mca_env_base.duckdb --clear-session
```

**Features:**

* Auto-saves progress to `.schema_review_session.json`
* Navigate with arrow keys
* Edit/Keep/Skip each field
* Only reviews tables without XML schemas
* Only reviews view columns with `source="fallback"` or `source="computed"`
* Exports edits to `manual_overrides.xml`

#### Filter Specific Tables

Generate comments for selected tables only:

```bash
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -t epc_domestic -t boundaries_lsoa \
    --dry-run
```

#### Exclude Views

Process tables only (skip view mapping):

```bash
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    --no-views
```

### Typical Workflow

1. **First Run:** Generate with XML schemas to document known datasets

   ```bash
   uv run python -m src.tools.schema_documenter generate \
       -d data_lake/mca_env_base.duckdb \
       -x src/schemas/documentation/epc_domestic_schema.xml \
       --dry-run
   ```

2. **Review:** Inspect `generated_comments.sql` for pattern-matched descriptions

3. **Interactive Edit:** Launch editor to refine inferred descriptions

   ```bash
   uv run python -m src.tools.schema_documenter edit-comments \
       -d data_lake/mca_env_base.duckdb
   ```

4. **Final Generation:** Regenerate with manual overrides and apply to database

   ```bash
   uv run python -m src.tools.schema_documenter generate \
       -d data_lake/mca_env_base.duckdb \
       -x src/schemas/documentation/epc_domestic_schema.xml
   ```

5. **Verification:** Query database to verify comments

   ```sql
   -- Check table comments
   SELECT table_name, comment
   FROM duckdb_tables()
   WHERE comment IS NOT NULL;

   -- Check column comments for specific table
   SELECT column_name, data_type, comment
   FROM duckdb_columns()
   WHERE table_name = 'epc_domestic' AND comment IS NOT NULL;
   ```

### Key Files

| File | Purpose |
|------|---------|
| `src/tools/schema_documenter.py` | CLI entry point (Click framework) |
| `src/tools/comment_editor.py` | Interactive Rich TUI editor |
| `src/tools/config/pattern_rules.yaml` | Pattern matching definitions (14 suffixes, 7 prefixes, 17 exact matches) |
| `src/tools/config/settings.yaml` | Default paths and confidence thresholds |
| `src/schemas/documentation/epc_domestic_schema.xml` | Canonical EPC metadata |
| `src/schemas/documentation/manual_overrides.xml` | User edits from interactive editor |
| `src/schemas/documentation/generated_comments.sql` | Output SQL COMMENT statements |
| `.schema_review_session.json` | Session persistence (gitignored) |

### Pattern Matching Examples

The inference engine recognizes UK-specific conventions:

| Column Name | Inferred Description | Source |
|-------------|---------------------|--------|
| `uprn` | "Unique Property Reference Number" | Exact match |
| `lmk_key` | "Lodgement Management Key" | Exact match |
| `energy_rating_cd` | "Energy rating code" | Suffix `_cd` |
| `current_co2_emissions` | "Current value of CO2 emissions" | Prefix `current_` |
| `improvement_flag` | "Improvement flag (Y/N)" | Suffix `_flag` |
| `lsoa` | "Lower Layer Super Output Area code" | Exact match |
| `total_floor_area` | "Total floor area" | Prefix `total_` |

### Extending Pattern Rules

Add custom patterns to `src/tools/config/pattern_rules.yaml`:

```yaml
suffix_patterns:
  _energy_rating: "energy efficiency rating"
  _improvement_: "suggested improvement"

exact_matches:
  ward_cd: "Electoral ward code"
  ward_nm: "Electoral ward name"
```

### Benefits

* **Self-Documenting Database:** Metadata visible in DBeaver, DuckDB CLI, and notebooks
* **Onboarding:** New analysts can explore schema without external documentation
* **Consistency:** Standardized descriptions across all datasets
* **Auditability:** XML and SQL files version-controlled in Git
* **Efficiency:** Automated inference reduces manual documentation burden
