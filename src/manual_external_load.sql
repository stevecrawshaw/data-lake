-- run from src/
duckdb '../data_lake/mca_env_base.duckdb';

--  not using auto schema ingest as domestic schema is wrong!
-- FROM read_json_auto('src/schemas/epc_domestic_certificates_schema.json') AS epc_domestic_certificates_schema;

-- 93 columns in single file domestic epc
-- schema file has wrong column names - should be ENVIRONMENT_IMPACT_CURRENT
-- not ENVIRONMENTAL_IMPACT_CURRENT (also POTENTIAL)

-- we need the bulk domestic data as a single file for this load  
-- https://epc.opendatacommunities.org/files/all-domestic-certificates-single-file.zip

CREATE OR REPLACE TABLE raw_domestic_epc_staging AS
FROM
read_csv(
    '../data_lake/landing/manual/epc_domestic/all-domestic-certificates-single-file/certificates.csv', 
    columns = {
  "LMK_KEY": "VARCHAR",
  "ADDRESS1": "VARCHAR",
  "ADDRESS2": "VARCHAR",
  "ADDRESS3": "VARCHAR",
  "POSTCODE": "VARCHAR",
  "BUILDING_REFERENCE_NUMBER": "VARCHAR",
  "CURRENT_ENERGY_RATING": "VARCHAR",
  "POTENTIAL_ENERGY_RATING": "VARCHAR",
  "CURRENT_ENERGY_EFFICIENCY": "BIGINT",
  "POTENTIAL_ENERGY_EFFICIENCY": "BIGINT",
  "PROPERTY_TYPE": "VARCHAR",
  "BUILT_FORM": "VARCHAR",
  "INSPECTION_DATE": "DATE",
  "LOCAL_AUTHORITY": "VARCHAR",
  "CONSTITUENCY": "VARCHAR",
  "COUNTY": "VARCHAR",
  "LODGEMENT_DATE": "DATE",
  "TRANSACTION_TYPE": "VARCHAR",
  "ENVIRONMENT_IMPACT_CURRENT": "BIGINT",
  "ENVIRONMENT_IMPACT_POTENTIAL": "BIGINT",
  "ENERGY_CONSUMPTION_CURRENT": "DOUBLE",
  "ENERGY_CONSUMPTION_POTENTIAL": "DOUBLE",
  "CO2_EMISSIONS_CURRENT": "DOUBLE",
  "CO2_EMISS_CURR_PER_FLOOR_AREA": "DOUBLE",
  "CO2_EMISSIONS_POTENTIAL": "DOUBLE",
  "LIGHTING_COST_CURRENT": "DOUBLE",
  "LIGHTING_COST_POTENTIAL": "DOUBLE",
  "HEATING_COST_CURRENT": "DOUBLE",
  "HEATING_COST_POTENTIAL": "DOUBLE",
  "HOT_WATER_COST_CURRENT": "DOUBLE",
  "HOT_WATER_COST_POTENTIAL": "DOUBLE",
  "TOTAL_FLOOR_AREA": "DOUBLE",
  "ENERGY_TARIFF": "VARCHAR",
  "MAINS_GAS_FLAG": "VARCHAR",
  "FLOOR_LEVEL": "VARCHAR",
  "FLAT_TOP_STOREY": "VARCHAR",
  "FLAT_STOREY_COUNT": "DOUBLE",
  "MAIN_HEATING_CONTROLS": "VARCHAR",
  "MULTI_GLAZE_PROPORTION": "DOUBLE",
  "GLAZED_TYPE": "VARCHAR",
  "GLAZED_AREA": "VARCHAR",
  "EXTENSION_COUNT": "BIGINT",
  "NUMBER_HABITABLE_ROOMS": "DOUBLE",
  "NUMBER_HEATED_ROOMS": "DOUBLE",
  "LOW_ENERGY_LIGHTING": "BIGINT",
  "NUMBER_OPEN_FIREPLACES": "BIGINT",
  "HOTWATER_DESCRIPTION": "VARCHAR",
  "HOT_WATER_ENERGY_EFF": "VARCHAR",
  "HOT_WATER_ENV_EFF": "VARCHAR",
  "FLOOR_DESCRIPTION": "VARCHAR",
  "FLOOR_ENERGY_EFF": "VARCHAR",
  "FLOOR_ENV_EFF": "VARCHAR",
  "WINDOWS_DESCRIPTION": "VARCHAR",
  "WINDOWS_ENERGY_EFF": "VARCHAR",
  "WINDOWS_ENV_EFF": "VARCHAR",
  "WALLS_DESCRIPTION": "VARCHAR",
  "WALLS_ENERGY_EFF": "VARCHAR",
  "WALLS_ENV_EFF": "VARCHAR",
  "SECONDHEAT_DESCRIPTION": "VARCHAR",
  "SHEATING_ENERGY_EFF": "VARCHAR",
  "SHEATING_ENV_EFF": "VARCHAR",
  "ROOF_DESCRIPTION": "VARCHAR",
  "ROOF_ENERGY_EFF": "VARCHAR",
  "ROOF_ENV_EFF": "VARCHAR",
  "MAINHEAT_DESCRIPTION": "VARCHAR",
  "MAINHEAT_ENERGY_EFF": "VARCHAR",
  "MAINHEAT_ENV_EFF": "VARCHAR",
  "MAINHEATCONT_DESCRIPTION": "VARCHAR",
  "MAINHEATC_ENERGY_EFF": "VARCHAR",
  "MAINHEATC_ENV_EFF": "VARCHAR",
  "LIGHTING_DESCRIPTION": "VARCHAR",
  "LIGHTING_ENERGY_EFF": "VARCHAR",
  "LIGHTING_ENV_EFF": "VARCHAR",
  "MAIN_FUEL": "VARCHAR",
  "WIND_TURBINE_COUNT": "DOUBLE",
  "HEAT_LOSS_CORRIDOR": "VARCHAR",
  "UNHEATED_CORRIDOR_LENGTH": "DOUBLE",
  "FLOOR_HEIGHT": "DOUBLE",
  "PHOTO_SUPPLY": "DOUBLE",
  "SOLAR_WATER_HEATING_FLAG": "VARCHAR",
  "MECHANICAL_VENTILATION": "VARCHAR",
  "ADDRESS": "VARCHAR",
  "LOCAL_AUTHORITY_LABEL": "VARCHAR",
  "CONSTITUENCY_LABEL": "VARCHAR",
  "POSTTOWN": "VARCHAR",
  "CONSTRUCTION_AGE_BAND": "VARCHAR",
  "LODGEMENT_DATETIME": "TIMESTAMP",
  "TENURE": "VARCHAR",
  "FIXED_LIGHTING_OUTLETS_COUNT": "DOUBLE",
  "LOW_ENERGY_FIXED_LIGHT_COUNT": "DOUBLE",
  "UPRN": "BIGINT",
  "UPRN_SOURCE": "VARCHAR",
  "REPORT_TYPE": "BIGINT"
}, ignore_errors = true 
);





CREATE OR REPLACE TABLE raw_domestic_epc_certificates_tbl AS
SELECT c.*
FROM raw_domestic_epc_staging c
INNER JOIN (
    SELECT UPRN, MAX(LODGEMENT_DATETIME) as max_date
    FROM raw_domestic_epc_staging
    GROUP BY UPRN
) latest ON c.UPRN = latest.UPRN 
    AND c.LODGEMENT_DATETIME = latest.max_date;

DROP TABLE raw_domestic_epc_staging;


-- NOW DO NON DOMESTIC TOO

CREATE OR REPLACE TABLE raw_non_domestic_epc_staging AS
FROM
read_csv(
    '../data_lake/landing/manual/epc_non_domestic/all-non-domestic-certificates/all-non-domestic-certificates-single-file/certificates.csv', 
    columns = {
  "LMK_KEY": "VARCHAR",
  "ADDRESS1": "VARCHAR",
  "ADDRESS2": "VARCHAR",
  "ADDRESS3": "VARCHAR",
  "POSTCODE": "VARCHAR",
  "BUILDING_REFERENCE_NUMBER": "VARCHAR",
  "ASSET_RATING": "BIGINT",
  "ASSET_RATING_BAND": "VARCHAR",
  "PROPERTY_TYPE": "VARCHAR",
  "INSPECTION_DATE": "DATE",
  "LOCAL_AUTHORITY": "VARCHAR",
  "CONSTITUENCY": "VARCHAR",
  "COUNTY": "VARCHAR",
  "LODGEMENT_DATE": "DATE",
  "TRANSACTION_TYPE": "VARCHAR",
  "NEW_BUILD_BENCHMARK": "VARCHAR",
  "EXISTING_STOCK_BENCHMARK": "VARCHAR",
  "BUILDING_LEVEL": "VARCHAR",
  "MAIN_HEATING_FUEL": "VARCHAR",
  "OTHER_FUEL_DESC": "VARCHAR",
  "SPECIAL_ENERGY_USES": "VARCHAR",
  "RENEWABLE_SOURCES": "VARCHAR",
  "FLOOR_AREA": "BIGINT",
  "STANDARD_EMISSIONS": "DOUBLE",
  "TARGET_EMISSIONS": "DOUBLE",
  "TYPICAL_EMISSIONS": "DOUBLE",
  "BUILDING_EMISSIONS": "DOUBLE",
  "AIRCON_PRESENT": "VARCHAR",
  "AIRCON_KW_RATING": "DOUBLE",
  "ESTIMATED_AIRCON_KW_RATING": "DOUBLE",
  "AC_INSPECTION_COMMISSIONED": "BIGINT",
  "BUILDING_ENVIRONMENT": "VARCHAR",
  "ADDRESS": "VARCHAR",
  "LOCAL_AUTHORITY_LABEL": "VARCHAR",
  "CONSTITUENCY_LABEL": "VARCHAR",
  "POSTTOWN": "VARCHAR",
  "LODGEMENT_DATETIME": "VARCHAR",
  "PRIMARY_ENERGY_VALUE": "BIGINT",
  "UPRN": "BIGINT",
  "UPRN_SOURCE": "VARCHAR",
  "REPORT_TYPE": "BIGINT"
}, ignore_errors = true 
);

CREATE OR REPLACE TABLE raw_non_domestic_epc_certificates_tbl AS
SELECT c.*
FROM raw_non_domestic_epc_staging c
INNER JOIN (
    SELECT UPRN, MAX(LODGEMENT_DATETIME) as max_date
    FROM raw_non_domestic_epc_staging
    GROUP BY UPRN
) latest ON c.UPRN = latest.UPRN 
    AND c.LODGEMENT_DATETIME = latest.max_date;

DROP TABLE raw_non_domestic_epc_staging;


-- EMISSIONS (ghg long)

CREATE OR REPLACE TABLE la_ghg_emissions_tbl AS
FROM
read_csv('../data_lake/landing/manual/2005-23-uk-local-authority-ghg-emissions-CSV-dataset.csv',
normalize_names = true);

-- EMISSIONS (ghg wide)

CREATE OR REPLACE TABLE la_ghg_emissions_wide_tbl AS
FROM
read_xlsx('../data_lake/landing/manual/2005-23-uk-local-authority-ghg-emissions.xlsx',
sheet = '1_1',
range = 'A5:AX7662',
normalize_names = true);


-- TENURE

CREATE OR REPLACE TABLE uk_lsoa_tenure_tbl AS
FROM
read_csv('../data_lake/landing/manual/household_tenure21_lsoa21.csv',
normalize_names = true);

-- IMD

CREATE OR REPLACE TABLE eng_lsoa_imd_tbl AS
FROM
read_csv('../data_lake/landing/manual/imd2025_england_lsoa21.csv',
normalize_names = true);

-- POSTCODE DATA
CREATE OR REPLACE TABLE postcode_centroids_tbl AS
FROM
read_csv('../data_lake/landing/manual/ONSPD_Online_latest_Postcode_Centroids_.csv',
types = {
    'ruc11ind':'VARCHAR',
    'ruc21ind':'VARCHAR',
    'ruc01ind':'VARCHAR'
},
normalize_names = true
);

-- BOUNDARY LOOKUP

CREATE OR REPLACE TABLE boundary_lookup_tbl AS
FROM
read_csv('../data_lake/landing/manual/PCD_OA21_LSOA21_MSOA21_LAD_NOV25_UK_LU.csv',
normalize_names = true);

-- WECA BOUNDARY AND POSTGRES DATA



