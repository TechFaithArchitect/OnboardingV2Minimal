# Custom Objects

## Core Onboarding Objects

### Onboarding__c

**Purpose**: Central object tracking an onboarding request for a Dealer (Account).

**Key Fields:**
- `Name` (Auto-Number) - Onboarding Number
- `Account__c` (Master-Detail to Account) - Dealer (Account)
- `Onboarding_Status__c` (Picklist) - Business-facing onboarding status for a Dealer (Account) and Vendor Program (for example: New, In Process, Pending Initial Review, Setup Complete); driven by the status rules engine unless an external override is enabled.
- `External_Override_Enabled__c` (Checkbox) - When true, automated status evaluation should not update the status.
- `External_Override_Reason__c` (Long Text Area) - Reason for granting the override.
- `External_Override_Source__c` (Text) - Source system or user that requested the override.
- `External_Override_Request_ID__c` (Text) - External request correlation ID.
- `External_Override_Programs__c` (Long Text Area) - Optional list of allowed programs for the override.
- `External_Override_Date__c` (DateTime) - Timestamp when the override was applied.
- `Previous_Status_Before_Override__c` (Text) - Status snapshot used to restore status when the override is removed.
- `Interview_Status__c` (Picklist) - Interview status
- `Vendor_Customization__c` (Lookup) - Related vendor customization

External overrides are audited in `Onboarding_External_Override_Log__c`.

**Relationships:**
- Master-Detail to Account
- Has many Onboarding_Requirement__c

**Sharing**: Controlled by Parent (Account)

**Key Flows:**
- `APP_Onboarding` - Main orchestration
- `Onboarding_Record_Trigger_Update_Onboarding_Status` - Status evaluation

### Interview__c

**Purpose**: Tracks interview status for a specific Contact during onboarding.

**Key Fields:**
- `Contact__c` (Lookup to Contact) - Interviewed contact
- `Interview_Status__c` (Picklist) - Interview status

**Relationships:**
- Belongs to Contact (Contact relates to Account via AccountContactRelation)

**Note**: The mapping that selects the correct Onboarding__c (Account + Vendor Program) to update from Interview__c is not defined yet and must be specified.

### Vendor Program (Vendor_Customization__c)

**Important**: The object label is **Vendor Program**, but the API name is **Vendor_Customization__c**. Many lookups are named `Vendor_Program__c` and reference `Vendor_Customization__c`.

**Purpose**: Versioned vendor program customization chosen during onboarding; drives requirement groups, status rules, and wizard selection.

**Key Fields:**
- `Name` (Text) - Program customization name
- `Status__c` (Picklist) - Draft/Active/Deprecated lifecycle
- `Active__c` (Checkbox) - Active status
- `Version__c` (Number) / `Previous_Version__c` (Lookup) - Versioning chain
- `Vendor__c` (Lookup to Account) - Vendor account
- `Vendor_Program_Group__c` (Lookup) - Default program group
- `Vendor_Program_Requirement_Group__c` (Lookup) - Default requirement group bundle
- Insurance/eligibility flags (e.g., `General_Liability_Insurance_Needed__c`, `Auto_Insurance_Needed__c`, `Works_Comp_Insurance_Needed__c`)
- Template/config fields (e.g., `Action_Plan_Template__c`, `Contract_Record_Type__c`, `Order_Entry_Platform__c`)

**Relationships:**
- Can belong to a `Vendor_Program_Group__c` via `Vendor_Program_Group_Member__c`
- Has many `Vendor_Program_Requirement__c` records
- Has many `Vendor_Program_Requirement_Set__c` records (links to `Onboarding_Requirement_Set__c`)
- Has many `Vendor_Program_Recipient_Group__c` records
- Drives `Onboarding__c` records through selection in the wizard

### Vendor_Program_Group__c

**Purpose**: Groups related vendor program customizations so they share requirement sets, rules, and stage dependencies in the onboarding wizard.

**Key Fields:**
- `Name` (Text) - Group name
- `Active__c` (Checkbox) - Active status
- `Logic_Type__c` (Picklist) - Control inheritance behavior
- `Parent_Group__c` (Lookup) - Optional parent group

**Relationships:**
- Has many `Vendor_Program_Group_Member__c`
- Has many `Onboarding_Status_Rules_Engine__c`
- Referenced by vendor onboarding wizard services when selecting programs

### Vendor_Program_Group_Member__c

**Purpose**: Links a specific vendor program customization (`Vendor_Customization__c`) to a `Vendor_Program_Group__c`; supports versioned history and inheritance.

**Key Fields:**
- `Vendor_Program_Group__c` (Lookup) - Parent group
- `Required_Program__c` (Lookup to Vendor_Customization__c) - Program required/included
- `Inherited_Program_Requirement_Group__c` (Lookup) - Inherited requirement group
- `Is_Target__c` (Checkbox) - Marks the target program in the grouping
- `Active__c` (Checkbox) - Controls current membership validity

**Relationships:**
- Junction between Vendor_Program_Group__c and Vendor_Customization__c; used by requirement set services for historical membership

## Recipient Group Objects

### Recipient_Group__c

**Purpose**: Reusable recipient group for onboarding communications.

**Key Fields:**
- `Name` (Text) - Group name
- `Group_Type__c` (Picklist) - Group type
- `Is_Active__c` (Checkbox) - Active flag
- `Description__c` (Text) - Description

**Relationships:**
- Has many Recipient_Group_Member__c
- Linked to vendor programs via Vendor_Program_Recipient_Group__c

### Recipient_Group_Member__c

**Purpose**: Member record for a recipient group.

**Key Fields:**
- `Recipient_Group__c` (Lookup) - Parent group
- `Recipient_User__c` (Lookup to User) - Recipient user (for User member type)
- `Member_Type__c` (Picklist) - Member type
- `Recipient_Type__c` (Picklist) - Recipient type
- `Role_Assignment__c` (Lookup) - Optional role assignment

**Relationships:**
- Belongs to Recipient_Group__c

### Vendor_Program_Recipient_Group__c

**Purpose**: Versioned association between a vendor program and a recipient group.

**Key Fields:**
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program
- `Recipient_Group__c` (Lookup) - Recipient group
- `Status__c` (Picklist) - Version status
- `Version__c` / `Parent_Version__c` (Number/Lookup) - Versioning chain
- `Is_Active__c` (Checkbox) - Active flag
- `Filter_Logic__c` (Text) - Filter/trigger logic
- `Order__c` (Number) - Evaluation order

**Relationships:**
- Belongs to Vendor_Customization__c (via `Vendor_Program__c`)
- Belongs to Recipient_Group__c

## Requirement Objects

### Onboarding_Requirement__c

**Purpose**: Tracks individual requirements for an onboarding.

**Key Fields:**
- `Name` (Text) - Requirement name
- `Onboarding__c` (Lookup) - Parent onboarding
- `Vendor_Program_Requirement__c` (Lookup) - Requirement definition
- `Status__c` (Picklist) - Status (Not Started, Incomplete, Complete, Approved, Denied)

**Relationships:**
- Belongs to Onboarding__c
- References Vendor_Program_Requirement__c

**Usage**: Used by status evaluation engine

### Onboarding_Requirement_Dependency__c

**Purpose**: Defines prerequisite relationships between onboarding requirements.

**Key Fields:**
- `Onboarding_Requirement__c` (Lookup) - Parent requirement
- `Dependent_Requirement__c` (Lookup) - Required prerequisite

**Relationships:**
- Links two Onboarding_Requirement__c records

### Onboarding_Requirement_Set__c

**Purpose**: Reusable bundle of requirement templates that can be applied to vendor programs.

**Key Fields:**
- `Name` (Text) - Requirement set name
- `Status__c` (Picklist) - Draft/Active/Deprecated lifecycle
- `Active__c` (Checkbox) - Active status
- `Version__c` (Number) - Version number

**Relationships:**
- Linked to templates via `Requirement_Set_Template__c`
- Linked to vendor programs via `Vendor_Program_Requirement_Set__c`

### Vendor_Program_Onboarding_Req_Template__c

**Purpose**: Template definition for an individual requirement.

**Key Fields:**
- `Requirement_Label__c` (Text) - Display label
- `Requirement_Type__c` (Picklist) - Type (Document/Training/etc.)
- `Status__c` (Picklist) - Version status
- `Active__c` (Checkbox) - Active status
- `Onboarding_Requirement_Set__c` (Lookup, legacy) - Optional parent set
- `Category_Group__c` (Lookup) - Requirement group/category

**Relationships:**
- Linked to requirement sets via `Requirement_Set_Template__c`
- Categorized by `Vendor_Program_Requirement_Group__c`
- Referenced by `Vendor_Program_Requirement__c`

### Vendor_Program_Requirement_Group__c

**Purpose**: Categorizes requirement templates into logical groups.

**Key Fields:**
- `Name` (Text) - Group name
- `Status__c` (Picklist) - Draft/Active/Deprecated lifecycle
- `Active__c` (Checkbox) - Active status
- `Version__c` / `Previous_Version__c` (Number/Lookup) - Versioning chain

**Relationships:**
- Has many `Vendor_Program_Requirement_Group_Member__c`
- Referenced by `Vendor_Customization__c` and `Onboarding_Status_Rules_Engine__c`

### Vendor_Program_Requirement_Group_Member__c

**Purpose**: Junction linking requirement groups to templates.

**Key Fields:**
- `Vendor_Program_Requirement_Group__c` (Lookup) - Parent group
- `Vendor_Program_Requirement_Definition__c` (Lookup) - Requirement template
- `Status__c` (Picklist) - Member status
- `Sequence__c` (Number) - Display order
- `Is_Required__c` (Checkbox) - Required flag

**Relationships:**
- Junction between `Vendor_Program_Requirement_Group__c` and `Vendor_Program_Onboarding_Req_Template__c`
- Referenced by `Vendor_Program_Requirement__c`

### Vendor_Program_Requirement__c

**Purpose**: Defines requirements for a vendor program.

**Key Fields:**
- `Name` (Text) - Requirement name
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Parent program
- `Requirement_Template__c` (Lookup to `Vendor_Program_Onboarding_Req_Template__c`) - Source template
- `Requirement_Group_Member__c` (Lookup to `Vendor_Program_Requirement_Group_Member__c`) - Group member link
- `Status__c` (Picklist) - Requirement status
- `Active__c` (Checkbox) - Active status
- `Is_Required__c` (Checkbox) - Required flag
- `Sequence__c` (Number) - Display order

**Relationships:**
- Belongs to Vendor_Customization__c (via `Vendor_Program__c`)
- Referenced by Onboarding_Requirement__c
- Referenced by Onboarding_Status_Rule__c

## Status Rules Objects

### Onboarding_Status_Rules_Engine__c

**Purpose**: Defines a rules engine for status evaluation.

**Key Fields**:
- `Name` (Text) - Rules engine name
- `Vendor_Program_Group__c` (Lookup) - Associated program group
- `Requirement_Group__c` (Lookup) - Associated requirement group
- `Target_Onboarding_Status__c` (Text) - Status to set when rule passes
- `Override_Status__c` (Checkbox) - Forces the target status without evaluating requirements
- `Sequence__c` (Number) - Rule evaluation order for engines in the same program group
- `Evaluation_Logic__c` (Picklist) - Logic type (ALL, ANY, CUSTOM)
- `Custom_Evaluation_Logic__c` (Text) - Custom expression
- `Status__c` (Picklist) - Draft/Active/Deprecated lifecycle
- `Version__c` (Text) - Version identifier
- `Effective_Start__c` (DateTime) - Effective date/time for rule activation
- `Effective_End__c` (DateTime) - End date/time for rule deactivation
- `Previous_Version__c` (Lookup to Onboarding_Status_Rules_Engine__c) - Link to previous version

**Relationships**:
- Belongs to Vendor_Program_Group__c
- Has many Onboarding_Status_Rule__c

**Usage**: Used by status evaluation engine

**Notes**:
- Rules engines with Status__c = 'Active' are evaluated during status updates
- Effective dating allows scheduled rule activation/deactivation
- Versioning supports rollback and audit trails
- Previous_Version__c links to the parent version for lineage tracking

### Onboarding_Status_Rule__c

**Purpose**: Individual rule conditions within a rules engine.

**Key Fields:**
- `Name` (Text) - Rule name
- `Parent_Rule__c` (Lookup) - Parent rules engine
- `Requirement__c` (Lookup) - Requirement to evaluate
- `Expected_Status__c` (Text) - Expected requirement status
- `Rule_Number__c` (Number) - Order of evaluation

**Relationships:**
- Belongs to Onboarding_Status_Rules_Engine__c
- References Vendor_Program_Requirement__c

**Usage**: Used in rule evaluation logic

## Application Framework Objects

### Onboarding_Application_Process__c

**Purpose**: Defines a reusable onboarding flow process.

**Key Fields:**
- `Name` (Text) - Process name
- `Description__c` (Text) - Process description
- `Active__c` (Checkbox) - Active status

**Relationships:**
- Has many Onboarding_Application_Stage__c
- Has many Onboarding_Application_Progress__c

### Onboarding_Application_Stage__c

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
- Belongs to Onboarding_Application_Process__c
- References Onboarding_Component_Library__c
- Self-referential for branching

### Onboarding_Component_Library__c

**Purpose**: Maps LWC components to metadata.

**Key Fields:**
- `Name` (Text) - Component name
- `Component_API_Name__c` (Text) - LWC component API name
- `Description__c` (Text) - Component description

**Relationships:**
- Referenced by Onboarding_Application_Stage__c

### Onboarding_Application_Progress__c

**Purpose**: Tracks user progress through an onboarding process.

**Key Fields:**
- `Onboarding_Application_Process__c` (Lookup) - Process being executed
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program being onboarded
- `Current_Stage__c` (Lookup) - Current stage

**Relationships:**
- Belongs to Onboarding_Application_Process__c
- References Vendor_Customization__c (via `Vendor_Program__c`)
- References Onboarding_Application_Stage__c

### Onboarding_Application_Stage_Completion__c

**Purpose**: Audit log of completed stages.

**Key Fields:**
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program
- `Onboarding_Application_Process__c` (Lookup) - Process
- `Onboarding_Application_Stage__c` (Lookup) - Completed stage
- `Completed_Date__c` (DateTime) - Completion timestamp
- `Completed_By__c` (Lookup to User) - User who completed

**Relationships:**
- References Vendor_Customization__c (via `Vendor_Program__c`)
- References Onboarding_Application_Process__c
- References Onboarding_Application_Stage__c

### Onboarding_Application_Stage_Dependency__c

**Purpose**: Defines dependency rules between onboarding stages. Uses a Campaign/Campaign Member pattern to allow flexible dependency management that persists even when stage orders change.

**Key Fields:**
- `Name` (Text, 80) - Dependency rule name
- `Logic_Type__c` (Picklist) - Evaluation logic: ALL (all members must be complete), ANY (at least one member must be complete), or CUSTOM (custom logic)
- `Required__c` (Checkbox) - Whether this dependency is required
- `Required_Stage__c` (Lookup to Onboarding_Application_Stage__c) - The stage that has dependencies (legacy field, may be deprecated)
- `Target_Stage__c` (Lookup to Onboarding_Application_Stage__c) - The stage that requires dependencies to be met before it can be started

**Relationships:**
- Has many Onboarding_App_Stage_Dependency_Member__c (Master-Detail)
- References Onboarding_Application_Stage__c (via Required_Stage__c and Target_Stage__c)

**Usage**: 
- Used to enforce that certain stages must be completed before others can be started
- The Campaign/Campaign Member pattern allows long-term reference even if stage orders change
- Logic_Type__c determines how multiple dependency members are evaluated (ALL vs ANY)

**Best Practices:**
- Use descriptive names like "Vendor Selection Required Before Program Setup"
- Set Target_Stage__c to the stage that requires dependencies
- Use ALL logic when all dependencies must be met, ANY when at least one is sufficient

### Onboarding_App_Stage_Dependency_Member__c

**Purpose**: Individual required stages within a dependency rule. Acts as the "Campaign Member" in the Campaign/Campaign Member pattern.

**Key Fields:**
- `Name` (Auto Number) - Auto-generated member identifier
- `Dependency__c` (Master-Detail to Onboarding_Application_Stage_Dependency__c) - Parent dependency rule
- `Required_Stage__c` (Lookup to Onboarding_Application_Stage__c) - The stage that must be completed
- `Required__c` (Checkbox) - Whether this specific member is required (allows optional dependencies)

**Relationships:**
- Belongs to Onboarding_Application_Stage_Dependency__c (Master-Detail)
- References Onboarding_Application_Stage__c (via Required_Stage__c)

**Usage:**
- Each member represents one stage that must be completed
- Multiple members can be added to a single dependency rule
- The parent dependency's Logic_Type__c determines how members are evaluated together

**Best Practices:**
- Add one member per required stage
- Use Required__c to mark optional dependencies (though Logic_Type__c on parent typically handles this)

## Training Objects

### Training_Requirement__c

**Purpose**: Defines training requirements.

**Key Fields:**
- `Name` (Text) - Requirement name
- `Training_System__c` (Lookup) - Training system
- `Active__c` (Checkbox) - Active status

**Relationships:**
- References Training_System__c

### Training_Assignment__c

**Purpose**: Tracks training assignments to contacts.

**Key Fields:**
- `Name` (Text) - Assignment name
- `Contact__c` (Lookup) - Assigned contact
- `Training_Requirement__c` (Lookup) - Training requirement
- `Status__c` (Picklist) - Assignment status

**Relationships:**
- Belongs to Contact
- References Training_Requirement__c

### Training_System__c

**Purpose**: Defines training systems.

**Key Fields:**
- `Name` (Text) - System name
- `Active__c` (Checkbox) - Active status

**Relationships:**
- Has many Training_Requirement__c

## Credential Objects

### External_Contact_Credential_Type__c

**Purpose**: Defines types of credentials for external contacts.

**Key Fields:**
- `Name` (Text) - Credential type name
- `Active__c` (Checkbox) - Active status

**Relationships:**
- Has many POE_External_Contact_Credential__c

**Duplicate Prevention**: Matching rule prevents duplicates

### POE_External_Contact_Credential__c

**Purpose**: Tracks credentials for external contacts.

**Key Fields:**
- `Name` (Text) - Credential name
- `Contact__c` (Lookup) - Contact
- `External_Contact_Credential_Type__c` (Lookup) - Credential type
- `Status__c` (Picklist) - Credential status
- `Unique_Key__c` (Text) - Unique identifier (auto-generated)

**Relationships:**
- Belongs to Contact
- References External_Contact_Credential_Type__c

**Duplicate Prevention**: Matching rule prevents duplicates per contact/type

### Required_Credential__c

**Purpose**: Defines required credentials for programs.

**Key Fields:**
- `Name` (Text) - Requirement name
- `Credential_Type__c` (Lookup) - Required credential type
- `Active__c` (Checkbox) - Active status

**Relationships:**
- References External_Contact_Credential_Type__c

### Required_External_Contact_Credential__c

**Purpose**: Links required credentials to vendor programs.

**Key Fields:**
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program
- `Required_Credential__c` (Lookup) - Required credential

**Relationships:**
- References Vendor_Customization__c (via `Vendor_Program__c`)
- References Required_Credential__c

### External_Credential_Type_Dependency__c

**Purpose**: Defines dependencies between credential types.

**Key Fields:**
- `Credential_Type__c` (Lookup) - Credential type
- `Dependent_Credential_Type__c` (Lookup) - Dependent credential type

**Relationships:**
- References External_Contact_Credential_Type__c (self-referential)

## ECC Configuration Objects

### ECC_Field_Configuration_Group__c

**Purpose**: Groups field configurations for ECC forms.

**Key Fields:**
- `Name` (Text) - Group name
- `Active__c` (Checkbox) - Active status

**Relationships:**
- Has many ECC_Field_Configuration_Group_Mapping__c

### ECC_Field_Display_Configuration__c

**Purpose**: Defines how fields are displayed in ECC forms.

**Key Fields:**
- `Name` (Text) - Configuration name
- `Field_API_Name__c` (Text) - Salesforce field API name
- `Display_Label__c` (Text) - Display label
- `Required__c` (Checkbox) - Whether field is required
- `Display_Order__c` (Number) - Order in form

**Relationships:**
- Referenced by ECC_Field_Configuration_Group_Mapping__c

### ECC_Field_Configuration_Group_Mapping__c

**Purpose**: Maps field configurations to groups.

**Key Fields:**
- `ECC_Field_Configuration_Group__c` (Lookup) - Configuration group
- `ECC_Field_Display_Configuration__c` (Lookup) - Field configuration

**Relationships:**
- Belongs to ECC_Field_Configuration_Group__c
- References ECC_Field_Display_Configuration__c

## Related Documentation

- [Data Model](../architecture/data-model.md)
- [Onboarding Process](../processes/onboarding-process.md)
- [Status Evaluation](../processes/status-evaluation.md)

## Messaging & Follow-Up Objects

### Follow_Up_Queue__c
**Purpose**: Tracks pending/failed onboarding follow-ups (SMS/Email) with status, attempts, next attempt date, and error details.

**Key Fields:**
- `Follow_Up_Type__c` (Picklist) – SMS, Email, etc.
- `Status__c` (Picklist) – Pending, Pending Retry, Sent, Failed, Suppressed.
- `Next_Attempt_Date__c` (DateTime) – When the next send should occur (supports escalation).
- `Attempt_Count__c` / `Consecutive_Failures__c` (Number) – Send attempt tracking.
- `Error_Message__c` (Long Text) – Latest send error.
- `Follow_Up_Rule__c` (Text) – DeveloperName of the generating rule.
- `Onboarding__c`, `Onboarding_Requirement__c` (Lookups) – Context.

### Follow_Up_Rule__mdt
**Purpose**: Custom metadata defining follow-up triggers, channel/template, delays, escalation schedule, and fatigue limits.

**Key Fields:**
- `Follow_Up_Type__c` (Picklist) – SMS/Email/In-App/Phone.
- `Trigger_Condition__c` (Text) – When to enqueue.
- `Initial_Delay_Days__c` (Number) – Delay before first send.
- `Escalation_Schedule__c` (Long Text, JSON) – Day offsets/steps for escalation.
- `Messaging_Channel__c`, `Messaging_Template__c` (Text) – Channel/template IDs.
- `Max_Attempts_Per_Window__c`, `Fatigue_Window_Days__c`, `Fatigue_Suppression_Enabled__c` – Fatigue controls.
- `Active__c` (Checkbox).

### Follow_Up_Suppression__mdt
**Purpose**: Custom metadata defining suppression windows (holiday/fatigue/manual/system) with optional timezone awareness.

**Key Fields:**
- `Start_Date__c`, `End_Date__c` (Date) – Suppression window.
- `Suppression_Type__c` (Picklist) – Holiday, Fatigue, Manual, System.
- `Timezone_Aware__c` (Checkbox).
- `Fatigue_Rule_Reference__c` (Text) – Rule reference (optional).
- `Active__c` (Checkbox).

### Communication_Template__c
**Purpose**: Unified template registry for onboarding communications (Email/SMS) with channel/template IDs and message body.

**Key Fields:**
- `Communication_Type__c` (Picklist) – Email/SMS.
- `Email_Template_Id__c`, `Email_Subject__c` (Text) – Email metadata.
- `Messaging_Template_Id__c`, `Messaging_Channel_Id__c` (Text) – SMS metadata.
- `Message_Body__c` (Long Text) – SMS/plain-text body when not using a Messaging Template.
- `Active__c`, `DeveloperName__c` (Text).

## Validation & Override Objects

### Requirement_Field__c
**Purpose**: Metadata for individual requirement fields; captures API name, data type, required flag, grouping, and validation linkage.

### Requirement_Field_Value__c
**Purpose**: Captured value and validation status/error for a Requirement_Field__c tied to an onboarding requirement.

### Requirement_Field_Group__c
**Purpose**: Logical grouping of requirement fields for UI display and batch validation.

### Vendor_Program_Requirement_Field__c
**Purpose**: Defines a field in a vendor program requirement template (label, type, rules).

**Key Fields:**
- `Name` (Auto-Number) - Vendor program requirement field number

### Vendor_Program_Requirement_Group_Field__c
**Purpose**: Groups vendor program requirement fields for display/logic within a program template.

**Key Fields:**
- `Name` (Auto-Number) - Vendor program requirement group field number

### Vendor_Program_Requirement_Field_Value__c
**Purpose**: Captured value for a vendor program requirement field.

**Key Fields:**
- `Name` (Auto-Number) - Vendor program requirement field value number

### Requirement_Field_Validation_Rule__mdt
**Purpose**: Custom metadata for reusable validation rules (format, cross-field, external) for requirement fields.

### Validation_Failure__c
**Purpose**: Logs onboarding validation failures with rule name, message, correlation IDs, and retry context.

### Onboarding_External_Override_Log__c
**Purpose**: Audit log for external override operations on Onboarding__c (source, reason, request, status changes).

### OrgWideEmail__c

**Purpose**: Read-only cache of org-wide email addresses synchronized via Apex so onboarding/Vendor Program setup can reference a valid From address.

**Key Fields:**
- `Email_Address__c` (Text) - Org-wide email address
- `Developer_Name__c` / `MasterLabel__c` (Text) - Source identifiers
- `OrgWideEmailAddressId__c` (Lookup/Text) - Id of the source OrgWideEmailAddress record
- `Active__c` (Checkbox) - Whether the address is usable

## Program Template & Dependency Objects

### Vendor_Program_Requirement_Set__c
**Purpose**: Junction linking vendor programs to onboarding requirement sets.

**Key Fields:**
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program
- `Onboarding_Requirement_Set__c` (Lookup) - Requirement set

**Relationships:**
- Belongs to Vendor_Customization__c and Onboarding_Requirement_Set__c

### Requirement_Set_Template__c
**Purpose**: Junction linking requirement sets to requirement templates.

**Key Fields:**
- `Onboarding_Requirement_Set__c` (Lookup) - Requirement set
- `Requirement_Template__c` (Lookup to `Vendor_Program_Onboarding_Req_Template__c`) - Requirement template

**Relationships:**
- Belongs to Onboarding_Requirement_Set__c and Vendor_Program_Onboarding_Req_Template__c
