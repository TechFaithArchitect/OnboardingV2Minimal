# Onboarding Opportunity End-to-End Simulation

This simulation validates the core lifecycle from account onboarding start through opportunity and onboarding record creation.

## What It Covers

The simulation executes these runtime steps in an org:

1. Create simulation records:
   - `Account`
   - `Vendor__c`
   - `Vendor_Customization__c` (Vendor Program)
   - `Vendor_Program_Requirement__c`
2. Run `DOMAIN_OmniSObject_SFL_CREATE_Opportunity`
3. Run `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record`
4. Verify:
   - `Opportunity` was created
   - `Onboarding__c` was created and linked correctly
   - `Onboarding_Requirement__c` records were seeded from `Vendor_Program_Requirement__c`
   - `Onboarding__c.Creation_of_Record_Completed__c = true`
5. Emit structured output as `SIMULATION_RESULT_JSON`

## Run It

### Option 1: Runner Script

```bash
scripts/simulation/run-account-onboarding-through-opportunity.sh OnboardV2
```

### Option 2: Make Target

```bash
make simulate-onboarding-opportunity ORG_ALIAS=OnboardV2
```

### Option 3: Direct Apex

```bash
sf apex run --target-org OnboardV2 --file scripts/simulation/account-onboarding-through-opportunity.apex
```

## Pass/Fail Behavior

- The Apex simulation uses hard assertions for critical checkpoints.
- If any critical step fails, the command fails with an assertion error.
- On success, Apex debug output includes:
  - `SIMULATION_RESULT_JSON=...`
  - `SIMULATION_COMPLETE=<runKey>`

## Notes

- The script creates simulation data in the target org; it does not auto-cleanup.
- Prefer running in a sandbox or scratch org.
