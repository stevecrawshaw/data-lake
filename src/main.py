from pathlib import Path

from utility.utils import convert_to_hive_partitioned, csv_to_parquet

ROOT = Path(__file__).parent.parent
# non domestic EPCs
convert_to_hive_partitioned(
    ROOT
    / "data_lake"
    / "landing"
    / "manual"
    / "epc_non_domestic"
    / "all-non-domestic-certificates",
    Path("data_lake") / "staging_parquet" / "epc_non_domestic",
)

convert_to_hive_partitioned(
    ROOT
    / "data_lake"
    / "landing"
    / "manual"
    / "epc_non_domestic"
    / "all-non-domestic-certificates",
    ROOT / "data_lake" / "staging_parquet" / "epc_non_domestic",
)
# domestic EPCs
convert_to_hive_partitioned(
    ROOT
    / "data_lake"
    / "landing"
    / "manual"
    / "epc_domestic"
    / "all-domestic-certificates",
    ROOT / "data_lake" / "staging_parquet" / "epc_domestic",
)

# ONS Postcode Lookups
csv_to_parquet(
    ROOT
    / "data_lake"
    / "landing"
    / "manual"
    / "PCD_OA21_LSOA21_MSOA21_LAD_NOV25_UK_LU.csv",
    ROOT / "data_lake" / "staging_parquet" / "ons_postcode_lookups.parquet",
)
# ONS Postcode Centroids
csv_to_parquet(
    ROOT
    / "data_lake"
    / "landing"
    / "manual"
    / "ONSPD_Online_latest_Postcode_Centroids_.csv",
    ROOT / "data_lake" / "staging_parquet" / "ons_postcode_centroids.parquet",
)

# IMD 2025 LSOA

csv_to_parquet(
    ROOT / "data_lake" / "landing" / "manual" / "imd2025_england_lsoa21.csv",
    ROOT / "data_lake" / "staging_parquet" / "imd2025_england_lsoa21.parquet",
)

# Emissions data

csv_to_parquet(
    ROOT
    / "data_lake"
    / "landing"
    / "manual"
    / "2005-23-uk-local-authority-ghg-emissions-CSV-dataset.csv",
    ROOT / "data_lake" / "staging_parquet" / "uk_emissions_by_lad.parquet",
)
