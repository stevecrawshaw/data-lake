<instruction>
Write a plan to implement this new feature. Save the plan in this repo and DO NOT PROCEED UNTIL I EXPLICITLY APPROVE THIS PLAN. Ask me questions if anything is unclear. Follow agent-docs/python-code-guidelines.md
</instruction>

<feature>
I want to add a new feature to this repo. It is a python script to update the
raw_domestic_epc_certificates_tbl  and  raw_non_domestic_epc_certificates_tbl tables in the
mca_env_base.duckdb database with new data retrieved from the epcopendatacommunities site via an API.
</feature>

<epc_api>
The openapi spec is in @epc.yml and the credentials are in the .env file in project root. The python
script should check the last lodgement date in each table and retrieve records after this date using
the appropriate endpoint.
</epc_api>

<helper_MCPs>
The  "epc-certificates" MCP server is available to you in this project to introspect the endpoints and test the API. The motherduck MCP can also access the local mca_env_base.duckdb database to confirm the schema. Save memories with serena MCP as you go.
</helper_MCPs>

<requirements>
Check that the column names match and include logic to transform column names if for example the case differs between the database and the api source. We want records from all local authorities.

Once the data are downloaded and validated they should be upserted into the relevant tables. The UPRN is the key, so if the UPRN exists in the database table the new record should overwrite it. This is because there can be multiple epc certificates for each property and we are only interested in the most recent one.
</requirements>

<tips>
If the data are downloaded as csv (recommended) duckDB can read multiple files with globbing and bulk upsert. Check the context7 MCP for details and syntax.
</tips>

<tools>
Use a modern api client like httpx, use duckdb's native functionality wherever possible - you can use the python relational AP for duckDB. Respect the CLAUDE.md instructions on uv.
</tools>
