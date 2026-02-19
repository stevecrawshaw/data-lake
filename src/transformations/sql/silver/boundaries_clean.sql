-- Silver Layer: Boundaries Cleaning and Standardization
-- Purpose: Create cleaned boundary lookup views including North Somerset in WECA
-- Dependencies: Bronze tables (ca_la_lookup_tbl, ca_boundaries_bgc_tbl, bdline_ua_lep_diss_tbl)
-- Views Created:
--   - ca_la_lookup_inc_ns_vw: Combined Authority to Local Authority lookup including North Somerset
--   - weca_lep_la_vw: West of England Combined Authority Local Authorities
--   - ca_boundaries_inc_ns_vw: Combined Authority boundaries including adjusted WECA boundary

-- Combined Authority to Local Authority lookup with North Somerset
-- North Somerset (E06000023) is manually added to West of England CA (E47000009)
-- as it's not in the official ONS lookup but is part of WECA
CREATE OR REPLACE VIEW ca_la_lookup_inc_ns_vw AS
SELECT
    LAD25CD AS ladcd,
    LAD25NM AS ladnm,
    CAUTH25CD AS cauthcd,
    CAUTH25NM AS cauthnm
FROM ca_la_lookup_tbl
UNION BY NAME
(SELECT
    'E06000024' AS ladcd,
    'North Somerset' AS ladnm,
    'E47000009' AS cauthcd,
    'West of England' AS cauthnm);

-- West of England Combined Authority Local Authorities only
-- Filters the complete CA/LA lookup to show only WECA constituent LAs
CREATE OR REPLACE VIEW weca_lep_la_vw AS
FROM ca_la_lookup_inc_ns_vw
WHERE cauthnm = 'West of England';

-- Combined Authority boundaries with corrected WECA boundary
-- The official CAUTH boundary for West of England doesn't include North Somerset
-- This view uses the dissolved UA boundary from bdline_ua_lep_diss_tbl instead
-- which includes all 4 WECA local authorities (Bristol, B&NES, South Glos, North Somerset)
CREATE OR REPLACE VIEW ca_boundaries_inc_ns_vw AS
SELECT
    CAUTH25CD AS cauthcd,
    CAUTH25NM AS cauthnm,
    geom
FROM ca_boundaries_bgc_tbl
WHERE CAUTH25CD != 'E47000009'  -- Exclude official WECA boundary
UNION BY NAME
SELECT
    'E47000009' AS cauthcd,
    'West of England' AS cauthnm,
    ST_GeomFromWKB(shape).ST_Transform('EPSG:27700', 'EPSG:4326', always_xy := true) AS geom
FROM bdline_ua_lep_diss_tbl;  -- Use dissolved UA boundary instead
