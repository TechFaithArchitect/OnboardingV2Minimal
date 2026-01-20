#!/bin/bash

# Deployment Script for OnboardingV2
# This script deploys the Salesforce metadata to the target org
#
# Usage:
#   ./scripts/deploy/deploy.sh [org-alias]
#
# Example:
#   ./scripts/deploy/deploy.sh myorg

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get org alias from argument or use default
ORG_ALIAS=${1:-OnboardV2}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OnboardingV2 Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Salesforce CLI is installed
if ! command -v sf &> /dev/null; then
    echo -e "${RED}Error: Salesforce CLI (sf) is not installed${NC}"
    echo "Please install it from: https://developer.salesforce.com/tools/salesforcecli"
    exit 1
fi

# Check if org is authenticated
echo -e "${YELLOW}Checking org authentication...${NC}"
if ! sf org display --target-org "$ORG_ALIAS" &> /dev/null; then
    echo -e "${RED}Error: Org '$ORG_ALIAS' is not authenticated${NC}"
    echo "Please authenticate first: sf org login web --alias $ORG_ALIAS"
    exit 1
fi

echo -e "${GREEN}✓ Org authenticated: $ORG_ALIAS${NC}"
echo ""

# Deploy main/default metadata
echo -e "${YELLOW}Deploying main/default metadata...${NC}"
if sf project deploy start --source-dir force-app/main/default --target-org "$ORG_ALIAS"; then
    echo -e "${GREEN}✓ Main/default deployment successful${NC}"
else
    echo -e "${RED}✗ Main/default deployment failed${NC}"
    exit 1
fi
echo ""

# Deploy unpackaged metadata
echo -e "${YELLOW}Deploying unpackaged metadata...${NC}"
if sf project deploy start --source-dir force-app/unpackaged --target-org "$ORG_ALIAS"; then
    echo -e "${GREEN}✓ Unpackaged deployment successful${NC}"
else
    echo -e "${RED}✗ Unpackaged deployment failed${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Run tests: ./scripts/deploy/run-tests.sh $ORG_ALIAS"
echo "  2. Run post-deployment: ./scripts/deploy/post-deploy.sh $ORG_ALIAS"
echo ""

