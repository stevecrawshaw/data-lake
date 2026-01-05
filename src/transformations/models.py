"""Pydantic models for SQL transformation configuration."""

from pathlib import Path

from pydantic import BaseModel, Field


class TransformationConfig(BaseModel):
    """Configuration for SQL transformations.

    Attributes:
        db_path: Path to DuckDB database file
        sql_root: Root directory containing SQL transformation files
        layers: Ordered list of transformation layers to execute
        postgres_secret_name: Name of DuckDB secret for PostGIS federation
        landing_manual: Directory for manually downloaded data files
        landing_automated: Directory for API-fetched data files
    """

    db_path: Path = Field(default=Path("data_lake/mca_env_base.duckdb"))
    sql_root: Path = Field(default=Path("src/transformations/sql"))
    layers: list[str] = Field(default=["bronze", "silver", "gold"])
    postgres_secret_name: str = Field(default="weca_postgres")
    landing_manual: Path = Field(default=Path("data_lake/landing/manual"))
    landing_automated: Path = Field(default=Path("data_lake/landing/automated"))

    def get_layer_path(self, layer: str) -> Path:
        """Get the directory path for a specific layer.

        Args:
            layer: Layer name (bronze, silver, or gold)

        Returns:
            Path to the layer directory
        """
        return self.sql_root / layer

    def get_schema_path(self, layer: str) -> Path:
        """Get the schema YAML path for a specific layer.

        Args:
            layer: Layer name (bronze, silver, or gold)

        Returns:
            Path to the _schema.yaml file
        """
        return self.get_layer_path(layer) / "_schema.yaml"


class SQLModule(BaseModel):
    """Metadata for a single SQL transformation module.

    Attributes:
        name: Module name (filename without .sql extension)
        layer: Transformation layer (bronze, silver, or gold)
        file_path: Absolute path to the SQL file
        depends_on: List of module names this module depends on
        description: Human-readable description of the module's purpose
        enabled: Whether this module should be executed
        requires_vpn: Whether this module requires VPN connection
        source_files: List of data files this module depends on
    """

    name: str
    layer: str
    file_path: Path
    depends_on: list[str] = Field(default_factory=list)
    description: str | None = None
    enabled: bool = True
    requires_vpn: bool = False
    source_files: list[str] = Field(default_factory=list)

    def get_dependencies(self) -> list[str]:
        """Get fully qualified dependency names.

        Returns:
            List of dependencies in 'layer/module' format
        """
        dependencies = []
        for dep in self.depends_on:
            # If dependency already has layer prefix, use as-is
            if "/" in dep:
                dependencies.append(dep)
            # Otherwise, assume same-layer dependency
            else:
                dependencies.append(f"{self.layer}/{dep}")
        return dependencies

    def get_qualified_name(self) -> str:
        """Get the fully qualified module name.

        Returns:
            Module name in 'layer/module' format
        """
        return f"{self.layer}/{self.name}"
