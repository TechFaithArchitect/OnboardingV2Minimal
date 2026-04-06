# Integrations

**Org-level connector inventory (fill in per environment):** [Environment and integrations matrix](./ENVIRONMENT_AND_INTEGRATIONS_MATRIX.md).

## Quick Read

This project currently depends on three integration areas:

- Adobe Sign (agreements)
- LearnUpon (training)
- Email template sync (Salesforce metadata + communication template objects)

If any integration is misconfigured, users usually see missing sends, stalled training artifacts, or flow faults captured in `Error_Log__c`.

## Integration Inventory

| Integration                  | Surface in Repo                                     | Purpose                                                 |
| ---------------------------- | --------------------------------------------------- | ------------------------------------------------------- |
| Adobe Sign (`echosign_dev1`) | Agreement flows and contract send screen flow       | Agreement creation and signature lifecycle evidence     |
| LearnUpon                    | Enrollment and portal membership flows/classes      | Training enrollment and assignment sync                 |
| Salesforce Metadata API      | `EmailTemplateSyncService` and related repositories | Sync email template catalog and communication templates |

Current release note: outbound SMS provider integrations are intentionally retired from this code line.

## How To Set Up and Validate (Per Integration)

### Adobe Sign setup and validation

1. Confirm Adobe Sign connector/auth is configured for the target org (sandbox first, then higher envs).
2. Confirm program/contract setup references expected agreement template where your process requires it.
3. Run `EXP_Contract_SCR_Send_Adobe_Agreement` on a test contract.
4. Verify agreement record creation and expected downstream onboarding/contract behavior.
5. If anything fails, check `Error_Log__c` and fix connector/permission/config issues before promotion.

### LearnUpon setup and validation

1. Confirm LearnUpon endpoint/auth configuration for the environment.
2. Confirm training requirements are correctly linked to vendor program requirements.
3. Run a test onboarding path that should create training/enrollment artifacts.
4. Verify LearnUpon-related records are created/updated by BLL/DOMAIN flows.
5. Validate scheduled consistency paths in UAT (membership review/update) before production rollout.

### Email template sync setup and validation

1. Confirm communication metadata is ready: `Communication_Template__c`, template assignments, event/dispatch policy rows.
2. Run sync in lower environment first (`EmailTemplateSyncService` / `EmailTemplateSyncJob` path used by your org).
3. Verify expected template rows/ids in `Communication_Template__c`.
4. Run one event-driven communication test (for example `SetupComplete`) and verify send outcome.
5. If sync/send fails, check `Error_Log__c`, integration user access, and metadata alignment.

## Adobe Agreement Path

- User interaction flow: `EXP_Contract_SCR_Send_Adobe_Agreement`
- Business action flow: `BLL_OmniSObject_ACTION_Send_Adobe_Agreement`
- Contract and onboarding status updates are routed through domain create/update flows
- Faults are captured through standard fault handler flow

## LearnUpon Path

Key automation includes:

- `DOMAIN_OmniSObject_SFL_CREATE_LearnUponContactEnrollment`
- `DOMAIN_OmniSObject_SFL_CREATE_LearnUpon_Contact_Enrollment_Membership_Record`
- `BLL_LearnUponContactEnrollment_RCD_Connect_Logical_Records`
- Scheduled review/update flows for membership consistency

## Email Template Sync

- Entry service: `EmailTemplateSyncService`
- Scheduled wrapper: `EmailTemplateSyncJob`
- Sync compares source templates, communication template records, and CMDT catalog entries
- Metadata deployment is used for new CMDT rows

### Operations (who runs it, when)

1. **Owner:** normally **platform/admin**, not end users.
2. **Environment:** run or schedule **lower environments first**; confirm `Communication_Template__c` rows and **Email Template Ids** match what [Admin Operations Runbook](../admin/ADMIN_OPERATIONS_RUNBOOK.md) expects before prod.
3. **Schedule:** your org may use **scheduled Apex** (`EmailTemplateSyncJob`) or an external CI step—document the **actual** schedule in your [environment and integrations matrix](./ENVIRONMENT_AND_INTEGRATIONS_MATRIX.md).
4. **Failure mode:** treat failures like other integrations—check **`Error_Log__c`** and integration user permissions.

## Scenario Playbooks

### Scenario 1: Adobe agreement send fails

1. Confirm the test contract/program has required agreement context.
2. Re-run `EXP_Contract_SCR_Send_Adobe_Agreement` with a known-good test record.
3. Check `Error_Log__c` for connector/auth/template faults.
4. Fix config or permissions and retest in the same environment.

### Scenario 2: LearnUpon enrollment not created

1. Confirm training requirements exist for the vendor program path under test.
2. Confirm onboarding reached the step that should trigger enrollment.
3. Check related LearnUpon records and `Error_Log__c`.
4. Validate scheduled consistency flow timing if enrollment is delayed.

### Scenario 3: Template exists but email did not send

1. Confirm event policy row exists and is active for the event key.
2. Confirm dispatch policy allows recipient type for that communication type.
3. Confirm template assignment is active for the vendor program.
4. Validate recipient resolution data (contact/role path) and review `Error_Log__c`.

## Operational Integration Notes

- All external integration failure paths should route into fault logging (`Error_Log__c`)
- Provider configuration should be validated in lower environments before release
- Integration configuration access should remain permission-controlled
