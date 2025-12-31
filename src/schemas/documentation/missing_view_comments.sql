-- Additional schema documentation comments for view columns
-- Created to supplement generated_comments.sql with missing view columns

BEGIN TRANSACTION;

-- View: ca_boundaries_inc_ns_vw
-- Combined Authority boundaries including North Somerset
COMMENT ON COLUMN mca_env_base.ca_boundaries_inc_ns_vw.cauthcd IS 'Combined Authority code (ONS)';
COMMENT ON COLUMN mca_env_base.ca_boundaries_inc_ns_vw.cauthnm IS 'Combined Authority name';
COMMENT ON COLUMN mca_env_base.ca_boundaries_inc_ns_vw.geom IS 'Spatial geometry in EPSG:4326 (WGS84)';

-- View: ca_la_lookup_inc_ns_vw
-- Combined Authority to Local Authority lookup including North Somerset
COMMENT ON COLUMN mca_env_base.ca_la_lookup_inc_ns_vw.ladcd IS 'Local Authority District code (ONS)';
COMMENT ON COLUMN mca_env_base.ca_la_lookup_inc_ns_vw.ladnm IS 'Local Authority District name';
COMMENT ON COLUMN mca_env_base.ca_la_lookup_inc_ns_vw.cauthcd IS 'Combined Authority code (ONS)';
COMMENT ON COLUMN mca_env_base.ca_la_lookup_inc_ns_vw.cauthnm IS 'Combined Authority name';

-- View: per_cap_emissions_ca_national_vw
-- Per capita greenhouse gas emissions by Combined Authority
COMMENT ON COLUMN mca_env_base.per_cap_emissions_ca_national_vw.area IS 'Combined Authority area name';
COMMENT ON COLUMN mca_env_base.per_cap_emissions_ca_national_vw.calendar_year IS 'Calendar year of emissions data';
COMMENT ON COLUMN mca_env_base.per_cap_emissions_ca_national_vw.per_cap IS 'Per capita emissions (tonnes CO2e per person)';

-- View: weca_lep_la_vw
-- West of England LEP Local Authorities lookup
COMMENT ON COLUMN mca_env_base.weca_lep_la_vw.ladcd IS 'Local Authority District code (ONS)';
COMMENT ON COLUMN mca_env_base.weca_lep_la_vw.ladnm IS 'Local Authority District name';
COMMENT ON COLUMN mca_env_base.weca_lep_la_vw.cauthcd IS 'Combined Authority code (ONS)';
COMMENT ON COLUMN mca_env_base.weca_lep_la_vw.cauthnm IS 'Combined Authority name';

COMMIT;
