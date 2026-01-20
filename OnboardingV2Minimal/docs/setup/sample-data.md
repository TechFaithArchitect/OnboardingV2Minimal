# Sample Data Setup Guide

This guide explains how to set up sample data for testing and demonstrations of the Onboarding V2 system.

## Overview

Sample data scripts help you quickly create test data without manual entry. These scripts create:

- Onboarding processes with stages
- Vendor programs with groups
- Status rules with different evaluation logic types

## Prerequisites

Before running sample data scripts, ensure:

1. **Salesforce Org Access**: You have access to Developer Console or Salesforce CLI
2. **Permissions**: You have create/edit permissions for custom objects
3. **Data Model**: Custom objects are deployed and configured
4. **Account Record**: At least one Account record exists (for vendor program script)

## Available Scripts

### 1. seed-onboarding-process.apex

Creates a complete onboarding process with 7 stages.

**What it creates**:
- 8 Component Library entries
- 1 Onboarding Application Process
- 7 Onboarding Application Stages (linked sequentially)

**Usage**:
```bash
# Via CLI
sf apex run --file scripts/sample-data/seed-onboarding-process.apex

# Or in Developer Console
# Debug > Open Execute Anonymous Window > Paste script > Execute
```

**Output**:
- Process ID and name
- Number of stages created
- Component library entries

### 2. seed-vendor-program.apex

Creates a vendor program with associated groups.

**What it creates**:
- 1 Account (if doesn't exist)
- 1 Vendor__c record
- 1 Vendor Program Group
- 1 Vendor Program Requirement Group
- 1 Vendor Customization (Vendor Program)
- 1 Vendor Program Group Member
- Links to onboarding process (if exists)

**Usage**:
```bash
sf apex run --file scripts/sample-data/seed-vendor-program.apex
```

**Output**:
- Vendor Account ID
- Vendor ID
- Vendor Program ID
- Group IDs

### 3. seed-status-rules.apex

Creates status rules with all three evaluation logic types.

**What it creates**:
- 1 Vendor Program Group (if doesn't exist)
- 1 Requirement Group (if doesn't exist)
- 3 Vendor Program Requirements (if don't exist)
- 3 Rules Engines (ALL, ANY, CUSTOM logic)
- 7 Status Rules (conditions for the engines)

**Usage**:
```bash
sf apex run --file scripts/sample-data/seed-status-rules.apex
```

**Output**:
- Rules Engine IDs
- Number of rules created
- Rule configuration details

## Running Scripts

### Option 1: Salesforce CLI

1. **Authenticate**:
   ```bash
   sf org login web --alias myorg
   ```

2. **Run Script**:
   ```bash
   sf apex run --file scripts/sample-data/seed-onboarding-process.apex
   ```

3. **View Results**:
   - Check command output
   - Review debug logs if errors occur

### Option 2: Developer Console

1. **Open Developer Console**:
   - Setup > Developer Console
   - Or use keyboard shortcut

2. **Execute Anonymous**:
   - Debug > Open Execute Anonymous Window
   - Paste script content
   - Check "Open Log" checkbox
   - Click Execute

3. **Review Results**:
   - Check Debug Log for output
   - Look for System.debug statements
   - Verify no errors occurred

### Option 3: VS Code with Salesforce Extensions

1. **Open Script File**:
   - Open `.apex` file in VS Code

2. **Execute**:
   - Right-click > "SFDX: Execute Anonymous Apex"
   - Or use Command Palette

3. **View Output**:
   - Check Output panel
   - Review debug logs

## Execution Order

For a complete setup, run scripts in this order:

1. **First**: `seed-onboarding-process.apex`
   - Creates the process structure
   - Needed for linking vendor programs

2. **Second**: `seed-vendor-program.apex`
   - Creates vendor program
   - Links to onboarding process
   - Creates groups

3. **Third**: `seed-status-rules.apex`
   - Creates status rules
   - Requires groups from step 2
   - Creates requirements if needed

## Verifying Setup

### Check Onboarding Process

```soql
SELECT Id, Name, Active__c, 
       (SELECT Id, Name, Display_Order__c, Label__c 
        FROM Onboarding_Application_Stages__r 
        ORDER BY Display_Order__c)
FROM Onboarding_Application_Process__c
WHERE Name = 'Standard Vendor Onboarding Process'
```

### Check Vendor Program

```soql
SELECT Id, Name, Vendor__c, 
       Vendor_Program_Group__c, 
       Vendor_Program_Requirement_Group__c
FROM Vendor_Customization__c
WHERE Name = 'Sample Vendor Program'
```

### Check Status Rules

```soql
SELECT Id, Name, Evaluation_Logic__c, Target_Onboarding_Status__c,
       (SELECT Id, Rule_Number__c, Expected_Status__c 
        FROM Onboarding_Status_Rules__r 
        ORDER BY Rule_Number__c)
FROM Onboarding_Status_Rules_Engine__c
WHERE Vendor_Program_Group__r.Name = 'Sample Program Group'
```

## Customizing Scripts

### Modifying Process Stages

Edit `seed-onboarding-process.apex`:
- Add/remove component library entries
- Change stage order
- Modify stage labels
- Add/remove stages

### Modifying Vendor Programs

Edit `seed-vendor-program.apex`:
- Change account/vendor names
- Modify group configurations
- Add additional group members
- Link to different processes

### Modifying Status Rules

Edit `seed-status-rules.apex`:
- Change evaluation logic
- Modify target statuses
- Add/remove rule conditions
- Change custom expressions

## Troubleshooting

### Error: "List has no rows"

**Cause**: Required records don't exist

**Solution**:
- Run scripts in correct order
- Check prerequisites are met
- Verify custom objects are deployed

### Error: "Required field is missing"

**Cause**: Required fields not populated

**Solution**:
- Review script for all required fields
- Check field-level security
- Verify picklist values are correct

### Error: "Insufficient access"

**Cause**: Missing permissions

**Solution**:
- Check object permissions
- Verify field-level security
- Contact administrator for access

### Script Runs But No Data Created

**Cause**: Silent failures or validation rules

**Solution**:
- Check debug logs for errors
- Review validation rules
- Verify required relationships exist

## Cleaning Up Sample Data

To remove sample data:

```apex
// Delete in reverse order of creation
delete [SELECT Id FROM Onboarding_Status_Rule__c WHERE Parent_Rule__r.Name LIKE 'Sample%'];
delete [SELECT Id FROM Onboarding_Status_Rules_Engine__c WHERE Name LIKE 'Sample%'];
delete [SELECT Id FROM Vendor_Program_Group_Member__c WHERE Name = 'Sample Group Member'];
delete [SELECT Id FROM Vendor_Customization__c WHERE Name = 'Sample Vendor Program'];
delete [SELECT Id FROM Vendor_Program_Requirement_Group__c WHERE Name = 'Sample Requirement Group'];
delete [SELECT Id FROM Vendor_Program_Group__c WHERE Name = 'Sample Program Group'];
delete [SELECT Id FROM Onboarding_Application_Stage__c WHERE Onboarding_Application_Process__r.Name = 'Standard Vendor Onboarding Process'];
delete [SELECT Id FROM Onboarding_Application_Process__c WHERE Name = 'Standard Vendor Onboarding Process'];
delete [SELECT Id FROM Onboarding_Component_Library__c WHERE Name LIKE 'Vendor%' OR Name LIKE 'Required%' OR Name LIKE 'Training%'];
```

## Best Practices

1. **Use Sandbox**: Always test scripts in sandbox first
2. **Backup Data**: Export existing data before running scripts
3. **Review Output**: Check debug logs for confirmation
4. **Verify Results**: Query records to confirm creation
5. **Clean Up**: Remove test data when done

## Related Documentation

- [Installation Guide](./installation.md)
- [Configuration Guide](./configuration.md)
- [Getting Started](../user-guides/getting-started.md)

