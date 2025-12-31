# Schema Documentation Tool

A Python CLI tool for automatically documenting DuckDB database schemas using SQL `COMMENT` statements.

## Features

- **XML Schema Parsing**: Import canonical metadata from XML schema files
- **Intelligent Inference**: Automatically generate column descriptions using:
  - Pattern matching (suffixes like `_cd`, `_nm`, prefixes like `current_`)
  - Data type conventions
  - Statistical data analysis
- **View Mapping**: Automatically propagate comments from base tables to views
- **Re-runnable**: Idempotent design - safe to run multiple times
- **Flexible Output**: Generate SQL files or apply directly to database

## Installation

The tool is already installed as part of the data-lake project dependencies:

```bash
# Ensure dependencies are installed
uv sync
```

## Quick Start

### 1. Generate Comments (Dry Run)

Generate comments for your database without applying them:

```bash
python -m src.tools.schema_documenter generate \
    --database data_lake/mca_env_base.duckdb \
    --dry-run
```

This will:
- Analyze all tables in the database
- Infer descriptions using pattern matching
- Map comments to views
- Save SQL to `src/schemas/documentation/generated_comments.sql`

### 2. Generate with XML Schemas

If you have canonical XML schemas for specific tables:

```bash
python -m src.tools.schema_documenter generate \
    --database data_lake/mca_env_base.duckdb \
    --xml-schema src/schemas/documentation/epc_domestic_schema.xml \
    --xml-schema src/schemas/documentation/epc_nondom_schema.xml \
    --dry-run
```

### 3. Apply to Database

Once you've reviewed the generated SQL, apply it:

```bash
python -m src.tools.schema_documenter apply \
    --database data_lake/mca_env_base.duckdb \
    --input src/schemas/documentation/generated_comments.sql
```

Or skip the dry-run step and apply directly:

```bash
python -m src.tools.schema_documenter generate \
    --database data_lake/mca_env_base.duckdb \
    # (no --dry-run flag = applies to database)
```

## Commands

### `generate`

Generate COMMENT statements for database schema.

**Options:**
- `-d, --database PATH`: Path to DuckDB database file (required)
- `-x, --xml-schema PATH`: XML schema file(s) - can be specified multiple times
- `-o, --output PATH`: Output SQL file path (default: `src/schemas/documentation/generated_comments.sql`)
- `--dry-run`: Generate SQL without executing
- `-t, --tables TEXT`: Filter specific tables - can be specified multiple times
- `--include-views/--no-views`: Include views (default: yes)
- `-v, --verbose`: Enable debug logging

**Example:**
```bash
python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -t raw_domestic_epc_certificates_tbl \
    -t ca_boundaries_bgc_tbl \
    --dry-run \
    --verbose
```

### `apply`

Apply COMMENT statements to database from a SQL file.

**Options:**
- `-d, --database PATH`: Path to DuckDB database file (required)
- `-i, --input PATH`: SQL file with COMMENT statements (required)
- `--force`: Overwrite existing comments

**Example:**
```bash
python -m src.tools.schema_documenter apply \
    -d data_lake/mca_env_base.duckdb \
    -i src/schemas/documentation/generated_comments.sql
```

### `validate`

Validate comment coverage in database (coming soon).

### `export`

Export existing comments from database as SQL (coming soon).

## Configuration

### Pattern Rules

Edit `src/tools/config/pattern_rules.yaml` to customize pattern matching:

```yaml
suffix_patterns:
  _cd: "code"
  _nm: "name"
  _desc: "description"
  # Add your own patterns

prefix_patterns:
  current_: "Current value of"
  potential_: "Potential value of"

exact_matches:
  uprn: "Unique Property Reference Number"
  postcode: "UK postal code"
  # Add your own exact matches
```

### Settings

Edit `src/tools/config/settings.yaml` to configure:
- Default database paths
- XML schema locations
- Inference parameters (confidence threshold, sample size)
- Output formatting

## XML Schema Format

The tool expects XML files in this format:

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

**Flexible structure** - the parser also supports:
- `<Table>` and `<Column>` (capitalized)
- Name as child element instead of attribute
- Optional constraints

## How It Works

1. **XML Parsing**: If XML schemas are provided, parse them first for canonical metadata
2. **Database Analysis**: Query `duckdb_columns()` and `duckdb_tables()` for structure
3. **Inference**: For tables/columns not in XML:
   - Apply pattern matching rules (suffixes, prefixes, exact matches)
   - Analyze sample data for additional insights
   - Generate confidence scores (0.0-1.0)
4. **View Mapping**:
   - Parse view definitions from `duckdb_views()`
   - Extract source tables
   - Copy matching column comments from base tables
5. **Generation**: Create `COMMENT ON TABLE/COLUMN` statements
6. **Output**: Save to SQL file and/or apply to database

## Architecture

```
src/tools/
├── schema_documenter.py       # CLI entry point
├── parsers/
│   ├── models.py              # Pydantic data models
│   ├── xml_parser.py          # XML schema parser
│   └── schema_analyzer.py     # Pattern matching & inference
├── generators/
│   ├── comment_generator.py   # SQL statement generator
│   └── view_mapper.py         # View-to-table mapper
└── config/
    ├── settings.yaml          # Configuration
    └── pattern_rules.yaml     # Pattern matching rules
```

## Advanced Usage

### Filter Specific Tables

```bash
python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -t raw_domestic_epc_certificates_tbl \
    -t epc_domestic_vw \
    --dry-run
```

### Skip Views

```bash
python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    --no-views \
    --dry-run
```

### Custom Output Path

```bash
python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -o backup/my_comments.sql \
    --dry-run
```

## Querying Comments

Once applied, query comments using DuckDB's system functions:

```sql
-- Get all table comments
SELECT table_name, comment
FROM duckdb_tables()
WHERE comment IS NOT NULL;

-- Get column comments for a specific table
SELECT column_name, data_type, comment
FROM duckdb_columns()
WHERE table_name = 'raw_domestic_epc_certificates_tbl'
  AND comment IS NOT NULL;
```

## Troubleshooting

### "pattern_rules.yaml not found"

Ensure you're running from the project root directory:

```bash
cd C:\Users\steve.crawshaw\projects\data-lake
python -m src.tools.schema_documenter generate ...
```

### XML Parsing Errors

Check XML file structure. The parser is flexible but requires:
- `<table>` elements with `name` attribute or child
- `<column>` elements with `name` attribute or child
- Optional `<description>` elements

Enable verbose logging to see details:

```bash
python -m src.tools.schema_documenter generate -d ... --verbose
```

### Low Confidence Scores

If inferred descriptions have low confidence:
1. Add patterns to `pattern_rules.yaml`
2. Provide XML schemas for important tables
3. Adjust `min_confidence` threshold in settings

## Next Steps

1. **Provide XML Schemas**: Create XML files for your EPC tables with canonical descriptions
2. **Review Generated Comments**: Run with `--dry-run` and review the SQL
3. **Customize Patterns**: Add domain-specific patterns to `pattern_rules.yaml`
4. **Apply to Database**: Run without `--dry-run` to apply comments
5. **Version Control**: Commit the generated SQL file to track documentation changes

## Contributing

To extend the tool:

1. **Add Pattern Rules**: Edit `config/pattern_rules.yaml`
2. **Enhance Inference**: Modify `schema_analyzer.py`
3. **Improve View Mapping**: Update `view_mapper.py` SQL parsing logic
4. **Add Commands**: Extend `schema_documenter.py` CLI

Follow Python code guidelines in `agent-docs/python-code-guidelines.md`.

## License

Part of the data-lake project.
