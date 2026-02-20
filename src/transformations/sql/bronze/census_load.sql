-- Bronze Layer: Census and Geographic Reference Data Loading
-- Purpose: Load ONS census and geographic reference data
-- Source: Manual downloads from ONS and Humaniverse
-- Dependencies: CSV files must exist in landing/manual/
-- Tables Created:
--   - uk_lsoa_tenure_tbl
--   - postcode_centroids_tbl
--   - boundary_lookup_tbl

-- Load household tenure data by LSOA (2021 Census)
-- Source: Census 2021 household tenure by LSOA
CREATE OR REPLACE TABLE uk_lsoa_tenure_tbl AS
FROM read_csv(
    'data_lake/landing/manual/household_tenure21_lsoa21.csv',
    normalize_names = true
);

-- Load ONS Postcode Directory (ONSPD) centroid locations
-- Note: RUC (Rural-Urban Classification) columns stored as VARCHAR to preserve leading zeros
CREATE OR REPLACE TABLE postcode_centroids_tbl AS
FROM read_csv(
    'data_lake/landing/manual/ONSPD_Online_latest_Postcode_Centroids_.csv',
    types = {
        'ruc11ind': 'VARCHAR',
        'ruc21ind': 'VARCHAR',
        'ruc01ind': 'VARCHAR'
    },
    normalize_names = true
);

-- Load boundary hierarchy lookup table
-- Maps postcodes to Output Areas, LSOAs, MSOAs, and Local Authority Districts
CREATE OR REPLACE TABLE boundary_lookup_tbl AS
FROM read_csv(
    'data_lake/landing/manual/PCD_OA21_LSOA21_MSOA21_LAD_NOV25_UK_LU.csv',
    normalize_names = true
);
