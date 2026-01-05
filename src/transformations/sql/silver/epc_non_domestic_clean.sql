-- Silver Layer: EPC Non-Domestic Cleaning
-- Purpose: Clean and standardize non-domestic EPC certificates with spatial joins
-- Dependencies: Bronze table (raw_non_domestic_epc_certificates_tbl), macros (geopoint_from_blob)
-- Views Created:
--   - epc_non_domestic_lep_vw: LEP-filtered non-domestic EPC with geopoint for ODS export

-- LEP-filtered non-domestic EPC with spatial geopoint for ODS export
-- Filters to West of England LEP local authorities
-- Adds geo_point_2d in ODS format via UPRN spatial join
CREATE OR REPLACE VIEW epc_non_domestic_lep_vw AS
SELECT
    nd.*,
    geopoint_from_blob(o.shape) AS geo_point_2d
FROM raw_non_domestic_epc_certificates_tbl nd
LEFT JOIN open_uprn_lep_tbl o ON nd.UPRN = o.uprn
WHERE nd.LOCAL_AUTHORITY IN ('E06000023', 'E06000024', 'E06000025', 'E06000022');
-- E06000023: North Somerset, E06000024: North East Somerset, E06000025: South Gloucestershire, E06000022: Bath and North East Somerset
