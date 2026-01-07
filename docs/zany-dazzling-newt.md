# Interactive Schema Comment Editor - Implementation Plan

## Overview
Build an interactive Python CLI tool to review and edit schema comments for tables/views that lack external XML documentation. The tool will allow users to iteratively review fields, edit descriptions, and save progress across sessions. Output will be stored as `manual_overrides.xml` and automatically integrated into the existing `schema_documenter` workflow.

## User Requirements
- **Tables**: Prompt for ALL columns in tables without external XML schemas
- **Views**: Prompt only for columns with `source="fallback"` OR `source="computed"`
- **UI**: Interactive menu with arrow key navigation, Enter to edit
- **Persistence**: Save progress, allow resume, allow skipping fields
- **Output**: XML file matching `epc_domestic_schema.xml` format at `src/schemas/documentation/manual_overrides.xml`
- **Integration**: Auto-load manual overrides when running `schema_documenter generate`

## Implementation Components

### 1. Session Management (`src/tools/utils/session_manager.py`)

**Purpose**: Track review progress and persist state across sessions

**Key Classes**:
```python
class FieldReviewStatus(BaseModel):
    status: Literal["pending", "reviewed", "skipped", "confirmed"]
    original_description: str
    user_description: str | None = None
    data_type: str
    confidence: float
    source: str
    reviewed_at: datetime | None = None

class SessionState(BaseModel):
    version: str = "1.0"
    database_path: str
    created_at: datetime
    last_updated: datetime
    current_position: dict | None  # entity_name, entity_type, column_index
    fields: dict[str, dict[str, FieldReviewStatus]]  # entity_name -> col_name -> status
    statistics: dict[str, int]  # total, reviewed, skipped, pending

class SessionManager:
    def load_or_create(database_path: Path) -> SessionState
    def save(state: SessionState) -> None
    def mark_reviewed(entity_name, column_name, user_description, metadata) -> None
    def mark_skipped(entity_name, column_name) -> None
    def get_next_pending_field() -> tuple[str, str] | None
    def get_progress_stats() -> dict
```

**Session File**: `.schema_review_session.json` (atomic writes to prevent corruption)

### 2. Interactive UI (`src/tools/utils/interactive_menu.py`)

**Purpose**: Rich CLI interface using questionary for navigation and editing

**Key Classes**:
```python
class InteractiveMenu:
    def display_welcome_banner(database_path, stats) -> None
    def display_progress_panel(stats) -> None
    def select_entity(entities: list[str]) -> str | None
    def select_column(entity_name, columns, session) -> tuple | None
    def review_field(entity_name, column_name, metadata, existing_description) -> FieldReviewAction
    def show_completion_summary(stats, xml_path) -> None

class FieldReviewAction(BaseModel):
    action: Literal["edit", "keep", "skip", "save_quit", "quit_no_save", "back"]
    new_description: str | None = None
```

**UI Features**:
- Rich panels showing entity/column info, data type, source, confidence
- Status indicators: ✓ (reviewed), ⊙ (pending), ⊘ (skipped)
- Progress statistics
- Keyboard shortcuts: Ctrl+S (save), Ctrl+Q (quit)

### 3. XML Generator (`src/tools/generators/xml_generator.py`)

**Purpose**: Generate `manual_overrides.xml` from session state

**Key Class**:
```python
class ManualOverrideXMLGenerator:
    def generate_from_session(session, tables, views) -> None
    def _create_table_element(table_name, metadata, reviewed_columns) -> etree.Element
    def _create_view_element(view_name, metadata, reviewed_columns) -> etree.Element
    def _escape_xml_content(text: str) -> str  # Escape &, <, >, ", '
    def _format_and_write_xml(root: etree.Element) -> None
```

**Output Format** (matching existing schemas):
```xml
<?xml version='1.0' encoding='UTF-8'?>
<schema>
  <table name="table_name">
    <description>Table description</description>
    <column name="column_name">
      <type>VARCHAR</type>
      <description>User-provided description</description>
    </column>
  </table>
</schema>
```

### 4. Main Editor (`src/tools/comment_editor.py`)

**Purpose**: Orchestrate the interactive review workflow

**Key Class**:
```python
class CommentEditor:
    def __init__(database_path, session_file, xml_output)
    def load_schema_metadata() -> tuple[list[TableMetadata], list[ViewMetadata]]
    def filter_fields_for_review(tables, views) -> dict[str, list[ColumnMetadata]]
    def start_interactive_session(fields_to_review) -> None
    def save_xml_output() -> None

    # Helper methods
    def _parse_generated_comments() -> dict  # Extract existing descriptions
    def _build_review_queue() -> list
    def _review_field(entity_name, column_name, metadata) -> None
```

**Filtering Logic**:
- **Tables**: Include ALL columns where `table.source != "xml"`
- **Views**: Include columns where `column.source in ("fallback", "computed")`

**CLI Command**:
```python
@click.command()
@click.option("--database", "-d", required=True, type=Path)
@click.option("--resume", is_flag=True, help="Resume previous session")
@click.option("--clear-session", is_flag=True, help="Clear and start fresh")
def edit(database, resume, clear_session) -> None:
    """Interactive schema comment editor."""
```

### 5. Integration with `schema_documenter.py`

**Modifications**:

1. **Add CLI command** (after line 47):
```python
@cli.command()
@click.option("--database", "-d", required=True, type=Path)
@click.option("--resume", is_flag=True)
@click.option("--clear-session", is_flag=True)
def edit_comments(database, resume, clear_session) -> None:
    """Launch interactive comment editor."""
    from .comment_editor import CommentEditor
    editor = CommentEditor(database_path=database)
    if clear_session:
        editor.clear_session()
    editor.run(resume=resume)
```

2. **Auto-load manual overrides** (after line 160 in `generate()`):
```python
# Load manual overrides if present
manual_overrides_path = Path("src/schemas/documentation/manual_overrides.xml")
if manual_overrides_path.exists():
    logger.info("Loading manual schema overrides...")
    manual_tables = parse_xml_schema(manual_overrides_path)

    # Merge with priority: manual > external XML > inferred
    for manual_table in manual_tables:
        existing_idx = next(
            (i for i, t in enumerate(all_tables)
             if t.name.upper() == manual_table.name.upper()),
            None
        )
        if existing_idx is not None:
            all_tables[existing_idx] = merge_table_metadata(
                all_tables[existing_idx], manual_table
            )
        else:
            all_tables.append(manual_table)
```

3. **Add merge helper function**:
```python
def merge_table_metadata(base: TableMetadata, override: TableMetadata) -> TableMetadata:
    """Merge metadata with manual override priority."""
    override_cols = {c.name.upper(): c for c in override.columns}
    base_cols = {c.name.upper(): c for c in base.columns}

    merged_columns = []
    for col_name, col in base_cols.items():
        merged_columns.append(override_cols.get(col_name, col))

    # Add new columns from override
    for col_name, col in override_cols.items():
        if col_name not in base_cols:
            merged_columns.append(col)

    return TableMetadata(
        name=base.name,
        description=override.description,
        columns=merged_columns,
        schema_name=base.schema_name,
        table_type=base.table_type,
        source="manual_override",
    )
```

### 6. Dependencies (`pyproject.toml`)

Add:
```toml
dependencies = [
    # ... existing ...
    "questionary>=2.0.1",  # Interactive CLI prompts
]
```

## Implementation Sequence

### Phase 1: Core Infrastructure
1. ✅ Create `src/tools/utils/session_manager.py`
   - Pydantic models for session state
   - JSON persistence with atomic writes
   - Progress tracking methods

2. ✅ Create `src/tools/utils/interactive_menu.py`
   - Rich console components
   - questionary integration
   - Field review UI

3. ✅ Update `pyproject.toml` and run `uv sync`

### Phase 2: Main Editor
4. ✅ Create `src/tools/comment_editor.py`
   - Load database schema
   - Parse `generated_comments.sql` for existing descriptions
   - Filter fields for review
   - Interactive session loop

### Phase 3: XML Generation
5. ✅ Create `src/tools/generators/xml_generator.py`
   - Generate XML matching `epc_domestic_schema.xml` format
   - XML escaping and validation
   - Pretty-print output

### Phase 4: Integration
6. ✅ Modify `src/tools/schema_documenter.py`
   - Add `edit-comments` command
   - Auto-load `manual_overrides.xml`
   - Merge logic for manual > XML > inferred priority

### Phase 5: Testing & Documentation
7. ✅ Test complete workflow
8. ✅ Update `src/tools/README.md` with usage examples

## Error Handling

- **KeyboardInterrupt**: Save session before exit
- **Session corruption**: Backup and start fresh
- **Database errors**: Display error, allow retry
- **XML validation**: Check well-formedness before write
- **Atomic writes**: Use temp file + rename for crash safety

## User Workflow

```bash
# Start new session
uv run python -m src.tools.schema_documenter edit-comments -d data_lake/mca_env_base.duckdb

# Resume previous session
uv run python -m src.tools.schema_documenter edit-comments -d data_lake/mca_env_base.duckdb --resume

# Clear and restart
uv run python -m src.tools.schema_documenter edit-comments -d data_lake/mca_env_base.duckdb --clear-session

# Generate with manual overrides (automatic if file exists)
uv run python -m src.tools.schema_documenter generate \
    -d data_lake/mca_env_base.duckdb \
    -x src/schemas/documentation/epc_domestic_schema.xml \
    --dry-run
```

## Critical Files

**To Create**:
- `src/tools/utils/session_manager.py` - Session state management
- `src/tools/utils/interactive_menu.py` - Rich CLI UI
- `src/tools/comment_editor.py` - Main editor orchestration
- `src/tools/generators/xml_generator.py` - XML output generation

**To Modify**:
- `src/tools/schema_documenter.py` - Add command, auto-load overrides
- `pyproject.toml` - Add questionary dependency

**Output Files**:
- `.schema_review_session.json` - Session state (gitignored)
- `src/schemas/documentation/manual_overrides.xml` - User-edited comments

**Key Existing Files** (for reference):
- `src/tools/parsers/models.py` - ColumnMetadata, TableMetadata, ViewMetadata
- `src/tools/parsers/xml_parser.py` - XML parsing patterns
- `src/tools/generators/view_mapper.py` - View column source detection
- `src/schemas/documentation/epc_domestic_schema.xml` - XML format example
- `src/schemas/documentation/generated_comments.sql` - Existing comments to parse
