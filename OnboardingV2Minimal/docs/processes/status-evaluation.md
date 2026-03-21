# Status Evaluation

This document describes the current status-evaluation chain and the intended single-owner pattern.

## Current chain

1. Evidence updates subject status (`Onboarding_Requirement_Subject__c.Status__c`).
2. Subject statuses roll up to parent requirement status/completion.
3. Requirement change triggers `BLL_Onboarding_Requirement_RCD_Logical_Process`.
4. That flow calls `OnboardingStatusEvaluatorInvocable`.
5. Evaluator normalizes statuses and applies ordered CMDT rules.
6. Evaluator updates `Onboarding__c.Onboarding_Status__c` and optional `Opportunity.StageName`.

## CMDT used

- `Onboarding_Status_Normalization__mdt`
  - Maps `(Requirement_Type__c, Status__c)` to `Normalized_Status__c`.
- `Onboarding_Status_Evaluation_Rule__mdt`
  - Ordered first-match rules using `Rule_Order__c`.
- `Onboarding_Fulfillment_Policy__mdt`
  - Defines subject model for requirement fulfillment (`Account`, `AllContacts`, `PrincipalOwner`, etc.).

## Evaluation rules (condition types)

- `ANY_DENIED`
- `OPPORTUNITY_CANCELED`
- `ANY_CANCELED`
- `ANY_EXPIRED`
- `ALL_SETUP_COMPLETE`
- `ONLY_AGREEMENT_OUT_FOR_SIGNATURE`
- `ONLY_AGREEMENT_SIGNED`
- `AGREEMENT_SIGNED_AND_CONTRACT_COMPLETE`
- `PENDING_SALES`
- `IN_PROCESS_DEFAULT`

### Condition behavior notes

- `ANY_DENIED` remains metadata-driven: business can override handling by changing rule priority/order and target values in `Onboarding_Status_Evaluation_Rule__mdt`.
- `ANY_CANCELED` is restart-aware: it matches only when at least one requirement normalizes to `Canceled`/`Cancelled` **and** the related Opportunity is still in a canceled/lost stage (`Canceled`, `Cancelled`, `Closed Lost`). If Opportunity is reopened, this condition no longer matches.

## Known design direction

Onboarding status should have one owner flow:

- Owner: `BLL_Onboarding_Requirement_RCD_Logical_Process`
- Other flows should update subject/requirement evidence only, not write onboarding status directly.
- `P0` implementation (2026-03-19) has been deployed: `BLL_Order_RCD_Business_Logic` now routes through evaluator action instead of direct onboarding-status assignment.

See:

- Business guide: `docs/user-guides/onboarding-status-business-rules-guide.md`
- Technical plan: `docs/implementation-notes/onboarding-status-single-owner-flow-plan-2026-03-19.md`
