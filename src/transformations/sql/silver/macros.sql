-- Silver Layer: Spatial Transformation Macros
-- Purpose: Shared spatial utility functions for coordinate transformations
-- Dependencies: Requires SPATIAL extension loaded
-- Macros Created:
--   - geopoint_from_blob: Converts BLOB geometry to ODS geopoint format

-- Load spatial extension
LOAD SPATIAL;

-- Macro to convert BLOB geometry to geopoint for ODS (Open Data Soft) format
-- Transforms from EPSG:27700 (British National Grid) to EPSG:4326 (WGS84 lat/lon)
-- Output format: '{longitude, latitude}' suitable for ODS geo_point_2d field
--
-- Usage example:
--   SELECT geopoint_from_blob(shape) AS geo_point_2d
--   FROM open_uprn_lep_tbl LIMIT 2;
--
CREATE OR REPLACE MACRO geopoint_from_blob(shape) AS
'{' || shape.ST_GeomFromWKB().ST_Transform('EPSG:27700', 'EPSG:4326').ST_X() || ', ' ||
       shape.ST_GeomFromWKB().ST_Transform('EPSG:27700', 'EPSG:4326').ST_Y() || '}';
