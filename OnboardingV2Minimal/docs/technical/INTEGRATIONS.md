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

## Operational Integration Notes

- All external integration failure paths should route into fault logging (`Error_Log__c`)
- Provider configuration should be validated in lower environments before release
- Integration configuration access should remain permission-controlled
