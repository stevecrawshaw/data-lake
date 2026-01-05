-- Bronze Layer: Boundaries from Federated PostGIS
-- Purpose: Load UK boundaries from corporate PostGIS database (requires VPN connection)
-- Source: Corporate PostGIS database via postgres_scanner
-- Dependencies: Requires DuckDB secret 'weca_postgres' to be configured
-- VPN Required: YES
-- Tables Created:
--   - open_uprn_lep_tbl
--   - codepoint_open_lep_tbl
--   - lsoa_2021_lep_tbl
--   - bdline_ua_lep_diss_tbl
--   - bdline_ua_weca_diss_tbl
--   - bdline_ua_lep_tbl
--   - bdline_ward_lep_tbl

-- Install and load spatial extension
INSTALL SPATIAL;
LOAD SPATIAL;

-- Attach PostGIS database using configured secret
ATTACH '' AS weca_postgres (TYPE POSTGRES, SECRET weca_postgres);

-- Load open UPRN (Unique Property Reference Number) boundaries
CREATE OR REPLACE TABLE open_uprn_lep_tbl AS
SELECT * FROM weca_postgres.os.open_uprn_lep;

-- Load Codepoint Open (postcode locations) boundaries
CREATE OR REPLACE TABLE codepoint_open_lep_tbl AS
SELECT * FROM weca_postgres.os.codepoint_open_lep;

-- Load LSOA 2021 (Lower Layer Super Output Area) boundaries
CREATE OR REPLACE TABLE lsoa_2021_lep_tbl AS
SELECT * FROM weca_postgres.ons.lsoa_2021_lep;

-- Load LEP (Local Enterprise Partnership) dissolved boundaries
CREATE OR REPLACE TABLE bdline_ua_lep_diss_tbl AS
SELECT * FROM weca_postgres.os.bdline_ua_lep_diss;

-- Load WECA (West of England Combined Authority) dissolved boundary
CREATE OR REPLACE TABLE bdline_ua_weca_diss_tbl AS
SELECT * FROM weca_postgres.os.bdline_ua_weca_diss;

-- Load Unitary Authority boundaries within LEP
CREATE OR REPLACE TABLE bdline_ua_lep_tbl AS
SELECT * FROM weca_postgres.os.bdline_ua_lep;

-- Load Ward boundaries within LEP
CREATE OR REPLACE TABLE bdline_ward_lep_tbl AS
SELECT * FROM weca_postgres.os.bdline_ward_lep;
