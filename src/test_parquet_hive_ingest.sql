./duckdb



COPY
(WITH schema_raw_cte AS
(FROM read_json('schemas/domestic_cert_recommendations_schema.json')
SELECT unnest(tables[1]['tableSchema']['columns']) r)
SELECT MAP(list(r.name),
list(CASE 
    WHEN r.datatype::VARCHAR = '"integer"' THEN 'BIGINT'
    WHEN r.datatype::VARCHAR = '"date"' THEN 'DATE'
    WHEN r.datatype::VARCHAR = '"decimal"' THEN 'DOUBLE'
    WHEN r.datatype::VARCHAR = '"float"' THEN 'DOUBLE'
    WHEN r.datatype::VARCHAR LIKE '%datetime%' THEN 'TIMESTAMP'
    ELSE 'VARCHAR'
    
END )) AS schema_map 
FROM schema_raw_cte) TO 'schemas/epc_domestic_certificates_schema.json' (FORMAT JSON);



CREATE OR REPLACE TABLE epc_domestic_sample AS
SELECT * 
FROM read_parquet('../data_lake/staging_parquet/epc_domestic/*/*.parquet',
                                hive_partitioning = true)
                                LIMIT 930;

FROM epc_domestic_sample;