# Data Model

## Core Domain Objects

| Object | Role |
|---|---|
| `Onboarding__c` | Central onboarding process record for account/vendor program |
| `Onboarding_Requirement__c` | Requirement row under onboarding |
| `Onboarding_Requirement_Subject__c` | Subject responsibility row under requirement |
| `Vendor_Program_Requirement__c` | Program requirement template |
| `Vendor_Program_Training_Requirement__c` | Program training requirement template |
| `Training_Assignment__c` | Contact-level training assignment |
| `Training_Assignment_Onboarding__c` | Junction between assignment and onboarding |
| `POE_External_Contact_Credential__c` | External credential evidence for contact |

## Primary Relationships

### Onboarding Graph

- `Onboarding__c.Account__c` -> `Account` (Master-Detail)
- `Onboarding__c.Opportunity__c` -> `Opportunity`
- `Onboarding__c.Contract__c` -> `Contract`
- `Onboarding__c.Vendor_Customization__c` -> `Vendor_Customization__c`

### Requirement Graph

- `Onboarding_Requirement__c.Onboarding__c` -> `Onboarding__c` (Master-Detail)
- `Onboarding_Requirement__c.Vendor_Program_Requirement__c` -> `Vendor_Program_Requirement__c`

### Subject Graph

- `Onboarding_Requirement_Subject__c.Onboarding_Requirement__c` -> `Onboarding_Requirement__c` (Master-Detail)
- `Onboarding_Requirement_Subject__c.Account__c` -> `Account`
- `Onboarding_Requirement_Subject__c.Contact__c` -> `Contact`

### Training Graph

- `Training_Assignment__c.Contact__c` -> `Contact`
- `Training_Assignment__c.Onboarding__c` -> `Onboarding__c`
- `Training_Assignment_Onboarding__c.Training_Assignment__c` -> `Training_Assignment__c`
- `Training_Assignment_Onboarding__c.Onboarding__c` -> `Onboarding__c`

This supports many-to-many linking between assignments and onboarding records.

## Subject Responsibility Model

Subject expansion is policy-driven by `Onboarding_Fulfillment_Policy__mdt`:

- `ACCOUNT_ONLY`
- `ALL_CONTACTS`
- `PRINCIPAL_OWNER`
- `PRIMARY_CONTACT_OR_ACCOUNT`

If responsibility is not explicitly specialized, the modeled default path is `PRIMARY_CONTACT_OR_ACCOUNT`.

## Status Model

- Subject status lives on `Onboarding_Requirement_Subject__c.Status__c`
- Parent requirement status/complete state lives on `Onboarding_Requirement__c.Status__c` and `Completed__c`
- Overall lifecycle lives on `Onboarding__c.Onboarding_Status__c`

Status transitions are normalized and evaluated through CMDT-driven logic, not hardcoded flow-only mappings.

## Evidence Sources (Current)

- `Training_Assignment__c`
- `Contract` and agreement signals
- `POE_External_Contact_Credential__c`

Evidence updates drive subject-level updates first, then parent and onboarding roll-up.
