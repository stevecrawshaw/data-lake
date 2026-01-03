"""Test script to verify DuckDB read_csv + UNION ALL BY NAME approach.

This tests the proposed refactor before implementing in epc_api_client.py
"""

import io

import duckdb


def test_union_by_name_from_csv_strings() -> None:
    """Test combining multiple CSV strings using UNION ALL BY NAME."""
    # Simulate API responses (3 pages with different column orders)
    page1_csv = """UPRN,LODGEMENT_DATE,ENERGY_RATING
100001,2024-01-15,C
100002,2024-01-16,B"""

    page2_csv = """ENERGY_RATING,UPRN,LODGEMENT_DATE
D,100003,2024-01-17
A,100004,2024-01-18"""

    page3_csv = """LODGEMENT_DATE,UPRN,ENERGY_RATING
2024-01-19,100005,B
2024-01-20,100006,C"""

    # Create DuckDB connection
    con = duckdb.connect()

    # Read each CSV into a relation
    rel1 = con.read_csv(io.StringIO(page1_csv))
    rel2 = con.read_csv(io.StringIO(page2_csv))
    rel3 = con.read_csv(io.StringIO(page3_csv))

    print(f"Page 1: {rel1.count('*').fetchone()[0]} rows")
    print(f"Page 2: {rel2.count('*').fetchone()[0]} rows")
    print(f"Page 3: {rel3.count('*').fetchone()[0]} rows")

    # Combine using UNION ALL BY NAME
    combined = con.sql(
        """
        SELECT * FROM rel1
        UNION ALL BY NAME
        SELECT * FROM rel2
        UNION ALL BY NAME
        SELECT * FROM rel3
    """
    )

    print(f"Combined total: {combined.count('*').fetchone()[0]} rows")

    # Convert to list of dicts (API compatibility)
    records = combined.fetchall()
    columns = [desc[0] for desc in combined.description]

    records_as_dicts = [dict(zip(columns, row)) for row in records]

    print(f"\nTotal records: {len(records_as_dicts)}")
    print("\nFirst record as dict:")
    print(records_as_dicts[0])

    # Verify all records present
    assert len(records_as_dicts) == 6, f"Expected 6 records, got {len(records_as_dicts)}"

    # Verify column alignment (all should have same keys)
    assert all(
        set(r.keys()) == {"UPRN", "LODGEMENT_DATE", "ENERGY_RATING"}
        for r in records_as_dicts
    ), "Column names not consistent"

    print("\n[PASS] Test passed: UNION ALL BY NAME works correctly!")

    con.close()


def test_alternative_approach_list_comprehension() -> None:
    """Test alternative: append relations to list and union dynamically."""
    csv_responses = [
        """UPRN,LODGEMENT_DATE,ENERGY_RATING
100001,2024-01-15,C
100002,2024-01-16,B""",
        """ENERGY_RATING,UPRN,LODGEMENT_DATE
D,100003,2024-01-17
A,100004,2024-01-18""",
    ]

    con = duckdb.connect()

    # Collect relations
    relations = []
    for idx, csv_str in enumerate(csv_responses):
        rel = con.read_csv(io.StringIO(csv_str))
        # Register relation with unique name
        con.register(f"page_{idx}", rel)
        relations.append(f"page_{idx}")

    # Build dynamic UNION query
    union_query = " UNION ALL BY NAME ".join(f"SELECT * FROM {r}" for r in relations)
    combined = con.sql(union_query)

    row_count = combined.count("*").fetchone()[0]
    print(f"\nAlternative approach - Dynamic UNION: {row_count} rows")

    assert row_count == 4

    print("\n[PASS] Alternative approach works!")

    con.close()


if __name__ == "__main__":
    print("=" * 60)
    print("Testing DuckDB read_csv + UNION ALL BY NAME")
    print("=" * 60)

    test_union_by_name_from_csv_strings()

    print("\n" + "=" * 60)
    test_alternative_approach_list_comprehension()
    print("=" * 60)
