"""View mapper for propagating table comments to views.

Analyzes view definitions to identify source tables and automatically map
column comments from base tables to their corresponding view columns.
"""

import logging
import re
from pathlib import Path

import duckdb

from ..parsers.models import ColumnMetadata, TableMetadata, ViewMetadata

logger = logging.getLogger(__name__)


class ViewMapper:
    """Maps table metadata to view metadata.

    Analyzes view definitions to determine source tables and propagates
    column metadata from base tables to views, handling:
    - Simple column selections
    - Renamed columns (AS aliases)
    - Computed columns
    - JOIN operations
    """

    def __init__(self, database_path: Path):
        """Initialize view mapper.

        Args:
            database_path: Path to DuckDB database file
        """
        self.database_path = database_path

    def map_views(
        self, tables: list[TableMetadata]
    ) -> list[ViewMetadata]:
        """Map table metadata to all views in the database.

        Args:
            tables: List of TableMetadata objects for base tables

        Returns:
            List of ViewMetadata objects with mapped column descriptions
        """
        views: list[ViewMetadata] = []

        # Create table lookup dictionary
        table_lookup = {t.name.upper(): t for t in tables}

        with duckdb.connect(str(self.database_path), read_only=True) as con:
            # Get all views
            views_query = """
                SELECT view_name, sql
                FROM duckdb_views()
                ORDER BY view_name
            """
            view_rows = con.execute(views_query).fetchall()

            for view_name, view_sql in view_rows:
                logger.info(f"Mapping view: {view_name}")

                try:
                    view_metadata = self._map_view(
                        con, view_name, view_sql, table_lookup
                    )
                    views.append(view_metadata)
                except Exception as e:
                    logger.error(f"Error mapping view {view_name}: {e}")
                    continue

        return views

    def _map_view(
        self,
        con: duckdb.DuckDBPyConnection,
        view_name: str,
        view_sql: str,
        table_lookup: dict[str, TableMetadata],
    ) -> ViewMetadata:
        """Map a single view to its source tables.

        Args:
            con: DuckDB connection
            view_name: Name of the view
            view_sql: SQL definition of the view
            table_lookup: Dictionary mapping table names to TableMetadata

        Returns:
            ViewMetadata object with mapped column descriptions
        """
        # Extract source tables from SQL
        source_tables = self._extract_source_tables(view_sql)
        logger.debug(f"View {view_name} sources: {source_tables}")

        # Get view columns
        columns_query = f"""
            SELECT column_name, data_type
            FROM duckdb_columns()
            WHERE table_name = '{view_name}'
            ORDER BY column_index
        """  # noqa: S608

        column_rows = con.execute(columns_query).fetchall()

        # Map columns
        columns: list[ColumnMetadata] = []
        for col_name, data_type in column_rows:
            column_meta = self._map_view_column(
                col_name, data_type, source_tables, table_lookup, view_sql
            )
            columns.append(column_meta)

        # Generate view description
        if source_tables:
            source_list = ", ".join(source_tables)
            view_desc = f"View based on {source_list}"
        else:
            view_desc = f"View: {view_name}"

        return ViewMetadata(
            name=view_name,
            description=view_desc,
            columns=columns,
            source_tables=source_tables,
            view_definition=view_sql,
            source="inferred",
        )

    def _map_view_column(
        self,
        col_name: str,
        data_type: str,
        source_tables: list[str],
        table_lookup: dict[str, TableMetadata],
        view_sql: str,
    ) -> ColumnMetadata:
        """Map a single view column to its source table column.

        Args:
            col_name: View column name
            data_type: View column data type
            source_tables: List of source table names
            table_lookup: Dictionary mapping table names to TableMetadata
            view_sql: SQL definition of the view

        Returns:
            ColumnMetadata object with description
        """
        # Try to find matching column in source tables
        for source_table_name in source_tables:
            source_table = table_lookup.get(source_table_name.upper())
            if not source_table:
                continue

            # Look for exact column name match
            source_column = source_table.get_column(col_name)
            if source_column:
                # Copy description from source table
                return ColumnMetadata(
                    name=col_name,
                    data_type=data_type,
                    description=source_column.description,
                    confidence=source_column.confidence * 0.95,  # Slight reduction
                    source=f"mapped_from_{source_table_name}",
                )

        # Check if column is computed/derived
        if self._is_computed_column(col_name, view_sql):
            return ColumnMetadata(
                name=col_name,
                data_type=data_type,
                description=f"Computed field: {col_name}",
                confidence=0.70,
                source="computed",
            )

        # Fallback: use column name as description
        return ColumnMetadata(
            name=col_name,
            data_type=data_type,
            description=col_name.replace("_", " ").capitalize(),
            confidence=0.50,
            source="fallback",
        )

    def _extract_source_tables(self, view_sql: str) -> list[str]:
        """Extract source table names from view SQL definition.

        Args:
            view_sql: SQL definition of the view

        Returns:
            List of source table names

        Note:
            This is a simple regex-based parser and may not handle all
            complex SQL constructs. For production use, consider using a
            proper SQL parser.
        """
        source_tables: list[str] = []

        # Remove comments
        sql_clean = re.sub(r"--.*$", "", view_sql, flags=re.MULTILINE)
        sql_clean = re.sub(r"/\*.*?\*/", "", sql_clean, flags=re.DOTALL)

        # Find FROM clauses
        from_pattern = r"\bFROM\s+([^\s,()]+)"
        from_matches = re.findall(from_pattern, sql_clean, re.IGNORECASE)

        for match in from_matches:
            # Clean up table name (remove schema, quotes, aliases)
            table_name = match.strip()
            table_name = table_name.replace('"', "").replace("'", "")

            # Remove schema prefix if present
            if "." in table_name:
                table_name = table_name.split(".")[-1]

            if table_name.upper() not in ("SELECT", "WHERE", "GROUP", "ORDER"):
                source_tables.append(table_name)

        # Find JOIN clauses
        join_pattern = r"\bJOIN\s+([^\s,()]+)"
        join_matches = re.findall(join_pattern, sql_clean, re.IGNORECASE)

        for match in join_matches:
            table_name = match.strip()
            table_name = table_name.replace('"', "").replace("'", "")

            if "." in table_name:
                table_name = table_name.split(".")[-1]

            if table_name.upper() not in ("SELECT", "ON", "WHERE"):
                source_tables.append(table_name)

        # Remove duplicates while preserving order
        seen = set()
        unique_tables = []
        for table in source_tables:
            if table.upper() not in seen:
                seen.add(table.upper())
                unique_tables.append(table)

        return unique_tables

    def _is_computed_column(self, col_name: str, view_sql: str) -> bool:
        """Check if a column is computed/derived in the view.

        Args:
            col_name: Column name to check
            view_sql: SQL definition of the view

        Returns:
            True if column appears to be computed, False otherwise

        Note:
            This is a heuristic check and may not be 100% accurate.
        """
        # Look for common computed patterns like:
        # - CASE WHEN
        # - function calls before AS col_name
        # - arithmetic operations

        # Simple pattern: check if AS col_name is preceded by operations
        pattern = rf"\b(CASE|CAST|ROUND|UPPER|LOWER|CONCAT|\+|-|\*|/)\b.*?\bAS\s+{re.escape(col_name)}\b"
        return bool(re.search(pattern, view_sql, re.IGNORECASE))
