-- Silver Layer: EPC Domestic Cleaning
-- Purpose: Clean and standardize domestic EPC certificates with derived fields
-- Dependencies: Bronze table (raw_domestic_epc_certificates_tbl), macros (geopoint_from_blob)
-- Views Created:
--   - epc_domestic_vw: Cleaned domestic EPC with derived construction year, epoch, tenure
--   - epc_domestic_lep_vw: LEP-filtered EPC with geopoint for ODS export

-- Clean domestic EPC certificates with derived fields
-- Key transformations:
--   1. NOMINAL_CONSTRUCTION_YEAR: Extract numeric year from CONSTRUCTION_AGE_BAND text
--   2. CONSTRUCTION_EPOCH: Categorize construction year into broad periods
--   3. TENURE_CLEAN: Standardize tenure categories
--   4. LODGEMENT_YEAR/MONTH/DAY: Extract date components from timestamp
CREATE OR REPLACE VIEW epc_domestic_vw AS
SELECT
    c.*,

    -- Clean the construction age band to produce a nominal construction year
    -- Handles multiple text formats: "YYYY-YYYY", "before YYYY", "YYYY onwards", "YYYY"
    CASE
        -- Rule 2: If range (e.g., "1900-1929") return the rounded midpoint as integer
        WHEN regexp_matches(CONSTRUCTION_AGE_BAND, '(\d{4})-(\d{4})')
        THEN CAST(round((
                CAST(regexp_extract(CONSTRUCTION_AGE_BAND, '(\d{4})-(\d{4})', 1) AS INTEGER)
                +
                CAST(regexp_extract(CONSTRUCTION_AGE_BAND, '(\d{4})-(\d{4})', 2) AS INTEGER)
             ) / 2.0) AS INTEGER)

        -- Handle 'before YYYY' (e.g., "before 1900") - return YYYY - 1
        WHEN regexp_matches(CONSTRUCTION_AGE_BAND, 'before (\d{4})')
        THEN CAST(regexp_extract(CONSTRUCTION_AGE_BAND, 'before (\d{4})', 1) AS INTEGER) - 1

        -- Handle 'YYYY onwards' (e.g., "2012 onwards") - return YYYY
        WHEN regexp_matches(CONSTRUCTION_AGE_BAND, '(\d{4}) onwards')
        THEN CAST(regexp_extract(CONSTRUCTION_AGE_BAND, '(\d{4}) onwards', 1) AS INTEGER)

        -- Rule 1: If a single 4-digit year is present anywhere, return that year
        WHEN regexp_matches(CONSTRUCTION_AGE_BAND, '(\d{4})')
        THEN CAST(regexp_extract(CONSTRUCTION_AGE_BAND, '(\d{4})', 1) AS INTEGER)

        -- Rule 3: If no numerical year value can be extracted, return NULL
        ELSE NULL
    END AS NOMINAL_CONSTRUCTION_YEAR,

    -- Clean the construction age band to produce a construction epoch
    -- Categorizes properties into broad historical periods
    CASE
        WHEN NOMINAL_CONSTRUCTION_YEAR < 1900
        THEN 'Before 1900'
        WHEN (NOMINAL_CONSTRUCTION_YEAR >= 1900) AND (NOMINAL_CONSTRUCTION_YEAR <= 1930)
        THEN '1900 - 1930'
        WHEN NOMINAL_CONSTRUCTION_YEAR > 1930
        THEN '1930 to present'
        ELSE 'Unknown'
    END AS CONSTRUCTION_EPOCH,

    -- Clean the tenure column
    -- Standardizes tenure variants into 3 categories: Owner occupied, Social rented, Private rented
    CASE LOWER(TENURE)
        WHEN 'owner-occupied' THEN 'Owner occupied'
        WHEN 'rented (social)' THEN 'Social rented'
        WHEN 'rental (social)' THEN 'Social rented'
        WHEN 'rental (private)' THEN 'Private rented'
        WHEN 'rented (private)' THEN 'Private rented'
        ELSE NULL
    END AS TENURE_CLEAN,

    -- Extract date components from lodgement datetime
    year(LODGEMENT_DATETIME)  AS LODGEMENT_YEAR,
    month(LODGEMENT_DATETIME) AS LODGEMENT_MONTH,
    day(LODGEMENT_DATETIME)   AS LODGEMENT_DAY

FROM raw_domestic_epc_certificates_tbl c;

-- LEP-filtered domestic EPC with spatial geopoint for ODS export
-- Filters to West of England LEP local authorities
-- Adds geo_point_2d in ODS format via UPRN spatial join
-- Excludes address fields for privacy
CREATE OR REPLACE VIEW epc_domestic_lep_vw AS
SELECT
    e.* EXCLUDE ("ADDRESS", ADDRESS1, ADDRESS2, ADDRESS3, POSTCODE),
    geopoint_from_blob(o.shape) AS geo_point_2d
FROM epc_domestic_vw e
LEFT JOIN open_uprn_lep_tbl o ON e.UPRN = o.uprn
WHERE e.LOCAL_AUTHORITY IN ('E06000023', 'E06000024', 'E06000025', 'E06000022');
-- E06000023: North Somerset, E06000024: North East Somerset, E06000025: South Gloucestershire, E06000022: Bath and North East Somerset
