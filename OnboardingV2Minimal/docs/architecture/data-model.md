# Data Model

## Core Objects

### Onboarding__c

The central object that tracks an onboarding request for a vendor.

**Key Fields:**
- `Account__c` (Master-Detail to Account) - The vendor account
- `Onboarding_Status__c` - Current status (e.g., "Not Started", "In Progress", "Complete", "Denied", "Expired")
- `Vendor_Customization__c` (Lookup) - Related vendor customization

**Relationships:**
- Master-Detail to Account
- Has many Onboarding_Requirement__c records

### Vendor Program (Vendor_Customization__c)

Represents a versioned vendor program configuration. The object label is "Vendor Program" while the API name is `Vendor_Customization__c`. Many lookup fields in this app are named `Vendor_Program__c` but reference `Vendor_Customization__c`.

**Key Fields:**
- `Name` - Program name
- `Status__c` - Version status (Draft/Active/Deprecated)
- `Active__c` - Whether the program is active
- `Vendor__c` (Lookup) - Related vendor account
- `Vendor_Program_Group__c` (Lookup) - Default program group
- `Previous_Version__c` - Links to parent version for versioning

**Relationships:**
- Has many Vendor_Program_Requirement__c records
- Has many Onboarding__c records (via `Vendor_Customization__c`)
- Linked to Vendor_Program_Group__c via Vendor_Program_Group_Member__c

**Activation Constraints:**
- All child `Vendor_Program_Requirement__c` records must be active
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
- Status evaluation uses Onboarding_Status_Evaluation_Rule__mdt (CMDT)
- Referenced by Vendor_Customization__c as a default program group

**Pattern:** Campaign/Campaign Member - allows many-to-many relationships between Groups and Vendor Programs

### Vendor_Program_Group_Member__c

Junction object implementing the Campaign Member pattern. Links Vendor Programs to Groups with relationship-specific attributes.

**Key Fields:**
- `Required_Program__c` (Lookup to `Vendor_Customization__c`) - Links to the vendor program
- `Vendor_Program_Group__c` (Lookup to `Vendor_Program_Group__c`) - Links to the group
- `Is_Target__c` (Checkbox) - Flag for special handling (e.g., target program in group)
- `Active__c` (Checkbox) - Active status for the membership

**Relationships:**
- Junction object between Vendor_Program_Group__c and Vendor_Customization__c
- Allows many-to-many: one program can belong to multiple groups, one group can contain multiple programs

**Pattern:** Campaign Member - stores relationship-specific attributes on the junction object

### Account_Vendor_Program_Onboarding__c

Links an Account to a specific Onboarding record (and optional Opportunity) for tracking the dealer onboarding engagement.

**Key Fields:**
- `Account__c` (Lookup) - Dealer account
- `Onboarding__c` (Lookup) - Onboarding record
- `Opportunity__c` (Lookup) - Optional onboarding opportunity
- `Status__c` (Picklist/Text) - Intake/in''ùprogress status
- `Primary_Contact__c` (Lookup) - Primary contact for the onboarding

**Relationships:**
- Belongs to Account
- Belongs to Onboarding__c
- Optional link to Opportunity

### Communication_Template__c

Reusable communication templates tied to vendor programs for onboarding outreach (email/SMS).

**Key Fields:**
- `Name` - Template name
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Associated vendor program
- Channel/type fields as configured (Email/SMS)

**Relationships:**
- Linked to Vendor_Customization__c (Vendor Program)

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

## Requirement Objects

The requirement system in V2 minimal is streamlined: requirements are stored directly on `Vendor_Program_Requirement__c` and referenced by `Onboarding_Requirement__c` for completion tracking. Requirement sets, templates, groups, and dependency objects are not part of the current data model.

### Vendor_Program_Requirement__c

**Purpose:** Requirement instances on vendor programs.

**Key Fields:**
- `Vendor_Program__c` (Lookup to `Vendor_Customization__c`) - Parent program
- `Active__c` - Whether the requirement is active
- `Is_Inherited__c` - Whether requirement is inherited
- `Is_Overridden__c` - Whether requirement is overridden
- `Is_Required__c` - Whether requirement is mandatory
- `Status__c` - Requirement status (New, Active, etc.)
- `Sequence__c` - Display order

**Relationships:**
- Belongs to Vendor_Customization__c (Vendor Program)
- Referenced by Onboarding_Requirement__c (completion tracking)
- Status evaluated via Onboarding_Status_Evaluation_Rule__mdt (CMDT)

**Pattern:** Instance - Created for specific programs

**Activation Constraints:**
- Must be active before parent `Vendor_Customization__c` can be activated (`AllChildRequirementsMustBeActiveRule`)

### Requirement Object Flow

```
Vendor_Customization__c (Vendor Program)
  '--'-' Vendor_Program_Requirement__c (Requirements)

Vendor_Program_Requirement__c
  '--'-' Vendor_Program__c 'ùù Vendor_Customization__c

Onboarding_Requirement__c (Completion Tracking)
  '-ù'-' Onboarding__c
  '--'-' Vendor_Program_Requirement__c
```

### Onboarding_Status_Normalization__mdt (CMDT)

Per-requirement status normalization. Maps Requirement_Type__c + Status__c to Normalized_Status__c.

**Key Fields:**
- `Requirement_Type__c` - Requirement type (e.g., Agreement, Contract)
- `Status__c` - Raw requirement status
- `Normalized_Status__c` - Normalized status (e.g., Setup Complete, Denied)
- `Active__c` - Whether the rule is active

**Related:**
- Flow `BLL_Onboarding_Requirement_RCD_Logical_Process` - Record-triggered status evaluation

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

## Supporting Objects

### Program_Dates__c

External custom object (not in this repo) used to track program''ùspecific dates tied to Account.

### Territory_Assignments__c

Territory metadata used for onboarding rep assignment and routing.

### Territory_Role_Assignment__c

User assignment records for territory roles; used for recipient resolution.

### LearnUpon__LearnUponContactEnrollment__c (Managed)

Managed package object for LearnUpon training enrollment tracking.

## Entity Relationship Diagram

### Core Onboarding Objects
Account
'-ù'-''-' Onboarding__c (Master-Detail)
'-ù '--'-''-' Onboarding_Requirement__c
'-ù
'--'-''-' Vendor_Customization__c (Vendor Program)
    '-ù'-''-' Onboarding__c
    '--'-''-' Vendor_Program_Requirement__c

Vendor_Program_Group__c (Campaign pattern)
'--'-''-' Vendor_Program_Group_Member__c (Campaign Member pattern)
    '-ù'-''-' Required_Program__c 'ùù Vendor_Customization__c
(Status evaluation: Onboarding_Status_Evaluation_Rule__mdt)

### Requirement Objects
Vendor_Customization__c
'--'-''-' Vendor_Program_Requirement__c (Requirements)
    '--'-''-' Onboarding_Requirement__c (Completion tracking)

Contact
'-ù'-''-' Training_Assignment__c
'--'-''-' POE_External_Contact_Credential__c
'--'-''-' External_Contact_Credential_Type__c


## Data Integrity

### Duplicate Prevention

- **External_Contact_Credential_Type__c**: Matching rule prevents duplicate credential types
- **POE_External_Contact_Credential__c**: Matching rule prevents duplicate credentials per contact/type
- **Unique Keys**: Auto-generated unique keys for credential records

### Activation Rules (Activation-Time)

Activation rules execute during the activation process (not on save) and prevent records from being activated if dependencies are not met. These rules are enforced by `OnboardingAppActivationService` and `VendorProgramActivationService`.

**Legacy registry key `Vendor_Program__c`:**
- `AllChildRequirementsMustBeActiveRule` - All child `Vendor_Program_Requirement__c` records must be active

**Activation Flow:**
1. User initiates activation via `OnboardingAppActivationOrchestrator`
2. Orchestrator routes to appropriate service (`VendorProgramActivationService` or `OnboardingAppActivationService`)
3. Service executes activation rules from `OnboardingAppRuleRegistry.getActivationRulesForObject()`
4. If any rule fails, activation is blocked with `AuraHandledException`
5. If all rules pass, record is set to active and sibling versions are deactivated

**Note:** Both `VendorProgramActivationService` and `OnboardingAppActivationService` execute activation rules before activation.

## Design Patterns Used

- **Campaign/Campaign Member Pattern**: Used for many-to-many relationships (Vendor Program Groups)
  - See [Architecture Overview - Campaign/Campaign Member Pattern](./overview.md#4-campaigncampaign-member-pattern)
- **Versioning Pattern**: Supports Draft/Active/Deprecated statuses for collaborative workflows
  - See [Architecture Overview - Versioning Pattern](./overview.md#5-versioning-pattern)
- **Template/Instance Pattern**: Templates define requirements, instances are created for programs
  - See [Requirement Objects](#requirement-objects) above
## Related Documentation

- [Architecture Overview](./overview.md) - Design patterns and system architecture
- [Custom Objects Details](../objects/custom-objects.md) - Detailed object field definitions
- [Onboarding Process Flow](../processes/onboarding-process.md) - Process workflows
- [Apex Classes](../components/apex-classes.md) - Apex class documentation including activation services
