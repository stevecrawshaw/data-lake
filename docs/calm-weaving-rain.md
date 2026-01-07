# Schema Documentation System - Implementation Plan

## 🎯 Objective

Create a robust, re-runnable Python CLI tool that automatically documents DuckDB database schemas using SQL COMMENT statements, with intelligent comment generation from XML schemas and data analysis.

## 📋 Requirements Summary

- **Primary Goal**: Use `COMMENT ON TABLE/COLUMN` for self-contained database documentation
- **XML Integration**: Parse canonical EPC schema XML files (domestic & non-domestic)
- **Intelligent Inference**: Generate descriptions for non-EPC tables by analyzing data patterns
- **View Mapping**: Automatically propagate comments from base tables to views
- **Robustness**: Re-runnable, idempotent, handles new tables/views gracefully
- **Code Quality**: Follow strict Python 3.10+ standards from `agent-docs/python-code-guidelines.md`

## 🏗️ Architecture Overview

### Tool Components

```
src/tools/
├── schema_documenter.py          # Main CLI entry point
├── parsers/
│   ├── __init__.py
│   ├── xml_parser.py             # Parse EPC XML schemas
│   └── schema_analyzer.py        # Analyze DB structure & infer descriptions
├── generators/
│   ├── __init__.py
│   ├── comment_generator.py      # Generate COMMENT ON statements
│   └── view_mapper.py            # Map table comments to views
└── config/
    ├── __init__.py
    └── view_mappings.py          # View-to-table relationship registry
```

### Supporting Files

```
src/schemas/
├── documentation/
│   ├── epc_domestic_schema.xml   # Canonical EPC domestic schema (user-provided)
│   ├── epc_nondom_schema.xml     # Canonical EPC non-domestic schema (user-provided)
│   └── generated_comments.sql    # Generated COMMENT statements (output)
```

## 🗺️ Implementation Roadmap

### Phase 1: Core Infrastructure (Agent: Python Developer)
**Deliverables**: CLI framework, configuration management

1. Create `src/tools/schema_documenter.py` with Click CLI framework
2. Set up logging (using standard library `logging`)
3. Create configuration system for database paths and mappings
4. Add database connection utilities (DuckDB context managers)

**Key Features**:
- CLI commands: `generate`, `apply`, `validate`, `export`
- Configuration file: `src/tools/config/settings.yaml`
- Database path resolution (support attached databases)

### Phase 2: XML Schema Parser (Agent: Data Parser)
**Deliverables**: XML-to-metadata converter

1. Create `src/tools/parsers/xml_parser.py`
2. Define Pydantic models for schema metadata:
   ```python
   class ColumnMetadata(BaseModel):
       name: str
       data_type: str
       description: str
       constraints: list[str] | None = None

   class TableMetadata(BaseModel):
       name: str
       description: str
       columns: list[ColumnMetadata]
   ```
3. Parse XML files to extract table/column descriptions
4. Handle missing or malformed XML gracefully

**Input XML Expected Format** (to be confirmed with user):
```xml
<table name="raw_domestic_epc_certificates_tbl">
    <description>Domestic Energy Performance Certificate data</description>
    <column name="LMK_KEY">
        <type>VARCHAR</type>
        <description>Unique Lodgement Key identifier</description>
    </column>
    ...
</table>
```

### Phase 3: Schema Analyzer (Agent: Data Analyst)
**Deliverables**: Intelligent description inference for non-XML tables

1. Create `src/tools/parsers/schema_analyzer.py`
2. Query `duckdb_columns()` to get table/column metadata
3. Implement inference strategies:
   - **Pattern Matching**: `*_cd` → "Code", `*_nm` → "Name", `uprn` → "Unique Property Reference Number"
   - **Data Analysis**: Sample 1000 rows, analyze:
     - Value distributions (categorical vs numeric)
     - Uniqueness ratio (likely primary key?)
     - Null percentage
     - Min/max values for dates/numbers
   - **Column Name Parsing**: Convert snake_case to human-readable (e.g., `LODGEMENT_DATE` → "Date of certificate lodgement")
4. Generate quality scores for inferred descriptions
5. Support manual override via YAML config file

**Example Inference Logic**:
```python
def infer_description(
    column_name: str,
    data_type: str,
    sample_data: pl.DataFrame
) -> tuple[str, float]:
    """
    Returns: (description, confidence_score)
    """
    # Pattern-based rules
    if column_name.upper().endswith('_CD'):
        return (f"{humanize(column_name[:-3])} code", 0.9)

    # Data-driven analysis
    if data_type == 'DATE':
        return (f"Date of {humanize(column_name)}", 0.7)

    # Fallback
    return (humanize(column_name), 0.5)
```

### Phase 4: View Mapping System (Agent: SQL Developer)
**Deliverables**: Automatic view-to-table relationship detection

1. Create `src/tools/generators/view_mapper.py`
2. Parse `create_views.sql` to extract view definitions
3. Analyze view SQL to determine source tables:
   - Use DuckDB's `duckdb_views()` system function
   - Parse `SELECT ... FROM <table>` patterns
   - Handle JOINs (prioritize primary source table)
4. Create mapping registry:
   ```python
   VIEW_MAPPINGS = {
       'epc_domestic_vw': {
           'source_table': 'raw_domestic_epc_certificates_tbl',
           'type': 'transform',  # vs 'filter', 'join'
           'comment_strategy': 'copy_all'
       },
       'epc_domestic_lep_vw': {
           'source_table': 'raw_domestic_epc_certificates_tbl',
           'type': 'join',
           'comment_strategy': 'copy_matching'
       }
   }
   ```
5. Generate COMMENT statements for views based on:
   - View columns matching table columns → copy comment
   - Computed columns → generate descriptive comment
   - Renamed columns → reference original + explain transform

### Phase 5: Comment Generator (Agent: SQL Generator)
**Deliverables**: SQL statement generator

1. Create `src/tools/generators/comment_generator.py`
2. Generate `COMMENT ON TABLE` statements
3. Generate `COMMENT ON COLUMN` statements
4. Handle SQL string escaping (single quotes → `''`)
5. Support dry-run mode (output SQL without execution)
6. Implement idempotency checks:
   ```python
   def should_update_comment(
       existing: str | None,
       generated: str,
       force: bool = False
   ) -> bool:
       if force:
           return True
       if existing is None or existing == '':
           return True
       # Don't overwrite manual comments
       return False
   ```

### Phase 6: CLI Integration & Testing (Agent: Integration)
**Deliverables**: Complete CLI tool with tests

1. Wire all components into CLI commands
2. Add progress bars (using `rich` library)
3. Create comprehensive logging
4. Write pytest tests:
   - Unit tests for parsers, analyzers, generators
   - Integration test with sample database
5. Add validation command to check comment coverage

## 📝 Detailed Task Breakdown

### Task 1: Project Setup
- [ ] Create `src/tools/` directory structure
- [ ] Add dependencies via `uv add`:
  - `click` (CLI framework)
  - `rich` (progress bars, formatting)
  - `pyyaml` (already installed - configuration)
  - `lxml` (XML parsing)
- [ ] Create empty `__init__.py` files
- [ ] Set up logging configuration

**Agent Assignment**: General Python Developer

### Task 2: XML Schema Parser
- [ ] Define Pydantic models for metadata
- [ ] Implement XML parser with error handling
- [ ] Add XML validation (check against expected structure)
- [ ] Create test fixtures with sample XML
- [ ] Write unit tests

**Agent Assignment**: Data Parser Specialist

### Task 3: Schema Analyzer
- [ ] Implement column name humanization
- [ ] Create pattern-matching rules database
- [ ] Add data sampling and analysis logic
- [ ] Implement confidence scoring
- [ ] Write unit tests with mock data
- [ ] Create YAML override config format

**Agent Assignment**: Data Analyst / ML Engineer

### Task 4: View Mapper
- [ ] Parse `create_views.sql` file
- [ ] Query `duckdb_views()` for view metadata
- [ ] Extract source table relationships
- [ ] Build view-to-table mapping registry
- [ ] Handle edge cases (multiple sources, complex JOINs)
- [ ] Write integration tests

**Agent Assignment**: SQL/Database Specialist

### Task 5: Comment Generator
- [ ] Implement SQL escaping utilities
- [ ] Create COMMENT statement templates
- [ ] Add idempotency logic (check existing comments)
- [ ] Implement batch generation (all tables/views)
- [ ] Add dry-run mode
- [ ] Write unit tests

**Agent Assignment**: SQL Generator Specialist

### Task 6: CLI Development
- [ ] Create Click command groups:
  - `schema-doc generate` - Generate comments
  - `schema-doc apply` - Apply to database
  - `schema-doc validate` - Check coverage
  - `schema-doc export` - Export as SQL file
- [ ] Add command-line options:
  - `--database` - Database path
  - `--xml-schema` - XML schema file(s)
  - `--dry-run` - Preview without applying
  - `--force` - Overwrite existing comments
  - `--tables` - Filter specific tables
  - `--views` - Include views
- [ ] Implement rich progress indicators
- [ ] Add verbose logging option

**Agent Assignment**: CLI Developer

### Task 7: Integration Testing
- [ ] Create test DuckDB database
- [ ] Add sample tables with various data types
- [ ] Create test views
- [ ] Write end-to-end tests
- [ ] Test idempotency (run twice, same result)
- [ ] Test error handling (malformed XML, missing tables)

**Agent Assignment**: QA / Integration Engineer

### Task 8: Documentation
- [ ] Create `README.md` in `src/tools/`
- [ ] Write usage examples
- [ ] Document XML schema format
- [ ] Document YAML override format
- [ ] Add troubleshooting guide

**Agent Assignment**: Technical Writer

## 🔄 Workflow Example

### User Workflow
```bash
# 1. Generate comments (dry-run)
python -m src.tools.schema_documenter generate \
    --database data_lake/mca_env_base.duckdb \
    --xml-schema src/schemas/documentation/epc_domestic_schema.xml \
    --xml-schema src/schemas/documentation/epc_nondom_schema.xml \
    --dry-run \
    --output src/schemas/documentation/generated_comments.sql

# 2. Review generated SQL
cat src/schemas/documentation/generated_comments.sql

# 3. Apply to database
python -m src.tools.schema_documenter apply \
    --database data_lake/mca_env_base.duckdb \
    --input src/schemas/documentation/generated_comments.sql

# 4. Validate coverage
python -m src.tools.schema_documenter validate \
    --database data_lake/mca_env_base.duckdb \
    --report coverage_report.txt
```

### System Workflow
```
1. Parse XML schemas → TableMetadata objects
2. Analyze database structure → Table/column lists
3. For each table:
   a. If XML metadata exists → use it
   b. Else → infer from patterns + data analysis
4. For each view:
   a. Identify source table(s)
   b. Map matching columns
   c. Generate view-specific comments
5. Generate COMMENT ON statements
6. (Optional) Apply to database
7. Export SQL file for version control
```

## 🎛️ Configuration Files

### `src/tools/config/settings.yaml`
```yaml
database:
  default_path: "data_lake/mca_env_base.duckdb"
  attached_databases:
    - name: "mca_data"
      path: "md:mca_data"  # MotherDuck

xml_schemas:
  - table: "raw_domestic_epc_certificates_tbl"
    xml_path: "src/schemas/documentation/epc_domestic_schema.xml"
  - table: "raw_non_domestic_epc_certificates_tbl"
    xml_path: "src/schemas/documentation/epc_nondom_schema.xml"

inference:
  enabled: true
  confidence_threshold: 0.6
  sample_size: 1000

view_mappings:
  auto_detect: true
  view_definitions_file: "src/create_views.sql"

overrides:
  # Manual overrides for specific columns
  raw_domestic_epc_certificates_tbl:
    UPRN: "Unique Property Reference Number - UK-wide unique property identifier"

output:
  sql_file: "src/schemas/documentation/generated_comments.sql"
  format: "pretty"  # or "compact"
```

### `src/tools/config/pattern_rules.yaml`
```yaml
# Pattern-based description rules
suffix_patterns:
  _cd: "code"
  _nm: "name"
  _desc: "description"
  _dt: "date"
  _flag: "flag (Y/N)"
  _count: "count"
  _pct: "percentage"
  _id: "identifier"

prefix_patterns:
  current_: "Current value of"
  potential_: "Potential value of"
  total_: "Total"

exact_matches:
  uprn: "Unique Property Reference Number"
  lmk_key: "Lodgement Management Key"
  postcode: "UK postal code"
  lsoa: "Lower Layer Super Output Area code"
  msoa: "Middle Layer Super Output Area code"
  oa: "Output Area code"
```

## 🧪 Testing Strategy

### Unit Tests
- XML parser with valid/invalid XML
- Pattern matching rules
- Data inference logic
- SQL statement generation
- String escaping

### Integration Tests
- End-to-end workflow with test database
- View mapping accuracy
- Idempotency verification
- Error recovery

### Manual Validation
- Review generated comments for accuracy
- Verify no SQL injection risks
- Check handling of special characters in data

## 📊 Success Criteria

- ✅ All tables have `COMMENT ON TABLE` statements
- ✅ All columns have meaningful `COMMENT ON COLUMN` statements
- ✅ Views inherit or generate appropriate comments
- ✅ Tool is re-runnable without errors or duplicates
- ✅ Generated SQL is version-controlled
- ✅ Confidence scores help identify low-quality descriptions
- ✅ Manual overrides work correctly
- ✅ Code passes Ruff linting (no warnings)
- ✅ All functions have type hints and docstrings
- ✅ Test coverage > 80%

## 🚀 Implementation Order (Recommended)

1. **Week 1**: Tasks 1, 2, 3 (Setup, XML Parser, Schema Analyzer)
2. **Week 2**: Tasks 4, 5 (View Mapper, Comment Generator)
3. **Week 3**: Tasks 6, 7 (CLI, Integration Tests)
4. **Week 4**: Task 8, Polish (Documentation, Refinement)

## 📁 Critical Files

### To Be Created
- `src/tools/schema_documenter.py` (main CLI)
- `src/tools/parsers/xml_parser.py`
- `src/tools/parsers/schema_analyzer.py`
- `src/tools/generators/comment_generator.py`
- `src/tools/generators/view_mapper.py`
- `src/tools/config/settings.yaml`
- `src/tools/config/pattern_rules.yaml`
- `tests/test_schema_documenter.py`

### To Be Modified
- `pyproject.toml` (via `uv add` commands - new dependencies)
- `.gitignore` (add `src/schemas/documentation/*.sql` if needed)

### To Be Referenced
- `src/create_views.sql` (existing - view definitions)
- `src/utility/utils.py` (existing - reference for code patterns)
- `agent-docs/python-code-guidelines.md` (existing - code standards)

## 🤔 Open Questions for User

1. **XML Schema Format**: Can you share a sample of the XML schema structure? This will help validate the parser design.

2. **Comment Update Strategy**: When re-running the tool, should it:
   - Only add missing comments (safe)
   - Update all comments if XML/inference changes (aggressive)
   - Require `--force` flag to overwrite existing comments (recommended)

3. **Computed Columns**: For derived columns in views (e.g., `NOMINAL_CONSTRUCTION_YEAR` in `epc_domestic_vw`), should the tool:
   - Generate description from the SQL logic
   - Use a template like "Computed field: [column_name]"
   - Require manual descriptions in overrides file

## 🎯 Next Steps

1. **User provides XML schema files** → Place in `src/schemas/documentation/`
2. **Review this plan** → Confirm approach and answer open questions
3. **Begin Phase 1** → Create project structure and CLI framework
4. **Iterative development** → Build and test each component
5. **Integration** → Wire all components together
6. **Validation** → Test on full database and refine

---

**Plan Status**: Ready for Review
**Estimated Effort**: 3-4 weeks (part-time) / 1-2 weeks (full-time)
**Risk Level**: Low (well-defined scope, mature technologies)
**Dependencies**: User-provided XML schemas
