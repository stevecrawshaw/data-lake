"""Tests for transformation orchestrator."""

from pathlib import Path

import pytest

from src.transformations.models import SQLModule, TransformationConfig
from src.transformations.orchestrator import TransformationOrchestrator


class TestTransformationOrchestrator:
    """Test suite for TransformationOrchestrator."""

    def test_init_with_default_config(self) -> None:
        """Test orchestrator initialization with default config."""
        orchestrator = TransformationOrchestrator()
        assert orchestrator.config is not None
        assert isinstance(orchestrator.config, TransformationConfig)
        assert not orchestrator._discovery_complete

    def test_init_with_custom_config(self, test_config: TransformationConfig) -> None:
        """Test orchestrator initialization with custom config."""
        orchestrator = TransformationOrchestrator(test_config)
        assert orchestrator.config == test_config
        assert orchestrator.config.db_path == test_config.db_path

    def test_discover_modules_empty_directory(self, test_config: TransformationConfig) -> None:
        """Test module discovery in empty SQL directory."""
        orchestrator = TransformationOrchestrator(test_config)
        modules = orchestrator.discover_modules()

        assert isinstance(modules, dict)
        assert len(modules) == 0
        assert orchestrator._discovery_complete

    def test_discover_modules_with_sql_files(
        self,
        test_config: TransformationConfig,
        sample_bronze_sql: Path,
        sample_silver_sql: Path,
    ) -> None:
        """Test module discovery with SQL files present."""
        orchestrator = TransformationOrchestrator(test_config)
        modules = orchestrator.discover_modules()

        assert len(modules) == 2
        assert "bronze/test_load" in modules
        assert "silver/test_clean" in modules

        bronze_module = modules["bronze/test_load"]
        assert bronze_module.name == "test_load"
        assert bronze_module.layer == "bronze"
        assert bronze_module.enabled

    def test_discover_modules_with_schema_metadata(
        self,
        test_config: TransformationConfig,
        sample_bronze_sql: Path,
        sample_schema_yaml: Path,
    ) -> None:
        """Test module discovery loads metadata from _schema.yaml."""
        orchestrator = TransformationOrchestrator(test_config)
        modules = orchestrator.discover_modules()

        bronze_module = modules["bronze/test_load"]
        assert bronze_module.description == "Test Bronze data load"
        assert bronze_module.depends_on == []

    def test_execute_layer_dry_run(
        self,
        test_config: TransformationConfig,
        sample_bronze_sql: Path,
    ) -> None:
        """Test dry-run mode previews without executing SQL."""
        orchestrator = TransformationOrchestrator(test_config)

        # Dry-run should not raise errors even if SQL would fail
        orchestrator.execute_layer("bronze", dry_run=True)

        # Verify discovery was performed
        assert orchestrator._discovery_complete
        assert len(orchestrator.modules) > 0

    def test_execute_layer_invalid_layer(self, test_config: TransformationConfig) -> None:
        """Test that invalid layer names raise ValueError."""
        orchestrator = TransformationOrchestrator(test_config)

        with pytest.raises(ValueError, match="Invalid layer"):
            orchestrator.execute_layer("invalid_layer")

    def test_sort_by_dependencies_no_deps(
        self,
        test_config: TransformationConfig,
        sample_bronze_sql: Path,
    ) -> None:
        """Test dependency sorting with no dependencies."""
        orchestrator = TransformationOrchestrator(test_config)
        orchestrator.discover_modules()

        layer_modules = {
            name: module
            for name, module in orchestrator.modules.items()
            if module.layer == "bronze"
        }

        sorted_modules = orchestrator._sort_by_dependencies(layer_modules)
        assert len(sorted_modules) == 1
        assert sorted_modules[0].name == "test_load"

    def test_sort_by_dependencies_with_deps(self, temp_sql_root: Path) -> None:
        """Test dependency sorting with dependencies."""
        # Create modules with dependencies
        module_a = SQLModule(
            name="module_a",
            layer="bronze",
            file_path=temp_sql_root / "bronze" / "module_a.sql",
            depends_on=[],
        )

        module_b = SQLModule(
            name="module_b",
            layer="bronze",
            file_path=temp_sql_root / "bronze" / "module_b.sql",
            depends_on=["module_a"],
        )

        modules = {
            "bronze/module_a": module_a,
            "bronze/module_b": module_b,
        }

        orchestrator = TransformationOrchestrator()
        sorted_modules = orchestrator._sort_by_dependencies(modules)

        # module_a should come before module_b
        assert len(sorted_modules) == 2
        assert sorted_modules[0].name == "module_a"
        assert sorted_modules[1].name == "module_b"

    def test_validate_sources_missing_files(self, temp_sql_root: Path) -> None:
        """Test source validation detects missing files."""
        module = SQLModule(
            name="test_module",
            layer="bronze",
            file_path=temp_sql_root / "bronze" / "test.sql",
            source_files=["nonexistent_file.csv"],
        )

        orchestrator = TransformationOrchestrator()

        with pytest.raises(RuntimeError, match="source file"):
            orchestrator.validate_sources([module])

    def test_validate_sources_all_present(self, temp_sql_root: Path, temp_dir: Path) -> None:
        """Test source validation passes when files exist."""
        # Create a test source file
        source_file = temp_dir / "test_source.csv"
        source_file.write_text("col1,col2\n1,2\n", encoding="utf-8")

        module = SQLModule(
            name="test_module",
            layer="bronze",
            file_path=temp_sql_root / "bronze" / "test.sql",
            source_files=[str(source_file)],
        )

        orchestrator = TransformationOrchestrator()

        # Should not raise
        orchestrator.validate_sources([module])

    def test_execute_sql_file(
        self,
        test_config: TransformationConfig,
        sample_bronze_sql: Path,
    ) -> None:
        """Test SQL file execution creates expected table."""
        import duckdb

        orchestrator = TransformationOrchestrator(test_config)
        orchestrator._execute_sql_file(sample_bronze_sql)

        # Verify table was created
        with duckdb.connect(str(test_config.db_path)) as conn:
            result = conn.execute("SELECT * FROM bronze_test").fetchall()
            assert len(result) == 1
            assert result[0][0] == 1  # id
            assert result[0][1] == "bronze"  # layer
