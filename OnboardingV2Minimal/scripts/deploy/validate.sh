#!/bin/bash

# Pre-Deployment Validation Script for OnboardingV2
# This script validates metadata before deployment
#
# Usage:
#   ./scripts/deploy/validate.sh [org-alias]
#
# Example:
#   ./scripts/deploy/validate.sh myorg

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get org alias from argument or use default
ORG_ALIAS=${1:-myorg}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OnboardingV2 Pre-Deployment Validation${NC}"
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

# Validate main/default metadata
echo -e "${YELLOW}Validating main/default metadata...${NC}"
if sf project deploy start --source-dir force-app/main/default --target-org "$ORG_ALIAS" --dry-run; then
    echo -e "${GREEN}✓ Main/default validation passed${NC}"
else
    echo -e "${RED}✗ Main/default validation failed${NC}"
    exit 1
fi
echo ""

# Validate unpackaged metadata
echo -e "${YELLOW}Validating unpackaged metadata...${NC}"
if sf project deploy start --source-dir force-app/unpackaged --target-org "$ORG_ALIAS" --dry-run; then
    echo -e "${GREEN}✓ Unpackaged validation passed${NC}"
else
    echo -e "${RED}✗ Unpackaged validation failed${NC}"
    exit 1
fi
echo ""

# Check for common issues
echo -e "${YELLOW}Checking for common issues...${NC}"

# Check API version compatibility
API_VERSION=$(grep -oP '(?<=<apiVersion>)[^<]+' force-app/main/default/classes/*.cls-meta.xml 2>/dev/null | head -1 || echo "64.0")
echo "  API Version: $API_VERSION"

# Check for test classes
TEST_COUNT=$(find force-app/main/default/classes -name "*Test.cls" | wc -l | tr -d ' ')
echo "  Test Classes Found: $TEST_COUNT"

if [ "$TEST_COUNT" -lt 10 ]; then
    echo -e "${YELLOW}  ⚠ Warning: Low number of test classes${NC}"
fi

# Check for LWC components
LWC_COUNT=$(find force-app/main/default/lwc -type d -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
echo "  LWC Components: $LWC_COUNT"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Validation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "If validation passed, you can proceed with deployment:"
echo "  ./scripts/deploy/deploy.sh $ORG_ALIAS"
echo ""

