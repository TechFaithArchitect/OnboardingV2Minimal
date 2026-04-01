# Deployment Runbook

## New Release Manager Quick Path

If this is your first deployment, follow this order:

1. Build Gearset comparison.
2. Confirm include scope using [GEARSET_INCLUDE_LIST.md](./GEARSET_INCLUDE_LIST.md).
3. Confirm planned UAT flow deactivations (if any) using [UAT_FLOW_DEACTIVATION_CANDIDATES.md](./UAT_FLOW_DEACTIVATION_CANDIDATES.md).
4. Deploy in Gearset.
5. Run smoke tests from this runbook and record results.

## Preconditions

- Gearset pipeline configured for this repository
- Required permission sets and metadata dependencies included
- Test strategy defined for changed automation paths
- Backout plan identified for high-risk changes

## Gearset Pipeline Model

Primary deployment path is Gearset, not direct CLI deploy.

Use these companion docs:

- Gearset include baseline: [GEARSET_INCLUDE_LIST.md](./GEARSET_INCLUDE_LIST.md)
- UAT deactivation targets from org comparison: [UAT_FLOW_DEACTIVATION_CANDIDATES.md](./UAT_FLOW_DEACTIVATION_CANDIDATES.md)
- Metadata drift between orgs and source: [METADATA_DRIFT_CHECKLIST.md](./METADATA_DRIFT_CHECKLIST.md)
- Release notes and smoke-test template: [RELEASE_NOTES_AND_SMOKE_TEST_TEMPLATE.md](./RELEASE_NOTES_AND_SMOKE_TEST_TEMPLATE.md)
- Baseline setup (what to smoke-test after onboarding-related changes): [BASELINE_SETUP_GUIDE.md](../BASELINE_SETUP_GUIDE.md)

## Recommended Deploy Sequence

1. Validate source formatting/lint/tests locally.
2. Build Gearset comparison against target pipeline stage (use [METADATA_DRIFT_CHECKLIST.md](./METADATA_DRIFT_CHECKLIST.md) for recurring org-vs-source discipline).
3. Confirm include/exclude set using the Gearset include baseline.
4. Apply planned flow deactivations in target stage where required.
5. Deploy through Gearset.
6. Run targeted Apex tests and smoke tests.
7. Promote through remaining pipeline stages.

## Core Commands

The following commands are for local validation and diagnostics. Replace `<alias>` (and any example alias such as `OnboardV2` below) with the Salesforce CLI org alias for your target environment.

```bash
sf org list
sf config get target-org
sf project deploy start --target-org <alias> --source-dir force-app
sf apex run test --target-org <alias> --test-level RunLocalTests
```

For scoped deploys:

```bash
sf project deploy start --target-org <alias> --source-dir force-app/main/default/flows
sf project deploy start --target-org <alias> --source-dir force-app/main/default/classes
```

## Prepared Destructive Cleanup Package

Prepared for org-side cleanup (validate first, then execute):

- [manifest/destructive-cleanup-onboardv2-2026-03-31/README.md](/Users/jasonmu/OnboardingV2Minimal/OnboardingV2Minimal/manifest/destructive-cleanup-onboardv2-2026-03-31/README.md)
- [manifest/destructive-cleanup-onboardv2-2026-03-31/destructiveChangesPost.xml](/Users/jasonmu/OnboardingV2Minimal/OnboardingV2Minimal/manifest/destructive-cleanup-onboardv2-2026-03-31/destructiveChangesPost.xml)
- [manifest/destructive-cleanup-onboardv2-2026-03-31/destructiveChangesPost-blocked-objects.xml](/Users/jasonmu/OnboardingV2Minimal/OnboardingV2Minimal/manifest/destructive-cleanup-onboardv2-2026-03-31/destructiveChangesPost-blocked-objects.xml)

Current status:

- `Onboarding__c.Program_Territory__c`
- `Onboarding__c.Terms_Conditions_Status_TEMP__c`
- `Onboarding__c.Vendor_Customization_Vertical__c`
- validated as deletable in dry-run (`0AfRL00000dfatu0AA`)
- `Audit__c`
- `Order__c`
- currently blocked by org dependencies; see package README prework section

Validation caveat:

- `RunLocalTests` dry-run currently fails in OnboardV2 due unrelated org-wide Apex compile/test issues (`0AfRL00000dfaVi0AI`).
- Use `NoTestRun` in sandbox validation for this cleanup package.

## Post-Deploy Validation Checklist

- Confirm key flows are Active and latest version is deployed.
- Confirm `BLL_Onboarding_RCD_SYNC_Account_Vendor_Program_Onboarding` is Active.
- Confirm planned UAT deactivation candidates are deactivated where applicable.
- Run onboarding creation smoke path from sales screen flow.
- Validate requirement expansion and subject creation.
- Validate evidence update path updates subject and parent requirement status.
- Validate onboarding status evaluator updates lifecycle correctly.
- Confirm fault handler still logs expected errors into `Error_Log__c`.

## One-Time Data Backfill (AVO)

If existing `Onboarding__c` rows pre-date AVO sync automation, run:

```bash
sf apex run --target-org OnboardV2 --file scripts/apex/backfill_account_vendor_program_onboarding.apex
```

(`OnboardV2` is an example alias only; substitute your org.)

Expected result:

- Existing onboarding rows create/update corresponding `Account_Vendor_Program_Onboarding__c` rows.
- Primary contact is sourced from primary OCR when role is `Principal Owner`, `Owner`, or `Authorized Signer`.

## Rollback Strategy

- Redeploy previous known-good metadata package.
- If data side effects occurred, run data correction scripts before re-enabling automation.
- Document rollback trigger conditions and incident details.
