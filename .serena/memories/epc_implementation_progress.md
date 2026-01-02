# EPC API Incremental Update - Implementation Progress

**Date**: 2026-01-02
**Status**: Core implementation COMPLETE, testing in progress

## Completed Components

### 1. ✅ Directory Structure
Created `src/extractors/` with proper module structure:
- `__init__.py` - Module initialization
- `__main__.py` - Entry point for `python -m` execution

### 2. ✅ Pydantic Models (`epc_models.py`)
- `EPCConfig` class with all configuration parameters
- `from_env()` class method to load credentials from .env
- `CertificateType` constants class
- All fields properly typed with Pydantic validation
- ~100 LOC

### 3. ✅ API Client (`epc_api_client.py`)
- `EPCAPIClient` class with context manager support
- HTTP Basic Auth with base64 encoding
- Automatic pagination with search-after cursor
- CSV response parsing
- Error handling for 401, 429, timeouts
- Rich progress bar with fallback for Git Bash (cp1252 detection)
- ~270 LOC

### 4. ✅ Main CLI (`epc_incremental_update.py`)
- Click-based CLI with commands: domestic, non-domestic, all
- `get_max_lodgement_date()` - Query database for incremental updates
- `normalize_column_names()` - API lowercase → Database UPPERCASE
- `write_staging_csv()` - DuckDB relational API for CSV writing
- `upsert_to_database()` - MERGE INTO implementation
- `update_certificate_type()` - Main orchestration
- Dry-run mode support
- Verbose logging levels
- ~430 LOC

**Total Code**: ~800 LOC across 5 files

## API Testing Results

### Successful Tests
- ✅ Configuration loading from .env
- ✅ API authentication (Basic Auth)
- ✅ Pagination (tested with 100,000+ records fetched across 20 pages)
- ✅ Date filtering (from-month, from-year, to-month, to-year)
- ✅ CSV parsing from API responses
- ✅ Column name normalization

### Known Issues & Fixes

#### Bug 1: Date Parsing
**Error**: `AttributeError: 'datetime.datetime' object has no attribute 'split'`
**Fix**: Click DateTime returns datetime object, convert with `.date()`

#### Bug 2: Git Bash Unicode Encoding
**Error**: `UnicodeEncodeError: 'charmap' codec can't encode character '\u280b'`
**Cause**: Rich progress bar uses unicode (Braille patterns) in cp1252 encoding
**Fix**: Added environment detection - disable Rich progress bar if cp1252 detected
**Workaround**: Use `winpty` or Windows Terminal instead of Git Bash

## DuckDB Integration

### Relational API Usage
- ✅ `con.from_df(records)` - Create relation from list of dicts
- ✅ `.filter('UPRN IS NOT NULL')` - Filter invalid records
- ✅ SQL `QUALIFY ROW_NUMBER() OVER (...)` - Deduplication by UPRN
- ✅ `.write_csv(path)` - Write relation to CSV

### MERGE INTO Implementation
```sql
MERGE INTO target_table AS target
USING temp_staging AS source
ON target.UPRN = source.UPRN
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *
```

## Manual Column Name Overrides
Applied for known schema issues:
- `ENVIRONMENTAL_IMPACT_CURRENT` → `ENVIRONMENT_IMPACT_CURRENT`
- `ENVIRONMENTAL_IMPACT_POTENTIAL` → `ENVIRONMENT_IMPACT_POTENTIAL`

## Next Steps
1. Complete dry-run testing with small date ranges
2. Test actual database UPSERT operations
3. Write comprehensive test suite
4. Document usage examples
5. Schedule for automated runs

## Files Created
```
src/extractors/
├── __init__.py (3 LOC)
├── __main__.py (6 LOC)
├── epc_models.py (100 LOC)
├── epc_api_client.py (270 LOC)
└── epc_incremental_update.py (430 LOC)
```

## Testing Status
- [x] Module imports
- [x] Configuration loading
- [x] API client initialization
- [x] API data fetching (100k+ records)
- [ ] Complete dry-run end-to-end
- [ ] Database MERGE INTO
- [ ] Test suite
- [ ] Production run

## Dependencies Used
All existing from pyproject.toml:
- duckdb (relational API)
- httpx (HTTP client)
- pydantic (validation)
- click (CLI)
- rich (logging/progress with fallback)
- dotenv (env vars)
