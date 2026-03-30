# Glossary

## Core Terms

- **Onboarding Record**: `Onboarding__c`, top-level lifecycle record for an account and vendor program.
- **Onboarding Requirement**: `Onboarding_Requirement__c`, a required milestone under onboarding.
- **Onboarding Requirement Subject**: `Onboarding_Requirement_Subject__c`, responsibility assignment row for a requirement.
- **Fulfillment Policy**: CMDT policy controlling how subjects are expanded for a requirement.
- **Primary Contact**: Primary `OpportunityContactRole` selected for responsibility-sensitive processing.
- **Principal Owner**: Business role used in fulfillment policy for owner-scoped requirements.
- **Normalization**: Mapping raw evidence status to canonical status via `Onboarding_Status_Normalization__mdt`.
- **Evaluation Rule**: Ordered rule in `Onboarding_Status_Evaluation_Rule__mdt` that sets target onboarding status.
- **Deferred Onboarding Tail**: Async queueable execution of onboarding tail work after core record creation.
- **Fault Handler Flow**: Reusable subflow that captures/logs automation failures (`DOMAIN_OmniSObject_SFL_CREATE_Fault_Message`).

## Flow Prefixes

- **EXP**: Experience or user-facing screen flow.
- **BLL**: Business logic and orchestration flow.
- **DOMAIN**: Reusable domain subflow.

## Status Terms

- **Paperwork Sent**: Pre-review state typically tied to agreement out-for-signature conditions.
- **Pending Initial Review**: Agreement signed and contract still in early requirement state.
- **Setup Complete**: Terminal target when applicable requirement set is complete/terminal.
