-- Bronze Layer: EPC Certificate Loading
-- Purpose: Load domestic and non-domestic EPC certificates from manual CSV drop zone
-- Pattern: Staging table → deduplication by UPRN → keep latest lodgement
-- Source: Manual download from https://epc.opendatacommunities.org
-- Dependencies: CSV files must exist in landing/manual/ directories
-- Tables Created:
--   - raw_domestic_epc_certificates_tbl
--   - raw_non_domestic_epc_certificates_tbl

-- ===========================
-- DOMESTIC EPC CERTIFICATES
-- ===========================

-- Stage 1: Load all domestic certificates into staging table
-- Schema: 93 columns (explicit schema needed due to column name inconsistencies)
-- Note: Schema file has wrong column names (ENVIRONMENT_IMPACT vs ENVIRONMENTAL_IMPACT)
CREATE OR REPLACE TABLE raw_domestic_epc_staging AS
FROM read_csv(
    'data_lake/landing/manual/epc_domestic/all-domestic-certificates-single-file/certificates.csv',
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
    },
    ignore_errors = true
);

-- Stage 2: Deduplicate - keep only latest certificate per UPRN
CREATE OR REPLACE TABLE raw_domestic_epc_certificates_tbl AS
SELECT c.*
FROM raw_domestic_epc_staging c
INNER JOIN (
    SELECT UPRN, MAX(LODGEMENT_DATETIME) as max_date
    FROM raw_domestic_epc_staging
    GROUP BY UPRN
) latest ON c.UPRN = latest.UPRN
    AND c.LODGEMENT_DATETIME = latest.max_date;

-- Stage 3: Clean up staging table
DROP TABLE raw_domestic_epc_staging;


-- ===============================
-- NON-DOMESTIC EPC CERTIFICATES
-- ===============================

-- Stage 1: Load all non-domestic certificates into staging table
-- Schema: 40 columns
CREATE OR REPLACE TABLE raw_non_domestic_epc_staging AS
FROM read_csv(
    'data_lake/landing/manual/epc_non_domestic/all-non-domestic-certificates/all-non-domestic-certificates-single-file/certificates.csv',
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
    },
    ignore_errors = true
);

-- Stage 2: Deduplicate - keep only latest certificate per UPRN
CREATE OR REPLACE TABLE raw_non_domestic_epc_certificates_tbl AS
SELECT c.*
FROM raw_non_domestic_epc_staging c
INNER JOIN (
    SELECT UPRN, MAX(LODGEMENT_DATETIME) as max_date
    FROM raw_non_domestic_epc_staging
    GROUP BY UPRN
) latest ON c.UPRN = latest.UPRN
    AND c.LODGEMENT_DATETIME = latest.max_date;

-- Stage 3: Clean up staging table
DROP TABLE raw_non_domestic_epc_staging;
