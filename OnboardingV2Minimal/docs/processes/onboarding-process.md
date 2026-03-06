# Onboarding Process (MVP)

This document describes the MVP onboarding lifecycle.

## Creation

1. User launches `accountProgramOnboardingModal` from an Account.
2. System creates `Onboarding__c` for the Account + Vendor Program.
3. System creates `Onboarding_Requirement__c` from active `Vendor_Program_Requirement__c`.

## Requirement Updates

- Onboarding reps update requirement statuses in `onboardingRequirementsPanel`.
- Requirement status changes trigger status evaluation.

## Status Evaluation

1. Load active `Onboarding_Status_Rules_Engine__c` for the Vendor Program Group.
2. Evaluate each `Onboarding_Status_Rule__c` against requirement statuses.
3. Update `Onboarding__c.Onboarding_Status__c` when a rule passes.

## Overrides

- Requirement-level override behavior is controlled by `Onboarding_Requirement__c.Is_Overridden__c`.
- Override/status changes are audited via field history tracking on `Onboarding_Requirement__c`.
- Next-step guidance can be overridden via `Onboarding_Next_Step_Override__c`.
