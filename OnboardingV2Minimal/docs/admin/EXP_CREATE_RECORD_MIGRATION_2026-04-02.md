# EXP Create Record Migration (2026-04-02)

This note captures the consolidation of the create experience into the canonical flow and class naming.

## Scope Delivered

- Canonical flow is now `EXP_Opportunity_SCR_Create_Record` (latest/active in org).
- Legacy flow `EXP_Opportunity_SCR_Create_Record_V2` removed from repo and org.
- LWC canonical component is `c:expCreateRecord`.
- Legacy class names removed in favor of:
  - `ExpOpportunityCreateAsyncService`
  - `ExpOpportunityCreateRecord`
  - `ExpOpportunityCreateRecordTest`

## Naming Refactor

- `ExperienceOpportunityCreateAsyncService` -> `ExpOpportunityCreateAsyncService`
- `ExpOpportunityCreateRecordV2Facade` -> `ExpOpportunityCreateRecord`
- `ExpOpportunityCreateRecordV2FacadeTest` -> `ExpOpportunityCreateRecordTest`

## Deployment / Cleanup Evidence (OnboardV2)

- Main deploy (flow + LWC + classes + CMDT + profile): `0AfRL00000diY9B0AU` (Succeeded)
- Legacy cleanup included:
  - Deactivated and deleted `EXP_Opportunity_SCR_Create_Record_V2` versions
  - Deleted obsolete `EXP_Opportunity_SCR_Create_Record` versions that still referenced legacy async class
  - Deleted blocking `FlowInterview` records when required
  - Deleted legacy Apex classes from org (`ExperienceOpportunityCreateAsyncService`, `ExpOpportunityCreateRecordV2Facade`, `ExpOpportunityCreateRecordV2FacadeTest`)

## Org Verification Queries (Summary)

- `FlowDefinition` includes `EXP_Opportunity_SCR_Create_Record` only (for this create path).
- `FlowDefinition` no longer includes `EXP_Opportunity_SCR_Create_Record_V2`.
- Apex classes present for this path:
  - `ExpOpportunityCreateAsyncService`
  - `ExpOpportunityCreateRecord`
  - `ExpOpportunityCreateRecordTest`
- `Start_Onboarding_V2` quick action is not present; canonical quick action is `Start_Onboarding`.

## Test Results

- Full local test run:
  - Run Id: `707RL00001KSExN`
  - Outcome: Failed
  - Results: `672` pass, `286` fail, `10` compile fail
  - These failures are pre-existing/unrelated broad org-suite failures outside this migration.
- Prior full local run (for traceability):
  - Run Id: `707RL00001KS3RC`
  - Results: `651` pass, `307` fail, `10` compile fail
- Targeted tests for migrated scope:
  - Run Id: `707RL00001KSDoK`
  - Outcome: Passed (`26/26`)
  - Classes:
    - `ExpOpportunityCreateRecordTest`
    - `ExpOppCreateAsyncServiceTest`
    - `RecordCollectionEditorConfigServiceTest`

## Admin Follow-up

- For onboarding requirement creation failures on new requirement type values, follow:
  - [MANUAL_VENDOR_PROGRAM_SETUP.md](./MANUAL_VENDOR_PROGRAM_SETUP.md#41-adding-a-brand-new-requirement-type-first-time-value)
