# Status Evaluation Engine

## Overview

The Status Evaluation Engine is a rules-based system that automatically evaluates and updates onboarding status based on requirement completion. It uses a configurable rules engine that supports multiple evaluation logic types.

## Status Meaning

- Each `Onboarding__c` represents one Account's onboarding for one Vendor Program (`Vendor_Customization__c`).
- `Onboarding_Status__c` is the business-facing status of that onboarding (for example: New, In Process, Pending Initial Review, Setup Complete).
- Status is primarily driven by requirement completion via status rules; optional progress fallback may apply when enabled.

See [User Journey Summary](../user-guides/user-journey-summary.md) for the end-to-end flow.

## Rules Engine Override (Override_Status\_\_c)

`Override_Status__c` on `Onboarding_Status_Rules_Engine__c` forces the engine's `Target_Onboarding_Status__c` without checking rule conditions.
This is the rules-based exception for when a Dealer should pass even if requirements are not complete.

- Override engines are evaluated in rule evaluation order (`Sequence__c`); the first override engine found wins.
- External override (`External_Override_Enabled__c`) still blocks all automation, including override engines.

## External Override (Pass/Exception)

The override feature exists to track when an Account is granted a pass even when it does not meet the standard criteria.

- `External_Override_Enabled__c` on `Onboarding__c` disables automated status evaluation for that record.
- Override metadata is stored on `Onboarding__c` and audited in `Onboarding_External_Override_Log__c`.
- When an override is removed, the previous status should be restored (see `OnboardingExternalOverrideService`).

## Architecture

```
Onboarding__c Record Change
    ↓
Onboarding_Record_Trigger_Update_Onboarding_Status (Flow)
    ↓
OnboardingStatusEvaluator.evaluateAndApplyStatus()
    ↓
OnboardingRulesService.getRulesForGroups()
    ↓
For each Onboarding_Status_Rules_Engine__c:
    OnboardingRuleEvaluator.evaluateRule()
        ↓
    For each Onboarding_Status_Rule__c:
        Check requirement status matches expected status
        ↓
    Apply evaluation logic (ALL/ANY/CUSTOM)
        ↓
    If rule passes: Update Onboarding__c.Onboarding_Status__c
```

## Preview Evaluation

The status evaluation engine supports preview evaluation, allowing administrators to test rule evaluation without applying changes to onboarding records.

### Features

- **Preview Without Changes**: Evaluate rules and see what status would be applied without actually updating records
- **Evaluation Trace**: View detailed trace of which rules were evaluated, passed/failed status, and resulting status
- **Filtering**: Filter trace data by group name, engine name, and rule number
- **CSV Export**: Export evaluation trace data for analysis

### Usage

1. Navigate to `onboardingStatusRulesEngine` component
2. Select Vendor Program Group and Requirement Group
3. Load rules
4. Select an onboarding record from the dropdown
5. Click "Preview Evaluation" button
6. Review evaluation trace in the preview modal

### Preview Modal

The `statusEvaluationPreviewModal` component displays:

- Rule order and evaluation sequence
- Group and engine information
- Individual rule conditions and their pass/fail status
- Expected status vs actual status
- Evaluation logic used
- Resulting status that would be applied
- Short-circuit reasons (if evaluation stopped early)

### API

- `OnboardingStatusRulesEngineController.previewStatusEvaluation()` - Returns `List<StatusEvaluationTraceDTO>`
- `OnboardingStatusRulesEngineController.getOnboardingOptions()` - Returns onboarding records for selection

See [Status Evaluation Preview Modal](../components/lwc-components.md#statusevaluationpreviewmodal) for component documentation.

```

## Rule Structure

### Onboarding_Status_Rules_Engine__c

The rules engine defines a set of rules and evaluation logic:

**Key Fields:**
- `Vendor_Program_Group__c` - Associated vendor program group
- `Target_Onboarding_Status__c` - Status to set when rule passes
- `Override_Status__c` - Forces the target status without evaluating requirements
- `Sequence__c` - Rule evaluation order for engines in the same program group
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
```

"1 AND 2" # Rules 1 AND 2 must pass
"1 OR 2" # Rule 1 OR Rule 2 must pass
"(1 AND 2) OR 3" # (Rule 1 AND Rule 2) OR Rule 3
"1 AND (2 OR 3)" # Rule 1 AND (Rule 2 OR Rule 3)

````

**Expression Processing:**
1. Rule numbers are replaced with boolean values (true/false)
2. `AND` is replaced with `&&`
3. `OR` is replaced with `||`
4. Expression is evaluated recursively with parentheses support

## Evaluation Flow

### Step 1: Gather Requirements

```apex
Map<Id, Onboarding_Requirement__c> reqByVPR =
    OnboardingRulesService.getRequirementsByVPR(onboarding.Id);
````

Maps requirements by `Vendor_Program_Requirement__c` ID for quick lookup.

### Step 2: Get Vendor Program Groups

```apex
Id vendorProgramId = OnboardingRulesService.getVendorProgramId(onboarding.Id);
List<Id> groupIds = OnboardingRulesService.getVendorProgramGroupIds(vendorProgramId);
```

Retrieves vendor program groups associated with the onboarding.

### Step 3: Get Rules

```apex
List<Onboarding_Status_Rules_Engine__c> rules =
    OnboardingRulesService.getRulesForGroups(groupIds);
```

Retrieves all rules engines for the groups.

### Step 4: Evaluate Each Rule

For each rule engine:

1. **Build Conditions Map**: For each `Onboarding_Status_Rule__c`:
   - Look up requirement status
   - Compare with `Expected_Status__c`
   - Store result in map keyed by `Rule_Number__c`

2. **Apply Evaluation Logic**:
   - **ALL**: Check all values are true
   - **ANY**: Check at least one value is true
   - **CUSTOM**: Evaluate expression using `OnboardingExpressionEngine`

3. **Update Status**: If rule passes, update `Onboarding__c.Onboarding_Status__c` and return

## Expression Engine

### OnboardingExpressionEngine

Recursively evaluates boolean expressions with support for:

- Parentheses grouping
- AND (`&&`) and OR (`||`) operators
- Nested expressions

**Algorithm:**

1. Process innermost parentheses first
2. Evaluate OR operations
3. Evaluate AND operations
4. Return final boolean result

**Example Evaluation:**
Onboardingc Record Change
↓
Onboarding_Record_Trigger_Update_Onboarding_Status (Flow)
↓
OnboardingStatusEvaluator.evaluateAndApplyStatus()
↓
OnboardingRulesService.getRulesForGroups()
↓
For each Onboarding_Status_Rules_Enginec:
OnboardingRuleEvaluator.evaluateRule()
↓
For each Onboarding_Status_Rulec:
Check requirement status matches expected status
↓
Apply evaluation logic (ALL/ANY/CUSTOM)
↓
If rule passes: Update Onboardingc.Onboarding_Status_c

## Rule Structure

### Onboarding_Status_Rules_Engine\_\_c

The rules engine defines a set of rules and evaluation logic:

**Key Fields:**

- `Vendor_Program_Group__c` - Associated vendor program group
- `Target_Onboarding_Status__c` - Status to set when rule passes
- `Evaluation_Logic__c` - Logic type: "ALL", "ANY", or "CUSTOM"
- `Custom_Evaluation_Logic__c` - Custom expression (if Evaluation_Logic\_\_c = "CUSTOM")

### Onboarding_Status_Rule\_\_c

Individual rule conditions:

**Key Fields:**

- `Parent_Rule__c` - Parent rules engine
- `Requirement__c` - Requirement to evaluate (Vendor_Program_Requirement\_\_c)
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

**Examples:**Complete" OR Compliance is "Approved")

**Configuration:**

1. Rules Engine:
   - `Target_Onboarding_Status__c`: "Ready for Review"
   - `Evaluation_Logic__c`: "CUSTOM"
   - `Custom_Evaluation_Logic__c`: "1 AND 2 AND (3 OR 4)"

2. Rules:
   - Rule 1: Background Check = "Complete"
   - Rule 2: Business License = "Approved"
   - Rule 3: Credit Check = "Complete"
   - Rule 4: Compliance = "Approved"

## UI Management

### onboardingStatusRulesEngine

Admin UI for configuring rules:

- Select Vendor Program Group
- Select Requirement Group
- Load existing rules
- Edit rules in datatable
- Save changes

### onboardingRequirementsPanel

User UI for managing requirements:

- View all requirements
- Update requirement statuses
- Trigger status re-evaluation

## Best Practices

1. **Rule Ordering**: Order rules from most specific to least specific
2. **Expression Testing**: Test custom expressions thoroughly
3. **Requirement Status Values**: Use consistent status values
4. **Performance**: Limit number of rules per engine
5. **Documentation**: Document complex custom expressions

## Troubleshooting

### Status Not Updating

1. Check rules are associated with correct Vendor Program Group
2. Verify requirement statuses match expected values
3. Check evaluation logic (especially custom expressions)
4. Verify rule order (first passing rule wins)

### Custom Expression Errors

1. Check rule numbers match `Rule_Number__c` values
2. Verify parentheses are balanced
3. Check for typos in operators (AND/OR)
4. Test expression with known values

## Related Documentation

- [Onboarding Process](./onboarding-process.md)
- [Apex Classes](../components/apex-classes.md)
- [Data Model](../architecture/data-model.md)

"1 AND 2" # Rules 1 AND 2 must pass
"1 OR 2" # Rule 1 OR Rule 2 must pass
"(1 AND 2) OR 3" # (Rule 1 AND Rule 2) OR Rule 3
"1 AND (2 OR 3)" # Rule 1 AND (Rule 2 OR Rule 3)

**Expression Processing:**

1. Rule numbers are replaced with boolean values (true/false)
2. `AND` is replaced with `&&`
3. `OR` is replaced with `||`
4. Expression is evaluated recursively with parentheses support

## Evaluation Flow

### Step 1: Gather Requirements

Map<Id, Onboarding_Requirement\_\_c> reqByVPR =
OnboardingRulesService.getRequirementsByVPR(onboarding.Id);

Maps requirements by Vendor_Program_Requirement\_\_c ID for quick lookup.

Step 2: Get Vendor Program Groups

Id vendorProgramId = OnboardingRulesService.getVendorProgramId(onboarding.Id);
List<Id> groupIds = OnboardingRulesService.getVendorProgramGroupIds(vendorProgramId);rdId`(Vendor Program ID) from Lightning record page
2. Calls`OnboardingApplicationService.getProcessIdForVendorProgram()`3. Passes`processId`to`onboardingFlowEngine` 4. Handles loading and error states

**Code:**
@wire(getProcessIdForVendorProgram, { vendorProgramId: '$recordId' })
wiredProcess({ error, data }) {
if (data) {
this.processId = data;
}
}### 2. Flow Controller: onboardingFlowEngine

**Purpose**: Manages the onboarding flow lifecycle.

**Responsibilities:**

- Load stages from metadata
- Track current stage index
- Handle navigation (next/back)
- Persist progress
- Resume from saved progress

**Key Methods:**

**initializeFlow()**

- Loads stages: `getStagesForProcess()`
- Loads progress: `getProgress()`
- Loads process details: `getProcessDetails()`
- Resumes from saved stage if exists

**handleNext()**

- Advances to next stage
- Supports branching via `Next_Stage__c`
- Falls back to sequential order
- Saves progress

**handleBack()**

- Returns to previous stage
- Saves progress

**persistProgress()**

- Saves to `Onboarding_Application_Progress__c`
- Logs to `Onboarding_Application_Stage_Completion__c`

### 3. Component Renderer: onboardingStageRenderer

**Purpose**: Dynamically renders stage components.

**Flow:**

1. Receives `componentName` (API name) from flow engine
2. Receives `context` object
3. Dynamically instantiates component using `<c-{componentName}>`
4. Passes context to component
5. Listens for navigation events

**Dynamic Instantiation:**
<template>
<template if:true={componentName}>
<c-{componentName} context={context}></c-{componentName}>
</template>
</template>**Event Handling:**
handleNext(event) {
this.dispatchEvent(new CustomEvent('next', { detail: event.detail }));
}### 4. Stage Components

**Purpose**: Implement stage-specific functionality.

**Requirements:**

- Accept `context` prop with `vendorProgramId` and `stageId`
- Fire `next` event when stage complete
- Fire `back` event to return to previous stage
- Handle own data operations
- Show loading states
- Handle errors gracefully

**Example Structure:**
export default class VendorProgramOnboardingVendor extends LightningElement {
@api context;

get vendorProgramId() {
return this.context?.vendorProgramId;
}

handleNext() {
this.dispatchEvent(new CustomEvent('next', {
detail: { /_ stage data _/ }
}));
}
}## Metadata Model

### Onboarding_Application_Process\_\_c

Defines a reusable onboarding process.

**Fields:**

- `Name` - Process name
- `Description__c` - Process description
- `Active__c` - Whether process is active

### Onboarding_Application_Stage\_\_c

Defines a stage within a process.

**Fields:**

- `Onboarding_Application_Process__c` - Parent process
- `Onboarding_Component_Library__c` - Component to render
- `Display_Order__c` - Order in flow
- `Label__c` - Display label
- `Required__c` - Whether stage is required
- `Next_Stage__c` - Next stage (for branching)

### Onboarding_Component_Library\_\_c

Maps LWC components to metadata.

**Fields:**

- `Component_API_Name__c` - LWC component API name
- `Name` - Component name
- `Description__c` - Component description

### Onboarding_Application_Progress\_\_c

Tracks user progress.

**Fields:**

- `Onboarding_Application_Process__c` - Process being executed
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program being onboarded
- `Current_Stage__c` - Current stage ID

### Onboarding_Application_Stage_Completion\_\_c

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

**Implementation:**avascript
async handleNext(event) {
const nextStageId = this.activeStage?.Next_Stage\_\_c;

if (nextStageId) {
const nextIndex = this.stages.findIndex(stage => stage.Id === nextStageId);
if (nextIndex >= 0) {
this.activeStageIndex = nextIndex;
}
} else {
// Sequential navigation
this.activeStageIndex++;
}
}## Progress Persistence

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

Retrieves vendor program groups associated with the onboarding.

Step 3: Get Rules
List<Onboarding_Status_Rules_Engine\_\_c> rules =
OnboardingRulesService.getRulesForGroups(groupIds); architectural layers: Application Layer, Business Logic Layer, and Domain Layer. Flows follow a consistent naming convention and handle various automation scenarios.

## Naming Convention

### Application Layer Flows

**Pattern**: `APP_[Object]_[Description]`

**Examples:**

- `APP_Onboarding` - Main onboarding orchestration flow

### Business Logic Layer Flows

**Pattern**: `BLL_[Object]_[Trigger]_[Description]`

**Examples:**

- `BLL_Training_Assignment_Credential_RCD_Unique_Key_Creation` - Creates unique keys
- `BLL_Contact_Training_Assignment_RCD_Update_Related_Records` - Updates related records
- `BLL_External_Contact_Credential_RCD_Execute_Supplemental_Onboarding_Requirements` - Executes supplemental requirements
- `BLL_Order_RCD_GET_Onboarding_Record` - Gets onboarding record from order

### Domain Layer Flows

**Pattern**: `DOMAIN_[Object]_[Type]_[Operation]_[Description]`

**Types:**

- `SFL` - Subflow
- `RCD` - Record-triggered flow

**Operations:**

- `CREATE` - Create records
- `UPDATE` - Update records
- `GET` - Get/query records
- `SEND` - Send communications

**Examples:**

- `DOMAIN_Onboarding_SFL_CREATE_Order_and_Assign_Product_to_Order` - Creates order
- `DOMAIN_Onboarding_SFL_UPDATE_Onboarding_Record` - Updates onboarding record
- `DOMAIN_Onboarding_SFL_GET_Records` - Gets onboarding records
- `DOMAIN_Onboarding_SFL_Send_Email_Notification` - Sends email notifications
- `DOMAIN_External_Contact_Credential_SFL_CREATE_Contact_Training_Assignment_Record` - Creates training assignment
- `DOMAIN_External_Contact_Credential_RCD_Before_Save_Flow_to_Prevent_Duplicates` - Prevents duplicates

## Key Flows

### APP_Onboarding

**Type**: Orchestrated Flow  
**Trigger**: Record-triggered on Onboarding\_\_c

**Purpose**: Main application layer flow that orchestrates onboarding record updates.

**Stages:**

1. **Create Order for Onboarding Record** - Creates order and assigns products
2. **Send Email Notification** - Sends notification emails
3. **Close All Onboarding Tasks** - Closes related tasks
4. Additional orchestrated stages for various operations

**Key Subflows:**

- `DOMAIN_Onboarding_SFL_CREATE_Order_and_Assign_Product_to_Order`
- `DOMAIN_Onboarding_SFL_Send_Email_Notification`
- `Onboarding_Autolaunch_Close_All_Tasks`

### Onboarding_Record_Trigger_Update_Onboarding_Status

**Type**: Record-Triggered Flow  
**Trigger**: After Save on Onboarding\_\_c

**Purpose**: Updates onboarding status based on rules engine.

**Logic:**

1. Checks bypass conditions:
   - User has `Onboarding_Bypass_Flow` permission
   - Status is "Setup Complete", "Expired", or "Denied"
2. If not bypassed, calls Apex:
   - `OnboardingStatusEvaluator.evaluateAndApplyStatus()`

**Bypass Conditions:**

- Permission: `Onboarding_Bypass_Flow`
- Status: "Setup Complete"
- Status: "Expired"
- Status: "Denied"

### DOMAIN_Onboarding_SFL_CREATE_Order_and_Assign_Product_to_Order

**Type**: Subflow  
**Purpose**: Creates order record and assigns products for onboarding.

**Input Variables:**

- `OnboardingRecord` - Onboarding record

**Operations:**

1. Creates Order record
2. Assigns products to order
3. Updates onboarding record with order reference

### DOMAIN_Onboarding_SFL_UPDATE_Onboarding_Record

**Type**: Subflow  
**Purpose**: Updates onboarding record fields.

**Input Variables:**

- `OnboardingRecord` - Onboarding record to update
- Update fields as needed

### DOMAIN_Onboarding_SFL_GET_Records

**Type**: Subflow  
**Purpose**: Queries and returns onboarding-related records.

**Output Variables:**

- Returns collection of records

### DOMAIN_Onboarding_SFL_Send_Email_Notification

**Type**: Subflow  
**Purpose**: Sends email notifications for onboarding events.

**Input Variables:**

- `OnboardingRecord` - Onboarding record
- `EmailTemplate` - Email template to use
- `Recipients` - Recipient list

### DOMAIN_External_Contact_Credential_SFL_CREATE_Contact_Training_Assignment_Record

**Type**: Subflow  
**Purpose**: Creates training assignment records for contacts based on credentials.

**Logic:**

1. Checks if onboarding record exists
2. Gets account associated with contact
3. Gets active onboarding records
4. Creates training assignment record

### DOMAIN_External_Contact_Credential_RCD_Before_Save_Flow_to_Prevent_Duplicates

**Type**: Record-Triggered Flow (Before Save)  
**Trigger**: Before Save on POE_External_Contact_Credential\_\_c

**Purpose**: Prevents duplicate credential records.

**Logic:**

1. Creates unique key from contact and credential type
2. Checks for existing records with same unique key
3. Prevents save if duplicate found

### DOMAIN_External_Contact_Credential_Type_RCD_Before_Save_Flow_to_Prevent_Duplicate

**Type**: Record-Triggered Flow (Before Save)  
**Trigger**: Before Save on External_Contact_Credential_Type\_\_c

**Purpose**: Prevents duplicate credential types.

### Onboarding_Subflow_Create_Related_Onboarding_Records

**Type**: Subflow  
**Purpose**: Creates related onboarding records.

### Onboarding_Subflow_Update_Status

**Type**: Subflow  
**Purpose**: Updates onboarding status.

### Onboarding_Subflow_LearnUpon_Contact_Creation

**Type**: Subflow  
**Purpose**: Creates LearnUpon contact records.

## Flow Categories

### Record-Triggered Flows

**Before Save:**

- Validation and duplicate prevention
- Unique key creation
- Field calculations

**After Save:**

- Status updates
- Related record creation
- Email notifications

### Autolaunched Flows

**Purpose**: Background automation

- Task management
- Record updates
- Data synchronization

### Screen Flows

**Purpose**: User interaction

- Contact creation
- Opportunity creation
- Onboarding record updates

### Subflows

**Purpose**: Reusable flow logic

- Common operations
- Data transformations
- Business rule execution

## Flow Best Practices

### Naming

- Follow naming convention
- Use descriptive names
- Include operation type (CREATE, UPDATE, GET, etc.)

### Error Handling

- Use decision elements for error conditions
- Provide clear error messages
- Log errors appropriately

### Performance

- Use bulkified operations
- Minimize SOQL queries
- Use collections efficiently

### Maintainability

- Document flow purpose
- Use clear element labels
- Organize flows by layer

## Related Documentation

- [Architecture Layers](../architecture/layers.md)
- [Onboarding Process](./onboarding-process.md)
- [Data Model](../architecture/data-model.md)

Retrieves all rules engines for the groups.
Step 4: Evaluate Each Rule

For each rule engine:
Build Conditions Map: For each Onboarding_Status_Rule**c:
Look up requirement status
Compare with Expected_Status**c
Store result in map keyed by Rule_Number**c
Apply Evaluation Logic:
ALL: Check all values are true
ANY: Check at least one value is true
CUSTOM: Evaluate expression using OnboardingExpressionEngine
Update Status: If rule passes, update Onboarding**c.Onboarding_Status\_\_c and return
Expression Engine
OnboardingExpressionEngine
Recursively evaluates boolean expressions with support for:
Parentheses grouping
AND (&&) and OR (||) operators
Nested expressions
Algorithm:
Process innermost parentheses first
Evaluate OR operations
Evaluate AND operations
Return final boolean result
Example Evaluation:

Expression: "(1 AND 2) OR 3"
Rule 1: true, Rule 2: true, Rule 3: false

Step 1: Replace rule numbers
→ "(true && true) || false"

Step 2: Evaluate parentheses
→ "true || false"

Step 3: Evaluate OR
→ true

Result: true

### Onboarding\_\_c

**Key Fields:**

- `Account__c` (Master-Detail to Account) - Vendor account
- `Onboarding_Status__c` (Picklist) - Current status
- `Interview_Status__c` (Picklist) - Interview status
- `Vendor_Customization__c` (Lookup) - Related vendor program

**Relationships:**

- Master-Detail to Account
- Has many Onboarding_Requirement\_\_c

**Sharing**: Controlled by Parent (Account)

**Key Flows:**

- `APP_Onboarding` - Main orchestration
- `Onboarding_Record_Trigger_Update_Onboarding_Status` - Status evaluation

**Note**: Interview status is sourced from `Interview__c.Interview_Status__c`, but the mapping to the correct Onboarding\_\_c (Account + Vendor Program) still needs to be defined.

### Vendor Program (Vendor_Customization\_\_c)

**Purpose**: Versioned vendor program configuration. The object label is "Vendor Program" while the API name is `Vendor_Customization__c`. Lookups named `Vendor_Program__c` reference this object.

**Key Fields:**

- `Name` (Text) - Program name
- `Status__c` (Picklist) - Draft/Active/Deprecated lifecycle
- `Active__c` (Checkbox) - Active status
- `Vendor__c` (Lookup to Account) - Vendor account
- `Vendor_Program_Group__c` (Lookup) - Default program group
- `Vendor_Program_Requirement_Group__c` (Lookup) - Default requirement group
- `Previous_Version__c` (Lookup) - Parent version

**Relationships:**

- Has many Vendor_Program_Requirement\_\_c
- Has many Vendor_Program_Requirement_Set\_\_c
- Has many Vendor_Program_Recipient_Group\_\_c
- Has many Onboarding**c (via `Vendor_Customization**c`)
- Linked to Vendor_Program_Group**c via Vendor_Program_Group_Member**c

### Vendor_Program_Group\_\_c

**Purpose**: Groups requirements and rules for a vendor program.

**Key Fields:**

- `Name` (Text) - Group name
- `Active__c` (Checkbox) - Active status
- `Logic_Type__c` (Picklist) - Inheritance logic
- `Parent_Group__c` (Lookup) - Optional parent group

**Relationships:**

- Has many Vendor_Program_Group_Member\_\_c
- Has many Onboarding_Status_Rules_Engine\_\_c
- Referenced by Vendor_Customization\_\_c as a default program group

### Vendor_Program_Group_Member\_\_c

**Purpose**: Members of a vendor program group.

**Key Fields:**

- `Vendor_Program_Group__c` (Lookup) - Parent group
- `Required_Program__c` (Lookup to `Vendor_Customization__c`) - Required/included program
- `Inherited_Program_Requirement_Group__c` (Lookup) - Inherited requirement group
- `Is_Target__c` (Checkbox) - Target program flag
- `Active__c` (Checkbox) - Active membership flag

**Relationships:**

- Junction between Vendor_Program_Group**c and Vendor_Customization**c

## Requirement Objects

### Onboarding_Requirement\_\_c

**Purpose**: Tracks individual requirements for an onboarding.

**Key Fields:**

- `Name` (Text) - Requirement name
- `Onboarding__c` (Lookup) - Parent onboarding
- `Vendor_Program_Requirement__c` (Lookup) - Requirement definition
- `Status__c` (Picklist) - Status (Not Started, Incomplete, Complete, Approved, Denied)

**Relationships:**

- Belongs to Onboarding\_\_c
- References Vendor_Program_Requirement\_\_c

**Usage**: Used by status evaluation engine

### Vendor_Program_Requirement\_\_c

**Purpose**: Defines requirements for a vendor program.

**Key Fields:**

- `Name` (Text) - Requirement name
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Parent program
- `Requirement_Template__c` (Lookup) - Source template
- `Requirement_Group_Member__c` (Lookup) - Requirement group member link
- `Status__c` (Picklist) - Requirement status
- `Active__c` (Checkbox) - Active status

**Relationships:**

- Belongs to Vendor_Customization**c (via `Vendor_Program**c`)
- Referenced by Onboarding_Requirement\_\_c

## Status Rules Objects

### Onboarding_Status_Rules_Engine\_\_c

**Purpose**: Defines a rules engine for status evaluation.

**Key Fields:**

- `Name` (Text) - Rules engine name
- `Vendor_Program_Group__c` (Lookup) - Associated program group
- `Requirement_Group__c` (Lookup) - Associated requirement group
- `Target_Onboarding_Status__c` (Text) - Status to set when rule passes
- `Evaluation_Logic__c` (Picklist) - Logic type (ALL, ANY, CUSTOM)
- `Custom_Evaluation_Logic__c` (Text) - Custom expression

**Relationships:**

- Belongs to Vendor_Program_Group\_\_c
- Has many Onboarding_Status_Rule\_\_c

**Usage**: Used by status evaluation engine

### Onboarding_Status_Rule\_\_c

**Purpose**: Individual rule conditions within a rules engine.

**Key Fields:**

- `Name` (Text) - Rule name
- `Parent_Rule__c` (Lookup) - Parent rules engine
- `Requirement__c` (Lookup) - Requirement to evaluate
- `Expected_Status__c` (Text) - Expected requirement status
- `Rule_Number__c` (Number) - Order of evaluation

**Relationships:**

- Belongs to Onboarding_Status_Rules_Engine\_\_c
- References Vendor_Program_Requirement\_\_c

**Usage**: Used in rule evaluation logic

## Application Framework Objects

### Onboarding_Application_Process\_\_c

**Purpose**: Defines a reusable onboarding flow process.

**Key Fields:**

- `Name` (Text) - Process name
- `Description__c` (Text) - Process description
- `Active__c` (Checkbox) - Active status

**Relationships:**

- Has many Onboarding_Application_Stage\_\_c
- Has many Onboarding_Application_Progress\_\_c

### Onboarding_Application_Stage\_\_c

**Purpose**: Defines a stage within an onboarding process.

**Key Fields:**

- `Name` (Text) - Stage name
- `Onboarding_Application_Process__c` (Lookup) - Parent process
- `Onboarding_Component_Library__c` (Lookup) - Component to render
- `Display_Order__c` (Number) - Order in flow
- `Label__c` (Text) - Display label
- `Required__c` (Checkbox) - Whether stage is required
- `Next_Stage__c` (Lookup) - Next stage (for branching)

**Relationships:**

- Belongs to Onboarding_Application_Process\_\_c
- References Onboarding_Component_Library\_\_c
- Self-referential for branching

### Onboarding_Component_Library\_\_c

**Purpose**: Maps LWC components to metadata.

**Key Fields:**

- `Name` (Text) - Component name
- `Component_API_Name__c` (Text) - LWC component API name
- `Description__c` (Text) - Component description

**Relationships:**

- Referenced by Onboarding_Application_Stage\_\_c

### Onboarding_Application_Progress\_\_c

**Purpose**: Tracks user progress through an onboarding process.

**Key Fields:**

- `Onboarding_Application_Process__c` (Lookup) - Process being executed
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program being onboarded
- `Current_Stage__c` (Lookup) - Current stage

**Relationships:**

- Belongs to Onboarding_Application_Process\_\_c
- References Vendor_Customization**c (via `Vendor_Program**c`)
- References Onboarding_Application_Stage\_\_c

### Onboarding_Application_Stage_Completion\_\_c

**Purpose**: Audit log of completed stages.

**Key Fields:**

- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program
- `Onboarding_Application_Process__c` (Lookup) - Process
- `Onboarding_Application_Stage__c` (Lookup) - Completed stage
- `Completed_Date__c` (DateTime) - Completion timestamp
- `Completed_By__c` (Lookup to User) - User who completed

**Relationships:**

- References Vendor_Customization**c (via `Vendor_Program**c`)
- References Onboarding_Application_Process\_\_c
- References Onboarding_Application_Stage\_\_c

## Training Objects

### Training_Requirement\_\_c

**Purpose**: Defines training requirements.

**Key Fields:**

- `Name` (Text) - Requirement name
- `Training_System__c` (Lookup) - Training system
- `Active__c` (Checkbox) - Active status

**Relationships:**

- References Training_System\_\_c

### Training_Assignment\_\_c

**Purpose**: Tracks training assignments to contacts.

**Key Fields:**

- `Name` (Text) - Assignment name
- `Contact__c` (Lookup) - Assigned contact
- `Training_Requirement__c` (Lookup) - Training requirement
- `Status__c` (Picklist) - Assignment status

**Relationships:**

- Belongs to Contact
- References Training_Requirement\_\_c

### Training_System\_\_c

**Purpose**: Defines training systems.

**Key Fields:**

- `Name` (Text) - System name
- `Active__c` (Checkbox) - Active status

**Relationships:**

- Has many Training_Requirement\_\_c

## Credential Objects

### External_Contact_Credential_Type\_\_c

**Purpose**: Defines types of credentials for external contacts.

**Key Fields:**

- `Name` (Text) - Credential type name
- `Active__c` (Checkbox) - Active status

**Relationships:**

- Has many POE_External_Contact_Credential\_\_c

**Duplicate Prevention**: Matching rule prevents duplicates

### POE_External_Contact_Credential\_\_c

**Purpose**: Tracks credentials for external contacts.

**Key Fields:**

- `Name` (Text) - Credential name
- `Contact__c` (Lookup) - Contact
- `External_Contact_Credential_Type__c` (Lookup) - Credential type
- `Status__c` (Picklist) - Credential status
- `Unique_Key__c` (Text) - Unique identifier (auto-generated)

**Relationships:**

- Belongs to Contact
- References External_Contact_Credential_Type\_\_c

**Duplicate Prevention**: Matching rule prevents duplicates per contact/type

### Required_Credential\_\_c

**Purpose**: Defines required credentials for programs.

**Key Fields:**

- `Name` (Text) - Requirement name
- `Credential_Type__c` (Lookup) - Required credential type
- `Active__c` (Checkbox) - Active status

**Relationships:**

- References External_Contact_Credential_Type\_\_c

### Required_External_Contact_Credential\_\_c

**Purpose**: Links required credentials to vendor programs.

**Key Fields:**

- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program
- `Required_Credential__c` (Lookup) - Required credential

**Relationships:**

- References Vendor_Customization**c (via `Vendor_Program**c`)
- References Required_Credential\_\_c

### External_Credential_Type_Dependency\_\_c

**Purpose**: Defines dependencies between credential types.

**Key Fields:**

- `Credential_Type__c` (Lookup) - Credential type
- `Dependent_Credential_Type__c` (Lookup) - Dependent credential type

**Relationships:**

- References External_Contact_Credential_Type\_\_c (self-referential)

## ECC Configuration Objects

### ECC_Field_Configuration_Group\_\_c

**Purpose**: Groups field configurations for ECC forms.

**Key Fields:**

- `Name` (Text) - Group name
- `Active__c` (Checkbox) - Active status

**Relationships:**

- Has many ECC_Field_Configuration_Group_Mapping\_\_c

### ECC_Field_Display_Configuration\_\_c

**Purpose**: Defines how fields are displayed in ECC forms.

**Key Fields:**

- `Name` (Text) - Configuration name
- `Field_API_Name__c` (Text) - Salesforce field API name
- `Display_Label__c` (Text) - Display label
- `Required__c` (Checkbox) - Whether field is required
- `Display_Order__c` (Number) - Order in form

**Relationships:**

- Referenced by ECC_Field_Configuration_Group_Mapping\_\_c

### ECC_Field_Configuration_Group_Mapping\_\_c

**Purpose**: Maps field configurations to groups.

**Key Fields:**

- `ECC_Field_Configuration_Group__c` (Lookup) - Configuration group
- `ECC_Field_Display_Configuration__c` (Lookup) - Field configuration

**Relationships:**

- Belongs to ECC_Field_Configuration_Group\_\_c
- References ECC_Field_Display_Configuration\_\_c

## Related Documentation

- [Data Model](../architecture/data-model.md)
- [Onboarding Process](../processes/onboarding-process.md)
- [Status Evaluation](../processes/status-evaluation.md)

Rule Priority
Rules are evaluated in the order returned by getRulesForGroups(). The first rule that passes updates the onboarding status and evaluation stops.
Best Practice: Order rules from most specific to least specific.
Triggering Evaluation
Automatic Triggering
Evaluation is triggered automatically via:
Flow: Onboarding_Record_Trigger_Update_Onboarding_Status
Triggered on Onboardingc record changes
Bypassed if:
User has Onboarding_Bypass_Flow permission
Status is "Setup Complete", "Expired", or "Denied"
Manual Triggering
Can be triggered manually via:
OnboardingRequirementsPanelController.runRuleEvaluation()
Called from onboardingRequirementsPanel LWC after requirement updates
Configuration
Creating a Rules Engine
Create Rules Engine: Create Onboarding_Status_Rules_Engine**c record
Set Vendor_Program_Group**c
Set Target_Onboarding_Status**c
Set Evaluation_Logic**c (ALL, ANY, or CUSTOM)
If CUSTOM, set Custom_Evaluation_Logic**c
Create Rules: Create Onboarding_Status_Rule**c records
Set Parent_Rule**c to rules engine
Set Requirement**c to Vendor_Program_Requirementc
Set Expected_Status**c (e.g., "Complete", "Approved")
Set Rule_Number**c for ordering and custom expressions
Example Configuration
Scenario: Set status to "Ready for Review" when:
Background Check is "Complete" AND
Business License is "Approved" AND
(Credit Check is "Complete" OR Compliance is "Approved")
Configuration:
Rules Engine:
Target_Onboarding_Status**c: "Ready for Review"
Evaluation_Logic**c: "CUSTOM"
Custom_Evaluation_Logic**c: "1 AND 2 AND (3 OR 4)"
Rules:
Rule 1: Background Check = "Complete"
Rule 2: Business License = "Approved"
Rule 3: Credit Check = "Complete"
Rule 4: Compliance = "Approved"
UI Management
onboardingStatusRulesEngine
Admin UI for configuring rules:
Select Vendor Program Group
Select Requirement Group
Load existing rules
Edit rules in datatable
Save changes
onboardingRequirementsPanel
User UI for managing requirements:
View all requirements
Update requirement statuses
Trigger status re-evaluation
Best Practices
Rule Ordering: Order rules from most specific to least specific
Expression Testing: Test custom expressions thoroughly
Requirement Status Values: Use consistent status values
Performance: Limit number of rules per engine
Documentation: Document complex custom expressions
Troubleshooting
Status Not Updating
Check rules are associated with correct Vendor Program Group
Verify requirement statuses match expected values
Check evaluation logic (especially custom expressions)
Verify rule order (first passing rule wins)
Custom Expression Errors
Check rule numbers match Rule_Number**c values
Verify parentheses are balanced
Check for typos in operators (AND/OR)
Test expression with known values
Related Documentation
Onboarding Process
Apex Classes
Data Model

## 9. Create docs/processes/application-flow-engine.md

Create `docs/processes/application-flow-engine.md`:
rkdown

# Application Flow Engine

## Overview

The Application Flow Engine is a metadata-driven system that dynamically renders Lightning Web Components based on configuration stored in Custom Objects. It provides a flexible, reusable framework for building onboarding flows without hardcoding component sequences.

## Architecture

unpackaged:\*\*
sf project deploy start --source-dir force-app/unpackaged### 4. Run Tests

sf apex run test --class-names OnboardingRulesServiceTest,OnboardingStatusEvaluatorTest### 5. Assign Permission Sets

Assign the following permission sets to users:

- `Onboarding_Account_Services`
- `Onboarding_Compliance_Team`
- `Onboarding_Program_Sales_Team`
- (Add others as needed)

## Post-Deployment Configuration

### 1. Configure Custom Metadata

Create required custom metadata records:

- Global Value Sets
- Custom Labels

### 2. Create Onboarding Processes

1. Create `Onboarding_Component_Library__c` records for each LWC component
2. Create `Onboarding_Application_Process__c` record
3. Create `Onboarding_Application_Stage__c` records
4. Link stages to process and components

### 3. Configure Status Rules

1. Create `Vendor_Program_Group__c` records
2. Create `Onboarding_Status_Rules_Engine__c` records
3. Create `Onboarding_Status_Rule__c` records
4. Link rules to engines

### 4. Set Up Record Pages

Add components to Lightning record pages:

- **Vendor Program Page**: Add `vendorProgramOnboardingFlow`
- **Onboarding Page**: Add `onboardingRequirementsPanel`

## Verification

### Verify Deployment

1. Check for deployment errors
2. Verify all components are available
3. Check permission sets are assigned

### Test Onboarding Flow

1. Create a Vendor Program
2. Assign an onboarding process
3. Navigate to Vendor Program record page
4. Verify onboarding flow appears and functions

### Test Status Evaluation

1. Create an Onboarding record
2. Create requirements
3. Update requirement statuses
4. Verify onboarding status updates automatically

## Troubleshooting

### Common Issues

**Deployment Errors:**

- Check API version compatibility
- Verify all dependencies are deployed
- Check for missing fields or objects

**Component Not Appearing:**

- Verify component is deployed
- Check Lightning page configuration
- Verify user has appropriate permissions

**Status Not Updating:**

- Check rules engine configuration
- Verify requirements are linked correctly
- Check flow is active and not bypassed

## Related Documentation

- [Configuration Guide](./configuration.md)
- [Architecture Overview](../architecture/overview.md)

┌─────────────────────────────────────────┐
│ vendorProgramOnboardingFlow (LWC) │
│ - Entry point from record page │
│ - Resolves process ID │
└─────────────────────────────────────────┘
↓
┌─────────────────────────────────────────┐
│ onboardingFlowEngine (LWC) │
│ - Loads stages from metadata │
│ - Manages current stage │
│ - Handles navigation │
│ - Persists progress │
└─────────────────────────────────────────┘
↓
┌─────────────────────────────────────────┐
│ onboardingStageRenderer (LWC) │
│ - Dynamically instantiates components │
│ - Passes context to children │
│ - Handles navigation events │
└─────────────────────────────────────────┘
↓
┌─────────────────────────────────────────┐
│ Stage Component (LWC) │
│ - Stage-specific logic │
│ - User interactions │
│ - Fires navigation events │
└─────────────────────────────────────────┘

## Component Flow

### 1. Entry Point: vendorProgramOnboardingFlow

**Purpose**: Resolves the onboarding process for a vendor program.

**Flow:**

1. Receives `recordId` (Vendor Program ID) from Lightning record page
2. Calls `OnboardingApplicationService.getProcessIdForVendorProgram()`
3. Passes `processId` to `onboardingFlowEngine`
4. Handles loading and error states

**Code:**e name (e.g., "Vendor Selection")

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

### 2. Flow Controller: onboardingFlowEngine

**Purpose**: Manages the onboarding flow lifecycle.

**Responsibilities:**

- Load stages from metadata
- Track current stage index
- Handle navigation (next/back)
- Persist progress
- Resume from saved progress

**Key Methods:**

**initializeFlow()**

- Loads stages: `getStagesForProcess()`
- Loads progress: `getProgress()`
- Loads process details: `getProcessDetails()`
- Resumes from saved stage if exists

**handleNext()**

- Advances to next stage
- Supports branching via `Next_Stage__c`
- Falls back to sequential order
- Saves progress

**handleBack()**

- Returns to previous stage
- Saves progress

**persistProgress()**

- Saves to `Onboarding_Application_Progress__c`
- Logs to `Onboarding_Application_Stage_Completion__c`

### 3. Component Renderer: onboardingStageRenderer

**Purpose**: Dynamically renders stage components.

**Flow:**

1. Receives `componentName` (API name) from flow engine
2. Receives `context` object
3. Dynamically instantiates component using `<c-{componentName}>`
4. Passes context to component
5. Listens for navigation events

**Dynamic Instantiation:**
<template>
<template if:true={componentName}>
<c-{componentName} context={context}></c-{componentName}>
</template>
</template>
nt group per program

- Parent version required on activation
- Recipient and program must be active
- Prevent duplicate assignments

## Best Practices

### Process Configuration

1. **Clear Labels**: Use descriptive stage labels
2. **Logical Order**: Order stages logically
3. **Required Stages**: Mark critical stages as required
4. **Documentation**: Document complex branching logic

### Rules Configuration

1. **Rule Ordering**: Order rules from specific to general
2. **Expression Testing**: Test custom expressions thoroughly
3. **Status Values**: Use consistent status values
4. **Documentation**: Document complex expressions

### Security

1. **Least Privilege**: Grant minimum required permissions
2. **Field Security**: Restrict sensitive fields
3. **Sharing Rules**: Configure appropriate sharing

## Related Documentation

- [Installation Guide](./installation.md)
- [Onboarding Process](../processes/onboarding-process.md)
- [Status Evaluation](../processes/status-evaluation.md)

Event Handling:

handleNext(event) {
this.dispatchEvent(new CustomEvent('next', { detail: event.detail }));
}pattern that separates concerns and promotes maintainability:

1. **Application Layer** - User interface and orchestration
2. **Business Logic Layer** - Business rules and coordination
3. **Domain Layer** - Data operations and domain logic

## Layer Responsibilities

### Application Layer

**Purpose**: Handles user interactions and high-level process orchestration.

**Components:**

- Lightning Web Components (LWC)
- Salesforce Flows (APP\_\*)
- Lightning Record Pages
- Screen Flows

**Responsibilities:**

- User interface rendering
- User input handling
- Process orchestration
- Navigation management
- Progress tracking

**Key Flows:**

- `APP_Onboarding` - Main onboarding orchestration

**Key Components:**

- `onboardingFlowEngine` - Flow controller
- `onboardingStageRenderer` - Component renderer
- `vendorProgramOnboardingFlow` - Entry point
- `onboardingRequirementsPanel` - Requirements UI

**Communication:**

- Calls Business Logic Layer services
- Receives data from Business Logic Layer
- Delegates data operations to Domain Layer

### Business Logic Layer

**Purpose**: Contains business rules, validation, and coordination logic.

**Components:**

- Apex Services (\*Service.cls)
- Apex Orchestrators (\*Orch.cls)
- Apex Controllers (\*Ctlr.cls)
- Apex Handlers (\*Hdlr.cls)
- Salesforce Flows (BLL\_\*)

**Responsibilities:**

- Business rule enforcement
- Validation logic
- Service coordination
- Status evaluation
- Rules engine execution

**Key Classes:**

- `OnboardingApplicationService` - Process management
- `OnboardingRulesService` - Rules data access
- `OnboardingStatusEvaluator` - Status evaluation
- `OnboardingRuleEvaluator` - Rule evaluation
- `OnboardingAppActivationOrchestrator` - Activation workflow

**Key Flows:**

- `BLL_Training_Assignment_Credential_RCD_Unique_Key_Creation`
- `BLL_Contact_Training_Assignment_RCD_Update_Related_Records`
- `BLL_External_Contact_Credential_RCD_Execute_Supplemental_Onboarding_Requirements`
- `BLL_Order_RCD_GET_Onboarding_Record`

**Communication:**

- Called by Application Layer
- Calls Domain Layer for data operations
- Contains business logic only (no direct data access)

### Domain Layer

**Purpose**: Handles data operations and domain-specific logic.

**Components:**

- Salesforce Flows (DOMAIN\_\*)
- Record-Triggered Flows
- Subflows

**Responsibilities:**

- Data creation
- Data updates
- Data queries
- Duplicate prevention
- Unique key generation
- Email communications

**Key Flows:**

- `DOMAIN_Onboarding_SFL_CREATE_Order_and_Assign_Product_to_Order`
- `DOMAIN_Onboarding_SFL_UPDATE_Onboarding_Record`
- `DOMAIN_Onboarding_SFL_GET_Records`
- `DOMAIN_Onboarding_SFL_Send_Email_Notification`
- `DOMAIN_External_Contact_Credential_SFL_CREATE_Contact_Training_Assignment_Record`
- `DOMAIN_External_Contact_Credential_RCD_Before_Save_Flow_to_Prevent_Duplicates`

**Naming Convention:**

- `DOMAIN_[Object]_SFL_[Operation]_[Description]` - Subflows
- `DOMAIN_[Object]_RCD_[Trigger]_[Description]` - Record-triggered flows

**Communication:**

- Called by Business Logic Layer
- Called by Application Layer (for simple operations)
- No business logic (pure data operations)

## Data Flow

### Example: Status Evaluation

4. Stage Components
   Purpose: Implement stage-specific functionality.
   Requirements:
   Accept context prop with vendorProgramId and stageId
   Fire next event when stage complete
   Fire back event to return to previous stage
   Handle own data operations
   Show loading states
   Handle errors gracefully
   Example Structure:

export default class VendorProgramOnboardingVendor extends LightningElement {
@api context;

get vendorProgramId() {
return this.context?.vendorProgramId;
}

handleNext() {
this.dispatchEvent(new CustomEvent('next', {
detail: { /_ stage data _/ }
}));
}
}

## Metadata Model

See [Data Model](../architecture/data-model.md) for the canonical object reference used by the onboarding flow engine.

async handleNext(event) {
const nextStageId = this.activeStage?.Next_Stage\_\_c;

if (nextStageId) {
const nextIndex = this.stages.findIndex(stage => stage.Id === nextStageId);
if (nextIndex >= 0) {
this.activeStageIndex = nextIndex;
}
} else {
// Sequential navigation
this.activeStageIndex++;
}
}ations

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

## Progress Persistence### Saving ProgressProgress is saved after each stage navigation: 1. Onboarding_Application_Progress**c is upserted with current stage 2. Onboarding_Application_Stage_Completion**c is inserted for audit### Resuming ProgressOn initialization: 1. Load Onboarding_Application_Progress**c for vendor program 2. Find Current_Stage**c in stage list 3. Set activeStageIndex to saved stage 4. User continues from that point## Error Handling### Missing Process - Displays error message - Prevents flow initialization### Missing Stages - Displays error message - Prevents flow initialization### Invalid Component - Logs error to console - Shows error message to user### Progress Save Failure - Logs error - Allows user to continue (progress may be lost)## Best Practices### Stage Components1. Self-Contained: Handle own data operations 2. Error Handling: Gracefully handle errors 3. Loading States: Show loading indicators 4. Validation: Validate before firing 'next' event 5. Context Usage: Use context for vendor program and stage IDs### Process Configuration1. Clear Labels: Use descriptive stage labels 2. Logical Ordering: Order stages logically 3. Component Naming: Use consistent component API names 4. Documentation: Document complex branching logic### Performance1. Lazy Loading: Load stage data on demand 2. Caching: Cache process and stage metadata 3. Batch Operations: Batch data operations when possible## Extending the Engine### Adding New Stages1. Create LWC component 2. Create Onboarding_Component_Library**c record 3. Create Onboarding_Application_Stage**c record 4. Add to process### Adding Branching Logic1. Set Next_Stage\_\_c on stage records 2. Implement conditional logic in stage components 3. Pass condition data in 'next' event detail### Adding Progress Indicators1. Calculate progress percentage 2. Display progress bar 3. Show completed stages## Related Documentation- Onboarding Process - LWC Components - Data Model

## 10. Create docs/processes/flows.md

Create `docs/processes/flows.md`:

# Salesforce Flows

## Overview

The onboarding system uses Salesforce Flows for automation across three architectural layers: Application Layer, Business Logic Layer, and Domain Layer. Flows follow a consistent naming convention and handle various automation scenarios.

## Naming Convention

### Application Layer Flows

**Pattern**: `APP_[Object]_[Description]`

**Examples:**

- `APP_Onboarding` - Main onboarding orchestration flow

### Business Logic Layer Flows

**Pattern**: `BLL_[Object]_[Trigger]_[Description]`

**Examples:**

- `BLL_Training_Assignment_Credential_RCD_Unique_Key_Creation` - Creates unique keys
- `BLL_Contact_Training_Assignment_RCD_Update_Related_Records` - Updates related records
- `BLL_External_Contact_Credential_RCD_Execute_Supplemental_Onboarding_Requirements` - Executes supplemental requirements
- `BLL_Order_RCD_GET_Onboarding_Record` - Gets onboarding record from order

### Domain Layer Flows

**Pattern**: `DOMAIN_[Object]_[Type]_[Operation]_[Description]`

**Types:**

- `SFL` - Subflow
- `RCD` - Record-triggered flow

**Operations:**

- `CREATE` - Create records
- `UPDATE` - Update records
- `GET` - Get/query records
- `SEND` - Send communications

**Examples:**

- `DOMAIN_Onboarding_SFL_CREATE_Order_and_Assign_Product_to_Order` - Creates order
- `DOMAIN_Onboarding_SFL_UPDATE_Onboarding_Record` - Updates onboarding record
- `DOMAIN_Onboarding_SFL_GET_Records` - Gets onboarding records
- `DOMAIN_Onboarding_SFL_Send_Email_Notification` - Sends email notifications
- `DOMAIN_External_Contact_Credential_SFL_CREATE_Contact_Training_Assignment_Record` - Creates training assignment
- `DOMAIN_External_Contact_Credential_RCD_Before_Save_Flow_to_Prevent_Duplicates` - Prevents duplicates

## Key Flows

### APP_Onboarding

**Type**: Orchestrated Flow  
**Trigger**: Record-triggered on Onboarding\_\_c

**Purpose**: Main application layer flow that orchestrates onboarding record updates.

**Stages:**

1. **Create Order for Onboarding Record** - Creates order and assigns products
2. **Send Email Notification** - Sends notification emails
3. **Close All Onboarding Tasks** - Closes related tasks
4. Additional orchestrated stages for various operations

**Key Subflows:**

- `DOMAIN_Onboarding_SFL_CREATE_Order_and_Assign_Product_to_Order`
- `DOMAIN_Onboarding_SFL_Send_Email_Notification`
- `Onboarding_Autolaunch_Close_All_Tasks`

### Onboarding_Record_Trigger_Update_Onboarding_Status

**Type**: Record-Triggered Flow  
**Trigger**: After Save on Onboarding\_\_c

**Purpose**: Updates onboarding status based on rules engine.

**Logic:**

1. Checks bypass conditions:
   - User has `Onboarding_Bypass_Flow` permission
   - Status is "Setup Complete", "Expired", or "Denied"
2. If not bypassed, calls Apex:
   - `OnboardingStatusEvaluator.evaluateAndApplyStatus()`

**Bypass Conditions:**

- Permission: `Onboarding_Bypass_Flow`
- Status: "Setup Complete"
- Status: "Expired"
- Status: "Denied"

### DOMAIN_Onboarding_SFL_CREATE_Order_and_Assign_Product_to_Order

**Type**: Subflow  
**Purpose**: Creates order record and assigns products for onboarding.

**Input Variables:**

- `OnboardingRecord` - Onboarding record

**Operations:**

1. Creates Order record
2. Assigns products to order
3. Updates onboarding record with order reference

### DOMAIN_Onboarding_SFL_UPDATE_Onboarding_Record

**Type**: Subflow  
**Purpose**: Updates onboarding record fields.

**Input Variables:**

- `OnboardingRecord` - Onboarding record to update
- Update fields as needed

### DOMAIN_Onboarding_SFL_GET_Records

**Type**: Subflow  
**Purpose**: Queries and returns onboarding-related records.

**Output Variables:**

- Returns collection of records

### DOMAIN_Onboarding_SFL_Send_Email_Notification

**Type**: Subflow  
**Purpose**: Sends email notifications for onboarding events.

**Input Variables:**

- `OnboardingRecord` - Onboarding record
- `EmailTemplate` - Email template to use
- `Recipients` - Recipient list

### DOMAIN_External_Contact_Credential_SFL_CREATE_Contact_Training_Assignment_Record

**Type**: Subflow  
**Purpose**: Creates training assignment records for contacts based on credentials.

**Logic:**

1. Checks if onboarding record exists
2. Gets account associated with contact
3. Gets active onboarding records
4. Creates training assignment record

### DOMAIN_External_Contact_Credential_RCD_Before_Save_Flow_to_Prevent_Duplicates

**Type**: Record-Triggered Flow (Before Save)  
**Trigger**: Before Save on POE_External_Contact_Credential\_\_c

**Purpose**: Prevents duplicate credential records.

**Logic:**

1. Creates unique key from contact and credential type
2. Checks for existing records with same unique key
3. Prevents save if duplicate found

### DOMAIN_External_Contact_Credential_Type_RCD_Before_Save_Flow_to_Prevent_Duplicate

**Type**: Record-Triggered Flow (Before Save)  
**Trigger**: Before Save on External_Contact_Credential_Type\_\_c

**Purpose**: Prevents duplicate credential types.

### Onboarding_Subflow_Create_Related_Onboarding_Records

**Type**: Subflow  
**Purpose**: Creates related onboarding records.

### Onboarding_Subflow_Update_Status

**Type**: Subflow  
**Purpose**: Updates onboarding status.

### Onboarding_Subflow_LearnUpon_Contact_Creation

**Type**: Subflow  
**Purpose**: Creates LearnUpon contact records.

## Flow Categories

### Record-Triggered Flows

**Before Save:**

- Validation and duplicate prevention
- Unique key creation
- Field calculations

**After Save:**

- Status updates
- Related record creation
- Email notifications

### Autolaunched Flows

**Purpose**: Background automation

- Task management
- Record updates
- Data synchronization

### Screen Flows

**Purpose**: User interaction

- Contact creation
- Opportunity creation
- Onboarding record updates

### Subflows

**Purpose**: Reusable flow logic

- Common operations
- Data transformations
- Business rule execution

## Flow Best Practices

### Naming

- Follow naming convention
- Use descriptive names
- Include operation type (CREATE, UPDATE, GET, etc.)

### Error Handling

- Use decision elements for error conditions
- Provide clear error messages
- Log errors appropriately

### Performance

- Use bulkified operations
- Minimize SOQL queries
- Use collections efficiently

### Maintainability

- Document flow purpose
- Use clear element labels
- Organize flows by layer

## Related Documentation

- [Architecture Layers](../architecture/layers.md)
- [Onboarding Process](./onboarding-process.md)
- [Data Model](../architecture/data-model.md)

## 11. Create docs/objects/custom-objects.mdCreate docs/objects/custom-objects.md:

# Custom Objects

## Core Onboarding Objects

### Onboarding\_\_c

**Purpose**: Central object tracking an onboarding request for a vendor.

**Key Fields:**

- `Name` (Auto-Number) - Onboarding Number
- `Account__c` (Master-Detail to Account) - Vendor account
- `Onboarding_Status__c` (Picklist) - Current status
- `Interview_Status__c` (Picklist) - Interview status
- `Vendor_Customization__c` (Lookup) - Related vendor customization

**Relationships:**

- Master-Detail to Account
- Has many Onboarding_Requirement\_\_c

**Sharing**: Controlled by Parent (Account)

**Key Flows:**

- `APP_Onboarding` - Main orchestration
- `Onboarding_Record_Trigger_Update_Onboarding_Status` - Status evaluation

### Vendor Program (Vendor_Customization\_\_c)

**Purpose**: Versioned vendor program configuration. The object label is "Vendor Program" while the API name is `Vendor_Customization__c`. Lookups named `Vendor_Program__c` reference this object.

**Key Fields:**

- `Name` (Text) - Program name
- `Status__c` (Picklist) - Draft/Active/Deprecated lifecycle
- `Active__c` (Checkbox) - Active status
- `Vendor__c` (Lookup to Account) - Vendor account
- `Vendor_Program_Group__c` (Lookup) - Default program group
- `Vendor_Program_Requirement_Group__c` (Lookup) - Default requirement group
- `Previous_Version__c` (Lookup) - Parent version

**Relationships:**

- Has many Vendor_Program_Requirement\_\_c
- Has many Vendor_Program_Requirement_Set\_\_c
- Has many Vendor_Program_Recipient_Group\_\_c
- Has many Onboarding**c (via `Vendor_Customization**c`)
- Linked to Vendor_Program_Group**c via Vendor_Program_Group_Member**c

### Vendor_Program_Group\_\_c

**Purpose**: Groups requirements and rules for a vendor program.

**Key Fields:**

- `Name` (Text) - Group name
- `Active__c` (Checkbox) - Active status
- `Logic_Type__c` (Picklist) - Inheritance logic
- `Parent_Group__c` (Lookup) - Optional parent group

**Relationships:**

- Has many Vendor_Program_Group_Member\_\_c
- Has many Onboarding_Status_Rules_Engine\_\_c
- Referenced by Vendor_Customization\_\_c as a default program group

### Vendor_Program_Group_Member\_\_c

**Purpose**: Members of a vendor program group.

**Key Fields:**

- `Vendor_Program_Group__c` (Lookup) - Parent group
- `Required_Program__c` (Lookup to `Vendor_Customization__c`) - Required/included program
- `Inherited_Program_Requirement_Group__c` (Lookup) - Inherited requirement group
- `Is_Target__c` (Checkbox) - Target program flag
- `Active__c` (Checkbox) - Active membership flag

**Relationships:**

- Junction between Vendor_Program_Group**c and Vendor_Customization**c

## Requirement Objects

### Onboarding_Requirement\_\_c

**Purpose**: Tracks individual requirements for an onboarding.

**Key Fields:**

- `Name` (Text) - Requirement name
- `Onboarding__c` (Lookup) - Parent onboarding
- `Vendor_Program_Requirement__c` (Lookup) - Requirement definition
- `Status__c` (Picklist) - Status (Not Started, Incomplete, Complete, Approved, Denied)

**Relationships:**

- Belongs to Onboarding\_\_c
- References Vendor_Program_Requirement\_\_c

**Usage**: Used by status evaluation engine

### Vendor_Program_Requirement\_\_c

**Purpose**: Defines requirements for a vendor program.

**Key Fields:**

- `Name` (Text) - Requirement name
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Parent program
- `Requirement_Template__c` (Lookup) - Source template
- `Requirement_Group_Member__c` (Lookup) - Requirement group member link
- `Status__c` (Picklist) - Requirement status
- `Active__c` (Checkbox) - Active status

**Relationships:**

- Belongs to Vendor_Customization**c (via `Vendor_Program**c`)
- Referenced by Onboarding_Requirement\_\_c

## Status Rules Objects

### Onboarding_Status_Rules_Engine\_\_c

**Purpose**: Defines a rules engine for status evaluation.

**Key Fields:**

- `Name` (Text) - Rules engine name
- `Vendor_Program_Group__c` (Lookup) - Associated program group
- `Requirement_Group__c` (Lookup) - Associated requirement group
- `Target_Onboarding_Status__c` (Text) - Status to set when rule passes
- `Evaluation_Logic__c` (Picklist) - Logic type (ALL, ANY, CUSTOM)
- `Custom_Evaluation_Logic__c` (Text) - Custom expression

**Relationships:**

- Belongs to Vendor_Program_Group\_\_c
- Has many Onboarding_Status_Rule\_\_c

**Usage**: Used by status evaluation engine

### Onboarding_Status_Rule\_\_c

**Purpose**: Individual rule conditions within a rules engine.

**Key Fields:**

- `Name` (Text) - Rule name
- `Parent_Rule__c` (Lookup) - Parent rules engine
- `Requirement__c` (Lookup) - Requirement to evaluate
- `Expected_Status__c` (Text) - Expected requirement status
- `Rule_Number__c` (Number) - Order of evaluation

**Relationships:**

- Belongs to Onboarding_Status_Rules_Engine\_\_c
- References Vendor_Program_Requirement\_\_c

**Usage**: Used in rule evaluation logic

## Application Framework Objects

### Onboarding_Application_Process\_\_c

**Purpose**: Defines a reusable onboarding flow process.

**Key Fields:**

- `Name` (Text) - Process name
- `Description__c` (Text) - Process description
- `Active__c` (Checkbox) - Active status

**Relationships:**

- Has many Onboarding_Application_Stage\_\_c
- Has many Onboarding_Application_Progress\_\_c

### Onboarding_Application_Stage\_\_c

**Purpose**: Defines a stage within an onboarding process.

**Key Fields:**

- `Name` (Text) - Stage name
- `Onboarding_Application_Process__c` (Lookup) - Parent process
- `Onboarding_Component_Library__c` (Lookup) - Component to render
- `Display_Order__c` (Number) - Order in flow
- `Label__c` (Text) - Display label
- `Required__c` (Checkbox) - Whether stage is required
- `Next_Stage__c` (Lookup) - Next stage (for branching)

**Relationships:**

- Belongs to Onboarding_Application_Process\_\_c
- References Onboarding_Component_Library\_\_c
- Self-referential for branching

### Onboarding_Component_Library\_\_c

**Purpose**: Maps LWC components to metadata.

**Key Fields:**

- `Name` (Text) - Component name
- `Component_API_Name__c` (Text) - LWC component API name
- `Description__c` (Text) - Component description

**Relationships:**

- Referenced by Onboarding_Application_Stage\_\_c

### Onboarding_Application_Progress\_\_c

**Purpose**: Tracks user progress through an onboarding process.

**Key Fields:**

- `Onboarding_Application_Process__c` (Lookup) - Process being executed
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program being onboarded
- `Current_Stage__c` (Lookup) - Current stage

**Relationships:**

- Belongs to Onboarding_Application_Process\_\_c
- References Vendor_Customization**c (via `Vendor_Program**c`)
- References Onboarding_Application_Stage\_\_c

### Onboarding_Application_Stage_Completion\_\_c

**Purpose**: Audit log of completed stages.

**Key Fields:**

- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program
- `Onboarding_Application_Process__c` (Lookup) - Process
- `Onboarding_Application_Stage__c` (Lookup) - Completed stage
- `Completed_Date__c` (DateTime) - Completion timestamp
- `Completed_By__c` (Lookup to User) - User who completed

**Relationships:**

- References Vendor_Customization**c (via `Vendor_Program**c`)
- References Onboarding_Application_Process\_\_c
- References Onboarding_Application_Stage\_\_c

## Training Objects

### Training_Requirement\_\_c

**Purpose**: Defines training requirements.

**Key Fields:**

- `Name` (Text) - Requirement name
- `Training_System__c` (Lookup) - Training system
- `Active__c` (Checkbox) - Active status

**Relationships:**

- References Training_System\_\_c

### Training_Assignment\_\_c

**Purpose**: Tracks training assignments to contacts.

**Key Fields:**

- `Name` (Text) - Assignment name
- `Contact__c` (Lookup) - Assigned contact
- `Training_Requirement__c` (Lookup) - Training requirement
- `Status__c` (Picklist) - Assignment status

**Relationships:**

- Belongs to Contact
- References Training_Requirement\_\_c

### Training_System\_\_c

**Purpose**: Defines training systems.

**Key Fields:**

- `Name` (Text) - System name
- `Active__c` (Checkbox) - Active status

**Relationships:**

- Has many Training_Requirement\_\_c

## Credential Objects

### External_Contact_Credential_Type\_\_c

**Purpose**: Defines types of credentials for external contacts.

**Key Fields:**

- `Name` (Text) - Credential type name
- `Active__c` (Checkbox) - Active status

**Relationships:**

- Has many POE_External_Contact_Credential\_\_c

**Duplicate Prevention**: Matching rule prevents duplicates

### POE_External_Contact_Credential\_\_c

**Purpose**: Tracks credentials for external contacts.

**Key Fields:**

- `Name` (Text) - Credential name
- `Contact__c` (Lookup) - Contact
- `External_Contact_Credential_Type__c` (Lookup) - Credential type
- `Status__c` (Picklist) - Credential status
- `Unique_Key__c` (Text) - Unique identifier (auto-generated)

**Relationships:**

- Belongs to Contact
- References External_Contact_Credential_Type\_\_c

**Duplicate Prevention**: Matching rule prevents duplicates per contact/type

### Required_Credential\_\_c

**Purpose**: Defines required credentials for programs.

**Key Fields:**

- `Name` (Text) - Requirement name
- `Credential_Type__c` (Lookup) - Required credential type
- `Active__c` (Checkbox) - Active status

**Relationships:**

- References External_Contact_Credential_Type\_\_c

### Required_External_Contact_Credential\_\_c

**Purpose**: Links required credentials to vendor programs.

**Key Fields:**

- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program
- `Required_Credential__c` (Lookup) - Required credential

**Relationships:**

- References Vendor_Customization**c (via `Vendor_Program**c`)
- References Required_Credential\_\_c

### External_Credential_Type_Dependency\_\_c

**Purpose**: Defines dependencies between credential types.

**Key Fields:**

- `Credential_Type__c` (Lookup) - Credential type
- `Dependent_Credential_Type__c` (Lookup) - Dependent credential type

**Relationships:**

- References External_Contact_Credential_Type\_\_c (self-referential)

## ECC Configuration Objects

### ECC_Field_Configuration_Group\_\_c

**Purpose**: Groups field configurations for ECC forms.

**Key Fields:**

- `Name` (Text) - Group name
- `Active__c` (Checkbox) - Active status

**Relationships:**

- Has many ECC_Field_Configuration_Group_Mapping\_\_c

### ECC_Field_Display_Configuration\_\_c

**Purpose**: Defines how fields are displayed in ECC forms.

**Key Fields:**

- `Name` (Text) - Configuration name
- `Field_API_Name__c` (Text) - Salesforce field API name
- `Display_Label__c` (Text) - Display label
- `Required__c` (Checkbox) - Whether field is required
- `Display_Order__c` (Number) - Order in form

**Relationships:**

- Referenced by ECC_Field_Configuration_Group_Mapping\_\_c

### ECC_Field_Configuration_Group_Mapping\_\_c

**Purpose**: Maps field configurations to groups.

**Key Fields:**

- `ECC_Field_Configuration_Group__c` (Lookup) - Configuration group
- `ECC_Field_Display_Configuration__c` (Lookup) - Field configuration

**Relationships:**

- Belongs to ECC_Field_Configuration_Group\_\_c
- References ECC_Field_Display_Configuration\_\_c

## Related Documentation

- [Data Model](../architecture/data-model.md)
- [Onboarding Process](../processes/onboarding-process.md)
- [Status Evaluation](../processes/status-evaluation.md)
