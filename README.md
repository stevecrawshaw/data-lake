# Local Gov Environmental Analytics: Local Lakehouse

A standalone analytical platform for UK Local Government environmental data built on DuckDB. Implements a **Medallion Architecture** (Bronze → Silver → Gold) for unifying geospatial boundaries, API streams, and manual datasets.

## 🎯 Quick Start

### Prerequisites

1. **Python 3.13+** with `uv` package manager
2. **DuckDB 1.4.0+** (installed via uv)
3. **VPN access** to corporate PostGIS (for boundary data)
4. **EPC API credentials** ([request here](https://epc.opendatacommunities.org/))

### Initial Setup

```bash
# 1. Install dependencies
uv sync

# 2. Configure environment variables
# Create .env file with:
EPC_USERNAME=your_api_username
EPC_PASSWORD=your_api_password

# 3. Verify prerequisites (creates database if missing)
uv run python -m src.tools.verify_prerequisites --create-if-missing

# 4. Load data layers (Bronze → Silver)
uv run python -m src.transformations bronze silver -vv

# 5. Document schema
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -x src/schemas/documentation/epc_domestic_schema.xml

# 6. Set up incremental updates (daily automation)
uv run python -m src.extractors.epc_incremental_update all -v
```

## 🏗 Architecture

This project implements a **Medallion Architecture** optimized for local filesystem operations:

### Data Flow

```
Landing Zone (Filesystem)
    ↓
Bronze Layer (Raw DuckDB Tables)
    ↓
Silver Layer (Cleaned DuckDB Views)
    ↓
Gold Layer (Analytics-Ready Views)
```

### Layer Definitions

**Landing Zone** (`data_lake/landing/`)
- **`automated/`** - API outputs (EPC certificates, boundaries)
- **`manual/`** - Manual downloads (Humaniverse, ONS, bulk EPC)
- Formats: CSV, Parquet, ZIP
- Retention: Permanent (source of truth)

**Bronze Layer** (Raw Data)
- DuckDB tables reading directly from landing zone files
- Zero-copy federation to corporate PostGIS
- Minimal transformations (type casting only)
- Idempotent: `CREATE OR REPLACE TABLE`

**Silver Layer** (Standardized)
- Data cleaning and deduplication
- **Spatial reprojection to EPSG:27700** (British National Grid)
- Column renaming and date extraction
- Implemented as views: `CREATE OR REPLACE VIEW`

**Gold Layer** (Analytics)
- Aggregated metrics ready for BI/GIS
- Complex joins across data domains
- KPIs and derived calculations
- ⚠️ **Status:** In development (Phase 4)

## 📂 Project Structure

```
data-lake/
├── data_lake/                       # LOCAL ONLY (gitignored)
│   ├── landing/
│   │   ├── automated/               # API outputs (EPC, boundaries)
│   │   └── manual/                  # Manual downloads (Humaniverse, ONS)
│   ├── staging/                     # Incremental update staging CSVs
│   └── mca_env_base.duckdb          # Main database (7GB)
│
├── src/
│   ├── extractors/                  # API clients and data extraction
│   │   ├── epc_incremental_update.py  # EPC API incremental update CLI
│   │   ├── epc_api_client.py          # EPC API HTTP client
│   │   └── epc_models.py              # Pydantic configuration models
│   │
│   ├── transformations/             # SQL transformation orchestration
│   │   ├── __main__.py              # CLI entry point
│   │   ├── orchestrator.py          # Execution logic with dependency resolution
│   │   ├── models.py                # Pydantic models for SQL modules
│   │   └── sql/                     # Modular SQL organized by layer
│   │       ├── bronze/              # Raw data loading (5 modules)
│   │       ├── silver/              # Cleaning and standardization (5 modules)
│   │       └── gold/                # Analytics views (in development)
│   │
│   ├── tools/                       # Schema documentation toolkit
│   │   ├── schema_documenter.py    # CLI for schema documentation
│   │   ├── comment_editor.py       # Interactive Rich TUI editor
│   │   ├── verify_prerequisites.py # Prerequisites checker
│   │   ├── parsers/                # XML and schema analysis
│   │   ├── generators/             # SQL comment generation
│   │   ├── utils/                  # Session management, UI components
│   │   └── config/                 # Pattern rules and settings
│   │
│   └── schemas/                     # Schema configurations
│       ├── config/                  # JSON schema files (column types)
│       ├── documentation/           # XML schemas and generated SQL
│       └── reference/               # External reference data
│
├── tests/                           # Pytest test suite
│   └── test_transformations/       # Transformation system tests
│
├── notebooks/                       # Jupyter notebooks for EDA
├── docs/                           # Project documentation and plans
└── README.md
```

## 🔄 Complete Workflow

### 1. Initial Data Load

#### Step 1: Verify Prerequisites

```bash
# Check database, VPN, and directory structure
uv run python -m src.tools.verify_prerequisites

# Auto-create database if missing
uv run python -m src.tools.verify_prerequisites --create-if-missing

# Skip VPN check (for offline development)
uv run python -m src.tools.verify_prerequisites --skip-vpn
```

#### Step 2: Manual Data Downloads

Download bulk datasets and place in landing zone:

```bash
# EPC domestic certificates (UK-wide bulk download)
# Download from: https://epc.opendatacommunities.org/
# Place in: data_lake/landing/manual/epc_domestic/all-domestic-certificates-single-file/certificates.csv

# EPC non-domestic certificates
# Place in: data_lake/landing/manual/epc_non_domestic/all-non-domestic-certificates-single-file/certificates.csv

# Humaniverse data, ONS statistics, etc.
# Place in: data_lake/landing/manual/<dataset>/
```

#### Step 3: Run Bronze Layer Transformations

Load raw data from landing zone into DuckDB tables:

```bash
# Preview execution plan (dry-run)
uv run python -m src.transformations bronze --dry-run

# Validate source files exist
uv run python -m src.transformations bronze --validate

# Execute Bronze layer
uv run python -m src.transformations bronze -vv
```

**Bronze modules created:**
- `boundaries_federated` - PostGIS federation (requires VPN)
- `boundaries_external` - ArcGIS REST API boundaries
- `epc_load` - Domestic and non-domestic EPC certificates
- `emissions_load` - GHG emissions (long and wide formats)
- `census_load` - Tenure, IMD, postcodes, boundary lookups

#### Step 4: Run Silver Layer Transformations

Create cleaned, standardized views:

```bash
# Execute Silver layer
uv run python -m src.transformations silver -vv
```

**Silver views created:**
- `macros` - Spatial transformation functions
- `boundaries_clean` - CA/LA boundary lookups with unions
- `epc_domestic_clean` - Cleaned domestic EPC with tenure, construction age
- `epc_non_domestic_clean` - Cleaned non-domestic EPC with spatial joins
- `emissions_clean` - Emissions data joined with boundaries

#### Step 5: Run Full Pipeline

```bash
# Run Bronze → Silver in one command
uv run python -m src.transformations all -vv
```

### 2. Schema Documentation

#### Automatic Comment Generation

Generate SQL COMMENT statements for database metadata:

```bash
# Generate comments (dry-run)
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -x src/schemas/documentation/epc_domestic_schema.xml \
    --dry-run

# Apply comments to database
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -x src/schemas/documentation/epc_domestic_schema.xml
```

**⚠️ Important: Idempotency and Force Flag**

The `generate` command has **idempotency protection** - it skips columns that already have comments to avoid overwriting existing metadata. If you need to update existing comments (e.g., after manual review), use the two-step workflow:

```bash
# Step 1: Generate SQL file
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -x src/schemas/documentation/manual_overrides.xml

# Step 2: Apply with --force to overwrite existing comments
uv run python -m src.tools.schema_documenter apply \
    -d data_lake/mca_env_base.duckdb \
    -i src/schemas/documentation/generated_comments.sql \
    --force
```

**How it works:**
1. **XML Parsing** - Imports canonical metadata from curated XML schemas
2. **Database Analysis** - Queries `duckdb_columns()`, `duckdb_tables()`, `duckdb_views()`
3. **Pattern Matching** - Infers descriptions from naming conventions:
   - Suffix: `_cd` → "code", `_nm` → "name", `_dt` → "date"
   - Prefix: `current_` → "Current value of"
   - Exact: `uprn` → "Unique Property Reference Number"
4. **View Mapping** - Auto-propagates table comments to dependent views
5. **Manual Overrides** - User edits via interactive editor
6. **SQL Generation** - Produces `COMMENT ON TABLE/COLUMN` statements

#### Interactive Comment Editor

Launch Rich TUI to review and edit inferred descriptions:

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
- Navigate with arrow keys
- Edit/Keep/Skip each field
- Auto-saves progress to `.schema_review_session.json`
- Exports to `manual_overrides.xml` (highest priority)
- Only reviews tables without XML schemas
- Only reviews view columns with `source="fallback"` or `source="computed"`

**Priority hierarchy:**
```
Manual Overrides > External XML Schemas > Pattern Inference
```

**XML Schema Examples:**

External schema (e.g., `epc_domestic_schema.xml`):
```xml
<schema>
  <table name="raw_domestic_epc_certificates_tbl">
    <description>Domestic Energy Performance Certificate data from UK government register</description>
    <column name="LMK_KEY">
      <type>VARCHAR</type>
      <description>Individual lodgement identifier. Guaranteed to be unique and can be used to identify a certificate in the downloads and the API.</description>
    </column>
    <column name="ADDRESS1">
      <type>VARCHAR</type>
      <description>First line of the address</description>
    </column>
    <!-- ... more columns ... -->
  </table>
</schema>
```

Manual overrides (generated from interactive editor):
```xml
<schema>
  <table name="postcode_centroids_tbl">
    <description>Table containing 60 columns</description>
    <column name="x">
      <type>BIGINT</type>
      <description>Easting</description>
    </column>
    <column name="y">
      <type>BIGINT</type>
      <description>Northing</description>
    </column>
    <column name="pcd7">
      <type>VARCHAR</type>
      <description>Postcode 7 characters</description>
    </column>
    <!-- ... more columns ... -->
  </table>
</schema>
```

**📝 After Completing Interactive Review**

Once you've finished reviewing and editing descriptions in the interactive editor, apply your changes to the database:

```bash
# The editor saves your work to manual_overrides.xml
# Now apply it with --force to update existing comments
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -x src/schemas/documentation/manual_overrides.xml

uv run python -m src.tools.schema_documenter apply \
    -d data_lake/mca_env_base.duckdb \
    -i src/schemas/documentation/generated_comments.sql \
    --force
```

**Why --force is needed:** If tables already have comments from a previous run (even auto-generated ones), the `generate` command will skip them. Using `apply --force` ensures your manually-reviewed descriptions replace the old ones.

#### Verify Comments

```sql
-- Check table comments
SELECT table_name, comment
FROM duckdb_tables()
WHERE comment IS NOT NULL;

-- Check column comments
SELECT column_name, data_type, comment
FROM duckdb_columns()
WHERE table_name = 'raw_domestic_epc_certificates_tbl'
  AND comment IS NOT NULL;
```

### 3. Incremental EPC Updates

#### Daily Automation

Update EPC certificates with new records from API:

```bash
# Update both domestic and non-domestic
uv run python -m src.extractors.epc_incremental_update all -v

# Update specific certificate type
uv run python -m src.extractors.epc_incremental_update domestic -v
uv run python -m src.extractors.epc_incremental_update non-domestic -v
```

**How it works:**
1. **Queries Database** - Finds latest `LODGEMENT_DATE` in target table
2. **Fetches from API** - Retrieves certificates lodged since that date (cursor-based pagination)
3. **Normalizes Columns** - Transforms API format (lowercase) to database format (UPPERCASE)
4. **Deduplicates** - Keeps only latest certificate per UPRN using `QUALIFY ROW_NUMBER()`
5. **Stages CSV** - Writes to `data_lake/staging/epc_{type}_incremental_{date}.csv`
6. **Upserts** - Uses `MERGE INTO` to atomically insert new + update existing records

**Output example:**
```
============================================================
Updating DOMESTIC certificates
============================================================

Date range: 2025-01-02 to 2025-01-07
Fetching certificates...
Page 1: Fetched ~4523 records (total: ~4523)
Normalized 4523 records (lowercase -> UPPERCASE)
Deduplicated to 4501 unique UPRNs (removed 22 duplicates)
Wrote staging CSV: data_lake/staging/epc_domestic_incremental_2025-01-07.csv

MERGE INTO raw_domestic_epc_certificates_tbl...
MERGE completed: 4489 inserted, 12 updated

New max LODGEMENT_DATE: 2025-01-07
```

#### Options

```bash
# Dry-run (preview without modifying database)
uv run python -m src.extractors.epc_incremental_update domestic --dry-run

# Override start date (backfill)
uv run python -m src.extractors.epc_incremental_update domestic --from-date 2024-01-01

# Debug logging
uv run python -m src.extractors.epc_incremental_update domestic -vv

# Custom batch size
uv run python -m src.extractors.epc_incremental_update domestic --batch-size 1000
```

#### Configuration

Default settings in `src/extractors/epc_models.py`:

| Setting | Default | Description |
|---------|---------|-------------|
| `base_url` | `https://epc.opendatacommunities.org` | EPC API endpoint |
| `page_size` | `5000` | Records per API request (max) |
| `max_records_per_batch` | `1,000,000` | Safety limit per run |
| `staging_dir` | `data_lake/staging/` | CSV output directory |
| `domestic_table` | `raw_domestic_epc_certificates_tbl` | Target table |
| `non_domestic_table` | `raw_non_domestic_epc_certificates_tbl` | Target table |

#### Error Handling

- **401 Unauthorized** - Invalid credentials (check `.env`)
- **429 Rate Limited** - Auto-waits 60s and retries
- **Network Timeout** - Logs error and exits (safe to re-run)
- **Duplicate UPRNs** - Auto-deduplicates by latest `LODGEMENT_DATE`

#### Performance

**Typical throughput:**
- ~5,000 records/minute from API
- ~10,000 records/second for `MERGE INTO`
- 1 million records: ~3-4 minutes total

### 4. Regular Maintenance

```bash
# Daily: Incremental EPC update
uv run python -m src.extractors.epc_incremental_update all -v

# Weekly: Refresh schema documentation (after schema changes)
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -x src/schemas/documentation/epc_domestic_schema.xml

# Monthly: Re-run Bronze layer for new manual downloads
# (Download new files → place in landing/manual/)
uv run python -m src.transformations bronze -vv

# As needed: Full pipeline rebuild
uv run python -m src.transformations all -vv
```

## 🌍 Geospatial Standards

**Critical:** This project mixes Web data (Lat/Lon) with UK Gov data (Easting/Northing).

**Input formats:**
- EPSG:4326 (WGS84 - Web/GPS data)
- EPSG:27700 (British National Grid - UK Gov data)

**Standardization:**
All tables in the **Silver Layer** are forced to **EPSG:27700** to ensure accurate UK area and distance calculations.

**Engine:** DuckDB SPATIAL extension with PostGIS federation via `postgres_scanner`

## 🧪 Data Ingestion Strategies

### 1. Federated PostGIS (Corporate Data)

**Source:** Corporate PostGIS (Boundaries, Assets)

**Strategy:** Zero-copy attachment via `postgres_scanner` extension

**Requirements:** VPN access to corporate network

**Bronze module:** `boundaries_federated.sql`

```sql
-- Attach PostGIS database
ATTACH 'dbname=corporate user=readonly' AS corp_db (TYPE POSTGRES);

-- Create Bronze table from federated query
CREATE OR REPLACE TABLE open_uprn_lep_tbl AS
FROM corp_db.boundaries.open_uprn
WHERE lep_cd IN ('E37000008', 'E37000009');  -- Filter to LEP areas
```

### 2. Automated APIs (EPC, Boundaries)

**Source:** EPC API, ArcGIS REST APIs

**Strategy:** Python scripts write to `landing/automated/` → Bronze layer reads via `read_csv()`

**Frequency:** Daily (EPC incremental), Weekly (boundaries)

**Bronze modules:** `epc_load.sql`, `boundaries_external.sql`

**Extractors:**
- `src/extractors/epc_incremental_update.py` - EPC API client
- Future: Boundary API extractors

### 3. Manual Drop Zone (Bulk Downloads)

**Source:** Humaniverse, ONS, bulk EPC downloads

**Strategy:** Manual download → Place in `landing/manual/` → SQL glob selects latest

**Protocol:**
1. Download file manually
2. Rename with date suffix: `{dataset}_YYYY-MM-DD.csv`
3. Drop into `data_lake/landing/manual/{dataset}/`
4. Bronze SQL uses glob pattern: `*.csv` (selects latest by filename sort)

**Bronze modules:** `census_load.sql`, `emissions_load.sql`

**Example glob pattern:**
```sql
CREATE OR REPLACE TABLE imd_tbl AS
FROM read_csv('data_lake/landing/manual/imd/*.csv', ...);
-- Auto-selects latest: imd_2025-01-01.csv > imd_2024-12-01.csv
```

## 🛠 Technology Stack

**Core:**
- **DuckDB 1.4.0+** - Embedded OLAP with SPATIAL extension
- **Python 3.13+** - Strict typing, modern syntax
- **uv** - Fast Python package manager

**CLI/UI:**
- **Click 8.3.1+** - CLI framework
- **Rich 14.2.0+** - Terminal UI and progress bars
- **questionary 2.1.1+** - Interactive prompts

**Data Processing:**
- **Polars 1.32.0+** - DataFrame library
- **PyArrow** - Columnar data interchange

**Schema/Config:**
- **Pydantic 2.12.5+** - Data validation and settings
- **PyYAML** - Configuration parsing
- **lxml 6.0.2+** - XML parsing

**HTTP:**
- **httpx 0.27.0+** - Async HTTP client
- **requests 2.32.5+** - HTTP library

**Testing:**
- **pytest 8.3.4+** - Test framework

## 📚 Key Files & Entry Points

| File | Purpose |
|------|---------|
| **Transformation System** |
| `src/transformations/__main__.py` | CLI for SQL transformation orchestration |
| `src/transformations/orchestrator.py` | Execution logic with dependency resolution |
| `src/transformations/sql/bronze/` | Bronze layer SQL modules (5 files) |
| `src/transformations/sql/silver/` | Silver layer SQL modules (5 files) |
| `src/transformations/sql/gold/` | ⚠️ Gold layer (empty - Phase 4) |
| **Schema Documentation** |
| `src/tools/schema_documenter.py` | CLI for schema documentation |
| `src/tools/comment_editor.py` | Interactive Rich TUI editor |
| `src/tools/verify_prerequisites.py` | Prerequisites verification |
| `src/tools/config/pattern_rules.yaml` | Pattern matching rules |
| `src/schemas/documentation/epc_domestic_schema.xml` | Canonical EPC metadata |
| `src/schemas/documentation/manual_overrides.xml` | User edits from interactive editor |
| **EPC Incremental Updates** |
| `src/extractors/epc_incremental_update.py` | EPC API incremental update CLI |
| `src/extractors/epc_api_client.py` | EPC API HTTP client |
| `src/extractors/epc_models.py` | Pydantic configuration models |
| **Configuration** |
| `src/schemas/config/epc_domestic_certificates_schema.json` | EPC domestic column types |
| `src/schemas/config/epc_non-domestic_certificates_schema.json` | EPC non-domestic column types |
| **Legacy (Deprecated)** |
| `src/create_views.sql` | ⚠️ Legacy analytics views (to be migrated to gold/) |
| `src/manual_external_load.sql` | ⚠️ Legacy Bronze SQL (replaced by transformations/) |
| `src/boundaries_staging.sql` | ⚠️ Legacy boundary loading (replaced by transformations/) |

## 📖 Additional Documentation

- **`docs/SQL_TRANSFORMATION_PLAN.md`** - Medallion Architecture migration plan (Phase 4 in progress)
- **`docs/VERIFICATION_PLAN.md`** - Bronze/Silver layer verification checklist
- **`docs/EPC_API_UPDATE_PLAN.md`** - EPC incremental update implementation plan
- **`CLAUDE.md`** - AI assistant guidance for working with this codebase

## 🤝 Contributing

### Code Standards

- Python 3.13+ with strict type hints
- Union syntax: `str | None` (not `Optional[str]`)
- Built-in generics: `list[str]`, `dict[str, int]`
- f-strings for formatting
- `pathlib.Path` for file operations
- Google-style docstrings
- Pydantic for configs/schemas

### Code Quality

```bash
# Run tests
uv run pytest

# Run linter
uv run ruff check

# Format code
uv run ruff format
```

### Package Management

**Always use `uv` for dependency management:**

```bash
# Add dependency
uv add <package>

# Add dev dependency
uv add <package> --group dev

# Remove dependency
uv remove <package>

# Sync dependencies
uv sync
```

**Never use:** pip, pip-tools, poetry, conda

## 📄 License

[Add license information]

## 🙏 Acknowledgments

- **DuckDB** - Fast embedded analytical database
- **EPC Open Data** - UK Energy Performance Certificate data
- **ONS** - Office for National Statistics datasets
- **Humaniverse** - Social infrastructure datasets
