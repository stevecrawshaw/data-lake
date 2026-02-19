 Root Cause Analysis

  The missing_view_comments.sql file exists because these views failed the ViewMapper's success criteria when generated_comments.sql was created:

  1. ViewMapper Success Criteria: A view needs ≥80% of columns mapped from source tables
  2. Why They Failed: When generate was run, the source tables (from Bronze/Silver layers) didn't have enough comments to propagate
  3. Result: These views were manually documented separately

  Integration Strategy

  You have two options to integrate these into the main workflow:

  Option 1: Regenerate Everything (Recommended)

  Since you now have better table/column documentation (via manual_overrides.xml), regenerate to let ViewMapper automatically include these views:

  # Close any database connections first, then:

  # Regenerate with all current metadata
  uv run python -m src.tools.schema_documenter generate \
      -d data_lake/mca_env_base.duckdb \
      -x src/schemas/documentation/epc_domestic_schema.xml \
      -x src/schemas/documentation/epc_nondom_schema.xml \
      -x src/schemas/documentation/manual_overrides.xml \
      --include-views

  # Apply with force to update everything
  uv run python -m src.tools.schema_documenter apply \
      -d data_lake/mca_env_base.duckdb \
      -i src/schemas/documentation/generated_comments.sql \
      --force

  Expected outcome: If source tables now have good comments, ViewMapper should automatically include ca_la_lookup_inc_ns_vw and others in generated_comments.sql.

  Option 2: Merge Manual Comments into Single File

  Consolidate missing_view_comments.sql into generated_comments.sql:

  1. Append the content of missing_view_comments.sql to generated_comments.sql
  2. Delete missing_view_comments.sql
  3. Apply the merged file with --force

  Downside: Next regeneration will overwrite your merged changes unless ViewMapper can map them.

  Recommended Workflow Going Forward

  1. Always use --include-views when running generate:
  uv run python -m src.tools.schema_documenter generate \
      -d data_lake/mca_env_base.duckdb \
      -x src/schemas/documentation/manual_overrides.xml \
      --include-views
  2. Add view descriptions to XML if ViewMapper can't map them:
  <!-- In manual_overrides.xml -->
  <view name="ca_la_lookup_inc_ns_vw">
    <description>Combined Authority to Local Authority lookup including North Somerset</description>     
    <column name="ladcd">
      <type>VARCHAR</type>
      <description>Local Authority District code (ONS)</description>
    </column>
    <!-- ... more columns ... -->
  </view>
  3. Check ViewMapper logs to see which views can't be mapped:
  uv run python -m src.tools.schema_documenter generate \
      -d data_lake/mca_env_base.duckdb \
      -x src/schemas/documentation/manual_overrides.xml \
      --include-views -vv  # Debug logging

  Why ViewMapper Might Miss Views

  Views won't be included in generated_comments.sql if:
  - Source tables lack comments (< 80% columns documented)
  - Complex SQL that ViewMapper can't parse
  - Computed columns that don't map directly to source tables

  My Recommendation

  Try Option 1 first (regenerate with --include-views). If ViewMapper still can't map these specific views, then we know they need manual XML entries or the ViewMapper needs enhancement.

  Can you close any DuckDB connections and try the regenerate command? I want to see if ViewMapper can now automatically include these views since we've improved the source table documentation.