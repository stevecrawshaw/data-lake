"""Pydantic models for EPC API incremental update configuration."""

from pathlib import Path

import dotenv
from pydantic import BaseModel, Field


class EPCConfig(BaseModel):
    """Configuration for EPC API incremental updates.

    Attributes:
        db_path: Path to DuckDB database file
        base_url: EPC API base URL
        domestic_endpoint: Domestic certificates search endpoint
        non_domestic_endpoint: Non-domestic certificates search endpoint
        username: API username (from .env)
        password: API password/key (from .env)
        page_size: Records per API request (max 5000)
        max_records_per_batch: Safety limit for total records
        staging_dir: Directory for staging CSV files
        domestic_schema: Path to domestic schema JSON
        non_domestic_schema: Path to non-domestic schema JSON
        domestic_table: Name of domestic certificates table
        non_domestic_table: Name of non-domestic certificates table
    """

    # Database
    db_path: Path = Field(default=Path("data_lake/mca_env_base.duckdb"))

    # API endpoints
    base_url: str = Field(default="https://epc.opendatacommunities.org")
    domestic_endpoint: str = "/api/v1/domestic/search"
    non_domestic_endpoint: str = "/api/v1/non-domestic/search"

    # Credentials (loaded from .env)
    username: str
    password: str

    # Pagination
    page_size: int = Field(default=5000, le=5000)
    max_records_per_batch: int = Field(default=100000)

    # Staging
    staging_dir: Path = Field(default=Path("data_lake/landing/automated"))

    # Schema paths
    domestic_schema: Path = Field(
        default=Path("src/schemas/epc_domestic_certificates_schema.json")
    )
    non_domestic_schema: Path = Field(
        default=Path("src/schemas/epc_non-domestic_certificates_schema.json")
    )

    # Table names
    domestic_table: str = "raw_domestic_epc_certificates_tbl"
    non_domestic_table: str = "raw_non_domestic_epc_certificates_tbl"

    @classmethod
    def from_env(cls, env_path: Path = Path(".env")) -> "EPCConfig":
        """Load configuration from .env file.

        Args:
            env_path: Path to .env file (default: .env in current directory)

        Returns:
            EPCConfig instance with credentials loaded from .env

        Raises:
            ValueError: If required environment variables are missing
        """
        env_values = dotenv.dotenv_values(str(env_path))

        username = env_values.get("EPC_USERNAME")
        password = env_values.get("EPC_PASSWORD")

        if not username or not password:
            msg = "Missing EPC_USERNAME or EPC_PASSWORD in .env file"
            raise ValueError(msg)

        return cls(username=username, password=password)


class CertificateType:
    """Certificate type constants."""

    DOMESTIC = "domestic"
    NON_DOMESTIC = "non-domestic"
    ALL = "all"

    @classmethod
    def valid_types(cls) -> list[str]:
        """Return list of valid certificate types."""
        return [cls.DOMESTIC, cls.NON_DOMESTIC, cls.ALL]
