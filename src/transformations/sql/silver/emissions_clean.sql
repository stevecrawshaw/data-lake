-- Silver Layer: Emissions Cleaning and Enrichment
-- Purpose: Join GHG emissions data with Combined Authority/Local Authority lookups
-- Dependencies: Bronze table (la_ghg_emissions_tbl), Silver view (ca_la_lookup_inc_ns_vw)
-- Views Created:
--   - ca_la_ghg_emissions_sub_sector_ods_vw: Emissions by sub-sector enriched with CA/LA codes for ODS export

-- Emissions by sub-sector enriched with Combined Authority and Local Authority information
-- Joins GHG emissions data with CA/LA lookup to add geography hierarchy
-- Excludes redundant columns (country, region, second_tier_authority) that are superseded by CA/LA codes
-- Output format suitable for Open Data Soft (ODS) platform publishing
CREATE OR REPLACE VIEW ca_la_ghg_emissions_sub_sector_ods_vw AS
WITH joined_data AS (
    SELECT *
    FROM la_ghg_emissions_tbl ghg
    INNER JOIN ca_la_lookup_inc_ns_vw ca ON ghg.local_authority_code = ca.ladcd
)
SELECT * EXCLUDE (country, country_code, region, ladcd, ladnm, second_tier_authority)
FROM joined_data;
