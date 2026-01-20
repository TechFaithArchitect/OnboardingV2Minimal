# Vendor Program Onboarding Wizard Components

This document provides comprehensive documentation for all Lightning Web Components used in the Vendor Program Onboarding Wizard flow.

## Overview

The Vendor Program Onboarding Wizard is a 14-step flow that guides users through creating and configuring a complete Vendor Program. Each step is implemented as a separate LWC component that extends `onboardingStepBase` and is dynamically rendered by the `onboardingStageRenderer` component.

## Component Architecture

All wizard components extend the `onboardingStepBase` base class and follow a consistent pattern:

### Base Class Pattern

All step components extend `OnboardingStepBase`, which provides:

- **Footer Navigation:** Automatic handling of `footernavnext` and `footernavback` events
- **Validation State:** Automatic dispatching of `validationchanged` events
- **Toast Notifications:** Centralized `showToast()` utility method
- **Card Titles:** Dynamic title generation using `stepNumber` and `stepName`
- **Event Dispatching:** Standardized `dispatchNextEvent()` and `dispatchBackEvent()` methods

### Component Pattern

Each step component:

- Extends `OnboardingStepBase`
- Sets `stepName` property for card title
- Implements `get canProceed()` to return validation state
- Implements `proceedToNext()` to dispatch next event with data
- Receives `vendorProgramId` and `stageId` as `@api` properties
- Receives additional context data (e.g., `requirementSetId`, `recipientGroupId`) from previous steps
- Uses `VendorOnboardingWizardController` Apex methods for data operations (controller coordinates multiple domain services)
- Some components call domain services directly via @AuraEnabled methods
- Displays information boxes with context and best practices
- Shows loading spinners during async operations
- Uses `this.showToast()` for success/error feedback

### Example Implementation

```javascript
import OnboardingStepBase from "c/onboardingStepBase";

export default class MyStepComponent extends OnboardingStepBase {
  stepName = "My Step Name";

  @api vendorProgramId;
  @api stageId;

  connectedCallback() {
    super.connectedCallback(); // Call base class for event listeners
    // Component-specific initialization
  }

  get canProceed() {
    return !!this.selectedId; // Your validation logic
  }

  proceedToNext() {
    this.dispatchNextEvent({
      selectedId: this.selectedId
    });
  }
}
```

**Benefits:**

- Eliminates ~700+ lines of duplicate code across all components
- Ensures consistent navigation and validation patterns
- Makes adding new steps easier and faster
- Centralizes common functionality for easier maintenance

## Step 1: Select Vendor

### vendorProgramOnboardingVendor

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingVendor/`

**Purpose:** Step 1 - Search for existing vendors or create a new vendor.

**API:**

- `@api vendorProgramId` - Current vendor program ID (optional)
- `@api stageId` - Current stage ID

**Key Features:**

- Search vendors by name
- Create new vendor inline
- Radio button selection for existing vendors
- Auto-enables Next button when vendor selected/created

**Methods:**

- `searchVendors()` - Searches for vendors by name
- `createVendor()` - Creates new vendor record
- `handleVendorSelect()` - Handles vendor selection
- `proceedNext()` - Fires next event with `vendorId`

**Dependencies:**

- `VendorOnboardingWizardController.searchVendors()`
- `VendorOnboardingWizardController.createVendor()`

**Events:**

- Fires `next` event with `detail: { vendorId: String }`

## Step 2: Search or Create Vendor Program

### vendorProgramOnboardingVendorProgramSearchOrCreate

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingVendorProgramSearchOrCreate/`

**Purpose:** Step 2 - Search for existing vendor programs or create a new draft vendor program with Label, Retail Option, and Business Vertical.

**API:**

- `@api vendorProgramId` - Current vendor program ID (optional)
- `@api stageId` - Current stage ID
- `@api vendorId` - Vendor ID from Step 1

**Key Features:**

- Search existing vendor programs by name
- Create new draft vendor program with:
  - `Label__c` (Vendor Program Label) - Text input
  - `Retail_Option__c` - Picklist (dynamically fetched)
  - `Business_Vertical__c` - Picklist (dynamically fetched)
- Radio button selection for existing programs
- Conditional rendering of create form
- Form validation for required fields

**Properties:**

- `searchText` - Search input text
- `programs` - Search results
- `selectedProgramId` - Selected program ID
- `showCreateForm` - Toggle for create form visibility
- `newProgramLabel` - New program label input
- `newRetailOption` - Retail option selection
- `newBusinessVertical` - Business vertical selection
- `retailOptionOptions` - Picklist options (via @wire)
- `businessVerticalOptions` - Picklist options (via @wire)

**Methods:**

- `searchVendorPrograms()` - Searches for vendor programs
- `createProgram()` - Creates new draft vendor program
- `handleProgramSelect()` - Handles program selection
- `toggleCreateForm()` - Shows/hides create form
- `handleFieldChange()` - Handles field changes

**Dependencies:**

- `VendorOnboardingWizardController.searchVendorPrograms()`
- `VendorOnboardingWizardController.createVendorProgram()`
- `VendorOnboardingWizardController.getRetailOptionPicklistValues()` (@wire, cacheable)
- `VendorOnboardingWizardController.getBusinessVerticalPicklistValues()` (@wire, cacheable)

**Events:**

- Fires `next` event with `detail: { vendorProgramId: String }`

**Note:** New vendor programs are created with `Status__c = 'Draft'` and `Active__c = false`.

## Step 3: Create Vendor Program in Draft

**Status:** Implicit - Vendor Program is already created in Draft status in Step 2.

## Step 4: Select Requirement Set OR Create Requirements

### vendorProgramOnboardingRequirementSetOrCreate

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingRequirementSetOrCreate/`

**Purpose:** Step 4 - Select existing Onboarding Requirement Set or create new requirements with inline template creation.

**API:**

- `@api vendorProgramId` - Current vendor program ID
- `@api stageId` - Current stage ID

**Key Features:**

- Multi-state component with views: `selectSet`, `confirmSet`, `createSet`, `createTemplates`, `confirmRequirements`
- Search and select existing `Onboarding_Requirement_Set__c`
- Confirm selection or create new set with naming convention
- Inline creation of `Vendor_Program_Onboarding_Req_Template__c` records
- Inline creation of `Vendor_Program_Requirement__c` records from templates
- Real-time updates without leaving screen

**Properties:**

- `currentView` - Current view state
- `searchText` - Search input text
- `requirementSets` - Search results
- `selectedRequirementSetId` - Selected requirement set ID
- `selectedRequirementSet` - Selected requirement set record
- `templates` - Templates for selected requirement set
- `newTemplate` - New template form data
- `showTemplateForm` - Template form visibility
- `templatesWithCreatedStatus` - Templates with created requirement status
- `createdRequirements` - Created requirements list
- `isLoading` - Loading state

**Methods:**

- `searchRequirementSets()` - Searches for requirement sets
- `handleRequirementSetSelect()` - Handles requirement set selection
- `handleSelectAndContinue()` - Proceeds with selected set
- `handleSkipToCreateRequirements()` - Skips to create requirements view
- `handleConfirmSelection()` - Confirms selected set
- `handleMakeChanges()` - Creates new set from existing
- `toggleTemplateForm()` - Shows/hides template form
- `createTemplate()` - Creates new template
- `loadTemplates()` - Loads templates for requirement set
- `createRequirementFromTemplate()` - Creates requirement from template
- `handleConfirmRequirementsCreated()` - Confirms all requirements created

**Dependencies:**

- `VendorOnboardingWizardController.searchOnboardingRequirementSets()`
- `VendorOnboardingWizardController.linkRequirementSetToVendorProgram()`
- `VendorOnboardingWizardController.createRequirementSetFromExisting()`
- `VendorOnboardingWizardController.getTemplatesForRequirementSet()`
- `VendorOnboardingWizardController.createRequirementFromTemplate()`
- `VendorOnboardingWizardController.getVendorProgramLabel()`

**Events:**

- Fires `next` event with `detail: { requirementSetId: String, requirementTemplateId: String }`

**Naming Convention:**

- New Requirement Set: `"Vendor Program Label - Onboarding Set"`

## Step 5: Create and Link Requirement Group Components

### vendorProgramOnboardingRequirementGroupLinking

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingRequirementGroupLinking/`

**Purpose:** Step 5 - Create and link Vendor Program Group, Vendor Program Requirement Group, and Vendor Program Group Member.

**API:**

- `@api vendorProgramId` - Current vendor program ID
- `@api stageId` - Current stage ID
- `@api requirementSetId` - Requirement Set ID from Step 4 (optional)

**Key Features:**

- Checks for historical group members from Requirement Set
- Option to use historical values or create new
- Creates all three components with proper linking
- Uses naming convention for new components

**Properties:**

- `useHistorical` - Whether to use historical values
- `historicalMembers` - Historical group members from Requirement Set
- `hasHistoricalData` - Whether historical data exists
- `isLoading` - Loading state
- `nextDisabled` - Next button state

**Methods:**

- `checkHistoricalData()` - Checks for historical data from Requirement Set
- `handleUseHistoricalChange()` - Handles historical option toggle
- `handleCreateAndLink()` - Creates and links all components

**Dependencies:**

- `VendorOnboardingWizardController.getHistoricalGroupMembers()`
- `VendorOnboardingWizardController.createRequirementGroupComponents()`

**Events:**

- Fires `next` event with `detail: { groupMemberId: String }`

**Naming Conventions:**

- Vendor Program Group: `"Vendor Program Label - Vendor Program Group"`
- Requirement Group: `"Vendor Program Label - Requirement Group"`

## Step 6: Required Credentials (Conditional)

### vendorProgramOnboardingRequiredCredentials

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingRequiredCredentials/`

**Purpose:** Step 6 - Configure required credentials if needed (conditional Yes/No prompt).

**API:**

- `@api vendorProgramId` - Current vendor program ID
- `@api stageId` - Current stage ID

**Key Features:**

- Yes/No prompt: "Are Required Credentials needed?"
- If Yes: Shows credential management UI
- If No: Skips to next step
- Inline creation of `Required_Credential__c` records
- Data table showing existing credentials

**Properties:**

- `credentialsNeeded` - User's answer (null, true, false)
- `showCredentialsManagement` - Whether to show management UI
- `credentials` - List of credentials
- `newCredential` - New credential form data
- `showForm` - Form visibility
- `isLoading` - Loading state

**Methods:**

- `handleCredentialsNeededChange()` - Handles Yes/No selection
- `handleSkip()` - Skips to next step (No selected)
- `loadCredentials()` - Loads existing credentials
- `handleCreate()` - Creates new credential
- `handleFieldChange()` - Handles field changes
- `toggleForm()` - Shows/hides form

**Dependencies:**

- `OnboardingAppVendorProgramReqSvc.getRequiredCredentials()` (direct service call)
- `OnboardingAppVendorProgramReqSvc.createRequiredCredential()` (direct service call)

**Events:**

- Fires `next` event with `detail: { credentialsNeeded: Boolean, vendorProgramId: String }`

## Step 7: Training Requirements

### vendorProgramOnboardingTrainingRequirements

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingTrainingRequirements/`

**Purpose:** Step 7 - Configure training requirements using dual-listbox selection.

**API:**

- `@api vendorProgramId` - Current vendor program ID
- `@api stageId` - Current stage ID

**Key Features:**

- Inline creation of `Training_System__c` records
- Dual-listbox for selecting training requirements
- Moving items to "Selected for Group" sets `Is_Required__c = true`
- Moving items to "Available" sets `Is_Required__c = false`
- Real-time updates to bottom table showing required training requirements
- Data table with Training System name (flattened from relationship)

**Properties:**

- `trainingRequirements` - All training requirements for vendor program
- `selectedTrainingRequirementIds` - IDs selected in dual-listbox
- `newTrainingSystem` - New training system form data
- `showTrainingSystemForm` - Training system form visibility
- `isLoading` - Loading state
- `columns` - Data table column definitions

**Methods:**

- `loadTrainingRequirements()` - Loads training requirements
- `loadTrainingRequirementsWithPreservation()` - Reloads while preserving selection state
- `handleTrainingRequirementSelection()` - Handles dual-listbox changes
- `updateLocalStateForSelection()` - Updates local state immediately
- `persistSelectionChanges()` - Persists changes to database
- `handleSelectionError()` - Handles selection errors
- `handleCreateTrainingSystem()` - Creates new training system
- `handleCreateTrainingRequirement()` - Creates new training requirement
- `handleFieldChange()` - Handles field changes
- `toggleTrainingSystemForm()` - Shows/hides training system form

**Dependencies:**

- `OnboardingAppVendorProgramReqSvc.getTrainingRequirements()` (direct service call)
- `OnboardingAppVendorProgramReqSvc.createTrainingSystem()` (direct service call)
- `OnboardingAppVendorProgramReqSvc.createTrainingRequirement()` (direct service call)
- `OnboardingAppVendorProgramReqSvc.updateTrainingRequirementRequiredStatus()` (direct service call)

**Events:**

- Fires `next` event with `detail: { vendorProgramId: String }`

**Computed Properties:**

- `requiredTrainingRequirements` - Filtered list of required training requirements
- `hasRequiredTrainingRequirements` - Whether any required training requirements exist

**Note:** The component uses `Is_Required__c` field to track selection state, not the `Vendor_Customization__c` Master-Detail relationship.

## Step 8: Status Rules Engine

### vendorProgramOnboardingStatusRulesEngine

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingStatusRulesEngine/`

**Purpose:** Step 8 - Select or create Status Rules Engine with historical data detection.

**API:**

- `@api vendorProgramId` - Current vendor program ID
- `@api stageId` - Current stage ID
- `@api requirementSetId` - Requirement Set ID from Step 4 (optional)

**Key Features:**

- Multi-view component: `check`, `confirm`, `create`, `search`
- Checks for historical Status Rules Engines from Requirement Set
- Confirmation view with option to use existing or create new
- Search existing Status Rules Engines
- Create new Status Rules Engine with:
  - Name
  - Evaluation Logic (picklist)
  - Required Status (picklist)
  - Target Onboarding Status (picklist)
  - Optional: Requirement Group ID, Program Group ID

**Properties:**

- `currentView` - Current view state
- `historicalEngines` - Historical engines from Requirement Set
- `selectedEngineId` - Selected engine ID
- `selectedEngine` - Selected engine record
- `searchText` - Search input text
- `searchResults` - Search results
- `showCreateForm` - Create form visibility
- `newName` - New engine name
- `newEvaluationLogic` - Evaluation logic selection
- `newRequiredStatus` - Required status selection
- `newTargetOnboardingStatus` - Target status selection
- `evaluationLogicOptions` - Picklist options (via @wire)
- `requiredStatusOptions` - Picklist options (via @wire)
- `targetOnboardingStatusOptions` - Picklist options (via @wire)
- `isLoading` - Loading state

**Methods:**

- `checkHistoricalEngines()` - Checks for historical engines
- `handleEngineSelect()` - Handles engine selection
- `handleConfirmSelection()` - Confirms selected engine
- `handleMakeChanges()` - Creates new engine
- `handleSkipToCreate()` - Skips to create view
- `handleSearch()` - Searches for engines
- `handleCreateClick()` - Creates new engine
- `handleRowAction()` - Handles row action (select from search)
- `handleBack()` - Handles back navigation

**Dependencies:**

- `VendorOnboardingWizardController.getHistoricalStatusRulesEngines()`
- `VendorOnboardingWizardController.searchStatusRulesEngines()`
- `VendorOnboardingWizardController.createOnboardingStatusRulesEngine()`
- `VendorOnboardingWizardController.getEvaluationLogicPicklistValues()` (@wire)
- `VendorOnboardingWizardController.getRequiredStatusPicklistValues()` (@wire)
- `VendorOnboardingWizardController.getTargetOnboardingStatusPicklistValues()` (@wire)

**Events:**

- Fires `next` event with `detail: { statusRulesEngineId: String, vendorProgramId: String }`

**Computed Properties:**

- `isConfirmView` - Whether in confirm view
- `isCreateOrSearchView` - Whether in create/search view
- `historicalEngineOptions` - Radio group options for historical engines

## Step 9: Recipient Groups (Admin Only)

### vendorProgramOnboardingRecipientGroup

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingRecipientGroup/`

**Purpose:** Step 9 (Admin) - Create or select Recipient Groups, add members, and link to Vendor Program.

**API:**

- `@api vendorProgramId` - Current vendor program ID
- `@api stageId` - Current stage ID

**Key Features:**

- Multi-view component: `select`, `create`, `addMembers`
- Shows existing Recipient Groups for Vendor Program
- Option to use existing or create new
- Create `Recipient_Group__c` with Name and Group Type
- Add `Recipient_Group_Member__c` records using dual-listbox
- Link via `Vendor_Program_Recipient_Group__c`
- Data table showing current group members

**Properties:**

- `currentView` - Current view state
- `searchText` - Search input text
- `recipientGroups` - Search results
- `existingGroups` - Existing groups for vendor program
- `selectedRecipientGroupId` - Selected group ID
- `newGroupName` - New group name
- `newGroupType` - New group type (default: 'User')
- `groupTypeOptions` - Picklist options (via @wire)
- `createdGroupId` - Created group ID
- `assignableUsers` - Available users for members
- `selectedUserIds` - Selected user IDs for members
- `groupMembers` - Current group members
- `isLoading` - Loading state
- `nextDisabled` - Next button state
- `showCreateForm` - Create form visibility

**Methods:**

- `loadExistingGroups()` - Loads existing groups for vendor program
- `loadAssignableUsers()` - Loads assignable users
- `loadGroupMembers()` - Loads members for a group
- `searchGroups()` - Searches for recipient groups
- `handleGroupSelect()` - Handles group selection
- `createGroup()` - Creates new recipient group
- `handleUserSelection()` - Handles user selection in dual-listbox
- `addMembers()` - Adds members to group
- `linkGroupToVendorProgram()` - Links group to vendor program
- `handleUseExisting()` - Uses existing groups
- `handleCreateNew()` - Creates new group
- `handleBack()` - Handles back navigation

**Dependencies:**

- `VendorOnboardingWizardController.searchRecipientGroups()`
- `VendorOnboardingWizardController.createRecipientGroup()`
- `VendorOnboardingWizardController.createRecipientGroupMember()`
- `VendorOnboardingWizardController.createVendorProgramRecipientGroupLink()`
- `VendorOnboardingWizardController.getRecipientGroupsForVendorProgram()`
- `VendorOnboardingWizardController.getRecipientGroupMembers()`
- `VendorOnboardingWizardController.getAssignableUsers()`
- `VendorOnboardingWizardController.getGroupTypePicklistValues()` (@wire)

**Events:**

- Fires `next` event with `detail: { recipientGroupId: String, vendorProgramId: String }`

**Computed Properties:**

- `isSelectView` - Whether in select view
- `isCreateView` - Whether in create view
- `isAddMembersView` - Whether in add members view
- `hasExistingGroups` - Whether existing groups exist
- `groupOptions` - Radio group options
- `userOptions` - Dual-listbox user options
- `isAddMembersDisabled` - Whether add members button is disabled

**Note:** This step is Admin-only. Users skip to Step 10.

## Step 10: Communication Template Selection

### vendorProgramOnboardingCommunicationTemplate

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingCommunicationTemplate/`

**Purpose:** Step 10 - Select Communication Template, Recipient Group, and trigger condition.

**API:**

- `@api vendorProgramId` - Current vendor program ID
- `@api stageId` - Current stage ID
- `@api recipientGroupId` - Recipient Group ID from Step 9 (optional)

**Key Features:**

- Select `Communication_Template__c` from dropdown
- Select `Recipient_Group__c` from existing groups for vendor program
- Enter trigger condition (e.g., "Onboarding Status = 'Setup Complete'")
- Creates `Vendor_Program_Recipient_Group__c` link with template and condition
- Pre-selects recipient group from Step 9 if provided

**Properties:**

- `templates` - Available communication templates
- `recipientGroups` - Available recipient groups for vendor program
- `selectedTemplateId` - Selected template ID
- `selectedRecipientGroupId` - Selected recipient group ID
- `triggerCondition` - Trigger condition text
- `isLoading` - Loading state

**Methods:**

- `connectedCallback()` - Loads templates and recipient groups in parallel
- `handleTemplateChange()` - Handles template selection
- `handleRecipientGroupChange()` - Handles recipient group selection
- `handleTriggerConditionChange()` - Handles trigger condition input
- `handleSaveClick()` - Creates link with template and condition
- `handleBack()` - Handles back navigation
- `showToast()` - Shows toast notifications

**Dependencies:**

- `VendorOnboardingWizardController.getCommunicationTemplates()`
- `VendorOnboardingWizardController.getRecipientGroupsForVendorProgram()`
- `VendorOnboardingWizardController.createVendorProgramRecipientGroupWithTemplate()`

**Events:**

- Fires `next` event with `detail: { communicationTemplateId: String, recipientGroupId: String, triggerCondition: String, vendorProgramId: String }`

**Computed Properties:**

- `hasTemplates` - Whether templates exist
- `hasRecipientGroups` - Whether recipient groups exist
- `isFormValid` - Whether form is valid (all fields filled)
- `isSaveDisabled` - Whether save button is disabled
- `templateOptions` - Template dropdown options
- `recipientGroupOptions` - Recipient group dropdown options

## Step 10 (Final): Finalize Vendor Program

### vendorProgramOnboardingFinalize

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingFinalize/`

**Purpose:** Step 10 (Final) - Complete onboarding setup and navigate to Vendor Program.

**API:**

- `@api vendorProgramId` - Current vendor program ID
- `@api stageId` - Current stage ID

**Key Features:**

- Summary of completed steps
- Success message with checklist
- Navigation to Vendor Program record page
- Vendor Program remains in Draft status (activation happens separately)

**Properties:**

- `isLoading` - Loading state

**Methods:**

- `handleComplete()` - Navigates to Vendor Program record page
- `handleBack()` - Handles back navigation
- `showToast()` - Shows success toast

**Dependencies:**

- `NavigationMixin` for navigation

**Events:**

- Fires `next` event (final step)

**Note:** The Vendor Program is created in Draft status and can be activated later through the activation process.

## Component Context Passing

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

Components receive this context via props and can access the data they need.

## Common Patterns

### Base Class Pattern

All components extend `OnboardingStepBase` which provides:

- **Navigation:** Automatic footer navigation handling
- **Validation:** Automatic validation state dispatching
- **Toast:** Centralized `showToast()` utility
- **Titles:** Dynamic card title generation
- **Events:** Standardized event dispatching

### Information Boxes

All components display information boxes with:

- Context about what the step does
- Best practices for naming and configuration
- Examples where helpful

### Form Validation

- Required fields are clearly marked
- Next/Save buttons are disabled until form is valid
- Validation happens both client-side and server-side
- Components implement `get canProceed()` to return validation state
- Base class automatically dispatches validation state changes

### Loading States

- Loading spinners shown during async operations
- Buttons disabled during operations
- Error handling with `this.showToast()` for notifications

### Inline Creation

- Many components support inline creation of related records
- Forms toggle visibility
- Created records immediately available for selection

### Historical Data Reuse

- Components check for historical data from Requirement Sets
- Option to use existing or create new
- Naming conventions applied for new records

### Navigation Pattern

- Components use `this.dispatchNextEvent(detail)` for next navigation
- Components use `this.dispatchBackEvent()` for back navigation
- Events automatically configured with `bubbles: true, composed: true`
- Footer navigation handled automatically by base class

## Error Handling

All components use centralized error handling:

- Toast notifications for user feedback
- Console logging for debugging
- Graceful degradation when data is missing

## Performance Optimizations

- Parallel data loading using `Promise.all()`
- `@wire` with cacheable methods for picklist values
- Single data reloads instead of multiple
- Local state updates before API calls for immediate UI feedback
