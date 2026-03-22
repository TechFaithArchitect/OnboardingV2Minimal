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

## Verifying Setup

### Vendor Program

```soql
SELECT Id, Name, Vendor__c, Vendor_Program_Group__c
FROM Vendor_Customization__c
WHERE Name = 'Sample Vendor Program'
```

### Status Normalization Rules

```soql
SELECT Id, DeveloperName, Requirement_Type__c, Status__c, Normalized_Status__c
FROM Onboarding_Status_Normalization__mdt
WHERE Active__c = true
```
