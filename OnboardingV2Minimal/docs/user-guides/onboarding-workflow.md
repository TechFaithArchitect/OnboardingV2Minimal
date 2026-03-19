# Onboarding Workflow

This guide reflects the current OnboardV2 flow/CMDT design (not legacy wizard behavior).

## Overview

Each `Onboarding__c` record represents one account onboarding to one vendor program. Requirement rows are created from active `Vendor_Program_Requirement__c` definitions.

## Start onboarding

1. Open the Account record.
2. Run the onboarding start quick action (currently backed by `EXP_Opportunity_SCR_Create_Record`).
3. Select the vendor program and submit.
4. System creates:
   - `Onboarding__c`
   - `Onboarding_Requirement__c` rows for that program
   - related subject rows where fulfillment policy requires them (`Onboarding_Requirement_Subject__c`)

## Work the onboarding

Use the **Onboarding record Lightning page** and its related-list components (including `objectRelatedList`) to:

- Review requirement rows
- Update requirement status/override fields
- Track onboarding progress/status

## Status evaluation model

Status updates are CMDT-driven and flow/Apex-evaluated:

- Requirement status normalization: `Onboarding_Status_Normalization__mdt`
- Onboarding status rules: `Onboarding_Status_Evaluation_Rule__mdt`
- Subject fulfillment model: `Onboarding_Fulfillment_Policy__mdt`

Primary status owner flow: `BLL_Onboarding_Requirement_RCD_Logical_Process`.

For business-facing rule maintenance, use:

- `docs/user-guides/onboarding-status-business-rules-guide.md`

## Common admin actions

- Update program requirement definitions in `Vendor_Program_Requirement__c`
- Adjust normalization/rule CMDT records
- Use overrides only for exception handling, not steady-state rule behavior
