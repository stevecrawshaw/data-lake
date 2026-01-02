# EPC API Update Plan - Key Revisions

## User Feedback Addressed

1. **Purpose clarification**: Script COMPLEMENTS bulk downloads (not replaces)
2. **DuckDB relational API**: Use DuckDB's native API instead of Polars
3. **MERGE INTO**: Use elegant MERGE INTO instead of DELETE+INSERT
4. **Git Bash compatibility**: Added Rich library compatibility notes and winpty workaround

## Technical Changes

### From Polars to DuckDB Relational API
- **Old**: Convert to Polars DataFrame, use `.group_by().first()`
- **New**: Use DuckDB's `.filter()`, SQL `QUALIFY ROW_NUMBER()` for deduplication
- **Benefit**: One less dependency, native DuckDB operations

### From DELETE+INSERT to MERGE INTO
- **Old**: DELETE existing UPRNs, then INSERT all
- **New**: Single MERGE INTO statement with WHEN MATCHED/NOT MATCHED
- **Benefit**: Cleaner, single statement, better tracking of inserts vs updates

### Git Bash Compatibility
- Rich library has color output issues in Git Bash on Windows
- Workaround: Use `winpty python -m src.extractors...`
- Alternative: Use Windows Terminal or WSL
- Added fallback logging if Rich fails

## DuckDB MERGE INTO Syntax
```sql
MERGE INTO target_table AS target
USING source_table AS source
ON target.UPRN = source.UPRN
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;
```

## DuckDB Relational API Examples
```python
# Read CSV as relation
rel = duckdb.read_csv("file.csv")

# Filter
rel = rel.filter('UPRN IS NOT NULL')

# Deduplicate with QUALIFY
con.sql("""
    SELECT * FROM rel 
    QUALIFY ROW_NUMBER() OVER (PARTITION BY UPRN ORDER BY LODGEMENT_DATETIME DESC) = 1
""")

# Write CSV
rel.write_csv("output.csv")
```

## Implementation remains in: src/extractors/
- epc_incremental_update.py
- epc_api_client.py
- epc_models.py
