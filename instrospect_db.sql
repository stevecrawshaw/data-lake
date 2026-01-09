duckdb data_lake/mca_env_base.duckdb

SHOW TABLES;

SELECT comment from duckdb_tables();

SELECT comment from duckdb_columns() WHERE table_name = 'codepoint_open_lep_tbl';
-- centroids not commented properly?
SELECT comment from duckdb_columns() WHERE table_name = 'postcode_centroids_tbl';

SELECT column_name FROM duckdb_columns()
WHERE table_name = 'postcode_centroids_tbl';