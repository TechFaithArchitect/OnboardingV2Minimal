# Onboarding Status Single-Owner Flow Plan (2026-03-19)

## Goal

Use one status-owner flow to update `Onboarding__c.Onboarding_Status__c`, with behavior controlled by CMDT and safe for bulk transactions.

Primary owner flow:

- `BLL_Onboarding_Requirement_RCD_Logical_Process`

## Implementation status

- `2026-03-19`: `P0` implemented and deployed to `OnboardV2` (`0AfRL00000dRee20AC`), validated first via dry-run (`0AfRL00000dRf8f0AC`) with `OnboardingStatusEvaluatorTest` `10/10` passing.

## Current state summary

Working today:

- Requirement changes call `OnboardingStatusEvaluatorInvocable` from `BLL_Onboarding_Requirement_RCD_Logical_Process`.
- Subject evidence updates are supported through:
  - `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_By_Evidence`
  - `BLL_Onboarding_Requirement_Subject_RCD_Logical_Process`
  - `BLL_OmniSObject_RCD_SYNC_Training_Assignments` (bulk parent rollup via `OnbReqParentBulkEvalInvocable`)
- CMDT-driven evaluation exists:
  - `Onboarding_Status_Normalization__mdt`
  - `Onboarding_Status_Evaluation_Rule__mdt`
  - `Onboarding_Fulfillment_Policy__mdt` (subject model)

Remaining gaps after `P0`:

1. Evidence -> subject status mapping is still formula-based in Flow, not CMDT-driven yet.
2. Unused compatibility flow `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_Parent` still exists in metadata and can be retired in a cleanup pass once no downstream dependency is expected.
3. Add automated guardrail scans to fail CI if a future flow directly writes `Onboarding__c.Onboarding_Status__c` outside the owner pattern.

## Target architecture

1. All evidence flows only update subject/requirement-level data.
2. Parent requirement status is recalculated in bulk (single engine).
3. Only `BLL_Onboarding_Requirement_RCD_Logical_Process` updates onboarding status by invoking evaluator.
4. Evaluator reads CMDT and applies first-match rule in order.

This keeps one owner for onboarding status while allowing many source events.

## Action plan

## P0 (must do)

1. Bulk-enable onboarding evaluator invocable.
   - Update `OnboardingStatusEvaluatorInvocable.evaluate(List<EvaluateRequest>)` to process all requests.
   - Dedupe onboarding ids, evaluate/apply in bulk, and return one result per request.
2. Remove direct onboarding status write from `BLL_Order_RCD_Business_Logic`.
   - Replace direct `Setup Complete` assignment with evaluator call path.
3. Declare one parent rollup engine as source of truth.
   - Prefer `OnbReqParentBulkEvalInvocable` for batch-safe rollups.
   - Keep `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_Parent` only as compatibility wrapper or retire it after migration.

## P1 (recommended)

1. Add CMDT for evidence-status mapping to subject status (replace hard-coded formula matrix in evidence flow).
2. Add flow/audit checks to detect any direct writes to `Onboarding__c.Onboarding_Status__c` outside the owner flow.
3. Add regression tests for mixed record types with restricted picklists.

## P2 (optional)

1. Add business-readable reporting dashboard for:
   - rule hit counts
   - unmatched/unsupported evidence statuses
   - failed rollups

## Acceptance criteria

- Any requirement/subject evidence change can update onboarding through the owner flow.
- No active flow directly writes onboarding status except owner flow.
- Bulk update of 200 source records completes without query/DML-in-loop issues.
- Business admins can change normalization/evaluation behavior using CMDT only.

## Business explanation (one sentence)

"Source events update requirement evidence, and one rules engine flow reads CMDT to decide the onboarding status."
