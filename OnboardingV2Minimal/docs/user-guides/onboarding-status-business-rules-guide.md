# Onboarding Status Rules Guide (Business Users)

This guide explains how `Onboarding__c.Onboarding_Status__c` is set and what you can configure without code.

## What the system does

The automation follows this chain:

1. Evidence updates a subject status (`Onboarding_Requirement_Subject__c.Status__c`).
2. Subject statuses roll up to the parent requirement (`Onboarding_Requirement__c.Status__c` and `Completed__c`).
3. Requirement statuses are normalized and evaluated to set `Onboarding__c.Onboarding_Status__c` (and sometimes Opportunity stage).

## What business users can configure (CMDT)

### 1) Status Normalization

Object: `Onboarding_Status_Normalization__mdt`

Use this when the same business meaning has many source values.

- `Requirement_Type__c`: which requirement this applies to (Agreement, Contract, etc.)
- `Status__c`: incoming requirement status
- `Normalized_Status__c`: standardized value used by rules
- `Active__c`: whether this mapping is active

Example: Agreement `Out for Signature` -> `Out for signature` (normalized).

### 2) Onboarding Status Evaluation Rules

Object: `Onboarding_Status_Evaluation_Rule__mdt`

Use this to decide final onboarding status.

- `Condition_Type__c`: rule condition key
- `Rule_Order__c`: evaluation order (first match wins)
- `Target_Onboarding_Status__c`: value to write on onboarding
- `Target_Opportunity_Stage__c`: optional opportunity stage update
- `Is_Active__c`: whether the rule is active

## Subject model (who must fulfill a requirement)

`Onboarding_Fulfillment_Policy__mdt` controls who needs to complete a requirement:

- `ACCOUNT_ONLY`
- `ALL_CONTACTS`
- `PRINCIPAL_OWNER`
- `PRIMARY_CONTACT_OR_ACCOUNT`

This policy is assigned from the vendor program requirement and copied to onboarding requirement records at runtime.

## How to request a rules change

Use this simple format:

1. Business scenario: what changed.
2. Requirement type(s): Agreement, Contract, Training, etc.
3. Source status(es): exact values from records/integrations.
4. Desired normalized status: one of the standard statuses.
5. Desired onboarding result: target onboarding status (and stage if needed).
6. Priority order: where this rule should run in relation to existing rules.

## Troubleshooting checklist

If onboarding status is not what you expect:

1. Confirm subject records exist and have the expected `Status__c`.
2. Confirm parent requirement status/completed reflects those subjects.
3. Confirm normalization CMDT has an active mapping for that requirement type + status.
4. Confirm evaluation rule is active and ordered correctly (`Rule_Order__c`).
5. Confirm there is no higher-priority rule matching first.

## Guardrails

- Keep normalization values consistent (avoid near-duplicates like `Canceled` vs `Cancelled` unless intentionally mapped).
- Do not change many rule orders at once in production.
- Validate in sandbox with at least one scenario per rule before deployment.
