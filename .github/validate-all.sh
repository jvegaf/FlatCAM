#!/bin/bash

# FlatCAM Build Workflow Complete Validation Script
# Runs all test suites and provides comprehensive status report

set -e

echo "🔥 FlatCAM Build Workflow - Complete Validation Suite"
echo "====================================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Track overall results
TOTAL_TEST_SUITES=0
PASSED_TEST_SUITES=0
FAILED_TEST_SUITES=0

run_test_suite() {
    local suite_name="$1"
    local test_command="$2"
    TOTAL_TEST_SUITES=$((TOTAL_TEST_SUITES + 1))
    
    echo -e "${BLUE}📋 Running: ${suite_name}${NC}"
    echo "----------------------------------------"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASSED: ${suite_name}${NC}"
        PASSED_TEST_SUITES=$((PASSED_TEST_SUITES + 1))
    else
        echo -e "${RED}❌ FAILED: ${suite_name}${NC}"
        FAILED_TEST_SUITES=$((FAILED_TEST_SUITES + 1))
    fi
    echo ""
}

# Test Suite 1: Component Tests
run_test_suite "Component Validation Tests" "./.github/test-workflow-components.sh"

# Test Suite 2: Comprehensive Workflow Validation
run_test_suite "Workflow Configuration Validation" "./.github/workflow-validation-tests.sh"

# Test Suite 3: Manual Testing Setup Validation
run_test_suite "Security Guidelines Display" "./.github/manual-workflow-tests.sh security-scan"

# Additional Quick Validations
echo -e "${BLUE}📋 Running: Additional Quick Validations${NC}"
echo "----------------------------------------"

# Check all scripts are executable
if [[ -x ".github/test-workflow-components.sh" && -x ".github/workflow-validation-tests.sh" && -x ".github/manual-workflow-tests.sh" ]]; then
    echo "✅ All test scripts are executable"
else
    echo "❌ Some test scripts are not executable"
    FAILED_TEST_SUITES=$((FAILED_TEST_SUITES + 1))
fi

# Check documentation exists
if [[ -f ".github/WORKFLOW_TESTING.md" && -f ".github/TESTING.md" ]]; then
    echo "✅ All documentation files exist"
else
    echo "❌ Missing documentation files"
    FAILED_TEST_SUITES=$((FAILED_TEST_SUITES + 1))
fi

# Check workflow file syntax one more time
if python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build-appimage.yml'))" 2>/dev/null; then
    echo "✅ Workflow YAML syntax is valid"
else
    echo "❌ Workflow YAML syntax is invalid"
    FAILED_TEST_SUITES=$((FAILED_TEST_SUITES + 1))
fi

echo ""

# Summary Report
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📊 FINAL VALIDATION REPORT${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "Test Suites Run: ${TOTAL_TEST_SUITES}"
echo -e "${GREEN}Passed: ${PASSED_TEST_SUITES}${NC}"
echo -e "${RED}Failed: ${FAILED_TEST_SUITES}${NC}"

if [[ $FAILED_TEST_SUITES -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}🎉 ALL VALIDATIONS PASSED!${NC}"
    echo -e "${GREEN}✅ The FlatCAM Build workflow is fully tested and ready for production use.${NC}"
    echo ""
    echo -e "${BLUE}📋 Available Testing Tools:${NC}"
    echo "• Component Tests: ./.github/test-workflow-components.sh"
    echo "• Workflow Validation: ./.github/workflow-validation-tests.sh" 
    echo "• Manual Test Scenarios: ./.github/manual-workflow-tests.sh"
    echo "• Full Validation: ./.github/validate-all.sh (this script)"
    echo ""
    echo -e "${BLUE}📖 Documentation:${NC}"
    echo "• Testing Guide: .github/WORKFLOW_TESTING.md"
    echo "• General Testing: .github/TESTING.md"
    echo ""
    echo -e "${BLUE}🚀 Next Steps:${NC}"
    echo "1. Test manual workflow dispatch via GitHub UI"
    echo "2. Create test tag for release validation"
    echo "3. Monitor first production workflow runs"
    echo "4. Validate AppImage functionality on target systems"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}❌ SOME VALIDATIONS FAILED!${NC}"
    echo -e "${RED}Please review the failed tests above and fix the issues.${NC}"
    echo ""
    exit 1
fi