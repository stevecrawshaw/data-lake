"""XML generator for manual schema overrides.

This module generates manual_overrides.xml from reviewed schema comments,
matching the format of external XML schemas like epc_domestic_schema.xml.
"""

import logging
from pathlib import Path

from lxml import etree

from ..parsers.models import TableMetadata, ViewMetadata
from ..utils.session_manager import SessionState

logger = logging.getLogger(__name__)


class ManualOverrideXMLGenerator:
    """Generates XML file from reviewed schema comments."""

    def __init__(
        self,
        output_path: Path = Path("src/schemas/documentation/manual_overrides.xml"),
    ):
        """Initialize XML generator.

        Args:
            output_path: Path to output XML file
        """
        self.output_path = output_path

    def generate_from_session(
        self,
        session: SessionState,
        tables: dict[str, TableMetadata],
        views: dict[str, ViewMetadata],
    ) -> None:
        """Generate XML file from reviewed fields in session.

        Args:
            session: Session state with reviewed fields
            tables: Dict of table metadata by name
            views: Dict of view metadata by name
        """
        # Create root element
        root = etree.Element("schema")

        # Get reviewed fields
        reviewed_fields = self._get_reviewed_fields(session)

        if not reviewed_fields:
            logger.warning("No reviewed fields to generate XML")
            return

        # Process tables
        for entity_name, columns in reviewed_fields.items():
            if entity_name.startswith("view:"):
                # Handle view
                view_name = entity_name.replace("view:", "")
                if view_name in views:
                    table_elem = self._create_view_element(
                        view_name, views[view_name], columns
                    )
                    if table_elem is not None:
                        root.append(table_elem)
            else:
                # Handle table
                if entity_name in tables:
                    table_elem = self._create_table_element(
                        entity_name, tables[entity_name], columns
                    )
                    if table_elem is not None:
                        root.append(table_elem)

        # Format and write XML
        self._format_and_write_xml(root)

        logger.info(f"Generated XML output: {self.output_path}")

    def _get_reviewed_fields(
        self, session: SessionState
    ) -> dict[str, dict[str, tuple[str, str]]]:
        """Extract reviewed fields from session.

        Args:
            session: Session state

        Returns:
            Dict mapping entity_name -> column_name -> (description, data_type)
        """
        reviewed = {}

        for entity_name, columns in session.fields.items():
            for column_name, field in columns.items():
                if field.status in ("reviewed", "confirmed") and field.user_description:
                    if entity_name not in reviewed:
                        reviewed[entity_name] = {}

                    reviewed[entity_name][column_name] = (
                        field.user_description,
                        field.data_type,
                    )

        return reviewed

    def _create_table_element(
        self,
        table_name: str,
        table_metadata: TableMetadata,
        reviewed_columns: dict[str, tuple[str, str]],
    ) -> etree.Element | None:
        """Create XML element for a table.

        Args:
            table_name: Table name
            table_metadata: Table metadata
            reviewed_columns: Dict of column_name -> (description, data_type)

        Returns:
            XML Element or None if no columns
        """
        if not reviewed_columns:
            return None

        # Create table element
        table_elem = etree.Element("table", name=table_name)

        # Add table description
        desc_elem = etree.SubElement(table_elem, "description")
        desc_elem.text = self._escape_xml_content(table_metadata.description)

        # Add columns
        for column_name, (description, data_type) in reviewed_columns.items():
            col_elem = etree.SubElement(table_elem, "column", name=column_name)

            # Add type
            type_elem = etree.SubElement(col_elem, "type")
            type_elem.text = data_type

            # Add description
            desc_elem = etree.SubElement(col_elem, "description")
            desc_elem.text = self._escape_xml_content(description)

        return table_elem

    def _create_view_element(
        self,
        view_name: str,
        view_metadata: ViewMetadata,
        reviewed_columns: dict[str, tuple[str, str]],
    ) -> etree.Element | None:
        """Create XML element for a view.

        Args:
            view_name: View name
            view_metadata: View metadata
            reviewed_columns: Dict of column_name -> (description, data_type)

        Returns:
            XML Element or None if no columns
        """
        if not reviewed_columns:
            return None

        # Create table element (views use same structure)
        table_elem = etree.Element("table", name=view_name)

        # Add view description
        desc_elem = etree.SubElement(table_elem, "description")
        desc_text = f"View: {view_metadata.description}"
        desc_elem.text = self._escape_xml_content(desc_text)

        # Add columns
        for column_name, (description, data_type) in reviewed_columns.items():
            col_elem = etree.SubElement(table_elem, "column", name=column_name)

            # Add type
            type_elem = etree.SubElement(col_elem, "type")
            type_elem.text = data_type

            # Add description
            desc_elem = etree.SubElement(col_elem, "description")
            desc_elem.text = self._escape_xml_content(description)

        return table_elem

    def _escape_xml_content(self, text: str) -> str:
        """Escape XML special characters in text content.

        Note: lxml handles this automatically for element text,
        but we do it explicitly for clarity and safety.

        Args:
            text: Text to escape

        Returns:
            Escaped text
        """
        # lxml handles escaping automatically, but we ensure
        # the text is properly formatted
        if not text:
            return ""

        # Remove any leading/trailing whitespace
        return text.strip()

    def _format_and_write_xml(self, root: etree.Element) -> None:
        """Format XML with pretty printing and write to file.

        Args:
            root: Root XML element
        """
        # Ensure output directory exists
        self.output_path.parent.mkdir(parents=True, exist_ok=True)

        # Create tree and write with pretty printing
        tree = etree.ElementTree(root)

        # Write to file with XML declaration and pretty formatting
        tree.write(
            str(self.output_path),
            encoding="UTF-8",
            xml_declaration=True,
            pretty_print=True,
        )

        logger.info(f"Wrote XML to {self.output_path}")
