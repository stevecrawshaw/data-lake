# EPC API Incremental Update - Approved Implementation Plan

**Status**: ✅ APPROVED by user on 2026-01-02

**Plan Location**: `C:\Users\steve.crawshaw\.claude\plans\delegated-waddling-sphinx.md`

## Implementation Summary

Create Python script to incrementally update EPC certificate tables via API (complements bulk downloads).

### Core Components
- **Location**: `src/extractors/` (new directory)
- **Main script**: `epc_incremental_update.py`
- **API client**: `epc_api_client.py`
- **Models**: `epc_models.py`

### Key Technical Decisions
1. **DuckDB Relational API**: Use native DuckDB operations (NO Polars)
2. **MERGE INTO**: Single statement upsert (NOT DELETE+INSERT)
3. **CSV response format**: Direct DuckDB compatibility
4. **Incremental only**: Query from MAX(LODGEMENT_DATE) + 1 day
5. **UPRN as key**: Overwrite existing, insert new

### API Details
- **Endpoints**: 
  - Domestic: `/api/v1/domestic/search`
  - Non-Domestic: `/api/v1/non-domestic/search`
- **Pagination**: search-after cursor (max 5000/page)
- **Auth**: HTTP Basic (EPC_USERNAME, EPC_PASSWORD from .env)
- **Date filters**: from-month, from-year, to-month, to-year

### DuckDB Operations

**Read & Process**:
```python
rel = duckdb.read_csv("staging.csv")
rel = rel.filter('UPRN IS NOT NULL')
# Dedup with QUALIFY
con.sql("""
    SELECT * FROM rel 
    QUALIFY ROW_NUMBER() OVER (PARTITION BY UPRN ORDER BY LODGEMENT_DATETIME DESC) = 1
""")
rel.write_csv("output.csv")
```

**MERGE INTO Upsert**:
```sql
MERGE INTO raw_domestic_epc_certificates_tbl AS target
USING temp_staging AS source
ON target.UPRN = source.UPRN
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;
```

### CLI Usage
```bash
# Standard
uv run python -m src.extractors.epc_incremental_update domestic -vv

# Git Bash (Windows) - use winpty for Rich colors
winpty uv run python -m src.extractors.epc_incremental_update domestic -vv

# Dry-run
uv run python -m src.extractors.epc_incremental_update --dry-run

# Override start date
uv run python -m src.extractors.epc_incremental_update --from-date 2025-11-01

# Both tables
uv run python -m src.extractors.epc_incremental_update all
```

### Git Bash Compatibility
- Rich library has color issues in Git Bash on Windows
- Workaround: Use `winpty` prefix
- Alternative: Windows Terminal or WSL
- Source: https://github.com/Textualize/rich/issues/988

### Dependencies (All Existing)
- duckdb>=1.4.0 (database + relational API)
- httpx>=0.27.0 (HTTP client)
- pydantic>=2.12.5 (validation)
- click>=8.3.1 (CLI)
- rich>=14.2.0 (logging/progress)
- dotenv>=0.9.9 (env vars)

### Critical Implementation Details

**Column Mapping**:
- API returns lowercase (e.g., `lmk_key`)
- Database expects UPPERCASE (e.g., `LMK_KEY`)
- Manual override: `ENVIRONMENTAL_IMPACT_CURRENT` → `ENVIRONMENT_IMPACT_CURRENT`

**Date Calculation**:
```python
max_date = get_max_lodgement_date(db_path, table_name)
from_date = max_date + timedelta(days=1) if max_date else date(2008, 1, 1)
to_date = date.today()
```

**Tables**:
- `raw_domestic_epc_certificates_tbl` (93 columns)
- `raw_non_domestic_epc_certificates_tbl` (30 columns)

### Success Criteria
- ✅ Incremental updates only (after latest LODGEMENT_DATE)
- ✅ API endpoints (NOT bulk downloads)
- ✅ Automatic pagination with search-after
- ✅ Column name normalization
- ✅ MERGE INTO upserts
- ✅ DuckDB relational API (no Polars)
- ✅ Type hints, Python 3.13+
- ✅ Dry-run mode
- ✅ Comprehensive tests
- ✅ Rich logging with Git Bash notes
- ✅ Complements bulk downloads

### Next Implementation Steps
1. Create `src/extractors/` directory
2. Implement `epc_models.py` (Pydantic config)
3. Implement `epc_api_client.py` (httpx + pagination)
4. Implement `epc_incremental_update.py` (CLI + orchestration)
5. Write tests in `tests/test_epc_incremental_update.py`
6. Test with `--dry-run`
7. Test small date range
8. Run full incremental update

### Files to Create
- `src/extractors/__init__.py`
- `src/extractors/epc_incremental_update.py` (~300 LOC)
- `src/extractors/epc_api_client.py` (~200 LOC)
- `src/extractors/epc_models.py` (~100 LOC)
- `tests/test_epc_incremental_update.py` (~200 LOC)

### Files to Reference
- `src/schemas/epc_domestic_certificates_schema.json` (column types)
- `src/schemas/epc_non-domestic_certificates_schema.json` (column types)
- `src/manual_external_load.sql` (deduplication pattern)
- `src/utility/utils.py` (existing API patterns)
- `.env` (credentials: EPC_USERNAME, EPC_PASSWORD)

**Estimated Total**: ~800 LOC across 5 new files
