# Automation Catalog

## Catalog Method

This catalog is derived from current flow metadata and Apex entry points.

## Flow Families

Current flow inventory is organized mainly as:

- `BLL`: 26 flows
- `DOMAIN`: 52 flows
- `EXP`: 5 flows
- `Onboarding`: 1 flow
- `Opportunity`: 1 flow

## Critical Record-Triggered Flows

| Flow | Trigger |
|---|---|
| `BLL_Opportunity_RCD_Logical_Process` | Opportunity `after insert` |
| `BLL_Onboarding_RCD_Logical_Process` | Onboarding__c `after insert/update` |
| `BLL_Onboarding_Requirement_RCD_Logical_Process` | Onboarding_Requirement__c `after insert/update` |
| `BLL_Onboarding_Requirement_Subject_RCD_Logical_Process` | Onboarding_Requirement_Subject__c `after update` |
| `BLL_OmniSObject_RCD_SYNC_Training_Assignments` | Training_Assignment__c `after insert/update` |
| `BLL_Agreement_RCD_Logical_Process` | echosign_dev1__SIGN_Agreement__c `after update` |
| `BLL_External_Contact_Credential_RCD_Logical_Process` | POE_External_Contact_Credential__c `after update` |

## Scheduled Flows

| Flow | Purpose |
|---|---|
| `BLL_Onboarding_SCD_Review_and_Assign_Missing_Training_Records` | Backfill/consistency for onboarding training records |
| `BLL_LearnUpon_Portal_Membership_SCD_Review_Update_Portal_Memberships` | LearnUpon membership maintenance |
| `BLL_Training_Assignment_SCD_Training_Reminder_Emails` | Reminder communication scheduling |

## Key Screen Flows

| Flow | User Surface |
|---|---|
| `EXP_Opportunity_SCR_Create_Record` | Sales/onboarding guided opportunity onboarding creation |
| `EXP_Opportunity_Contacts_SCR_CREATE_Opportunity_Contacts` | OCR assignment and contact selection |
| `EXP_Contact_SCR_Create_Contact` | Contact + account-contact relationship creation path |
| `EXP_Contract_SCR_Send_Adobe_Agreement` | Agreement send initiation and user feedback |

## High-Value Domain Subflows

| Flow | Role |
|---|---|
| `DOMAIN_OmniSObject_SFL_GET_Primary_Opportunity_Contact` | Primary OCR retrieval and fallback pathways |
| `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements` | Requirement row generation |
| `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirement_Subjects` | Subject expansion by policy |
| `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_By_Evidence` | Evidence-to-subject status mapping |
| `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_Parent` | Parent requirement roll-up |
| `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` | Reusable fault handling + logging bridge |

## Apex Invocable Entry Points (Selected)

| Class | Purpose |
|---|---|
| `OnboardingStatusEvaluatorInvocable` | CMDT-driven onboarding status evaluation/apply |
| `OnbReqParentBulkEvalInvocable` | Bulk parent requirement roll-up |
| `OnboardingRequirementSubjectInvocable` | Idempotent subject creation |
| `OnboardingEnqueueOnboardingTailInvocable` | Queueable deferred onboarding tail |
| `OnboardingErrorLogInvocable` | Flow fault persistence to `Error_Log__c` |
| `VendorOnboardingJsonAdapter` | Eligible vendor JSON for flow/LWC |
| `FlowAdminGuardService` | Administrative guardrail checks for flow automation paths |

## Automation Design Principles in Use

- Prefix-based layering for discoverability
- Reusable getter/creator/evaluator domain subflows
- Fault paths routed into a standard handler
- Bulk-aware invocables for parent-child recalculation paths
- Async offload where user latency matters and consistency can remain eventual
