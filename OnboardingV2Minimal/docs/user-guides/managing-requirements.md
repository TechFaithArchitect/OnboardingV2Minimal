# Managing Requirements

This guide explains how to view, update, and manage onboarding requirements.

## Overview

Requirements are individual items that must be completed as part of the onboarding process. Each requirement has a status that tracks its completion state. The system automatically evaluates all requirements to determine the overall onboarding status.

See [User Journey Summary](./user-journey-summary.md) for the end-to-end flow.

## Accessing Requirements

### From an Onboarding Record

1. Navigate to the **Onboarding** record
2. Find the **Requirements Panel** component on the record page
3. The panel displays all requirements for this onboarding

### Requirements Panel Features

- **List View**: All requirements displayed in a table
- **Status Dropdown**: Change status for each requirement
- **Submit Button**: Save all changes and trigger status evaluation

## Understanding Requirement Statuses

### Available Statuses

- **Not Started**: Requirement has not been initiated
- **Incomplete**: Work has started but not finished
- **Complete**: Requirement is fully completed
- **Approved**: Requirement has been reviewed and approved
- **Denied**: Requirement was rejected or denied

### Status Progression

Typical flow:
1. **Not Started** → **Incomplete** → **Complete** → **Approved**

Alternative flows:
- **Not Started** → **Denied** (if requirement is not applicable)
- **Complete** → **Denied** (if work doesn't meet standards)

## Updating Requirement Status

### Single Requirement Update

1. Find the requirement in the Requirements Panel
2. Click the **Status** dropdown for that requirement
3. Select the new status
4. Click **Submit** to save

### Multiple Requirement Updates

1. Update status for multiple requirements
2. All changes are tracked locally
3. Click **Submit** once to save all changes
4. The system processes all updates together

### After Submitting

1. Changes are saved to the database
2. Status rules are automatically evaluated
3. Onboarding status may update automatically
4. A confirmation message appears

## Status Rules Evaluation

### Automatic Evaluation

When you submit requirement updates:
1. System checks all requirement statuses
2. Evaluates configured status rules
3. Updates onboarding status if rules match
4. Updates occur automatically - no manual intervention needed

### Rule Types

- **ALL Rules**: All specified requirements must meet criteria
- **ANY Rules**: At least one requirement must meet criteria
- **CUSTOM Rules**: Complex logic using custom expressions

See [Configuring Rules](./configuring-rules.md) for more details.

## Viewing Requirement Details

### Requirement Information

Each requirement shows:
- **Name**: Requirement identifier
- **Status**: Current completion status
- **Last Updated**: When status was last changed

### Related Records

- Requirements link to **Vendor Program Requirements**
- Requirements are associated with **Onboarding** records
- Status changes are logged in the system

## Common Tasks

### Task 1: Marking Requirements Complete

1. Navigate to Onboarding record
2. Find requirement in Requirements Panel
3. Change status to **Complete**
4. Click **Submit**
5. Verify status updated successfully

### Task 2: Approving Multiple Requirements

1. Navigate to Onboarding record
2. Update multiple requirements to **Approved**
3. Click **Submit** once
4. System evaluates and updates onboarding status

### Task 3: Reviewing Requirement Status

1. Open Onboarding record
2. View Requirements Panel
3. Review all requirement statuses
4. Identify any incomplete requirements
5. Update as needed

### Task 4: Handling Denied Requirements

1. If a requirement is denied:
   - Review the reason (if documented)
   - Update related records if needed
   - Re-submit when ready
2. Change status back to **Incomplete** or **Not Started**
3. Complete the work again
4. Update to **Complete** or **Approved**

## Best Practices

1. **Update Regularly**: Keep requirement statuses current
2. **Submit Together**: Update multiple requirements before submitting
3. **Verify Status**: Check onboarding status after submitting
4. **Document Denials**: If denying, document the reason
5. **Complete Before Approving**: Ensure work is complete before approval

## Troubleshooting

### Issue: Status Not Updating

**Solution**:
- Ensure you clicked **Submit**
- Check for error messages
- Verify you have edit permissions
- Refresh the page and try again

### Issue: Onboarding Status Not Changing

**Solution**:
- Check that requirement statuses match rule criteria
- Verify status rules are configured correctly
- Review rule evaluation logic
- Contact administrator if rules need adjustment

### Issue: Can't See Requirements Panel

**Solution**:
- Verify you're on the Onboarding record (not Vendor Program)
- Check that component is added to the page layout
- Contact administrator to add component if missing
- Verify you have read permissions

## Related Documentation

- [Getting Started](./getting-started.md)
- [Onboarding Workflow](./onboarding-workflow.md)
- [Configuring Rules](./configuring-rules.md)
- [Troubleshooting](./troubleshooting.md)
- [Status Evaluation](../processes/status-evaluation.md)

