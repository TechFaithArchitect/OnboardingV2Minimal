#!/bin/bash

# Test Execution Script for OnboardingV2
# This script runs all Apex tests in the project and validates coverage
#
# Usage:
#   ./scripts/deploy/run-tests.sh [org-alias] [test-classes]
#
# Examples:
#   ./scripts/deploy/run-tests.sh myorg
#   ./scripts/deploy/run-tests.sh myorg "OnboardingReqDueDateControllerTest,OnboardingReqPanelControllerTest"

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get org alias from argument or use default
ORG_ALIAS=${1:-OnboardV2}
TEST_CLASSES=${2:-""}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OnboardingV2 Test Execution${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Salesforce CLI is installed
if ! command -v sf &> /dev/null; then
    echo -e "${RED}Error: Salesforce CLI (sf) is not installed${NC}"
    exit 1
fi

# Check if org is authenticated
echo -e "${YELLOW}Checking org authentication...${NC}"
if ! sf org display --target-org "$ORG_ALIAS" &> /dev/null; then
    echo -e "${RED}Error: Org '$ORG_ALIAS' is not authenticated${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Org authenticated${NC}"
echo ""

# Run tests
echo -e "${YELLOW}Running Apex tests...${NC}"

# Discover all test classes in the project
# Note: We only include classes with test methods (multiple @isTest annotations).
discover_test_classes() {
    if [ ! -d "force-app" ]; then
        echo -e "${RED}Error: force-app directory not found${NC}"
        exit 1
    fi

    TEST_CLASS_NAMES=()
    while IFS= read -r -d '' file; do
        is_test_count=$(grep -i -c "@isTest" "$file" || true)
        if [ "$is_test_count" -gt 1 ]; then
            TEST_CLASS_NAMES+=("$(basename "$file" .cls)")
            continue
        fi
        if grep -qiE "\\btestMethod\\b" "$file"; then
            TEST_CLASS_NAMES+=("$(basename "$file" .cls)")
        fi
    done < <(find force-app -type f -name "*.cls" -print0)

    if [ "${#TEST_CLASS_NAMES[@]}" -eq 0 ]; then
        echo -e "${RED}Error: No test classes found under force-app${NC}"
        exit 1
    fi

    printf '%s\n' "${TEST_CLASS_NAMES[@]}" | sort -u | paste -sd, -
}

if [ -z "$TEST_CLASSES" ]; then
    echo "Discovering test classes in force-app..."
    ALL_TEST_CLASSES=$(discover_test_classes)
    # Run all tests in the project
    echo "Running all tests in the project..."
    TEST_RESULT=$(sf apex run test --class-names "$ALL_TEST_CLASSES" --target-org "$ORG_ALIAS" --result-format human --code-coverage --wait 10)
else
    # Run specific test classes provided as argument
    echo "Running test classes: $TEST_CLASSES"
    TEST_RESULT=$(sf apex run test --class-names "$TEST_CLASSES" --target-org "$ORG_ALIAS" --result-format human --code-coverage --wait 10)
fi

# Check test results
if echo "$TEST_RESULT" | grep -q "Test Execution: PASSED"; then
    echo -e "${GREEN}✓ All tests passed${NC}"
    
    # Extract coverage information
    COVERAGE=$(echo "$TEST_RESULT" | grep -oP 'Code Coverage: \K[0-9]+%' || echo "N/A")
    echo "  Code Coverage: $COVERAGE"
    
    # Check if coverage meets minimum (75%)
    COVERAGE_NUM=$(echo "$COVERAGE" | grep -oP '[0-9]+' || echo "0")
    if [ "$COVERAGE_NUM" -ge 75 ]; then
        echo -e "${GREEN}  ✓ Coverage meets minimum requirement (75%)${NC}"
    else
        echo -e "${YELLOW}  ⚠ Warning: Coverage below 75%${NC}"
    fi
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo "$TEST_RESULT"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Test Execution Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Save test results to file
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="test-results/test-run-$TIMESTAMP.txt"
mkdir -p test-results
echo "$TEST_RESULT" > "$RESULT_FILE"
echo "Test results saved to: $RESULT_FILE"
echo ""
