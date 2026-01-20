# Lightning Web Components

## Core Flow Components

### onboardingApplicationFlow

**Location:** `force-app/main/default/lwc/onboardingApplicationFlow/`

**Purpose:** Main controller for the onboarding flow engine. Dynamically loads and manages onboarding stages based on metadata.

**Key Features:**

- Loads stages from `Onboarding_Application_Process__c`
- Tracks current stage index
- Handles navigation (next/back)
- Parallel loading of stages and process details
- Computed properties for current stage, component name, and context

**Error Handling:**

- Uses `c/utils.extractErrorMessage` and `ShowToastEvent` to surface Apex failures instead of failing silently

**API:**

- `@api processId` - ID of the onboarding process
- `@api vendorProgramId` - ID of the vendor program being onboarded

**Computed Properties:**

- `currentComponentName` - Component API name from current stage
- `currentStage` - Current stage record
- `componentContext` - Context object with vendorProgramId and stageId
- `currentStageLabel` - Display label for current stage
- `isFirst` - Whether on first stage
- `isLast` - Whether on last stage

**Methods:**

- `loadProcess()` - Loads stages and process details in parallel
- `handleNext()` - Advances to next stage
- `handleBack()` - Returns to previous stage

**Dependencies:**

- `OnboardingApplicationService.getStagesForProcess()`
- `OnboardingApplicationService.getProcessDetails()`

**Note:** This is a standalone flow engine component. The `onboardingFlowEngine` component is used by `vendorProgramOnboardingFlow` and includes progress persistence.

### onboardingFlowEngine

**Location:** `force-app/main/default/lwc/onboardingFlowEngine/`

**Purpose:** Alternative/legacy flow engine implementation with progress tracking.

**Key Features:**

- Similar to `onboardingApplicationFlow` but includes progress persistence
- Resumes from saved progress
- Tracks completion status
- **Status Display**: Uses `getUserFacingStage()` to display simplified Vendor Program statuses for end users
  - ⚠️ **ONLY for Vendor_Customization**c.Status**c** - NOT for Dealer Onboarding statuses
  - Maps technical statuses (Draft, In Process) to user-friendly stages (In Progress, Review Pending, Completed)
  - Admins see technical statuses unchanged

**API:**

- `@api processId` - ID of the onboarding process
- `@api vendorProgramId` - ID of the vendor program being onboarded

**Properties:**

- `userFacingStatus` - User-friendly status label (simplified for end users, technical for admins)

**Dependencies:**

- `OnboardingApplicationService.getStagesForProcess()`
- `OnboardingApplicationService.getProgress()`
- `OnboardingApplicationService.saveProgress()`
- `OnboardingApplicationService.getUserFacingStage()` - For Vendor Program status simplification

### onboardingStageRenderer

**Location:** `force-app/main/default/lwc/onboardingStageRenderer/`

**Purpose:** Dynamically renders stage-specific LWC components based on metadata.

**Key Features:**

- Dynamically instantiates components by API name using static conditional rendering
- Extracts individual props from context object for cleaner prop passing
- Handles navigation events from child components
- Supports 10+ different stage component types

**API:**

- `@api componentName` - API name of component to render
- `@api context` - Context object with vendorProgramId and stageId (extracted via getters)

**Computed Properties:**

- `vendorProgramId` - Extracted from context
- `stageId` - Extracted from context
- `showVendorProgramOnboardingVendor` - Boolean for vendor selection component
- `showVendorProgramOnboardingVendorProgramCreate` - Boolean for vendor program creation
- `showVendorProgramOnboardingVendorProgramGroup` - Boolean for program group component
- `showVendorProgramOnboardingVendorProgramRequirementGroup` - Boolean for requirement group component
- `showVendorProgramOnboardingVendorProgramRecipientGroup` - Boolean for recipient group component
- `showVendorProgramOnboardingRecipientGroup` - Boolean for recipient group management
- `showVendorProgramOnboardingRecipientGroupMembers` - Boolean for recipient group members
- `showVendorProgramOnboardingTrainingRequirements` - Boolean for training requirements
- `showVendorProgramOnboardingRequiredCredentials` - Boolean for required credentials
- `showVendorProgramOnboardingVendorProgramSearchOrCreate` - Boolean for search/create component
- `showVendorProgramOnboardingVendorProgramRequirements` - Boolean for vendor program requirements component
- `showVendorProgramOnboardingStatusRulesEngine` - Boolean for status rules engine component
- `showVendorProgramOnboardingStatusRuleBuilder` - Boolean for status rule builder component
- `showVendorProgramOnboardingCommunicationTemplate` - Boolean for communication template component
- `hasValidComponent` - Whether component name matches any known component

**Events:**

- `next` - Fired when child component requests next stage (passes event detail through)
- `back` - Fired when child component requests previous stage (passes event detail through)

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
- `vendorProgramOnboardingVendorProgramRequirements`
- `vendorProgramOnboardingStatusRulesEngine`
- `vendorProgramOnboardingStatusRuleBuilder`
- `vendorProgramOnboardingCommunicationTemplate`

### vendorProgramOnboardingFlow

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingFlow/`

**Purpose:** Vendor-specific wrapper that resolves the onboarding process for a vendor program and initializes the flow engine.

**Key Features:**

- Accepts `recordId` from Lightning record page (Vendor Program)
- Queries for associated onboarding process
- Injects process ID into flow engine
- Handles loading and error states

**API:**

- `@api recordId` - Vendor Program ID (from record page context)

**Dependencies:**

- `OnboardingApplicationService.getProcessIdForVendorProgram()`

**Usage:**
Add to a Vendor Program record page:

```xml
<c-vendor-program-onboarding-flow record-id={recordId}></c-vendor-program-onboarding-flow>
```

## Dashboard Components

### onboardingHomeDashboard

**Location:** `force-app/main/default/lwc/onboardingHomeDashboard/`

**Purpose:** Central home page dashboard for the Vendor Onboarding application. Provides a comprehensive command center with KPI summaries, work queues, analytics, and quick access to start new onboarding processes.

**Key Features:**

- **Tabbed Layout**: My Active Onboarding, Eligible Dealers, Vendor Programs, Team/Org Queue, Insights
- **KPI Summary Cards**: Active Dealer Onboarding, Completed This Period, Active Vendor Programs, Dealers Onboarded, Blocked/At Risk
- **Global Filters**: Time Range, Vendor, Vendor Program, View (My View, My Team, Org Wide)
- **Work Queue**: Reusable datatable with row highlighting (Red: Blocked, Yellow: At-Risk, Blue: Normal)
- **Vendor Program Grid**: Card layout showing program health metrics
- **Recent Activity Sidebar**: Timeline-style activity feed
- **Insights Tab**: Analytics and visualizations
- **Admin Shortcuts**: Permission-gated configuration shortcuts rendered via `onboardingAdminToolsPanel`
- Quick action buttons to start new onboarding:
  - Uses `onboardingVendorProgramWizard` for Vendor Program selection/creation and onboarding kickoff
  - Uses `onboardingDealerOnboardingModal` for Account (Dealer) selection before launching the Account onboarding quick action
- Row actions for viewing, resuming, and viewing requirements
- Refresh functionality to reload data

**Child Components:**

- `onboardingKpiRow` - KPI summary cards
- `onboardingFilterChips` - Global filters
- `onboardingWorkQueue` - Reusable work queue table
- `onboardingVendorProgramGrid` - Vendor program card grid
- `onboardingRecentActivity` - Activity feed sidebar
- `onboardingInsights` - Analytics and charts
- `onboardingVendorProgramWizard` - Vendor Program selection/creation + onboarding kickoff modal
- `onboardingDealerOnboardingModal` - Dealer Account selection modal for starting onboarding
- `onboardingAdminToolsPanel` - Admin configuration shortcuts and tools

**Status Handling:**

- **Dealer Onboarding Status** (`OnboardingDTO.Status`): Displayed as-is from `Onboarding__c.Onboarding_Status__c` - no simplification
- **Vendor Program Status** (`vp.Status__c`): Shown in dropdown labels for vendor program selection (technical status)

**Targets:**

- `lightning__HomePage` - Can be added to Lightning Home pages
- `lightning__AppPage` - Can be added to Lightning App pages

**Data Sources:**

- `OnboardingHomeDashboardController.getMyActiveOnboarding(timeFilter, vendorIds, programIds, viewFilter)` - Active onboarding with filters
- `OnboardingHomeDashboardController.getOnboardingSummary(timeFilter, vendorIds, programIds, viewFilter)` - Summary statistics with filters
- `OnboardingHomeDashboardController.getEligibleAccounts(timeFilter, vendorIds, programIds)` - Accounts that can start new onboarding
- `OnboardingHomeDashboardController.getRecentActivity(recordLimit, timeFilter, vendorIds, programIds)` - Recent activity with filters
- `OnboardingHomeDashboardController.getVendorProgramMetrics(timeFilter, vendorIds)` - Vendor program health metrics
- `OnboardingHomeDashboardController.getBlockedOnboardingCount(timeFilter, vendorIds, programIds)` - Blocked/at-risk count
- `OnboardingHomeDashboardController.getTeamOnboarding(viewFilter, timeFilter, vendorIds, programIds)` - Team/org queue
- `OnboardingHomeDashboardController.getOnboardingWithBlockingInfo(onboardingIds)` - Onboarding with blocking info
- `OnboardingHomeDashboardController.getVendors()` - Vendor list for filters
- `OnboardingHomeDashboardController.getVendorPrograms()` - Vendor program list for filters

**Design Decisions:**

- **Ownership Model**: Uses `OnboardingAccessService` to resolve ownership based on Account Owner and Territory Assignments
- **View Filters**: Supports MY_VIEW (current user), MY_TEAM (role hierarchy), ORG_WIDE (all accessible)
- **Filter State**: Centralized filter state object (`filters`) that applies across all tabs
- **Sharing**: Controlled by Account parent (ControlledByParent), so all users with Account access can see onboarding records
- **Blocking Detection**: Uses `OnboardingBlockingDetectionService` to identify blocked/at-risk records
- Respects Account sharing rules through `with sharing` class

**Column Definitions:**

- **Active Onboarding Table:** Account, Vendor Program, Status, Last Modified, Created By, Actions (View, Resume)
- **Eligible Accounts Table:** Account Name, Territory, Region, Eligible Vendor Count, Actions (Start Onboarding, View Account)

**Methods:**

- `handleStartNewOnboarding()` - Opens modal to select account for new onboarding
- `handleActiveOnboardingRowAction(event)` - Handles row actions (View, Resume)
- `handleEligibleAccountsRowAction(event)` - Handles row actions (Start Onboarding, View Account)
- `navigateToRecord(recordId)` - Navigates to record detail page
- `startOnboardingForAccount(accountId)` - Navigates to account record with Quick Action to start onboarding
- `handleRefresh()` - Refreshes dashboard data

**Dependencies:**

- `OnboardingHomeDashboardController` - Apex controller for dashboard data
- `OnboardingEligibilityService` - Service for determining eligible vendors (used indirectly)

**Usage:**

1. Create a Lightning Home Page in Setup → Lightning App Builder
2. Add the `onboardingHomeDashboard` component to the page
3. Save and activate the home page
4. Set as default home page in your app settings

**Example:**
The component automatically loads data when added to a home page. Filters can be applied via the `onboardingFilterChips` component, and all tabs will update accordingly.

### onboardingKpiRow

**Location:** `force-app/main/default/lwc/onboardingKpiRow/`

**Purpose:** Displays KPI summary cards in a grid layout.

**Key Features:**

- 5-6 KPI cards: Active Dealer Onboarding, Completed This Period, Active Vendor Programs, Dealers Onboarded, Blocked/At Risk
- Each card shows value, label, optional trend indicator
- Clickable cards dispatch `tileclick` event with metric key
- Uses SLDS styling with color-coded themes

**API Properties:**

- `@api summary` - Onboarding summary map
- `@api vendorSummary` - Vendor program summary
- `@api blockedCount` - Blocked/at-risk count

**Events:**

- `tileclick` - Dispatched when a KPI card is clicked (detail.metricKey contains the metric identifier)

### onboardingFilterChips

**Location:** `force-app/main/default/lwc/onboardingFilterChips/`

**Purpose:** Global filter component for the dashboard.

**Key Features:**

- Time Range filter (Last 30 Days, Last 90 Days, Year to Date, All Time)
- Vendor single-select combobox
- Vendor Program single-select combobox
- View filter (My View, My Team, Org Wide) - permission-gated
- Dispatches `filterchange` event when filters change

**API Properties:**

- `@api timeFilter` - Current time filter value
- `@api vendorFilter` - Current vendor filter values
- `@api programFilter` - Current program filter values
- `@api viewFilter` - Current view filter
- `@api showTeamView` - Whether to show team/org view options

**Wire Methods:**

- `@wire(getVendors)` - Load vendor options
- `@wire(getVendorPrograms)` - Load vendor program options

**Events:**

- `filterchange` - Dispatched when any filter changes (detail contains all filter values)

### onboardingWorkQueue

**Location:** `force-app/main/default/lwc/onboardingWorkQueue/`

**Purpose:** Reusable datatable component for displaying onboarding records with visual indicators.

**Key Features:**

- Row highlighting: Red border for blocked, Yellow for at-risk, Blue for normal
- Columns: Account, Vendor Program, Status, Age (days), Last Modified, Actions
- Action buttons: View, Resume, Requirements
- Shows blocking indicators and tooltips

**API Properties:**

- `@api records` - Array of onboarding records
- `@api showBlockingIndicators` - Whether to show blocking info
- `@api columns` - Column definitions (optional, has defaults)

**Events:**

- `view` - Dispatched when View action clicked
- `resume` - Dispatched when Resume action clicked
- `viewrequirements` - Dispatched when Requirements action clicked

### onboardingVendorProgramGrid

**Location:** `force-app/main/default/lwc/onboardingVendorProgramGrid/`

**Purpose:** Card grid layout for displaying vendor program health metrics.

**Key Features:**

- Card grid layout for vendor programs
- Each card shows: Program name, Vendor, Status badge, Dealer counts, Requirement progress bar
- Health indicators: Rules Engine status, Dependencies status
- Action buttons: View Program, Launch Wizard

**API Properties:**

- `@api programs` - Array of vendor program metrics

**Events:**

- `viewprogram` - Dispatched when View Program clicked
- `launchwizard` - Dispatched when Launch Wizard clicked

### onboardingRecentActivity

**Location:** `force-app/main/default/lwc/onboardingRecentActivity/`

**Purpose:** Timeline-style activity feed component.

**Key Features:**

- Timeline-style activity feed
- Shows: Time ago, Actor, Activity summary, Link to record
- Color-coded: Green (completions), Orange (blocks), Blue (neutral)
- Vertical timeline with connecting lines

**API Properties:**

- `@api activities` - Array of activity records

### onboardingInsights

**Location:** `force-app/main/default/lwc/onboardingInsights/`

**Purpose:** Analytics and visualization component.

**Key Features:**

- Status distribution chart (donut or stacked bar)
- Funnel visualization (Not Started → In Progress → Pending → Complete)
- Vendor program metrics chart
- Uses `lightning-chart` or custom SVG

**API Properties:**

- `@api summary` - Onboarding summary data
- `@api vendorProgramMetrics` - Vendor program metrics

## Management Components

### onboardingAppHeaderBar

**Location:** `force-app/main/default/lwc/onboardingAppHeaderBar/`

**Purpose:** Generic header bar component for versioned records with activation/deactivation capabilities.

**Key Features:**

- Displays record status and active state
- Provides activate/deactivate functionality
- Shows last modified date
- Menu for clone and create new actions
- Accessible keyboard navigation
- Form change tracking

**API:**

- `@api recordId` - Record ID
- `@api objectApiName` - Object API name (e.g., 'Vendor_Customization\_\_c')
- `@api statusFieldApiName` - Status field API name (default: 'Status\_\_c')
- `@api isActiveFieldApiName` - Active field API name (default: 'Active\_\_c')
- `@api lastModifiedFieldApiName` - Last modified field (default: 'LastModifiedDate')

**Methods:**

- `handleSave()` - Saves record via lightning-record-edit-form
- `handleActivate()` - Activates record via OnboardingAppActivationService
- `handleDeactivate()` - Deactivates record
- `handleFormChange()` - Tracks unsaved changes
- `toggleMenu()` - Opens/closes action menu

**Dependencies:**

- `OnboardingAppActivationService.activate()` (direct service call)
- Lightning UI Record API (`getRecord`, `updateRecord`)

### onboardingAppVendorProgramECCManager

**Location:** `force-app/main/default/lwc/onboardingAppVendorProgramECCManager/`

**Purpose:** Manages External Contact Credentials (ECC) for vendor programs.

**Key Features:**

- Displays required credentials in data table
- Links credential types to required credentials
- Creates new credential types
- Modal for credential type creation

**API:**

- `@api recordId` - Vendor_Customization\_\_c ID

**Methods:**

- `loadData()` - Loads required credentials and available credential types in parallel
- `handleRowAction()` - Handles manage action from data table
- `handleLinkCredential()` - Links credential type to required credential
- `handleCreateCredentialType()` - Creates new credential type

**Dependencies:**

- `OnboardingAppECCService.getRequiredCredentials()` (direct service call)
- `OnboardingAppECCService.getAvailableCredentialTypes()` (direct service call)
- `OnboardingAppECCService.createCredentialType()` (direct service call)
- `OnboardingAppECCService.linkCredentialTypeToRequiredCredential()` (direct service call)

### onboardingAppRequirementSetupWizard

**Location:** `force-app/main/default/lwc/onboardingAppRequirementSetupWizard/`

**Purpose:** Wizard for setting up onboarding requirements.

### onboardingStatusRulesManager

**Location:** `force-app/main/default/lwc/onboardingStatusRulesManager/`

**Purpose:** Manages status rules configuration (currently minimal implementation).

### onboardingStatusRuleList

**Location:** `force-app/main/default/lwc/onboardingStatusRuleList/`

**Purpose:** Displays list of status rules.

### requirementConditionsList

**Location:** `force-app/main/default/lwc/requirementConditionsList/`

**Purpose:** Displays and manages requirement conditions (Onboarding_Status_Rule\_\_c records) for a rules engine.

**Key Features:**

- Loads and displays rule conditions for a given status rule engine
- Handles deletion with automatic refresh via `refreshApex`/fallback reload
- Emits bubbling `error` events with user-friendly messages (using `c/utils.extractErrorMessage`) so parents can centralize toast handling
- Maps requirement name from relationship (Vendor_Program_Requirement\_\_r.Name)

**API Properties:**

- `ruleId` (@api) - Rules engine ID to load conditions for

**Properties:**

- `conditions` (@track) - Array of rule conditions with mapped requirementName
- `wiredConditionsResult` - Stored wire result for refreshApex

**Columns:**

- Sequence (Sequence\_\_c) - Number type
- Requirement (requirementName) - Mapped from Vendor_Program_Requirement\_\_r.Name
- Delete button - Destructive variant

**Methods:**

- `wiredConditions(result)` - Wire adapter handler for getConditions
  - Stores result for refreshApex
  - Maps data to include requirementName from relationship
  - Dispatches error event on failure
- `handleRowAction(event)` - Handles row action button clicks
  - Checks for 'delete' action
  - Calls deleteCondition Apex method
  - Refreshes data using refreshApex or fallback refreshData
- `addCondition()` - Placeholder for adding conditions (shows alert - TODO)
- `refreshData()` - Fallback refresh method if wire result unavailable
  - Calls getConditions imperatively
  - Maps requirement names
  - Dispatches error event on failure

**Dependencies:**

- `OnboardingStatusRuleController.getConditions()` - Loads rule conditions via @wire adapter
  - Parameter: `ruleId` (Id)
  - Returns list with Vendor_Program_Requirement\_\_r.Name relationship
- `OnboardingStatusRuleController.deleteCondition()` - Deletes a rule condition
  - Parameter: `conditionId` (Id)

**Events:**

- `error` - Dispatched on Apex errors with detail.message

**Usage:**
Used within rules management UI to display and manage individual rule conditions for a status rules engine.

### vendorProgramHighlights

**Location:** `force-app/main/default/lwc/vendorProgramHighlights/`

**Purpose:** Displays highlights/summary information for vendor programs.

## Vendor Program Onboarding Wizard Components

**📖 See [Vendor Program Onboarding Wizard Components](./vendor-program-onboarding-wizard-components.md) for comprehensive documentation of all wizard components.**

### onboardingStepBase (Base Class)

**Location:** `force-app/main/default/lwc/onboardingStepBase/`

**Purpose:** Base class that provides common functionality for all onboarding step components, eliminating code duplication and standardizing patterns.

**Key Features:**

- Footer navigation event listeners (`footernavnext`, `footernavback`)
- Validation state dispatching (`validationchanged` event)
- Toast notification utility (`showToast`)
- Dynamic card title generation (`cardTitle` getter)
- Standardized event dispatching (`dispatchNextEvent`, `dispatchBackEvent`)

**API:**

- `@api stepNumber` - Step number for card title generation

**Properties:**

- `stepName` - Step name for card title (must be set in child components)

**Methods:**

- `connectedCallback()` - Sets up event listeners and dispatches initial validation state
- `setupFooterNavigation()` - Configures footer navigation listeners
- `handleFooterNextClick()` - Handles footer Next button clicks
- `handleFooterBackClick()` - Handles footer Back button clicks
- `dispatchValidationState()` - Dispatches validation state to flow engine
- `showToast(title, message, variant)` - Shows toast notifications
- `dispatchNextEvent(detail)` - Dispatches next event with proper configuration
- `dispatchBackEvent()` - Dispatches back event with proper configuration

**Required Overrides:**

- `get canProceed()` - Must return boolean indicating if step can proceed
- `proceedToNext()` - Must dispatch next event with appropriate data

**Computed Properties:**

- `cardTitle` - Automatically generates "Step {N}: {stepName}"

**Usage:**
All 14 wizard step components extend this base class. See individual component documentation for implementation details.

**Benefits:**

- Eliminates ~700+ lines of duplicate code
- Standardizes navigation, validation, and event handling patterns
- Ensures consistency across all steps
- Makes adding new steps easier

The Vendor Program Onboarding Wizard consists of 14 steps, each implemented as a separate LWC component that extends `onboardingStepBase`:

1. **vendorProgramOnboardingVendor** - Select or create vendor
2. **vendorProgramOnboardingVendorProgramSearchOrCreate** - Search or create vendor program with Label, Retail Option, Business Vertical
3. **vendorProgramOnboardingRequirementSetOrCreate** - Select Requirement Set or create requirements with inline templates
4. **vendorProgramOnboardingRequirementGroupLinking** - Link Requirement Group components
5. **vendorProgramOnboardingRequiredCredentials** - Configure required credentials (conditional)
6. **vendorProgramOnboardingTrainingRequirements** - Configure training requirements
7. **vendorProgramOnboardingStatusRulesEngine** - Select or create Status Rules Engine
8. **vendorProgramOnboardingRecipientGroup** - Create/manage Recipient Groups (Admin only)
9. **vendorProgramOnboardingCommunicationTemplate** - Link Communication Template with Recipient Group and trigger condition
10. **vendorProgramOnboardingFinalize** - Complete onboarding setup and navigate to vendor program record

**Detailed Stage Component Documentation:**

### vendorProgramOnboardingFinalize

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingFinalize/`

**Purpose:** Final step of vendor program onboarding wizard. Completes the onboarding process and navigates to the vendor program record.

**Key Features:**

- Always allows proceeding (canProceed always returns true)
- Overrides footer Next button to trigger completion
- Shows success toast on completion
- Automatically navigates to vendor program record detail page

**API Properties:**

- `vendorProgramId` (@api) - Vendor Program ID to navigate to after completion
- `stageId` (@api) - Current stage ID (from flow engine)

**Methods:**

- `handleFooterNextClick()` - Overrides base class to trigger handleComplete when Next clicked
- `canProceed` (getter) - Always returns true (finalize step always allows proceeding)
- `proceedToNext()` - Not used (handleComplete handles navigation directly)
- `handleComplete()` - Completes onboarding process
  - Shows success toast: "Vendor Program Onboarding completed successfully!"
  - Navigates to vendor program record detail page using NavigationMixin

**Inheritance:**

- Extends `OnboardingStepBase` for common step functionality
- Uses `NavigationMixin` for navigation

**Usage:**
Final step in the vendor program onboarding wizard flow. Automatically displayed as the last stage when configured in the onboarding process.

All components follow a consistent pattern and are dynamically rendered by `onboardingStageRenderer`.

## Stage Components (Legacy/Other)

### vendorProgramOnboardingVendor

**Purpose:** Stage component for selecting/creating a vendor.

**Context:**

- `vendorProgramId` - Current vendor program ID
- `stageId` - Current stage ID

**Note:** See [Vendor Program Onboarding Wizard Components](./vendor-program-onboarding-wizard-components.md) for full documentation.

### vendorProgramOnboardingVendorProgramSearchOrCreate

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingVendorProgramSearchOrCreate/`

**Purpose:** Stage component for searching or creating a vendor program. Step 2 in the vendor onboarding wizard flow.

**Key Features:**

- Search for existing vendor programs by name
- Create new vendor program records
- Radio button selection for existing programs
- Input field for creating new programs
- Dispatches 'next' event with selected/created vendor program ID

**API:**

- `@api vendorId` - Vendor ID from previous step (required for creating new programs)

**Properties:**

- `searchText` - Search input text for vendor programs
- `programs` - List of search results
- `selectedProgramId` - Currently selected program ID
- `newProgramName` - Name for new program being created
- `nextDisabled` - Controls Next button state (disabled until program selected/created)

**Methods:**

- `handleSearchChange(event)` - Updates search text from input
- `handleNewProgramChange(event)` - Updates new program name from input
- `searchVendorPrograms()` - Calls Apex to search for vendor programs
- `handleProgramSelect(event)` - Handles radio button selection of existing program
- `createProgram()` - Creates new vendor program via Apex
- `proceedNext()` - Dispatches 'next' event with vendor program ID

**Computed Properties:**

- `programOptions` - Maps programs array to radio group options format

**Dependencies:**

- `VendorOnboardingWizardController.searchVendorPrograms()`
- `VendorOnboardingWizardController.createVendorProgram()`

**Events:**

- Fires `next` event with `detail: { vendorProgramId: String }`

### vendorProgramOnboardingVendorProgramCreate

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingVendorProgramCreate/`

**Purpose:** Stage component for finalizing vendor program setup. Step 5 in the vendor onboarding wizard flow. Links the vendor program to vendor, program group, and requirement group.

**Key Features:**

- Finalizes vendor program by linking all related entities
- Uses lightning-record-form for editing vendor program details
- Dispatches 'next' event after finalization

**API:**

- `@api vendorProgramId` - Vendor program ID to finalize
- `@api vendorId` - Vendor ID to link
- `@api programGroupId` - Program group ID to link
- `@api requirementGroupId` - Requirement group ID to link

**Properties:**

- `nextDisabled` - Controls button state during finalization

**Methods:**

- `finalizeProgram()` - Calls Apex to finalize vendor program by linking all entities. Disables button during operation, then dispatches 'next' event

**Dependencies:**

- `VendorOnboardingWizardController.finalizeVendorProgram()`

**Events:**

- Fires `next` event with `detail: { vendorProgramId: String }` after successful finalization

**Note:** This component uses a lightning-record-form for editing, but the actual finalization (linking entities) happens via the `finalizeProgram()` method which calls the Apex controller.

### vendorProgramOnboardingVendorProgramGroup

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingVendorProgramGroup/`

**Purpose:** Stage component for selecting or creating a vendor program group. Step 3 in the vendor onboarding wizard flow.

**Key Features:**

- Search for existing vendor program groups by name
- Create new vendor program group records with required fields visible
- Radio button selection for existing groups
- Toggle button to show/hide create form
- Form validation ensuring all required fields are filled
- Compact information box with context and naming best practices

**Required Fields (for Create):**

- `Name` - Text input (required)
- `Label__c` - Text input (required, auto-filled from Name if empty)
- `Logic_Type__c` - Combobox with picklist values dynamically fetched from Salesforce (required)

**Properties:**

- `searchText` - Search input text for vendor program groups
- `groups` - List of search results
- `selectedGroupId` - Currently selected vendor program group ID
- `newGroupName` - Name for new group being created
- `newGroupLabel` - Label for new group being created
- `newGroupLogicType` - Logic type for new group being created
- `logicTypeOptions` - Picklist options for Logic Type (loaded via @wire)
- `nextDisabled` - Controls Next button state (disabled until group selected/created)
- `showCreateForm` - Controls create form visibility

**Methods:**

- `handleSearchChange(event)` - Updates search text from input
- `handleNewGroupChange(event)` - Updates new group name and auto-fills label
- `handleNewGroupLabelChange(event)` - Updates new group label
- `handleLogicTypeChange(event)` - Updates logic type selection
- `searchGroups()` - Calls Apex to search for vendor program groups
- `handleGroupSelect(event)` - Handles radio button selection of existing group
- `createGroup()` - Creates new vendor program group via Apex with all required fields
- `proceedNext()` - Dispatches 'next' event with vendor program group ID (validates selection first)
- `toggleCreateForm()` - Shows/hides create form
- `validateCreateForm()` - Validates create form and enables/disables Next button
- `showToast(title, message, variant)` - Displays toast notifications

**Computed Properties:**

- `groupOptions` - Maps groups array to radio group options format
- `createButtonLabel` - Dynamic button label based on form state (uses getter instead of ternary expression)

**Dependencies:**

- `VendorOnboardingWizardController.searchVendorProgramGroups()`
- `VendorOnboardingWizardController.createVendorProgramGroup()`
- `VendorOnboardingWizardController.getLogicTypePicklistValues()` (cacheable @wire)

**Events:**

- Fires `next` event with `detail: { programGroupId: String }`

**Validation:**

- Service layer validates required fields and throws exceptions if missing
- Client-side validation ensures all fields are filled before creation

### vendorProgramOnboardingVendorProgramRequirementGroup

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingVendorProgramRequirementGroup/`

**Purpose:** Stage component for selecting or creating a vendor program requirement group.

**Key Features:**

- Search for existing requirement groups by name
- Create new requirement group records with required fields visible
- Radio button selection for existing groups
- Toggle button to show/hide create form
- Form validation ensuring all required fields are filled
- Compact information box with context and naming best practices

**Required Fields (for Create):**

- `Name` - Text input (required)
- `Status__c` - Combobox with picklist values dynamically fetched from Salesforce (required)

**Properties:**

- `searchText` - Search input text for requirement groups
- `groups` - List of search results
- `selectedGroupId` - Currently selected requirement group ID
- `newGroupName` - Name for new group being created
- `newGroupStatus` - Status for new group being created (defaults to 'Active')
- `statusOptions` - Picklist options for Status (loaded via @wire)
- `nextDisabled` - Controls Next button state
- `showCreateForm` - Controls create form visibility
- `templatesToLink` - Templates to link (passed via @api)

**Methods:**

- `handleSearchChange(event)` - Updates search text from input
- `handleNewGroupChange(event)` - Updates new group name
- `handleStatusChange(event)` - Updates status selection
- `searchGroups()` - Calls Apex to search for requirement groups
- `handleGroupSelect(event)` - Handles radio button selection
- `createGroup()` - Creates new requirement group with Name and Status
- `proceedNext()` - Dispatches 'next' event with requirement group ID
- `toggleCreateForm()` - Shows/hides create form
- `validateCreateForm()` - Validates create form
- `showToast(title, message, variant)` - Displays toast notifications

**Computed Properties:**

- `groupOptions` - Maps groups array to radio group options format
- `createButtonLabel` - Dynamic button label based on form state

**Dependencies:**

- `VendorOnboardingWizardController.searchVendorProgramRequirementGroups()`
- `VendorOnboardingWizardController.createVendorProgramRequirementGroup()`
- `VendorOnboardingWizardController.getStatusPicklistValues()` (cacheable @wire) Step 4 in the vendor onboarding wizard flow.

**Key Features:**

- Search for existing requirement groups by name
- Create new requirement group records
- Radio button selection for existing groups
- Input field for creating new groups
- Dispatches 'next' event with selected/created requirement group ID

**API:**

- `@api templatesToLink` - Array of template IDs to link (optional, for future use)

**Properties:**

- `searchText` - Search input text for requirement groups
- `groups` - List of search results
- `selectedGroupId` - Currently selected group ID
- `newGroupName` - Name for new group being created
- `nextDisabled` - Controls Next button state (disabled until group selected/created)

**Methods:**

- `handleSearchChange(event)` - Updates search text from input
- `handleNewGroupChange(event)` - Updates new group name from input
- `searchGroups()` - Calls Apex to search for requirement groups
- `handleGroupSelect(event)` - Handles radio button selection of existing group
- `createGroup()` - Creates new requirement group via Apex
- `proceedNext()` - Dispatches 'next' event with requirement group ID

**Computed Properties:**

- `groupOptions` - Maps groups array to radio group options format

**Dependencies:**

- `VendorOnboardingWizardController.searchVendorProgramRequirementGroups()`
- `VendorOnboardingWizardController.createVendorProgramRequirementGroup()`

**Events:**

- Fires `next` event with `detail: { requirementGroupId: String }`

### vendorProgramOnboardingVendorProgramRecipientGroup

**Purpose:** Stage component for assigning a recipient group.

### vendorProgramOnboardingRecipientGroup

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingRecipientGroup/`

**Purpose:** Stage component for selecting or creating a recipient group. Used in the vendor onboarding wizard flow for recipient group configuration.

**Key Features:**

- Search for existing recipient groups by name
- Create new recipient group records with required fields visible
- Radio button selection for existing groups
- Toggle button to show/hide create form
- Form validation ensuring all required fields are filled
- Compact information box with context and naming best practices

**Required Fields (for Create):**

- `Name` - Text input (required)
- `Group_Type__c` - Combobox with picklist values dynamically fetched from Salesforce (required)

**API:**

- `@api vendorProgramId` - Vendor program ID (required for creating new groups)

**Properties:**

- `searchText` - Search input text for recipient groups
- `recipientGroups` - List of search results
- `selectedRecipientGroupId` - Currently selected recipient group ID
- `newGroupName` - Name for new group being created
- `newGroupType` - Group type for new group being created (defaults to 'User')
- `groupTypeOptions` - Picklist options for Group Type (loaded via @wire)
- `nextDisabled` - Controls Next button state (disabled until group selected/created)
- `showCreateForm` - Controls create form visibility

**Methods:**

- `handleSearchChange(event)` - Updates search text from input
- `handleNewGroupChange(event)` - Updates new group name from input
- `handleGroupTypeChange(event)` - Updates group type selection
- `searchGroups()` - Calls Apex to search for recipient groups
- `handleGroupSelect(event)` - Handles radio button selection of existing group
- `createGroup()` - Creates new recipient group via Apex with Name and Group Type
- `proceedNext()` - Dispatches 'next' event with recipient group ID
- `toggleCreateForm()` - Shows/hides create form
- `validateCreateForm()` - Validates create form
- `showToast(title, message, variant)` - Displays toast notifications

**Computed Properties:**

- `groupOptions` - Maps recipient groups array to radio group options format
- `createButtonLabel` - Dynamic button label based on form state

**Dependencies:**

- `VendorOnboardingWizardController.searchRecipientGroups()`
- `VendorOnboardingWizardController.createRecipientGroup()`
- `VendorOnboardingWizardController.getGroupTypePicklistValues()` (cacheable @wire)

**Events:**

- Fires `next` event with `detail: { recipientGroupId: String }`

### vendorProgramOnboardingRecipientGroupMembers

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingRecipientGroupMembers/`

**Purpose:** Stage component for adding members to a recipient group. Manages recipient group membership configuration.

### vendorProgramOnboardingRequiredCredentials

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingRequiredCredentials/`

**Purpose:** Stage component for managing required credentials. Allows configuration of credential requirements for vendor programs.

### vendorProgramOnboardingTrainingRequirements

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingTrainingRequirements/`

**Purpose:** Stage component for managing training requirements. Allows configuration of training requirements for vendor programs.

### vendorProgramOnboardingRequirementSet

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingRequirementSet/`

**Purpose:** Stage component (Step 3) for selecting or creating a requirement set. Displays requirement sets in a hierarchical tree grid with search functionality.

**Key Features:**

- Search requirement sets by name
- Tree grid display showing requirement sets with template counts
- Create new requirement set with Name and optional Display Label
- Select existing requirement set
- Expandable/collapsible tree grid rows
- Auto-selects requirement set if vendor program already has one linked

**API Properties:**

- `vendorProgramId` (@api) - Vendor Program ID (from flow engine)
- `stageId` (@api) - Current stage ID

**Properties:**

- `searchText` (@track) - Search input text
- `searchTimeout` - Timeout for debounced search
- `requirementSetHierarchy` (@track) - Tree grid data with requirement sets
- `selectedRequirementSetId` (@track) - Selected requirement set ID
- `selectedRequirementSetName` (@track) - Selected requirement set name for display
- `showCreateForm` (@track) - Controls create form visibility
- `nextDisabled` (@track) - Controls Next button state
- `newRequirementSetName` (@track) - Name for new requirement set
- `newRequirementSetDisplayLabel` (@track) - Optional display label for new set
- `isHierarchyLoading` (@track) - Loading state indicator
- `expandedRows` (@track) - Array of expanded row keys
- `selectedRows` (@track) - Selected row IDs for tree grid

**Columns:**

- Display Label (displayName) - Text with row class styling, wrapText enabled
- Status (status) - Text with status class styling
- Templates (templateCount) - Number showing count of templates in set

**Methods:**

- `wiredRequirementSets({ error, data })` - Wire adapter handler for getRequirementSetsWithTemplates
- `handleSearchChange(event)` - Updates search text and triggers debounced search
- `handleRowSelection(event)` - Handles tree grid row selection
- `toggleCreateForm()` - Shows/hides create form
- `handleCreateFormChange(event)` - Updates new requirement set fields
- `createRequirementSet()` - Creates new requirement set via Apex
- `proceedNext()` - Dispatches 'next' event with requirementSetId
- `handleExpandAll()` - Expands all tree grid rows
- `handleCollapseAll()` - Collapses all tree grid rows

**Dependencies:**

- `VendorOnboardingWizardController.getRequirementSetsWithTemplates()` - Loads requirement sets via @wire
- `VendorOnboardingWizardController.searchRequirementSetsWithTemplates()` - Searches requirement sets
- `VendorOnboardingWizardController.createOnboardingRequirementSet()` - Creates new requirement set

**Events:**

- Fires `next` event with `detail: { requirementSetId: String }`

### vendorProgramOnboardingRequirementSetOrCreate

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingRequirementSetOrCreate/`

**Purpose:** Stage component (Step 3 alternative) for selecting requirement set or creating requirements with inline templates. Provides flexible workflow for requirement set management.

**Key Features:**

- **Multiple Views**: search, confirm, create, createRequirements, confirmRequirements
- Search existing requirement sets
- Link requirement set to vendor program
- Create requirement set from existing template
- Inline template creation during requirement set creation
- Create requirements from templates automatically

**API Properties:**

- `vendorProgramId` (@api) - Vendor Program ID
- `stageId` (@api) - Current stage ID
- `stepNumber` (@api) - Step number in wizard
- `requirementSetId` (@api) - Existing requirement set ID (from context when resuming)

**Properties:**

- `currentView` (@track) - Current view state ('search', 'confirm', 'create', 'createRequirements', 'confirmRequirements')
- `searchText` (@track) - Search input text
- `requirementSets` (@track) - Search results for requirement sets
- `selectedRequirementSetId` (@track) - Selected requirement set ID
- `selectedRequirementSet` (@track) - Selected requirement set object
- `templates` (@track) - Templates in selected requirement set
- `createdRequirements` (@track) - Created requirements for confirmation
- `nextDisabled` (@track) - Controls Next button state
- `isLoading` (@track) - Loading state indicator
- `showTemplateForm` (@track) - Controls inline template form visibility
- `newTemplate` (@track) - New template form data
- `currentRequirementSetId` (@track) - Requirement set ID for inline template creation

**Methods:**

- `handleSearchChange(event)` - Updates search text and searches requirement sets
- `handleRequirementSetSelect(event)` - Selects requirement set and loads templates
- `handleLinkRequirementSet()` - Links selected requirement set to vendor program
- `handleCreateFromExisting()` - Creates new requirement set from existing template
- `handleCreateNewSet()` - Shows create new set view
- `handleCreateRequirementSet()` - Creates new requirement set
- `handleAddTemplate()` - Shows inline template creation form
- `handleCreateTemplate()` - Creates template inline during set creation
- `handleCreateRequirements()` - Creates requirements from templates
- `handleConfirm()` - Confirms and proceeds to next step
- `handleBack()` - Returns to previous view
- Template form handlers for inline template creation

**Dependencies:**

- `VendorOnboardingWizardController.searchOnboardingRequirementSets()` - Searches requirement sets
- `VendorOnboardingWizardController.linkRequirementSetToVendorProgram()` - Links set to program
- `VendorOnboardingWizardController.createRequirementSetFromExisting()` - Creates set from template
- `VendorOnboardingWizardController.getTemplatesForRequirementSet()` - Loads templates for set
- `VendorOnboardingWizardController.createOnboardingRequirementTemplate()` - Creates template
- `VendorOnboardingWizardController.createRequirementFromTemplate()` - Creates requirement from template
- `VendorOnboardingWizardController.createOnboardingRequirementSet()` - Creates requirement set
- `VendorOnboardingWizardController.getRequirementSetById()` - Gets requirement set details

**Events:**

- Fires `next` event with requirementSetId when proceeding

### vendorProgramOnboardingRequirementGroupLinking

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingRequirementGroupLinking/`

**Purpose:** Stage component (Step 4) for linking requirement groups to requirement sets. Handles historical group member linking.

**Key Features:**

- Detects if requirement set has historical group members
- Option to use historical group linking or create new
- Creates requirement group components from historical data
- Validates requirement set selection

**API Properties:**

- `vendorProgramId` (@api) - Vendor Program ID
- `stageId` (@api) - Current stage ID
- `stepNumber` (@api) - Step number in wizard
- `requirementSetId` (@api) - Requirement Set ID from Step 3

**Properties:**

- `useHistorical` (@track) - Whether to use historical group members
- `historicalMembers` (@track) - Historical group members if available
- `isLoading` (@track) - Loading state indicator
- `nextDisabled` (@track) - Controls Next button state
- `hasHistoricalData` (@track) - Whether historical data exists

**Methods:**

- `connectedCallback()` - Checks for historical data on load
- `checkHistoricalData()` - Checks if requirement set has historical group members
  - Calls getHistoricalGroupMembers Apex method
  - Sets useHistorical flag if historical data exists
- `handleUseHistoricalChange(event)` - Updates useHistorical flag from checkbox
- `handleProceed()` - Creates requirement group components from historical data if selected
  - Calls createRequirementGroupComponents Apex method
  - Dispatches 'next' event to proceed

**Dependencies:**

- `VendorOnboardingWizardController.getHistoricalGroupMembers()` - Gets historical group members for requirement set
  - Parameter: `requirementSetId` (Id)
- `VendorOnboardingWizardController.createRequirementGroupComponents()` - Creates group components from historical data
  - Parameters: requirementSetId, vendorProgramId, useHistorical (Boolean)

**Events:**

- Fires `next` event when proceeding to next step

**Usage:**
Step 4 in vendor program onboarding wizard. Links requirement groups to the requirement set selected in Step 3, with option to use historical data if available.

### vendorProgramOnboardingReqTemplate

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingReqTemplate/`

**Purpose:** Stage component (Step 5) for creating requirement templates and linking them to requirement groups. Manages template creation and requirement group linking in the wizard.

**Key Features:**

- Create new requirement templates with all fields
- Edit existing templates inline
- Link templates to requirement groups
- Auto-link new templates to selected requirement group
- Display all templates in requirement set
- Admin-only features for template editing

**API Properties:**

- `vendorProgramId` (@api) - Vendor Program ID
- `stageId` (@api) - Current stage ID
- `requirementSetId` (@api) - Requirement Set ID from Step 3
- `requirementGroupId` (@api) - Requirement Group ID from Step 4 (auto-selected)

**Properties:**

- `newTemplate` (@track) - Template form data object
- `allRequirementGroups` (@track) - All available requirement groups
- `selectedGroupId` (@track) - Selected requirement group ID
- `selectedGroupName` (@track) - Selected requirement group name
- `nextDisabled` (@track) - Controls Next button state
- `isLoading` (@track) - Loading state indicator
- `isLoadingGroups` (@track) - Loading state for groups
- `templates` (@track) - All templates in requirement set
- `selectedTemplateIds` (@track) - Template IDs linked to selected group
- `previousSelectedTemplateIds` (@track) - Previous selection for change detection
- `lastCreatedTemplateId` (@track) - Last created template ID in session
- `autoLinkNewTemplates` (@track) - Auto-link new templates flag
- `showCreateGroupForm` (@track) - Show/hide create group form
- `editingTemplateId` (@track) - Template ID being edited (null if creating new)
- `statusOptions` (@track) - Status picklist options
- `onboardingStatusFields` (@track) - Available onboarding status fields
- `selectedCompleteStatusValues` (@track) - Multi-select values for complete status
- `selectedDeniedStatusValues` (@track) - Multi-select values for denied status
- `isAdmin` (@track) - Whether current user is admin

**Methods:**

- `wiredAllGroups({ error, data })` - Wire adapter handler for getAllVendorProgramRequirementGroups
- `wiredStatusOptions({ error, data })` - Wire adapter handler for getStatusPicklistValues
- `connectedCallback()` - Loads existing requirements and groups
- `loadTemplates()` - Loads all templates for requirement set
- `loadExistingRequirements()` - Loads existing requirements for context
- `handleGroupChange(event)` - Updates selected requirement group and loads linked templates
- `handleTemplateFieldChange(event)` - Updates template form field values
- `handleStatusFieldChange(event)` - Updates onboarding status field selection
- `handleCompleteStatusChange(event)` - Updates complete status multi-select
- `handleDeniedStatusChange(event)` - Updates denied status multi-select
- `handleCategoryGroupChange(event)` - Updates category group selection
- `handleCreateTemplate()` - Creates new requirement template
- `handleUpdateTemplate()` - Updates existing template
- `handleEditTemplate(event)` - Starts editing a template
- `handleCancelEdit()` - Cancels editing
- `resetTemplateForm()` - Resets template form to defaults
- `handleTemplateSelection(event)` - Handles template checkbox selection
- `handleSaveLinks()` - Saves template-to-group links
- `handleCreateGroup()` - Creates new requirement group
- `validateTemplateForm()` - Validates template form fields
- `isEditing` (getter) - Returns true if editing existing template
- `formTitle` (getter) - Returns form title based on edit/create mode
- `saveButtonLabel` (getter) - Returns save button label based on mode

**Dependencies:**

- `VendorOnboardingWizardController.createOnboardingRequirementTemplate()` - Creates template
- `VendorOnboardingWizardController.updateOnboardingRequirementTemplate()` - Updates template
- `VendorOnboardingWizardController.getAllVendorProgramRequirementGroups()` - Loads groups (wire)
- `VendorOnboardingWizardController.getRequirementTemplatesForSet()` - Loads templates for set
- `VendorOnboardingWizardController.updateRequirementTemplateGroupLinks()` - Updates template-group links
- `VendorOnboardingWizardController.createVendorProgramRequirementGroup()` - Creates group
- `VendorOnboardingWizardController.getStatusPicklistValues()` - Loads status options (wire)
- `VendorOnboardingWizardController.getAvailableOnboardingStatusFields()` - Loads status fields
- `VendorOnboardingWizardController.getPicklistValuesForOnboardingField()` - Loads picklist values for field
- `VendorOnboardingWizardController.isCurrentUserAdmin()` - Checks admin status (wire)

**Events:**

- Fires `next` event when proceeding to next step

**Usage:**
Step 5 in vendor program onboarding wizard. Creates requirement templates and links them to requirement groups selected in Step 4.

### vendorProgramOnboardingVendorProgramRequirements

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingVendorProgramRequirements/`

**Purpose:** Stage component for searching and selecting vendor program requirements. Allows users to search for existing requirements and select them for the vendor program.

**Key Features:**

- Search for vendor program requirements by name
- Display search results in data table
- Select requirement from results
- Dispatches 'next' event with selected requirement ID

**API:**

- `@api vendorProgramId` - Vendor program ID
- `@api stageId` - Current stage ID

**Dependencies:**

- `VendorOnboardingWizardController.searchVendorProgramRequirements()`

**Events:**

- Fires `next` event with `detail: { selectedRequirementId: String, vendorProgramId: String }`

### vendorProgramOnboardingStatusRulesEngine

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingStatusRulesEngine/`

**Purpose:** Stage component for searching, selecting, or creating status rules engines.

**Key Features:**

- Search for existing status rules engines
- Create new status rules engine records with all required fields visible
- Data table display of search results
- Toggle button to show/hide create form
- Form validation ensuring all required fields are filled
- Compact information box with context and naming best practices

**Required Fields (for Create):**

- `Name` - Text input (required)
- `Evaluation_Logic__c` - Combobox with picklist values (ALL, ANY, CUSTOM) (required)
- `Required_Status__c` - Combobox with picklist values (required)
- `Target_Onboarding_Status__c` - Combobox with picklist values (required)

**Optional Fields:**

- `Vendor_Program_Requirement_Group__c` - Text input
- `Vendor_Program_Group__c` - Text input

**Properties:**

- `searchText` - Search input text
- `searchResults` - List of search results
- `showCreateForm` - Controls create form visibility
- `newName` - Name for new rules engine
- `newRequirementGroupId` - Vendor program requirement group ID (optional)
- `newProgramGroupId` - Vendor program group ID (optional)
- `newEvaluationLogic` - Evaluation logic (defaults to 'ALL')
- `newRequiredStatus` - Required status (defaults to 'New')
- `newTargetOnboardingStatus` - Target onboarding status (defaults to 'In Process')
- `evaluationLogicOptions` - Picklist options for Evaluation Logic (loaded via @wire)
- `requiredStatusOptions` - Picklist options for Required Status (loaded via @wire)
- `targetOnboardingStatusOptions` - Picklist options for Target Onboarding Status (loaded via @wire)
- `columns` - Data table column definitions

**Methods:**

- `handleSearchTextChange(event)` - Updates search text
- `handleSearch()` - Calls Apex to search for rules engines
- `handleRowAction(event)` - Handles row action (select)
- `handleInputChange(event)` - Updates input field values
- `handleEvaluationLogicChange(event)` - Updates evaluation logic selection
- `handleRequiredStatusChange(event)` - Updates required status selection
- `handleTargetOnboardingStatusChange(event)` - Updates target onboarding status selection
- `handleCreateClick()` - Creates new rules engine with all required fields
- `toggleCreateForm()` - Shows/hides create form
- `showToast(title, message, variant)` - Displays toast notifications

**Computed Properties:**

- `hasSearchResults` - Whether search results exist
- `createButtonLabel` - Dynamic button label based on form state

**Dependencies:**

- `VendorOnboardingWizardController.searchStatusRulesEngines()`
- `VendorOnboardingWizardController.createOnboardingStatusRulesEngine()`
- `VendorOnboardingWizardController.getEvaluationLogicPicklistValues()` (cacheable @wire)
- `VendorOnboardingWizardController.getRequiredStatusPicklistValues()` (cacheable @wire)
- `VendorOnboardingWizardController.getTargetOnboardingStatusPicklistValues()` (cacheable @wire)

**Purpose:** Stage component for searching, creating, and selecting status rules engines. Allows users to search for existing rules engines or create new ones.

**Key Features:**

- Search for status rules engines by name
- Create new status rules engine records
- Display search results in data table
- Select rules engine from results
- Dispatches 'next' event with selected rules engine ID

**API:**

- `@api vendorProgramId` - Vendor program ID
- `@api stageId` - Current stage ID

**Properties:**

- `newName` - Name for new rules engine
- `newRequirementGroupId` - Requirement group ID for new rules engine
- `newProgramGroupId` - Program group ID for new rules engine

**Dependencies:**

- `VendorOnboardingWizardController.searchStatusRulesEngines()`
- `VendorOnboardingWizardController.createOnboardingStatusRulesEngine()`

**Events:**

- Fires `next` event with `detail: { rulesEngineId: String, vendorProgramId: String }`

### vendorProgramOnboardingStatusRuleBuilder

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingStatusRuleBuilder/`

**Purpose:** Stage component for building and configuring status rules. Provides UI for creating rule conditions and configuring rule evaluation logic.

**API:**

- `@api vendorProgramId` - Vendor program ID
- `@api stageId` - Current stage ID

### vendorProgramOnboardingCommunicationTemplate

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingCommunicationTemplate/`

**Purpose:** Stage component for selecting and linking communication templates to vendor programs. Allows users to choose from available communication templates and link them to the vendor program.

**Key Features:**

- Loads all available communication templates
- Select template from dropdown
- Link selected template to vendor program
- Dispatches 'next' event after linking

**API:**

- `@api vendorProgramId` - Vendor program ID

**Dependencies:**

- `VendorOnboardingWizardController.getCommunicationTemplates()`
- `VendorOnboardingWizardController.linkCommunicationTemplateToVendorProgram()`

**Events:**

- Fires `next` event with `detail: { vendorProgramId: String, communicationTemplateId: String }`

## Management Components

### onboardingRequirementsPanel

**Location:** `force-app/main/default/lwc/onboardingRequirementsPanel/`

**Purpose:** Displays and manages onboarding requirements for an onboarding record with rules version tracking and validation management.

**Key Features:**

- Lists all requirements for an onboarding
- Allows status updates via combobox
- Triggers status re-evaluation after updates
- Displays requirement details and invalid field summaries
- **Rules Version Tracking**: Monitors rules version changes and shows banner when rules change after page load
- **Refresh & Re-evaluate**: Button to refresh rules and re-evaluate status
- **Invalid Field Management**: Displays invalid field values and allows re-running validation
- **Auto-refresh**: Checks for rules changes every 30 seconds
- Uses shared error handling (`c/utils.extractErrorMessage`) and toasts for all Apex failures (load, submit, re-run validation)

**API:**

- `@api recordId` - Onboarding record ID (from record page context)

**Properties:**

- `requirements` - List of requirement records
- `invalidFields` - List of invalid field values
- `rulesVersionOnLoad` - Rules version timestamp when page loaded
- `currentRulesVersion` - Current rules version timestamp
- `showRulesChangedBanner` - Whether to show rules changed banner
- `isRefreshing` - Whether refresh operation is in progress
- `rulesVersionCheckInterval` - Interval ID for version checking

**Methods:**

- `loadData()` - Loads requirements and invalid field values in parallel
- `loadRulesVersion()` - Loads current rules version
- `checkRulesVersion()` - Checks if rules version has changed (called every 30 seconds)
- `handleRefreshRules()` - Refreshes rules and re-evaluates status
- `handleStatusChange(event)` - Handles requirement status change
- `submit()` - Updates requirement statuses and triggers re-evaluation
- `rerunSelected()` - Re-runs validation for selected invalid fields

**Dependencies:**

- `OnboardingRequirementsPanelController.getRequirements()` - Returns requirements as RequirementDTO objects
- `OnboardingRequirementsPanelController.getInvalidFieldValues()` - Returns invalid field values
- `OnboardingRequirementsPanelController.updateRequirementStatuses()` - Updates requirement statuses and triggers re-evaluation
- `OnboardingRequirementsPanelController.runRuleEvaluation()` - Triggers status re-evaluation
- `OnboardingRequirementsPanelController.rerunValidation()` - Re-runs validation for field values
- `OnboardingRequirementsPanelController.getActiveRulesVersion()` - Gets current rules version timestamp
- `OnboardingRequirementsPanelController.refreshAndReevaluate()` - Refreshes rules and re-evaluates status

**Lifecycle:**

- `connectedCallback()` - Starts rules version checking interval
- `disconnectedCallback()` - Clears rules version checking interval

**Usage:**
Add to an Onboarding record page:

```xml
<c-onboarding-requirements-panel record-id={recordId}></c-onboarding-requirements-panel>
```

### onboardingStatusRulesEngine

**Location:** `force-app/main/default/lwc/onboardingStatusRulesEngine/`

**Purpose:** Admin UI for configuring onboarding status rules with preview evaluation capability.

**Key Features:**

- Select vendor program group and requirement group
- Validate that both groups are selected before loading rules
- Load existing rules
- Edit rules engines in datatable with editable columns:
  - Name (Name) - Read-only, displays rules engine name
  - Target Status (Target_Onboarding_Status\_\_c) - Editable
  - Evaluation Logic (Evaluation_Logic\_\_c) - Editable
  - Custom Evaluation Logic (Custom_Evaluation_Logic\_\_c) - Editable
- Save rule changes with success/error toasts using shared error handling (`c/utils.extractErrorMessage`)
- **Preview Evaluation**: Select an onboarding record and preview status evaluation without applying changes
- Preview modal integration with `statusEvaluationPreviewModal` component
- Onboarding record selection dropdown (loads recent active onboarding records)

**Properties:**

- `vendorProgramGroupOptions` (@track) - Array of vendor program group options for combobox
- `requirementGroupOptions` (@track) - Array of requirement group options for combobox
- `onboardingOptions` (@track) - Array of onboarding record options for preview selection
- `rules` (@track) - Array of rules engine records displayed in datatable
- `draftValues` (@track) - Array of draft values from datatable for saving
- `showPreviewModal` (@track) - Controls preview modal visibility
- `selectedOnboardingId` (@track) - Selected onboarding ID for preview
- `selectedVendorProgramGroup` - Selected vendor program group ID (not tracked, updated via handler)
- `selectedRequirementGroup` - Selected requirement group ID (not tracked, updated via handler)
- `columns` - Datatable column configuration:
  - **Name** (`Name`) - Read-only, displays rules engine name
  - **Target Status** (`Target_Onboarding_Status__c`) - Editable
  - **Evaluation Logic** (`Evaluation_Logic__c`) - Editable
  - **Custom Evaluation Logic** (`Custom_Evaluation_Logic__c`) - Editable

**Methods:**

- `handleVendorProgramGroupChange(event)` - Updates selected vendor program group when combobox changes
- `handleRequirementGroupChange(event)` - Updates selected requirement group when combobox changes
- `loadRules()` - Loads rules for selected groups (validates both groups are selected, shows warning toast if not)
- `handleSave(event)` - Saves rule changes from datatable (extracts draftValues, calls saveRules with parameter name `statusRulesEngineRecords`, reloads rules, shows success toast)
- `handlePreviewClick()` - Opens preview modal (validates onboarding selection first, shows warning toast if not selected)
- `handleOnboardingSelection(event)` - Updates selected onboarding ID from combobox
- `handlePreviewModalClose()` - Closes preview modal by setting showPreviewModal to false
- `showToast(title, message, variant)` - Helper method to dispatch ShowToastEvent for user feedback

**Computed Properties:**

- `isPreviewDisabled` - Disables preview button when no onboarding is selected

**Lifecycle:**

- `connectedCallback()` - Loads vendor program groups, requirement groups, and onboarding options in parallel on component initialization

**Dependencies:**

- `OnboardingStatusRulesEngineController.getVendorProgramGroups()` - Loads vendor program group options (cacheable)
- `OnboardingStatusRulesEngineController.getRequirementGroups()` - Loads requirement group options (cacheable)
- `OnboardingStatusRulesEngineController.getRules()` - Loads rules engines for selected groups
- `OnboardingStatusRulesEngineController.saveRules()` - Saves rule changes (updates Onboarding_Status_Rules_Engine\_\_c records)
- `OnboardingStatusRulesEngineController.getOnboardingOptions()` - Loads onboarding records for preview selection (cacheable, limit 50)

**UI Structure:**

- Lightning Card with title "Onboarding Status Rules Engine" and rules icon
- Two comboboxes for Vendor Program Group and Requirement Group selection
- Grid layout with three columns:
  1. "Load Rules" button
  2. "Select Onboarding for Preview" combobox
  3. "Preview Evaluation" button (disabled when no onboarding selected)
- Datatable conditionally rendered when rules.length > 0
  - Uses key-field="Id"
  - Hides checkbox column
  - Handles inline editing with onsave event
- Preview modal conditionally rendered when showPreviewModal is true
  - Passes record-id={selectedOnboardingId} and is-open={showPreviewModal}
  - Listens for onclose event

**Error Handling:**

- Uses `c/utils.extractErrorMessage` for consistent error message extraction
- Shows warning toasts when validation fails (missing group selections, missing onboarding selection)
- Shows error toasts when Apex calls fail
- Shows success toast when rules are saved successfully

**Validation:**

- Both vendor program group and requirement group must be selected before loading rules
- Onboarding record must be selected before preview evaluation
- Preview button is disabled when no onboarding is selected (via `isPreviewDisabled` computed property)

**Note:** The datatable edits `Onboarding_Status_Rules_Engine__c` records (rules engines), not individual `Onboarding_Status_Rule__c` records (rule conditions). Editable fields are `Target_Onboarding_Status__c`, `Evaluation_Logic__c`, and `Custom_Evaluation_Logic__c`. The `Name` field is displayed as read-only for identification purposes.

### statusEvaluationPreviewModal

**Location:** `force-app/main/default/lwc/statusEvaluationPreviewModal/`

**Purpose:** Modal component for previewing status evaluation trace without applying changes. Displays detailed evaluation results with filtering and CSV export capabilities.

**Key Features:**

- Displays evaluation trace data in sortable datatable
- **Filtering**: Filter by Group Name, Engine Name, or Rule Number (case-insensitive, partial match)
- **CSV Export**: Export filtered trace data to CSV file
- **Loading State**: Shows spinner while loading evaluation data
- **Empty State**: Displays message when no trace data is available
- Uses `@wire` adapter for reactive data loading
- Automatically adds unique keys to trace records for datatable

**API Properties:**

- `recordId` (@api) - Onboarding record ID to evaluate (required)
- `isOpen` (@api) - Controls modal visibility (default: false)

**Properties:**

- `traceData` (@track) - Full array of evaluation trace records from server
- `filteredTraceData` (@track) - Filtered trace data displayed in datatable
- `isLoading` (@track) - Loading state indicator
- `internalIsOpen` (@track) - Internal state for modal visibility (synced with @api isOpen)
- `filters` (@track) - Filter object with groupName, engineName, ruleNumber properties
- `columns` - Datatable column configuration:
  - Order (ruleOrder) - Sortable number
  - Group (groupName) - Sortable text
  - Engine (engineName) - Sortable text
  - Rule # (ruleNumber) - Sortable number
  - Requirement (requirementName) - Text
  - Expected Status (expectedStatus) - Text
  - Passed (passed) - Sortable boolean
  - Evaluation Logic (evaluationLogic) - Text
  - Resulting Status (resultingStatus) - Text
  - Reason (shortCircuitReason) - Text with wrapText enabled

**Computed Properties:**

- `hasTraceData` - Returns true if filteredTraceData has items
- `canExport` - Returns true if trace data is available for export
- `isExportDisabled` - Returns true if export should be disabled (inverse of canExport)

**Methods:**

- `wiredPreview({ error, data })` - Wire adapter handler for previewStatusEvaluation
  - Handles loading state
  - Maps trace data with unique keys (engineId + ruleNumber + index)
  - Applies filters after data loads
  - Shows error toast on failure
- `handleFilterChange(event)` - Updates filter value from input field (uses data-field attribute)
- `applyFilters()` - Applies all active filters to traceData and updates filteredTraceData
  - Filters are case-insensitive and use partial matching (includes)
  - Filters groupName, engineName, and ruleNumber independently
- `handleExportCSV()` - Exports filtered trace data to CSV file
  - Creates CSV with headers matching datatable columns
  - Escapes quotes in cell values
  - Downloads file with timestamp: `evaluation-preview-{timestamp}.csv`
- `handleClose()` - Closes modal and dispatches 'close' event to parent
- `showToast(title, message, variant)` - Helper method to dispatch ShowToastEvent

**Lifecycle:**

- `connectedCallback()` - Initializes internalIsOpen from @api isOpen property
- `renderedCallback()` - Syncs internalIsOpen with @api isOpen property changes

**Dependencies:**

- `OnboardingStatusRulesEngineController.previewStatusEvaluation()` - Loads evaluation trace data via @wire adapter
  - Parameters: onboardingId (from recordId), asOfDateTime (null), rulesEngineIds (null)
  - Returns List<StatusEvaluationTraceDTO>

**Events:**

- `close` - Dispatched when modal is closed (handled by parent component)

**Usage:**
Used by `onboardingStatusRulesEngine` component to display preview evaluation results. Parent component passes `record-id` and `is-open` properties, and listens for `onclose` event.

### onboardingStatusRuleList

**Location:** `force-app/main/default/lwc/onboardingStatusRuleList/`

**Purpose:** Displays a list of onboarding status rules.

**Key Features:**

- Filters by vendor program group
- Displays rules in datatable
- Edit button for each rule

**Dependencies:**

- `OnboardingStatusRuleController.getRules()`

### onboardingStatusRulesManager

**Location:** `force-app/main/default/lwc/onboardingStatusRulesManager/`

**Purpose:** Manager component for onboarding status rules (wrapper/container).

### onboardingRuleModal

**Location:** `force-app/main/default/lwc/onboardingRuleModal/`

**Purpose:** Modal dialog for creating/editing onboarding rules. Currently a placeholder component (empty implementation).

**Note:** This component is essentially empty (just extends LightningElement) and appears to be a stub for future functionality.

### requirementConditionsList

**Location:** `force-app/main/default/lwc/requirementConditionsList/`

**Purpose:** Displays and manages requirement conditions for rules.

## Utility Components

### vendorProgramHighlights

**Location:** `force-app/main/default/lwc/vendorProgramHighlights/`

**Purpose:** Displays highlights/summary information for a vendor program.

**Key Features:**

- Displays Vendor Program status (`Vendor_Customization__c.Status__c`)
- Shows version and active state
- **Note**: Currently displays technical status directly - could be enhanced to use `getUserFacingStage()` for consistency with other components

**Status Display:**

- Shows `Vendor_Customization__c.Status__c` value directly
- ⚠️ **Future Enhancement**: Consider using `OnboardingApplicationService.getUserFacingStage()` to show simplified statuses for end users

### vendorSelector

**Location:** `force-app/main/default/lwc/vendorSelector/`

**Purpose:** Reusable component for selecting vendors.

### onboardingAppHeaderBar

**Location:** `force-app/main/default/lwc/onboardingAppHeaderBar/`

**Purpose:** Header bar component for onboarding applications.

**Configuration:**

- `isActiveFieldApiName` - API name of the active field (default: "Active\_\_c")

### onboardingVendorProgramWizard

**Location:** `force-app/main/default/lwc/onboardingVendorProgramWizard/`

**Purpose:** Modal wizard for selecting or creating Vendor Programs and initializing their onboarding flow.

**Key Features:**

- Vendor/program hierarchy tree grid with search
- Vendor search and inline creation (with duplicate detection)
- Vendor Program search, recent list, and selection
- Initializes onboarding progress for the selected/created Vendor Program
- Emits `launchwizard` events consumed by `onboardingHomeDashboard` to open the main onboarding flow

### onboardingDealerOnboardingModal

**Location:** `force-app/main/default/lwc/onboardingDealerOnboardingModal/`

**Purpose:** Simple modal for selecting an Account (Dealer) from the Eligible Accounts list before starting dealer onboarding.

**Key Features:**

- Accepts eligible Account list from parent
- Maps Accounts into combobox options
- Emits `start` event with `accountId` when user confirms

### onboardingAdminToolsPanel

**Location:** `force-app/main/default/lwc/onboardingAdminToolsPanel/`

**Purpose:** Encapsulates the Admin Tools section of the onboarding dashboard.

**Key Features:**

- Tabs for Validation Failures, Messaging Issues, Rule Tester, Override Audit, Rule Builder
- Buttons to open list views for validation failures, messaging issues, and override audit
- Follow-up shortcut buttons (Pending, Pending Retry, Failed, Due Today)
- Stubbed navigation shortcuts (Manage Requirements, Stage Dependencies, Vendor Program Wizard, Component Library)

### onboardingAppRequirementSetupWizard

**Location:** `force-app/main/default/lwc/onboardingAppRequirementSetupWizard/`

**Purpose:** Wizard component for setting up onboarding requirement sets and templates. Guides users through creating requirement sets and adding requirement templates.

**Key Features:**

- Creates onboarding requirement sets
- Adds requirement templates to sets
- Displays list of created templates
- Fires 'next' event when setup is complete

**API:**

- None (standalone wizard component)

**Properties:**

- `requirementSetName` - Name for new requirement set
- `newTemplateName` - Name for new requirement template
- `newRequirementType` - Type of requirement template
- `requirementTemplates` - List of templates in current set
- `requirementSetId` - ID of created requirement set
- `requirementSetCreated` - Boolean flag indicating if set was created
- `requirementTypeOptions` - Picklist options for requirement types

**Methods:**

- `createRequirementSet()` - Creates a new requirement set
- `addRequirementTemplate()` - Adds a template to the current set
- `finalizeSetup()` - Fires 'next' event to proceed to next step

**Dependencies:**

- `VendorOnboardingWizardController.createOnboardingRequirementSet()`
- `VendorOnboardingWizardController.createOnboardingRequirementTemplate()`
- `VendorOnboardingWizardController.getRequirementTemplatesForSet()`

**Usage:**
Used in vendor onboarding wizard workflows for requirement setup.

### onboardingAppVendorProgramECCManager

**Location:** `force-app/main/default/lwc/onboardingAppVendorProgramECCManager/`

**Purpose:** Manages External Contact Credential (ECC) types for vendor programs. Allows linking credential types to required credentials and creating new credential types.

**Key Features:**

- Displays required credentials for a vendor program in datatable
- Links credential types to required credentials
- Creates new credential types via modal
- Shows linked credential type for each required credential

**API:**

- `@api recordId` - Vendor Program ID (Vendor_Customization\_\_c) from record page context

**Properties:**

- `requiredCredentials` - List of required credentials for the vendor program
- `credentialTypeOptions` - Options for credential type combobox
- `selectedRequiredCredentialId` - Currently selected required credential
- `selectedCredentialTypeId` - Selected credential type for linking
- `showModal` - Controls visibility of create credential type modal
- `newCredentialTypeName` - Name for new credential type

**Methods:**

- `loadData()` - Loads required credentials and credential types
- `handleRowAction(event)` - Handles datatable row actions (Manage button)
- `handleCredentialTypeChange(event)` - Updates selected credential type
- `handleLinkCredential()` - Links selected credential type to required credential
- `handleShowModal()` - Opens create credential type modal
- `handleCloseModal()` - Closes modal
- `handleCreateCredentialType()` - Creates new credential type
- `showToast(message)` - Displays success toast
- `showError(title, error)` - Displays error toast

**Dependencies:**

- `OnboardingAppECCService.getRequiredCredentials()` (direct service call)
- `OnboardingAppECCService.getAvailableCredentialTypes()` (direct service call)
- `OnboardingAppECCService.createCredentialType()` (direct service call)
- `OnboardingAppECCService.linkCredentialTypeToRequiredCredential()` (direct service call)

**Usage:**
Add to a Vendor Program record page:

```xml
<c-onboarding-app-vendor-program-e-c-c-manager record-id={recordId}></c-onboarding-app-vendor-program-e-c-c-manager>
```

### onboardingOrderStatusViewer

**Location:** `force-app/unpackaged/lwc/onboardingOrderStatusViewer/`

**Purpose:** Displays order status for onboarding records.

### onboardingStatusRuleForm

**Location:** `force-app/unpackaged/lwc/onboardingStatusRuleForm/`

**Purpose:** Form for creating/editing status rules.

### onboardingECC

**Location:** `force-app/unpackaged/lwc/onboardingECC/`

**Purpose:** External Contact Credential management component.

### onboardingStageDependencyViewer

**Location:** `force-app/main/default/lwc/onboardingStageDependencyViewer/`

**Purpose:** Visual viewer for onboarding stage dependencies. Displays stages in a visual layout showing dependencies and completion status.

**Key Features:**

- Visual representation of stages with dependency relationships
- Shows stage completion status with color coding
- Calculates stage positions based on dependencies
- SVG-based rendering for stage visualization
- Displays stage sequence numbers and status badges

**API:**

- `@api vendorProgramId` - Vendor program ID
- `@api processId` - Onboarding process ID

**Properties:**

- `stages` - List of stages with dependency information and calculated positions
- `isLoading` - Loading state
- `error` - Error object if loading fails

**Dependencies:**

- `OnboardingStageDependencyController.getStagesWithDependencies()`

**Usage:**
Used to visualize stage dependencies in the onboarding flow.

### twilioSettings

**Location:** `force-app/main/default/lwc/twilioSettings/`

**Purpose:** Admin UI for managing Twilio SMS provider configurations. Lists all Twilio configurations with validation and management capabilities.

**Key Features:**

- Lists all Twilio configurations from Custom Metadata
- Shows active/inactive status with visual indicators
- Validation button to check configuration
- Refresh functionality
- Edit capabilities for configurations
- Help text and validation warnings
- Responsive design

**Properties:**

- `configurations` - List of Twilio configuration records
- `isLoading` - Loading state
- `showEditModal` - Controls edit modal visibility
- `editingConfig` - Currently editing configuration
- `showAccessDenied` - Whether access is denied

**Columns:**

- Label (text)
- From Phone (phone)
- Named Credential (text)
- Account SID (text)
- Active (boolean with color coding)
- Actions (Edit)

**Methods:**

- `handleValidate()` - Validates active configuration
- `handleRefresh()` - Refreshes configuration list
- `handleRowAction(event)` - Handles row actions (Edit)
- `handleEdit()` - Opens edit modal
- `handleCloseModal()` - Closes edit modal

**Dependencies:**

- `TwilioSettingsController.getTwilioConfigurations()` - Retrieves all Twilio configurations
- `TwilioSettingsController.validateConfiguration()` - Validates active configuration

**Usage:**
Used by administrators to manage Twilio SMS provider settings. See [Implementation Status](../implementation-status.md) for Twilio integration details.

### onboardingAtRiskPanel

**Location:** `force-app/main/default/lwc/onboardingAtRiskPanel/`

**Purpose:** Displays onboarding records that are at risk or blocked.

**Key Features:**

- Lists at-risk onboarding records
- Shows blocking reasons
- Visual indicators for risk level

**Usage:**
Used in dashboard and admin views to highlight records needing attention.

### validationFailuresTab

**Location:** `force-app/main/default/lwc/validationFailuresTab/`

**Purpose:** Admin dashboard tab for viewing and managing validation failures. Enhanced tab version with advanced filtering, grouping, and CSV export capabilities.

**Key Features:**

- Displays validation failures in sortable datatable
- **Grouping**: Group by Rule, User, or Requirement
- **Filtering**: Filter by rule name, user, and date range (Last 24 Hours, Last 7 Days, Last 30 Days, All Time)
- **Row Actions**: Retry Validation, View Details, Dismiss
- **Bulk Actions**: Bulk retry for selected failures
- **CSV Export**: Export filtered failures to CSV file
- Uses `@wire` adapter for reactive data loading
- Uses `refreshApex` for manual refresh after actions

**Properties:**

- `failures` (@track) - Full array of validation failures from server
- `filteredFailures` (@track) - Filtered failures displayed in datatable
- `isLoading` (@track) - Loading state indicator
- `selectedRows` (@track) - Selected rows for bulk operations
- `groupBy` (@track) - Grouping mode ('rule', 'user', 'requirement')
- `filters` (@track) - Filter object with rule, user, dateRange properties
- `wiredFailuresResult` - Stored wire result for refreshApex

**Columns:**

- Rule Name (ruleName) - Sortable text
- Requirement Field (requirementFieldName) - Text
- Status (status) - Sortable text
- Error Message (errorMessage) - Text with wrapText enabled
- Created Date (createdDate) - Date with formatted display (year, month, day, hour, minute)
- Retry Count (retryCount) - Number
- Action menu with: Retry Validation, View Details, Dismiss

**Methods:**

- `wiredFailures({ error, data })` - Wire adapter handler for getValidationFailures
  - Stores result for refreshApex
  - Handles loading state
  - Populates failures and filteredFailures
- `handleRowAction(event)` - Handles row action menu selections
  - Switches on action name: 'retry', 'view', 'dismiss'
- `handleRetry(row)` - Retries validation for a single failure
  - Calls retryValidation Apex method
  - Shows success/error toasts
  - Refreshes data on success
- `handleView(row)` - Navigates to validation failure record detail page
  - Uses NavigationMixin to navigate to standard\_\_recordPage
- `handleDismiss(row)` - Removes failure from view (client-side filter only)
- `handleBulkRetry()` - Retries validation for all selected failures
  - Validates at least one row selected
  - Uses Promise.all for parallel retry operations
- `handleGroupByChange(event)` - Updates grouping mode and refreshes data
- `handleFilterChange(event)` - Updates filter values using data-field attribute
- `handleDateRangeChange(event)` - Updates date range filter
- `handleSelectionChange(event)` - Updates selected rows from datatable
- `refreshData()` - Refreshes data using refreshApex if wired result exists
- `handleExport()` - Exports filtered failures to CSV
  - Validates data exists
  - Builds CSV using buildCsv method
  - Downloads with filename 'validation-failures.csv'
- `buildCsv(rows)` - Builds CSV content from rows
  - Headers: Rule Name, Requirement Field, Status, Error Message, Created Date, Retry Count
  - Escapes quotes and handles null/undefined values
  - Formats dates as ISO strings
- `downloadCsv(csvContent, filename)` - Triggers CSV download via blob and temporary anchor element
- Toast helpers: `showError(message)`, `showSuccess(message)`, `showWarning(message)`, `showInfo(message)`

**Computed Properties:**

- `groupByOptions` - Returns grouping options array:
  - { label: 'By Rule', value: 'rule' }
  - { label: 'By User', value: 'user' }
  - { label: 'By Requirement', value: 'requirement' }
- `dateRangeOptions` - Returns date range filter options:
  - Last 24 Hours, Last 7 Days, Last 30 Days, All Time
- `hasNoFailures` - Returns true if not loading and filteredFailures is empty

**Dependencies:**

- `OnboardingAdminDashboardController.getValidationFailures()` - Loads validation failures via @wire adapter
  - Parameters: `groupBy` (String), `filters` (Object with rule, user, dateRange)
- `OnboardingAdminDashboardController.retryValidation()` - Retries validation for a failure
  - Parameter: `failureId` (Id)

**Usage:**
Used as a tab component in `onboardingAdminDashboard` for admin management of validation failures. Provides advanced filtering, grouping, and export capabilities compared to the simpler panel version.

### messagingIssuesTab

**Location:** `force-app/main/default/lwc/messagingIssuesTab/`

**Purpose:** Admin dashboard tab for viewing and managing messaging issues (SMS/Email follow-up failures). Enhanced tab version with advanced filtering, grouping, and bulk operations.

**Key Features:**

- Displays messaging issues in sortable datatable
- **Grouping**: Group by Type, Status, or Onboarding
- **Filtering**: Filter by follow-up type (SMS, Email, In-App), status (Failed, Pending, Pending Retry), and date range
- **Row Actions**: Retry, View Onboarding, Dismiss
- **Bulk Actions**: Bulk retry and bulk dismiss for selected issues
- **CSV Export**: Export placeholder (TODO - functionality to be implemented)
- Uses `@wire` adapter for reactive data loading

**Properties:**

- `issues` (@track) - Full array of messaging issues from server
- `filteredIssues` (@track) - Filtered issues displayed in datatable
- `isLoading` (@track) - Loading state indicator
- `selectedRows` (@track) - Selected rows for bulk operations
- `groupBy` (@track) - Grouping mode ('type', 'status', 'onboarding')
- `filters` (@track) - Filter object with type, status, dateRange properties

**Columns:**

- Follow-Up Type (followUpType) - Sortable text (SMS, Email, In-App)
- Status (status) - Sortable text
- Onboarding (onboardingName) - Text
- Account (accountName) - Text
- Error Message (errorMessage) - Text with wrapText enabled
- Attempt Count (attemptCount) - Number
- Last Attempt (lastAttemptDate) - Date with formatted display
- Created Date (createdDate) - Date with formatted display
- Action menu with: Retry, View Onboarding, Dismiss

**Methods:**

- `wiredIssues({ error, data })` - Wire adapter handler for getMessagingIssues
  - Handles loading state
  - Populates issues and filteredIssues
- `handleRowAction(event)` - Handles row action menu selections
  - Switches on action name: 'retry', 'view', 'dismiss'
- `handleRetry(row)` - Retries messaging for a single issue
  - Calls retryMessaging Apex method
  - Shows success/error toasts
  - Refreshes data on success
- `handleView(row)` - Navigates to onboarding record detail page
  - Uses NavigationMixin to navigate to standard\_\_recordPage
- `handleDismiss(row)` - Dismisses an issue
  - Calls dismissMessagingIssue Apex method
  - Shows success/error toasts
  - Refreshes data on success
- `handleBulkRetry()` - Retries messaging for all selected issues
  - Validates at least one row selected
  - Uses Promise.all for parallel retry operations
- `handleBulkDismiss()` - Dismisses all selected issues
  - Validates at least one row selected
  - Uses Promise.all for parallel dismiss operations
- `handleGroupByChange(event)` - Updates grouping mode and refreshes data
- `handleFilterChange(event)` - Updates filter values using event detail (name, value)
- `handleDateRangeChange(event)` - Updates date range filter
- `handleStatusChange(event)` - Updates status filter
- `handleTypeChange(event)` - Updates type filter
- `handleSelectionChange(event)` - Updates selected rows from datatable
- `refreshData()` - Triggers wire adapter refresh by setting isLoading
- `handleExport()` - Export placeholder (shows info toast - TODO)
- Toast helpers: `showError(message)`, `showSuccess(message)`, `showWarning(message)`, `showInfo(message)`

**Computed Properties:**

- `groupByOptions` - Returns grouping options array:
  - { label: 'By Type', value: 'type' }
  - { label: 'By Status', value: 'status' }
  - { label: 'By Onboarding', value: 'onboarding' }
- `dateRangeOptions` - Returns date range filter options:
  - Last 24 Hours, Last 7 Days, Last 30 Days, All Time
- `statusOptions` - Returns status filter options:
  - All Statuses (null), Failed, Pending, Pending Retry
- `typeOptions` - Returns type filter options:
  - All Types (null), SMS, Email, In-App
- `hasNoIssues` - Returns true if not loading and filteredIssues is empty

**Dependencies:**

- `OnboardingAdminDashboardController.getMessagingIssues()` - Loads messaging issues via @wire adapter
  - Parameters: `groupBy` (String), `filters` (Object with type, status, dateRange)
- `OnboardingAdminDashboardController.retryMessaging()` - Retries messaging for an issue
  - Parameter: `issueId` (Id)
- `OnboardingAdminDashboardController.dismissMessagingIssue()` - Dismisses a messaging issue
  - Parameter: `issueId` (Id)

**Usage:**
Used as a tab component in `onboardingAdminDashboard` for admin management of messaging/follow-up issues. Provides advanced filtering, grouping, and bulk operations compared to the simpler panel version.

### adobeSyncFailuresTab

**Location:** `force-app/main/default/lwc/adobeSyncFailuresTab/`

**Purpose:** Admin dashboard tab for viewing and managing Adobe sync failures (form submissions, signatures, document generation). Handles retry and resolution of Adobe integration sync issues.

**Key Features:**

- Displays Adobe sync failures in sortable datatable
- **Grouping**: Group by Type, Status, or Onboarding
- **Filtering**: Filter by failure type (Form Submission, Signature Sync, Document Generation), status (Pending, Retrying, Resolved, Failed), and date range
- **Row Actions**: Retry Sync, View Onboarding, Mark Resolved
- **Bulk Actions**: Bulk retry and bulk resolve for selected failures
- **CSV Export**: Export placeholder (TODO - functionality to be implemented)
- Uses `@wire` adapter for reactive data loading

**Properties:**

- `failures` (@track) - Full array of Adobe sync failures from server
- `filteredFailures` (@track) - Filtered failures displayed in datatable
- `isLoading` (@track) - Loading state indicator
- `selectedRows` (@track) - Selected rows for bulk operations
- `groupBy` (@track) - Grouping mode ('type', 'status', 'onboarding')
- `filters` (@track) - Filter object with type, status, dateRange properties

**Columns:**

- Failure Type (failureType) - Sortable text (Form Submission, Signature Sync, Document Generation)
- Status (status) - Sortable text
- Onboarding (onboardingName) - Text
- Account (accountName) - Text
- Error Message (errorMessage) - Text with wrapText enabled
- Retry Count (retryCount) - Number
- Last Retry (lastRetryDate) - Date with formatted display
- Created Date (createdDate) - Date with formatted display
- Action menu with: Retry Sync, View Onboarding, Mark Resolved

**Methods:**

- `wiredFailures({ error, data })` - Wire adapter handler for getAdobeSyncFailures
  - Handles loading state
  - Populates failures and filteredFailures
- `handleRowAction(event)` - Handles row action menu selections
  - Switches on action name: 'retry', 'view', 'resolve'
- `handleRetry(row)` - Retries Adobe sync for a single failure
  - Calls retryAdobeSync Apex method
  - Shows success/error toasts
  - Refreshes data on success
- `handleView(row)` - Navigates to onboarding record detail page
  - Uses NavigationMixin to navigate to standard\_\_recordPage
- `handleResolve(row)` - Marks a failure as resolved
  - Calls resolveAdobeSyncFailure Apex method
  - Shows success/error toasts
  - Refreshes data on success
- `handleBulkRetry()` - Retries sync for all selected failures
  - Validates at least one row selected
  - Uses Promise.all for parallel retry operations
- `handleBulkResolve()` - Resolves all selected failures
  - Validates at least one row selected
  - Uses Promise.all for parallel resolve operations
- `handleGroupByChange(event)` - Updates grouping mode and refreshes data
- `handleDateRangeChange(event)` - Updates date range filter
- `handleStatusChange(event)` - Updates status filter
- `handleTypeChange(event)` - Updates type filter
- `handleSelectionChange(event)` - Updates selected rows from datatable
- `refreshData()` - Triggers wire adapter refresh by setting isLoading
- `handleExport()` - Export placeholder (shows info toast - TODO)
- Toast helpers: `showError(message)`, `showSuccess(message)`, `showWarning(message)`, `showInfo(message)`

**Computed Properties:**

- `groupByOptions` - Returns grouping options array:
  - { label: 'By Type', value: 'type' }
  - { label: 'By Status', value: 'status' }
  - { label: 'By Onboarding', value: 'onboarding' }
- `dateRangeOptions` - Returns date range filter options:
  - Last 24 Hours, Last 7 Days, Last 30 Days, All Time
- `statusOptions` - Returns status filter options:
  - All Statuses (null), Pending, Retrying, Resolved, Failed
- `typeOptions` - Returns type filter options:
  - All Types (null), Form Submission, Signature Sync, Document Generation
- `hasNoFailures` - Returns true if not loading and filteredFailures is empty

**Dependencies:**

- `OnboardingAdminDashboardController.getAdobeSyncFailures()` - Loads Adobe sync failures via @wire adapter
  - Parameters: `groupBy` (String), `filters` (Object with type, status, dateRange)
- `OnboardingAdminDashboardController.retryAdobeSync()` - Retries Adobe sync for a failure
  - Parameter: `failureId` (Id)
- `OnboardingAdminDashboardController.resolveAdobeSyncFailure()` - Marks a sync failure as resolved
  - Parameter: `failureId` (Id)

**Usage:**
Used as a tab component in `onboardingAdminDashboard` for admin management of Adobe integration sync failures.

### onboardingAdminDashboard

**Location:** `force-app/main/default/lwc/onboardingAdminDashboard/`

**Purpose:** Admin dashboard for onboarding system management and monitoring.

**Key Features:**

- Admin metrics and KPIs
- System health monitoring
- Configuration management shortcuts
- Validation and messaging issue tracking
- Tabbed interface with:
  - Validation Failures Tab (`validationFailuresTab`)
  - Messaging Issues Tab (`messagingIssuesTab`)
  - Adobe Sync Failures Tab (`adobeSyncFailuresTab`)

**Usage:**
Used by administrators for system oversight and management.

### accountProgramOnboardingModal

**Location:** `force-app/main/default/lwc/accountProgramOnboardingModal/`

**Purpose:** Modal for selecting account and program combinations for onboarding initiation.

**Key Features:**

- Account selection
- Program selection
- Onboarding initiation

**Usage:**
Used to start new onboarding processes from account or program contexts.

### messagingIssuesPanel

**Location:** `force-app/main/default/lwc/messagingIssuesPanel/`

**Purpose:** Admin panel for viewing and managing messaging issues (SMS/email failures).

**Key Features:**

- Lists messaging issues in datatable with pagination
- Shows issue details: Name, Type, Status, Onboarding, Account, Reason, Attempts, Last Attempt, Failures
- Retry functionality for failed messages
- Dismiss functionality for resolved issues
- Detail drawer with issue information
- Navigation to related records
- Row-level status feedback (color coding)
- Async operation handling with disabled buttons during operations

**Columns:**

- Name, Type, Status, Onboarding, Account, Reason, Attempts, Last Attempt, Failures, Actions

**Dependencies:**

- `OnboardingAdminDashboardController.getMessagingIssues()`
- `OnboardingAdminDashboardController.retryMessaging()`
- `OnboardingAdminDashboardController.dismissMessagingIssue()`

**Usage:**
Used in admin dashboard for monitoring and resolving messaging issues.

### onboardingResumePanel

**Location:** `force-app/main/default/lwc/onboardingResumePanel/`

**Purpose:** Panel for resuming onboarding progress. Shows completion status and navigates to next incomplete requirement.

**Key Features:**

- Displays completion percentage with progress bar
- Shows last completed requirement
- Shows next incomplete requirement
- Resume button to navigate to next incomplete requirement or field
- Progress visualization

**API:**

- `@api recordId` - Onboarding record ID (renamed from onboardingId - properties starting with "on" are reserved)

**Properties:**

- `resumeContext` - Resume context data from Apex
- `isLoading` - Loading state

**Computed Properties:**

- `hasIncompleteRequirements` - Whether there are incomplete requirements
- `completionPercentage` - Completion percentage (0-100)
- `lastCompletedRequirementName` - Name of last completed requirement
- `nextIncompleteRequirementName` - Name of next incomplete requirement
- `progressBarStyle` - CSS style for progress bar

**Methods:**

- `handleResume()` - Navigates to next incomplete requirement or field

**Dependencies:**

- `OnboardingApplicationService.getResumeContext()` - Returns resume context with next incomplete requirement

**Usage:**
Used on onboarding record pages to help users resume their progress.

### requirementFieldAutoSave

**Location:** `force-app/main/default/lwc/requirementFieldAutoSave/`

**Purpose:** Auto-saves requirement field values with configurable interval and immediate save on blur.

**Key Features:**

- Auto-saves field values at configurable intervals (default 30 seconds)
- Immediate save on field blur
- Saves on component unmount
- Shows last saved timestamp
- Handles encrypted fields
- Supports multiple field types

**API:**

- `@api requirementFieldValueId` - Field value record ID
- `@api requirementFieldId` - Requirement field ID
- `@api requirementRecordId` - Onboarding requirement record ID (renamed from onboardingRequirementId)
- `@api fieldApiName` - Field API name
- `@api fieldType` - Field type
- `@api isEncrypted` - Whether field is encrypted
- `@api autoSaveInterval` - Auto-save interval in milliseconds (default: 30000)
- `@api fieldLabel` - Field label for display

**Properties:**

- `fieldValue` - Current field value
- `isSaving` - Whether save is in progress
- `lastSaved` - Last saved timestamp
- `saveTimer` - Auto-save timer reference

**Methods:**

- `handleValueChange(event)` - Handles field value changes and resets timer
- `handleFieldBlur()` - Saves immediately on blur
- `saveFieldValue()` - Saves field value to server
- `startAutoSaveTimer()` - Starts auto-save timer
- `resetAutoSaveTimer()` - Resets auto-save timer

**Dependencies:**

- `RequirementFieldValueController.saveFieldValue()` - Saves field value

**Usage:**
Used in requirement forms to automatically save user input without requiring explicit save actions.

### validationFailuresPanel

**Location:** `force-app/main/default/lwc/validationFailuresPanel/`

**Purpose:** Admin panel for viewing validation failures with filtering capabilities.

**Key Features:**

- Lists validation failures in datatable
- Date range filtering (Last 24 Hours, Last 7 Days, Last 30 Days, All Time)
- Validation type filtering (Format, Cross-Field, External, Other)
- Shows failure details: Name, Rule, Field API, Result, Message, Validated On, Created By, Created

**Columns:**

- Name, Rule, Field API, Result, Message, Validated On, Created By, Created

**Properties:**

- `failures` - List of validation failures
- `dateRange` - Selected date range filter
- `validationType` - Selected validation type filter
- `isLoading` - Loading state

**Methods:**

- `loadData()` - Loads validation failures with current filters
- `handleDateRangeChange(event)` - Updates date range filter
- `handleValidationTypeChange(event)` - Updates validation type filter

**Dependencies:**

- `OnboardingAdminDashboardController.getValidationFailures()` - Returns validation failures with filters

**Usage:**
Used in admin dashboard for monitoring validation failures.

### progressHeader

**Location:** `force-app/main/default/lwc/progressHeader/`

**Purpose:** Displays overall onboarding progress and SLA/Risk badges for the Dealer.

**Key Features:**

- Progress percentage display (0-100)
- Risk badge display (On Track, At Risk, Overdue)
- Active programs list
- Visual progress bar
- Color-coded risk indicators

**API:**

- `@api progressPercent` - Progress percentage (0-100)
- `@api riskBadge` - Risk badge text ('On Track' | 'At Risk' | 'Overdue')
- `@api activePrograms` - Array of active programs [{ id, name }]

**Computed Properties:**

- `progressLabel` - Formatted progress label (e.g., "75% Complete")
- `riskClass` - CSS class for risk badge styling

**Usage:**
Used to display onboarding progress and risk status. Inputs are provided by parent via GraphQL/Apex.

### requirementChecklist

**Location:** `force-app/main/default/lwc/requirementChecklist/`

**Purpose:** Displays requirements in a checklist format for easy tracking.

**Key Features:**

- Checklist-style requirement display
- Completion status indicators
- Requirement grouping and organization

**Usage:**
Used for displaying requirements in a user-friendly checklist format.

### requirementFormPanel

**Location:** `force-app/main/default/lwc/requirementFormPanel/`

**Purpose:** Form panel for entering requirement field values.

**Key Features:**

- Dynamic form rendering based on requirement fields
- Field validation
- Save functionality

**Usage:**
Used for displaying and editing requirement forms.

### requirementRuleBuilder

**Location:** `force-app/main/default/lwc/requirementRuleBuilder/`

**Purpose:** Builder UI for creating and configuring requirement validation rules.

**Key Features:**

- Rule creation and editing
- Rule condition configuration
- Rule testing

**Usage:**
Used for building requirement validation rules.

### validationRuleBuilder

**Location:** `force-app/main/default/lwc/validationRuleBuilder/`

**Purpose:** Builder UI for creating and configuring validation rules.

**Key Features:**

- Validation rule creation
- Rule logic configuration
- Rule preview

**Usage:**
Used for building validation rules.

### validationRuleTester

**Location:** `force-app/main/default/lwc/validationRuleTester/`

**Purpose:** Tool for testing validation rules against sample data.

**Key Features:**

- Rule testing interface
- Sample data input
- Test result display

**Usage:**
Used for testing validation rules before deployment.

### overrideAuditPanel

**Location:** `force-app/main/default/lwc/overrideAuditPanel/`

**Purpose:** Admin panel for viewing override audit records.

**Key Features:**

- Lists override operations
- Audit trail display
- Filtering capabilities

**Usage:**
Used in admin dashboard for monitoring override operations.

### nextBestActionsPanel

**Location:** `force-app/main/default/lwc/nextBestActionsPanel/`

**Purpose:** Panel displaying recommended next actions for onboarding records.

**Key Features:**

- Action recommendations
- Priority-based ordering
- Action execution

**Usage:**
Used to guide users on next steps in onboarding process.

### repDealerQueue

**Location:** `force-app/main/default/lwc/repDealerQueue/`

**Purpose:** Queue view for sales representatives showing their dealer onboarding records.

**Key Features:**

- Rep-specific onboarding queue
- Filtering and sorting
- Quick actions

**Usage:**
Used by sales representatives to manage their dealer onboarding queue.

### programSetupWizardContainer

**Location:** `force-app/main/default/lwc/programSetupWizardContainer/`

**Purpose:** Container component for program setup wizard flow.

**Key Features:**

- Wizard flow management
- Step navigation
- Progress tracking

**Usage:**
Used as container for program setup wizard flows.

### vendorOnboardingPicker

**Location:** `force-app/main/default/lwc/vendorOnboardingPicker/`

**Purpose:** Component for picking vendors in onboarding flows.

**Key Features:**

- Vendor search
- Vendor selection
- Vendor creation

**Usage:**
Used in onboarding flows for vendor selection.

### vendorProgramQuickActions

**Location:** `force-app/main/default/lwc/vendorProgramQuickActions/`

**Purpose:** Quick action buttons for vendor program operations.

**Key Features:**

- Quick action buttons
- Common operations
- Context-aware actions

**Usage:**
Used on vendor program record pages for quick actions.

### vendorProgramOnboardingWizardModal

**Location:** `force-app/main/default/lwc/vendorProgramOnboardingWizardModal/`

**Purpose:** Modal wrapper for vendor program onboarding wizard.

**Key Features:**

- Modal display
- Wizard flow integration
- Close handling

**Usage:**
Used to display vendor program onboarding wizard in a modal.

## Utility Components

### utils

**Location:** `force-app/main/default/lwc/utils/`

**Purpose:** Shared utility module for error handling and toast notifications. Provides reusable functions for consistent error handling across LWC components.

**Key Functions:**

- `extractErrorMessage(error, defaultMessage)` - Extracts meaningful error messages from various error formats
  - Handles Salesforce error formats (error.body array, error.body.message, error.body.pageErrors)
  - Falls back to error.message or defaultMessage
  - Returns user-friendly error string

- `showToast(component, title, message, variant)` - Shows a toast notification
  - Uses `lightning/platformShowToastEvent`
  - Supports variants: success, error, warning, info
  - Dispatches toast event from component

- `handleError(component, error, defaultMessage, debugMode)` - Handles errors and shows toast notification
  - Combines error extraction and toast display
  - Optional debug mode for console logging
  - Shows error toast automatically

**Usage:**

```javascript
import { extractErrorMessage } from "c/utils";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// In component method
try {
  await someApexMethod();
} catch (error) {
  this.dispatchEvent(
    new ShowToastEvent({
      title: "Error",
      message: extractErrorMessage(error, "An error occurred"),
      variant: "error"
    })
  );
}
```

**Benefits:**

- Consistent error handling across all components
- User-friendly error messages
- Centralized error parsing logic
- Reduces code duplication

**Note:** Components that extend `onboardingStepBase` have built-in `showToast()` method, but can still use `extractErrorMessage()` from utils.

## Component Communication

### Event Flow

Stage Components

vendorProgramOnboardingVendor
Purpose: Stage component for selecting/creating a vendor.

Context:
vendorProgramId - Current vendor program ID
stageId - Current stage ID
vendorProgramOnboardingVendorProgramSearchOrCreate
Purpose: Stage component for searching or creating a vendor program.

vendorProgramOnboardingVendorProgramCreate
Purpose: Stage component for creating a new vendor program.

vendorProgramOnboardingVendorProgramGroup
Purpose: Stage component for assigning a program group.

vendorProgramOnboardingVendorProgramRequirementGroup
Purpose: Stage component for assigning a requirement group.

vendorProgramOnboardingVendorProgramRecipientGroup
Purpose: Stage component for assigning a recipient group.

vendorProgramOnboardingRecipientGroup
Purpose: Stage component for configuring recipient group details.

vendorProgramOnboardingRecipientGroupMembers
Purpose: Stage component for adding members to a recipient group.

vendorProgramOnboardingRequiredCredentials
Purpose: Stage component for managing required credentials.

vendorProgramOnboardingTrainingRequirements
Purpose: Stage component for managing training requirements.

Management Components
onboardingRequirementsPanel
Location: force-app/main/default/lwc/onboardingRequirementsPanel/
Purpose: Displays and manages onboarding requirements for an onboarding record.
Key Features:
Lists all requirements for an onboarding
Allows status updates via combobox
Triggers status re-evaluation after updates
Displays requirement details

API:
@api recordId - Onboarding record ID (from record page context)

Dependencies:
OnboardingRequirementsPanelController.getRequirements()
OnboardingRequirementsPanelController.updateRequirementStatuses()
OnboardingRequirementsPanelController.runRuleEvaluation()

Usage:
Add to an Onboarding record page:
<c-onboarding-requirements-panel record-id={recordId}></c-onboarding-requirements-panel>: String,
stageId: String
}### Navigation Events

Stage components fire custom events:

- `next` - Request to advance to next stage
- `back` - Request to return to previous stage

## Best Practices

1. **Stage Components**: Should be self-contained and handle their own data operations
2. **Error Handling**: All components should handle errors gracefully
3. **Loading States**: Show loading indicators during async operations
4. **Progress Persistence**: Stage components should trigger progress saves
5. **Event Communication**: Use custom events for parent-child communication

## Related Documentation

- [Onboarding Process Flow](../processes/onboarding-process.md)
- [Application Flow Engine](../processes/application-flow-engine.md)
- [Apex Classes](./apex-classes.md)

onboardingStatusRulesEngine
Location: force-app/main/default/lwc/onboardingStatusRulesEngine/
Purpose: Admin UI for configuring onboarding status rules.
Key Features:
Select vendor program group and requirement group
Load existing rules
Edit rules in datatable
Save rule changes
Dependencies:
OnboardingStatusRulesEngineController.getVendorProgramGroups()
OnboardingStatusRulesEngineController.getRequirementGroups()
OnboardingStatusRulesEngineController.getRules()
OnboardingStatusRulesEngineController.saveRules()
onboardingStatusRuleList
Location: force-app/main/default/lwc/onboardingStatusRuleList/
Purpose: Displays a list of onboarding status rules.
Key Features:
Filters by vendor program group
Displays rules in datatable
Edit button for each rule
Dependencies:
OnboardingStatusRuleController.getRules()
onboardingStatusRulesManager
Location: force-app/main/default/lwc/onboardingStatusRulesManager/
Purpose: Manager component for onboarding status rules (wrapper/container).
onboardingRuleModal
Location: force-app/main/default/lwc/onboardingRuleModal/
Purpose: Modal dialog for creating/editing onboarding rules.
requirementConditionsList
Location: force-app/main/default/lwc/requirementConditionsList/
Purpose: Displays and manages requirement conditions for rules.
Utility Components
vendorProgramHighlights
Location: force-app/main/default/lwc/vendorProgramHighlights/
Purpose: Displays highlights/summary information for a vendor program.
vendorSelector
Location: force-app/main/default/lwc/vendorSelector/
Purpose: Reusable component for selecting vendors.
onboardingAppHeaderBar
Location: force-app/main/default/lwc/onboardingAppHeaderBar/
Purpose: Header bar component for onboarding applications.
Configuration:
isActiveFieldApiName - API name of the active field (default: "Activec")
onboardingApplicationFlow
Location: force-app/main/default/lwc/onboardingApplicationFlow/
Purpose: Generic onboarding application flow component.
onboardingOrderStatusViewer
Location: force-app/unpackaged/lwc/onboardingOrderStatusViewer/
Purpose: Displays order status for onboarding records.
onboardingStatusRuleForm
Location: force-app/unpackaged/lwc/onboardingStatusRuleForm/
Purpose: Form for creating/editing status rules.
onboardingECC
Location: force-app/unpackaged/lwc/onboardingECC/
Purpose: External Contact Credential management component.
Component Communication
Event Flow
vendorProgramOnboardingFlow
↓ (processId)
onboardingFlowEngine
↓ (componentName, context)
onboardingStageRenderer
↓ (dynamic component)
Stage Component (e.g., vendorProgramOnboardingVendor)
↓ (next/back events)
onboardingStageRenderer
↓ (next/back events)
onboardingFlowEngine
↓ (progress update)
OnboardingApplicationServicey order

- `getProcessDetails(Id processId)` - Returns process details
- `saveProgress(Id processId, Id vendorProgramId, Id stageId)` - Saves progress and logs stage completion
- `getProgress(Id vendorProgramId, Id processId)` - Retrieves saved progress
- `getProcessIdForVendorProgram(Id vendorProgramId)` - Resolves process ID for a vendor program

**Usage:**
Primary service used by `onboardingFlowEngine` LWC component.

### OnboardingRulesService

**Location:** `force-app/main/default/classes/OnboardingRulesService.cls`

**Purpose:** Service for managing onboarding status rules and requirements.

**Key Methods:**

- `getRulesEngineRecords(Id engineId)` - Returns rules for a rules engine
- `createOrUpdateRule(Onboarding_Status_Rule__c rule)` - Creates or updates a rule
- `deleteRule(Id ruleId)` - Deletes a rule
- `getRequirementsByVPR(Id onboardingId)` - Returns requirements mapped by Vendor Program Requirement ID
- `getVendorProgramId(Id onboardingId)` - Gets vendor program ID from onboarding
- `getVendorProgramGroupIds(Id vendorProgramId)` - Gets group IDs for a vendor program
- `getRulesForGroups(List<Id> groupIds)` - Gets rules for vendor program groups

**Usage:**
Used by status evaluation engine and rules management UI.

### OnboardingStatusEvaluator

**Location:** `force-app/main/default/classes/OnboardingStatusEvaluator.cls`

**Purpose:** Evaluates onboarding status based on rules engine configuration.

**Key Methods:**

- `evaluateAndApplyStatus(Onboarding__c onboarding)` - Evaluates rules and updates onboarding status

**Flow:**

1. Gets requirements for onboarding
2. Gets vendor program ID
3. Gets vendor program group IDs
4. Gets rules for groups
5. Evaluates each rule
6. Updates onboarding status when rule passes

**Usage:**
Called from flows when onboarding records change.

### OnboardingRuleEvaluator

**Location:** `force-app/main/default/classes/OnboardingRuleEvaluator.cls`

**Purpose:** Evaluates individual rules against requirement statuses.

**Key Methods:**

- `evaluateRule(Onboarding_Status_Rules_Engine__c rule, Map<Id, Onboarding_Requirement__c> reqByVPR)` - Evaluates a rule

**Logic:**

- Supports AND, OR, and Custom evaluation logic
- Uses `OnboardingExpressionEngine` for custom expressions

### OnboardingExpressionEngine

**Location:** `force-app/main/default/classes/OnboardingExpressionEngine.cls`

**Purpose:** Parses and evaluates custom expression logic for rules.

**Key Methods:**

- `evaluate(String expression, Map<Id, Onboarding_Requirement__c> reqByVPR)` - Evaluates a custom expression

**Expression Syntax:**
Supports logical operators and requirement status checks.

## Controllers

### OnboardingRequirementsPanelController

**Location:** `force-app/main/default/classes/OnboardingRequirementsPanelController.cls`

**Purpose:** Controller for the onboarding requirements panel LWC.

**Key Methods:**

- `getRequirements(Id onboardingId)` - Returns requirements for an onboarding
- `updateRequirementStatuses(List<Onboarding_Requirement__c> updates)` - Updates requirement statuses
- `runRuleEvaluation(Id onboardingId)` - Triggers status re-evaluation

**Usage:**
Used by `onboardingRequirementsPanel` LWC.

### OnboardingStatusRulesEngineController

**Location:** `force-app/main/default/classes/OnboardingStatusRulesEngineController.cls`

**Purpose:** Controller for the status rules engine management UI.

**Key Methods:**

- `getVendorProgramGroups()` - Returns vendor program groups for picklist
- `getRequirementGroups()` - Returns requirement groups for picklist
- `getRules(Id vendorProgramGroupId, Id requirementGroupId)` - Returns rules for selected groups
- `saveRules(List<Onboarding_Status_Rule__c> rules)` - Saves rule changes

**Usage:**
Used by `onboardingStatusRulesEngine` LWC.

### OnboardingStatusRuleController

**Location:** `force-app/main/default/classes/OnboardingStatusRuleController.cls`

**Purpose:** Controller for status rule list component.

**Key Methods:**

- `getRules(Id vendorProgramGroupId)` - Returns rules for a vendor program group

**Usage:**
Used by `onboardingStatusRuleList` LWC.

### OnboardingAppActivationService

**Location:** `force-app/main/default/classes/services/OnboardingAppActivationService.cls`

**Purpose:** Service for activation actions with direct LWC integration (consolidated from controller and orchestrator).

**Key Methods:**

- `activate(Id recordId, String objectApiName)` - @AuraEnabled method for direct LWC calls
- Activation logic for various object types

**Note:** The `OnboardingAppActivationController` and `OnboardingAppActivationOrchestrator` have been consolidated into this service.

## Services (Consolidated)

**Note:** Most orchestrators have been consolidated into services. Services now expose @AuraEnabled methods for direct LWC integration.

### Consolidated Domain Services

**VendorDomainService** - Vendor, VendorProgram, VendorProgramGroup operations
**RequirementDomainService** - VendorProgramRequirement, VendorProgramRequirementGroup operations
**CommunicationDomainService** - CommunicationTemplate, RecipientGroup operations
**VendorOnboardingService** - Vendor eligibility and onboarding logic

**Note:** The `VendorOnboardingWizardService` facade has been removed. Controllers now call domain services directly.

## Handlers

### OnboardingAppRuleEngineHandler

**Location:** `force-app/main/default/classes/OnboardingAppRuleEngineHandler.cls`

**Purpose:** Handler for rule engine events and triggers.

### OnboardingAppVendorProgramReqHdlr

**Location:** `force-app/main/default/classes/handlers/OnboardingAppVendorProgramReqHdlr.cls`

**Purpose:** Handler for vendor program requirement events.

### OnboardingStatusTrackerHandler

**Location:** `force-app/main/default/classes/handlers/OnboardingStatusTrackerHandler.cls`

**Purpose:** Tracks onboarding status changes.

## Validation Rules

### OnboardingAppRuleRegistry

**Location:** `force-app/main/default/classes/OnboardingAppRuleRegistry.cls`

**Purpose:** Central registry of validation rules for onboarding application objects.

**Key Methods:**

- `getRules()` - Returns map of object API names to validation rule lists

**Registered Rules:**

- `Vendor_Program_Recipient_Group__c`:
  - `RequireParentVersionOnActivationRule`
  - `OnlyOneActiveRecGrpPerPrgrmRule`
  - `RecipientAndProgramMustBeActiveRule`
  - `PreventDupRecGrpAssignmentRule`

### OnboardingAppValidationRule

**Location:** `force-app/main/default/classes/OnboardingAppValidationRule.cls`

**Purpose:** Interface for validation rules.

**Key Methods:**

- `validate(SObject record)` - Validates a record
- `getErrorMessage()` - Returns error message

### Rule Implementations

- **RequireParentVersionOnActivationRule** - Requires parent version on activation
- **OnlyOneActiveRecGrpPerPrgrmRule** - Ensures only one active recipient group per program
- **RecipientAndProgramMustBeActiveRule** - Validates recipient and program are active
- **PreventDupRecGrpAssignmentRule** - Prevents duplicate recipient group assignments

## Actions

### OnboardingAppActivationAction

**Location:** `force-app/main/default/classes/actions/OnboardingAppActivationAction.cls`

**Purpose:** Action class for activating records.

**Key Methods:**

- `activate(List<Request> requestList)` - Activates multiple records

**Request Class:**

- `recordId` - Record ID to activate
- `objectApiName` - Object API name

## Repositories

Repository classes follow the pattern `*Repo.cls` and handle data access operations:

- `OnboardingAppVendorProgramReqRepo` - Vendor program requirement data access

## DTOs (Data Transfer Objects)

DTO classes in `dto/` package provide structured data transfer:

- Various DTO classes for data transfer between layers

## Helpers

Helper classes in `helpers/` package provide utility functions:

- Various helper classes for common operations

## Jobs

Scheduled and batch job classes in `jobs/` package:

- Various job classes for background processing

## Test Classes

Test classes follow naming convention `*Test.cls`:

- `OnboardingRulesServiceTest`
- `OnboardingStatusEvaluatorTest`
- `OnlyOneActiveRecGrpPerPrgrmRuleTest`
- `PreventDupRecGrpAssignmentRuleTest`
- `RecipientAndProgramMustBeActiveRuleTest`
- `RequireParentVersionOnActivationRuleTest`
- And many more...

## Class Organization

Context Object
Stage components receive a context object:

{
vendorProgramId: String,
stageId: String
}ss logic in service classes 2. **Controllers**: Thin controllers that delegate to services 3. **Orchestrators**: Coordinate multiple services 4. **Repositories**: Data access abstraction 5. **Sharing**: Use `with sharing` for security 6. **Error Handling**: Proper exception handling 7. **Testing**: Comprehensive test coverage

## Related Documentation

- [LWC Components](./lwc-components.md)
- [API Reference](../api/apex-api.md)
- [Architecture Overview](../architecture/overview.md)

Navigation Events
Stage components fire custom events:
next - Request to advance to next stage
back - Request to return to previous stage
Best Practices
Stage Components: Should be self-contained and handle their own data operations
Error Handling: All components should handle errors gracefully
Loading States: Show loading indicators during async operations
Progress Persistence: Stage components should trigger progress saves
Event Communication: Use custom events for parent-child communication
Related Documentation
Onboarding Process Flow
Application Flow Engine
Apex Classes

## 6. Create docs/components/apex-classes.md

Create `docs/components/apex-classes.md`:

# Apex Classes

## Service Layer

### OnboardingApplicationService

**Location:** `force-app/main/default/classes/OnboardingApplicationService.cls`

**Purpose:** Core service for managing onboarding application processes, stages, and progress.

**Key Methods:**

- `getStagesForProcess(Id processId)` - Returns stages for a process, ordered by display order
- `getProcessDetails(Id processId)` - Returns process details
- `saveProgress(Id processId, Id vendorProgramId, Id stageId)` - Saves progress and logs stage completion
- `getProgress(Id vendorProgramId, Id processId)` - Retrieves saved progress
- `getProcessIdForVendorProgram(Id vendorProgramId)` - Resolves process ID for a vendor program

**Usage:**
Primary service used by `onboardingFlowEngine` LWC component.

### OnboardingRulesService

**Location:** `force-app/main/default/classes/OnboardingRulesService.cls`

**Purpose:** Service for managing onboarding status rules and requirements.

**Key Methods:**

- `getRulesEngineRecords(Id engineId)` - Returns rules for a rules engine
- `createOrUpdateRule(Onboarding_Status_Rule__c rule)` - Creates or updates a rule
- `deleteRule(Id ruleId)` - Deletes a rule
- `getRequirementsByVPR(Id onboardingId)` - Returns requirements mapped by Vendor Program Requirement ID
- `getVendorProgramId(Id onboardingId)` - Gets vendor program ID from onboarding
- `getVendorProgramGroupIds(Id vendorProgramId)` - Gets group IDs for a vendor program
- `getRulesForGroups(List<Id> groupIds)` - Gets rules for vendor program groups

**Usage:**
Used by status evaluation engine and rules management UI.

### OnboardingStatusEvaluator

**Location:** `force-app/main/default/classes/OnboardingStatusEvaluator.cls`

**Purpose:** Evaluates onboarding status based on rules engine configuration.

**Key Methods:**

- `evaluateAndApplyStatus(Onboarding__c onboarding)` - Evaluates rules and updates onboarding status

**Flow:**

1. Gets requirements for onboarding
2. Gets vendor program ID
3. Gets vendor program group IDs
4. Gets rules for groups
5. Evaluates each rule
6. Updates onboarding status when rule passes

**Usage:**
Called from flows when onboarding records change.

### OnboardingRuleEvaluator

**Location:** `force-app/main/default/classes/OnboardingRuleEvaluator.cls`

**Purpose:** Evaluates individual rules against requirement statuses.

**Key Methods:**

- `evaluateRule(Onboarding_Status_Rules_Engine__c rule, Map<Id, Onboarding_Requirement__c> reqByVPR)` - Evaluates a rule

**Logic:**

- Supports AND, OR, and Custom evaluation logic
- Uses `OnboardingExpressionEngine` for custom expressions

### OnboardingExpressionEngine

**Location:** `force-app/main/default/classes/OnboardingExpressionEngine.cls`

**Purpose:** Parses and evaluates custom expression logic for rules.

**Key Methods:**

- `evaluate(String expression, Map<Id, Onboarding_Requirement__c> reqByVPR)` - Evaluates a custom expression

**Expression Syntax:**
Supports logical operators and requirement status checks.

## Controllers

### OnboardingRequirementsPanelController

**Location:** `force-app/main/default/classes/OnboardingRequirementsPanelController.cls`

**Purpose:** Controller for the onboarding requirements panel LWC.

**Key Methods:**

- `getRequirements(Id onboardingId)` - Returns requirements for an onboarding
- `updateRequirementStatuses(List<Onboarding_Requirement__c> updates)` - Updates requirement statuses
- `runRuleEvaluation(Id onboardingId)` - Triggers status re-evaluation

**Usage:**
Used by `onboardingRequirementsPanel` LWC.

### OnboardingStatusRulesEngineController

**Location:** `force-app/main/default/classes/OnboardingStatusRulesEngineController.cls`

**Purpose:** Controller for the status rules engine management UI.

**Key Methods:**

- `getVendorProgramGroups()` - Returns vendor program groups for picklist
- `getRequirementGroups()` - Returns requirement groups for picklist
- `getRules(Id vendorProgramGroupId, Id requirementGroupId)` - Returns rules for selected groups
- `saveRules(List<Onboarding_Status_Rule__c> rules)` - Saves rule changes

**Usage:**
Used by `onboardingStatusRulesEngine` LWC.

### OnboardingStatusRuleController

**Location:** `force-app/main/default/classes/OnboardingStatusRuleController.cls`

**Purpose:** Controller for status rule list component.

**Key Methods:**

- `getRules(Id vendorProgramGroupId)` - Returns rules for a vendor program group

**Usage:**
Used by `onboardingStatusRuleList` LWC.

### OnboardingAppActivationService

**Location:** `force-app/main/default/classes/services/OnboardingAppActivationService.cls`

**Purpose:** Service for activation actions with direct LWC integration (consolidated from controller and orchestrator).

**Key Methods:**

- `activate(Id recordId, String objectApiName)` - @AuraEnabled method for direct LWC calls
- Activation logic for various object types

**Note:** The `OnboardingAppActivationController` and `OnboardingAppActivationOrchestrator` have been consolidated into this service.

## Services (Consolidated)

**Note:** Most orchestrators have been consolidated into services. Services now expose @AuraEnabled methods for direct LWC integration.

### Consolidated Domain Services

**VendorDomainService** - Vendor, VendorProgram, VendorProgramGroup operations
**RequirementDomainService** - VendorProgramRequirement, VendorProgramRequirementGroup operations
**CommunicationDomainService** - CommunicationTemplate, RecipientGroup operations
**VendorOnboardingService** - Vendor eligibility and onboarding logic

**Note:** The `VendorOnboardingWizardService` facade has been removed. Controllers now call domain services directly.

## Handlers

### OnboardingAppRuleEngineHandler

**Location:** `force-app/main/default/classes/OnboardingAppRuleEngineHandler.cls`

**Purpose:** Handler for rule engine events and triggers.

### OnboardingAppVendorProgramReqHdlr

**Location:** `force-app/main/default/classes/handlers/OnboardingAppVendorProgramReqHdlr.cls`

**Purpose:** Handler for vendor program requirement events.

### OnboardingStatusTrackerHandler

**Location:** `force-app/main/default/classes/handlers/OnboardingStatusTrackerHandler.cls`

**Purpose:** Tracks onboarding status changes.

## Validation Rules

### OnboardingAppRuleRegistry

**Location:** `force-app/main/default/classes/OnboardingAppRuleRegistry.cls`

**Purpose:** Central registry of validation rules for onboarding application objects.

**Key Methods:**

- `getRules()` - Returns map of object API names to validation rule lists

**Registered Rules:**

- `Vendor_Program_Recipient_Group__c`:
  - `RequireParentVersionOnActivationRule`
  - `OnlyOneActiveRecGrpPerPrgrmRule`
  - `RecipientAndProgramMustBeActiveRule`
  - `PreventDupRecGrpAssignmentRule`

### OnboardingAppValidationRule

**Location:** `force-app/main/default/classes/OnboardingAppValidationRule.cls`

**Purpose:** Interface for validation rules.

**Key Methods:**

- `validate(SObject record)` - Validates a record
- `getErrorMessage()` - Returns error message

### Rule Implementations

- **RequireParentVersionOnActivationRule** - Requires parent version on activation
- **OnlyOneActiveRecGrpPerPrgrmRule** - Ensures only one active recipient group per program
- **RecipientAndProgramMustBeActiveRule** - Validates recipient and program are active
- **PreventDupRecGrpAssignmentRule** - Prevents duplicate recipient group assignments

## Actions

### OnboardingAppActivationAction

**Location:** `force-app/main/default/classes/actions/OnboardingAppActivationAction.cls`

**Purpose:** Action class for activating records.

**Key Methods:**

- `activate(List<Request> requestList)` - Activates multiple records

**Request Class:**

- `recordId` - Record ID to activate
- `objectApiName` - Object API name

## Repositories

Repository classes follow the pattern `*Repo.cls` and handle data access operations:

- `OnboardingAppVendorProgramReqRepo` - Vendor program requirement data access

## DTOs (Data Transfer Objects)

DTO classes in `dto/` package provide structured data transfer:

- Various DTO classes for data transfer between layers

## Helpers

Helper classes in `helpers/` package provide utility functions:

- Various helper classes for common operations

## Jobs

Scheduled and batch job classes in `jobs/` package:

- Various job classes for background processing

## Test Classes

Test classes follow naming convention `*Test.cls`:

- `OnboardingRulesServiceTest`
- `OnboardingStatusEvaluatorTest`
- `OnlyOneActiveRecGrpPerPrgrmRuleTest`
- `PreventDupRecGrpAssignmentRuleTest`
- `RecipientAndProgramMustBeActiveRuleTest`
- `RequireParentVersionOnActivationRuleTest`
- And many more...

## Class Organization

classes/
├── actions/ # Action classes
├── controllers/ # LWC controllers
├── dto/ # Data transfer objects
├── handlers/ # Event/trigger handlers
├── helpers/ # Utility helpers
├── jobs/ # Scheduled/batch jobs
├── orchestrators/ # Orchestration logic
├── repository/ # Data access layer
├── resolver/ # Resolution logic
├── services/ # Business logic services
├── test/ # Test data factories
├── util/ # Utilities
└── wrappers/ # Wrapper classes

## Best Practices

1. **Service Layer**: Business logic in service classes
2. **Controllers**: Thin controllers that delegate to services
3. **Orchestrators**: Coordinate multiple services
4. **Repositories**: Data access abstraction
5. **Sharing**: Use `with sharing` for security
6. **Error Handling**: Proper exception handling
7. **Testing**: Comprehensive test coverage

## Related Documentation

- [LWC Components](./lwc-components.md)
- [API Reference](../api/apex-api.md)
- [Architecture Overview](../architecture/overview.md)
