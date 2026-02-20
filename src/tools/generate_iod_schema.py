# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "duckdb>=1.4.0",
# ]
# ///
"""Generate Bronze SQL and XML schema for IoD 2025 File 7.

One-off generator script that reads CSV headers from the IoD 2025 File 7,
validates them against a hand-crafted mapping, and produces:
  - src/transformations/sql/bronze/iod_load.sql  (CREATE TABLE with aliased columns)
  - src/schemas/documentation/iod2025_schema.xml (XML schema for comment generation)

Usage:
    uv run src/tools/generate_iod_schema.py
"""

from pathlib import Path

import duckdb

# -- Configuration ----------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
CSV_PATH = (
    PROJECT_ROOT
    / "data_lake"
    / "landing"
    / "manual"
    / "File_7_IoD2025_All_Ranks_Scores_Deciles_Population_Denominators.csv"
)
SQL_OUTPUT = PROJECT_ROOT / "src" / "transformations" / "sql" / "bronze" / "iod_load.sql"
XML_OUTPUT = PROJECT_ROOT / "src" / "schemas" / "documentation" / "iod2025_schema.xml"
TABLE_NAME = "iod2025_tbl"

# -- Column mapping: original CSV header -> short snake_case name -----------

COLUMN_MAP: dict[str, str] = {
    "LSOA code (2021)": "lsoa_cd",
    "LSOA name (2021)": "lsoa_nm",
    "Local Authority District code (2024)": "la_cd",
    "Local Authority District name (2024)": "la_nm",
    "Index of Multiple Deprivation (IMD) Score": "imd_score",
    "Index of Multiple Deprivation (IMD) Rank (where 1 is most deprived)": "imd_rank",
    "Index of Multiple Deprivation (IMD) Decile (where 1 is most deprived 10% of LSOAs)": "imd_decile",
    "Income Score (rate)": "income_score",
    "Income Rank (where 1 is most deprived)": "income_rank",
    "Income Decile (where 1 is most deprived 10% of LSOAs)": "income_decile",
    "Employment Score (rate)": "employment_score",
    "Employment Rank (where 1 is most deprived)": "employment_rank",
    "Employment Decile (where 1 is most deprived 10% of LSOAs)": "employment_decile",
    "Education, Skills and Training Score": "education_score",
    "Education, Skills and Training Rank (where 1 is most deprived)": "education_rank",
    "Education, Skills and Training Decile (where 1 is most deprived 10% of LSOAs)": "education_decile",
    "Health Deprivation and Disability Score": "health_score",
    "Health Deprivation and Disability Rank (where 1 is most deprived)": "health_rank",
    "Health Deprivation and Disability Decile (where 1 is most deprived 10% of LSOAs)": "health_decile",
    "Crime Score": "crime_score",
    "Crime Rank (where 1 is most deprived)": "crime_rank",
    "Crime Decile (where 1 is most deprived 10% of LSOAs)": "crime_decile",
    "Barriers to Housing and Services Score": "barriers_score",
    "Barriers to Housing and Services Rank (where 1 is most deprived)": "barriers_rank",
    "Barriers to Housing and Services Decile (where 1 is most deprived 10% of LSOAs)": "barriers_decile",
    "Living Environment Score": "living_env_score",
    "Living Environment Rank (where 1 is most deprived)": "living_env_rank",
    "Living Environment Decile (where 1 is most deprived 10% of LSOAs)": "living_env_decile",
    "Income Deprivation Affecting Children Index (IDACI) Score (rate)": "idaci_score",
    "Income Deprivation Affecting Children Index (IDACI) Rank (where 1 is most deprived)": "idaci_rank",
    "Income Deprivation Affecting Children Index (IDACI) Decile (where 1 is most deprived 10% of LSOAs)": "idaci_decile",
    "Income Deprivation Affecting Older People (IDAOPI) Score (rate)": "idaopi_score",
    "Income Deprivation Affecting Older People (IDAOPI) Rank (where 1 is most deprived)": "idaopi_rank",
    "Income Deprivation Affecting Older People (IDAOPI) Decile (where 1 is most deprived 10% of LSOAs)": "idaopi_decile",
    "Children and Young People Sub-domain Score": "cyp_sub_score",
    "Children and Young People Sub-domain Rank (where 1 is most deprived)": "cyp_sub_rank",
    "Children and Young People Sub-domain Decile (where 1 is most deprived 10% of LSO": "cyp_sub_decile",
    "Adult Skills Sub-domain Score": "adult_skills_sub_score",
    "Adult Skills Sub-domain Rank (where 1 is most deprived)": "adult_skills_sub_rank",
    "Adult Skills Sub-domain Decile (where 1 is most deprived 10% of LSOAs)": "adult_skills_sub_decile",
    "Geographical Barriers Sub-domain Score": "geo_barriers_sub_score",
    "Geographical Barriers Sub-domain Rank (where 1 is most deprived)": "geo_barriers_sub_rank",
    "Geographical Barriers Sub-domain Decile (where 1 is most deprived 10% of LSOAs)": "geo_barriers_sub_decile",
    "Wider Barriers Sub-domain Score": "wider_barriers_sub_score",
    "Wider Barriers Sub-domain Rank (where 1 is most deprived)": "wider_barriers_sub_rank",
    "Wider Barriers Sub-domain Decile (where 1 is most deprived 10% of LSOAs)": "wider_barriers_sub_decile",
    "Indoors Sub-domain Score": "indoors_sub_score",
    "Indoors Sub-domain Rank (where 1 is most deprived)": "indoors_sub_rank",
    "Indoors Sub-domain Decile (where 1 is most deprived 10% of LSOAs)": "indoors_sub_decile",
    "Outdoors Sub-domain Score": "outdoors_sub_score",
    "Outdoors Sub-domain Rank (where 1 is most deprived)": "outdoors_sub_rank",
    "Outdoors Sub-domain Decile (where 1 is most deprived 10% of LSOAs)": "outdoors_sub_decile",
    "Total population: mid 2022": "total_pop",
    "Dependent Children aged 0-15: mid 2022": "children_pop",
    "Older population aged 60 and over: mid 2022": "older_pop",
    "Working age population 18-66 (for use with Employment Deprivation Domain): mid 2022": "working_age_pop",
}


def read_csv_headers(csv_path: Path) -> list[str]:
    """Read headers from CSV file using DuckDB."""
    conn = duckdb.connect()
    result = conn.execute(
        f"SELECT * FROM read_csv('{csv_path.as_posix()}') LIMIT 0"
    )
    headers = [desc[0] for desc in result.description]
    conn.close()
    return headers


def get_column_types(csv_path: Path) -> dict[str, str]:
    """Get DuckDB-inferred column types from the CSV."""
    conn = duckdb.connect()
    result = conn.execute(
        f"DESCRIBE SELECT * FROM read_csv('{csv_path.as_posix()}')"
    )
    types = {row[0]: row[1] for row in result.fetchall()}
    conn.close()
    return types


def validate_mapping(headers: list[str]) -> None:
    """Validate all CSV headers are in the mapping and vice versa."""
    header_set = set(headers)
    map_set = set(COLUMN_MAP.keys())

    missing_from_map = header_set - map_set
    extra_in_map = map_set - header_set

    if missing_from_map:
        raise ValueError(
            f"CSV headers not in COLUMN_MAP:\n"
            + "\n".join(f"  - {h!r}" for h in sorted(missing_from_map))
        )
    if extra_in_map:
        raise ValueError(
            f"COLUMN_MAP entries not in CSV:\n"
            + "\n".join(f"  - {h!r}" for h in sorted(extra_in_map))
        )

    # Check for duplicate short names
    short_names = list(COLUMN_MAP.values())
    dupes = {n for n in short_names if short_names.count(n) > 1}
    if dupes:
        raise ValueError(f"Duplicate short names: {dupes}")


def generate_sql(headers: list[str]) -> str:
    """Generate Bronze layer SQL with aliased columns."""
    csv_rel = "data_lake/landing/manual/File_7_IoD2025_All_Ranks_Scores_Deciles_Population_Denominators.csv"

    lines = [
        "-- Bronze Layer: Index of Deprivation (IoD) 2025 Loading",
        "-- Purpose: Load IoD 2025 File 7 with all ranks, scores, deciles, and population denominators",
        "-- Source: DLUHC IoD 2025 File 7 (manual download)",
        "-- Geography: England LSOAs (2021 boundaries)",
        f"-- Table Created: {TABLE_NAME}",
        "",
        f"CREATE OR REPLACE TABLE {TABLE_NAME} AS",
        "SELECT",
    ]

    col_lines = []
    for header in headers:
        short = COLUMN_MAP[header]
        col_lines.append(f'    "{header}" AS {short}')

    lines.append(",\n".join(col_lines))
    lines.append(f"FROM read_csv('{csv_rel}');")
    lines.append("")

    return "\n".join(lines)


def generate_xml(headers: list[str], types: dict[str, str]) -> str:
    """Generate XML schema for comment generation."""
    lines = [
        "<?xml version='1.0' encoding='UTF-8'?>",
        "<schema>",
        f'  <table name="{TABLE_NAME}">',
        "    <description>Index of Deprivation (IoD) 2025 File 7 - all ranks, scores, deciles, and population denominators by LSOA (England)</description>",
    ]

    for header in headers:
        short = COLUMN_MAP[header]
        col_type = types.get(header, "VARCHAR")
        # Use the original verbose header as the description
        desc = header.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        lines.append(f'    <column name="{short}">')
        lines.append(f"      <type>{col_type}</type>")
        lines.append(f"      <description>{desc}</description>")
        lines.append("    </column>")

    lines.append("  </table>")
    lines.append("</schema>")
    lines.append("")

    return "\n".join(lines)


def main() -> None:
    """Generate Bronze SQL and XML schema for IoD 2025."""
    if not CSV_PATH.exists():
        raise FileNotFoundError(f"CSV not found: {CSV_PATH}")

    print(f"Reading headers from: {CSV_PATH.name}")
    headers = read_csv_headers(CSV_PATH)
    print(f"Found {len(headers)} columns")

    print("Validating column mapping...")
    validate_mapping(headers)
    print("All headers mapped successfully")

    print("Getting column types...")
    types = get_column_types(CSV_PATH)

    print(f"Generating SQL: {SQL_OUTPUT.relative_to(PROJECT_ROOT)}")
    sql = generate_sql(headers)
    SQL_OUTPUT.write_text(sql, encoding="utf-8")

    print(f"Generating XML: {XML_OUTPUT.relative_to(PROJECT_ROOT)}")
    xml = generate_xml(headers, types)
    XML_OUTPUT.write_text(xml, encoding="utf-8")

    print(f"\nDone. {len(headers)} columns mapped to {TABLE_NAME}")
    print(f"  SQL: {SQL_OUTPUT}")
    print(f"  XML: {XML_OUTPUT}")


if __name__ == "__main__":
    main()
