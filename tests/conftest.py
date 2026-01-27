"""Pytest configuration and shared fixtures for EPC incremental update tests."""

import json
from pathlib import Path
from typing import Any

import duckdb
import pytest


@pytest.fixture
def temp_dir(tmp_path: Path) -> Path:
    """Provide a temporary directory for test files."""
    return tmp_path


@pytest.fixture
def mock_env_file(temp_dir: Path) -> Path:
    """Create a mock .env file with test credentials."""
    env_path = temp_dir / ".env"
    env_path.write_text("EPC_USERNAME=test_user\nEPC_PASSWORD=test_password_123\n")
    return env_path


@pytest.fixture
def mock_schema_domestic(temp_dir: Path) -> Path:
    """Create a mock domestic EPC schema JSON file."""
    schema_path = temp_dir / "domestic_schema.json"
    schema = {
        "LMK_KEY": "VARCHAR",
        "ADDRESS1": "VARCHAR",
        "ADDRESS2": "VARCHAR",
        "POSTCODE": "VARCHAR",
        "UPRN": "BIGINT",
        "LODGEMENT_DATE": "DATE",
        "TRANSACTION_TYPE": "VARCHAR",
        "CURRENT_ENERGY_EFFICIENCY": "INTEGER",
        "POTENTIAL_ENERGY_EFFICIENCY": "INTEGER",
        "CURRENT_ENERGY_RATING": "VARCHAR",
        "POTENTIAL_ENERGY_RATING": "VARCHAR",
        "PROPERTY_TYPE": "VARCHAR",
        "BUILT_FORM": "VARCHAR",
        "ENVIRONMENT_IMPACT_CURRENT": "INTEGER",
        "ENVIRONMENT_IMPACT_POTENTIAL": "INTEGER",
        "TOTAL_FLOOR_AREA": "DOUBLE",
    }
    schema_path.write_text(json.dumps(schema, indent=2))
    return schema_path


@pytest.fixture
def mock_schema_non_domestic(temp_dir: Path) -> Path:
    """Create a mock non-domestic EPC schema JSON file."""
    schema_path = temp_dir / "non_domestic_schema.json"
    schema = {
        "LMK_KEY": "VARCHAR",
        "ADDRESS1": "VARCHAR",
        "POSTCODE": "VARCHAR",
        "UPRN": "BIGINT",
        "LODGEMENT_DATE": "DATE",
        "ASSET_RATING": "INTEGER",
        "ASSET_RATING_BAND": "VARCHAR",
        "PROPERTY_TYPE": "VARCHAR",
        "FLOOR_AREA": "DOUBLE",
    }
    schema_path.write_text(json.dumps(schema, indent=2))
    return schema_path


@pytest.fixture
def mock_db_path(temp_dir: Path) -> Path:
    """Create a mock DuckDB database with test tables."""
    db_path = temp_dir / "test_epc.duckdb"

    with duckdb.connect(str(db_path)) as con:
        # Create domestic table with sample data
        con.execute("""
            CREATE TABLE raw_domestic_epc_certificates_tbl (
                LMK_KEY VARCHAR,
                ADDRESS1 VARCHAR,
                ADDRESS2 VARCHAR,
                POSTCODE VARCHAR,
                UPRN BIGINT,
                LODGEMENT_DATE DATE,
                TRANSACTION_TYPE VARCHAR,
                CURRENT_ENERGY_EFFICIENCY INTEGER,
                POTENTIAL_ENERGY_EFFICIENCY INTEGER,
                CURRENT_ENERGY_RATING VARCHAR,
                POTENTIAL_ENERGY_RATING VARCHAR,
                PROPERTY_TYPE VARCHAR,
                BUILT_FORM VARCHAR,
                ENVIRONMENT_IMPACT_CURRENT INTEGER,
                ENVIRONMENT_IMPACT_POTENTIAL INTEGER,
                TOTAL_FLOOR_AREA DOUBLE
            )
        """)

        # Insert sample records
        con.execute("""
            INSERT INTO raw_domestic_epc_certificates_tbl VALUES
            ('1234567890', '1 Test Street', 'Test Area', 'TE1 1ST', 100023336956,
             '2025-10-15', 'marketed sale', 75, 85, 'C', 'B', 'House', 'Detached',
             70, 80, 120.5),
            ('0987654321', '2 Sample Road', 'Sample Town', 'SA2 2MP', 100023336957,
             '2025-10-31', 'rental', 60, 75, 'D', 'C', 'Flat', 'Mid-Terrace',
             55, 70, 85.0)
        """)

        # Create non-domestic table with sample data
        con.execute("""
            CREATE TABLE raw_non_domestic_epc_certificates_tbl (
                LMK_KEY VARCHAR,
                ADDRESS1 VARCHAR,
                POSTCODE VARCHAR,
                UPRN BIGINT,
                LODGEMENT_DATE DATE,
                ASSET_RATING INTEGER,
                ASSET_RATING_BAND VARCHAR,
                PROPERTY_TYPE VARCHAR,
                FLOOR_AREA DOUBLE
            )
        """)

        con.execute("""
            INSERT INTO raw_non_domestic_epc_certificates_tbl VALUES
            ('ND1234567890', '10 Business Park', 'BU1 1SS', 200012345678,
             '2025-10-20', 45, 'C', 'Office', 500.0)
        """)

    return db_path


@pytest.fixture
def sample_api_records_domestic() -> list[dict[str, Any]]:
    """Provide sample API response records for domestic certificates."""
    return [
        {
            "lmk-key": "ABC1234567890",
            "address1": "123 New Street",
            "address2": "New Area",
            "postcode": "NE1 1WS",
            "uprn": "100023336958",
            "lodgement-date": "2025-11-15",
            "transaction-type": "marketed sale",
            "current-energy-efficiency": "80",
            "potential-energy-efficiency": "90",
            "current-energy-rating": "B",
            "potential-energy-rating": "A",
            "property-type": "House",
            "built-form": "Semi-Detached",
            "environmental-impact-current": "75",
            "environmental-impact-potential": "85",
            "total-floor-area": "150.0",
        },
        {
            "lmk-key": "DEF0987654321",
            "address1": "456 Another Road",
            "address2": "",
            "postcode": "AN2 2TH",
            "uprn": "100023336959",
            "lodgement-date": "2025-11-20",
            "transaction-type": "rental",
            "current-energy-efficiency": "65",
            "potential-energy-efficiency": "78",
            "current-energy-rating": "D",
            "potential-energy-rating": "C",
            "property-type": "Flat",
            "built-form": "Mid-Terrace",
            "environmental-impact-current": "60",
            "environmental-impact-potential": "72",
            "total-floor-area": "75.5",
        },
        {
            # Duplicate UPRN with earlier date (should be filtered)
            "lmk-key": "GHI1111111111",
            "address1": "456 Another Road",
            "address2": "",
            "postcode": "AN2 2TH",
            "uprn": "100023336959",
            "lodgement-date": "2025-11-10",
            "transaction-type": "rental",
            "current-energy-efficiency": "62",
            "potential-energy-efficiency": "75",
            "current-energy-rating": "D",
            "potential-energy-rating": "C",
            "property-type": "Flat",
            "built-form": "Mid-Terrace",
            "environmental-impact-current": "58",
            "environmental-impact-potential": "70",
            "total-floor-area": "75.5",
        },
        {
            # Missing UPRN (should be filtered out)
            "lmk-key": "JKL2222222222",
            "address1": "789 No UPRN Street",
            "address2": "",
            "postcode": "NU3 3PR",
            "uprn": "",
            "lodgement-date": "2025-11-25",
            "transaction-type": "new dwelling",
            "current-energy-efficiency": "92",
            "potential-energy-efficiency": "95",
            "current-energy-rating": "A",
            "potential-energy-rating": "A",
            "property-type": "House",
            "built-form": "Detached",
            "environmental-impact-current": "90",
            "environmental-impact-potential": "93",
            "total-floor-area": "200.0",
        },
    ]


@pytest.fixture
def sample_normalized_records_domestic() -> list[dict[str, Any]]:
    """Provide sample normalized records (after column name transformation)."""
    return [
        {
            "LMK_KEY": "ABC1234567890",
            "ADDRESS1": "123 New Street",
            "ADDRESS2": "New Area",
            "POSTCODE": "NE1 1WS",
            "UPRN": "100023336958",
            "LODGEMENT_DATE": "2025-11-15",
            "TRANSACTION_TYPE": "marketed sale",
            "CURRENT_ENERGY_EFFICIENCY": "80",
            "POTENTIAL_ENERGY_EFFICIENCY": "90",
            "CURRENT_ENERGY_RATING": "B",
            "POTENTIAL_ENERGY_RATING": "A",
            "PROPERTY_TYPE": "House",
            "BUILT_FORM": "Semi-Detached",
            "ENVIRONMENT_IMPACT_CURRENT": "75",
            "ENVIRONMENT_IMPACT_POTENTIAL": "85",
            "TOTAL_FLOOR_AREA": "150.0",
        },
        {
            "LMK_KEY": "DEF0987654321",
            "ADDRESS1": "456 Another Road",
            "ADDRESS2": "",
            "POSTCODE": "AN2 2TH",
            "UPRN": "100023336959",
            "LODGEMENT_DATE": "2025-11-20",
            "TRANSACTION_TYPE": "rental",
            "CURRENT_ENERGY_EFFICIENCY": "65",
            "POTENTIAL_ENERGY_EFFICIENCY": "78",
            "CURRENT_ENERGY_RATING": "D",
            "POTENTIAL_ENERGY_RATING": "C",
            "PROPERTY_TYPE": "Flat",
            "BUILT_FORM": "Mid-Terrace",
            "ENVIRONMENT_IMPACT_CURRENT": "60",
            "ENVIRONMENT_IMPACT_POTENTIAL": "72",
            "TOTAL_FLOOR_AREA": "75.5",
        },
    ]


@pytest.fixture
def sample_csv_content() -> str:
    """Provide sample CSV content for testing."""
    return """LMK_KEY,ADDRESS1,POSTCODE,UPRN,LODGEMENT_DATE
ABC1234567890,123 New Street,NE1 1WS,100023336958,2025-11-15
DEF0987654321,456 Another Road,AN2 2TH,100023336959,2025-11-20
"""
