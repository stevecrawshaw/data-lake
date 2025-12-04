-- VPN ON------------------------------

./duckdb.exe '../data_lake/weca_duckdb.db'

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
CREATE OR REPLACE TABLE weca_duckdb.open_uprn_lep AS
SELECT * FROM weca_postgres.os.open_uprn_lep;

-- get codepoint LEP boundaries
CREATE OR REPLACE TABLE weca_duckdb.codepoint_open_lep AS
SELECT * FROM weca_postgres.os.codepoint_open_lep;

-- get LSOA boundaries
CREATE OR REPLACE TABLE weca_duckdb.lsoa_2021_lep AS
SELECT * FROM weca_postgres.ons.lsoa_2021_lep;

-- get LEP boundaries
CREATE OR REPLACE TABLE weca_duckdb.bdline_ua_lep_diss AS
SELECT * FROM weca_postgres.os.bdline_ua_lep_diss;

-- get WECA boundary
CREATE OR REPLACE TABLE weca_duckdb.bdline_ua_weca_diss AS
SELECT * FROM weca_postgres.os.bdline_ua_weca_diss;

-- get UA boundaries
CREATE OR REPLACE TABLE weca_duckdb.bdline_ua_lep AS
SELECT * FROM weca_postgres.os.bdline_ua_lep;

-- get ward boundaries
CREATE OR REPLACE TABLE weca_duckdb.bdline_ward_lep AS
SELECT * FROM weca_postgres.os.bdline_ward_lep;

-- get CA boundaries
CREATE OR REPLACE TABLE weca_duckdb.ca_boundaries_bgc_tbl AS
(SELECT * FROM ST_Read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/CAUTH_MAY_2025_EN_BGC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson'));

-- get CA LA lookups
CREATE OR REPLACE TABLE weca_duckdb.ca_la_lookup AS
SELECT unnest(features, recursive := true) 
FROM read_json('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LAD25_CAUTH25_EN_LU/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=false&outSR=4326&f=json');

USE weca_duckdb;

SHOW TABLES;

.quit
