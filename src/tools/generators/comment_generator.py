"""SQL COMMENT statement generator.

Generates SQL COMMENT ON TABLE and COMMENT ON COLUMN statements from
TableMetadata and ViewMetadata objects, with support for:
- SQL string escaping
- Pretty and compact formatting
- Idempotency checks
- Dry-run mode
"""

import logging
from pathlib import Path

import duckdb

from ..parsers.models import DatabaseMetadata, TableMetadata, ViewMetadata

logger = logging.getLogger(__name__)


class CommentGenerator:
    """Generates SQL COMMENT statements from metadata objects.

    Produces properly escaped, formatted SQL statements that can be:
    - Executed directly against a database
    - Saved to a file for version control
    - Reviewed before application (dry-run mode)
    """

    def __init__(
        self,
        database_path: Path | None = None,
        format: str = "pretty",  # noqa: A002
        database_name: str = "mca_env_base",
    ):
        """Initialize comment generator.

        Args:
            database_path: Optional path to DuckDB database for idempotency checks
            format: Output format ('pretty' or 'compact')
            database_name: Name prefix for fully qualified table references
        """
        self.database_path = database_path
        self.format = format
        self.database_name = database_name

    def generate_table_comment(self, table: TableMetadata) -> str:
        """Generate COMMENT ON TABLE statement.

        Args:
            table: TableMetadata object

        Returns:
            SQL COMMENT statement as string

        Example:
            >>> gen = CommentGenerator()
            >>> table = TableMetadata(name="users", description="User accounts")
            >>> print(gen.generate_table_comment(table))
            COMMENT ON TABLE mca_env_base.users IS 'User accounts';
        """
        escaped_desc = self._escape_sql_string(table.description)
        table_ref = f"{self.database_name}.{table.name}"

        if self.format == "pretty":
            return f"COMMENT ON TABLE {table_ref} IS '{escaped_desc}';"
        else:
            return f"COMMENT ON TABLE {table_ref} IS '{escaped_desc}';"

    def generate_column_comment(
        self, table: TableMetadata, column_name: str, description: str
    ) -> str:
        """Generate COMMENT ON COLUMN statement.

        Args:
            table: TableMetadata object
            column_name: Name of the column
            description: Description text for the column

        Returns:
            SQL COMMENT statement as string

        Example:
            >>> gen = CommentGenerator()
            >>> table = TableMetadata(name="users")
            >>> print(gen.generate_column_comment(table, "email", "User's email"))
            COMMENT ON COLUMN mca_env_base.users.email IS 'User's email';
        """
        escaped_desc = self._escape_sql_string(description)
        column_ref = f"{self.database_name}.{table.name}.{column_name}"

        if self.format == "pretty":
            return f"COMMENT ON COLUMN {column_ref} IS '{escaped_desc}';"
        else:
            return f"COMMENT ON COLUMN {column_ref} IS '{escaped_desc}';"

    def generate_all_comments(
        self,
        tables: list[TableMetadata],
        views: list[ViewMetadata] | None = None,
    ) -> str:
        """Generate all COMMENT statements for tables and views.

        Args:
            tables: List of TableMetadata objects
            views: Optional list of ViewMetadata objects

        Returns:
            Complete SQL script with all COMMENT statements
        """
        statements: list[str] = []

        # Header
        if self.format == "pretty":
            statements.append("-- Generated schema documentation comments")
            statements.append("-- Created by schema_documenter tool")
            statements.append("")

        # Table comments
        for table in tables:
            if self.format == "pretty":
                statements.append(f"-- Table: {table.name}")

            # Table description
            statements.append(self.generate_table_comment(table))

            # Column descriptions
            for column in table.columns:
                statements.append(
                    self.generate_column_comment(
                        table, column.name, column.description
                    )
                )

            if self.format == "pretty":
                statements.append("")  # Blank line between tables

        # View comments
        if views:
            if self.format == "pretty":
                statements.append("-- Views")
                statements.append("")

            for view in views:
                if self.format == "pretty":
                    statements.append(f"-- View: {view.name}")

                statements.append(self.generate_table_comment(view))

                for column in view.columns:
                    statements.append(
                        self.generate_column_comment(
                            view, column.name, column.description
                        )
                    )

                if self.format == "pretty":
                    statements.append("")

        return "\n".join(statements)

    def apply_comments(
        self,
        tables: list[TableMetadata],
        views: list[ViewMetadata] | None = None,
        force: bool = False,
    ) -> dict[str, int]:
        """Apply COMMENT statements directly to the database.

        Args:
            tables: List of TableMetadata objects
            views: Optional list of ViewMetadata objects
            force: If True, overwrite existing comments

        Returns:
            Dictionary with statistics (tables_updated, columns_updated, etc.)

        Raises:
            ValueError: If database_path not provided during initialization
        """
        if not self.database_path:
            msg = "database_path required for apply_comments"
            raise ValueError(msg)

        stats = {
            "tables_updated": 0,
            "columns_updated": 0,
            "tables_skipped": 0,
            "columns_skipped": 0,
        }

        with duckdb.connect(str(self.database_path)) as con:
            # Apply table comments
            for table in tables:
                # Check if table comment already exists
                if not force and self._has_table_comment(con, table.name):
                    logger.debug(f"Skipping table {table.name} (already has comment)")
                    stats["tables_skipped"] += 1
                else:
                    stmt = self.generate_table_comment(table)
                    con.execute(stmt)
                    logger.info(f"Updated table comment: {table.name}")
                    stats["tables_updated"] += 1

                # Apply column comments
                for column in table.columns:
                    if not force and self._has_column_comment(
                        con, table.name, column.name
                    ):
                        stats["columns_skipped"] += 1
                    else:
                        stmt = self.generate_column_comment(
                            table, column.name, column.description
                        )
                        con.execute(stmt)
                        stats["columns_updated"] += 1

            # Apply view comments
            if views:
                for view in views:
                    if not force and self._has_table_comment(con, view.name):
                        stats["tables_skipped"] += 1
                    else:
                        stmt = self.generate_table_comment(view)
                        con.execute(stmt)
                        stats["tables_updated"] += 1

                    for column in view.columns:
                        if not force and self._has_column_comment(
                            con, view.name, column.name
                        ):
                            stats["columns_skipped"] += 1
                        else:
                            stmt = self.generate_column_comment(
                                view, column.name, column.description
                            )
                            con.execute(stmt)
                            stats["columns_updated"] += 1

        return stats

    def _escape_sql_string(self, text: str) -> str:
        """Escape single quotes in SQL strings.

        Args:
            text: String to escape

        Returns:
            Escaped string safe for SQL

        Example:
            >>> _escape_sql_string("User's name")
            "User''s name"
        """
        return text.replace("'", "''")

    def _has_table_comment(
        self, con: duckdb.DuckDBPyConnection, table_name: str
    ) -> bool:
        """Check if table already has a comment.

        Args:
            con: DuckDB connection
            table_name: Name of table to check

        Returns:
            True if table has a comment, False otherwise
        """
        try:
            query = f"""
                SELECT comment
                FROM duckdb_tables()
                WHERE table_name = '{table_name}'
            """  # noqa: S608
            result = con.execute(query).fetchone()
            if result and result[0]:
                return True
        except Exception:
            pass
        return False

    def _has_column_comment(
        self, con: duckdb.DuckDBPyConnection, table_name: str, column_name: str
    ) -> bool:
        """Check if column already has a comment.

        Args:
            con: DuckDB connection
            table_name: Name of table containing column
            column_name: Name of column to check

        Returns:
            True if column has a comment, False otherwise
        """
        try:
            query = f"""
                SELECT comment
                FROM duckdb_columns()
                WHERE table_name = '{table_name}'
                  AND column_name = '{column_name}'
            """  # noqa: S608
            result = con.execute(query).fetchone()
            if result and result[0]:
                return True
        except Exception:
            pass
        return False


def save_comments_to_file(
    output_path: Path,
    tables: list[TableMetadata],
    views: list[ViewMetadata] | None = None,
    format: str = "pretty",  # noqa: A002
    database_name: str = "mca_env_base",
) -> None:
    """Convenience function to generate and save comments to a file.

    Args:
        output_path: Path to output SQL file
        tables: List of TableMetadata objects
        views: Optional list of ViewMetadata objects
        format: Output format ('pretty' or 'compact')
        database_name: Name prefix for fully qualified table references

    Example:
        >>> tables = [...]
        >>> save_comments_to_file(
        ...     Path("generated_comments.sql"),
        ...     tables,
        ...     format="pretty"
        ... )
    """
    generator = CommentGenerator(format=format, database_name=database_name)
    sql = generator.generate_all_comments(tables, views)

    output_path.write_text(sql, encoding="utf-8")
    logger.info(f"Saved comments to: {output_path}")
