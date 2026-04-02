# Support and Troubleshooting

## Start Here (Plain-English Triage)

When a user says “onboarding is broken,” do this first:

1. Identify which record is wrong (`Onboarding__c`, requirement, or subject).
2. Check if the issue is data, policy/config, or automation fault.
3. Confirm by checking `Error_Log__c` and the related records.
4. Fix the root cause, then re-test with the same scenario.

If you need symptom-specific checks, use the FAQs linked below.

## FAQ (symptom-first)

- [FAQ — Sales and Business Users](./FAQ_USERS.md) — “Something is broken — what should I check?” from the UI, before opening a ticket.
- [FAQ — Admins & Platform](./FAQ_ADMINS.md) — Same style for operators: **Error_Log**, CMDT, comms keys, approval gates, integrations.

Use this page for the **compact triage matrix** and **standard resolution path** when you already know the technical layer.

**Baseline vs extensions:** [Baseline setup guide](../BASELINE_SETUP_GUIDE.md) and [FAQ — Admins: scenarios](./FAQ_ADMINS.md#scenario-index-extending-the-baseline).

## Related playbooks

- [System Overview](../technical/SYSTEM_OVERVIEW.md) — end-to-end execution paths
- [Admin Operations Runbook](../admin/ADMIN_OPERATIONS_RUNBOOK.md) — configuration surfaces and monitoring
- [Deployment Runbook](../admin/DEPLOYMENT_RUNBOOK.md) — deploy and validation context
- [Metadata Drift Checklist](../admin/METADATA_DRIFT_CHECKLIST.md) — org vs source parity

## Fast Triage Matrix

| Symptom                       | Likely Layer                    | First Check                                                                      |
| ----------------------------- | ------------------------------- | -------------------------------------------------------------------------------- |
| Onboarding record not created | EXP/BLL create path             | `EXP_Opportunity_SCR_Create_Record` run outcome and related contract/opportunity |
| Requirement rows missing      | DOMAIN requirement create       | `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements` execution path           |
| Subject rows missing          | Fulfillment policy expansion    | Policy key on requirement and subject expansion flow behavior                    |
| Status stuck or unexpected    | Status normalization/evaluation | Normalized statuses and ordered CMDT rule match                                  |
| Communication not sent        | Dispatch policy or template     | Communication policy + template resolution + recipient set                       |
| Silent async delay            | Deferred tail enabled           | Queueable job activity and chain events                                          |

## Required Artifacts for Any Ticket

- Record ids (onboarding, requirement, subject)
- Flow or UI action path user took
- Timestamp
- Error Log Id
- User profile/permission set context

## Automatic Background Retry (Onboarding)

OnboardV2 now auto-captures onboarding background faults into `Onboarding_Background_Job__c` and retries them with idempotency.

- Capture source: `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` via `OnboardingErrorLogInvocable`.
- Scope: any background fault that includes onboarding context (`OnboardingId` input or an onboarding/requirement id in `ContextKey`).
- Idempotency key: `Operation_Type__c + Onboarding__c` (single replay lane per onboarding).
- Operation currently replayed: `Replay Onboarding Background Chain`.
- Retry schedule: immediate queue attempt plus scheduled retries every 10 minutes.
- Backoff: 5, 10, 20, 40, then 60-minute cap until max attempts.
- Terminal state: `Status__c = Dead` when `Attempt_Count__c >= Max_Attempts__c`.

### How to Re-run a Failed Background Chain

1. Open the `Onboarding_Background_Job__c` row for the onboarding.
2. Correct root-cause config/data first (policy, picklist, mapping, etc.).
3. Set:
   - `Status__c = Pending`
   - `Attempt_Count__c = 0`
   - `Next_Run_At__c = NOW` (or blank)
4. Save; the worker will pick it up automatically.

### What to Check First

- `Last_Error__c` on `Onboarding_Background_Job__c`
- linked `Last_Error_Log__c`
- source metadata (`Source_Flow_Api_Name__c`, `Source_Element_Api_Name__c`, `Context_Key__c`)

## Where to Look

- `Error_Log__c` for technical failure detail
- Flow debug details for failed interviews
- Related records under onboarding graph for missing link analysis

## Common Root Causes

- Invalid or incomplete contact role responsibility setup
- Missing or mismatched fulfillment policy mapping
- New `Requirement_Type__c` value added without matching `Onboarding_Requirement__c` record type picklist assignment and flow record-type mapping
- Metadata rule precedence changes causing different status outcome
- Integration auth/config drift (Adobe/LearnUpon)
- Permission set gaps after metadata updates

## Restricted Picklist Error Pattern (Requirements)

If debug shows:

- `INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST: bad value for restricted picklist field: <value>`

on `Create Onboarding Requirements`, treat this as a requirement-type onboarding configuration mismatch (global value set + record type + flow mapping). Use:

- [Manual Vendor Program Setup - 4.1 Adding a brand-new Requirement Type](../admin/MANUAL_VENDOR_PROGRAM_SETUP.md#41-adding-a-brand-new-requirement-type-first-time-value)

## Standard Resolution Path

1. Confirm data shape and required relationship links.
2. Confirm metadata policy/normalization/rule configuration.
3. Confirm automation execution path and fault details.
4. Apply data/config/code fix.
5. Re-run safe evaluation path and confirm expected final state.
