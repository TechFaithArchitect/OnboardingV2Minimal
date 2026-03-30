# Admin Operations Runbook

## Daily Checks

### 1) Automation Health

- Review `Error_Log__c` for new failures.
- Filter by provider `OnboardingV2` and subtype for triage priority.
- Validate no repeated fault loops for the same record.

### 2) Fault Monitoring Health

- Monitor `Error_Log__c` trend volume by type/subtype.
- Confirm no repeated fault patterns for the same automation context.

### 3) Lifecycle Continuity

- Spot check onboarding records with stale statuses.
- Verify requirement and subject rows are advancing from new evidence updates.

## Weekly Checks

- Verify CMDT records still align with business policy.
- Review onboarding status rules for unintended precedence changes.
- Validate communication policy records and template availability.
- Confirm deferred onboarding tail behavior is stable.

## Incident Triage Procedure

1. Gather record ids from user report.
2. Locate related `Error_Log__c` entries.
3. Identify source flow/element and context key.
4. Determine if issue is:
- data issue
- configuration issue
- automation regression
- integration outage
5. Apply fix path and document root cause.

## Core Objects for Admin Monitoring

- `Onboarding__c`
- `Onboarding_Requirement__c`
- `Onboarding_Requirement_Subject__c`
- `Error_Log__c`
- `POE_External_Contact_Credential__c`
- `Training_Assignment__c`
- `Training_Assignment_Onboarding__c`

## Recovery Patterns

- Re-run safe/idempotent automation where available
- Use subject unique key model to avoid duplicates on retries
- Re-evaluate parent requirements in bulk using invocable paths
- Re-evaluate onboarding status after data correction
