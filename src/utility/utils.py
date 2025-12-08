import json
import re
import shutil
import zipfile
from pathlib import Path

import dotenv
import duckdb
import httpx
import polars as pl

"""
run download_zip for domestic and non-domestic to get
sample zips
which contain the columns.csv files.

run extract_columns_csv_from_zip on each zip to get the raw columns csvs

run create_epc_schema on each raw columns csv to generate the schema jsons

This will create:
- ../../src/schemas/epc_domestic_certificates_schema.json
- ../../src/schemas/epc_non-domestic_certificates_schema.json

You can then use these schema jsons in the csv_to_parquet function below
to convert CSVs to Parquet using the correct types.

"""

# with open("../schemas/epc_domestic_certificates_schema.json") as f:
#     EPC_DOMESTIC_SCHEMA = json.load(f)["schema_map"]

EPC_AUTH_TOKEN = dotenv.dotenv_values("../../.env").get("AUTH_TOKEN")
print(f"EPC_AUTH_TOKEN found: {EPC_AUTH_TOKEN is not None}")


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


def convert_to_hive_partitioned(source_root: str, staging_root: str, type: str):
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

    if type == "domestic":
        with open("../../src/schemas/epc_domestic_certificates_schema.json") as f:
            EPC_SCHEMA = json.load(f)
    elif type == "non-domestic":
        with open("../../src/schemas/epc_non-domestic_certificates_schema.json") as f:
            EPC_SCHEMA = json.load(f)

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
                        SELECT * FROM read_csv(
                            '{csv_path}',
                            types = {EPC_SCHEMA}
                        )
                    ) TO '{output_path}' (FORMAT PARQUET, COMPRESSION lz4);
                """  # noqa: S608
                )
            else:
                print(f"Skipping: {district_name} due to 'unknown' in path")
        except Exception as e:
            print(f"FAILED on {district_name}: {e}")


def download_zip(
    url: str,
    directory: str = "../data_lake/landing/automated",
    filename: str | None = None,
    auth_token: str | None = EPC_AUTH_TOKEN,
) -> str:
    """
    Downloads a zip file from the given URL
    and saves it to the specified directory with an optional custom filename.

    Args:
        url (str): The URL of the zip file to download.
        directory (str): The directory where the zip file will be saved.
        Defaults to "../data_lake/landing/automated".
        filename (str, optional):
        The name to save the zip file as.
        If not provided, the name is extracted from the URL.

    Returns:
        str: The full path to the downloaded file.
    """
    # Create a Path object for the directory
    directory_path = Path(directory)

    # Ensure the directory exists, create it if it doesn't
    directory_path.mkdir(parents=True, exist_ok=True)

    # Use the provided filename or extract the filename from the URL
    if not filename:
        filename = url.split("/")[-1]

    # Create the full file path
    file_path = directory_path / filename
    headers = {}
    if auth_token:
        headers = {"Authorization": f"Basic {auth_token}"}
    r = httpx.get(url, headers=headers, follow_redirects=True, timeout=10)
    r.raise_for_status()  # Check if the request was successful
    with file_path.open("wb") as f:
        f.write(r.content)

    print(f"Downloaded {len(r.content):,} bytes to {file_path}")
    return str(file_path)


def extract_columns_csv_from_zip(zip_file_path: str, type: str = "domestic") -> str:
    """
    Extracts the columns.csv file from the given zip file

    Args:
        zip_file_path (str): The path to the zip file.
        domestic (bool): Whether source is domestic or non-domestic CSV.

    Returns:
        str: The path to the extracted CSV file.

    Raises:
        FileNotFoundError: If no CSV file is found inside the zip.
        ValueError: If multiple or no CSV files
        are found in the immediate 'Data' folder.
    """

    zip_file = Path(zip_file_path)
    extract_path = Path("../schemas/")  # Extract to the same directory

    # Ensure the zip file exists
    if not zip_file.exists():
        raise FileNotFoundError(f"Zip file '{zip_file}' does not exist.")

    # Open the zip file
    with zipfile.ZipFile(zip_file, "r") as z:
        # List all files in the zip archive
        all_files = z.namelist()

        # Filter for CSV files in the immediate 'Data/' folder (no subfolders)
        csv_files = [f for f in all_files if f == "columns.csv"]

        # Ensure there's exactly one CSV file in the immediate 'Data' folder
        if len(csv_files) == 0:
            raise FileNotFoundError("No CSV file found inside the zip.")
        # Extract the CSV file without the 'Data/' folder structure
        csv_file = csv_files[0]
        if type == "domestic":
            csv_filename = Path(f"domestic-columns-raw-{csv_file}").name
        elif type == "non-domestic":
            csv_filename = Path(f"non-domestic-columns-raw-{csv_file}").name
            # Get only the file name, ignoring the folder
        extracted_csv_path = extract_path / csv_filename
        # Extract the file, but rename it to remove the folder structure
        with (
            z.open(csv_file) as source,
            extracted_csv_path.open("wb") as target,
        ):
            shutil.copyfileobj(source, target)

        return str(extracted_csv_path)


def create_epc_schema(
    csv_file_path: str,
    epc_type: str = "domestic",
) -> Path:
    """
    Creates a schema json file from the given CSV file.

    Args:
        csv_file_path (str): The path to the CSV file.
    """
    type_strings_expr: pl.Expr = (
        pl.when(pl.col("datatype") == "integer")
        .then(pl.lit("BIGINT"))
        .when(pl.col("datatype") == "date")
        .then(pl.lit("DATE"))
        .when(pl.col("datatype") == "decimal")
        .then(pl.lit("DOUBLE"))
        .when(pl.col("datatype") == "float")
        .then(pl.lit("DOUBLE"))
        .when(pl.col("datatype") == "datetime")
        .then(pl.lit("TIMESTAMP"))
        .otherwise(pl.lit("VARCHAR"))
        .alias("type")
    )

    raw_schema_df = pl.read_csv(csv_file_path)
    schema_df = raw_schema_df.select(pl.col("column"), type_strings_expr)
    output_file_path = Path(
        f"../../src/schemas/epc_{epc_type}_certificates_schema.json"
    )
    json_data = dict(zip(schema_df["column"], schema_df["type"], strict=True))
    with open(output_file_path, "w") as f:
        json.dump(json_data, f, indent=2)

    print(f"Schema saved to {output_file_path}")
    return output_file_path


# testing raw schema extraction-------------------------

# testing zip download
url_dom = "https://epc.opendatacommunities.org/api/v1/files/domestic-E06000023-Bristol-City-of.zip"

url_non_dom = "https://epc.opendatacommunities.org/api/v1/files/non-domestic-E06000023-Bristol-City-of.zip"

download_zip(
    url_non_dom,
    filename="non-domestic-bristol.zip",
    directory="../../data_lake/landing/automated",
    auth_token=EPC_AUTH_TOKEN,
)

download_zip(
    url_dom,
    filename="domestic-bristol.zip",
    directory="../../data_lake/landing/automated",
    auth_token=EPC_AUTH_TOKEN,
)


extract_columns_csv_from_zip(
    "../../data_lake/landing/automated/domestic-bristol.zip", type="domestic"
)

extract_columns_csv_from_zip(
    "../../data_lake/landing/automated/non-domestic-bristol.zip", type="non-domestic"
)


# testing schema

create_epc_schema(
    "../../src/schemas/domestic-columns-raw-columns.csv", epc_type="domestic"
)

create_epc_schema(
    "../../src/schemas/non-domestic-columns-raw-columns.csv", epc_type="non-domestic"
)
