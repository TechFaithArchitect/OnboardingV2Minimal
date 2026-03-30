# Integrations

## Integration Inventory

| Integration | Surface in Repo | Purpose |
|---|---|---|
| Adobe Sign (`echosign_dev1`) | Agreement flows and contract send screen flow | Agreement creation and signature lifecycle evidence |
| LearnUpon | Enrollment and portal membership flows/classes | Training enrollment and assignment sync |
| Salesforce Metadata API | `EmailTemplateSyncService` and related repositories | Sync email template catalog and communication templates |

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

## Operational Integration Notes

- All external integration failure paths should route into fault logging (`Error_Log__c`)
- Provider configuration should be validated in lower environments before release
- Integration configuration access should remain permission-controlled
