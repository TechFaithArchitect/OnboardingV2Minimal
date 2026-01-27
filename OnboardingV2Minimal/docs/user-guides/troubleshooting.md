# Troubleshooting Guide

This guide covers common issues in the MVP onboarding experience.

## Common Issues and Solutions

### Onboarding UI Not Appearing

**Symptoms**:
- `onboardingHomeDashboard` shows a blank area
- `accountProgramOnboardingModal` does not render
- LWC error on the record page

**Solutions**:
1. Verify the Lightning page includes the correct component.
2. Confirm you have access to the Account and Onboarding records.
3. Check browser console logs for LWC errors.
4. Clear cache and retry.

### Requirements Panel Not Loading

**Symptoms**:
- Panel spins indefinitely
- No requirements displayed

**Solutions**:
1. Confirm you are on an `Onboarding__c` record.
2. Ensure `Onboarding_Requirement__c` records exist for the onboarding.
3. Verify access to `Onboarding__c` and `Onboarding_Requirement__c` fields.
4. Check Apex logs for `OnboardingRequirementsPanelController.getRequirements`.

### Status Not Updating Automatically

**Symptoms**:
- Requirements updated but onboarding status unchanged

**Solutions**:
1. Confirm the status rules engine is active and linked to the program group.
2. Verify requirement statuses match the rule expectations.
3. Ensure the status update flow (`Onboarding_Record_Trigger_Update_Onboarding_Status`) is active.
4. Re-save a requirement to trigger evaluation and check logs for rule errors.

### Permission Denied

**Symptoms**:
- Errors about missing access

**Solutions**:
1. Check permission sets for `Onboarding__c`, `Onboarding_Requirement__c`, and `Vendor_Customization__c`.
2. Confirm field-level security for status fields.

### Data Issues

#### Missing Requirements
**Cause**: Requirements were not created during onboarding.

**Fix**:
- Verify `Vendor_Program_Requirement__c` records exist and are active.
- Re-run the onboarding creation step.

#### Duplicate Requirements
**Cause**: Multiple requirement records for the same program requirement.

**Fix**:
- Review requirement creation logic.
- Remove duplicates and re-run onboarding creation.

#### Incorrect Status Values
**Cause**: Requirement status picklist values don'''t align with rule expectations.

**Fix**:
- Update rule expectations or picklist values so they match.

## Getting Additional Help

If you still can'''t resolve the issue, capture:
- Record IDs
- Steps to reproduce
- Any Apex error messages

Then share with the onboarding admin or engineering team.
