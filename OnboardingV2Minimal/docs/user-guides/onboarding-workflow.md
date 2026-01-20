# Vendor Program Onboarding Workflow Guide

This guide walks you through the complete Vendor Program Onboarding workflow step by step.

## Overview

The Vendor Program Onboarding workflow is a guided, 10-step process that helps you create and configure a complete Vendor Program from scratch. Each step represents a specific set of tasks or information that must be completed.

## Audience and Terminology

This workflow is for Program Managers configuring Vendor Programs. Dealer refers to an Account record. Program Specialists (Sales) initiate Dealer onboarding from the Account quick action.

See [Terminology](../README.md#terminology) for role definitions.

See [User Journey Summary](./user-journey-summary.md) for the end-to-end flow.

**Note:** The workflow supports **Program Manager** and **Admin** roles, with some steps being Admin-only.

## Starting the Onboarding Process

### Prerequisites

- You must have appropriate permissions to create Vendor Programs
- An onboarding process must be configured in the system
- Component Library must be populated (handled by administrators)

### Steps

1. **Navigate to Vendor Program**
   - Go to the **Vendor Programs** tab or search for a specific Vendor Program
   - Open the Vendor Program record (or create a new one)

2. **Access the Onboarding Flow**
   - The onboarding flow component appears automatically on the record page
   - If you see a loading spinner, wait for the process to initialize
   - If you see an error about missing process, contact your administrator

3. **Review Process Information**
   - The flow header shows the process name
   - Progress indicator shows all stages and your current position

## Step-by-Step Process

### Step 1: Select Vendor

**Purpose**: Select or create the vendor account for this program.

**Actions**:
- Search for existing vendor accounts by name
- Create a new vendor if needed (enters as draft)
- Select the appropriate vendor using radio buttons

**Information Box**: Explains that vendors are business partners/suppliers and can have multiple programs. Best practice: Use official business name exactly.

**Completion**: Click **Next** to proceed with `vendorId`

### Step 2: Search or Create Vendor Program

**Purpose**: Search for existing vendor programs or create a new draft vendor program.

**Actions**:
- Search for existing vendor programs by name
- Select existing program using radio buttons
- OR create new draft vendor program with:
  - **Vendor Program Label** (`Label__c`) - Required text input
  - **Retail Option** (`Retail_Option__c`) - Required picklist
  - **Business Vertical** (`Business_Vertical__c`) - Required picklist

**Information Box**: Explains vendor programs and best practices for naming.

**Completion**: Click **Next** to proceed with `vendorProgramId`

**Note**: New vendor programs are created with `Status__c = 'Draft'` and `Active__c = false`.

### Step 3: Create Vendor Program in Draft

**Status**: Implicit - Vendor Program is already created in Draft status in Step 2.

### Step 4: Select Requirement Set OR Create Requirements

**Purpose**: Select existing Onboarding Requirement Set or create new requirements with inline template creation.

**Sub-Steps**:

#### Option A: Select Existing Requirement Set

1. **Search for Requirement Sets**
   - Enter search text and click Search
   - Select a requirement set using radio buttons
   - Click "Select and Continue"

2. **Confirm Selection**
   - Review selected requirement set details
   - View templates in the requirement set
   - Choose:
     - **Confirm Selection**: Links requirement set to Vendor Program
     - **Make Changes**: Creates new requirement set with naming convention

#### Option B: Create New Requirements

1. **Create Templates Inline**
   - Click "Create New Template" button
   - Fill in template form:
     - **Requirement Label** - Required
     - **Requirement Type** - Required picklist
     - **Status** - Required picklist
     - **Is Current Version** - Checkbox
   - Click "Create Template"
   - Template appears immediately in the list

2. **Create Requirements from Templates**
   - Click "Create Requirement" action on a template row
   - Requirement is created automatically from the template
   - Created requirements appear in the "Created Requirements" table

3. **Confirm All Requirements Created**
   - Review created requirements
   - Click "Confirm All Requirements Created" when done

**Information Box**: Explains requirement sets, templates, and requirements. Best practices for naming.

**Completion**: Click **Next** to proceed with `requirementSetId` and `requirementTemplateId`

**Naming Convention**: New Requirement Sets use `"Vendor Program Label - Onboarding Set"`

### Step 5: Create and Link Requirement Group Components

**Purpose**: Create and link Vendor Program Group, Vendor Program Requirement Group, and Vendor Program Group Member.

**Actions**:
- If Requirement Set was selected in Step 4:
  - System checks for historical group members
  - Option to use historical values or create new
  - Checkbox: "Use Historical Values"
- If creating new:
  - System creates all three components automatically
  - Uses naming conventions

**Information Box**: Explains the three components and their relationships.

**Completion**: Click "Create and Link Components" to proceed with `groupMemberId`

**Naming Conventions**:
- Vendor Program Group: `"Vendor Program Label - Vendor Program Group"`
- Requirement Group: `"Vendor Program Label - Requirement Group"`

### Step 6: Required Credentials (Conditional)

**Purpose**: Configure required credentials if needed.

**Actions**:
1. **Answer Prompt**: "Are Required Credentials needed for this Vendor Program?"
   - Select **Yes** or **No** using radio buttons
   - Click **Continue**

2. **If Yes**:
   - Credential management UI appears
   - Click "Add Credential" to create new credentials
   - Fill in form:
     - **Name** - Required
     - **Notes** - Optional
     - **Is Required** - Checkbox
     - **Sequence** - Number
   - Click **Save** to create
   - View existing credentials in data table

3. **If No**:
   - Skips directly to next step

**Information Box**: Explains required credentials and best practices.

**Completion**: Click **Next** to proceed (with `credentialsNeeded` flag)

### Step 7: Training Requirements

**Purpose**: Configure training requirements using dual-listbox selection.

**Actions**:
1. **Create Training Systems (if needed)**
   - Click "Add Training System" button
   - Fill in form:
     - **Name** - Required
     - **Active** - Checkbox (defaults to true)
   - Click **Save**
   - Training system appears immediately in dropdown

2. **Create Training Requirements**
   - Click "Add Training Requirement" button
   - Fill in form:
     - **Training System** - Required combobox (includes newly created systems)
     - **Description** - Optional
     - **Is Required** - Checkbox
   - Click **Save**
   - Training requirement appears in dual-listbox

3. **Select Training Requirements**
   - Use dual-listbox to move items between "Available" and "Selected for Group"
   - Moving to "Selected for Group" sets `Is_Required__c = true`
   - Moving to "Available" sets `Is_Required__c = false`
   - Bottom table shows "Required Training Requirements" in real-time

**Information Box**: Explains training requirements and best practices.

**Completion**: Click **Next** to proceed

**Note**: The `Name` field on `Training_Requirement__c` is auto-number and not shown in the form.

### Step 8: Status Rules Engine

**Purpose**: Select or create Status Rules Engine with historical data detection.

**Actions**:

#### Option A: Historical Engine Found

1. **Confirmation View**
   - System detects historical Status Rules Engine from Requirement Set
   - Shows list of available engines with radio buttons
   - Select an engine
   - Choose:
     - **Confirm Selection**: Uses selected engine
     - **Make Changes**: Creates new engine

#### Option B: Create New Engine

1. **Search Existing Engines**
   - Enter search text and click Search
   - Select from search results using row action

2. **Create New Engine**
   - Click "Create New Rules Engine" button
   - Fill in form:
     - **Name** - Required
     - **Evaluation Logic** - Required picklist (ALL, ANY, CUSTOM)
     - **Required Status** - Required picklist
     - **Target Onboarding Status** - Required picklist
     - **Requirement Group ID** - Optional
     - **Program Group ID** - Optional
   - Click "Create Rules Engine"

**Information Box**: Explains Status Rules Engine and best practices.

**Completion**: Click **Next** to proceed with `statusRulesEngineId`

**Note**: After selecting/creating engine, proceed to Status Rule Builder to create individual rules.

### Step 9: Recipient Groups (Admin Only)

**Purpose**: Create or select Recipient Groups, add members, and link to Vendor Program.

**Note**: This step is **Admin-only**. Regular users skip to Step 10.

**Actions**:

#### View 1: Select Existing or Create New

1. **Existing Groups**
   - If groups exist for Vendor Program:
     - View list in data table
     - Click "Use Existing Groups" to proceed
     - OR click "Create New Group" to create new

2. **No Existing Groups**
   - Search for recipient groups
   - Select existing group using radio buttons
   - OR click "Create New Group" button

#### View 2: Create New Group

1. **Create Group**
   - Fill in form:
     - **Group Name** - Required
     - **Group Type** - Required picklist (defaults to 'User')
   - Click "Create Group"
   - Automatically proceeds to Add Members view

#### View 3: Add Members

1. **Select Users**
   - Use dual-listbox to select users
   - Available users shown on left
   - Selected users shown on right
   - Click "Add Members" to add to group
   - OR click "Skip - Link to Vendor Program" to skip adding members

2. **View Current Members**
   - Data table shows current group members
   - Displays User Name, Email, Member Type, Recipient Type

3. **Link to Vendor Program**
   - Click "Skip - Link to Vendor Program" or proceed after adding members
   - Group is linked to Vendor Program via `Vendor_Program_Recipient_Group__c`

**Information Box**: Explains recipient groups and best practices.

**Completion**: Click **Next** to proceed with `recipientGroupId`

### Step 10: Communication Template Selection

**Purpose**: Select Communication Template, Recipient Group, and trigger condition.

**Actions**:
1. **Select Communication Template**
   - Choose from dropdown of available templates
   - Required field

2. **Select Recipient Group**
   - Choose from dropdown of recipient groups for Vendor Program
   - Pre-selected if provided from Step 9
   - Required field

3. **Enter Trigger Condition**
   - Enter text describing when to send (e.g., "Onboarding Status = 'Setup Complete'")
   - Required field
   - Placeholder shows example format

4. **Save and Continue**
   - Click "Save and Continue" to create link
   - System creates `Vendor_Program_Recipient_Group__c` with template and condition

**Information Box**: Explains communication templates, recipient groups, and trigger conditions. Shows example format.

**Completion**: Click **Next** to proceed

### Step 10 (Final): Finalize Vendor Program

**Purpose**: Complete onboarding setup and navigate to Vendor Program.

**Actions**:
1. **Review Summary**
   - View checklist of completed steps:
     - ✅ Vendor Program created in Draft status
     - ✅ Onboarding Requirement Set configured
     - ✅ Vendor Program Requirements created
     - ✅ Requirement Groups linked
     - ✅ Training Requirements configured
     - ✅ Status Rules Engine set up
     - ✅ Communication Templates and Recipient Groups configured

2. **Complete**
   - Click "Complete and View Vendor Program"
   - Navigates to Vendor Program record page
   - Vendor Program remains in Draft status (activation happens separately)

**Information Box**: Success message with summary and next steps.

**Completion**: Process complete!

## Navigation

### Moving Forward

- Click **Next** after completing each stage
- The system automatically saves your progress
- Data from each step is stored and passed to subsequent steps
- You can return to previous stages using **Back**

### Moving Backward

- Click **Back** to return to the previous stage
- Your progress is saved when navigating backward
- You can review and modify previous stage data
- Context data is preserved in the flow engine

### Progress Indicator

- Shows all stages in the process
- Highlights the current stage
- Marks completed stages
- Displays stage labels for easy reference

## Saving Progress

### Automatic Saving

- Progress is saved automatically when you click **Next** or **Back**
- Current stage is tracked in `Onboarding_Application_Progress__c`
- Stage completion is logged in `Onboarding_Application_Stage_Completion__c`
- Step data is stored in flow engine's `_stepData` map for context passing

### Resuming Later

- Your progress is saved automatically
- Return to the Vendor Program record to resume
- The flow will start from your last completed stage
- All context data is preserved

## Completing the Process

### Final Stage

1. Complete all required actions in Step 10 (Finalize)
2. Click "Complete and View Vendor Program"
3. Review the success message and checklist
4. You are navigated to the Vendor Program record page

### Post-Completion

- Vendor Program is fully configured but remains in Draft status
- All related records are created and linked:
  - Requirement Set and Templates
  - Vendor Program Requirements
  - Requirement Groups
  - Training Requirements
  - Status Rules Engine
  - Recipient Groups and Communication Templates
- Vendor Program can be activated later through the activation process

## Common Scenarios

### Scenario 1: Completing All Steps in One Session

1. Start the onboarding flow
2. Complete each step sequentially
3. Click **Next** after each step
4. Finish Step 10 (Finalize)
5. Review the completion confirmation
6. Navigate to Vendor Program record

### Scenario 2: Pausing and Resuming

1. Complete several steps
2. Navigate away from the record
3. Return later to the Vendor Program record
4. The flow resumes from your last step
5. Continue where you left off
6. All context data is preserved

### Scenario 3: Reviewing Previous Steps

1. While on any step, click **Back**
2. Navigate to the step you want to review
3. Review or modify the data
4. Click **Next** to continue forward
5. Context data is updated accordingly

### Scenario 4: Using Historical Data

1. In Step 4, select an existing Requirement Set
2. In Step 5, choose to use historical group members
3. In Step 8, choose to use historical Status Rules Engine
4. System automatically links historical data to new Vendor Program

### Scenario 5: Creating Everything New

1. In Step 4, skip Requirement Set selection and create new requirements
2. In Step 5, create new groups (not using historical)
3. In Step 8, create new Status Rules Engine
4. All components use naming conventions automatically

### Scenario 6: Handling Errors

1. If you see an error message, read it carefully
2. Common issues:
   - Missing required fields
   - Invalid data formats
   - Permission issues
   - Validation rule violations
3. Fix the issue and try again
4. See [Troubleshooting](./troubleshooting.md) for more help

## Best Practices

1. **Complete Steps Sequentially**: Work through steps in order for best results
2. **Save Frequently**: Progress is auto-saved, but don't navigate away during data entry
3. **Review Before Submitting**: Double-check your entries before clicking **Next**
4. **Use Back Button**: Don't refresh the page - use the **Back** button to navigate
5. **Complete in One Session**: If possible, complete all steps in one session
6. **Use Historical Data**: When available, reuse historical data from Requirement Sets
7. **Follow Naming Conventions**: System applies naming conventions automatically for new records
8. **Inline Creation**: Use inline creation features to create related records without leaving the screen

## User vs Admin Differences

### User Flow
- **Step 9**: Skips Recipient Group creation (uses existing groups)
- **Step 10**: Only selects Communication Template, Recipient Group, and trigger condition

### Admin Flow
- **Step 9**: Can create new Recipient Groups, add members, and link to Vendor Program
- **Step 10**: Same as User flow - selects Communication Template, Recipient Group, and trigger condition

## Related Documentation

- [Getting Started](./getting-started.md)
- [Managing Requirements](./managing-requirements.md)
- [Configuring Rules](./configuring-rules.md)
- [Troubleshooting](./troubleshooting.md)
- [Vendor Program Onboarding Flow](../processes/vendor-program-onboarding-flow.md)
- [Vendor Program Onboarding Wizard Components](../components/vendor-program-onboarding-wizard-components.md)
