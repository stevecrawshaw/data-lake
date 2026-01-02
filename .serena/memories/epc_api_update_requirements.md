# EPC API Incremental Update - Requirements Summary

## User Requirements
- Create Python script to incrementally update EPC certificate tables via API
- Tables: `raw_domestic_epc_certificates_tbl` and `raw_non_domestic_epc_certificates_tbl`
- Retrieve only NEW records after latest LODGEMENT_DATE in each table
- Download from ALL UK local authorities (not just WECA)
- Use API endpoints, NOT bulk downloads
- Single staging CSV file per certificate type
- Automatic pagination with search-after cursor
- Column name transformation (API lowercase → Database UPPERCASE)
- UPSERT by UPRN (overwrite existing, insert new)

## Key Database Schema Details
**Domestic table:** 93 columns, UPRN as key, LODGEMENT_DATETIME (TIMESTAMP)
**Non-Domestic table:** 30 columns, UPRN as key, LODGEMENT_DATETIME (VARCHAR)

## API Endpoints
- Domestic: `/api/v1/domestic/search`
- Non-Domestic: `/api/v1/non-domestic/search`
- Date filters: from-month, from-year, to-month, to-year
- Pagination: search-after cursor, max 5000 records per page
- Auth: HTTP Basic Auth (credentials in .env)
- Response format: CSV (recommended)

## Codebase Patterns to Follow
- httpx for API calls (not requests)
- dotenv for .env file loading
- DuckDB Python API for database operations
- Polars for DataFrame processing
- Rich for progress bars and logging
- Click for CLI framework
- Type hints on ALL functions
- pathlib.Path for file operations
- Google-style docstrings

## Implementation Location
New directory: `src/extractors/`
- `epc_incremental_update.py` - Main CLI script
- `epc_api_client.py` - API client class
- `epc_models.py` - Pydantic configuration models

## Critical Implementation Points
1. Query MAX(LODGEMENT_DATE) from tables for incremental start point
2. Handle pagination with X-Next-Search-After response header
3. Normalize column names from API (lowercase) to database (UPPERCASE)
4. Manual override: ENVIRONMENTAL_IMPACT_CURRENT → ENVIRONMENT_IMPACT_CURRENT
5. Deduplicate within batch (latest per UPRN by LODGEMENT_DATETIME)
6. UPSERT via DELETE existing UPRNs + INSERT all staging records
7. Dry-run mode for testing without database modifications

## Latest API Data
- Latest certificate: 2025-11-30
- Dataset updated: 2025-12-25
