#!/bin/bash

# Deployment Script for Phase 1 Changes Only
# This script deploys only the Phase 1 components to avoid dependency validation issues
#
# Usage:
#   ./scripts/deploy/deploy-phase1.sh [org-alias]
#
# Example:
#   ./scripts/deploy/deploy-phase1.sh myorg

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get org alias from argument or use default
ORG_ALIAS=${1:-myorg}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Phase 1 Deployment Script${NC}"
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

echo -e "${GREEN}✓ Org authenticated: $ORG_ALIAS${NC}"
echo ""

# Phase 1 Components to Deploy
echo -e "${YELLOW}Deploying Phase 1 components...${NC}"
echo ""

# Deploy Phase 1 components using source paths
echo -e "${YELLOW}  → Deploying Phase 1 components...${NC}"
sf project deploy start \
    --source-path force-app/main/default/classes/dto/StatusEvaluationTraceDTO.cls \
    --source-path force-app/main/default/classes/controllers/OnboardingStatusRulesEngineController.cls \
    --source-path force-app/main/default/classes/controllers/OnboardingRequirementsPanelController.cls \
    --source-path force-app/main/default/classes/controllers/OnboardingHomeDashboardController.cls \
    --source-path force-app/main/default/classes/test/OnboardingStatusRulesEngineControllerTest.cls \
    --source-path force-app/main/default/classes/test/OnboardingRequirementsPanelControllerTest.cls \
    --source-path force-app/main/default/classes/test/OnboardingHomeDashboardControllerTest.cls \
    --source-path force-app/main/default/lwc/statusEvaluationPreviewModal \
    --source-path force-app/main/default/lwc/onboardingAtRiskPanel \
    --source-path force-app/main/default/lwc/onboardingStatusRulesEngine \
    --source-path force-app/main/default/lwc/onboardingRequirementsPanel \
    --source-path force-app/main/default/lwc/onboardingHomeDashboard \
    --target-org "$ORG_ALIAS"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Phase 1 Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Run tests: ./scripts/deploy/run-tests.sh $ORG_ALIAS"
echo "  2. Verify functionality in the org"
echo ""
