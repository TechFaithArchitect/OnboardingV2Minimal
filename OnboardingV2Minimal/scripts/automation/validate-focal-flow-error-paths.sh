#!/usr/bin/env bash
set -euo pipefail

FLOWS_DIR="${1:-force-app/main/default/flows}"

if [[ ! -d "$FLOWS_DIR" ]]; then
  echo "Flows directory not found: $FLOWS_DIR" >&2
  exit 2
fi

failures=0
passes=0

assert_xpath_exists() {
  local file_path="$1"
  local xpath_expr="$2"
  local description="$3"
  local count_value

  count_value="$(xmllint --xpath "string(count(${xpath_expr}))" "$file_path" 2>/dev/null || echo "0")"
  count_value="${count_value%.*}"
  if [[ -z "$count_value" ]]; then
    count_value="0"
  fi

  if [[ "$count_value" -ge 1 ]]; then
    echo "PASS	$description"
    passes=$((passes + 1))
  else
    echo "FAIL	$description"
    failures=$((failures + 1))
  fi
}

bll_req_flow="$FLOWS_DIR/BLL_Onboarding_Requirement_RCD_Logical_Process.flow-meta.xml"
related_req_flow="$FLOWS_DIR/DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records.flow-meta.xml"
exp_opp_flow="$FLOWS_DIR/EXP_Opportunity_SCR_Create_Record.flow-meta.xml"
bll_bre_flow="$FLOWS_DIR/BLL_BRE_Evaluate_Business_Rules.flow-meta.xml"

for required_file in "$bll_req_flow" "$related_req_flow" "$exp_opp_flow" "$bll_bre_flow"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Missing required flow file: $required_file" >&2
    exit 2
  fi
done

# BLL_Onboarding_Requirement_RCD_Logical_Process focal assertions
assert_xpath_exists "$bll_req_flow" \
  "/*[local-name()='Flow']/*[local-name()='actionCalls'][*[local-name()='name' and text()='Evaluate_Onboarding_Status'] and *[local-name()='faultConnector']/*[local-name()='targetReference' and text()='Capture_Evaluate_Onboarding_Status_Fault']]" \
  "BLL_Onboarding_Requirement_RCD_Logical_Process: Evaluate_Onboarding_Status has fault connector"

assert_xpath_exists "$bll_req_flow" \
  "/*[local-name()='Flow']/*[local-name()='actionCalls'][*[local-name()='name' and text()='Evaluate_Onboarding_Status'] and *[local-name()='outputParameters'][*[local-name()='name' and text()='errorMessage'] and *[local-name()='assignToReference' and text()='errorMessage']]]" \
  "BLL_Onboarding_Requirement_RCD_Logical_Process: Evaluate_Onboarding_Status maps output errorMessage"

assert_xpath_exists "$bll_req_flow" \
  "/*[local-name()='Flow']/*[local-name()='decisions'][*[local-name()='name' and text()='Did_Evaluate_Onboarding_Status_Fail'] and *[local-name()='rules'][*[local-name()='name' and text()='Evaluate_Onboarding_Status_Failed'] and *[local-name()='connector']/*[local-name()='targetReference' and text()='Handle_Evaluate_Onboarding_Status_Fault']]]" \
  "BLL_Onboarding_Requirement_RCD_Logical_Process: Did_Evaluate_Onboarding_Status_Fail routes to handler"

assert_xpath_exists "$bll_req_flow" \
  "/*[local-name()='Flow']/*[local-name()='subflows'][*[local-name()='name' and text()='Handle_Evaluate_Onboarding_Status_Fault'] and *[local-name()='flowName' and text()='DOMAIN_OmniSObject_SFL_CREATE_Fault_Message']]" \
  "BLL_Onboarding_Requirement_RCD_Logical_Process: Evaluate_Onboarding_Status fault handler uses shared fault-message flow"

# DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records assertions
assert_xpath_exists "$related_req_flow" \
  "/*[local-name()='Flow']/*[local-name()='assignments'][*[local-name()='name' and text()='Assign_Onboarding_Record_Path_Not_Supported_Error'] and *[local-name()='assignmentItems']/*[local-name()='value']/*[local-name()='stringValue' and contains(text(),'OnboardingRecord-only invocation is not supported')]]" \
  "DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records: unsupported OnboardingRecord path sets deterministic error message"

assert_xpath_exists "$related_req_flow" \
  "/*[local-name()='Flow']/*[local-name()='decisions'][*[local-name()='name' and text()='Decide_On_Logical_Creation_Path'] and *[local-name()='rules'][*[local-name()='name' and text()='Via_OnboardingRecord'] and *[local-name()='connector']/*[local-name()='targetReference' and text()='Assign_Onboarding_Record_Path_Not_Supported_Error']]]" \
  "DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records: Via_OnboardingRecord routes to deterministic error assignment"

assert_xpath_exists "$related_req_flow" \
  "/*[local-name()='Flow']/*[local-name()='subflows'][*[local-name()='name' and text()='Create_Agreement'] and *[local-name()='outputAssignments'][*[local-name()='name' and text()='errorMessage'] and *[local-name()='assignToReference' and text()='errorMessage']]]" \
  "DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records: Create_Agreement output propagates errorMessage"

assert_xpath_exists "$related_req_flow" \
  "/*[local-name()='Flow']/*[local-name()='subflows'][*[local-name()='name' and text()='Get_Contract_Record'] and *[local-name()='outputAssignments'][*[local-name()='name' and text()='errorMessage'] and *[local-name()='assignToReference' and text()='errorMessage']]]" \
  "DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records: Get_Contract_Record output propagates errorMessage"

# EXP_Opportunity_SCR_Create_Record focal assertions
assert_xpath_exists "$exp_opp_flow" \
  "/*[local-name()='Flow']/*[local-name()='actionCalls'][*[local-name()='name' and text()='Get_Available_Vendors'] and *[local-name()='faultConnector']/*[local-name()='targetReference' and text()='Capture_Get_Available_Vendors_Fault']]" \
  "EXP_Opportunity_SCR_Create_Record: Get_Available_Vendors has fault connector"

assert_xpath_exists "$exp_opp_flow" \
  "/*[local-name()='Flow']/*[local-name()='actionCalls'][*[local-name()='name' and text()='Get_Default_Vendor_Program'] and *[local-name()='faultConnector']/*[local-name()='targetReference' and text()='Capture_Get_Default_Vendor_Program_Fault']]" \
  "EXP_Opportunity_SCR_Create_Record: Get_Default_Vendor_Program has fault connector"

assert_xpath_exists "$exp_opp_flow" \
  "/*[local-name()='Flow']/*[local-name()='actionCalls'][*[local-name()='name' and text()='Queue_Opportunity_Create_Chain'] and *[local-name()='faultConnector']/*[local-name()='targetReference' and text()='Capture_Queue_Opportunity_Create_Chain_Fault']]" \
  "EXP_Opportunity_SCR_Create_Record: Queue_Opportunity_Create_Chain has fault connector"

assert_xpath_exists "$exp_opp_flow" \
  "/*[local-name()='Flow']/*[local-name()='recordUpdates'][*[local-name()='name' and text()='Update_Account_Record'] and *[local-name()='faultConnector']/*[local-name()='targetReference' and text()='Capture_Update_Account_Record_Fault']]" \
  "EXP_Opportunity_SCR_Create_Record: Update_Account_Record has fault connector"

assert_xpath_exists "$exp_opp_flow" \
  "/*[local-name()='Flow']/*[local-name()='decisions'][*[local-name()='name' and text()='Did_Queue_Opportunity_Create_Chain_Fail'] and *[local-name()='rules'][*[local-name()='name' and text()='Queue_Opportunity_Create_Chain_Failed'] and *[local-name()='connector']/*[local-name()='targetReference' and text()='Handle_Queue_Opportunity_Create_Chain_Output_Error']]]" \
  "EXP_Opportunity_SCR_Create_Record: queue output-failure path routes to explicit handler"

assert_xpath_exists "$exp_opp_flow" \
  "/*[local-name()='Flow']/*[local-name()='subflows'][*[local-name()='name' and text()='Handle_Queue_Opportunity_Create_Chain_Output_Error'] and *[local-name()='flowName' and text()='DOMAIN_OmniSObject_SFL_CREATE_Fault_Message']]" \
  "EXP_Opportunity_SCR_Create_Record: queue output-failure handler uses shared fault-message flow"

# BLL_BRE_Evaluate_Business_Rules focal assertions
assert_xpath_exists "$bll_bre_flow" \
  "/*[local-name()='Flow']/*[local-name()='actionCalls'][*[local-name()='name' and text()='Run_Communication_Dispatch'] and *[local-name()='faultConnector']/*[local-name()='targetReference' and text()='Capture_Run_Communication_Dispatch_Fault']]" \
  "BLL_BRE_Evaluate_Business_Rules: Run_Communication_Dispatch has fault connector"

assert_xpath_exists "$bll_bre_flow" \
  "/*[local-name()='Flow']/*[local-name()='actionCalls'][*[local-name()='name' and text()='Run_Onboarding_Orchestrator'] and *[local-name()='faultConnector']/*[local-name()='targetReference' and text()='Capture_Run_Onboarding_Orchestrator_Fault']]" \
  "BLL_BRE_Evaluate_Business_Rules: Run_Onboarding_Orchestrator has fault connector"

assert_xpath_exists "$bll_bre_flow" \
  "/*[local-name()='Flow']/*[local-name()='actionCalls'][*[local-name()='name' and text()='Run_Onboarding_Status_Normalization'] and *[local-name()='faultConnector']/*[local-name()='targetReference' and text()='Capture_Run_Onboarding_Status_Normalization_Fault']]" \
  "BLL_BRE_Evaluate_Business_Rules: Run_Onboarding_Status_Normalization has fault connector"

assert_xpath_exists "$bll_bre_flow" \
  "/*[local-name()='Flow']/*[local-name()='actionCalls'][*[local-name()='name' and text()='Run_Vendor_Program_Approval_Policy'] and *[local-name()='faultConnector']/*[local-name()='targetReference' and text()='Capture_Run_Vendor_Program_Approval_Policy_Fault']]" \
  "BLL_BRE_Evaluate_Business_Rules: Run_Vendor_Program_Approval_Policy has fault connector"

echo "Validation complete: ${passes} pass, ${failures} fail"
if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
