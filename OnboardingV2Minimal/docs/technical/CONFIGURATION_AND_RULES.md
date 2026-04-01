# Configuration and Rules

## If You Are New To This File

Most behavior is controlled by metadata, not hardcoded logic.

Remember these three quick mappings:

- Fulfillment policy metadata = who a requirement is assigned to.
- Status metadata = how requirement evidence becomes onboarding status.
- Communication metadata = when to send and to whom.

## Configuration Philosophy

Business behavior is intentionally metadata-driven where practical, so policy changes can occur without deploying new Apex or redesigning core flows.

## Key Custom Metadata Types

| CMDT | Purpose |
|---|---|
| `Onboarding_Fulfillment_Policy__mdt` | Defines requirement subject expansion model |
| `Onboarding_Status_Normalization__mdt` | Maps raw evidence statuses to normalized statuses |
| `Onboarding_Status_Evaluation_Rule__mdt` | Ordered onboarding status rules and targets |
| `Onboarding_Next_Step_Rule__mdt` | Next-step action derivation by field/operator/value |
| `Onboarding_Performance_Config__mdt` | Async/defer behavior toggles |
| `Onboarding_Logging_Config__mdt` | Logging enablement, minimum level, PII redaction |
| `Communication_Dispatch_Policy__mdt` | Recipient dispatch policy by context |
| `Communication_Event_Policy__mdt` | Event-to-template policy routing |

## Fulfillment Policies in Source

`Onboarding_Fulfillment_Policy__mdt` active policies:

- `ACCOUNT_ONLY` -> `Account`
- `ALL_CONTACTS` -> `AllContacts`
- `PRINCIPAL_OWNER` -> `PrincipalOwner`
- `PRIMARY_CONTACT_OR_ACCOUNT` -> `PrimaryContactOrAccount`

## Onboarding Status Rule Order

Current `Onboarding_Status_Evaluation_Rule__mdt` ordering and targets:

1. `ANY_DENIED` -> `Denied` (also sets Opportunity Stage `Denied`)
2. `OPPORTUNITY_CANCELED` -> `Canceled`
3. `ANY_CANCELED` -> `Canceled`
4. `ANY_EXPIRED` -> `Expired`
5. `ALL_SETUP_COMPLETE` -> `Setup Complete`
6. `ONLY_AGREEMENT_OUT_FOR_SIGNATURE` -> `Paperwork Sent`
7. `ONLY_AGREEMENT_SIGNED` -> `Pending Initial Review`
8. `AGREEMENT_SIGNED_AND_CONTRACT_COMPLETE` -> `In Process`
9. `PENDING_SALES` -> `Pending Sales`
10. `IN_PROCESS_DEFAULT` -> `In Process`

Rules are evaluated top-down. First match wins.

## Normalization Layer

`OnboardingStatusNormalizationService` builds a map from:

- `Requirement_Type__c + raw Status__c` -> `Normalized_Status__c`

This standardizes mixed evidence values before rule evaluation.

## Contract Evidence Policy

- Contract-related requirement evaluation should be driven by contract evidence status paths (contract status and linked requirement normalization).
- Legacy contact application-status based logic is not part of the modern policy baseline.

## Predicate Engine

`OnboardingStatusPredicateInterpreter` evaluates JSON predicates in `Predicate_Config__c`, including:

- logical composition (`all`, `any`)
- normalized status checks
- terminal completion checks
- stage-gated cancellation behavior
- agreement/contract composite predicates
- assigned-team and opportunity-stage predicates

## Performance and Logging Defaults

From source defaults:

- `Defer_Onboarding_Tail__c = true`
- `Publish_Chain_Progress_Events__c = true`
- `Logging enabled = true`
- `Minimum log level = WARN`
- `PII redaction = true`
