# SQL Transformation System - Verification Plan

**Purpose**: Validate that the SQL transformation system (Bronze → Silver layers) works correctly before proceeding to Phase 4 (Gold Layer)

**Last Updated**: 2026-01-07

## Prerequisites Checklist

Before running any transformations, verify these are in place.

### Automated Prerequisites Check

**Run the automated verification tool:**

```bash
# Check all prerequisites
uv run python -m src.tools.verify_prerequisites

# Skip VPN/PostGIS check (if not needed)
uv run python -m src.tools.verify_prerequisites --skip-vpn

# Verbose output (show all source files)
uv run python -m src.tools.verify_prerequisites --verbose
```

**What it checks:**
1. ✅ Database file exists and size (offers to create if missing)
2. ✅ All Bronze layer source files from `_schema.yaml`
3. ✅ PostGIS/VPN connectivity (optional)
4. ✅ Python version (≥3.12) and DuckDB version (≥1.4.0)

**Database Auto-Creation:**
- If database doesn't exist, you'll be prompted to create it
- Creates database with required extensions:
  - SPATIAL (for EPSG:27700 transformations)
  - postgres_scanner (for PostGIS federation)
- Use `--create-if-missing` for non-interactive auto-creation

**Expected output:**
- All green OK = ready to proceed
- Red FAIL = fix issues before continuing
- Yellow WARN = warnings (VPN not required for all modules)

---

### Manual Prerequisites Check (Alternative)

If you prefer to check manually:

#### 1. Database File

```bash
# Check if database exists
ls -lh data_lake/mca_env_base.duckdb
```

- If missing, you'll need to create it first
- Expected size: ~7GB (based on CLAUDE.md)

#### 2. Source Data Files

```bash
# Check Bronze layer source files exist
ls -lh data_lake/landing/manual/epc_domestic/all-domestic-certificates-single-file/certificates.csv
ls -lh data_lake/landing/manual/epc_non_domestic/all-non-domestic-certificates-single-file/certificates.csv
ls -lh data_lake/landing/manual/2005-23-uk-local-authority-ghg-emissions-CSV-dataset.csv
ls -lh data_lake/landing/manual/household_tenure21_lsoa21.csv
ls -lh data_lake/landing/manual/imd2025_england_lsoa21.csv
ls -lh data_lake/landing/manual/ONSPD_Online_latest_Postcode_Centroids_.csv
ls -lh data_lake/landing/manual/PCD_OA21_LSOA21_MSOA21_LAD_NOV25_UK_LU.csv
```

#### 3. PostGIS Connection (for boundaries_federated.sql)

```bash
# Test PostGIS connection
duckdb data_lake/mca_env_base.duckdb -c "ATTACH '' AS weca_postgres (TYPE POSTGRES, SECRET weca_postgres);"
```

- Requires VPN connection to corporate PostGIS
- IO Error = VPN not connected
- Secret error = `weca_postgres` not configured

#### 4. Python Environment

```bash
# Verify uv and dependencies
uv run python --version
uv run python -c "import duckdb; print(duckdb.__version__)"
```

---

## Step 1: Test Module Discovery

**Verify orchestrator can find SQL modules:**

```bash
# Dry-run to see what would be executed (no database changes)
uv run python -m src.transformations all --dry-run -vv
```

**Expected output:**
- Should discover 5 Bronze modules
- Should discover 5 Silver modules
- Should show dependency order
- Should NOT error (even if Gold is empty)

**What to check:**
- ✅ All Bronze files detected: boundaries_federated, boundaries_external, epc_load, emissions_load, census_load
- ✅ All Silver files detected: macros, boundaries_clean, epc_domestic_clean, epc_non_domestic_clean, emissions_clean
- ✅ Dependency order is logical (Bronze before Silver)
- ❌ Any file not found errors

---

## Step 2: Validate Source Files

**Check if required source files exist before attempting Bronze layer:**

```bash
# Run Bronze validation (checks CSV files exist, doesn't execute SQL)
uv run python -m src.transformations bronze --validate --dry-run
```

**Expected output:**
- List of source files being checked
- ✅ or ❌ for each file existence

**What to check:**
- ✅ All CSV files in `data_lake/landing/manual/` are found
- ❌ If any are missing, you'll need to download them first
- Note: PostGIS validation may fail if VPN not connected (expected)

---

## Step 3: Test Bronze Layer (Data Loading)

**Run Bronze layer transformations to load raw data:**

```bash
# Execute Bronze layer only
uv run python -m src.transformations bronze -vv
```

**Expected actions:**
1. Connects to DuckDB database
2. Executes `boundaries_federated.sql` (may fail without VPN - that's OK for now)
3. Executes `boundaries_external.sql` (loads from ArcGIS REST APIs)
4. Executes `epc_load.sql` (loads EPC CSVs, deduplicates by UPRN)
5. Executes `emissions_load.sql` (loads GHG emissions data)
6. Executes `census_load.sql` (loads tenure, IMD, postcodes)

**Verification queries after Bronze completes:**

```bash
# Connect to database
duckdb data_lake/mca_env_base.duckdb
```

```sql
-- Check Bronze tables exist and have data
SELECT table_name, estimated_size
FROM duckdb_tables()
WHERE table_name LIKE 'raw_%' OR table_name LIKE '%_tbl'
ORDER BY table_name;

-- Check EPC domestic table
SELECT COUNT(*) as row_count,
       MIN(LODGEMENT_DATE) as earliest,
       MAX(LODGEMENT_DATE) as latest
FROM raw_domestic_epc_certificates_tbl;

-- Check EPC non-domestic table
SELECT COUNT(*) as row_count,
       MIN(LODGEMENT_DATE) as earliest,
       MAX(LODGEMENT_DATE) as latest
FROM raw_non_domestic_epc_certificates_tbl;

-- Check emissions data
SELECT COUNT(*) as row_count
FROM ghg_emissions_long_tbl;

-- Check census/geography data
SELECT COUNT(*) FROM household_tenure_tbl;
SELECT COUNT(*) FROM imd2025_england_lsoa21_tbl;
SELECT COUNT(*) FROM postcode_centroids_tbl;

-- Exit
.quit
```

**What to check:**
- ✅ Tables exist (not empty result set)
- ✅ Row counts are reasonable (millions for EPC, thousands for emissions)
- ✅ Date ranges look correct (EPC should span multiple years)
- ❌ Zero row counts indicate loading failure

---

## Step 4: Test Silver Layer (Cleaning/Transformation)

**Run Silver layer to create cleaned views:**

```bash
# Execute Bronze + Silver layers
uv run python -m src.transformations bronze silver -vv
```

**Verification queries after Silver completes:**

```bash
duckdb data_lake/mca_env_base.duckdb
```

```sql
-- Check Silver views exist
SELECT table_name, view_definition IS NOT NULL as is_view
FROM duckdb_views()
WHERE table_name LIKE '%_clean' OR table_name LIKE '%_vw'
ORDER BY table_name;

-- Check EPC domestic cleaning (should have derived columns)
SELECT
    COUNT(*) as row_count,
    COUNT(DISTINCT construction_age_band) as age_bands,
    COUNT(DISTINCT tenure) as tenure_types
FROM epc_domestic_clean_vw
LIMIT 5;

-- Sample cleaned data
SELECT
    ADDRESS,
    construction_age_band,
    tenure,
    CURRENT_ENERGY_RATING,
    TOTAL_FLOOR_AREA
FROM epc_domestic_clean_vw
LIMIT 5;

-- Check boundaries cleaning
SELECT COUNT(*) FROM boundaries_ca_clean_vw;

-- Check emissions cleaning
SELECT COUNT(*) FROM emissions_clean_vw;

.quit
```

**What to check:**
- ✅ Views are created (not tables)
- ✅ Derived columns populated (construction_age_band, tenure)
- ✅ Sample data looks reasonable
- ❌ Views empty or errors when querying

---

## Step 5: Test EPC Incremental Update Integration

**Verify the EPC incremental update still works with new structure:**

```bash
# Dry-run EPC update to test without API calls
uv run python -m src.extractors.epc_incremental_update domestic --dry-run -vv
```

**Expected output:**
- Should query `raw_domestic_epc_certificates_tbl` for MAX(LODGEMENT_DATE)
- Should show date range it would fetch
- Should NOT error on table access

**If dry-run works, test actual update (requires EPC API credentials):**

```bash
# Real update (fetches from API)
uv run python -m src.extractors.epc_incremental_update domestic -v
```

**Verification:**

```bash
duckdb data_lake/mca_env_base.duckdb
```

```sql
-- Check for new records
SELECT
    COUNT(*) as total_records,
    MAX(LODGEMENT_DATE) as latest_date
FROM raw_domestic_epc_certificates_tbl;

-- Silver view should automatically reflect new data
SELECT
    COUNT(*) as total_records,
    MAX(LODGEMENT_DATE) as latest_date
FROM epc_domestic_clean_vw;

.quit
```

**What to check:**
- ✅ Incremental update runs without errors
- ✅ New records added to Bronze table
- ✅ Silver view automatically shows new records (no rebuild needed)

---

## Step 6: Run Tests

**Execute the test suite to validate transformation logic:**

```bash
# Run all transformation tests
uv run pytest tests/test_transformations/ -v

# Run specific test files
uv run pytest tests/test_transformations/test_bronze_layer.py -v
uv run pytest tests/test_transformations/test_silver_layer.py -v
uv run pytest tests/test_transformations/test_orchestrator.py -v
```

**Expected results:**
- ✅ All tests pass (or mostly pass)
- Test coverage for Bronze, Silver, orchestration logic

**What to check:**
- ✅ No failures in test_orchestrator.py (core logic)
- ✅ Bronze layer tests validate table creation
- ✅ Silver layer tests validate transformations (construction year derivation, tenure cleaning)

---

## Step 7: Full Pipeline Test

**Run the complete pipeline end-to-end:**

```bash
# Full pipeline: Bronze → Silver (Gold is empty, so it won't error)
uv run python -m src.transformations all -vv
```

**Final verification:**

```bash
duckdb data_lake/mca_env_base.duckdb
```

```sql
-- Verify complete pipeline
SELECT
    'Bronze Tables' as layer,
    COUNT(*) as table_count
FROM duckdb_tables()
WHERE table_name LIKE 'raw_%' OR table_name LIKE '%_tbl'

UNION ALL

SELECT
    'Silver Views' as layer,
    COUNT(*) as view_count
FROM duckdb_views()
WHERE table_name LIKE '%_clean_vw' OR table_name LIKE '%_vw';

-- Check data flows through pipeline
SELECT
    'EPC Bronze' as source,
    COUNT(*) as records
FROM raw_domestic_epc_certificates_tbl

UNION ALL

SELECT
    'EPC Silver' as source,
    COUNT(*) as records
FROM epc_domestic_clean_vw;

.quit
```

**What to check:**
- ✅ Bronze and Silver counts match
- ✅ No execution errors
- ✅ Execution time reasonable (<10 minutes per plan)

---

## Troubleshooting Common Issues

### Issue: "Database file not found"

```bash
# Create database manually if needed
duckdb data_lake/mca_env_base.duckdb "SELECT 'DB created';"
```

### Issue: "CSV file not found"

- Download missing files to `data_lake/landing/manual/`
- Verify paths in `_schema.yaml` match actual file locations
- Use `--validate` flag to see which files are missing

### Issue: "PostGIS connection failed"

- Expected if VPN not connected
- Disable `boundaries_federated` module temporarily:

```yaml
# In sql/bronze/_schema.yaml
boundaries_federated:
  enabled: false  # Set to false
```

### Issue: "Table already exists" errors

- Transformation SQL uses `CREATE OR REPLACE` so this shouldn't happen
- If it does, check SQL file syntax

### Issue: Silver views are empty

- Verify Bronze tables populated first
- Check view SQL definitions for errors
- Run Bronze layer again if needed

---

## Success Criteria

**You'll know the system works if:**

1. ✅ Dry-run completes without errors
2. ✅ Bronze layer creates populated tables
3. ✅ Silver layer creates views that query Bronze tables
4. ✅ EPC incremental update can read/write to Bronze tables
5. ✅ Silver views automatically reflect Bronze data changes
6. ✅ Tests pass
7. ✅ Full pipeline runs in reasonable time (<10 min)

**Once verified, you're ready to proceed with Phase 4 (Gold Layer).**

---

## Verification Checklist

Use this checklist to track verification progress:

- [ ] Step 1: Module discovery works (dry-run)
- [ ] Step 2: Source file validation passes
- [ ] Step 3: Bronze layer loads data successfully
- [ ] Step 3: Bronze tables have correct row counts
- [ ] Step 4: Silver layer creates views
- [ ] Step 4: Silver views have derived columns
- [ ] Step 5: EPC incremental update works
- [ ] Step 6: Test suite passes
- [ ] Step 7: Full pipeline runs successfully
- [ ] Step 7: Data flows Bronze → Silver correctly

**Status**: ⏳ NOT STARTED

**Date Started**: ___________

**Date Completed**: ___________

**Notes**:
