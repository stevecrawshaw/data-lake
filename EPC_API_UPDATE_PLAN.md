# EPC API Incremental Update - Implementation Plan Reference

**Status**: ✅ APPROVED
**Date**: 2026-01-02

## Plan Location

The detailed implementation plan is saved at:
**`C:\Users\steve.crawshaw\.claude\plans\delegated-waddling-sphinx.md`**

## Quick Summary

Create Python script to incrementally update EPC certificate tables via API (complements existing bulk downloads).

### What It Does
- Queries `raw_domestic_epc_certificates_tbl` and `raw_non_domestic_epc_certificates_tbl`
- Retrieves only NEW records after latest `LODGEMENT_DATE` from EPC API
- Updates database using DuckDB's MERGE INTO statement
- Runs incrementally (NOT replacing bulk downloads)

### Key Technology Decisions
- ✅ **DuckDB Relational API** - Native operations, no Polars dependency
- ✅ **MERGE INTO** - Elegant single-statement upserts
- ✅ **search-after pagination** - Cursor-based, handles unlimited results
- ✅ **CSV response format** - Direct DuckDB compatibility

### Files to Create
```
src/extractors/
├── __init__.py
├── epc_incremental_update.py  (~300 LOC) - Main CLI
├── epc_api_client.py          (~200 LOC) - API client
└── epc_models.py              (~100 LOC) - Config models

tests/
└── test_epc_incremental_update.py (~200 LOC)
```

### Usage Examples
```bash
# Standard usage
uv run python -m src.extractors.epc_incremental_update domestic -vv

# Git Bash on Windows (use winpty for colors)
winpty uv run python -m src.extractors.epc_incremental_update domestic -vv

# Dry-run preview
uv run python -m src.extractors.epc_incremental_update --dry-run

# Update both tables
uv run python -m src.extractors.epc_incremental_update all
```

### Git Bash Compatibility
⚠️ Rich library has color output issues in Git Bash on Windows
**Workaround**: Use `winpty` prefix or switch to Windows Terminal/WSL
**Source**: https://github.com/Textualize/rich/issues/988

### Dependencies (All Existing)
- duckdb>=1.4.0
- httpx>=0.27.0
- pydantic>=2.12.5
- click>=8.3.1
- rich>=14.2.0
- dotenv>=0.9.9

**No new dependencies required**

### Next Steps
1. Implement the three core modules
2. Write comprehensive tests
3. Test with `--dry-run`
4. Run incremental update
5. Schedule for automated runs

---

**For full implementation details, see the complete plan at:**
`C:\Users\steve.crawshaw\.claude\plans\delegated-waddling-sphinx.md`
