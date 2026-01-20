# Application Flow Engine

## Overview

The Application Flow Engine is a metadata-driven system that dynamically renders Lightning Web Components based on configuration stored in Custom Objects. It provides a flexible, reusable framework for building onboarding flows without hardcoding component sequences.

## Architecture

```
┌─────────────────────────────────────────┐
│  vendorProgramOnboardingFlow (LWC)      │
│  - Entry point from record page         │
│  - Resolves process ID                  │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  onboardingFlowEngine (LWC)             │
│  OR onboardingApplicationFlow (LWC)    │
│  - Loads stages from metadata           │
│  - Manages current stage                │
│  - Handles navigation                   │
│  - Persists progress (FlowEngine only)  │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  onboardingStageRenderer (LWC)           │
│  - Dynamically instantiates components  │
│  - Passes context to children           │
│  - Handles navigation events            │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  Stage Component (LWC)                  │
│  - Stage-specific logic                 │
│  - User interactions                   │
│  - Fires navigation events              │
└─────────────────────────────────────────┘
```

## Component Flow

### 1. Entry Point: vendorProgramOnboardingFlow

**Purpose**: Resolves the onboarding process for a vendor program.

**Flow:**
1. Receives `recordId` (Vendor Program ID) from Lightning record page
2. Calls `OnboardingApplicationService.getProcessIdForVendorProgram()`
3. Passes `processId` to `onboardingFlowEngine`
4. Handles loading and error states

**Code:**
```javascript
@wire(getProcessIdForVendorProgram, { vendorProgramId: '$recordId' })
wiredProcess({ error, data }) {
  if (data) {
    this.processId = data;
  }
}
```

### 2. Flow Controller: onboardingFlowEngine / onboardingApplicationFlow

**Purpose**: Manages the onboarding flow lifecycle.

**Two Implementations:**

**onboardingFlowEngine** (Used by vendorProgramOnboardingFlow):
- Load stages from metadata
- Track current stage index
- Handle navigation (next/back)
- Persist progress
- Resume from saved progress

**onboardingApplicationFlow** (Standalone implementation):
- Load stages from metadata
- Track current stage index
- Handle navigation (next/back)
- Parallel loading of stages and process details
- Computed properties for UI state
- Surfaces Apex failures via toast using shared error handling (`c/utils.extractErrorMessage`)

**Key Methods:**

**initializeFlow() / loadProcess()**
- Loads stages: `getStagesForProcess()` (includes Label__c, Next_Stage__c, Required__c)
- Loads progress: `getProgress()` (onboardingFlowEngine only)
- Loads process details: `getProcessDetails()` (parallel load in onboardingApplicationFlow)
- Resumes from saved stage if exists (onboardingFlowEngine only)

**handleNext()**
- Advances to next stage
- Supports branching via `Next_Stage__c`
- Falls back to sequential order
- Saves progress

**handleBack()**
- Returns to previous stage
- Saves progress

**persistProgress()** (onboardingFlowEngine only)
- Uses `saveProgress()` which upserts `Onboarding_Application_Progress__c`
- Creates new `Onboarding_Application_Stage_Completion__c` record
- Handles both insert (new progress) and update (existing progress) scenarios via upsert

### 3. Component Renderer: onboardingStageRenderer

**Purpose**: Dynamically renders stage components.

**Flow:**
1. Receives `componentName` (API name) from flow engine
2. Receives `context` object (extracts vendorProgramId and stageId)
3. Uses static conditional rendering (LWC requires static component references)
4. Passes individual props to components (vendor-program-id, stage-id)
5. Listens for navigation events (onnext, onback)

**Static Conditional Rendering:**
Uses computed boolean properties for each component type. Components receive props based on their needs:
```html
<template>
  <!-- Components that don't need props -->
  <template if:true={showVendorProgramOnboardingVendor}>
    <c-vendor-program-onboarding-vendor
      onnext={handleNext}
      onback={handleBack}>
    </c-vendor-program-onboarding-vendor>
  </template>

  <!-- Components that need vendorProgramId -->
  <template if:true={showVendorProgramOnboardingVendorProgramRecipientGroup}>
    <c-vendor-program-onboarding-vendor-program-recipient-group
      vendor-program-id={vendorProgramId}
      onnext={handleNext}
      onback={handleBack}>
    </c-vendor-program-onboarding-vendor-program-recipient-group>
  </template>

  <!-- Components that need vendorProgramId and stageId -->
  <template if:true={showVendorProgramOnboardingTrainingRequirements}>
    <c-vendor-program-onboarding-training-requirements
      vendor-program-id={vendorProgramId}
      stage-id={stageId}
      onnext={handleNext}
      onback={handleBack}>
    </c-vendor-program-onboarding-training-requirements>
  </template>
</template>
```

**Supported Components:**
- `vendorProgramOnboardingVendor`
- `vendorProgramOnboardingVendorProgramCreate`
- `vendorProgramOnboardingVendorProgramGroup`
- `vendorProgramOnboardingVendorProgramRequirementGroup`
- `vendorProgramOnboardingVendorProgramRecipientGroup`
- `vendorProgramOnboardingRecipientGroup`
- `vendorProgramOnboardingRecipientGroupMembers`
- `vendorProgramOnboardingTrainingRequirements`
- `vendorProgramOnboardingRequiredCredentials`
- `vendorProgramOnboardingVendorProgramSearchOrCreate`

**Event Handling:**
```javascript
handleNext(event) {
  this.dispatchEvent(new CustomEvent('next', { detail: event.detail }));
}
```

### 4. Stage Components

**Purpose**: Implement stage-specific functionality.

**Requirements:**
- Accept `context` prop with `vendorProgramId` and `stageId`
- Fire `next` event when stage complete
- Fire `back` event to return to previous stage
- Handle own data operations
- Show loading states
- Handle errors gracefully

**Example Structure:**
```javascript
export default class VendorProgramOnboardingVendor extends LightningElement {
  @api context;
  
  get vendorProgramId() {
    return this.context?.vendorProgramId;
  }
  
  handleNext() {
    this.dispatchEvent(new CustomEvent('next', { 
      detail: { /* stage data */ } 
    }));
  }
}
```

## Metadata Model

### Onboarding_Application_Process__c

Defines a reusable onboarding process.

**Fields:**
- `Name` - Process name
- `Description__c` - Process description
- `Active__c` - Whether process is active

### Onboarding_Application_Stage__c

Defines a stage within a process.

**Fields:**
- `Onboarding_Application_Process__c` - Parent process
- `Onboarding_Component_Library__c` - Component to render
- `Display_Order__c` - Order in flow
- `Label__c` - Display label
- `Required__c` - Whether stage is required
- `Next_Stage__c` - Next stage (for branching)

### Onboarding_Component_Library__c

Maps LWC components to metadata.

**Fields:**
- `Component_API_Name__c` - LWC component API name
- `Name` - Component name
- `Description__c` - Component description

### Onboarding_Application_Progress__c

Tracks user progress.

**Fields:**
- `Onboarding_Application_Process__c` - Process being executed
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program being onboarded
- `Current_Stage__c` - Current stage ID

### Onboarding_Application_Stage_Completion__c

Audit log of completed stages.

**Fields:**
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program
- `Onboarding_Application_Process__c` - Process
- `Onboarding_Application_Stage__c` - Completed stage
- `Completed_Date__c` - Completion timestamp
- `Completed_By__c` - User who completed

## Navigation

### Sequential Navigation

Default navigation follows `Display_Order__c`:
- Stage 1 → Stage 2 → Stage 3 → ...

### Branching Navigation

Stages can branch by setting `Next_Stage__c`:
- Stage 1 → Stage 2 (if condition A)
- Stage 1 → Stage 3 (if condition B)

**Implementation:**
```javascript
async handleNext(event) {
  const nextStageId = this.activeStage?.Next_Stage__c;
  
  if (nextStageId) {
    const nextIndex = this.stages.findIndex(stage => stage.Id === nextStageId);
    if (nextIndex >= 0) {
      this.activeStageIndex = nextIndex;
    }
  } else {
    // Sequential navigation
    this.activeStageIndex++;
  }
}
```

## Progress Persistence

### Saving Progress

Progress is saved after each stage navigation:
1. `Onboarding_Application_Progress__c` is upserted with current stage
2. `Onboarding_Application_Stage_Completion__c` is inserted for audit

### Resuming Progress

On initialization:
1. Load `Onboarding_Application_Progress__c` for vendor program
2. Find `Current_Stage__c` in stage list
3. Set `activeStageIndex` to saved stage
4. User continues from that point

## Error Handling

### Missing Process
- Displays error message
- Prevents flow initialization

### Missing Stages
- Displays error message
- Prevents flow initialization

### Invalid Component
- Logs error to console
- Shows error message to user

### Progress Save Failure
- Logs error
- Allows user to continue (progress may be lost)

## Best Practices

### Stage Components

1. **Self-Contained**: Handle own data operations
2. **Error Handling**: Gracefully handle errors
3. **Loading States**: Show loading indicators
4. **Validation**: Validate before firing 'next' event
5. **Context Usage**: Use context for vendor program and stage IDs

### Process Configuration

1. **Clear Labels**: Use descriptive stage labels
2. **Logical Ordering**: Order stages logically
3. **Component Naming**: Use consistent component API names
4. **Documentation**: Document complex branching logic

### Performance

1. **Lazy Loading**: Load stage data on demand
2. **Caching**: Cache process and stage metadata
3. **Batch Operations**: Batch data operations when possible

## Extending the Engine

### Adding New Stages

1. Create LWC component
2. Create `Onboarding_Component_Library__c` record
3. Create `Onboarding_Application_Stage__c` record
4. Add to process

### Adding Branching Logic

1. Set `Next_Stage__c` on stage records
2. Implement conditional logic in stage components
3. Pass condition data in 'next' event detail

### Adding Progress Indicators

1. Calculate progress percentage
2. Display progress bar
3. Show completed stages

## Related Documentation

- [Onboarding Process](./onboarding-process.md)
- [LWC Components](../components/lwc-components.md)
- [Data Model](../architecture/data-model.md)
