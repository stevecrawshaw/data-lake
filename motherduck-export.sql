duckdb 'data_lake/mca_env_base.duckdb';

SHOW TABLES;
DESCRIBE mca_env_base.postcode_centroids_tbl;

ATTACH 'md:';

SHOW DATABASES;


SELECT DISTINCT database_name FROM duckdb_columns();

DROP DATABASE mca_data CASCADE;
-- md authentication is in the .env variable

CREATE OR REPLACE DATABASE mca_data FROM mca_env_base;

SELECT table_name, column_name, comment FROM duckdb_columns() WHERE table_name = 'epc_domestic_lep_vw';

SELECT name FROM (SHOW ALL TABLES) WHERE name LIKE '%emission%';

SHOW DATABASES;