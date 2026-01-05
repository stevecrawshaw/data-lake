-- Bronze Layer: GHG Emissions Loading
-- Purpose: Load UK Local Authority greenhouse gas emissions data
-- Source: Manual download from UK Government statistics
-- Format: Both long (normalized) and wide (pivot table) formats
-- Dependencies: CSV and XLSX files must exist in landing/manual/
-- Tables Created:
--   - la_ghg_emissions_tbl (long format)
--   - la_ghg_emissions_wide_tbl (wide format)

-- Load GHG emissions in long (normalized) format
-- Source: 2005-2023 UK Local Authority GHG emissions dataset
CREATE OR REPLACE TABLE la_ghg_emissions_tbl AS
FROM read_csv(
    'data_lake/landing/manual/2005-23-uk-local-authority-ghg-emissions-CSV-dataset.csv',
    normalize_names = true
);

-- Load GHG emissions in wide (pivot) format
-- Source: 2005-2023 UK Local Authority GHG emissions Excel workbook
-- Sheet: 1_1 contains the main data table
-- Range: A5:AX7662 captures header and all data rows
CREATE OR REPLACE TABLE la_ghg_emissions_wide_tbl AS
FROM read_xlsx(
    'data_lake/landing/manual/2005-23-uk-local-authority-ghg-emissions.xlsx',
    sheet = '1_1',
    range = 'A5:AX7662',
    normalize_names = true
);
