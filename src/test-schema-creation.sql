./duckdb

CREATE OR REPLACE TABLE schema_raw AS
SELECT "column", "datatype" 
FROM read_csv('schemas/domestic-columns-raw-columns.csv')
WHERE filename = 'certificates.csv';

.mode line
FROM schema_raw;
.mode duckbox

COPY
(
SELECT MAP(list("column"), list(CASE 
    WHEN "datatype" = 'integer' THEN 'BIGINT'
    WHEN "datatype" = 'date' THEN 'DATE'
    WHEN "datatype" = 'decimal' THEN 'DOUBLE'
    WHEN "datatype" = 'float' THEN 'DOUBLE'
    WHEN "datatype" = 'datetime' THEN 'TIMESTAMP'
    ELSE 'VARCHAR'
END )) AS schema_map
FROM schema_raw) TO 'schemas/domestic_certificates_schema.json' (FORMAT JSON);