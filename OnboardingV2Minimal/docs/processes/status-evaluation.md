# Status Evaluation (MVP)

This document describes how onboarding status is evaluated using the rules engine.

## Inputs

- `Onboarding__c`
- `Onboarding_Requirement__c` statuses
- `Onboarding_Status_Rules_Engine__c` and `Onboarding_Status_Rule__c`

## Flow

1. Load active rules engines for the Vendor Program Group.
2. For each engine, evaluate rules against requirement statuses.
3. Apply the target onboarding status when a rule passes.
4. If no rule matches, fallback to progress‑based status logic.

## Overrides

If an external override is active, the evaluator does not update the onboarding status.

## Related Classes

- `OnboardingStatusEvaluator`
- `OnboardingRuleEvaluator`
- `OnboardingRulesService`
