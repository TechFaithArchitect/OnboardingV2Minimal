#!/bin/bash

# Post-Deployment Configuration Script for OnboardingV2
# This script performs post-deployment configuration tasks
#
# Usage:
#   ./scripts/deploy/post-deploy.sh [org-alias]
#
# Example:
#   ./scripts/deploy/post-deploy.sh myorg

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get org alias from argument or use default
ORG_ALIAS=${1:-myorg}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OnboardingV2 Post-Deployment Setup${NC}"
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

# Step 1: Assign Permission Sets
echo -e "${YELLOW}Step 1: Assigning Permission Sets...${NC}"
echo "  Note: Permission sets must be assigned manually via UI"
echo "  Required permission sets:"
echo "    - Onboarding_Account_Services"
echo "    - Onboarding_Compliance_Team"
echo "    - Onboarding_Program_Sales_Team"
echo "    - Onboarding_Program_Specialists"
echo "    - Onboarding_Customer_Service"
echo "    - Onboarding_Finance_Team"
echo ""

# Step 2: Verify Custom Metadata
echo -e "${YELLOW}Step 2: Verifying Custom Metadata...${NC}"
echo "  Checking Global Value Sets..."
GVS_COUNT=$(sf data query --query "SELECT COUNT() FROM GlobalValueSet" --target-org "$ORG_ALIAS" --use-tooling-api --json 2>/dev/null | grep -oP '"size":\s*\K[0-9]+' || echo "0")
echo "    Global Value Sets: $GVS_COUNT"
echo ""

# Step 3: Verify Custom Objects
echo -e "${YELLOW}Step 3: Verifying Custom Objects...${NC}"
echo "  Checking key custom objects..."

OBJECTS=("Onboarding__c" "Vendor_Program__c" "Onboarding_Application_Process__c" "Onboarding_Status_Rules_Engine__c")
for OBJ in "${OBJECTS[@]}"; do
    if sf data query --query "SELECT COUNT() FROM $OBJ" --target-org "$ORG_ALIAS" --json 2>/dev/null | grep -q "records"; then
        echo -e "    ${GREEN}✓${NC} $OBJ exists"
    else
        echo -e "    ${YELLOW}⚠${NC} $OBJ not found or not accessible"
    fi
done
echo ""

# Step 4: Verify Flows
echo -e "${YELLOW}Step 4: Verifying Flows...${NC}"
FLOW_COUNT=$(sf data query --query "SELECT COUNT() FROM Flow WHERE Status = 'Active'" --target-org "$ORG_ALIAS" --use-tooling-api --json 2>/dev/null | grep -oP '"size":\s*\K[0-9]+' || echo "0")
echo "  Active Flows: $FLOW_COUNT"

# Check for key flows
KEY_FLOWS=("APP_Onboarding" "Onboarding_Record_Trigger_Update_Onboarding_Status")
for FLOW in "${KEY_FLOWS[@]}"; do
    if sf data query --query "SELECT Id FROM Flow WHERE DeveloperName = '$FLOW' AND Status = 'Active'" --target-org "$ORG_ALIAS" --use-tooling-api --json 2>/dev/null | grep -q "records"; then
        echo -e "    ${GREEN}✓${NC} $FLOW is active"
    else
        echo -e "    ${YELLOW}⚠${NC} $FLOW not found or not active"
    fi
done
echo ""

# Step 5: Verify LWC Components
echo -e "${YELLOW}Step 5: Verifying LWC Components...${NC}"
LWC_COUNT=$(find force-app/main/default/lwc -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
echo "  LWC Components Deployed: $LWC_COUNT"

KEY_COMPONENTS=("vendorProgramOnboardingFlow" "onboardingFlowEngine" "onboardingRequirementsPanel")
for COMP in "${KEY_COMPONENTS[@]}"; do
    if [ -d "force-app/main/default/lwc/$COMP" ]; then
        echo -e "    ${GREEN}✓${NC} $COMP exists"
    else
        echo -e "    ${RED}✗${NC} $COMP not found"
    fi
done
echo ""

# Step 6: Configuration Reminders
echo -e "${YELLOW}Step 6: Configuration Reminders...${NC}"
echo "  The following must be configured manually:"
echo "    1. Create Onboarding_Component_Library__c records for each LWC component"
echo "    2. Create Onboarding_Application_Process__c record"
echo "    3. Create Onboarding_Application_Stage__c records"
echo "    4. Link stages to process and components"
echo "    5. Create Vendor_Program_Group__c records"
echo "    6. Create Onboarding_Status_Rules_Engine__c records"
echo "    7. Create Onboarding_Status_Rule__c records"
echo "    8. Add components to Lightning record pages"
echo ""
echo "  See docs/setup/configuration.md for detailed instructions"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Post-Deployment Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Assign permission sets to users"
echo "  2. Configure onboarding processes (see docs/setup/configuration.md)"
echo "  3. Set up status rules"
echo "  4. Add components to Lightning pages"
echo "  5. Run sample data scripts if needed (see docs/setup/sample-data.md)"
echo ""

