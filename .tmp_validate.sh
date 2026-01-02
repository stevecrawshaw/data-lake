#!/bin/bash
set +e  # Don't exit on errors, collect all results

echo "==============================================================================="
echo "                   DATA LAKE COMPREHENSIVE VALIDATION"
echo "==============================================================================="
echo ""

# Phase 1: Linting
echo "=== Phase 1: Code Linting ==="
uv run ruff check src/ > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ PASSED: No linting issues"
else
    echo "⚠ WARNINGS: Some linting issues found (see details with: uv run ruff check src/)"
fi
echo ""

# Phase 2: Formatting
echo "=== Phase 2: Code Formatting ==="
uv run ruff format --check src/ > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ PASSED: All files properly formatted"
else
    echo "⚠ WARNINGS: Some files need formatting"
fi
echo ""

# Phase 3: Unit Tests
echo "=== Phase 3: Unit Tests ==="
uv run pytest -v --tb=short -q > .tmp_test_output.txt 2>&1
if [ $? -eq 0 ]; then
    test_count=$(grep -c "PASSED" .tmp_test_output.txt || echo "0")
    echo "✓ PASSED: $test_count tests passing"
else
    echo "✗ FAILED: Some tests failing"
fi
echo ""

# Phase 4: Python Import Validation
echo "=== Phase 4: Python Import Validation ==="
import_errors=0

modules=(
    "src.utility.utils:csv_to_parquet,convert_to_hive_partitioned,download_zip"
    "src.utility.get_schema:get_schema_as_xml,save_schema_to_file"
    "src.tools.schema_documenter:cli"
    "src.tools.parsers.models"
    "src.tools.parsers.xml_parser"
    "src.tools.parsers.schema_analyzer"
    "src.tools.generators.comment_generator"
    "src.tools.generators.view_mapper"
    "src.tools.generators.xml_generator"
    "src.tools.utils.interactive_menu"
    "src.tools.utils.session_manager"
    "src.extractors.epc_models"
    "src.extractors.epc_api_client"
    "src.extractors.epc_incremental_update"
)

for module in "${modules[@]}"; do
    module_path=$(echo "$module" | cut -d: -f1)
    if echo "$module" | grep -q ":"; then
        imports=$(echo "$module" | cut -d: -f2)
        uv run python -c "from $module_path import $imports" 2>/dev/null
    else
        uv run python -c "import $module_path" 2>/dev/null
    fi
    
    if [ $? -eq 0 ]; then
        echo "  ✓ $module_path"
    else
        echo "  ✗ $module_path (import error)"
        import_errors=$((import_errors + 1))
    fi
done

if [ $import_errors -eq 0 ]; then
    echo "✓ PASSED: All modules import successfully"
else
    echo "✗ FAILED: $import_errors modules failed to import"
fi
echo ""

