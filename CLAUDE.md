# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Local Gov Environmental Analytics: Local Lakehouse** - A standalone analytical platform for UK Local Government environmental data built on DuckDB. Implements a **Medallion Architecture** (Bronze → Silver → Gold layers) with orchestrated SQL transformations, automated schema documentation, and incremental API updates.

**Key characteristics:**

- **Database:** DuckDB 1.4.0+ (`data_lake/mca_env_base.duckdb`, ~7GB)
- **Language:** Python 3.13+ with strict typing
- **Package Manager:** `uv` (NOT pip)
- **Linter/Formatter:** Ruff 0.9.3+
- **Architecture:** Medallion (Bronze → Silver → Gold)

## Current Project Status

**Completed:**
- ✅ Orchestrated transformation system (Bronze/Silver layers)
- ✅ Schema documentation toolkit with interactive editor
- ✅ EPC API incremental update system
- ✅ Prerequisites verification tool

**In Progress:**
- 🚧 Gold layer implementation (Phase 4)
- 🚧 Bronze/Silver verification (docs/VERIFICATION_PLAN.md)

**Next Steps:**
- Migrate analytics views from `src/create_views.sql` to `src/transformations/sql/gold/`
- Complete Gold layer schema definitions
- Full end-to-end testing

## Python Package Management with uv

**Use uv exclusively for Python package management in this project.**

### Package Management Commands

All Python dependencies **must be installed, synchronised, and locked** using uv. Never use pip, pip-tools, poetry, or conda directly for dependency management.

```bash
# Install dependencies
uv add <package>                  # Add production dependency
uv add <package> --group dev      # Add development dependency

# Remove dependencies
uv remove <package>

# Sync dependencies (install/update from lock file)
uv sync
```

### Running Python Code

Always use `uv run` to execute Python code and tools:

```bash
# Run a Python script
uv run <script-name>.py

# Run Python tools
uv run pytest                     # Run tests
uv run ruff                       # Run linter

# Launch Python REPL
uv run python
```

### Managing Scripts with PEP 723 Inline Metadata

For standalone scripts with inline metadata (dependencies defined at the top of the file):

```bash
# Run a script with inline metadata
uv run script.py

# Add dependency to script
uv add package-name --script script.py

# Remove dependency from script
uv remove package-name --script script.py
```

## Essential Commands

### Prerequisites Verification

Always run this before working with the database:

```bash
# Automated prerequisites verification (prompts to create DB if missing)
uv run python -m src.tools.verify_prerequisites

# Auto-create database without prompt
uv run python -m src.tools.verify_prerequisites --create-if-missing

# Skip VPN/PostGIS check (for offline development)
uv run python -m src.tools.verify_prerequisites --skip-vpn
```

### SQL Transformations (Medallion Architecture)

**Orchestrated transformation system:**

```bash
# Run full pipeline (Bronze → Silver → Gold)
uv run python -m src.transformations all

# Run specific layers
uv run python -m src.transformations bronze
uv run python -m src.transformations silver gold
uv run python -m src.transformations bronze silver

# Dry-run preview (show execution plan without running)
uv run python -m src.transformations all --dry-run

# Validate sources before running (Bronze layer only)
uv run python -m src.transformations bronze --validate

# Verbose logging
uv run python -m src.transformations all -v     # INFO level
uv run python -m src.transformations all -vv    # DEBUG level
```

**Key features:**
- Dependency resolution via topological sort
- Idempotent transformations
- Progress tracking with Rich
- Error handling with informative messages
- Modular SQL organised by layer

**Legacy SQL scripts (⚠️ deprecated, do not use):**

```bash
# OLD: Manual SQL execution (being phased out)
duckdb data_lake/mca_env_base.duckdb < src/create_views.sql
duckdb data_lake/mca_env_base.duckdb < src/manual_external_load.sql
duckdb data_lake/mca_env_base.duckdb < src/boundaries_staging.sql
```

### Schema Documentation System

The schema documentation system (3411 LOC) maintains DuckDB schema metadata through intelligent comment generation.

```bash
# Interactive comment editor (with session persistence)
uv run python -m src.tools.schema_documenter edit-comments \
    -d data_lake/mca_env_base.duckdb

# Resume previous session
uv run python -m src.tools.schema_documenter edit-comments \
    -d data_lake/mca_env_base.duckdb --resume

# Clear session and start fresh
uv run python -m src.tools.schema_documenter edit-comments \
    -d data_lake/mca_env_base.duckdb --clear-session

# Generate SQL COMMENT statements (dry run)
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -x src/schemas/documentation/epc_domestic_schema.xml \
    --dry-run

# Apply comments to database
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -x src/schemas/documentation/epc_domestic_schema.xml
```

### EPC Incremental Updates

Daily automation for fetching new EPC certificates from API:

```bash
# Update both domestic and non-domestic
uv run python -m src.extractors.epc_incremental_update all -v

# Update specific certificate type
uv run python -m src.extractors.epc_incremental_update domestic -v
uv run python -m src.extractors.epc_incremental_update non-domestic -v

# Dry-run (preview without modifying database)
uv run python -m src.extractors.epc_incremental_update domestic --dry-run

# Override start date (backfill)
uv run python -m src.extractors.epc_incremental_update domestic --from-date 2024-01-01

# Debug logging
uv run python -m src.extractors.epc_incremental_update domestic -vv
```

### Code Quality

```bash
uv run pytest                     # Run test suite
uv run pytest -v                  # Verbose output
uv run pytest -k test_bronze      # Run specific tests

uv run ruff check                 # Run linter
uv run ruff format                # Format code
```

## Architecture Overview

### Medallion Architecture Pattern

**Landing Zone:** Raw CSVs, Zips, Parquet in `data_lake/landing/`
- `automated/` - API outputs (EPC, boundaries)
- `manual/` - Manual downloads (Humaniverse, ONS)

**Bronze Layer:** DuckDB tables on raw files + PostGIS federation
- 6 SQL modules: boundaries_federated, boundaries_external, epc_load, emissions_load, census_load, iod_load
- Minimal transformations (type casting only)
- `CREATE OR REPLACE TABLE` for idempotency

**Silver Layer:** Cleaned, deduplicated, spatially standardised (EPSG:27700)
- 5 SQL modules: macros, boundaries_clean, epc_domestic_clean, epc_non_domestic_clean, emissions_clean
- `CREATE OR REPLACE VIEW` for efficiency
- Spatial reprojection to British National Grid

**Gold Layer:** Aggregated analytics-ready data
- ⚠️ **Status:** In development (Phase 4)
- Target: 2+ modules (emissions_aggregates, epc_analytics)
- Migrating from `src/create_views.sql`

### Data Ingestion Strategies

1. **Federated PostGIS:** Zero-copy attachment via `postgres_scanner`
   - Requires VPN to corporate network
   - Bronze module: `boundaries_federated.sql`

2. **Automated APIs:** Python scripts → Parquet → Bronze reads via `read_csv()`
   - EPC incremental updates (daily)
   - Boundary API extractions (weekly)

3. **Manual Drop Zone:** Download → Rename with date suffix → Drop in `landing/manual/` → SQL glob selects latest
   - Bulk EPC downloads, Humaniverse, ONS data
   - Glob pattern: `data_lake/landing/manual/{dataset}/*.csv`

### Spatial Standards

**Critical:** All Silver layer data MUST use **EPSG:27700** (British National Grid) for accurate UK area/distance calculations.

**Extensions required:**
- DuckDB SPATIAL extension (geometry functions, spatial joins)
- postgres_scanner extension (PostGIS federation)

## Schema Documentation System

The schema documentation toolkit is a sophisticated multi-stage pipeline located in `src/tools/`:

### Pipeline Stages

1. **XML Parsing** - Import canonical metadata from curated XML schemas
2. **Database Analysis** - Query `duckdb_columns()`, `duckdb_tables()`, `duckdb_views()`
3. **Inference Engine** - Pattern matching with confidence scoring:
   - Suffix patterns: `_cd` → "code", `_nm` → "name", `_dt` → "date", `_flag` → "flag (Y/N)"
   - Prefix patterns: `current_` → "Current value of", `total_` → "Total"
   - Exact matches: `uprn` → "Unique Property Reference Number", `lsoa` → "Lower Layer Super Output Area code"
4. **View Mapping** - Auto-propagate table comments to dependent views
5. **Manual Overrides** - User edits via interactive editor → `manual_overrides.xml`
6. **SQL Generation** - `COMMENT ON TABLE/COLUMN` statements

### Key Modules

| Module | Purpose | LOC |
|--------|---------|-----|
| `src/tools/schema_documenter.py` | CLI entry point (Click) | 200 |
| `src/tools/comment_editor.py` | Interactive Rich TUI with session management | 400 |
| `src/tools/parsers/models.py` | Pydantic schema metadata models | 150 |
| `src/tools/parsers/schema_analyzer.py` | Pattern inference with confidence scoring | 300 |
| `src/tools/parsers/xml_parser.py` | Flexible XML schema parsing | 200 |
| `src/tools/generators/comment_generator.py` | SQL statement generation | 250 |
| `src/tools/generators/view_mapper.py` | View definition parsing & comment propagation | 300 |
| `src/tools/utils/session_manager.py` | JSON-based session persistence | 200 |
| `src/tools/utils/interactive_menu.py` | Rich TUI components | 250 |

### Configuration Files

- `src/tools/config/pattern_rules.yaml` - Pattern definitions (14 suffixes, 7 prefixes, 17+ exact matches)
- `src/tools/config/settings.yaml` - Default paths, confidence thresholds, output settings

### Comment Priority Hierarchy

```
Manual Overrides (manual_overrides.xml)
    ↓
External XML Schemas (epc_domestic_schema.xml, etc.)
    ↓
Pattern Inference (pattern_rules.yaml)
```

### Working with the Schema Tool

**Pattern Matching Priority:**
1. Exact matches (highest confidence)
2. Suffix patterns
3. Prefix patterns
4. Data type conventions
5. Statistical analysis (lowest confidence)

**Interactive Editor Workflow:**
1. Start: `uv run python -m src.tools.schema_documenter edit-comments -d <db>`
2. Navigate with arrow keys
3. Edit/Keep/Skip each field
4. Auto-saves to `.schema_review_session.json`
5. Generates `manual_overrides.xml`
6. Resume anytime with `--resume`

**View Handling:**
- **Tables:** Editor reviews ALL columns if no XML schema exists
- **Views:** Editor only reviews `source="fallback"` or `source="computed"` columns
- View mapping automatically copies comments from base tables

## SQL Transformation System

### Architecture

**Core components:**
- `src/transformations/__main__.py` - Click CLI entry point (~145 LOC)
- `src/transformations/orchestrator.py` - Execution logic with dependency resolution (~344 LOC)
- `src/transformations/models.py` - Pydantic configuration models (~95 LOC)

**SQL modules organised by layer:**
- `src/transformations/sql/bronze/` - 6 modules (342+ LOC total)
- `src/transformations/sql/silver/` - 5 modules (189 LOC total)
- `src/transformations/sql/gold/` - ⚠️ EMPTY (Phase 4 - in development)

### Dependency Management

Each layer has a `_schema.yaml` file defining module metadata:

```yaml
# Example: src/transformations/sql/silver/_schema.yaml
epc_domestic_clean:
  description: "Clean domestic EPC certificates"
  depends_on:
    - "bronze/epc_load"      # Cross-layer dependency
    - "silver/macros"        # Same-layer dependency
  enabled: true

boundaries_clean:
  description: "CA/LA boundary lookups with North Somerset union"
  depends_on:
    - "bronze/boundaries_federated"
    - "bronze/boundaries_external"
  enabled: true
```

**Dependency resolution:**
- Topological sort (Kahn's algorithm)
- Detects circular dependencies
- Allows cross-layer dependencies
- Execution in dependency order

### Module Discovery

**Automatic discovery:**
1. Scan `src/transformations/sql/{layer}/` for `*.sql` files
2. Load metadata from `_schema.yaml`
3. Build dependency graph
4. Sort modules by dependencies
5. Execute in order

### Extension Loading

**DuckDB extensions are loaded automatically per connection:**
```python
with duckdb.connect(str(self.config.db_path)) as conn:
    # SPATIAL extension does NOT autoload, must load explicitly
    conn.execute("LOAD spatial;")
    # Postgres extension autoloads but load explicitly for consistency
    conn.execute("LOAD postgres;")
    conn.execute(sql_content)
```

**Important:** Extensions must be loaded for each new connection session even though `INSTALL` is persistent.

## Python Code Standards

From `agent-docs/python-code-guidelines.md`:

**Mandatory:**

- Python 3.13+ syntax (NOT 3.10 or 3.11)
- Strict type hints on ALL functions: `def func(arg: str) -> int:`
- Union syntax: `str | None` (NOT `Optional[str]`)
- Built-in generics: `list[str]`, `dict[str, int]` (NOT `typing.List/Dict`)
- f-strings for formatting (NOT %-formatting or .format())
- `pathlib.Path` for file operations (NOT `os.path`)
- Google-style docstrings
- Pydantic for configs/schemas
- Early returns and guard clauses
- `match/case` for complex branching (NOT long if/elif chains)
- Specific exception handling (NOT bare `except Exception`)

**Ruff Configuration:**

- Line length: 88 characters
- Target: Python 3.12
- Enabled rules: E, W, F, UP, S, B, SIM, I
- Quote style: double
- Auto-format enabled

## Project Plans & Documentation

### Active Plans

**`docs/SQL_TRANSFORMATION_PLAN.md`** - 🚧 IN PROGRESS (Phase 4 - Gold Layer)
- Status: Phases 1-3 completed (Bronze/Silver), Phase 4 pending
- Next: Migrate analytics views from `src/create_views.sql` to `src/transformations/sql/gold/`
- Blocked: Waiting for Bronze/Silver verification

**`docs/VERIFICATION_PLAN.md`** - ⏳ PENDING
- Purpose: Verify Bronze/Silver layers work correctly before Phase 4
- Action: Test transformation system end-to-end
- Requirement: Must complete before Gold layer implementation

**`docs/EPC_API_UPDATE_PLAN.md`** - ✅ COMPLETED
- Implementation complete: `src/extractors/epc_incremental_update.py`
- Fully functional EPC API incremental update system
- Reference: `docs/delegated-waddling-sphinx.md` (detailed plan)

### Historical Documentation

**`docs/calm-weaving-rain.md`** - Schema Documentation System Implementation Plan
- Status: ✅ COMPLETED
- Reference for schema documentation toolkit architecture

**`docs/zany-dazzling-newt.md`** - Interactive Schema Comment Editor Implementation Plan
- Status: ✅ COMPLETED
- Reference for comment editor and session management

## Key Files & Entry Points

### Transformation System

| File | Purpose | LOC |
|------|---------|-----|
| `src/transformations/__main__.py` | CLI entry point (Click) | 145 |
| `src/transformations/orchestrator.py` | Execution logic with dependency resolution | 344 |
| `src/transformations/models.py` | Pydantic models for SQL modules | 95 |
| `src/transformations/sql/bronze/` | Bronze layer SQL (5 modules) | 342 |
| `src/transformations/sql/silver/` | Silver layer SQL (5 modules) | 189 |
| `src/transformations/sql/gold/` | Gold layer SQL (EMPTY - Phase 4) | 0 |

### Schema Documentation

| File | Purpose | LOC |
|------|---------|-----|
| `src/tools/schema_documenter.py` | CLI entry point | 200 |
| `src/tools/comment_editor.py` | Interactive editor | 400 |
| `src/tools/verify_prerequisites.py` | Prerequisites checker | 150 |
| `src/tools/parsers/models.py` | Pydantic schema models | 150 |
| `src/tools/parsers/schema_analyzer.py` | Pattern inference | 300 |
| `src/tools/parsers/xml_parser.py` | XML parsing | 200 |
| `src/tools/generators/comment_generator.py` | SQL comment generation | 250 |
| `src/tools/generators/view_mapper.py` | View definition parsing | 300 |
| `src/tools/utils/session_manager.py` | Session persistence | 200 |
| `src/tools/utils/interactive_menu.py` | Rich TUI components | 250 |

### EPC Incremental Updates

| File | Purpose | LOC |
|------|---------|-----|
| `src/extractors/epc_incremental_update.py` | EPC API CLI | 300 |
| `src/extractors/epc_api_client.py` | HTTP client | 200 |
| `src/extractors/epc_models.py` | Pydantic config | 100 |

### Configuration & Schemas

| File | Purpose |
|------|---------|
| `src/schemas/config/epc_domestic_certificates_schema.json` | EPC domestic column types |
| `src/schemas/config/epc_non-domestic_certificates_schema.json` | EPC non-domestic column types |
| `src/schemas/documentation/epc_domestic_schema.xml` | Canonical EPC metadata |
| `src/schemas/documentation/iod2025_schema.xml` | IoD 2025 File 7 metadata (56 columns) |
| `src/schemas/documentation/manual_overrides.xml` | User edits from interactive editor |
| `src/schemas/documentation/generated_comments.sql` | Output: SQL COMMENT statements |
| `src/tools/config/pattern_rules.yaml` | Pattern matching definitions |
| `src/tools/config/settings.yaml` | Default paths and settings |
| `pyproject.toml` | Project metadata & dependencies |
| `ruff.toml` | Code quality rules |

### Legacy (Deprecated - DO NOT USE)

| File | Status | Replacement |
|------|--------|-------------|
| `src/create_views.sql` | ⚠️ DEPRECATED | Being migrated to `src/transformations/sql/gold/` |
| `src/manual_external_load.sql` | ⚠️ DEPRECATED | Replaced by `src/transformations/sql/bronze/` |
| `src/boundaries_staging.sql` | ⚠️ DEPRECATED | Replaced by `src/transformations/sql/bronze/` |
| `src/utility/` | ⚠️ DEPRECATED | Use `src/extractors/` and `src/tools/` instead |

## Important Patterns & Conventions

### Session Management

- Interactive editor uses `.schema_review_session.json` for progress tracking
- Sessions auto-save after each edit
- Resume with `--resume` flag, clear with `--clear-session`
- Session file gitignored

### View Comment Propagation

- View definitions parsed from `duckdb_views()`
- Source tables extracted via SQL parsing
- Comments copied from base tables to matching view columns
- Handles multi-level view chains

### DuckDB System Tables

Query schema metadata using:

```sql
-- Column definitions with comments
SELECT * FROM duckdb_columns() WHERE table_name = 'your_table';

-- Table definitions with comments
SELECT * FROM duckdb_tables() WHERE table_name LIKE '%epc%';

-- View definitions (SQL text)
SELECT * FROM duckdb_views() WHERE view_name = 'your_view';
```

### XML Schema Format

Flexible parsing supports:

```xml
<schema>
  <table name="table_name">
    <description>Table description</description>
    <column name="column_name">
      <type>VARCHAR</type>
      <description>Column description</description>
    </column>
  </table>
</schema>
```

## Directory Notes

### Gitignored (Local Only)

- `data_lake/` - Contains live database files and data (~7GB)
  - `landing/` - Raw data files
  - `staging/` - Incremental update CSVs
  - `mca_env_base.duckdb` - Main database
- `.schema_review_session.json` - Session state for interactive editor
- `.env` - Environment variables (EPC API credentials)

### Source Code

- `src/` - Source code package
  - `extractors/` - API clients and data extraction (EPC API)
  - `transformations/` - SQL transformation orchestration
  - `tools/` - Schema documentation toolkit (main codebase)
  - `schemas/` - Schema configurations and documentation
    - `config/` - JSON schema files for column types
    - `reference/` - External reference data (ONSPD, PDFs)
    - `analysis/` - Analysis artifacts (raw column CSVs)
    - `documentation/` - XML schemas and generated SQL
  - `utility/` - **⚠️ DEPRECATED** - Legacy code (use extractors/tools instead)

### Documentation

- `docs/` - Project documentation and planning files
  - `SQL_TRANSFORMATION_PLAN.md` - Medallion Architecture migration plan
  - `VERIFICATION_PLAN.md` - Bronze/Silver verification checklist
  - `EPC_API_UPDATE_PLAN.md` - EPC incremental update reference
  - `*.md` - Historical implementation plans

### Other

- `notebooks/` - Jupyter notebooks for EDA
- `plots/` - Generated visualisations
- `tests/` - Pytest test suite
  - `test_transformations/` - Transformation system tests
- `.serena/` - Agent memory/session data
- `.claude/` - Claude Code CLI commands

## Common Development Tasks

### Adding New Bronze Layer Module

1. Create SQL file in `src/transformations/sql/bronze/{module_name}.sql`
2. Add metadata to `src/transformations/sql/bronze/_schema.yaml`:
```yaml
module_name:
  description: "Module description"
  depends_on: []  # Or list dependencies
  enabled: true
  requires_vpn: false  # true if needs PostGIS
  source_files:  # Optional - for validation
    - "data_lake/landing/manual/dataset/*.csv"
```
3. Test with dry-run: `uv run python -m src.transformations bronze --dry-run`
4. Execute: `uv run python -m src.transformations bronze -vv`

### Adding New Silver Layer View

1. Create SQL file in `src/transformations/sql/silver/{module_name}.sql`
2. Add metadata to `src/transformations/sql/silver/_schema.yaml`:
```yaml
module_name:
  description: "View description"
  depends_on:
    - "bronze/source_module"
    - "silver/macros"  # If using spatial functions
  enabled: true
```
3. Use `CREATE OR REPLACE VIEW` for idempotency
4. Test: `uv run python -m src.transformations silver -vv`

### Adding Pattern Rules

Edit `src/tools/config/pattern_rules.yaml`:

```yaml
suffix_patterns:
  _new_suffix: "description"

prefix_patterns:
  new_prefix_: "Description prefix"

exact_matches:
  new_column: "Full description"
```

### Modifying Inference Logic

- Pattern matching: `src/tools/parsers/schema_analyzer.py`
- Confidence scoring: Adjust thresholds in `schema_analyzer.py`
- View SQL parsing: `src/tools/generators/view_mapper.py`

### Database Introspection

```sql
-- Get tables with comments
SELECT table_name, comment
FROM duckdb_tables()
WHERE comment IS NOT NULL;

-- Get columns for table with comments
SELECT column_name, data_type, comment
FROM duckdb_columns()
WHERE table_name = 'your_table' AND comment IS NOT NULL;

-- Get view definitions
SELECT view_name, sql
FROM duckdb_views()
WHERE view_name LIKE '%epc%';
```

## Technology Stack

**Core:**
- DuckDB 1.4.0+ (embedded OLAP with SPATIAL extension)
- Polars 1.32.0+ (DataFrames)
- PyArrow (columnar data)

**CLI/UI:**
- Click 8.3.1+ (CLI framework)
- Rich 14.2.0+ (terminal UI)
- questionary 2.1.1+ (interactive prompts)

**Schema/Config:**
- Pydantic 2.12.5+ (data validation)
- PyYAML (config parsing)
- lxml 6.0.2+ (XML parsing)

**HTTP:**
- httpx 0.27.0+ (async HTTP client)
- requests 2.32.5+ (HTTP library)

**Testing:**
- pytest 8.3.4+ (test framework)

## Typical Workflows for AI Assistants

### Helping with New Features

1. **Understand the layer:** Bronze (raw), Silver (clean), or Gold (analytics)?
2. **Check dependencies:** What existing modules/tables are needed?
3. **Create SQL file:** Use appropriate layer directory
4. **Update _schema.yaml:** Add metadata with dependencies
5. **Test incrementally:** Dry-run first, then execute with verbose logging
6. **Document:** Add schema comments if new tables/columns

### Debugging Transformation Issues

1. **Check logs:** Look for specific error messages in verbose output
2. **Verify prerequisites:** Run `src.tools.verify_prerequisites`
3. **Check dependencies:** Ensure all required modules are enabled
4. **Test in isolation:** Run single layer to isolate issue
5. **Validate sources:** Use `--validate` flag for Bronze layer
6. **Check extensions:** Ensure SPATIAL and postgres are loaded

### Adding Schema Documentation

1. **Check existing schemas:** Look in `src/schemas/documentation/`
2. **Run generator with dry-run:** Preview output first
3. **Use interactive editor:** For tables without XML schemas
4. **Verify comments:** Query `duckdb_columns()` to confirm
5. **Commit overrides:** `manual_overrides.xml` to version control

### Maintaining EPC Data

1. **Daily incremental update:** `uv run python -m src.extractors.epc_incremental_update all -v`
2. **Check for errors:** Look for 401 (credentials), 429 (rate limit)
3. **Verify MERGE results:** Check inserted vs updated counts
4. **Monitor staging CSVs:** Check `data_lake/staging/` for audit trail
5. **Backfill if needed:** Use `--from-date` to catch up after downtime

## Extending Patterns

Add UK-specific codes to `pattern_rules.yaml`:

- UPRN, USRN (property/street references)
- LSOA, MSOA, OA (census geography)
- Postcode formats
- EPC-specific suffixes (`_energy_rating`, `_improvement_`)
- LA codes (`_la_cd`, `_la_nm`)
- IMD deciles (`_imd_decile`)
