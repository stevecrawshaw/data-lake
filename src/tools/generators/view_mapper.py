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
        """Map table metadata to all views in the database using multi-pass processing.

        Uses iterative enrichment to propagate comments through view chains:
        - Pass 1: Maps views sourcing directly from base tables
        - Pass 2+: Maps views sourcing from previously-mapped views
        - Continues until no new views are successfully mapped

        Args:
            tables: List of TableMetadata objects for base tables

        Returns:
            List of ViewMetadata objects with mapped column descriptions
        """
        # Initialize lookup with base tables (can contain both tables and views)
        entity_lookup: dict[str, TableMetadata | ViewMetadata] = {
            t.name.upper(): t for t in tables
        }

        with duckdb.connect(str(self.database_path), read_only=True) as con:
            # Get all views from database
            views_query = """
                SELECT view_name, sql
                FROM duckdb_views()
                ORDER BY view_name
            """
            all_view_rows = con.execute(views_query).fetchall()

            # Multi-pass processing
            mapped_views: list[ViewMetadata] = []
            unmapped_views = all_view_rows.copy()
            max_passes = 10

            for pass_num in range(1, max_passes + 1):
                if not unmapped_views:
                    logger.info("All views successfully mapped")
                    break

                newly_mapped = []
                still_unmapped = []

                logger.info(
                    f"Pass {pass_num}: Processing {len(unmapped_views)} unmapped views"
                )

                for view_name, view_sql in unmapped_views:
                    try:
                        view_metadata = self._map_view(
                            con, view_name, view_sql, entity_lookup
                        )

                        # Check if mapping was successful
                        if self._is_successfully_mapped(view_metadata):
                            newly_mapped.append(view_metadata)
                            # Add to lookup for next pass
                            entity_lookup[view_metadata.name.upper()] = view_metadata
                            logger.debug(
                                f"Successfully mapped view: {view_name} "
                                f"(sources: {', '.join(view_metadata.source_tables)})"
                            )
                        else:
                            still_unmapped.append((view_name, view_sql))
                            logger.debug(
                                f"View {view_name} not fully mapped, deferring to next pass"
                            )

                    except Exception as e:
                        logger.error(f"Error mapping view {view_name}: {e}")
                        still_unmapped.append((view_name, view_sql))
                        continue

                if newly_mapped:
                    logger.info(
                        f"Pass {pass_num}: Successfully mapped {len(newly_mapped)} views"
                    )
                    mapped_views.extend(newly_mapped)
                    unmapped_views = still_unmapped
                else:
                    # No progress made, stop iterating
                    logger.warning(
                        f"Pass {pass_num}: No views mapped, stopping multi-pass processing"
                    )
                    break

            # Log warnings for unmapped views
            if unmapped_views:
                unmapped_names = [name for name, _ in unmapped_views]
                logger.warning(
                    f"{len(unmapped_views)} views could not be fully mapped: "
                    f"{', '.join(unmapped_names)}"
                )

        return mapped_views

    def _is_successfully_mapped(self, view_metadata: ViewMetadata) -> bool:
        """Check if a view was successfully mapped (has non-fallback sources).

        A view is considered successfully mapped if:
        - At least 80% of columns are mapped (not fallback or computed)
        - This ensures views are only marked complete when most columns have proper sources

        Args:
            view_metadata: ViewMetadata object to check

        Returns:
            True if view has successfully mapped columns, False otherwise
        """
        if not view_metadata.columns:
            return False

        # Count columns that were successfully mapped (not fallback)
        mapped_columns = [
            c for c in view_metadata.columns
            if c.source not in ("fallback", "computed")
        ]

        # Require at least 80% of columns to be successfully mapped
        mapped_ratio = len(mapped_columns) / len(view_metadata.columns)

        logger.debug(
            f"View {view_metadata.name}: {len(mapped_columns)}/{len(view_metadata.columns)} "
            f"columns mapped ({mapped_ratio:.1%})"
        )

        return mapped_ratio >= 0.80

    def _map_view(
        self,
        con: duckdb.DuckDBPyConnection,
        view_name: str,
        view_sql: str,
        entity_lookup: dict[str, TableMetadata | ViewMetadata],
    ) -> ViewMetadata:
        """Map a single view to its source tables or views.

        Args:
            con: DuckDB connection
            view_name: Name of the view
            view_sql: SQL definition of the view
            entity_lookup: Dictionary mapping table/view names to their metadata

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
                col_name, data_type, source_tables, entity_lookup, view_sql
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
        entity_lookup: dict[str, TableMetadata | ViewMetadata],
        view_sql: str,
    ) -> ColumnMetadata:
        """Map a single view column to its source table or view column.

        Supports propagation through view chains by looking up both tables
        and previously-mapped views.

        Args:
            col_name: View column name
            data_type: View column data type
            source_tables: List of source table/view names
            entity_lookup: Dictionary mapping table/view names to their metadata
            view_sql: SQL definition of the view

        Returns:
            ColumnMetadata object with description
        """
        # Try to find matching column in source entities (tables or views)
        for source_name in source_tables:
            source_entity = entity_lookup.get(source_name.upper())
            if not source_entity:
                logger.debug(
                    f"Source '{source_name}' not found in lookup for column {col_name}"
                )
                continue

            # Both TableMetadata and ViewMetadata have get_column() method
            source_column = source_entity.get_column(col_name)
            if source_column:
                # Adjust confidence based on indirection level
                # Slightly lower confidence when inheriting from views vs tables
                if isinstance(source_entity, TableMetadata):
                    confidence_multiplier = 0.95
                    logger.debug(
                        f"Mapped {col_name} from table {source_name} "
                        f"(confidence: {source_column.confidence * confidence_multiplier:.2f})"
                    )
                else:  # ViewMetadata
                    confidence_multiplier = 0.90
                    logger.debug(
                        f"Mapped {col_name} from view {source_name} "
                        f"(confidence: {source_column.confidence * confidence_multiplier:.2f})"
                    )

                # Copy description from source, preserving XML-sourced detail
                return ColumnMetadata(
                    name=col_name,
                    data_type=data_type,
                    description=source_column.description,
                    confidence=source_column.confidence * confidence_multiplier,
                    source=f"mapped_from_{source_name}",
                )

        # Check if column is computed/derived
        if self._is_computed_column(col_name, view_sql):
            logger.debug(f"Column {col_name} identified as computed")
            return ColumnMetadata(
                name=col_name,
                data_type=data_type,
                description=f"Computed field: {col_name}",
                confidence=0.70,
                source="computed",
            )

        # Fallback: use column name as description
        logger.debug(f"Using fallback description for column {col_name}")
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
