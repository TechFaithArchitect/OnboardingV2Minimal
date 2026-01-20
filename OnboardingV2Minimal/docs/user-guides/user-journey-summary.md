# User Journey Summary

This summary describes how internal users move a Dealer (Account) through onboarding for a Vendor Program.

## Actors

- Program Specialist (Sales): Starts Dealer onboarding and links a Dealer to a Vendor Program.
- Program Manager: Configures Vendor Program requirements, rules, and stage dependencies.
- Onboarding Manager (Account Services): Works with Dealers to complete requirements and updates requirement statuses.
- Compliance Manager: Updates compliance requirements and effective dates when policies change.
- Finance Manager: Manages agreements and payment structures tied to Vendor Programs.

## Journey (Happy Path)

1. Program Manager configures a Vendor Program, requirement groups, and status rules.
2. Program Specialist initiates Dealer onboarding from the Account quick action.
3. The system creates `Onboarding__c` and seeds `Onboarding_Requirement__c` from vendor program requirements.
4. Onboarding Manager updates requirement statuses as the Dealer completes tasks.
5. The status rules engine evaluates requirements (ALL/ANY/CUSTOM) and updates `Onboarding__c.Onboarding_Status__c`.
6. Onboarding completes when requirements meet the configured rules (for example, status reaches Setup Complete).

## Exceptions and Overrides

- Rules-based override: `Override_Status__c` on a rules engine forces its `Target_Onboarding_Status__c` without evaluating requirements. Engines are evaluated by `Sequence__c`.
- External override: `External_Override_Enabled__c` on `Onboarding__c` stops automated status evaluation. Manual updates are tracked and audited in `Onboarding_External_Override_Log__c`.

## Signals and Outputs

- `Onboarding__c.Onboarding_Status__c` reflects the Dealer's current onboarding state for the Vendor Program.
- `Onboarding_Requirement__c` records show requirement completion progress.
- Override fields and audit logs document exceptions and approvals.
