# Sample Data Setup Guide (MVP)

This guide covers sample data scripts that remain relevant for the MVP onboarding flow.

## Available Scripts

### seed-vendor-program.apex

Creates a vendor program with program group membership.

**What it creates**:
- Account (if needed)
- Vendor__c
- Vendor_Customization__c (Vendor Program)
- Vendor_Program_Group__c
- Vendor_Program_Group_Member__c

**Usage**:
```bash
sf apex run --file scripts/sample-data/seed-vendor-program.apex
```

### seed-status-rules.apex

Creates status rules with different evaluation logic types.

**What it creates**:
- Vendor Program Group (if needed)
- Vendor Program Requirements (if needed)
- Onboarding_Status_Rules_Engine__c
- Onboarding_Status_Rule__c

**Usage**:
```bash
sf apex run --file scripts/sample-data/seed-status-rules.apex
```

## Verifying Setup

### Vendor Program

```soql
SELECT Id, Name, Vendor__c, Vendor_Program_Group__c
FROM Vendor_Customization__c
WHERE Name = 'Sample Vendor Program'
```

### Status Rules

```soql
SELECT Id, Name, Evaluation_Logic__c, Target_Onboarding_Status__c,
       (SELECT Id, Rule_Number__c, Expected_Status__c
        FROM Onboarding_Status_Rules__r
        ORDER BY Rule_Number__c)
FROM Onboarding_Status_Rules_Engine__c
WHERE Vendor_Program_Group__r.Name = 'Sample Program Group'
```
