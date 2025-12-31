"""Pydantic models for schema metadata.

These models represent table and column metadata extracted from various sources
including XML schemas, database introspection, and inference engines.
"""

from pydantic import BaseModel, Field


class ColumnMetadata(BaseModel):
    """Metadata for a single column.

    Attributes:
        name: Column name (case-sensitive)
        data_type: SQL data type (e.g., VARCHAR, INTEGER, DATE)
        description: Human-readable description of the column
        constraints: Optional list of constraints (e.g., NOT NULL, PRIMARY KEY)
        confidence: Confidence score for inferred descriptions (0.0-1.0)
        source: Source of metadata (xml, inferred, manual)
    """

    name: str
    data_type: str
    description: str
    constraints: list[str] | None = None
    confidence: float = Field(default=1.0, ge=0.0, le=1.0)
    source: str = "unknown"  # xml, inferred, manual, database

    def __str__(self) -> str:
        return f"{self.name} ({self.data_type}): {self.description}"


class TableMetadata(BaseModel):
    """Metadata for a single table.

    Attributes:
        name: Table name (case-sensitive)
        description: Human-readable description of the table
        columns: List of column metadata objects
        schema_name: Database schema name (default: 'main')
        table_type: Type of table (table, view)
        source: Source of metadata (xml, inferred, manual)
    """

    name: str
    description: str
    columns: list[ColumnMetadata]
    schema_name: str = "main"
    table_type: str = "table"  # table or view
    source: str = "unknown"

    def get_column(self, column_name: str) -> ColumnMetadata | None:
        """Get column metadata by name (case-insensitive).

        Args:
            column_name: Name of the column to retrieve

        Returns:
            ColumnMetadata object if found, None otherwise
        """
        column_name_upper = column_name.upper()
        for col in self.columns:
            if col.name.upper() == column_name_upper:
                return col
        return None

    def __str__(self) -> str:
        return f"{self.name} ({len(self.columns)} columns): {self.description}"


class ViewMetadata(TableMetadata):
    """Metadata for a database view.

    Extends TableMetadata with view-specific attributes.

    Attributes:
        source_tables: List of source table names that the view references
        view_definition: Optional SQL definition of the view
    """

    source_tables: list[str] = Field(default_factory=list)
    view_definition: str | None = None
    table_type: str = "view"

    def __str__(self) -> str:
        sources = ", ".join(self.source_tables) if self.source_tables else "unknown"
        return (
            f"{self.name} (view from {sources}, {len(self.columns)} columns): "
            f"{self.description}"
        )


class DatabaseMetadata(BaseModel):
    """Complete database schema metadata.

    Attributes:
        database_name: Name of the database
        tables: List of table metadata objects
        views: List of view metadata objects
    """

    database_name: str
    tables: list[TableMetadata] = Field(default_factory=list)
    views: list[ViewMetadata] = Field(default_factory=list)

    def get_table(self, table_name: str) -> TableMetadata | None:
        """Get table metadata by name (case-insensitive).

        Args:
            table_name: Name of the table to retrieve

        Returns:
            TableMetadata object if found, None otherwise
        """
        table_name_upper = table_name.upper()
        for table in self.tables:
            if table.name.upper() == table_name_upper:
                return table
        return None

    def get_view(self, view_name: str) -> ViewMetadata | None:
        """Get view metadata by name (case-insensitive).

        Args:
            view_name: Name of the view to retrieve

        Returns:
            ViewMetadata object if found, None otherwise
        """
        view_name_upper = view_name.upper()
        for view in self.views:
            if view.name.upper() == view_name_upper:
                return view
        return None

    def __str__(self) -> str:
        return (
            f"Database: {self.database_name} "
            f"({len(self.tables)} tables, {len(self.views)} views)"
        )
