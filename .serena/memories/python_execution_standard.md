# Python Execution Standard

## Always Use `uv run` for Python Commands

When executing Python scripts or commands in this project, **always use `uv run`** instead of plain `python`.

### Examples

```bash
# Correct
uv run python script.py
uv run python -m module.name

# Incorrect - DO NOT USE
python script.py
python -m module.name
```

### Rationale

- Ensures correct virtual environment activation
- Manages dependencies correctly via uv
- Consistent execution across project
