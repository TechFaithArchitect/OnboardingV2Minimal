# Support and Troubleshooting

## Fast Triage Matrix

| Symptom | Likely Layer | First Check |
|---|---|---|
| Onboarding record not created | EXP/BLL create path | `EXP_Opportunity_SCR_Create_Record` run outcome and related contract/opportunity |
| Requirement rows missing | DOMAIN requirement create | `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements` execution path |
| Subject rows missing | Fulfillment policy expansion | Policy key on requirement and subject expansion flow behavior |
| Status stuck or unexpected | Status normalization/evaluation | Normalized statuses and ordered CMDT rule match |
| Communication not sent | Dispatch policy or template | Communication policy + template resolution + recipient set |
| Silent async delay | Deferred tail enabled | Queueable job activity and chain events |

## Required Artifacts for Any Ticket

- Record ids (onboarding, requirement, subject)
- Flow or UI action path user took
- Timestamp
- Error Log Id
- User profile/permission set context

## Where to Look

- `Error_Log__c` for technical failure detail
- Flow debug details for failed interviews
- Related records under onboarding graph for missing link analysis

## Common Root Causes

- Invalid or incomplete contact role responsibility setup
- Missing or mismatched fulfillment policy mapping
- Metadata rule precedence changes causing different status outcome
- Integration auth/config drift (Adobe/LearnUpon)
- Permission set gaps after metadata updates

## Standard Resolution Path

1. Confirm data shape and required relationship links.
2. Confirm metadata policy/normalization/rule configuration.
3. Confirm automation execution path and fault details.
4. Apply data/config/code fix.
5. Re-run safe evaluation path and confirm expected final state.
