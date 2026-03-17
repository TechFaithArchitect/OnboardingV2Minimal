# Onboarding Requirement Subject Fulfillment (2026-03-16)

## Goal
Document the first-pass redesign for contact-scoped and account-scoped vendor program requirements without relying on `Onboarding__c` requirement status fields such as background-check fields.

The implemented pattern keeps `Onboarding_Requirement__c` as the business-rules-engine-facing aggregate, and introduces a child runtime object to represent the specific subject that must satisfy the requirement.

## Problem Statement
Some vendor program requirements are satisfied at the account level, while others are satisfied by one or more contacts on the account.

Examples:
- Internal background check where the account passes when the principal owner passes.
- Vendor background check where every contact on the account must pass.
- Driver's license or similar credential where the subject may be an individual contact rather than the account.

The original onboarding requirement model did not distinguish between:
- what the requirement is, and
- who must satisfy it.

## Design Summary
The redesign splits configuration from runtime state:

- `Vendor_Program_Requirement__c` defines the requirement and now carries a `Fulfillment_Policy_Key__c`.
- `Onboarding_Requirement__c` remains the parent aggregate record and stores a copied `Fulfillment_Policy_Key__c` snapshot.
- `Onboarding_Fulfillment_Policy__mdt` defines how subjects should be expanded.
- `Onboarding_Requirement_Subject__c` stores the runtime account/contact subject rows created for each onboarding requirement.

This preserves the current business-rules-engine pattern: the BRE can continue to evaluate the parent `Onboarding_Requirement__c`, while subject-specific logic runs underneath it.

## Metadata Added

### New Object
`Onboarding_Requirement_Subject__c`

Purpose:
- one row per subject that must satisfy an onboarding requirement

Fields added:
- `Onboarding_Requirement__c`
- `Account__c`
- `Contact__c`
- `Requirement_Type__c`
- `Status__c`
- `Role_Snapshot__c`
- `Unique_Key__c`

Validation rule:
- `Require_Exactly_One_Subject`
- enforces that exactly one of `Account__c` or `Contact__c` is populated

### New Fields
Added `Fulfillment_Policy_Key__c` to:
- `Vendor_Program_Requirement__c`
- `Onboarding_Requirement__c`

Purpose:
- correlate a requirement to subject-expansion metadata
- snapshot the VPR policy onto the onboarding requirement at record creation time

### New CMDT
`Onboarding_Fulfillment_Policy__mdt`

Fields:
- `Active__c`
- `Policy_Key__c`
- `Subject_Model__c`

Seed metadata records:
- `ACCOUNT_ONLY`
- `ALL_CONTACTS`
- `PRINCIPAL_OWNER`

## Flow Changes

### Updated Flow
`DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements`

Changes:
- copies `Vendor_Program_Requirement__c.Fulfillment_Policy_Key__c` onto the new `Onboarding_Requirement__c`
- invokes the new subject-expansion subflow after onboarding requirements are created

### New Flow
`DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirement_Subjects`

Responsibilities:
- query onboarding requirements for the onboarding record
- look up the fulfillment policy from `Onboarding_Fulfillment_Policy__mdt`
- create account or contact subject rows based on the policy

Supported subject models in the first pass:
- `Account`
- `AllContacts`
- `PrincipalOwner`

### Additional Flows
`DOMAIN_OmniSObject_SFL_GET_Onboarding_Requirement`

Responsibilities:
- return onboarding requirement rows for an onboarding record
- support direct lookup by `OnboardingRequirementId` for downstream reuse

`DOMAIN_OmniSObject_SFL_GET_Onboarding_Fullfilment_Policy`

Responsibilities:
- return active `Onboarding_Fulfillment_Policy__mdt` rows by one key or a key collection

`DOMAIN_OmniSObject_SFL_GET_Onboarding_Requirement_Subjects`

Responsibilities:
- return all runtime subject rows for a given `Onboarding_Requirement__c`

`DOMAIN_OmniSObject_SFL_EVALUATE_Onboarding_Requirement_Subject`

Responsibilities:
- aggregate child `Onboarding_Requirement_Subject__c.Status__c` values
- recalculate parent `Onboarding_Requirement__c.Status__c`
- set parent `Onboarding_Requirement__c.Completed__c`
- log evaluation faults through the shared fault-handler flow

`BLL_Onboarding_Requirement_Subject_RCD_Logical_Process`

Responsibilities:
- listen for `Onboarding_Requirement_Subject__c.Status__c` changes
- invoke the parent evaluation asynchronously after commit

## Relationship Sourcing Rule
For contact-scoped subject expansion, the implementation intentionally resolves subjects from `AccountContactRelation`, not `Contact`.

Important note:
- the repo and Salesforce API name use `AccountContactRelation`
- when discussing business meaning, this is effectively the account-contact role/relationship row

This matters because the role context, including `Principal Owner`, lives on the relationship record rather than the contact record itself.

Implemented behavior:
- `AllContacts` now queries active, direct `AccountContactRelation` rows for the account
- `PrincipalOwner` now queries active, direct `AccountContactRelation` rows where `Roles` contains `Principal Owner`
- subject rows use `ContactId` from the relationship row for `Onboarding_Requirement_Subject__c.Contact__c`
- `Role_Snapshot__c` is populated from `AccountContactRelation.Roles`

This avoids using raw `Contact` data to infer relationship roles.

## What This First Pass Does Not Yet Do
This implementation now creates the subject rows and performs a first-pass parent aggregation when subject status changes.

It does not yet:
- evaluate real evidence sources such as contract-backed compliance statuses, training assignments, agreements, or credentials against the subject rows
- automatically set `Onboarding_Requirement_Subject__c.Status__c` from those evidence records
- distinguish evidence-specific pass/fail rules beyond the current subject-status rollup

The next layer should include:
- subject-level evidence matching
- subject status recalculation from evidence
- duplicate reconciliation / idempotency rules for `Unique_Key__c`

## Deployment Log
- 2026-03-16: Deployed the initial object, field, CMDT, and flow bundle to `OnboardV2` (`0AfRL00000dMapd0AC`)
- 2026-03-16: Updated subject-expansion flow to source contact-scoped subjects from `AccountContactRelation` rather than `Contact`, and deployed to `OnboardV2` (`0AfRL00000dMxXg0AK`)
- 2026-03-16: Added the first-pass subject aggregation layer with `DOMAIN_OmniSObject_SFL_GET_Onboarding_Requirement_Subjects`, `DOMAIN_OmniSObject_SFL_EVALUATE_Onboarding_Requirement_Subject`, and `BLL_Onboarding_Requirement_Subject_RCD_Logical_Process`, then deployed to `OnboardV2` (`0AfRL00000dNGLl0AO`)
- 2026-03-16: Standardized the reusable getter APIs onto `SFL_GET_*` names, deploying `DOMAIN_OmniSObject_SFL_GET_Onboarding_Fullfilment_Policy`, `DOMAIN_OmniSObject_SFL_GET_Onboarding_Requirement_Subjects`, and `DOMAIN_OmniSObject_SFL_GET_Onboarding_Requirement` to `OnboardV2` (`0AfRL00000dNHRV0A4`) and deactivating the two old `GET_` getter definitions
- 2026-03-16: Removed `DOMAIN_OmniSObject_SFL_ROLLUP_Onboarding_Requirement_From_Subjects` from source in favor of the retained evaluator flow `DOMAIN_OmniSObject_SFL_EVALUATE_Onboarding_Requirement_Subject`, updated `BLL_Onboarding_Requirement_Subject_RCD_Logical_Process` to call the evaluator, validated the cutover (`0AfRL00000dNI930AG`), deployed it (`0AfRL00000dNIAf0AO`), and retired the old rollup flow definition from `OnboardV2`
- 2026-03-16: Deleted the two old legacy `GET_` getter flow definitions from `OnboardV2` after their obsolete dependent flows and historical versions were removed

## Practical Usage
To configure a vendor program requirement:

1. Set `Vendor_Program_Requirement__c.Fulfillment_Policy_Key__c`.
2. Use one of the supported keys:
   - `ACCOUNT_ONLY`
   - `ALL_CONTACTS`
   - `PRINCIPAL_OWNER`
3. Let onboarding requirement creation expand the runtime subject rows automatically.

## Recommended Next Step
Build the remaining evidence evaluator layer so real evidence sources such as contract-backed compliance statuses, training assignments, agreements, and credentials update `Onboarding_Requirement_Subject__c.Status__c` automatically; the parent `Onboarding_Requirement__c` rollup layer is now in place.
