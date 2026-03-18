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
- `vendorProgramOnboardingVendorProgramRecipientGroup`
- `vendorProgramOnboardingRecipientGroup`
- `vendorProgramOnboardingRecipientGroupMembers`
- `vendorProgramOnboardingRequiredCredentials`
- `vendorProgramOnboardingTrainingRequirements`
- `vendorProgramOnboardingCommunicationTemplate`
- `vendorProgramOnboardingFinalize`

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
3. Stage 3: Required Credentials (Order: 3)
4. Stage 4: Training Requirements (Order: 4)
5. Stage 5: Recipient Groups (Order: 5)
6. Stage 6: Communication Template (Order: 6)
7. Stage 7: Finalize (Order: 7)

### Step 4: Assign Process to Vendor Program

1. Navigate to Vendor Program record
2. Create `Onboarding Application Progress` record:
   - **Onboarding Application Process**: Select process
   - **Vendor Program**: Current vendor program
   - **Current Stage**: (Leave blank initially)

### Example: Onboarding Flow
Application Layer
User starts onboarding from Account or dashboard
↓
Application Layer Component
accountProgramOnboardingModal / onboardingDealerOnboardingModal
↓
Business Logic Layer
VendorOnboardingService / Flows
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

- [Architecture Overview](../architecture/overview.md)
- [Data Model](../architecture/data-model.md)
- [Flows](../components/flows.md)
