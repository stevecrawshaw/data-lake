"""Shared test fixtures for transformation tests."""

from pathlib import Path
from tempfile import TemporaryDirectory

import duckdb
import pytest
import yaml

from src.transformations.models import TransformationConfig


@pytest.fixture
def temp_dir():
    """Create a temporary directory for test files."""
    with TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


@pytest.fixture
def temp_db(temp_dir: Path) -> Path:
    """Create a temporary DuckDB database for testing.

    Args:
        temp_dir: Temporary directory fixture

    Returns:
        Path to the test database
    """
    db_path = temp_dir / "test.duckdb"

    # Create database with a simple test table
    with duckdb.connect(str(db_path)) as conn:
        conn.execute("CREATE TABLE test_table (id INTEGER, name VARCHAR)")
        conn.execute("INSERT INTO test_table VALUES (1, 'test')")

    return db_path


@pytest.fixture
def temp_sql_root(temp_dir: Path) -> Path:
    """Create a temporary SQL root directory with layer structure.

    Args:
        temp_dir: Temporary directory fixture

    Returns:
        Path to the SQL root directory
    """
    sql_root = temp_dir / "sql"
    sql_root.mkdir()

    # Create layer directories
    for layer in ["bronze", "silver", "gold"]:
        (sql_root / layer).mkdir()

    return sql_root


@pytest.fixture
def sample_bronze_sql(temp_sql_root: Path) -> Path:
    """Create a sample Bronze layer SQL file.

    Args:
        temp_sql_root: SQL root directory fixture

    Returns:
        Path to the created SQL file
    """
    sql_file = temp_sql_root / "bronze" / "test_load.sql"
    sql_file.write_text(
        "CREATE OR REPLACE TABLE bronze_test AS SELECT 1 as id, 'bronze' as layer;",
        encoding="utf-8",
    )
    return sql_file


@pytest.fixture
def sample_silver_sql(temp_sql_root: Path) -> Path:
    """Create a sample Silver layer SQL file.

    Args:
        temp_sql_root: SQL root directory fixture

    Returns:
        Path to the created SQL file
    """
    sql_file = temp_sql_root / "silver" / "test_clean.sql"
    sql_file.write_text(
        "CREATE OR REPLACE VIEW silver_test AS SELECT * FROM bronze_test WHERE id = 1;",
        encoding="utf-8",
    )
    return sql_file


@pytest.fixture
def sample_schema_yaml(temp_sql_root: Path) -> Path:
    """Create a sample _schema.yaml file for Bronze layer.

    Args:
        temp_sql_root: SQL root directory fixture

    Returns:
        Path to the created YAML file
    """
    schema_path = temp_sql_root / "bronze" / "_schema.yaml"
    schema_data = {
        "test_load": {
            "description": "Test Bronze data load",
            "depends_on": [],
            "enabled": True,
        }
    }

    with schema_path.open("w") as f:
        yaml.dump(schema_data, f)

    return schema_path


@pytest.fixture
def test_config(temp_db: Path, temp_sql_root: Path) -> TransformationConfig:
    """Create a test configuration.

    Args:
        temp_db: Temporary database fixture
        temp_sql_root: SQL root directory fixture

    Returns:
        TransformationConfig for testing
    """
    return TransformationConfig(
        db_path=temp_db,
        sql_root=temp_sql_root,
    )
