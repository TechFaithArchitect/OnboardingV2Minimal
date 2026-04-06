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

## Automated permission-set check (local)

From the DX project root:

```bash
npm run audit:permissions:highrisk
```

Fails the run if any permission set enables high-risk **user** permissions (for example Author Apex or Modify All Data). Always review reported **`modifyAllRecords: true`** object rows during access reviews.

## How To Manage Access

### Onboard a new user (grant access)

1. Identify persona (Sales, Account Services, Specialist, Compliance, Finance, Service, or Admin config).
2. Assign only the matching permission set(s) from this document and [Persona and permission sets](./PERSONA_AND_PERMISSION_SETS.md).
3. Add any org-standard baseline access your security model requires.
4. Run one real workflow test as that user (create path or operations path) to confirm minimum required access.
5. Record assignment and verification date in your access control process.

### Offboard or reduce access

1. Remove onboarding-related permission sets first.
2. Validate user no longer has access to onboarding objects/actions.
3. Keep audit trail of removed permission sets and date.

### Validate least privilege

1. Confirm user can complete required tasks for their role.
2. Confirm user cannot access admin/config-only features unless role requires it.
3. Re-check after each release that adds new objects/fields/flows.

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

## Scenario Playbooks

### Scenario 1: User cannot run onboarding create flow

1. Confirm persona-matched permission set is assigned.
2. Confirm flow/action visibility for that profile/app context.
3. Confirm object/field access needed by create flow path.
4. Retest as user and capture `Error_Log__c` or UI error text if still failing.

### Scenario 2: User can view records but cannot update required fields

1. Confirm update/edit object permissions are present in assigned permission sets.
2. Confirm field-level security for blocked fields.
3. Confirm no validation rule/business rule is intentionally blocking the action.
4. Adjust permission set scope minimally and retest.

### Scenario 3: User has too much access

1. Compare assigned permission sets vs expected persona bundle.
2. Remove non-required permission sets.
3. Re-run role-based workflow test to confirm required actions still work.
