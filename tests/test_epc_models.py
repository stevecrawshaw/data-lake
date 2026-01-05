"""Tests for EPC Pydantic models and configuration."""

from pathlib import Path

import pytest
from pydantic import ValidationError

from src.extractors.epc_models import CertificateType, EPCConfig


class TestEPCConfig:
    """Tests for EPCConfig Pydantic model."""

    def test_default_values(self) -> None:
        """Test that EPCConfig initializes with correct defaults."""
        config = EPCConfig(username="test_user", password="test_pass")

        assert config.db_path == Path("data_lake/mca_env_base.duckdb")
        assert config.base_url == "https://epc.opendatacommunities.org"
        assert config.domestic_endpoint == "/api/v1/domestic/search"
        assert config.non_domestic_endpoint == "/api/v1/non-domestic/search"
        assert config.page_size == 5000
        assert config.max_records_per_batch == 100000
        assert config.staging_dir == Path("data_lake/landing/automated")
        assert config.domestic_table == "raw_domestic_epc_certificates_tbl"
        assert config.non_domestic_table == "raw_non_domestic_epc_certificates_tbl"

    def test_custom_values(self) -> None:
        """Test that EPCConfig accepts custom values."""
        config = EPCConfig(
            username="custom_user",
            password="custom_pass",
            db_path=Path("/custom/path/db.duckdb"),
            page_size=1000,
            max_records_per_batch=50000,
        )

        assert config.username == "custom_user"
        assert config.password == "custom_pass"
        assert config.db_path == Path("/custom/path/db.duckdb")
        assert config.page_size == 1000
        assert config.max_records_per_batch == 50000

    def test_page_size_validation(self) -> None:
        """Test that page_size is validated to be <= 5000."""
        # Valid page size
        config = EPCConfig(username="test", password="test", page_size=5000)
        assert config.page_size == 5000

        # Invalid page size (exceeds maximum)
        with pytest.raises(ValidationError) as exc_info:
            EPCConfig(username="test", password="test", page_size=6000)

        assert "less than or equal to 5000" in str(exc_info.value)

    def test_required_fields(self) -> None:
        """Test that username and password are required."""
        # Missing username
        with pytest.raises(ValidationError) as exc_info:
            EPCConfig(password="test")  # type: ignore[call-arg]

        assert "username" in str(exc_info.value)

        # Missing password
        with pytest.raises(ValidationError) as exc_info:
            EPCConfig(username="test")  # type: ignore[call-arg]

        assert "password" in str(exc_info.value)

    def test_from_env_success(self, mock_env_file: Path) -> None:
        """Test loading config from .env file successfully."""
        config = EPCConfig.from_env(mock_env_file)

        assert config.username == "test_user"
        assert config.password == "test_password_123"
        assert config.db_path == Path("data_lake/mca_env_base.duckdb")

    def test_from_env_missing_file(self, temp_dir: Path) -> None:
        """Test from_env handles missing .env file gracefully."""
        non_existent = temp_dir / "nonexistent.env"

        # Should raise ValueError for missing credentials
        with pytest.raises(ValueError) as exc_info:
            EPCConfig.from_env(non_existent)

        assert "Missing EPC_USERNAME or EPC_PASSWORD" in str(exc_info.value)

    def test_from_env_missing_username(self, temp_dir: Path) -> None:
        """Test from_env validates missing username."""
        env_path = temp_dir / ".env"
        env_path.write_text("EPC_PASSWORD=test_password\n")

        with pytest.raises(ValueError) as exc_info:
            EPCConfig.from_env(env_path)

        assert "Missing EPC_USERNAME or EPC_PASSWORD" in str(exc_info.value)

    def test_from_env_missing_password(self, temp_dir: Path) -> None:
        """Test from_env validates missing password."""
        env_path = temp_dir / ".env"
        env_path.write_text("EPC_USERNAME=test_user\n")

        with pytest.raises(ValueError) as exc_info:
            EPCConfig.from_env(env_path)

        assert "Missing EPC_USERNAME or EPC_PASSWORD" in str(exc_info.value)

    def test_from_env_empty_credentials(self, temp_dir: Path) -> None:
        """Test from_env validates empty credential strings."""
        env_path = temp_dir / ".env"
        env_path.write_text("EPC_USERNAME=\nEPC_PASSWORD=\n")

        with pytest.raises(ValueError) as exc_info:
            EPCConfig.from_env(env_path)

        assert "Missing EPC_USERNAME or EPC_PASSWORD" in str(exc_info.value)

    def test_schema_paths(self) -> None:
        """Test that schema paths are correctly set."""
        config = EPCConfig(username="test", password="test")

        assert config.domestic_schema == Path(
            "src/schemas/config/epc_domestic_certificates_schema.json"
        )
        assert config.non_domestic_schema == Path(
            "src/schemas/config/epc_non-domestic_certificates_schema.json"
        )


class TestCertificateType:
    """Tests for CertificateType constants."""

    def test_certificate_type_constants(self) -> None:
        """Test that certificate type constants are correct."""
        assert CertificateType.DOMESTIC == "domestic"
        assert CertificateType.NON_DOMESTIC == "non-domestic"
        assert CertificateType.ALL == "all"

    def test_valid_types(self) -> None:
        """Test that valid_types returns all valid certificate types."""
        valid_types = CertificateType.valid_types()

        assert len(valid_types) == 3
        assert "domestic" in valid_types
        assert "non-domestic" in valid_types
        assert "all" in valid_types
        assert valid_types == ["domestic", "non-domestic", "all"]

    def test_valid_types_is_list(self) -> None:
        """Test that valid_types returns a list."""
        valid_types = CertificateType.valid_types()
        assert isinstance(valid_types, list)

    def test_certificate_type_usage(self) -> None:
        """Test using CertificateType constants in conditional logic."""
        cert_type = CertificateType.DOMESTIC

        if cert_type == CertificateType.DOMESTIC:
            result = "domestic"
        elif cert_type == CertificateType.NON_DOMESTIC:
            result = "non-domestic"
        else:
            result = "unknown"

        assert result == "domestic"
