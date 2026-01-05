# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Local Gov Environmental Analytics: Local Lakehouse** - A standalone analytical platform for UK Local Government environmental data built on DuckDB and dbt. Implements a **Medallion Architecture** (Bronze → Silver → Gold layers) for unifying geospatial boundaries, API streams, and manual datasets (EPC, ONS, Humaniverse data).

Key characteristics:

- **Database:** DuckDB 1.4.0+ (`data_lake/mca_env_base.duckdb`, ~7GB)
- **Language:** Python 3.13+ with strict typing
- **Package Manager:** `uv` (NOT pip)
- **Linter/Formatter:** Ruff 0.9.3+

## Python Package Management with uv

**Use uv exclusively for Python package management in this project.**

### Package Management Commands

All Python dependencies **must be installed, synchronized, and locked** using uv. Never use pip, pip-tools, poetry, or conda directly for dependency management.

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

### Schema Documentation Tool

The schema documentation system (3411 LOC) is the core utility for maintaining DuckDB schema metadata.

```bash
# Interactive comment editor (with session persistence)
uv run python -m src.tools.schema_documenter edit-comments \
    -d data_lake/mca_env_base.duckdb

# Resume previous session
uv run python -m src.tools.schema_documenter edit-comments \
    -d data_lake/mca_env_base.duckdb --resume

# Generate SQL COMMENT statements (dry run)
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -x src/schemas/documentation/epc_domestic_schema.xml \
    --dry-run

# Apply comments to database
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb
```

### Data Processing

```bash
# Convert CSVs to Hive-partitioned Parquet
uv run python src/staging_csv.py

# Run SQL transformations
duckdb data_lake/mca_env_base.duckdb
> .read src/create_views.sql
> .read src/manual_external_load.sql
```

### Code Quality

```bash
uv run pytest                     # Run test suite
uv run ruff check                 # Run linter
uv run ruff format                # Format code
```

## Architecture Overview

### Medallion Architecture Pattern

- **Landing Zone:** Raw CSVs, Zips, Parquet in `data_lake/landing/`
  - `automated/` - API outputs (EPC, boundaries)
  - `manual/` - Manual downloads (Humaniverse, ONS)
- **Bronze Layer:** DuckDB views on raw files + PostGIS federation
- **Silver Layer:** Cleaned, deduplicated, spatially standardized (EPSG:27700)
- **Gold Layer:** Aggregated analytics-ready data

### Data Ingestion Strategies

1. **Federated PostGIS:** Zero-copy attachment via `postgres_scanner`
2. **Automated APIs:** Python scripts → Parquet (daily/weekly)
3. **Manual Drop Zone:** Download → Rename with date suffix → Drop in `landing/manual/` → SQL glob selects latest

### Spatial Standards

**Critical:** All Silver layer data MUST use **EPSG:27700** (British National Grid) for accurate UK area/distance calculations. Uses DuckDB SPATIAL extension.

## Schema Documentation System

The schema tool is a sophisticated multi-stage pipeline located in `src/tools/`:

### Pipeline Stages

1. **XML Parsing** - Import canonical metadata from curated XML schemas
2. **Database Analysis** - Query `duckdb_columns()`, `duckdb_tables()`
3. **Inference Engine** - Pattern matching with confidence scoring:
   - Suffix patterns: `_cd` → "code", `_nm` → "name", `_dt` → "date"
   - Prefix patterns: `current_` → "Current value of"
   - Exact matches: `uprn` → "Unique Property Reference Number"
4. **View Mapping** - Auto-propagate table comments to dependent views
5. **Manual Overrides** - User edits via interactive editor → `manual_overrides.xml`
6. **SQL Generation** - `COMMENT ON TABLE/COLUMN` statements

### Key Modules

- `src/tools/schema_documenter.py` - CLI entry point (Click)
- `src/tools/comment_editor.py` - Interactive Rich TUI with session management
- `src/tools/parsers/models.py` - Pydantic schema metadata models
- `src/tools/parsers/schema_analyzer.py` - Pattern inference with confidence scoring
- `src/tools/parsers/xml_parser.py` - Flexible XML schema parsing
- `src/tools/generators/comment_generator.py` - SQL statement generation
- `src/tools/generators/view_mapper.py` - View definition parsing & comment propagation
- `src/tools/utils/session_manager.py` - JSON-based session persistence (`.schema_review_session.json`)
- `src/tools/utils/interactive_menu.py` - Rich TUI components

### Configuration Files

- `src/tools/config/pattern_rules.yaml` - Pattern definitions (14 suffixes, 7 prefixes, 15+ exact matches)
- `src/tools/config/settings.yaml` - Default paths, confidence thresholds, output settings

### Comment Priority Hierarchy

Manual overrides (`manual_overrides.xml`) > External XML schemas > Pattern inference

## Python Code Standards

From `agent-docs/python-code-guidelines.md`:

**Mandatory:**

- Python 3.13+ syntax
- Strict type hints on ALL functions: `def func(arg: str) -> int:`
- Union syntax: `str | None` (NOT `Optional[str]`)
- Built-in generics: `list[str]`, `dict[str, int]` (NOT `typing.List/Dict`)
- f-strings for formatting
- `pathlib.Path` for file operations (NOT `os.path`)
- Google-style docstrings
- Pydantic for configs/schemas
- Early returns and guard clauses
- `match/case` for complex branching
- Specific exception handling (NOT bare `except Exception`)

**Ruff Configuration:**

- Line length: 88 characters
- Target: Python 3.12
- Enabled rules: E, W, F, UP, S, B, SIM, I
- Quote style: double
- Auto-format enabled

## Key Files & Entry Points

| File | Purpose |
|------|---------|
| `src/tools/schema_documenter.py` | CLI for schema documentation |
| `src/tools/comment_editor.py` | Interactive comment editor (Rich TUI) |
| `src/extractors/epc_incremental_update.py` | EPC API incremental update CLI |
| `src/extractors/epc_api_client.py` | EPC API client |
| `src/create_views.sql` | Analytics view definitions (232 LOC) |
| `src/manual_external_load.sql` | EPC staging SQL (249 LOC) |
| `src/schemas/config/epc_domestic_certificates_schema.json` | EPC domestic column types |
| `src/schemas/config/epc_non-domestic_certificates_schema.json` | EPC non-domestic column types |
| `src/schemas/documentation/epc_domestic_schema.xml` | Canonical EPC metadata |
| `src/schemas/documentation/manual_overrides.xml` | User edits from interactive editor |
| `src/schemas/documentation/generated_comments.sql` | Output: SQL COMMENT statements |
| `docs/EPC_API_UPDATE_PLAN.md` | EPC incremental update implementation plan |
| `pyproject.toml` | Project metadata & dependencies |
| `ruff.toml` | Code quality rules |

## Important Patterns & Conventions

### Session Management

- Interactive editor uses `.schema_review_session.json` for progress tracking
- Sessions auto-save after each edit
- Resume with `--resume` flag, clear with `--clear-session`

### View Comment Propagation

- View definitions parsed from `duckdb_views()`
- Source tables extracted via SQL parsing
- Comments copied from base tables to matching view columns
- Handles multi-level view chains

### DuckDB System Tables

Query schema metadata using:

- `duckdb_columns()` - Column definitions with comments
- `duckdb_tables()` - Table definitions with comments
- `duckdb_views()` - View definitions (SQL text)

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

- `data_lake/` - Gitignored, contains live database files and data
- `src/` - Source code package
  - `extractors/` - API clients and data extraction (EPC API)
  - `tools/` - Schema documentation toolkit (main codebase)
  - `schemas/` - Schema configurations and documentation
    - `config/` - JSON schema files for column types
    - `reference/` - External reference data (ONSPD, PDFs)
    - `analysis/` - Analysis artifacts (raw column CSVs)
    - `documentation/` - XML schemas and generated SQL
  - `utility/` - **⚠️ DEPRECATED** - Legacy code (use extractors/tools instead)
- `docs/` - Project documentation and planning files
- `notebooks/` - Jupyter notebooks for EDA
- `plots/` - Generated visualizations
- `tests/` - Pytest test suite
- `.serena/` - Agent memory/session data
- `.claude/` - Claude Code CLI commands

## Common Development Tasks

### Adding Pattern Rules

Edit `src/tools/config/pattern_rules.yaml`:

```yaml
suffix_patterns:
  _new_suffix: "description"

exact_matches:
  new_column: "Full description"
```

### Modifying Inference Logic

- Pattern matching: `src/tools/parsers/schema_analyzer.py`
- Confidence scoring: Adjust in `schema_analyzer.py`
- View SQL parsing: `src/tools/generators/view_mapper.py`

### Database Introspection

```sql
-- Get tables with comments
SELECT table_name, comment FROM duckdb_tables() WHERE comment IS NOT NULL;

-- Get columns for table
SELECT column_name, data_type, comment
FROM duckdb_columns()
WHERE table_name = 'your_table' AND comment IS NOT NULL;
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

- httpx 0.27.0+
- requests 2.32.5+

**Testing:**

- pytest 8.3.4+

## Working with the Schema Tool

### Pattern Matching Priority

1. Exact matches (highest confidence)
2. Suffix patterns
3. Prefix patterns
4. Data type conventions
5. Statistical analysis (lowest confidence)

### Interactive Editor Workflow

1. Start: `uv run python -m src.tools.schema_documenter edit-comments -d <db>`
2. Navigate with arrow keys
3. Edit/Keep/Skip each field
4. Auto-saves to `.schema_review_session.json`
5. Generates `manual_overrides.xml`
6. Resume anytime with `--resume`

### View Handling

- **Tables:** Editor reviews ALL columns if no XML schema exists
- **Views:** Editor only reviews `source="fallback"` or `source="computed"` columns
- View mapping automatically copies comments from base tables

### Extending Patterns

Add UK-specific codes to `pattern_rules.yaml`:

- UPRN, USRN (property/street references)
- LSOA, MSOA, OA (census geography)
- Postcode formats
- EPC-specific suffixes (`_energy_rating`, `_improvement_`)
