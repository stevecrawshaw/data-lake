"""XML schema parser for extracting canonical table/column metadata.

Supports parsing XML schema files with table and column definitions, converting
them into structured TableMetadata objects for documentation generation.
"""

import logging
from pathlib import Path

from lxml import etree

from .models import ColumnMetadata, TableMetadata

logger = logging.getLogger(__name__)


class XMLSchemaParser:
    """Parser for XML schema files containing table and column metadata.

    This parser supports flexible XML formats and attempts to extract:
    - Table names and descriptions
    - Column names, types, and descriptions
    - Optional constraints and additional metadata

    Expected XML structure (flexible):
    ```xml
    <schema>
      <table name="table_name">
        <description>Table description</description>
        <column name="column_name">
          <type>VARCHAR</type>
          <description>Column description</description>
          <constraints>
            <constraint>NOT NULL</constraint>
          </constraints>
        </column>
      </table>
    </schema>
    ```
    """

    def __init__(self, xml_path: Path):
        """Initialize the XML parser.

        Args:
            xml_path: Path to the XML schema file

        Raises:
            FileNotFoundError: If the XML file doesn't exist
            etree.XMLSyntaxError: If the XML is malformed
        """
        self.xml_path = xml_path
        if not xml_path.exists():
            msg = f"XML schema file not found: {xml_path}"
            raise FileNotFoundError(msg)

        logger.debug(f"Loading XML schema from: {xml_path}")
        self.tree = etree.parse(str(xml_path))  # noqa: S320
        self.root = self.tree.getroot()

    def parse(self) -> list[TableMetadata]:
        """Parse the XML file and extract all table metadata.

        Returns:
            List of TableMetadata objects, one for each table in the XML

        Raises:
            ValueError: If XML structure is invalid or missing required fields
        """
        tables: list[TableMetadata] = []

        # Try multiple possible root structures
        table_elements = self._find_table_elements()

        if not table_elements:
            logger.warning(f"No table elements found in {self.xml_path}")
            return tables

        for table_elem in table_elements:
            try:
                table_metadata = self._parse_table(table_elem)
                tables.append(table_metadata)
                logger.info(
                    f"Parsed table '{table_metadata.name}' "
                    f"with {len(table_metadata.columns)} columns"
                )
            except Exception as e:
                logger.error(f"Error parsing table element: {e}")
                continue

        return tables

    def _find_table_elements(self) -> list[etree._Element]:
        """Find all table elements in the XML tree.

        Supports multiple XML structures:
        - <schema><table>...</table></schema>
        - <tables><table>...</table></tables>
        - <table>...</table> (root element)

        Returns:
            List of table XML elements
        """
        # Try different possible paths
        table_elements = []

        # Check if root is already a table
        if self.root.tag.lower() in ("table", "table_schema"):
            table_elements = [self.root]
        else:
            # Look for table elements as children
            table_elements = self.root.findall(".//table")
            if not table_elements:
                table_elements = self.root.findall(".//Table")

        return table_elements

    def _parse_table(self, table_elem: etree._Element) -> TableMetadata:
        """Parse a single table element.

        Args:
            table_elem: XML element representing a table

        Returns:
            TableMetadata object

        Raises:
            ValueError: If required fields are missing
        """
        # Extract table name (from attribute or child element)
        table_name = table_elem.get("name") or table_elem.get("Name")
        if not table_name:
            name_elem = table_elem.find("name") or table_elem.find("Name")
            if name_elem is not None and name_elem.text:
                table_name = name_elem.text
            else:
                msg = "Table element missing 'name' attribute"
                raise ValueError(msg)

        # Extract table description
        desc_elem = table_elem.find("description") or table_elem.find("Description")
        table_description = (
            desc_elem.text.strip()
            if desc_elem is not None and desc_elem.text
            else f"Table: {table_name}"
        )

        # Parse columns
        columns = self._parse_columns(table_elem)

        return TableMetadata(
            name=table_name,
            description=table_description,
            columns=columns,
            source="xml",
        )

    def _parse_columns(
        self, table_elem: etree._Element
    ) -> list[ColumnMetadata]:
        """Parse all column elements within a table.

        Args:
            table_elem: XML element representing a table

        Returns:
            List of ColumnMetadata objects
        """
        columns: list[ColumnMetadata] = []

        # Find column elements (try multiple patterns)
        column_elements = table_elem.findall(".//column") or table_elem.findall(
            ".//Column"
        )

        for col_elem in column_elements:
            try:
                column_metadata = self._parse_column(col_elem)
                columns.append(column_metadata)
            except Exception as e:
                logger.warning(f"Error parsing column: {e}")
                continue

        return columns

    def _parse_column(self, col_elem: etree._Element) -> ColumnMetadata:
        """Parse a single column element.

        Args:
            col_elem: XML element representing a column

        Returns:
            ColumnMetadata object

        Raises:
            ValueError: If required fields are missing
        """
        # Extract column name
        col_name = col_elem.get("name") or col_elem.get("Name")
        if not col_name:
            name_elem = col_elem.find("name") or col_elem.find("Name")
            if name_elem is not None and name_elem.text:
                col_name = name_elem.text
            else:
                msg = "Column element missing 'name' attribute"
                raise ValueError(msg)

        # Extract data type
        type_elem = col_elem.find("type") or col_elem.find("Type")
        data_type = (
            type_elem.text.strip()
            if type_elem is not None and type_elem.text
            else "VARCHAR"
        )

        # Extract description
        desc_elem = col_elem.find("description") or col_elem.find("Description")
        description = (
            desc_elem.text.strip()
            if desc_elem is not None and desc_elem.text
            else col_name
        )

        # Extract constraints (optional)
        constraints: list[str] = []
        constraint_elem = col_elem.find("constraints") or col_elem.find("Constraints")
        if constraint_elem is not None:
            for constraint in constraint_elem.findall("constraint"):
                if constraint.text:
                    constraints.append(constraint.text.strip())

        return ColumnMetadata(
            name=col_name,
            data_type=data_type,
            description=description,
            constraints=constraints if constraints else None,
            confidence=1.0,  # XML is canonical source
            source="xml",
        )


def parse_xml_schema(xml_path: Path) -> list[TableMetadata]:
    """Convenience function to parse an XML schema file.

    Args:
        xml_path: Path to the XML schema file

    Returns:
        List of TableMetadata objects

    Example:
        >>> tables = parse_xml_schema(Path("epc_domestic_schema.xml"))
        >>> for table in tables:
        ...     print(f"{table.name}: {len(table.columns)} columns")
    """
    parser = XMLSchemaParser(xml_path)
    return parser.parse()
