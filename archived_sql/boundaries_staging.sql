-- VPN ON------------------------------
-- run from src/
duckdb 'data_lake/mca_env_base.duckdb'

SHOW TABLES;

INSTALL SPATIAL;
LOAD SPATIAL;

ATTACH '' AS weca_postgres (TYPE POSTGRES, SECRET weca_postgres);

-- List tables in ons schema
SELECT table_name, column_name 
FROM information_schema.columns 
WHERE table_schema = 'ons' AND table_name ILIKE '%lsoa%';

DESCRIBE (FROM weca_postgres.ons.lsoa_2021_lep LIMIT 1);
DESCRIBE (FROM weca_postgres.os.codepoint_open_lep LIMIT 1);
DESCRIBE (FROM weca_postgres.os.bdline_ua_lep_diss LIMIT 1);
DESCRIBE (FROM weca_postgres.os.bdline_ward_lep LIMIT 1);

-- get open UPRN LEP
CREATE OR REPLACE TABLE mca_env_base.open_uprn_lep_tbl AS
SELECT * FROM weca_postgres.os.open_uprn_lep;
    
-- get codepoint LEP boundaries
CREATE OR REPLACE TABLE mca_env_base.codepoint_open_lep_tbl AS
SELECT * FROM weca_postgres.os.codepoint_open_lep;

-- get LSOA boundaries
CREATE OR REPLACE TABLE mca_env_base.lsoa_2021_lep_tbl AS
SELECT * FROM weca_postgres.ons.lsoa_2021_lep;

-- get LEP boundaries
CREATE OR REPLACE TABLE mca_env_base.bdline_ua_lep_diss_tbl AS
SELECT * FROM weca_postgres.os.bdline_ua_lep_diss;

-- get WECA boundary
CREATE OR REPLACE TABLE mca_env_base.bdline_ua_weca_diss_tbl AS
SELECT * FROM weca_postgres.os.bdline_ua_weca_diss;

-- get UA boundaries
CREATE OR REPLACE TABLE mca_env_base.bdline_ua_lep_tbl AS
SELECT * FROM weca_postgres.os.bdline_ua_lep;

-- get ward boundaries
CREATE OR REPLACE TABLE mca_env_base.bdline_ward_lep_tbl AS
SELECT * FROM weca_postgres.os.bdline_ward_lep;

-- get CA boundaries
CREATE OR REPLACE TABLE mca_env_base.ca_boundaries_bgc_tbl AS
(SELECT * FROM ST_Read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/CAUTH_MAY_2025_EN_BGC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson'));

-- get CA LA lookups
CREATE OR REPLACE TABLE mca_env_base.ca_la_lookup_tbl AS
SELECT unnest(features, recursive := true) 
FROM read_json('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LAD25_CAUTH25_EN_LU/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=false&outSR=4326&f=json');

USE mca_env_base;

SHOW TABLES;

.quit
