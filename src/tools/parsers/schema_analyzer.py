"""Schema analyzer for inferring column descriptions from patterns and data.

Analyzes database schemas to generate intelligent descriptions for tables and
columns based on:
- Column naming patterns (suffixes, prefixes, exact matches)
- Data type conventions
- Statistical analysis of sample data
"""

import logging
import re
from pathlib import Path

import duckdb
import yaml
from polars import DataFrame

from .models import ColumnMetadata, TableMetadata

logger = logging.getLogger(__name__)


class PatternMatcher:
    """Pattern-based description generator for column names.

    Uses configurable rules from YAML files to match column names against
    known patterns and generate appropriate descriptions.
    """

    def __init__(self, pattern_rules_path: Path):
        """Initialize pattern matcher with rules from YAML file.

        Args:
            pattern_rules_path: Path to pattern_rules.yaml configuration file
        """
        self.pattern_rules_path = pattern_rules_path
        self._load_rules()

    def _load_rules(self) -> None:
        """Load pattern rules from YAML configuration file."""
        logger.debug(f"Loading pattern rules from: {self.pattern_rules_path}")

        with open(self.pattern_rules_path) as f:
            rules = yaml.safe_load(f)

        self.suffix_patterns = rules.get("suffix_patterns", {})
        self.prefix_patterns = rules.get("prefix_patterns", {})
        self.exact_matches = rules.get("exact_matches", {})

        logger.info(
            f"Loaded {len(self.exact_matches)} exact matches, "
            f"{len(self.suffix_patterns)} suffix patterns, "
            f"{len(self.prefix_patterns)} prefix patterns"
        )

    def match(self, column_name: str, data_type: str) -> tuple[str | None, float]:
        """Match column name against patterns and generate description.

        Args:
            column_name: Name of the column to match
            data_type: SQL data type of the column

        Returns:
            Tuple of (description, confidence_score) where description may be None
            if no match found. Confidence ranges from 0.0 to 1.0.
        """
        col_lower = column_name.lower()
        col_upper = column_name.upper()

        # 1. Exact matches (highest confidence)
        if col_lower in self.exact_matches:
            return (self.exact_matches[col_lower], 0.95)

        # 2. Suffix patterns
        for suffix, suffix_desc in self.suffix_patterns.items():
            if col_lower.endswith(suffix):
                base_name = col_lower[: -len(suffix)]
                humanized = self._humanize(base_name)
                desc = f"{humanized} {suffix_desc}"
                return (desc.capitalize(), 0.85)

        # 3. Prefix patterns
        for prefix, prefix_desc in self.prefix_patterns.items():
            if col_lower.startswith(prefix):
                base_name = col_lower[len(prefix) :]
                humanized = self._humanize(base_name)
                desc = f"{prefix_desc} {humanized}"
                return (desc.capitalize(), 0.80)

        # 4. Data type-based inference
        if data_type.upper() == "DATE":
            humanized = self._humanize(col_lower)
            return (f"Date of {humanized}", 0.70)

        if data_type.upper() in ("TIMESTAMP", "DATETIME"):
            humanized = self._humanize(col_lower)
            return (f"Timestamp for {humanized}", 0.70)

        if data_type.upper() == "BOOLEAN":
            humanized = self._humanize(col_lower)
            return (f"Flag indicating whether {humanized}", 0.65)

        # 5. Fallback: humanize the column name
        humanized = self._humanize(col_lower)
        return (humanized.capitalize(), 0.50)

    def _humanize(self, column_name: str) -> str:
        """Convert snake_case or camelCase column name to human-readable text.

        Args:
            column_name: Column name to humanize

        Returns:
            Human-readable text

        Examples:
            >>> _humanize("total_floor_area")
            "total floor area"
            >>> _humanize("LODGEMENT_DATE")
            "lodgement date"
            >>> _humanize("currentEnergyRating")
            "current energy rating"
        """
        # Handle UPPER_CASE
        if "_" in column_name:
            words = column_name.split("_")
            return " ".join(word.lower() for word in words if word)

        # Handle camelCase or PascalCase
        # Insert space before uppercase letters
        spaced = re.sub(r"([a-z])([A-Z])", r"\1 \2", column_name)
        return spaced.lower()


class DataAnalyzer:
    """Statistical analyzer for inferring column properties from sample data.

    Analyzes data distributions, uniqueness, null rates, and value ranges to
    enhance description quality and confidence scores.
    """

    def __init__(self, database_path: Path, sample_size: int = 1000):
        """Initialize data analyzer.

        Args:
            database_path: Path to DuckDB database file
            sample_size: Number of rows to sample for analysis
        """
        self.database_path = database_path
        self.sample_size = sample_size

    def analyze(
        self, table_name: str, column_name: str, data_type: str
    ) -> tuple[dict[str, float | int | str], float]:
        """Analyze column data and return statistics.

        Args:
            table_name: Name of the table containing the column
            column_name: Name of the column to analyze
            data_type: SQL data type of the column

        Returns:
            Tuple of (statistics_dict, confidence_adjustment)
            where confidence_adjustment is a value to add/subtract from base
            confidence score (-0.2 to +0.2)
        """
        try:
            with duckdb.connect(str(self.database_path), read_only=True) as con:
                # Get total row count
                total_rows_query = f"SELECT COUNT(*) as cnt FROM {table_name}"  # noqa: S608
                total_rows = con.execute(total_rows_query).fetchone()[0]

                if total_rows == 0:
                    return ({}, 0.0)

                # Sample data for analysis
                sample_query = f"""
                    SELECT
                        {column_name},
                        COUNT(*) as cnt,
                        COUNT(DISTINCT {column_name}) as distinct_cnt,
                        COUNT(*) * 1.0 / {total_rows} as coverage
                    FROM (SELECT * FROM {table_name} LIMIT {self.sample_size})
                    WHERE {column_name} IS NOT NULL
                """  # noqa: S608

                stats = con.execute(sample_query).fetchone()

                if not stats:
                    return ({}, 0.0)

                cnt, distinct_cnt, coverage = stats

                # Calculate uniqueness ratio
                uniqueness = distinct_cnt / cnt if cnt > 0 else 0

                statistics = {
                    "total_rows": total_rows,
                    "sample_size": cnt,
                    "distinct_values": distinct_cnt,
                    "uniqueness": uniqueness,
                    "coverage": coverage,
                }

                # Adjust confidence based on statistics
                confidence_adj = 0.0

                # High uniqueness suggests primary key or identifier
                if uniqueness > 0.95:
                    confidence_adj += 0.1

                # Low coverage suggests mostly NULL (less reliable inference)
                if coverage < 0.5:
                    confidence_adj -= 0.1

                return (statistics, confidence_adj)

        except Exception as e:
            logger.warning(
                f"Error analyzing column {table_name}.{column_name}: {e}"
            )
            return ({}, 0.0)


class SchemaAnalyzer:
    """Main schema analyzer combining pattern matching and data analysis.

    Generates comprehensive table and column metadata by:
    1. Querying database structure (duckdb_columns, duckdb_tables)
    2. Applying pattern matching rules
    3. Optionally analyzing sample data
    4. Generating confidence scores
    """

    def __init__(
        self,
        database_path: Path,
        pattern_rules_path: Path,
        sample_size: int = 1000,
        enable_data_analysis: bool = True,
    ):
        """Initialize schema analyzer.

        Args:
            database_path: Path to DuckDB database file
            pattern_rules_path: Path to pattern_rules.yaml file
            sample_size: Number of rows to sample for data analysis
            enable_data_analysis: Whether to perform statistical data analysis
        """
        self.database_path = database_path
        self.pattern_matcher = PatternMatcher(pattern_rules_path)
        self.enable_data_analysis = enable_data_analysis

        if enable_data_analysis:
            self.data_analyzer = DataAnalyzer(database_path, sample_size)

    def analyze_database(
        self,
        table_filter: list[str] | None = None,
        min_confidence: float = 0.0,
    ) -> list[TableMetadata]:
        """Analyze all tables in the database and generate metadata.

        Args:
            table_filter: Optional list of table names to analyze (None = all)
            min_confidence: Minimum confidence threshold for including columns

        Returns:
            List of TableMetadata objects
        """
        tables: list[TableMetadata] = []

        with duckdb.connect(str(self.database_path), read_only=True) as con:
            # Get all table names
            tables_query = "SELECT DISTINCT table_name FROM duckdb_tables() WHERE table_type = 'BASE TABLE'"
            table_rows = con.execute(tables_query).fetchall()

            for (table_name,) in table_rows:
                # Apply filter if specified
                if table_filter and table_name not in table_filter:
                    continue

                logger.info(f"Analyzing table: {table_name}")
                table_metadata = self._analyze_table(con, table_name, min_confidence)
                tables.append(table_metadata)

        return tables

    def _analyze_table(
        self, con: duckdb.DuckDBPyConnection, table_name: str, min_confidence: float
    ) -> TableMetadata:
        """Analyze a single table and generate metadata.

        Args:
            con: DuckDB connection
            table_name: Name of table to analyze
            min_confidence: Minimum confidence threshold

        Returns:
            TableMetadata object
        """
        # Get column information
        columns_query = f"""
            SELECT column_name, data_type
            FROM duckdb_columns()
            WHERE table_name = '{table_name}'
            ORDER BY column_index
        """  # noqa: S608

        column_rows = con.execute(columns_query).fetchall()

        columns: list[ColumnMetadata] = []

        for col_name, data_type in column_rows:
            # Pattern matching
            desc, confidence = self.pattern_matcher.match(col_name, data_type)

            # Data analysis (optional enhancement)
            if self.enable_data_analysis:
                try:
                    stats, conf_adj = self.data_analyzer.analyze(
                        table_name, col_name, data_type
                    )
                    confidence += conf_adj
                    confidence = max(0.0, min(1.0, confidence))  # Clamp to [0, 1]
                except Exception as e:
                    logger.debug(f"Data analysis failed for {col_name}: {e}")

            # Only include if meets minimum confidence
            if confidence >= min_confidence:
                column_meta = ColumnMetadata(
                    name=col_name,
                    data_type=data_type,
                    description=desc or col_name,
                    confidence=confidence,
                    source="inferred",
                )
                columns.append(column_meta)

        # Generate table description
        table_desc = f"Table containing {len(columns)} columns"

        return TableMetadata(
            name=table_name,
            description=table_desc,
            columns=columns,
            source="inferred",
        )
