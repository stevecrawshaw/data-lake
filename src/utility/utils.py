import re
from pathlib import Path

import duckdb


def csv_to_parquet(input_csv, output_parquet):
    """
    Converts a single raw CSV to Parquet using DuckDB.
    Safe Mode: Reads everything as strings (all_varchar) to prevent
    failures during ingestion. Types are cast later in SQL (Silver Layer).
    """

    input_csv = Path(input_csv)
    if output_parquet is None:
        output_parquet = input_csv.with_suffix(".parquet")
    else:
        output_parquet = Path(output_parquet)

    print(f"Converting {input_csv.name}...")

    con = duckdb.connect()

    # Using read_csv_auto ensures it attempts to guess headers/delimiters
    # all_varchar=True is the 'Safety Valve' - it prevents the load from crashing
    # if column 5 is an Integer in row 1 but a String in row 10,000.
    # Use POSIX paths to avoid backslash escaping issues in SQL strings
    input_path = input_csv.as_posix()
    output_path = output_parquet.as_posix()
    query = f"""
        COPY (
            SELECT * FROM read_csv_auto(
                '{input_path}',
                all_varchar=True,
                filename=True
            )
        ) TO '{output_path}' (FORMAT PARQUET, COMPRESSION lz4)
    """  # noqa: S608

    try:
        con.execute(query)
        print(f"-> Saved to {output_parquet}")
    except Exception as e:
        print(f"Error converting {input_csv}: {e}")


def convert_to_hive_partitioned(source_root, staging_root):
    """
    Converts nested CSVs into a Hive Partitioned Parquet structure.

    Input:  source_root/camden/certificates.csv
    Output: staging_root/district=camden/data.parquet
    """

    source_path = Path(source_root)
    staging_path = Path(staging_root)

    # Find all CSVs
    all_csvs = list(source_path.rglob("*.csv"))
    print(f"Found {len(all_csvs)} CSV files to process.")

    con = duckdb.connect()

    for csv_file in all_csvs:
        # 1. Extract the folder name (e.g., 'camden')
        # parent.name gets the immediate folder name the file is sitting in
        match = re.search(r"(E|W)\d{8}", csv_file.parent.name)
        district_name = match.group() if match else csv_file.parent.name

        # 2. Define the output directory based on Hive syntax (key=value)
        # We sanitize the name to remove spaces or weird characters if necessary
        output_dir = staging_path / f"lad={district_name}"
        if str(output_dir).find("unknown") == -1:
            output_dir.mkdir(parents=True, exist_ok=True)

        output_file = output_dir / "data.parquet"

        print(f"Processing: {district_name} -> {output_file}")

        # 3. Convert ONLY this file
        # We don't need to add a 'district' column inside the data,
        # because the folder name acts as that column!
        try:
            csv_path = csv_file.as_posix()
            output_path = output_file.as_posix()
            if str(csv_path).find("unknown") == -1:
                con.execute(
                    f"""
                    COPY (
                        SELECT * FROM read_csv_auto(
                            '{csv_path}',
                            all_varchar=True
                        )
                    ) TO '{output_path}' (FORMAT PARQUET, COMPRESSION lz4);
                """  # noqa: S608
                )
            else:
                print(f"Skipping: {district_name} due to 'unknown' in path")
        except Exception as e:
            print(f"FAILED on {district_name}: {e}")
