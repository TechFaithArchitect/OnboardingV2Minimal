# Status Evaluation (MVP)

This document describes how onboarding status is evaluated.

## Inputs

- `Onboarding__c` (with related `Onboarding_Requirement__c` records)
- `Onboarding_Status_Normalization__mdt` (CMDT) – per-requirement normalized status mapping (Requirement_Type__c + Status__c → Normalized_Status__c)
- `Onboarding_Status_Evaluation_Rule__mdt` (CMDT) – rules for evaluating target Onboarding Status and Opportunity Stage
- Flow: `BLL_Onboarding_Requirement_RCD_Logical_Process` – record-triggered on Onboarding Requirement create/update

## Flow

1. When an Onboarding Requirement is created or updated, the flow runs.
2. The flow calls `OnboardingStatusEvaluatorInvocable` (Apex) with the Onboarding Id.
3. The invocable loads requirements, normalizes statuses via `Onboarding_Status_Normalization__mdt`, and evaluates rules from `Onboarding_Status_Evaluation_Rule__mdt` in order.
4. The first matching rule determines the target Onboarding Status (and optionally Opportunity Stage).
5. The invocable updates `Onboarding__c.Onboarding_Status__c` and `Opportunity.StageName` when applicable.

## Evaluation Rules (Condition Types)

- `ANY_DENIED` – Any requirement has normalized status Denied → Denied
- `OPPORTUNITY_CANCELED` – Opportunity stage is Canceled/Closed Lost → Canceled
- `ALL_SETUP_COMPLETE` – All requirements Setup Complete or Ignore → Setup Complete
- `ONLY_AGREEMENT_OUT_FOR_SIGNATURE` – Only Agreement has "Out for signature" → Out For Signature
- `ONLY_AGREEMENT_SIGNED` – Only Agreement has Signed/Setup Complete → Pending Initial Review
- `AGREEMENT_SIGNED_AND_CONTRACT_COMPLETE` – Agreement signed, Contract complete → In Process
- `PENDING_SALES` – Not denied, not all complete, Assigned_Team = Sales → Pending Sales
- `IN_PROCESS_DEFAULT` – Not denied, not all complete → In Process

## Overrides

When `Onboarding_Requirement__c.Is_Overridden__c` is true, the normalized status can differ from the raw status.
