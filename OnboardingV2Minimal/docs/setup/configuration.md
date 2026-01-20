
## 13. Create docs/setup/configuration.md

Create `docs/setup/configuration.md`:
rkdown
# Configuration Guide

## Overview

This guide covers configuration of the onboarding system, including process setup, rules configuration, and component setup.

## Onboarding Process Configuration

### Step 1: Create Component Library Entries

For each LWC component used in stages:

1. Navigate to `Onboarding Component Library` tab
2. Create new record:
   - **Name**: Descriptive name (e.g., "Vendor Selection")
   - **Component API Name**: LWC component API name (e.g., "vendorProgramOnboardingVendor")
   - **Description**: Component description

**Available Components:**
- `vendorProgramOnboardingVendor`
- `vendorProgramOnboardingVendorProgramSearchOrCreate`
- `vendorProgramOnboardingVendorProgramCreate`
- `vendorProgramOnboardingVendorProgramGroup`
- `vendorProgramOnboardingVendorProgramRequirementGroup`
- `vendorProgramOnboardingVendorProgramRecipientGroup`
- `vendorProgramOnboardingRecipientGroup`
- `vendorProgramOnboardingRecipientGroupMembers`
- `vendorProgramOnboardingRequiredCredentials`
- `vendorProgramOnboardingTrainingRequirements`

### Step 2: Create Onboarding Process

1. Navigate to `Onboarding Application Process` tab
2. Create new record:
   - **Name**: Process name (e.g., "Standard Vendor Onboarding")
   - **Description**: Process description
   - **Active**: Checked

### Step 3: Create Stages

1. Navigate to `Onboarding Application Stage` tab
2. For each stage, create record:
   - **Onboarding Application Process**: Select process
   - **Onboarding Component Library**: Select component
   - **Display Order**: Sequential number (1, 2, 3, ...)
   - **Label**: Display label (e.g., "Select Vendor")
   - **Required**: Check if stage is mandatory
   - **Next Stage**: (Optional) For branching logic

**Example Stage Configuration:**
1. Stage 1: Vendor Selection (Order: 1)
2. Stage 2: Program Search/Create (Order: 2)
3. Stage 3: Program Group Assignment (Order: 3)
4. Stage 4: Requirement Group Assignment (Order: 4)
5. Stage 5: Recipient Group Assignment (Order: 5)
6. Stage 6: Recipient Group Configuration (Order: 6)
7. Stage 7: Add Members (Order: 7)
8. Stage 8: Required Credentials (Order: 8)
9. Stage 9: Training Requirements (Order: 9)

### Step 4: Assign Process to Vendor Program

1. Navigate to Vendor Program record
2. Create `Onboarding Application Progress` record:
   - **Onboarding Application Process**: Select process
   - **Vendor Program**: Current vendor program
   - **Current Stage**: (Leave blank initially)

## Status Rules Configuration

### Step 1: Create Vendor Program Groups

1. Navigate to `Vendor Program Group` tab
2. Create group:
   - **Name**: Group name
   - **Vendor Program**: Select program
   - **Active**: Checked

### Step 2: Create Rules Engine

1. Navigate to `Onboarding Status Rules Engine` tab
2. Create engine:
   - **Name**: Engine name
   - **Vendor Program Group**: Select group
   - **Target Onboarding Status**: Status to set (e.g., "Ready for Review")
   - **Evaluation Logic**: Select (ALL, ANY, or CUSTOM)
   - **Custom Evaluation Logic**: (If CUSTOM) Enter expression

**Evaluation Logic Options:**
- **ALL**: All rules must pass
- **ANY**: At least one rule must pass
- **CUSTOM**: Use custom expression

### Step 3: Create Rules

1. Navigate to `Onboarding Status Rule` tab
2. For each rule condition, create record:
   - **Parent Rule**: Select rules engine
   - **Requirement**: Select Vendor Program Requirement
   - **Expected Status**: Expected status (e.g., "Complete", "Approved")
   - **Rule Number**: Sequential number (1, 2, 3, ...)

**Example Rule Configuration:**
- Rule 1: Background Check = "Complete"
- Rule 2: Business License = "Approved"
- Rule 3: Credit Check = "Complete"
- Rule 4: Compliance = "Approved"

**Custom Expression Example:**
1. Application Layer Onboarding_c record changes
↓
Application Layer Flow
Onboarding_Record_Trigger_Update_Onboarding_Status
↓
Business Logic Layer
OnboardingStatusEvaluator.evaluateAndApplyStatus()
↓
Business Logic Layer
OnboardingRulesService.getRulesForGroups()
↓
Business Logic Layer
OnboardingRuleEvaluator.evaluateRule()
↓
Domain Layer (if needed)
Data queries via SOQL
↓
Business Logic Layer
Update Onboardingc.Onboarding_Status_c


### Example: Onboarding Flow
Application Layer
User navigates to Vendor Program record page
↓
Application Layer Component
vendorProgramOnboardingFlow
↓
Business Logic Layer
OnboardingApplicationService.getProcessIdForVendorProgram()
↓
Application Layer Component
onboardingFlowEngine
↓
Business Logic Layer
OnboardingApplicationService.getStagesForProcess()
↓
Application Layer Component
onboardingStageRenderer (dynamically renders stage components)
↓
Application Layer Component
Stage component (e.g., vendorProgramOnboardingVendor)
↓
Business Logic Layer
OnboardingApplicationService.saveProgress()
↓
Domain Layer (if needed)
Data operations via flows


## Benefits of Layered Architecture

### Separation of Concerns

- **Application Layer**: Focuses on user experience
- **Business Logic Layer**: Focuses on business rules
- **Domain Layer**: Focuses on data operations

### Maintainability

- Changes to UI don't affect business logic
- Business logic changes don't affect data operations
- Data model changes isolated to Domain Layer

### Testability

- Each layer can be tested independently
- Business logic can be tested without UI
- Data operations can be tested in isolation

### Reusability

- Business logic services can be reused across components
- Domain flows can be reused across processes
- Components can be reused across applications

## Best Practices

### Application Layer

1. **Thin Controllers**: Keep component logic minimal
2. **Service Delegation**: Delegate to Business Logic Layer
3. **Error Handling**: Handle errors gracefully
4. **Loading States**: Show loading indicators

### Business Logic Layer

1. **Service Classes**: Organize logic into services
2. **No Direct Data Access**: Use Domain Layer for data
3. **Validation**: Enforce business rules
4. **Error Handling**: Throw meaningful exceptions

### Domain Layer

1. **Pure Data Operations**: No business logic
2. **Reusable Flows**: Create reusable subflows
3. **Error Handling**: Handle data errors
4. **Naming Convention**: Follow naming convention

## Related Documentation

- [Architecture Overview](./overview.md)
- [Data Model](./data-model.md)
- [Flows](../processes/flows.md)
