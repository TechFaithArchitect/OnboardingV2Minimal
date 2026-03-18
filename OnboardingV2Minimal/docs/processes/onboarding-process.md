# Onboarding Process (MVP)

This document describes the MVP onboarding lifecycle.

## Creation

1. User launches onboarding from an Account (e.g., via `onboardingDealerOnboardingModal` or quick action).
2. System creates `Onboarding__c` for the Account + Vendor Program.
3. System creates `Onboarding_Requirement__c` from active `Vendor_Program_Requirement__c`.

## Requirement Updates

- Onboarding reps update requirement statuses in the onboarding UI.
- Requirement status changes trigger status evaluation.

## Status Evaluation

1. Flow `BLL_Onboarding_Requirement_RCD_Logical_Process` runs on Onboarding Requirement create/update.
2. `OnboardingStatusEvaluatorInvocable` evaluates rules from `Onboarding_Status_Normalization__mdt` and `Onboarding_Status_Evaluation_Rule__mdt`.
3. `Onboarding__c.Onboarding_Status__c` and `Opportunity.StageName` are updated when conditions are met.

## Overrides

- Requirement-level override behavior is controlled by `Onboarding_Requirement__c.Is_Overridden__c`.
- Override/status changes are audited via field history tracking on `Onboarding_Requirement__c`.
