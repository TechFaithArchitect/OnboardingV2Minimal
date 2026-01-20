# Data Model

## Core Objects

### Onboarding__c

The central object that tracks an onboarding request for a vendor.

**Key Fields:**
- `Account__c` (Master-Detail to Account) - The vendor account
- `Onboarding_Status__c` - Current status (e.g., "Not Started", "In Progress", "Complete", "Denied", "Expired")
- `Interview_Status__c` - Interview status (picklist)
- `Vendor_Customization__c` (Lookup) - Related vendor customization

**Relationships:**
- Master-Detail to Account
- Has many Onboarding_Requirement__c records

### Interview__c

Tracks interview status for a Contact during onboarding.

**Key Fields:**
- `Contact__c` (Lookup to Contact) - Interviewed contact
- `Interview_Status__c` (Picklist) - Interview status

**Relationships:**
- Belongs to Contact (Contact relates to Account via AccountContactRelation)

**Note**: The mapping that selects the correct Onboarding__c (Account + Vendor Program) to update from Interview__c is not defined yet.

### Vendor Program (Vendor_Customization__c)

Represents a versioned vendor program configuration. The object label is "Vendor Program" while the API name is `Vendor_Customization__c`. Many lookup fields in this app are named `Vendor_Program__c` but reference `Vendor_Customization__c`.

**Key Fields:**
- `Name` - Program name
- `Status__c` - Version status (Draft/Active/Deprecated)
- `Active__c` - Whether the program is active
- `Vendor__c` (Lookup) - Related vendor account
- `Vendor_Program_Group__c` (Lookup) - Default program group
- `Vendor_Program_Requirement_Group__c` (Lookup) - Default requirement group
- `Previous_Version__c` - Links to parent version for versioning

**Relationships:**
- Has many Vendor_Program_Requirement__c records
- Has many Vendor_Program_Requirement_Set__c records (links to Onboarding_Requirement_Set__c)
- Has many Vendor_Program_Recipient_Group__c records
- Has many Onboarding__c records (via `Vendor_Customization__c`)
- Linked to Vendor_Program_Group__c via Vendor_Program_Group_Member__c

**Activation Constraints:**
- All child `Vendor_Program_Requirement__c` records must be active
- All requirement templates referenced by requirements must be active
- The linked `Vendor_Program_Requirement_Group__c` must be active (`AllRequirementGroupsMustBeActiveRule`)
- Only one active version per parent (enforced by versioning handler)

### Vendor_Program_Group__c

Groups requirements and rules for a vendor program. Follows the Campaign/Campaign Member pattern for many-to-many relationships.

**Key Fields:**
- `Name` - Group name
- `Active__c` - Whether the group is active
- `Logic_Type__c` - Inheritance logic for group membership
- `Parent_Group__c` (Lookup) - Optional parent group

**Relationships:**
- Has many Vendor_Program_Group_Member__c records (junction object)
- Has many Onboarding_Status_Rules_Engine__c records
- Referenced by Vendor_Customization__c as a default program group

**Pattern:** Campaign/Campaign Member - allows many-to-many relationships between Groups and Vendor Programs

### Vendor_Program_Group_Member__c

Junction object implementing the Campaign Member pattern. Links Vendor Programs to Groups with relationship-specific attributes.

**Key Fields:**
- `Required_Program__c` (Lookup to `Vendor_Customization__c`) - Links to the vendor program
- `Vendor_Program_Group__c` (Lookup to `Vendor_Program_Group__c`) - Links to the group
- `Inherited_Program_Requirement_Group__c` (Lookup to `Vendor_Program_Requirement_Group__c`) - Links to requirement groups
- `Is_Target__c` (Checkbox) - Flag for special handling (e.g., target program in group)
- `Active__c` (Checkbox) - Active status for the membership

**Relationships:**
- Junction object between Vendor_Program_Group__c and Vendor_Customization__c
- Allows many-to-many: one program can belong to multiple groups, one group can contain multiple programs

**Pattern:** Campaign Member - stores relationship-specific attributes on the junction object

### Onboarding_Requirement__c

Tracks individual requirements for an onboarding record. Represents the completion status of a requirement for a specific onboarding.

**Key Fields:**
- `Onboarding__c` (Lookup) - Parent onboarding
- `Vendor_Program_Requirement__c` (Lookup) - Related requirement definition
- `Status__c` - Requirement status (Not Started, Incomplete, Complete, Approved, Denied)

**Relationships:**
- Belongs to Onboarding__c
- References Vendor_Program_Requirement__c

**Purpose:** Tracks completion status for requirements during an onboarding process

### Recipient_Group__c

Reusable group used for onboarding communications.

**Key Fields:**
- `Name` - Group name
- `Group_Type__c` - Group type
- `Is_Active__c` - Active flag
- `Description__c` - Description

**Relationships:**
- Has many Recipient_Group_Member__c records
- Linked to Vendor_Customization__c via Vendor_Program_Recipient_Group__c

### Recipient_Group_Member__c

Membership record for a recipient group.

**Key Fields:**
- `Recipient_Group__c` (Lookup) - Parent group
- `Recipient_User__c` (Lookup to User) - Recipient user when member type is User
- `Member_Type__c` - Member type
- `Recipient_Type__c` - Recipient type
- `Role_Assignment__c` (Lookup) - Optional role assignment

**Relationships:**
- Belongs to Recipient_Group__c

### Vendor_Program_Recipient_Group__c

Versioned association between a Vendor Program and a Recipient Group.

**Key Fields:**
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program
- `Recipient_Group__c` (Lookup) - Recipient group
- `Status__c` - Version status
- `Version__c` / `Parent_Version__c` - Versioning chain
- `Is_Active__c` - Active flag
- `Filter_Logic__c` - Filter/trigger logic
- `Order__c` - Evaluation order

**Relationships:**
- Belongs to Vendor_Customization__c (via `Vendor_Program__c`)
- Belongs to Recipient_Group__c

## Requirement Objects

The requirement system uses a multi-layered approach with reusable bundles, templates, categorization, and instances.

### Onboarding_Requirement_Dependency__c

Defines prerequisite relationships between onboarding requirements.

**Key Fields:**
- `Onboarding_Requirement__c` (Lookup) - Parent requirement
- `Dependent_Requirement__c` (Lookup) - Required/prerequisite requirement

**Relationships:**
- Links two Onboarding_Requirement__c records

### Onboarding_Requirement_Set__c ⭐ **Reusable Bundle/Starter Pack**

**Purpose:** Reusable bundle of requirement templates (like a "starter pack"). Pre-configured sets that can be applied to multiple vendor programs.

**Key Fields:**
- `Name` - Set name (e.g., "Enterprise Vendor Starter Pack")
- `Version__c` - Version number
- `Status__c` - Version status (Draft/Active/Deprecated)
- `Active__c` - Whether the requirement set is active

**Use Case:** Create pre-configured bundles of requirements that can be reused across multiple vendor programs.

**Example:** "Standard Vendor Onboarding Set" containing 10 common requirements that can be applied to any new vendor program.

**Relationships:**
- Has many Requirement_Set_Template__c records (junction to templates)
- Linked to Vendor_Customization__c via Vendor_Program_Requirement_Set__c

**Activation Constraints:**
- Must be active before linked templates can be activated (rule exists but is not currently registered in the activation registry)

### Vendor_Program_Onboarding_Req_Template__c

**Purpose:** Template definitions for individual requirements. These are the building blocks within a requirement set.

**Key Fields:**
- `Name` - Template name
- `Onboarding_Requirement_Set__c` (Lookup, legacy) - Optional parent bundle/set
- `Category_Group__c` (Lookup to `Vendor_Program_Requirement_Group__c`) - Categorization
- `Requirement_Label__c` - Display label
- `Requirement_Type__c` - Type of requirement (e.g., "Document", "Training")
- `Status__c` - Version status
- `Active__c` - Whether the template is active
- `Is_Current_Version__c` - Version flag

**Relationships:**
- Linked to Onboarding_Requirement_Set__c via Requirement_Set_Template__c (primary)
- Direct `Onboarding_Requirement_Set__c` lookup is retained for backward compatibility
- Categorized by Vendor_Program_Requirement_Group__c
- Referenced by Vendor_Program_Requirement__c (instances created from templates)

**Pattern:** Template/Instance - Templates define what requirements exist, instances are created for specific programs

**Activation Constraints:**
- Parent `Onboarding_Requirement_Set__c` must be active (rule exists but is not currently registered in the activation registry)
- Must be active before linked vendor programs are activated when legacy activation rules are used (`AllTemplatesInReqSetMustBeActiveRule`)

### Vendor_Program_Requirement_Group__c ⭐ **Categorization/Organization**

**Purpose:** Categorizes and organizes requirements for logical grouping. Follows Campaign pattern.

**Key Fields:**
- `Name` - Group name (e.g., "Legal Requirements", "Financial Requirements")
- `Status__c` - Version status (Draft/Active/Deprecated)
- `Active__c` - Whether the group is active
- `Version__c` - Version number
- `Previous_Version__c` - Links to parent version for versioning
- `Vendor__c` (Lookup) - Related vendor account

**Use Case:** Organize requirements by category within a set or program.

**Example:** "Legal Requirements Group" containing all legal-related requirements.

**Relationships:**
- Has many Vendor_Program_Requirement_Group_Member__c records (junction object)
- Used to categorize Vendor_Program_Onboarding_Req_Template__c records
- Linked to Vendor_Customization__c via `Vendor_Program_Requirement_Group__c` field
- Referenced by Onboarding_Status_Rules_Engine__c via `Requirement_Group__c`

**Pattern:** Campaign - parent object in Campaign/Campaign Member pattern

**Activation Constraints:**
- Must be active before linked `Vendor_Customization__c` can be activated (`AllRequirementGroupsMustBeActiveRule`)
- All templates in the group should be active (enforced via requirement set/template rules)

### Vendor_Program_Requirement_Group_Member__c

**Purpose:** Junction object linking requirements to groups. Follows Campaign Member pattern.

**Key Fields:**
- `Vendor_Program_Requirement_Group__c` (Lookup) - Parent group
- `Vendor_Program_Requirement_Definition__c` (Lookup to `Vendor_Program_Onboarding_Req_Template__c`) - Requirement template
- `Status__c` - Member status
- `Sequence__c` - Display order
- `Is_Required__c` - Whether the template is required

**Relationships:**
- Junction object between Vendor_Program_Requirement_Group__c and Vendor_Program_Onboarding_Req_Template__c

**Pattern:** Campaign Member - junction object in Campaign/Campaign Member pattern

### Vendor_Program_Requirement__c

**Purpose:** Actual requirement instances on vendor programs. Created from templates for specific programs.

**Key Fields:**
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Parent program
- `Requirement_Template__c` (Lookup to `Vendor_Program_Onboarding_Req_Template__c`) - Source template
- `Requirement_Group_Member__c` (Lookup to `Vendor_Program_Requirement_Group_Member__c`) - Links to group member
- `Active__c` - Whether the requirement is active
- `Is_Inherited__c` - Whether requirement is inherited
- `Is_Overridden__c` - Whether requirement is overridden
- `Is_Required__c` - Whether requirement is mandatory
- `Status__c` - Requirement status (New, Active, etc.)
- `Sequence__c` - Display order

**Relationships:**
- Belongs to Vendor_Customization__c (Vendor Program)
- Created from Vendor_Program_Onboarding_Req_Template__c
- Referenced by Onboarding_Requirement__c (completion tracking)
- Referenced by Onboarding_Status_Rule__c (for status evaluation)

**Pattern:** Instance - Created from templates for specific programs

**Activation Constraints:**
- Must be active before parent `Vendor_Customization__c` can be activated (`AllChildRequirementsMustBeActiveRule`)
- Referenced requirement template must be active (`AllTemplatesInReqSetMustBeActiveRule`)

### Requirement Object Flow

```
Onboarding_Requirement_Set__c (Reusable Bundle/Starter Pack)
  └─ Requirement_Set_Template__c (Junction)
       └─ Vendor_Program_Onboarding_Req_Template__c (Templates in the bundle)
            └─ Category_Group__c → Vendor_Program_Requirement_Group__c (Categorization)

Vendor_Program_Requirement_Group__c (Category/Organization - Campaign pattern)
  └─ Vendor_Program_Requirement_Group_Member__c (Junction - Campaign Member pattern)
       └─ Vendor_Program_Requirement_Definition__c → Vendor_Program_Onboarding_Req_Template__c

Vendor_Customization__c (Vendor Program)
  └─ Vendor_Program_Requirement__c (Instance on Program)

Vendor_Program_Requirement__c (Instance on Program)
  ├─ Vendor_Program__c → Vendor_Customization__c
  ├─ Requirement_Template__c → Vendor_Program_Onboarding_Req_Template__c
  └─ Requirement_Group_Member__c → Vendor_Program_Requirement_Group_Member__c

Onboarding_Requirement__c (Completion Tracking)
  ├─ Onboarding__c
  └─ Vendor_Program_Requirement__c
```

Onboarding_Requirement_Dependency__c links prerequisite Onboarding_Requirement__c records.

### Key Distinction: Set vs Group

**Onboarding_Requirement_Set__c (Bundle/Starter Pack):**
- **What:** A reusable collection of requirement templates
- **Purpose:** Pre-configured bundles that can be applied to multiple programs
- **Analogy:** Like a "starter pack" or "package deal"
- **Example:** "Enterprise Vendor Starter Pack" with 15 standard requirements
- **Reusability:** Can be used across multiple vendor programs
- **Scope:** Program-level or organization-level

**Vendor_Program_Requirement_Group__c (Category/Organization):**
- **What:** A category for organizing requirements
- **Purpose:** Logical grouping/categorization of requirements
- **Analogy:** Like "folders" or "tags" for organization
- **Example:** "Legal Requirements", "Financial Requirements", "Technical Requirements"
- **Reusability:** Used within a program or set for organization
- **Scope:** Organizational structure within a set or program

**Relationship:**
- A **Set** (bundle) contains multiple **Templates**
- Each **Template** can be categorized into a **Group** (category)
- **Groups** organize templates within a set for better management

### Onboarding_Status_Rules_Engine__c

Defines a rule engine for status evaluation.

**Key Fields:**
- `Name` - Rules engine name
- `Vendor_Program_Group__c` (Lookup) - Associated program group
- `Requirement_Group__c` (Lookup) - Associated requirement group
- `Target_Onboarding_Status__c` - Status to set when rule passes
- `Evaluation_Logic__c` - Logic type (AND, OR, Custom)
- `Active__c` - Whether the rules engine is active

**Relationships:**
- Has many Onboarding_Status_Rule__c records
- Linked to Vendor_Program_Group__c
- Linked to Requirement_Group__c (Vendor_Program_Requirement_Group__c)

**Activation Constraints:**
- All child `Onboarding_Status_Rule__c` records must be active
- Both `Vendor_Program_Group__c` and `Requirement_Group__c` must be active

### Onboarding_Status_Rule__c

Individual rule conditions within a rules engine.

**Key Fields:**
- `Name` - Rule name
- `Parent_Rule__c` (Lookup) - Parent rules engine (`Onboarding_Status_Rules_Engine__c`)
- `Requirement__c` (Lookup) - Requirement to evaluate (`Vendor_Program_Requirement__c`)
- `Expected_Status__c` - Expected requirement status
- `Rule_Number__c` - Order of evaluation
- `Active__c` - Whether the rule is active

**Relationships:**
- Belongs to Onboarding_Status_Rules_Engine__c
- References Vendor_Program_Requirement__c

**Activation Constraints:**
- Parent `Onboarding_Status_Rules_Engine__c` must be active
- Related `Vendor_Program_Requirement__c` must be active

## Application Framework Objects

### Onboarding_Application_Process__c

Defines a reusable onboarding flow process.

**Key Fields:**
- `Name` - Process name
- `Description__c` - Process description
- `Active__c` - Whether the process is active

**Relationships:**
- Has many Onboarding_Application_Stage__c records
- Has many Onboarding_Application_Progress__c records

### Onboarding_Application_Stage__c

Defines a stage within an onboarding process.

**Key Fields:**
- `Onboarding_Application_Process__c` (Lookup) - Parent process
- `Onboarding_Component_Library__c` (Lookup) - Component to render
- `Display_Order__c` - Order in the flow
- `Label__c` - Display label
- `Required__c` - Whether stage is required
- `Next_Stage__c` (Lookup) - Next stage (for branching)

**Relationships:**
- Belongs to Onboarding_Application_Process__c
- References Onboarding_Component_Library__c

### Onboarding_Component_Library__c

Maps LWC components to metadata.

**Key Fields:**
- `Component_API_Name__c` - API name of the LWC component
- `Name` - Component name
- `Description__c` - Component description

**Relationships:**
- Referenced by Onboarding_Application_Stage__c

### Onboarding_Application_Progress__c

Tracks user progress through an onboarding process.

**Key Fields:**
- `Onboarding_Application_Process__c` (Lookup) - Process being executed
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program being onboarded
- `Current_Stage__c` (Lookup) - Current stage

**Relationships:**
- Belongs to Onboarding_Application_Process__c
- References Vendor_Customization__c (via `Vendor_Program__c`)

### Onboarding_Application_Stage_Completion__c

Audit log of completed stages.

**Key Fields:**
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Vendor program
- `Onboarding_Application_Process__c` (Lookup) - Process
- `Onboarding_Application_Stage__c` (Lookup) - Completed stage
- `Completed_Date__c` - Completion timestamp
- `Completed_By__c` (Lookup to User) - User who completed

## Training & Credentials Objects

### Training_Requirement__c

Defines training requirements.

**Key Fields:**
- `Name` - Requirement name
- `Training_System__c` (Lookup) - Training system
- `Active__c` - Whether requirement is active

### Training_Assignment__c

Tracks training assignments to contacts.

**Key Fields:**
- `Contact__c` (Lookup) - Assigned contact
- `Training_Requirement__c` (Lookup) - Training requirement
- `Status__c` - Assignment status

### External_Contact_Credential_Type__c

Defines types of credentials for external contacts.

**Key Fields:**
- `Name` - Credential type name
- `Active__c` - Whether type is active

### POE_External_Contact_Credential__c

Tracks credentials for external contacts.

**Key Fields:**
- `Contact__c` (Lookup) - Contact
- `External_Contact_Credential_Type__c` (Lookup) - Credential type
- `Status__c` - Credential status
- `Unique_Key__c` - Unique identifier (auto-generated)

## ECC (External Contact Credential) Configuration Objects

### ECC_Field_Configuration_Group__c

Groups field configurations for ECC forms.

**Key Fields:**
- `Name` - Group name
- `Active__c` - Whether group is active

### ECC_Field_Display_Configuration__c

Defines how fields are displayed in ECC forms.

**Key Fields:**
- `Field_API_Name__c` - Salesforce field API name
- `Display_Label__c` - Display label
- `Required__c` - Whether field is required
- `Display_Order__c` - Order in form

### ECC_Field_Configuration_Group_Mapping__c

Maps field configurations to groups.

**Key Fields:**
- `ECC_Field_Configuration_Group__c` (Lookup) - Configuration group
- `ECC_Field_Display_Configuration__c` (Lookup) - Field configuration

## Entity Relationship Diagram

### Core Onboarding Objects
Account
├── Onboarding__c (Master-Detail)
│ └── Onboarding_Requirement__c
│
└── Vendor_Customization__c (Vendor Program)
    ├── Onboarding__c
    ├── Vendor_Program_Requirement__c
    └── Vendor_Program_Requirement_Set__c
    └── Vendor_Program_Recipient_Group__c → Recipient_Group__c

Vendor_Program_Group__c (Campaign pattern)
└── Vendor_Program_Group_Member__c (Campaign Member pattern)
    ├── Required_Program__c → Vendor_Customization__c
    └── Inherited_Program_Requirement_Group__c
└── Onboarding_Status_Rules_Engine__c
    └── Onboarding_Status_Rule__c

Recipient_Group__c
├── Recipient_Group_Member__c
└── Vendor_Program_Recipient_Group__c → Vendor_Customization__c

### Requirement Objects
Onboarding_Requirement_Set__c (Bundle/Starter Pack)
└── Requirement_Set_Template__c (Junction)
    └── Vendor_Program_Onboarding_Req_Template__c (Templates)
        └── Category_Group__c → Vendor_Program_Requirement_Group__c

Vendor_Program_Requirement_Group__c (Category - Campaign pattern)
└── Vendor_Program_Requirement_Group_Member__c (Junction - Campaign Member pattern)
    └── Vendor_Program_Requirement_Definition__c → Vendor_Program_Onboarding_Req_Template__c

Vendor_Customization__c
└── Vendor_Program_Requirement__c (Instances from templates)
    └── Onboarding_Requirement__c (Completion tracking)
        └── Onboarding_Requirement_Dependency__c

Onboarding_Application_Process__c
├── Onboarding_Application_Stage__c
│ └── Onboarding_Component_Library__c
│
└── Onboarding_Application_Progress__c
└── Onboarding_Application_Stage_Completion__c
Contact
├── Training_Assignment__c
└── POE_External_Contact_Credential__c
└── External_Contact_Credential_Type__c


## Data Integrity

### Duplicate Prevention

- **External_Contact_Credential_Type__c**: Matching rule prevents duplicate credential types
- **POE_External_Contact_Credential__c**: Matching rule prevents duplicate credentials per contact/type
- **Unique Keys**: Auto-generated unique keys for credential records

### Validation Rules (Trigger-Based)

Validation rules execute on record save via triggers and prevent invalid data states.

- **Vendor_Program_Recipient_Group__c**: 
  - `RequireParentVersionOnActivationRule` - Non-draft versions must have parent version
  - `OnlyOneActiveRecGrpPerPrgrmRule` - Only one active recipient group per program
  - `RecipientAndProgramMustBeActiveRule` - Recipient and program must be active
  - `PreventDupRecGrpAssignmentRule` - Prevent duplicate assignments

### Activation Rules (Activation-Time)

Activation rules execute during the activation process (not on save) and prevent records from being activated if dependencies are not met. These rules are enforced by `OnboardingAppActivationService` and `VendorProgramActivationService`.

**Vendor_Customization__c (Vendor Program):**
- `AllRequirementGroupsMustBeActiveRule` - The linked `Vendor_Program_Requirement_Group__c` must be active

**Legacy registry key `Vendor_Program__c`:**
- `AllChildRequirementsMustBeActiveRule` - All child `Vendor_Program_Requirement__c` records must be active
- `AllTemplatesInReqSetMustBeActiveRule` - All requirement templates referenced by requirements must be active

**Onboarding_Status_Rule__c:**
- `AllLinkedEngineMustBeActiveRule` - Parent `Onboarding_Status_Rules_Engine__c` and related `Requirement__c` must be active

**Onboarding_Status_Rules_Engine__c:**
- `AllStatusRulesMustBeActiveRule` - All child `Onboarding_Status_Rule__c` records must be active
- `AllStatusRuleGroupMustBeActiveRule` - Both `Requirement_Group__c` and `Vendor_Program_Group__c` must be active

**Activation Flow:**
1. User initiates activation via `OnboardingAppActivationOrchestrator`
2. Orchestrator routes to appropriate service (`VendorProgramActivationService` or `OnboardingAppActivationService`)
3. Service executes activation rules from `OnboardingAppRuleRegistry.getActivationRulesForObject()`
4. If any rule fails, activation is blocked with `AuraHandledException`
5. If all rules pass, record is set to active and sibling versions are deactivated

**Note:** Both `VendorProgramActivationService` and `OnboardingAppActivationService` execute activation rules before activation.

## Design Patterns Used

- **Campaign/Campaign Member Pattern**: Used for many-to-many relationships (Groups, Requirement Groups, Recipient Groups)
  - See [Architecture Overview - Campaign/Campaign Member Pattern](./overview.md#4-campaigncampaign-member-pattern)
- **Versioning Pattern**: Supports Draft/Active/Deprecated statuses for collaborative workflows
  - See [Architecture Overview - Versioning Pattern](./overview.md#5-versioning-pattern)
- **Template/Instance Pattern**: Templates define requirements, instances are created for programs
  - See [Requirement Objects](#requirement-objects) above
- **Activation Guard Pattern**: Activation rules enforce dependencies before records can be activated
  - See [Activation Rules](#activation-rules-activation-time) above
  - Implemented via `OnboardingAppActivationRule` interface
  - Executed by activation services before setting records to active

## Related Documentation

- [Architecture Overview](./overview.md) - Design patterns and system architecture
- [Custom Objects Details](../objects/custom-objects.md) - Detailed object field definitions
- [Onboarding Process Flow](../processes/onboarding-process.md) - Process workflows
- [Activation Guards Analysis](../reports/security/activation-guards-analysis.md) - Detailed analysis of activation guard classes and rules (historical report)
- [Apex Classes](../components/apex-classes.md) - Apex class documentation including activation services
