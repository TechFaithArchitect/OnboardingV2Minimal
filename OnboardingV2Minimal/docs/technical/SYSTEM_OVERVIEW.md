# System Overview

## Plain-English Summary

Think of the system as a pipeline:

1. A user starts onboarding in a screen flow.
2. The system creates onboarding records and requirements.
3. Evidence updates those requirements.
4. Rules compute final onboarding status.
5. Communication rules decide if and who gets email.

## Architecture Style

OnboardingV2 follows a layered automation model inside Salesforce:

- `EXP_*`: user-facing screen flows for guided interactions
- `BLL_*`: record-triggered and orchestrator flows for business logic
- `DOMAIN_*` and `DOM_*`: reusable get/create/evaluate building blocks
- Apex services: rule engines, async workers, dynamic UI services, and invocable adapters

This yields modular behavior while keeping Flow as the orchestration surface.

## Primary Execution Paths

### 1) Opportunity-Led Onboarding Creation

1. User runs `EXP_Opportunity_SCR_Create_Record`.
2. Flow resolves vendor options and program path decisions.
3. Core records are created: Opportunity, OCR, Contract.
4. Onboarding tail runs either inline (sync) or deferred via `OnboardingEnqueueOnboardingTailInvocable` -> `OnboardingChainTailQueueable`.
5. Tail executes `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record`.

Deferred behavior is controlled by `Onboarding_Performance_Config__mdt.Default.Defer_Onboarding_Tail__c` (currently `true`).

### 2) Onboarding Requirements Lifecycle

1. `BLL_Onboarding_RCD_Logical_Process` triggers on Onboarding create/update.
2. `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements` seeds requirement rows.
3. Requirement subjects are expanded via fulfillment policy.
4. Evidence events update subject statuses through `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_By_Evidence`.
5. Parent requirement is rolled up by `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_Parent` or bulk invocable.

### 3) Onboarding Status Evaluation

1. Requirement statuses are normalized (`Onboarding_Status_Normalization__mdt`).
2. Ordered rule evaluation runs (`Onboarding_Status_Evaluation_Rule__mdt`).
3. `OnboardingStatusEvaluatorService` selects first matching rule.
4. Onboarding status and optional opportunity stage are updated.

### 4) Communication Dispatch

1. Event/context enters `BLL_Onboarding_SFL_Dispatch_Communication_By_Event`.
2. Template and dispatch policies are loaded.
3. Recipient strategy resolves account/contact/agent/principal-owner routes.
4. Email send and logging execute with fault handling.

## Reliability and Fault Model

- Domain-level reusable fault flow: `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message`
- Apex fault persistence: `OnboardingErrorLogInvocable` -> `OnboardingErrorLogService`
- Categorized error subtype derivation (Communication, Requirement Subjects, BRE, Training Sync, Agreement, Experience Create Record)
- PII redaction support through logging utility configuration

## Key Operational Signals

- `Error_Log__c` for automation failures
- `Onboarding_Opportunity_Chain__e` for deferred onboarding tail chain progress events
