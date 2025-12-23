-- run from src/
duckdb '../data_lake/mca_env_base.duckdb';
SHOW TABLES;
-- CREATE VIEW FOR COMBINED AUTHORITIES WHICH INCLUDES NORTH SOMERSET
LOAD SPATIAL;
-- MACRO TO CONVERT BLOB GEOMETRY TO GEOPOINT FOR ODS
-- IT WORKS LIKE THIS:
-- SELECT geopoint_from_blob(shape) AS geo_point_2d
-- FROM open_uprn_lep_tbl LIMIT 2;

CREATE OR REPLACE MACRO  geopoint_from_blob(shape) AS
'{' || shape.ST_GeomFromWKB().ST_Transform('EPSG:27700', 'EPSG:4326').ST_X() || ', ' ||
       shape.ST_GeomFromWKB().ST_Transform('EPSG:27700', 'EPSG:4326').ST_Y() || '}';

CREATE OR REPLACE VIEW ca_la_lookup_inc_ns_vw AS
SELECT 
    LAD25CD AS ladcd,
    LAD25NM AS ladnm,
    CAUTH25CD AS cauthcd, 
    CAUTH25NM AS cauthnm
FROM ca_la_lookup_tbl
UNION BY NAME
(SELECT 
    'E06000023' AS ladcd,
    'North Somerset' AS ladnm,
    'E47000009' AS cauthcd,
    'West of England' AS cauthnm);

CREATE OR REPLACE VIEW weca_lep_la_vw AS
FROM ca_la_lookup_inc_ns_vw
WHERE cauthnm = 'West of England';

-- CREATE BOUNDARIES VIEW WHICH INCLUDES NORTH SOMERSET

CREATE OR REPLACE VIEW ca_boundaries_inc_ns_vw AS
SELECT 
    CAUTH25CD AS cauthcd,
    CAUTH25NM AS cauthnm,
    geom FROM ca_boundaries_bgc_tbl
    WHERE CAUTH25CD != 'E47000009'
UNION BY NAME
SELECT
    'E47000009' AS cauthcd,
    'West of England' AS cauthnm,
    ST_GeomFromWKB(shape).ST_Transform('EPSG:27700', 'EPSG:4326', always_xy := true) AS geom
FROM bdline_ua_lep_diss_tbl;

-- PER CAP EMISSIONS VIEW

CREATE OR REPLACE VIEW per_cap_emissions_ca_national_vw AS
(SELECT
  "t6"."calendar_year",
  "t6"."cauthnm" AS "area",
  "t6"."gt_sum_ca" / "t6"."pop_sum_ca" AS "per_cap"
FROM (
  SELECT
    "t5"."cauthnm",
    "t5"."calendar_year",
    SUM("t5"."grand_total") AS "gt_sum_ca",
    SUM("t5"."population_000s_midyear_estimate") AS "pop_sum_ca"
  FROM (
    SELECT
    "t2"."regioncountry",
    "t2"."second_tier_authority",
    "t2"."local_authority",
    "t2"."local_authority_code",
    "t2"."calendar_year",
    "t2"."industry_electricity",
    "t2"."industry_gas",
    "t2"."large_industrial_installations",
    "t2"."industry_other",
    "t2"."industry_total",
    "t2"."commercial_electricity",
    "t2"."commercial_gas",
    "t2"."commercial_other",
    "t2"."commercial_total",
    "t2"."public_sector_electricity",
    "t2"."public_sector_gas",
    "t2"."public_sector_other",
    "t2"."public_sector_total",
    "t2"."domestic_electricity",
    "t2"."domestic_gas",
    "t2"."domestic_other",
    "t2"."domestic_total",
    "t2"."road_transport_a_roads",
    "t2"."road_transport_motorways",
    "t2"."road_transport_minor_roads",
    "t2"."diesel_railways",
    "t2"."transport_other",
    "t2"."transport_total",
    "t2"."net_emissions_forestry",
    "t2"."net_emissions_cropland_mineral_soils_change",
    "t2"."net_emissions_grassland_mineral_soils_change",
    "t2"."net_emissions_settlements",
    "t2"."net_emissions_peatland",
    "t2"."net_emissions_bioenergy_crops",
    "t2"."net_emissions_other_lulucf",
    "t2"."lulucf_net_emissions",
    "t2"."agriculture_electricity",
    "t2"."agriculture_gas",
    "t2"."agriculture_other",
    "t2"."agriculture_livestock",
    "t2"."agriculture_soils",
    "t2"."agriculture_total",
    "t2"."landfill",
    "t2"."waste_other",
    "t2"."waste_total",
    "t2"."grand_total",
    "t2"."population_000s_midyear_estimate",
    "t2"."per_capita_emissions_t_co2e",
    "t2"."area_km2",
    "t2"."emissions_per_km2_kt_co2e",
      "t4"."ladcd",
      "t4"."ladnm",
      "t4"."cauthcd",
      "t4"."cauthnm"
    FROM "la_ghg_emissions_wide_tbl" AS "t2"
    INNER JOIN (
      SELECT
        *
      FROM "ca_la_lookup_inc_ns_vw" AS "t1"
    ) AS "t4"
      ON "t2"."local_authority_code" = "t4"."ladcd"
  ) AS "t5"
  GROUP BY
    1,
    2
) AS "t6");

-- EMISSIONS SUB SECTOR ODS VIEW

CREATE OR REPLACE VIEW ca_la_ghg_emissions_sub_sector_ods_vw AS
    WITH joined_data AS (
        SELECT *
        FROM la_ghg_emissions_tbl ghg
        INNER JOIN ca_la_lookup_inc_ns_vw ca ON ghg.local_authority_code = ca.ladcd
    )
    SELECT * EXCLUDE (country, country_code, region, ladcd, ladnm, second_tier_authority)
    FROM joined_data;



-- CREATE SILVER VIEW OF EPC DOMESTIC DATA
-- NEED TO DECIDE ABOUT NEW FORMAT FOR EPC? SHOULD WE ADD PROPERTY GEOM FROM OPEN UPRN?

-- FROM raw_domestic_epc_certificates_tbl SELECT count();
-- .mode column
-- SELECT column_name, data_type FROM duckdb_columns() WHERE table_name = 'raw_domestic_epc_certificates_tbl';
-- .mode duckbox

CREATE OR REPLACE VIEW epc_domestic_vw AS 
SELECT
    c.*,
    -- Clean the construction age band to produce a nominal construction year
    CASE
        -- Rule 2 (Revised): If range return the rounded mid point as integer
        WHEN regexp_matches(CONSTRUCTION_AGE_BAND, '(\d{4})-(\d{4})')
        THEN CAST(round((
                CAST(regexp_extract(CONSTRUCTION_AGE_BAND, '(\d{4})-(\d{4})', 1) AS INTEGER)
                +
                CAST(regexp_extract(CONSTRUCTION_AGE_BAND, '(\d{4})-(\d{4})', 2) AS INTEGER)
             ) / 2.0) AS INTEGER)

        -- New Rule: Handle 'before YYYY'
        WHEN regexp_matches(CONSTRUCTION_AGE_BAND, 'before (\d{4})')
        THEN CAST(regexp_extract(CONSTRUCTION_AGE_BAND, 'before (\d{4})', 1) AS INTEGER) - 1

        -- New Rule: Handle 'YYYY onwards'
        WHEN regexp_matches(CONSTRUCTION_AGE_BAND, '(\d{4}) onwards')
        THEN CAST(regexp_extract(CONSTRUCTION_AGE_BAND, '(\d{4}) onwards', 1) AS INTEGER)

        -- Rule 1 (Revised): If a single 4-digit year is present anywhere, return that year
        WHEN regexp_matches(CONSTRUCTION_AGE_BAND, '(\d{4})')
        THEN CAST(regexp_extract(CONSTRUCTION_AGE_BAND, '(\d{4})', 1) AS INTEGER)

        -- Rule 3: If no numerical year value can be extracted, return NULL
        ELSE NULL
    END AS NOMINAL_CONSTRUCTION_YEAR,
    -- Clean the construction age band to produce a construction epoch
    CASE WHEN NOMINAL_CONSTRUCTION_YEAR < 1900
    THEN 'Before 1900'
         WHEN (NOMINAL_CONSTRUCTION_YEAR >= 1900)
         AND (NOMINAL_CONSTRUCTION_YEAR <= 1930)
         THEN '1900 - 1930'
         WHEN NOMINAL_CONSTRUCTION_YEAR > 1930
         THEN '1930 to present'
         ELSE 'Unknown' END AS CONSTRUCTION_EPOCH,
    -- Clean the tenure column
   CASE LOWER(TENURE)
        WHEN 'owner-occupied' THEN 'Owner occupied'
        WHEN 'rented (social)' THEN 'Social rented'
        WHEN 'rental (social)' THEN 'Social rented'
        WHEN 'rental (private)' THEN 'Private rented'
        WHEN 'rented (private)' THEN 'Private rented'
        ELSE NULL
    END AS TENURE_CLEAN,
    -- Extract the day, month, and year from the lodgement datetime
       -- Simplified Date Extraction
    year(LODGEMENT_DATETIME)  AS LODGEMENT_YEAR,
    month(LODGEMENT_DATETIME) AS LODGEMENT_MONTH,
    day(LODGEMENT_DATETIME)   AS LODGEMENT_DAY
FROM raw_domestic_epc_certificates_tbl c;
-- UPRN DE - DUPLICATED AT INGESTION


CREATE OR REPLACE VIEW epc_domestic_lep_vw AS
SELECT 
    e.* EXCLUDE (ADDRESS1, ADDRESS2, ADDRESS3, POSTCODE),
    geopoint_from_blob(o.shape) AS geo_point_2d
FROM epc_domestic_vw e
LEFT JOIN open_uprn_lep_tbl o ON e.UPRN = o.uprn
WHERE e.LOCAL_AUTHORITY IN ('E06000023', 'E06000024', 'E06000025', 'E06000022');

-- NOW DO NON - DOMESTIC EPCS

CREATE OR REPLACE VIEW epc_non_domestic_lep_vw AS
SELECT nd.*, geopoint_from_blob(o.shape) AS geo_point_2d
FROM 
raw_non_domestic_epc_certificates_tbl nd
    LEFT JOIN open_uprn_lep_tbl o ON nd.UPRN = o.uprn
WHERE nd.LOCAL_AUTHORITY IN ('E06000023', 'E06000024', 'E06000025', 'E06000022');



.mode column
SELECT column_name, data_type FROM duckdb_columns() WHERE table_name = 'epc_domestic_vw';
.mode duckbox

.mode column
SELECT column_name, data_type FROM duckdb_columns() WHERE table_name = 'open_uprn_lep_tbl';
.mode duckbox

