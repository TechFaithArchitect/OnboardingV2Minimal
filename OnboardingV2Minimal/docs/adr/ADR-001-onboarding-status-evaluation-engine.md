# ADR-001: Onboarding status evaluation engine

## Status

Accepted (development)

## Context

- Onboarding status must be derived from requirement rows using **stable normalization** and **ordered evaluation rules**.
- Prior approaches (heavy Flow branching; Apex `switch` on opaque condition keys) do not scale: each new rule required code or unmaintainable Flow.
- Normalization changes rarely; **evaluation rules** change more often and should be configurable without new Apex `when` branches.

## Decision

1. **Normalization** — Single source: **`Onboarding_Status_Normalization__mdt`**, loaded at runtime by Apex. No parallel normalization in BRE for this path (the `OnboardingStatusNormalization` expression set is **not** used by `OnboardingStatusEvaluatorService`; avoid drift).

2. **Evaluation** — Single engine: **`OnboardingStatusCmdtRuleEngine`** implementing **`IOnboardingStatusRuleEngine`**, driven by **`Predicate_Config__c`** (JSON) on **`Onboarding_Status_Evaluation_Rule__mdt`**. First matching active rule by `Rule_Order__c` wins; targets come from the same CMDT row.

3. **Primitives** — JSON supports composable `all` / `any` and a fixed set of **`op`** values implemented in **`OnboardingStatusPredicateInterpreter`**. Adding a **new kind of condition** requires a new `op` handler in that class (one place), not a new row type in the evaluator service loop.

4. **Automation** — Record-triggered Flows keep a **single** Apex invocable entry: **`OnboardingStatusEvaluatorInvocable`**. No duplicate evaluators in Flow decision trees.

## Non-goals

- Not maintaining a second evaluator (BRE + CMDT) for the same onboarding status outcome in this codebase path.
- Not requiring business users to use Setup Custom Metadata UI without a future LWC (out of scope for this ADR).

## Consequences

- Admins configure rules by editing **CMDT** (deploy) or a future **LWC + Metadata API** tool; rule **shape** is JSON documented in [docs/onboarding-status-predicate-config.md](onboarding-status-predicate-config.md).
- New **semantic** ops require an Apex change in **`OnboardingStatusPredicateInterpreter`** but not in **`OnboardingStatusEvaluatorService`**.
