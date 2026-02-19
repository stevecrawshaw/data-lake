-- # scratchpad file to introspect duckdb database
duckdb data_lake/mca_env_base.duckdb

ATTACH '../duckdb-macros/macro_library.duckdb' AS macro;

FROM duckdb_functions() WHERE database_name = 'macro';

FROM macro.glimpse(weca_lep_la_vw);

SHOW TABLES;

SELECT comment from duckdb_tables();

SELECT comment from duckdb_columns() WHERE table_name = 'codepoint_open_lep_tbl';
-- centroids not commented properly?
SELECT comment from duckdb_columns() WHERE table_name = 'raw_domestic_epc_certificates_tbl';
SELECT comment from duckdb_columns() WHERE table_name = 'epc_domestic_lep_vw';


SELECT comment from duckdb_columns() WHERE table_name = 'ca_la_lookup_inc_ns_vw';

FROM ca_la_lookup_inc_ns_vw;

SELECT column_name FROM duckdb_columns()
WHERE table_name = 'postcode_centroids_tbl';