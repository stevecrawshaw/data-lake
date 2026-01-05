-- Bronze Layer: Boundaries from External ArcGIS REST APIs
-- Purpose: Load Combined Authority boundaries and lookups from ArcGIS REST services
-- Source: ArcGIS REST API (services1.arcgis.com)
-- Dependencies: None (no VPN required)
-- Tables Created:
--   - ca_boundaries_bgc_tbl
--   - ca_la_lookup_tbl

-- Load Combined Authority boundaries (May 2025) using BGC (Boundaries - Generalised Clipped)
CREATE OR REPLACE TABLE ca_boundaries_bgc_tbl AS
SELECT * FROM ST_Read(
    'https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/CAUTH_MAY_2025_EN_BGC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson'
);

-- Load Combined Authority to Local Authority lookup table (2025)
CREATE OR REPLACE TABLE ca_la_lookup_tbl AS
SELECT unnest(features, recursive := true)
FROM read_json(
    'https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LAD25_CAUTH25_EN_LU/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=false&outSR=4326&f=json'
);
