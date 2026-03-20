# Onboarding Contract-Centric Model and Legacy Migration Plan (2026-03-20)

## Goal

Move Onboarding to a contract-centric model so Agreement and Contract events always update the correct Onboarding Requirement and then drive `Onboarding__c.Onboarding_Status__c` through the existing BRE/CMDT + evaluator path.

## Problem Summary

Current behavior can become ambiguous when:

1. One `Opportunity` has many `Contract` records.
2. One `Contract` has many `Agreement` records over time.
3. One `Opportunity` can have many `Onboarding__c` records.

If Agreement evidence is evaluated broadly by account/requirement-type, wrong onboarding requirements can be updated.

## Target Model (Authoritative Links)

1. `Onboarding__c.Contract__c` is the authoritative relationship for requirement and status routing.
2. `Onboarding__c.Opportunity__c` remains for reporting/UI context (derived from Contract where possible).
3. `Onboarding__c.Agreement__c` stores the current/latest relevant Agreement for user navigation.

Practical rule:

- Resolve status-routing from `Agreement -> Contract -> Onboarding`.
- Do not route Agreement evidence by account-wide requirement-type scope.

## Target Runtime Behavior

### 1) Agreement Signed

When `Agreement.Status = Signed`:

1. Resolve Agreement `ContractId`.
2. Find Onboarding records tied to that Contract.
3. Update only `Onboarding_Requirement__c` rows with `Requirement_Type__c = Agreement` for those onboarding records.
4. Run parent requirement rollup and evaluator.
5. Evaluator sets `Onboarding__c.Onboarding_Status__c` using CMDT rules (example target: `Pending Initial Review`).

### 2) Contract Review Outcome

When user updates Contract status:

1. Find Onboarding records tied to that Contract.
2. Update only `Onboarding_Requirement__c` rows with `Requirement_Type__c = Contract`.
3. Run parent rollup and evaluator.
4. Evaluator sets `Onboarding__c.Onboarding_Status__c` from CMDT.

### 3) User Navigation

Keep easy Agreement access:

1. Continue surfacing `Onboarding__c.Agreement__c` on onboarding layout/LWC.
2. On Agreement events, refresh `Onboarding__c.Agreement__c` to the latest relevant Agreement for that Contract.

## Implementation Plan (Phased)

## Execution Status (2026-03-20)

- Phase 1 step 1/2 completed in `OnboardV2`:
  - `BLL_Agreement_RCD_Logical_Process` now routes Agreement evidence through contract-scoped Apex action `OnbReqContractEvidenceInvocable`.
  - Account-wide Agreement requirement evaluation is removed from this Agreement event path.
  - Deployment reference: `0AfRL00000dSv050AC` (`OnbReqContractEvidenceInvocableTest` `4/4` passing).
- Remaining: Phase 2 invariants and Phase 3 legacy migration/backfill.

## Phase 1 - Routing Safety (No Data Migration Yet)

1. Tighten Agreement-triggered subject/requirement evaluation to contract-scoped onboarding only.
2. Remove account-wide Agreement requirement evaluation paths from Agreement event processing.
3. Keep existing evaluator (`OnboardingStatusEvaluatorInvocable` / `OnboardingStatusEvaluatorService`) as onboarding-status owner.

Acceptance:

- A signed Agreement only updates onboarding requirement rows for onboarding records linked to the same Contract.

## Phase 2 - Contract-Centric Invariants

1. Add sync guard: when `Onboarding__c.Contract__c` is set/changed, align `Onboarding__c.Opportunity__c` to `Contract.Opportunity_to_Contract__c`.
2. Add data-quality rule for mismatches (`Onboarding.Opportunity` must match Contract’s Opportunity when both exist).
3. Define duplicate policy for active onboarding rows per contract (for example, allow many by vendor program, block exact duplicates).

Acceptance:

- New/updated onboarding data cannot drift into Contract/Opportunity mismatch.

## Phase 3 - Legacy Data Migration

Backfill and normalize legacy onboarding records with deterministic mapping and exception reporting.

## Legacy Migration Plan

## A. Pre-Migration Snapshot and Audit

Create exports/reports for:

1. Onboarding records with null `Contract__c`.
2. Onboarding records where `Contract__c` exists but `Opportunity__c` mismatch exists.
3. Opportunities with 2+ contracts and related onboarding records.
4. Contracts with 2+ onboarding records (to apply duplicate policy).

## B. Backfill Resolution Rules (Priority Order)

For each onboarding row, resolve target contract as:

1. Keep existing `Onboarding__c.Contract__c` if valid.
2. Else from `Onboarding__c.Agreement__c -> Agreement.Contract`.
3. Else if onboarding opportunity has exactly one active contract, use that contract.
4. Else mark unresolved for manual review.

## C. Field Updates During Migration

For resolvable rows:

1. Set `Onboarding__c.Contract__c` to resolved contract.
2. Set/align `Onboarding__c.Opportunity__c` from resolved contract’s opportunity.
3. Set `Onboarding__c.Agreement__c` to latest relevant agreement for that contract (if available).

## D. Exception Bucket (Manual Queue)

Do not auto-update rows where:

1. Multiple contracts are valid candidates and no deterministic tie-breaker applies.
2. Contract is closed/invalid per business rules.
3. Record has conflicting legacy links that violate invariants.

Track unresolved rows in a migration exception report for manual assignment.

## E. Post-Migration Verification

1. Re-run the audit reports and confirm mismatch/null counts trend to zero (except approved exceptions).
2. Validate Agreement Signed -> Requirement Agreement status -> Onboarding status in test scenarios.
3. Validate Contract status change -> Requirement Contract status -> Onboarding status in test scenarios.
4. Confirm users can open latest Agreement directly from onboarding.

## Test Scenarios to Validate

1. One Opportunity, one Contract, one Onboarding.
2. One Opportunity, two Contracts, two Onboardings.
3. One Contract, multiple Agreements (new signed agreement should update same onboarding contract scope and latest agreement pointer).
4. Legacy onboarding with null contract resolved by Agreement.
5. Legacy onboarding with ambiguous contracts routes to exception queue only.

## Business/User Summary

1. Agreement events now update only onboarding requirements tied to the same contract.
2. Contract review updates then drive onboarding status via existing CMDT rules.
3. Users still navigate from onboarding to the latest relevant agreement.
4. Legacy records are migrated with deterministic rules and manual-review exceptions.
