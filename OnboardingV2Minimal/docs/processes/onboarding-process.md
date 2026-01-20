# Onboarding Process

## Overview

The onboarding process is a metadata-driven workflow that guides users through structured stages to complete vendor program onboarding. The process is fully configurable through Custom Objects and supports progress tracking, auditability, and dynamic component rendering.

See [User Journey Summary](../user-guides/user-journey-summary.md) for the end-to-end flow.

## Process Flow

```
1. User initiates onboarding from Vendor Program record
   ↓
2. System resolves Onboarding_Application_Process__c for Vendor Program
   ↓
3. onboardingFlowEngine or onboardingApplicationFlow loads stages from Onboarding_Application_Stage__c
   ↓
4. For each stage:
   a. onboardingStageRenderer renders stage component using static conditional rendering
   b. User completes stage actions
   c. Stage component fires 'next' event
   d. Progress is upserted to Onboarding_Application_Progress__c (onboardingFlowEngine only)
   e. Stage completion is logged to Onboarding_Application_Stage_Completion__c (onboardingFlowEngine only)
   ↓
5. Process completes when all stages are finished
```

## Stage Components

### 1. Vendor Selection (`vendorProgramOnboardingVendor`)
- Select or create a vendor account
- Validates vendor exists and is active

### 2. Vendor Program Search/Create (`vendorProgramOnboardingVendorProgramSearchOrCreate`)
- Search for existing vendor program
- Option to create new vendor program

### 3. Vendor Program Create (`vendorProgramOnboardingVendorProgramCreate`)
- Create a new vendor program record
- Set program details and configuration

### 4. Vendor Program Group (`vendorProgramOnboardingVendorProgramGroup`)
- Assign a program group to the vendor program
- Links requirements and rules

### 5. Vendor Program Requirement Group (`vendorProgramOnboardingVendorProgramRequirementGroup`)
- Assign requirement groups
- Defines what requirements must be completed

### 6. Vendor Program Recipient Group (`vendorProgramOnboardingVendorProgramRecipientGroup`)
- Assign recipient groups
- Defines who receives onboarding communications

### 7. Recipient Group Configuration (`vendorProgramOnboardingRecipientGroup`)
- Configure recipient group details
- Set group parameters

### 8. Recipient Group Members (`vendorProgramOnboardingRecipientGroupMembers`)
- Add members to recipient group
- Assign contacts to group

### 9. Required Credentials (`vendorProgramOnboardingRequiredCredentials`)
- Configure required credentials
- Set credential requirements

### 10. Training Requirements (`vendorProgramOnboardingTrainingRequirements`)
- Configure training requirements
- Set training assignments

## Progress Tracking

### Onboarding_Application_Progress__c

Tracks the current state of an onboarding process:
- `Current_Stage__c` - Current stage ID
- `Onboarding_Application_Process__c` - Process being executed
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program being onboarded

### Onboarding_Application_Stage_Completion__c

Audit log of completed stages:
- `Completed_Date__c` - Timestamp of completion
- `Completed_By__c` - User who completed the stage
- `Onboarding_Application_Stage__c` - Completed stage

## Resuming Progress

Users can resume onboarding from where they left off:
1. System loads `Onboarding_Application_Progress__c` for the vendor program
2. Finds the `Current_Stage__c` in the stage list
3. Sets `activeStageIndex` to the saved stage
4. User continues from that point

## Configuration

### Creating an Onboarding Process

1. **Create Process**: Create `Onboarding_Application_Process__c` record
   - Set Name and Description
   - Set Active = true

2. **Create Component Library Entries**: Create `Onboarding_Component_Library__c` records
   - Set `Component_API_Name__c` to LWC component API name (e.g., "vendorProgramOnboardingVendor")
   - Set Name and Description

3. **Create Stages**: Create `Onboarding_Application_Stage__c` records
   - Set `Onboarding_Application_Process__c` to process
   - Set `Onboarding_Component_Library__c` to component
   - Set `Display_Order__c` for sequence
   - Set `Label__c` for display
   - Set `Required__c` if stage is mandatory
   - Optionally set `Next_Stage__c` for branching

4. **Assign Process**: Link process to Vendor Program via `Onboarding_Application_Progress__c`

## Branching Logic

Stages can support branching by setting `Next_Stage__c`:
- If `Next_Stage__c` is set, flow advances to that stage
- If not set, flow advances to next stage in `Display_Order__c`
- Allows conditional stage progression

## Event Handling

### Navigation Events

Stage components communicate with the flow engine via custom events:

**Next Event:**ascript
this.dispatchEvent(new CustomEvent('next', { 
  detail: { /* stage-specific data */ } 
}));**Back Event:**ascript
this.dispatchEvent(new CustomEvent('back', { 
  detail: { /* stage-specific data */ } 
}));### Context Passing

Stage components receive context:
{
  vendorProgramId: String,  // Current vendor program ID
  stageId: String          // Current stage ID
}## Error Handling

- **Missing Process**: If no process found, displays error message
- **Missing Stages**: If no stages found, displays error message
- **Component Not Found**: If component API name invalid, logs error
- **Progress Save Failure**: Logs error but allows user to continue

## Best Practices

1. **Stage Independence**: Each stage should be self-contained
2. **Data Validation**: Validate data before firing 'next' event
3. **Progress Persistence**: Always save progress after stage completion
4. **Error Messages**: Provide clear error messages to users
5. **Loading States**: Show loading indicators during async operations

## Related Documentation

- [Application Flow Engine](./application-flow-engine.md)
- [LWC Components](../components/lwc-components.md)
- [Data Model](../architecture/data-model.md)


Back Event:
this.dispatchEvent(new CustomEvent('back', { 
  detail: { /* stage-specific data */ } 
}));em that automatically evaluates and updates onboarding status based on requirement completion. It uses a configurable rules engine that supports multiple evaluation logic types.

## Architecture

Context Passing
Stage components receive context:

{
  vendorProgramId: String,  // Current vendor program ID
  stageId: String          // Current stage ID
}uation logic:

**Key Fields:**
- `Vendor_Program_Group__c` - Associated vendor program group
- `Target_Onboarding_Status__c` - Status to set when rule passes
- `Evaluation_Logic__c` - Logic type: "ALL", "ANY", or "CUSTOM"
- `Custom_Evaluation_Logic__c` - Custom expression (if Evaluation_Logic__c = "CUSTOM")

### Onboarding_Status_Rule__c

Individual rule conditions:

**Key Fields:**
- `Parent_Rule__c` - Parent rules engine
- `Requirement__c` - Requirement to evaluate (Vendor_Program_Requirement__c)
- `Expected_Status__c` - Expected requirement status (e.g., "Complete", "Approved")
- `Rule_Number__c` - Order of evaluation (used in custom expressions)

## Evaluation Logic Types

### ALL (AND Logic)

All rules must pass for the engine to pass.

**Example:**
- Rule 1: Requirement A = "Complete" ✓
- Rule 2: Requirement B = "Complete" ✓
- Rule 3: Requirement C = "Approved" ✓
- **Result**: Rule passes (all conditions met)

### ANY (OR Logic)

At least one rule must pass for the engine to pass.

**Example:**
- Rule 1: Requirement A = "Complete" ✗
- Rule 2: Requirement B = "Complete" ✓
- Rule 3: Requirement C = "Approved" ✗
- **Result**: Rule passes (at least one condition met)

### CUSTOM (Expression Logic)

Uses a custom expression with rule numbers.

**Expression Syntax:**
- Use rule numbers (e.g., "1", "2", "3")
- Operators: `AND`, `OR`
- Parentheses for grouping
- Case-insensitive

**Examples:**
Error Handling
Missing Process: If no process found, displays error message
Missing Stages: If no stages found, displays error message
Component Not Found: If component API name invalid, logs error
Progress Save Failure: Logs error but allows user to continue
Best Practices
Stage Independence: Each stage should be self-contained
Data Validation: Validate data before firing 'next' event
Progress Persistence: Always save progress after stage completion
Error Messages: Provide clear error messages to users
Loading States: Show loading indicators during async operations
