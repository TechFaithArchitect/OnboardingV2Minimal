# Vendor Program Onboarding Flow Architecture

## Overview

This document describes the complete flow for building a Vendor Program from scratch using the metadata-driven onboarding system. The system uses a **Component Library** pattern that allows you to define a sequence of wizard steps, and the system dynamically renders the appropriate Lightning Web Components based on the library configuration.

See [User Journey Summary](../user-guides/user-journey-summary.md) for the end-to-end flow.

## Current Flow Structure (10 Steps)

The Vendor Program Onboarding wizard has been restructured into a **10-step flow** that supports both **User** and **Admin** roles with conditional branching based on user permissions.

### Step-by-Step Flow

#### **Step 1: Select Vendor**

- **Component:** `vendorProgramOnboardingVendor`
- **Purpose:** Search for existing vendors or create a new vendor
- **Output:** `vendorId` passed to next step

#### **Step 2: Search or Create Vendor Program**

- **Component:** `vendorProgramOnboardingVendorProgramSearchOrCreate`
- **Purpose:** Search for existing vendor programs or create a new draft vendor program
- **Features:**
  - Search existing vendor programs
  - Create new draft vendor program with:
    - `Label__c` (Vendor Program Label)
    - `Retail_Option__c` (Picklist)
    - `Business_Vertical__c` (Picklist)
  - Draft status is set automatically (`Status__c = 'Draft'`, `Active__c = false`)
- **Output:** `vendorProgramId` passed to next step

#### **Step 3: Select Requirement Set OR Create Requirements**

- **Component:** `vendorProgramOnboardingRequirementSetOrCreate`
- **Purpose:** Select existing Onboarding Requirement Set or create new requirements
- **Sub-steps:**
  - **3a:** If Requirement Set exists and is selected:
    - Confirm selection or make changes
    - If confirmed: Link Requirement Set to Vendor Program (via `Vendor_Program_Requirement_Set__c`)
    - If changes: Create new Requirement Set with naming convention: `"Vendor Program Label - Onboarding Set"`
  - **3b:** If no Requirement Set or skipped:
    - Create `Vendor_Program_Onboarding_Req_Template__c` records inline
    - Create `Vendor_Program_Requirement__c` records from templates
    - Confirm all requirements created
- **Features:**
  - Inline template creation without leaving screen
  - Inline requirement creation from templates
  - Search and select existing Requirement Sets
- **Output:** `requirementSetId`, `requirementTemplateId` passed to next step

#### **Step 4: Create and Link Requirement Group Components**

- **Component:** `vendorProgramOnboardingRequirementGroupLinking`
- **Purpose:** Create and link Vendor Program Group, Vendor Program Requirement Group, and Vendor Program Group Member
- **Sub-steps:**
  - **4a:** If using selected Requirement Set (from Step 3):
    - Link from historical values (reuse existing groups)
  - **4b:** If creating new:
    - Create `Vendor_Program_Group__c` with naming: `"Vendor Program Label - Vendor Program Group"`
    - Create `Vendor_Program_Requirement_Group__c` with naming: `"Vendor Program Label - Requirement Group"`
    - Create `Vendor_Program_Group_Member__c` to link them together
- **Output:** `groupMemberId` passed to next step

#### **Step 5: Required Credentials (Conditional)**

- **Component:** `vendorProgramOnboardingRequiredCredentials`
- **Purpose:** Configure required credentials if needed
- **Features:**
  - Yes/No prompt: "Are Required Credentials needed?"
  - If Yes: Show credential management UI
  - If No: Skip to next step
- **Output:** `credentialsNeeded` boolean flag

#### **Step 6: Training Requirements**

- **Component:** `vendorProgramOnboardingTrainingRequirements`
- **Purpose:** Configure training requirements using dual-listbox selection
- **Features:**
  - Inline creation of `Training_System__c` records
  - Dual-listbox for selecting training requirements
  - Moving items to "Selected for Group" sets `Is_Required__c = true`
  - Moving items to "Available" sets `Is_Required__c = false`
  - Real-time updates to bottom table showing required training requirements
- **Output:** Training requirements linked to Vendor Program

#### **Step 7: Status Rules Engine**

- **Component:** `vendorProgramOnboardingStatusRulesEngine`
- **Purpose:** Select or create Status Rules Engine
- **Sub-steps:**
  - **7a:** If creating new or no Requirement Set:
    - Create `Onboarding_Status_Rules_Engine__c`
    - Create `Onboarding_Status_Rule__c` records
  - **7b:** If previous Status Rules Engine exists (from Requirement Set):
    - Show confirmation with option to use existing or create new
- **Features:**
  - Search existing Status Rules Engines
  - Historical data detection from Requirement Set
  - Confirmation view with option to make changes
- **Output:** `statusRulesEngineId` passed to next step

#### **Step 8: Communication Template & Recipient Groups**

- **Component (Admin):** `vendorProgramOnboardingRecipientGroup`
- **Component (User):** Skip to Step 9
- **Purpose (Admin):** Create or select Recipient Groups and link to Vendor Program
- **Features (Admin):**
  - Show existing Recipient Groups for Vendor Program
  - Option to use existing or create new
  - Create `Recipient_Group__c` with members
  - Add `Recipient_Group_Member__c` records
  - Link via `Vendor_Program_Recipient_Group__c`
- **Output:** `recipientGroupId` passed to next step

#### **Step 9: Communication Template Selection**

- **Component:** `vendorProgramOnboardingCommunicationTemplate`
- **Purpose:** Select Communication Template, Recipient Group, and trigger condition
- **Features:**
  - Select `Communication_Template__c`
  - Select `Recipient_Group__c` (from Step 9 or existing)
  - Enter trigger condition (e.g., "Onboarding Status = 'Setup Complete'")
  - Create `Vendor_Program_Recipient_Group__c` link with template and condition
- **Output:** Communication template linked with trigger condition

#### **Step 10: Finalize Vendor Program**

- **Component:** `vendorProgramOnboardingFinalize`
- **Purpose:** Complete onboarding setup and navigate to Vendor Program
- **Features:**
  - Summary of completed steps
  - Navigation to Vendor Program record page
  - Vendor Program remains in Draft status (activation happens separately)

## System Components

### 1. Component Library (`Onboarding_Component_Library__c`)

The Component Library is the central registry that maps Lightning Web Component API names to displayable metadata records. This allows the system to dynamically determine which LWC components are available for use in onboarding flows.

**Key Fields:**

- `Component_API_Name__c` - The API name of the LWC component (e.g., "vendorProgramOnboardingVendor")
- `Name` - Display name (auto-generated from API name)
- `Component_Type__c` - Type of component (e.g., "LWC")
- `Active__c` - Whether the component is active

**How It's Populated:**

The component library is automatically populated using the `VendorOnboardingWizardController.syncRendererComponents()` method, which is marked as `@InvocableMethod` for Flow integration.

**Available Components (Current):**

1. `vendorProgramOnboardingVendor` - Vendor selection/creation
2. `vendorProgramOnboardingVendorProgramSearchOrCreate` - Search/create vendor program with Label, Retail Option, Business Vertical
3. `vendorProgramOnboardingRequirementSetOrCreate` - Select Requirement Set or create requirements with inline templates
4. `vendorProgramOnboardingRequirementGroupLinking` - Link Requirement Group components
5. `vendorProgramOnboardingRequiredCredentials` - Configure required credentials (conditional)
6. `vendorProgramOnboardingTrainingRequirements` - Configure training requirements
7. `vendorProgramOnboardingStatusRulesEngine` - Select/create Status Rules Engine
8. `vendorProgramOnboardingRecipientGroup` - Create/manage Recipient Groups (Admin only)
9. `vendorProgramOnboardingCommunicationTemplate` - Link Communication Template with Recipient Group and trigger condition
10. `vendorProgramOnboardingFinalize` - Complete onboarding setup

### 2. Onboarding Process (`Onboarding_Application_Process__c`)

A process defines a sequence of stages that make up an onboarding workflow. Multiple processes can exist for different types of onboarding scenarios.

**Key Fields:**

- `Name` - Process name (e.g., "Vendor Program Onboarding")
- `Active__c` - Whether the process is active
- `Description__c` - Process description

### 3. Onboarding Stages (`Onboarding_Application_Stage__c`)

Stages define individual steps in the onboarding process. Each stage references a component from the Component Library that should be rendered.

**Key Fields:**

- `Onboarding_Application_Process__c` - Parent process
- `Onboarding_Component_Library__c` - Component to render (lookup to Component Library)
- `Display_Order__c` - Order in sequence (1, 2, 3, etc.)
- `Label__c` - Display label for the stage
- `Required__c` - Whether stage is mandatory
- `Next_Stage__c` - Optional: Specific next stage (for branching logic)

### 4. Onboarding Progress (`Onboarding_Application_Progress__c`)

Tracks where a user is in the onboarding process for a specific Vendor Program.

**Key Fields:**

- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - The vendor program being onboarded
- `Onboarding_Application_Process__c` - The process being executed
- `Current_Stage__c` - Current stage ID (allows resuming)

### 5. Stage Completion (`Onboarding_Application_Stage_Completion__c`)

Audit log of completed stages.

**Key Fields:**

- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program
- `Onboarding_Application_Process__c` - Process
- `Onboarding_Application_Stage__c` - Completed stage
- `Completed_Date__c` - When completed
- `Completed_By__c` - Who completed it

## Flow Architecture

### High-Level Flow

```
1. User starts Vendor Program creation
   ↓
2. System creates/loads Vendor Program record
   ↓
3. Vendor Program record page loads vendorProgramOnboardingFlow component
   ↓
4. vendorProgramOnboardingFlow:
   - Gets Process ID from Onboarding_Application_Progress__c (or creates new progress)
   - Loads onboardingFlowEngine with processId and vendorProgramId
   ↓
5. onboardingFlowEngine:
   - Loads all stages from Onboarding_Application_Stage__c for the process
   - Loads progress (if exists) to resume at Current_Stage__c
   - Renders onboardingStageRenderer for the current stage
   - Stores step data in _stepData map for context passing
   ↓
6. onboardingStageRenderer:
   - Gets Component_API_Name__c from Onboarding_Component_Library__c (via stage)
   - Uses static conditional rendering to show the appropriate LWC component
   - Passes context (vendorProgramId, stageId, requirementSetId, etc.) to the component
   ↓
7. Stage Component (e.g., vendorProgramOnboardingRequirementSetOrCreate):
   - User interacts with the component
   - Component uses VendorOnboardingWizardController Apex methods
   - Component fires 'next' event with stage data
   ↓
8. onboardingFlowEngine:
   - Receives 'next' event
   - Stores event.detail in _stepData map for context passing
   - Saves progress to Onboarding_Application_Progress__c
   - Creates Onboarding_Application_Stage_Completion__c record
   - Advances to next stage (by Display_Order__c or Next_Stage__c)
   ↓
9. Repeat steps 6-8 until all stages complete
   ↓
10. Process complete - Vendor Program is fully configured in Draft status
```

### Context Passing Between Steps

The `onboardingFlowEngine` component maintains a `_stepData` map that stores data from each step. This data is passed to subsequent steps via the `componentContext` getter:

```javascript
get componentContext() {
  return {
    vendorProgramId: this.vendorProgramId,
    stageId: this.currentStage?.Id,
    requirementSetId: this._stepData.get('requirementSetId'),
    requirementTemplateId: this._stepData.get('requirementTemplateId'),
    recipientGroupId: this._stepData.get('recipientGroupId'),
    // ... other context data
  };
}
```

### Component Interaction Pattern

```javascript
// onboardingFlowEngine loads stage with Component_API_Name__c
activeComponentName = stage.Onboarding_Component_Library__r.Component_API_Name__c;
// Example: "vendorProgramOnboardingRequirementSetOrCreate"

// onboardingStageRenderer receives componentName prop
// Uses static getters for conditional rendering
get showVendorProgramOnboardingRequirementSetOrCreate() {
  return this.componentName === 'vendorProgramOnboardingRequirementSetOrCreate';
}

// Template renders component based on getter
<template if:true={showVendorProgramOnboardingRequirementSetOrCreate}>
  <c-vendor-program-onboarding-requirement-set-or-create
    vendor-program-id={vendorProgramId}
    stage-id={stageId}
    requirement-set-id={requirementSetId}
    onnext={handleNext}
    onback={handleBack}>
  </c-vendor-program-onboarding-requirement-set-or-create>
</template>
```

## User vs Admin Flow Differences

### User Flow

- **Step 9:** Skips Recipient Group creation (uses existing groups)
- **Step 10:** Only selects Communication Template, Recipient Group, and trigger condition

### Admin Flow

- **Step 9:** Can create new Recipient Groups, add members, and link to Vendor Program
- **Step 10:** Same as User flow - selects Communication Template, Recipient Group, and trigger condition

## Key Technical Details

### Static Rendering Pattern

LWC does not support dynamic component loading. Therefore, `onboardingStageRenderer` uses **static conditional rendering** with getters:

```javascript
get showVendorProgramOnboardingRequirementSetOrCreate() {
  return this.componentName === 'vendorProgramOnboardingRequirementSetOrCreate';
}
```

The HTML template has all possible components statically defined, but only one renders based on the getter.

### Context Passing

Components receive context via props:

- `vendorProgramId` - Current Vendor Program ID
- `stageId` - Current Stage ID
- `requirementSetId` - From Step 4 (optional)
- `requirementTemplateId` - From Step 4 (optional)
- `recipientGroupId` - From Step 9 (optional)
- Additional data via custom event details stored in `_stepData` map

### Progress Persistence

After each stage:

1. `Onboarding_Application_Progress__c` is upserted with `Current_Stage__c`
2. `Onboarding_Application_Stage_Completion__c` is inserted for audit trail
3. Step data is stored in `_stepData` map for context passing
4. User can close browser and resume later

### Apex Integration

All stage components use `VendorOnboardingWizardController` methods:

- `searchVendors()` / `createVendor()`
- `searchVendorPrograms()` / `createVendorProgram()`
- `searchOnboardingRequirementSets()` / `linkRequirementSetToVendorProgram()` / `createRequirementSetFromExisting()`
- `getTemplatesForRequirementSet()` / `createRequirementFromTemplate()`
- `getHistoricalGroupMembers()` / `createRequirementGroupComponents()`
- `getHistoricalStatusRulesEngines()`
- `getRecipientGroupsForVendorProgram()` / `createRecipientGroup()` / `createRecipientGroupMember()`
- `createVendorProgramRecipientGroupWithTemplate()`
- And many more...

## Setting Up a New Onboarding Process

### Step 1: Populate Component Library

```apex
// Execute via Anonymous Apex or Flow
VendorOnboardingWizardController.syncRendererComponents();
```

This creates all `Onboarding_Component_Library__c` records for the wizard components.

### Step 2: Create Process Record

```apex
Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
    Name = 'Vendor Program Onboarding',
    Active__c = true,
    Description__c = 'Complete wizard flow for setting up a vendor program'
);
insert process;
```

### Step 3: Create Stages

For each component, create a stage:

```apex
List<Onboarding_Application_Stage__c> stages = new List<Onboarding_Application_Stage__c>();

// Get component library records
Map<String, Id> componentMap = new Map<String, Id>();
for (Onboarding_Component_Library__c lib : [
    SELECT Id, Component_API_Name__c
    FROM Onboarding_Component_Library__c
]) {
    componentMap.put(lib.Component_API_Name__c, lib.Id);
}

// Stage 1: Vendor Selection
stages.add(new Onboarding_Application_Stage__c(
    Onboarding_Application_Process__c = process.Id,
    Onboarding_Component_Library__c = componentMap.get('vendorProgramOnboardingVendor'),
    Display_Order__c = 1,
    Label__c = 'Select Vendor',
    Required__c = true
));

// Stage 2: Vendor Program Search/Create
stages.add(new Onboarding_Application_Stage__c(
    Onboarding_Application_Process__c = process.Id,
    Onboarding_Component_Library__c = componentMap.get('vendorProgramOnboardingVendorProgramSearchOrCreate'),
    Display_Order__c = 2,
    Label__c = 'Vendor Program',
    Required__c = true
));

// ... continue for all 10 stages

insert stages;
```

### Step 4: Link Process to Vendor Program

When a Vendor Program is created, link it to the process:

```apex
Onboarding_Application_Progress__c progress = new Onboarding_Application_Progress__c(
    Vendor_Program__c = vendorProgramId,
    Onboarding_Application_Process__c = processId,
    Current_Stage__c = firstStageId
);
insert progress;
```

## Entry Points

### 1. From Dashboard (New Vendor Program)

- User clicks "Start Onboarding Vendor Program" → "Create New"
- Selects/creates Vendor
- Navigates to new Vendor Program record
- Flow starts automatically

### 2. From Vendor Program Record Page

- User views existing Vendor Program
- `vendorProgramOnboardingFlow` component detects Process
- If Process exists, flow resumes or starts
- If no Process, user can select one (or system uses default)

### 3. From Home Dashboard

- "Start Dealer Onboarding" for Account-based onboarding
- "Start Onboarding Vendor Program" for vendor program setup

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Component Library                         │
│         (Onboarding_Component_Library__c)                    │
│  Maps: "vendorProgramOnboardingVendor" → Component Record    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  Onboarding Process                          │
│         (Onboarding_Application_Process__c)                  │
│              "Vendor Program Onboarding"                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    Onboarding Stages                         │
│        (Onboarding_Application_Stage__c)                     │
│  Stage 1 → vendorProgramOnboardingVendor (Order: 1)         │
│  Stage 2 → vendorProgramOnboardingVendorProgram... (Order: 2)│
│  ...                                                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              onboardingFlowEngine                            │
│  - Loads stages for Process                                  │
│  - Tracks current stage                                      │
│  - Stores step data in _stepData map                         │
│  - Renders onboardingStageRenderer                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│            onboardingStageRenderer                           │
│  - Gets Component_API_Name__c from stage                     │
│  - Uses static conditional rendering                         │
│  - Renders appropriate LWC component                         │
│  - Passes context (vendorProgramId, requirementSetId, etc.) │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│        Stage Component (e.g., vendorProgramOnboarding...)    │
│  - User interacts                                            │
│  - Uses VendorOnboardingWizardController                     │
│  - Fires 'next' event with data                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Progress Tracking                               │
│  (Onboarding_Application_Progress__c)                        │
│  (Onboarding_Application_Stage_Completion__c)                │
│  (_stepData map for context passing)                         │
└─────────────────────────────────────────────────────────────┘
```

## Summary

The Vendor Program Onboarding Flow is a **metadata-driven wizard system** that:

1. **Uses Component Library** to define available wizard components
2. **Uses Process & Stages** to define the sequence of steps
3. **Uses Flow Engine** to orchestrate the wizard flow with context passing
4. **Uses Stage Renderer** to dynamically render components via static conditional rendering
5. **Tracks Progress** to allow resuming incomplete onboarding
6. **Passes Context** between steps via `_stepData` map
7. **Creates Related Records** step-by-step to build a complete Vendor Program

The system is fully documented and extensible - you can add new components to the library and create new processes with different stage sequences for different onboarding scenarios.
