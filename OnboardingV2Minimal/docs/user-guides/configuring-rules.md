# Configuring Status Rules

This guide explains how to configure status rules that automatically evaluate and update onboarding status based on requirement completion.

## Overview

Status rules define conditions that, when met, automatically update the onboarding status. Rules are evaluated whenever requirement statuses change, ensuring the onboarding status always reflects current completion state.

See [User Journey Summary](./user-journey-summary.md) for the end-to-end flow.

## Understanding Status Rules

### Rule Components

1. **Rules Engine**: Container for multiple rules with evaluation logic
2. **Rules**: Individual conditions that check requirement statuses
3. **Evaluation Logic**: How rules are combined (ALL, ANY, CUSTOM)
4. **Target Status**: The status to set when rules pass

### Rule Structure

- **Vendor Program Group**: Links rules to specific vendor program groups
- **Requirement Group**: Links rules to specific requirement groups
- **Target Status**: Status to apply when rule conditions are met
- **Evaluation Logic**: How to combine rule conditions
- **Override Status**: Force the target status without evaluating requirements

## Accessing Rules Configuration

### From Status Rules Engine Component

1. Navigate to the page containing the **Status Rules Engine** component
2. Select a **Vendor Program Group**
3. Select a **Requirement Group**
4. Click **Load Rules** to view existing rules

### From Custom Objects

1. Navigate to **Onboarding Status Rules Engine** tab
2. Create or edit rules engine records
3. Navigate to **Onboarding Status Rule** tab
4. Create or edit individual rule conditions

## Creating a Rules Engine

### Step 1: Create Rules Engine Record

1. Go to **Onboarding Status Rules Engine** tab
2. Click **New**
3. Fill in required fields:
   - **Name**: Descriptive name (e.g., "Approval Rules for Standard Programs")
   - **Vendor Program Group**: Select the program group
   - **Requirement Group**: Select the requirement group
   - **Target Onboarding Status**: Status to set (e.g., "Approved")
   - **Override Status** (optional): Force the target status without evaluating requirements
   - **Rule Evaluation Order** (optional): Sequence for evaluation within the program group
   - **Evaluation Logic**: Choose ALL, ANY, or CUSTOM
4. Click **Save**

### Step 2: Create Rule Conditions

1. Go to **Onboarding Status Rule** tab
2. Click **New**
3. Fill in required fields:
   - **Name**: Rule name (e.g., "Requirement 1 Complete")
   - **Parent Rule**: Select the rules engine created in Step 1
   - **Requirement**: Select the requirement to check
   - **Expected Status**: Status that must be met (e.g., "Complete")
   - **Rule Number**: Order number (1, 2, 3, etc.)
4. Click **Save**
5. Repeat for each condition

## Evaluation Logic Types

## Override Status (Force)

Use **Override Status** on a rules engine to force the Target Status without evaluating requirements.
This should be reserved for exceptional cases where a Dealer should pass even when criteria are not met.

### ALL Logic (AND)

**Use Case**: All requirements must be complete

**Example**:
- Rule 1: Requirement A = "Complete"
- Rule 2: Requirement B = "Complete"
- Rule 3: Requirement C = "Approved"
- **Result**: All three must be true for rule to pass

**When to Use**: When every requirement must be satisfied

### ANY Logic (OR)

**Use Case**: At least one requirement must be complete

**Example**:
- Rule 1: Requirement A = "Complete"
- Rule 2: Requirement B = "Incomplete"
- Rule 3: Requirement C = "Not Started"
- **Result**: Rule passes if ANY one is true

**When to Use**: When multiple paths can lead to completion

### CUSTOM Logic (Expression)

**Use Case**: Complex combinations of requirements

**Expression Syntax**:
- Use rule numbers: `1`, `2`, `3`, etc.
- Operators: `AND`, `OR`
- Grouping: `(1 AND 2) OR 3`

**Examples**:
```
"1 AND 2"                    # Rules 1 AND 2 must pass
"1 OR 2"                     # Rule 1 OR Rule 2 must pass
"(1 AND 2) OR 3"             # (Rule 1 AND Rule 2) OR Rule 3
"1 AND (2 OR 3)"             # Rule 1 AND (Rule 2 OR Rule 3)
```

**When to Use**: For complex business logic that doesn't fit ALL or ANY

## Configuring Rules via UI

### Using Status Rules Engine Component

1. **Select Groups**:
   - Choose Vendor Program Group
   - Choose Requirement Group
   - Click **Load Rules**

2. **View Rules**:
   - Rules appear in a data table
   - Each row represents a rules engine
   - Shows evaluation logic and target status

3. **Edit Rules**:
   - Click in editable cells
   - Modify values directly
   - Click **Save** to persist changes

4. **Add New Rules**:
   - Create rules engine record first
   - Then create rule conditions
   - Reload to see new rules

## Rule Configuration Examples

### Example 1: Simple Approval Rule

**Scenario**: Set status to "Approved" when all requirements are complete

**Configuration**:
- Rules Engine:
  - Target Status: "Approved"
  - Evaluation Logic: "ALL"
- Rules:
  - Rule 1: Requirement A = "Complete"
  - Rule 2: Requirement B = "Complete"
  - Rule 3: Requirement C = "Complete"

### Example 2: Flexible Completion Rule

**Scenario**: Set status to "In Process" when any requirement is complete

**Configuration**:
- Rules Engine:
  - Target Status: "In Process"
  - Evaluation Logic: "ANY"
- Rules:
  - Rule 1: Requirement A = "Complete"
  - Rule 2: Requirement B = "Complete"
  - Rule 3: Requirement C = "Incomplete"

### Example 3: Complex Custom Rule

**Scenario**: Set status to "Ready for Review" when (Requirement A AND Requirement B) OR Requirement C is complete

**Configuration**:
- Rules Engine:
  - Target Status: "Ready for Review"
  - Evaluation Logic: "CUSTOM"
  - Custom Expression: "(1 AND 2) OR 3"
- Rules:
  - Rule 1: Requirement A = "Complete"
  - Rule 2: Requirement B = "Complete"
  - Rule 3: Requirement C = "Complete"

## Testing Rules

### Manual Testing

1. Create test onboarding record
2. Update requirement statuses to match rule conditions
3. Submit requirement updates
4. Verify onboarding status updates correctly
5. Test edge cases (partial matches, no matches)

### Verification Checklist

- [ ] Rules engine is active
- [ ] Rule conditions are correctly configured
- [ ] Evaluation logic matches requirements
- [ ] Target status is correct
- [ ] Rules are linked to correct groups
- [ ] Test with actual requirement updates

## Best Practices

1. **Clear Naming**: Use descriptive names for rules engines and rules
2. **Logical Ordering**: Number rules logically (1, 2, 3...)
3. **Test Thoroughly**: Test rules with various requirement combinations
4. **Document Logic**: Add descriptions explaining rule purpose
5. **Start Simple**: Begin with ALL or ANY before using CUSTOM
6. **One Target Per Group**: Avoid multiple rules engines with same target for same groups

## Troubleshooting

### Issue: Rules Not Evaluating

**Solutions**:
- Verify rules engine is active
- Check that requirement groups match
- Ensure vendor program groups match
- Verify rule conditions are correct
- Check that requirements exist and are linked

### Issue: Wrong Status Applied

**Solutions**:
- Review evaluation logic (ALL vs ANY vs CUSTOM)
- Check rule conditions match actual requirement statuses
- Verify target status is correct
- Test with different requirement combinations
- Review custom expression syntax if using CUSTOM

### Issue: Rules Not Appearing

**Solutions**:
- Verify groups are selected correctly
- Check that rules engines exist for selected groups
- Ensure you have read permissions
- Try refreshing the component
- Check that rules are not filtered out

## Related Documentation

- [Getting Started](./getting-started.md)
- [Managing Requirements](./managing-requirements.md)
- [Status Evaluation](../processes/status-evaluation.md)
- [Configuration Guide](../setup/configuration.md)

