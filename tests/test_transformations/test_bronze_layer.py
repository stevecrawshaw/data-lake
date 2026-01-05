"""Tests for Bronze layer transformations."""

from pathlib import Path

import duckdb
import pytest

from src.transformations.models import TransformationConfig
from src.transformations.orchestrator import TransformationOrchestrator


class TestBronzeLayerDiscovery:
    """Test suite for Bronze layer module discovery."""

    def test_discovers_all_bronze_modules(self) -> None:
        """Test that all Bronze layer SQL files are discovered."""
        config = TransformationConfig()
        orchestrator = TransformationOrchestrator(config)
        modules = orchestrator.discover_modules()

        # Filter to Bronze layer only
        bronze_modules = {
            name: module for name, module in modules.items() if module.layer == "bronze"
        }

        # Should have exactly 5 Bronze modules
        assert len(bronze_modules) == 5

        # Verify all expected modules are present
        expected_modules = {
            "bronze/boundaries_federated",
            "bronze/boundaries_external",
            "bronze/epc_load",
            "bronze/emissions_load",
            "bronze/census_load",
        }

        assert set(bronze_modules.keys()) == expected_modules

    def test_bronze_module_metadata_from_schema_yaml(self) -> None:
        """Test that module metadata is loaded from _schema.yaml."""
        config = TransformationConfig()
        orchestrator = TransformationOrchestrator(config)
        modules = orchestrator.discover_modules()

        # Check boundaries_federated metadata
        boundaries_fed = modules["bronze/boundaries_federated"]
        assert boundaries_fed.description == "Load UK boundaries from corporate PostGIS database (VPN required)"
        assert boundaries_fed.requires_vpn is True
        assert boundaries_fed.depends_on == []

        # Check epc_load metadata
        epc_load = modules["bronze/epc_load"]
        assert "domestic and non-domestic EPC" in epc_load.description
        assert epc_load.requires_vpn is False
        assert len(epc_load.source_files) == 2  # Domestic + Non-domestic CSVs

    def test_bronze_modules_enabled_by_default(self) -> None:
        """Test that all Bronze modules are enabled by default."""
        config = TransformationConfig()
        orchestrator = TransformationOrchestrator(config)
        modules = orchestrator.discover_modules()

        bronze_modules = {
            name: module for name, module in modules.items() if module.layer == "bronze"
        }

        for module in bronze_modules.values():
            assert module.enabled is True


class TestBronzeLayerValidation:
    """Test suite for Bronze layer source file validation."""

    def test_validation_detects_existing_source_files(self) -> None:
        """Test that validation passes when all source files exist."""
        config = TransformationConfig()
        orchestrator = TransformationOrchestrator(config)
        orchestrator.discover_modules()

        # Get Bronze modules with source files
        bronze_modules = [
            module
            for module in orchestrator.modules.values()
            if module.layer == "bronze" and module.source_files
        ]

        # Should not raise - all files should exist
        orchestrator.validate_sources(bronze_modules)

    def test_validation_source_file_paths(self) -> None:
        """Test that source file paths are correctly specified."""
        config = TransformationConfig()
        orchestrator = TransformationOrchestrator(config)
        orchestrator.discover_modules()

        # Check EPC load module
        epc_module = orchestrator.modules["bronze/epc_load"]
        assert len(epc_module.source_files) == 2

        # Verify paths start with data_lake/ (not ../data_lake/)
        for source_file in epc_module.source_files:
            assert source_file.startswith("data_lake/")
            assert not source_file.startswith("../")

        # Check emissions load module
        emissions_module = orchestrator.modules["bronze/emissions_load"]
        assert len(emissions_module.source_files) == 2

        for source_file in emissions_module.source_files:
            assert source_file.startswith("data_lake/")


class TestBronzeLayerSQL:
    """Test suite for Bronze layer SQL content."""

    def test_boundaries_federated_sql_structure(self) -> None:
        """Test boundaries_federated.sql has expected structure."""
        sql_path = Path("src/transformations/sql/bronze/boundaries_federated.sql")
        assert sql_path.exists()

        sql_content = sql_path.read_text(encoding="utf-8")

        # Should have INSTALL/LOAD SPATIAL
        assert "INSTALL SPATIAL" in sql_content
        assert "LOAD SPATIAL" in sql_content

        # Should attach PostGIS
        assert "ATTACH" in sql_content
        assert "weca_postgres" in sql_content

        # Should create expected tables
        expected_tables = [
            "open_uprn_lep_tbl",
            "codepoint_open_lep_tbl",
            "lsoa_2021_lep_tbl",
            "bdline_ua_lep_diss_tbl",
            "bdline_ua_weca_diss_tbl",
            "bdline_ua_lep_tbl",
            "bdline_ward_lep_tbl",
        ]

        for table in expected_tables:
            assert table in sql_content

    def test_boundaries_external_sql_structure(self) -> None:
        """Test boundaries_external.sql has expected structure."""
        sql_path = Path("src/transformations/sql/bronze/boundaries_external.sql")
        assert sql_path.exists()

        sql_content = sql_path.read_text(encoding="utf-8")

        # Should use ST_Read for ArcGIS REST
        assert "ST_Read" in sql_content
        assert "arcgis.com" in sql_content

        # Should create CA boundary tables
        assert "ca_boundaries_bgc_tbl" in sql_content
        assert "ca_la_lookup_tbl" in sql_content

    def test_epc_load_sql_structure(self) -> None:
        """Test epc_load.sql has expected staging pattern."""
        sql_path = Path("src/transformations/sql/bronze/epc_load.sql")
        assert sql_path.exists()

        sql_content = sql_path.read_text(encoding="utf-8")

        # Should have staging tables for both domestic and non-domestic
        assert "raw_domestic_epc_staging" in sql_content
        assert "raw_non_domestic_epc_staging" in sql_content

        # Should have final tables
        assert "raw_domestic_epc_certificates_tbl" in sql_content
        assert "raw_non_domestic_epc_certificates_tbl" in sql_content

        # Should drop staging tables
        assert "DROP TABLE raw_domestic_epc_staging" in sql_content
        assert "DROP TABLE raw_non_domestic_epc_staging" in sql_content

        # Should have deduplication pattern (MAX LODGEMENT_DATETIME)
        assert "MAX(LODGEMENT_DATETIME)" in sql_content

        # Paths should not have ../ prefix
        assert "'data_lake/landing" in sql_content
        assert "'../data_lake" not in sql_content

    def test_emissions_load_sql_structure(self) -> None:
        """Test emissions_load.sql has expected structure."""
        sql_path = Path("src/transformations/sql/bronze/emissions_load.sql")
        assert sql_path.exists()

        sql_content = sql_path.read_text(encoding="utf-8")

        # Should create both long and wide format tables
        assert "la_ghg_emissions_tbl" in sql_content
        assert "la_ghg_emissions_wide_tbl" in sql_content

        # Should use read_csv for CSV file
        assert "read_csv" in sql_content

        # Should use read_xlsx for Excel file
        assert "read_xlsx" in sql_content

    def test_census_load_sql_structure(self) -> None:
        """Test census_load.sql has expected structure."""
        sql_path = Path("src/transformations/sql/bronze/census_load.sql")
        assert sql_path.exists()

        sql_content = sql_path.read_text(encoding="utf-8")

        # Should create all expected census tables
        expected_tables = [
            "uk_lsoa_tenure_tbl",
            "eng_lsoa_imd_tbl",
            "postcode_centroids_tbl",
            "boundary_lookup_tbl",
        ]

        for table in expected_tables:
            assert table in sql_content

        # Postcode table should have explicit RUC column types (VARCHAR)
        assert "ruc11ind" in sql_content
        assert "ruc21ind" in sql_content


class TestBronzeLayerExecution:
    """Test suite for Bronze layer execution (integration tests)."""

    @pytest.mark.skipif(
        not Path("data_lake/mca_env_base.duckdb").exists(),
        reason="Database file not found",
    )
    def test_bronze_execution_dry_run(self) -> None:
        """Test Bronze layer dry-run execution."""
        config = TransformationConfig()
        orchestrator = TransformationOrchestrator(config)

        # Should not raise
        orchestrator.execute_layer("bronze", dry_run=True)

    @pytest.mark.skipif(
        not Path("data_lake/mca_env_base.duckdb").exists(),
        reason="Database file not found",
    )
    def test_bronze_tables_exist_after_execution(self) -> None:
        """Test that Bronze tables exist in database (assumes already executed)."""
        db_path = Path("data_lake/mca_env_base.duckdb")

        with duckdb.connect(str(db_path), read_only=True) as conn:
            # Check a sample of Bronze tables exist
            tables_to_check = [
                "raw_domestic_epc_certificates_tbl",
                "raw_non_domestic_epc_certificates_tbl",
                "la_ghg_emissions_tbl",
                "uk_lsoa_tenure_tbl",
            ]

            for table in tables_to_check:
                result = conn.execute(
                    f"SELECT COUNT(*) FROM information_schema.tables WHERE table_name = '{table}'"
                ).fetchone()

                assert result[0] == 1, f"Table {table} not found in database"
