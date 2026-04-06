#!/usr/bin/env bash
#
# Run a single consolidated Apex test sweep for best-practices / hardening work.
# Class list is the union of all validation runs documented in docs/technical/best-practices-findings.md.
#
# Usage:
#   ./scripts/deploy/run-best-practices-in-scope-tests.sh [org-alias]
#
# Default org alias: OnboardV2 (override with first argument or SF_TARGET_ORG).
#
set -euo pipefail

ORG_ALIAS="${1:-${SF_TARGET_ORG:-OnboardV2}}"

# Deduped from CRUD/FLS, PMD CRUD burn-down, and PMD non-CRUD validation sections,
# plus ObjectRelatedListCtrlTest (covers ObjectRelatedListController PMD hardening).
readonly BP_TEST_CLASSES=(
  AccountVendorOnboardingSyncInvocableTest
  AVOTriggerHandlerTest
  CommunicationEventDispatchInvocableTest
  CommunicationTemplateBulkSendActionTest
  ExpOpportunityCreateRecordTest
  ExpOppCreateAsyncServiceTest
  LoggingUtilTest
  ObjectRelatedListCtrlTest
  OnbReqContractEvidenceInvocableTest
  OnbReqParentBulkEvalInvocableTest
  OnbReqSubjectInvocableTest
  OnboardingBackgroundRetryServiceTest
  OnboardingDefaultVendorProgramInvocTest
  OnboardingErrorLogInvocableTest
  OnboardingNextStepRuleInvocableTest
  OnboardingRequirementVPRGateServiceTest
  OnboardingStatusEvaluatorTest
  RecordCollectionEditorAsyncServiceTest
  RecordCollectionEditorConfigServiceTest
  RecordCollectionEditorGetRecordsTest
)

echo "=========================================="
echo "Best-practices in-scope Apex tests (${#BP_TEST_CLASSES[@]} classes)"
echo " target-org: $ORG_ALIAS"
echo "=========================================="
printf '%s\n' "${BP_TEST_CLASSES[@]}" | nl
echo ""
echo "Running tests..."
echo ""

CMD_ARGS=()
for class in "${BP_TEST_CLASSES[@]}"; do
  CMD_ARGS+=("--class-names" "$class")
done

# --wait is in minutes; consolidated runs can exceed the CLI default.
sf apex run test \
  "${CMD_ARGS[@]}" \
  --target-org "$ORG_ALIAS" \
  --result-format human \
  --code-coverage \
  --wait 45
