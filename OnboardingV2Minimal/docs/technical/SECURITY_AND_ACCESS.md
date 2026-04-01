# Security and Access

**Persona-to-permission-set mapping and onboarding guidance:** [Persona and permission sets](./PERSONA_AND_PERMISSION_SETS.md).

## Plain-English Summary

Users should only have the permission sets needed for their job.  
Automation should respect user/security context and log errors instead of failing silently.

## Access Model

OnboardingV2 uses permission-set-based access controls for operational personas.

Current permission sets in source:

- `Onboarding_Program_Sales_Team`
- `Onboarding_Account_Services`
- `Onboarding_Program_Specialists`
- `Onboarding_Compliance_Team`
- `Onboarding_Finance_Team`
- `Onboarding_Customer_Service`
- `Onboarding_Status_Rule_Config`
- `Onboarding_Can_Send_Special_Chuzo_Agreement`
- `Standard_User`

## Apex Security Posture

Patterns present in core classes:

- `with sharing` used for most services/controllers
- `WITH SECURITY_ENFORCED` in many read paths
- `WITH USER_MODE` in selected queueable queries
- `update as user` used in evaluator apply paths

Exceptions are explicit and documented in code comments where automation behavior requires relaxed read paths to avoid silent no-op outcomes.

## Flow Security Posture

- Domain getter flows isolate data access responsibilities
- Business flows call domain flows and apply fault handling patterns
- Sensitive operations route through reusable fault/logging flow to avoid silent failures

## Data Protection and Logging

- Logging pipeline uses `OnboardingErrorLogService`
- Provider labels and subtype categories are applied for triage
- PII redaction is supported and enabled by default in logging config

## Hardening Priorities

- Maintain least-privilege permission set assignments by function
- Continue removal of legacy field dependencies and references
- Add validation rules for responsibility uniqueness constraints where business policy requires single-owner semantics
- Keep automation-level guardrails around OCR/ACR role assumptions
