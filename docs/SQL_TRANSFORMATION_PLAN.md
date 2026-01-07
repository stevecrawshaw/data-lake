# SQL Transformation Reorganization Plan

**Status**: 🚧 IN PROGRESS (Phase 4 - Gold Layer)
**Last Updated**: 2026-01-07
**Related**: See `CLAUDE.md` for project context

## Project Status Summary

### ✅ Completed Phases
- **Phase 1**: Setup Structure (Week 1) - DONE
- **Phase 2**: Migrate Bronze Layer (Week 2) - DONE
- **Phase 3**: Migrate Silver Layer (Week 3) - DONE

### 🚧 Current Phase
- **Verification**: Validate Bronze/Silver layers work correctly
  - **Action Required**: Follow `docs/VERIFICATION_PLAN.md` to test transformation system
  - **Blocked Until**: Verification complete

- **Phase 4**: Migrate Gold Layer (Week 4) - WAITING FOR VERIFICATION
  - Gold layer SQL directory exists but is EMPTY
  - Need to create analytics views from `src/create_views.sql`

### ⏳ Remaining Work
- **Phase 5**: Integration & Documentation (Week 4-5) - NOT STARTED

## Overview

Reorganize three monolithic SQL scripts into a modular, testable Python-orchestrated transformation system that follows Medallion Architecture (Bronze → Silver → Gold) best practices.

**Approach**: Extend the successful `epc_incremental_update.py` pattern to create a Python orchestrator that manages layered SQL transformations.

## Current State

### Three SQL Scripts (544 LOC total)

1. **`src/boundaries_staging.sql`** (63 LOC) - Bronze layer
   - Loads boundaries from federated PostGIS (requires VPN)
   - Loads CA/LA boundaries from ArcGIS REST APIs
   - Creates 9 tables (open_uprn_lep_tbl, lsoa_2021_lep_tbl, etc.)
   - Issues: Manual execution, no error handling, not testable

2. **`src/manual_external_load.sql`** (249 LOC) - Bronze layer
   - Loads manual CSVs (EPC domestic/non-domestic, GHG emissions, tenure, IMD, postcodes)
   - Uses explicit column schemas (93 columns for domestic EPC)
   - Deduplication pattern: keeps latest per UPRN using staging tables
   - Creates 8 tables
   - Issues: Hardcoded paths, large inline schemas, no validation

3. **`src/create_views.sql`** (232 LOC) - Silver + Gold mixed
   - Creates macros (geopoint_from_blob for spatial transforms)
   - Creates lookup views (CA + North Somerset union)
   - EPC cleaning (tenure, construction age, spatial joins)
   - Emissions aggregations (per capita by CA)
   - Issues: Mixed layer concerns, complex nested CTEs, debugging commands in production

### Problems to Solve

- ❌ No dependency management (must run in correct order manually)
- ❌ Not testable (no way to validate transformation logic)
- ❌ No error handling or rollback
- ❌ Mixed layer concerns (Silver + Gold in one file)
- ❌ Hardcoded database paths and file locations
- ❌ No idempotency guarantees

## Proposed Architecture

### Directory Structure

```
src/
├── extractors/                    # External data ingestion (existing)
│   ├── epc_incremental_update.py  # ✅ Pattern to replicate
│   ├── epc_api_client.py
│   └── epc_models.py
│
├── transformations/               # NEW: SQL transformation orchestration
│   ├── __init__.py
│   ├── __main__.py                # CLI entry point (~100 LOC)
│   ├── orchestrator.py            # Orchestration logic (~300 LOC)
│   ├── models.py                  # Pydantic config models (~100 LOC)
│   └── sql/                       # SQL organized by Medallion layer
│       ├── bronze/
│       │   ├── _schema.yaml       # Dependency metadata
│       │   ├── boundaries_federated.sql
│       │   ├── boundaries_external.sql
│       │   ├── epc_load.sql
│       │   ├── emissions_load.sql
│       │   └── census_load.sql
│       ├── silver/
│       │   ├── _schema.yaml
│       │   ├── macros.sql         # Shared spatial macros
│       │   ├── boundaries_clean.sql
│       │   ├── epc_domestic_clean.sql
│       │   ├── epc_non_domestic_clean.sql
│       │   └── emissions_clean.sql
│       └── gold/
│           ├── _schema.yaml
│           ├── emissions_aggregates.sql
│           └── epc_analytics.sql
│
└── legacy/                        # OLD: Deprecated scripts (moved after migration)
    ├── boundaries_staging.sql
    ├── manual_external_load.sql
    └── create_views.sql

tests/
└── test_transformations/          # NEW: Transformation tests
    ├── conftest.py                # Shared fixtures
    ├── test_orchestrator.py       # Orchestration logic tests
    ├── test_bronze_layer.py       # Bronze transformation tests
    ├── test_silver_layer.py       # Silver transformation tests (~200 LOC)
    └── test_gold_layer.py         # Gold transformation tests
```

### Layer Organization Principles

**Bronze Layer** (`sql/bronze/`)
- Raw data ingestion only (PostGIS federation, CSV loading)
- `CREATE OR REPLACE TABLE` (idempotent)
- No transformations beyond type casting
- Explicit schemas from JSON config files

**Silver Layer** (`sql/silver/`)
- Cleaning and standardization
- Deduplication, column renaming, spatial reprojection (EPSG:27700)
- `CREATE OR REPLACE VIEW` (idempotent)
- Business logic for derived fields

**Gold Layer** (`sql/gold/`)
- Analytics-ready aggregations
- Joins across domains, GROUP BY aggregations
- Complex metrics and KPIs
- `CREATE OR REPLACE VIEW` (idempotent)

## Key Implementation Components

### 1. Configuration Model (`models.py`)

```python
from pathlib import Path
from pydantic import BaseModel, Field

class TransformationConfig(BaseModel):
    """Configuration for SQL transformations."""

    db_path: Path = Field(default=Path("data_lake/mca_env_base.duckdb"))
    sql_root: Path = Field(default=Path("src/transformations/sql"))
    layers: list[str] = Field(default=["bronze", "silver", "gold"])
    postgres_secret_name: str = "weca_postgres"
    landing_manual: Path = Field(default=Path("data_lake/landing/manual"))
    landing_automated: Path = Field(default=Path("data_lake/landing/automated"))

class SQLModule(BaseModel):
    """Metadata for a single SQL transformation module."""

    name: str
    layer: str  # bronze, silver, gold
    file_path: Path
    depends_on: list[str] = Field(default_factory=list)
    description: str | None = None
    enabled: bool = True
```

### 2. Orchestrator (`orchestrator.py`)

**Core responsibilities:**
- Discover SQL modules from filesystem + YAML metadata
- Resolve dependencies via topological sort
- Execute SQL files in dependency order
- Handle errors with informative messages
- Support dry-run mode for preview
- Validate source files before Bronze layer

**Key methods:**
- `discover_modules()` - Scan sql/ directories and load _schema.yaml
- `execute_layer(layer, dry_run)` - Execute all modules in a layer
- `validate_sources()` - Check PostGIS connection and CSV files exist
- `_sort_by_dependencies()` - Topological sort for execution order

### 3. CLI Interface (`__main__.py`)

```bash
# Run full pipeline
uv run python -m src.transformations all

# Run specific layers
uv run python -m src.transformations bronze
uv run python -m src.transformations silver gold

# Dry-run preview
uv run python -m src.transformations all --dry-run

# Validate sources before running
uv run python -m src.transformations bronze --validate

# Verbose logging
uv run python -m src.transformations all -vv
```

### 4. Dependency Metadata (`_schema.yaml`)

Each layer directory contains `_schema.yaml` defining module metadata:

```yaml
# sql/bronze/_schema.yaml
boundaries_federated:
  description: "Load boundaries from corporate PostGIS"
  depends_on: []
  requires_vpn: true

epc_load:
  description: "Load EPC certificates from manual CSV drop zone"
  depends_on: []
  source_files:
    - "landing/manual/epc_domestic/all-domestic-certificates-single-file/certificates.csv"

# sql/silver/_schema.yaml
epc_domestic_clean:
  description: "Clean domestic EPC certificates"
  depends_on: ["bronze/epc_load", "silver/macros"]

# sql/gold/_schema.yaml
emissions_aggregates:
  description: "Per capita emissions by Combined Authority"
  depends_on: ["silver/emissions_clean", "silver/boundaries_clean"]
```

## Migration Phases (4 Weeks)

### Phase 1: Setup Structure (Week 1)

**Goal**: Create directory structure and core orchestration logic

**Tasks**:
1. Create `src/transformations/` directory structure
2. Implement `models.py` (Pydantic config ~100 LOC)
3. Implement basic `orchestrator.py` (module discovery, execution ~300 LOC)
4. Implement `__main__.py` CLI (~100 LOC)
5. Create initial test fixtures in `tests/test_transformations/conftest.py`

**Validation**:
```bash
# Test CLI works
uv run python -m src.transformations --help

# Test dry-run (should not fail even with no SQL files yet)
uv run python -m src.transformations bronze --dry-run
```

**Deliverables**:
- [x] Working CLI interface with --help, --dry-run, --validate flags
- [x] Config model with sensible defaults
- [x] Orchestrator skeleton with module discovery
- [x] Test infrastructure ready

**Status**: ✅ COMPLETED

---

### Phase 2: Migrate Bronze Layer (Week 2)

**Goal**: Split `boundaries_staging.sql` and `manual_external_load.sql` into modular files

**Tasks**:

1. **Create `sql/bronze/` directory structure**

2. **Split `boundaries_staging.sql` → 2 modules**:
   - `boundaries_federated.sql` - PostGIS federation (VPN required)
   - `boundaries_external.sql` - ArcGIS REST API loads

3. **Split `manual_external_load.sql` → 3 modules**:
   - `epc_load.sql` - Domestic + non-domestic EPC (with staging pattern)
   - `emissions_load.sql` - GHG emissions (long + wide formats)
   - `census_load.sql` - Tenure, IMD, postcode, boundary lookups

4. **Create `sql/bronze/_schema.yaml`** with dependencies

5. **Parametrize hardcoded paths** using TransformationConfig

6. **Test Bronze layer execution**:
   ```bash
   uv run python -m src.transformations bronze --dry-run
   uv run python -m src.transformations bronze --validate
   uv run python -m src.transformations bronze
   ```

7. **Write tests** (`test_bronze_layer.py`):
   - Test module discovery finds all Bronze files
   - Test validation detects missing CSVs
   - Test execution creates expected tables

**Key decisions**:
- Extract EPC column schemas to separate files (already have `epc_domestic_certificates_schema.json`)
- Use `CREATE OR REPLACE TABLE` for idempotency
- Add retry logic for PostGIS connection failures
- Validate CSV file existence before running

**Deliverables**:
- [x] 5 Bronze SQL modules (boundaries_federated, boundaries_external, epc_load, emissions_load, census_load)
- [x] _schema.yaml with metadata
- [x] All Bronze tables created successfully
- [x] Tests verify table creation

**Status**: ✅ COMPLETED

---

### Phase 3: Migrate Silver Layer (Week 3)

**Goal**: Split `create_views.sql` into Silver cleaning modules

**Tasks**:

1. **Create `sql/silver/` directory structure**

2. **Extract from `create_views.sql` → 5 modules**:
   - `macros.sql` - Spatial transformation macro (geopoint_from_blob)
   - `boundaries_clean.sql` - CA/LA lookups with North Somerset union
   - `epc_domestic_clean.sql` - EPC domestic cleaning (tenure, construction age, date extraction)
   - `epc_non_domestic_clean.sql` - EPC non-domestic with spatial joins
   - `emissions_clean.sql` - Emissions with CA/LA joins

3. **Create `sql/silver/_schema.yaml`** with dependencies

4. **Test Silver layer**:
   ```bash
   uv run python -m src.transformations bronze silver --dry-run
   uv run python -m src.transformations bronze silver
   ```

5. **Write comprehensive tests** (`test_silver_layer.py`):
   - Test construction year derivation (ranges, "before YYYY", "YYYY onwards")
   - Test tenure cleaning (normalize variants)
   - Test spatial macro (EPSG:27700 → EPSG:4326 conversion)
   - Test date component extraction

**Key transformations to preserve**:
- Construction year extraction using regex patterns
- Tenure standardization (owner-occupied, social/private rented)
- Construction epoch categorization
- Spatial joins with UPRN table

**Deliverables**:
- [x] 5 Silver SQL modules creating cleaned views
- [x] _schema.yaml with cross-layer dependencies
- [x] All Silver views created successfully
- [x] Tests verify transformation logic (340 LOC tests)

**Status**: ✅ COMPLETED

---

### Phase 4: Migrate Gold Layer (Week 4)

**Goal**: Extract analytics views from `create_views.sql`

**Tasks**:

1. **Create `sql/gold/` directory structure**

2. **Extract from `create_views.sql` → 2 modules**:
   - `emissions_aggregates.sql` - Per capita emissions by CA (nested CTEs)
   - `epc_analytics.sql` - EPC with spatial joins for ODS export

3. **Create `sql/gold/_schema.yaml`**

4. **Test full pipeline**:
   ```bash
   uv run python -m src.transformations all -vv
   ```

5. **Write end-to-end tests** (`test_gold_layer.py`):
   - Test emissions per capita calculations
   - Test view row counts match original
   - Test spatial geopoint format for ODS

6. **Validation**:
   - Compare row counts before/after migration
   - Verify schema comments preserved (using schema_documenter)
   - Test EPC incremental update still works with new views

**Deliverables**:
- [ ] Create `sql/gold/_schema.yaml` with dependencies
- [ ] Extract Gold layer views from `src/create_views.sql`
- [ ] 2+ Gold SQL modules creating analytics views (emissions_aggregates.sql, epc_analytics.sql, etc.)
- [ ] Write end-to-end tests (test_gold_layer.py)
- [ ] Full pipeline runs successfully (`uv run python -m src.transformations all`)
- [ ] Data validation confirms no regressions

**Status**: 🚧 IN PROGRESS - Gold layer directory exists but is EMPTY

---

### Phase 5: Integration & Documentation (Week 4-5)

**Goal**: Finalize integration and documentation

**Tasks**:

1. **Update documentation**:
   - Update `CLAUDE.md` with new transformation workflow
   - Update `README.md` with usage examples
   - Document migration from old scripts

2. **Deprecate old scripts**:
   - Move old SQL files to `src/legacy/`
   - Add deprecation notices
   - Keep old scripts until full validation passes

3. **Schema documentation integration**:
   - Run schema_documenter after transformations
   - Verify view comments propagate correctly
   - Update manual_overrides.xml if needed

4. **Integration with EPC incremental update**:
   ```bash
   # Step 1: Incremental API update (daily)
   uv run python -m src.extractors.epc_incremental_update all

   # Step 2: Refresh Silver/Gold views (automatic - views reference Bronze tables)
   # No action needed - views automatically reflect new Bronze data
   ```

5. **Final validation**:
   - Run full pipeline on clean database
   - Compare all table/view row counts
   - Verify spatial standards (EPSG:27700)
   - Check schema comments present

**Deliverables**:
- [ ] Updated CLAUDE.md with new transformation workflow
- [ ] Updated README.md with usage examples
- [ ] Old scripts moved to src/legacy/ (boundaries_staging.sql, manual_external_load.sql, create_views.sql)
- [ ] Schema documenter integration confirmed
- [ ] Full validation passes
- [ ] Documentation updated in docs/ folder

**Status**: ⏳ NOT STARTED - Waiting for Phase 4 completion

## Critical Files Status

### ✅ Completed Files

1. **`src/transformations/models.py`** (95 LOC) - ✅ DONE
   - Pydantic configuration models (TransformationConfig, SQLModule)

2. **`src/transformations/orchestrator.py`** (339 LOC) - ✅ DONE
   - Core orchestration logic with dependency resolution

3. **`src/transformations/__main__.py`** (145 LOC) - ✅ DONE
   - CLI interface with Click framework

4. **`src/transformations/sql/bronze/`** - ✅ DONE
   - `epc_load.sql` (200 LOC)
   - `boundaries_federated.sql` (48 LOC)
   - `boundaries_external.sql` (20 LOC)
   - `emissions_load.sql` (28 LOC)
   - `census_load.sql` (46 LOC)
   - `_schema.yaml` (45 lines)

5. **`src/transformations/sql/silver/`** - ✅ DONE
   - `epc_domestic_clean.sql` (86 LOC)
   - `epc_non_domestic_clean.sql` (17 LOC)
   - `boundaries_clean.sql` (48 LOC)
   - `emissions_clean.sql` (18 LOC)
   - `macros.sql` (20 LOC)
   - `_schema.yaml` (47 lines)

6. **`tests/test_transformations/`** - ✅ DONE
   - `test_bronze_layer.py` (264 LOC)
   - `test_silver_layer.py` (340 LOC)
   - `test_orchestrator.py` (188 LOC)
   - `conftest.py` (135 LOC)

### 🚧 Files to Create (Phase 4 - Gold Layer)

1. **`src/transformations/sql/gold/_schema.yaml`** - ⏳ TODO
   - Dependencies metadata for Gold layer modules

2. **`src/transformations/sql/gold/emissions_aggregates.sql`** - ⏳ TODO
   - Per capita emissions by Combined Authority
   - Extract from `src/create_views.sql`

3. **`src/transformations/sql/gold/epc_analytics.sql`** - ⏳ TODO
   - EPC analytics views with spatial joins for ODS export
   - Extract from `src/create_views.sql`

4. **`tests/test_transformations/test_gold_layer.py`** - ⏳ TODO
   - End-to-end tests for Gold layer
   - Test emissions calculations, spatial joins, row counts

### ⏳ Files to Modify (Phase 5 - Documentation)

1. **`CLAUDE.md`** - Add transformation workflow section
2. **`README.md`** - Update with new usage examples
3. **Reference in `docs/`** - Add link to SQL_TRANSFORMATION_PLAN.md

### ⏳ Files to Move (Phase 5 - After Validation)

1. `src/boundaries_staging.sql` → `src/legacy/boundaries_staging.sql`
2. `src/manual_external_load.sql` → `src/legacy/manual_external_load.sql`
3. `src/create_views.sql` → `src/legacy/create_views.sql`

## Example: Bronze Layer EPC Load

### Current Code (from `manual_external_load.sql` lines 14-129)

```sql
CREATE OR REPLACE TABLE raw_domestic_epc_staging AS
FROM read_csv(
    '../data_lake/landing/manual/epc_domestic/all-domestic-certificates-single-file/certificates.csv',
    columns = { /* 93 column definitions */ },
    ignore_errors = true
);

CREATE OR REPLACE TABLE raw_domestic_epc_certificates_tbl AS
SELECT c.*
FROM raw_domestic_epc_staging c
INNER JOIN (
    SELECT UPRN, MAX(LODGEMENT_DATETIME) as max_date
    FROM raw_domestic_epc_staging
    GROUP BY UPRN
) latest ON c.UPRN = latest.UPRN AND c.LODGEMENT_DATETIME = latest.max_date;

DROP TABLE raw_domestic_epc_staging;
```

### New Modular Implementation

**File**: `src/transformations/sql/bronze/epc_load.sql`

```sql
-- Bronze Layer: EPC Certificate Loading
-- Purpose: Load domestic and non-domestic EPC certificates from manual CSV drop zone
-- Pattern: Staging table → deduplication by UPRN → keep latest lodgement

-- DOMESTIC CERTIFICATES
CREATE OR REPLACE TABLE raw_domestic_epc_staging AS
FROM read_csv(
    'data_lake/landing/manual/epc_domestic/all-domestic-certificates-single-file/certificates.csv',
    columns = {{ SCHEMA_FROM_JSON }},  -- Reference external schema file
    ignore_errors = true
);

-- Keep only latest certificate per UPRN
CREATE OR REPLACE TABLE raw_domestic_epc_certificates_tbl AS
SELECT c.*
FROM raw_domestic_epc_staging c
INNER JOIN (
    SELECT UPRN, MAX(LODGEMENT_DATETIME) as max_date
    FROM raw_domestic_epc_staging
    GROUP BY UPRN
) latest ON c.UPRN = latest.UPRN AND c.LODGEMENT_DATETIME = latest.max_date;

DROP TABLE raw_domestic_epc_staging;

-- NON-DOMESTIC CERTIFICATES
CREATE OR REPLACE TABLE raw_non_domestic_epc_staging AS
FROM read_csv(
    'data_lake/landing/manual/epc_non_domestic/all-non-domestic-certificates-single-file/certificates.csv',
    columns = {{ SCHEMA_FROM_JSON }},
    ignore_errors = true
);

CREATE OR REPLACE TABLE raw_non_domestic_epc_certificates_tbl AS
SELECT c.*
FROM raw_non_domestic_epc_staging c
INNER JOIN (
    SELECT UPRN, MAX(LODGEMENT_DATETIME) as max_date
    FROM raw_non_domestic_epc_staging
    GROUP BY UPRN
) latest ON c.UPRN = latest.UPRN AND c.LODGEMENT_DATETIME = latest.max_date;

DROP TABLE raw_non_domestic_epc_staging;
```

**Enhancement**: Orchestrator will read schema from JSON and inject into SQL template

## Success Criteria

### Functional Requirements
- [ ] All Bronze tables match current row counts
- [ ] All Silver views match current schema and results
- [ ] All Gold views produce identical results
- [ ] Full pipeline runs without errors
- [ ] Dry-run mode previews without executing
- [ ] Validation detects missing sources

### Non-Functional Requirements
- [ ] Test coverage >80% for transformation logic
- [ ] Execution time <10 minutes for full pipeline
- [ ] Error messages are clear and actionable
- [ ] Logs are structured (using Rich console)
- [ ] Documentation is complete and accurate

### Quality Metrics
- [ ] Zero data loss during migration
- [ ] Schema comments preserved via schema_documenter
- [ ] Spatial standards maintained (EPSG:27700)
- [ ] EPC incremental update integration works
- [ ] All pytest tests pass

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Data loss during migration | Keep old scripts in legacy/ until validation passes |
| PostGIS federation breaks | Test separately, add connection retry logic |
| Performance regression | Benchmark execution time before/after |
| Complex dependencies missed | Use _schema.yaml to explicitly document |
| Test coverage gaps | Require tests for all Silver transformation logic |

## Integration with Existing Tools

### Schema Documentation System
- Run `schema_documenter` after Bronze/Silver/Gold layers complete
- Auto-propagate comments from tables → views
- Use manual_overrides.xml for Gold analytics descriptions

### EPC Incremental Update
- No changes needed (runs independently)
- Bronze tables updated by API script
- Silver/Gold views automatically reflect new data (no rebuild needed)

## Post-Migration Workflow

### Daily Operations

```bash
# 1. Update EPC data from API (as needed)
uv run python -m src.extractors.epc_incremental_update all

# 2. Refresh transformations (Silver/Gold views automatically update)
# No action needed - views are dynamic

# 3. Document schema changes (as needed)
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb
```

### Manual Data Refresh

```bash
# 1. Download new CSV files to data_lake/landing/manual/

# 2. Re-run Bronze layer to load new files
uv run python -m src.transformations bronze

# 3. Silver/Gold views automatically update
# No action needed
```

### Full Pipeline Rebuild

```bash
# Rebuild entire pipeline (if database corruption or major schema change)
uv run python -m src.transformations all -vv
```

## Technical Debt Reduction

**Before Migration**:
- 3 monolithic SQL scripts (544 LOC)
- No tests, no dependency management
- Manual execution, no error handling

**After Migration**:
- 12+ modular SQL files organized by layer
- ~500 LOC Python orchestration with Pydantic configs
- ~400 LOC comprehensive test suite
- CLI-driven with dry-run, validation, logging
- Clear dependency management via YAML metadata
- Integration with existing schema documentation tool

**Net benefit**: Improved maintainability, testability, and reliability while preserving all functionality.
