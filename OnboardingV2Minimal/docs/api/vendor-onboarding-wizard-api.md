# Vendor Onboarding Wizard API Reference

This document provides a comprehensive API reference for all Apex methods used by the Vendor Program Onboarding Wizard components.

## Controller: VendorOnboardingWizardController

**Location:** `force-app/main/default/classes/controllers/VendorOnboardingWizardController.cls`

**Security:** `with sharing`

### Vendor Management

#### searchVendors

```apex
@AuraEnabled(cacheable=true)
public static List<Vendor__c> searchVendors(String vendorNameSearchText)
```

**Purpose:** Searches for vendors by name.

**Parameters:**

- `vendorNameSearchText` (String) - Search text (partial match)

**Returns:** `List<Vendor__c>` - List of matching vendors (limit 10)

**Usage:** Used by `vendorProgramOnboardingVendor` component.

#### createVendor

```apex
@AuraEnabled
public static Id createVendor(Vendor__c vendor)
```

**Purpose:** Creates a new vendor record.

**Parameters:**

- `vendor` (Vendor\_\_c) - Vendor record to create (must include `Name`)

**Returns:** `Id` - ID of created vendor record

**Default Values:** Sets `Active__c = false` (draft)

**Usage:** Used by `vendorProgramOnboardingVendor` component.

### Vendor Program Management

#### searchVendorPrograms

```apex
@AuraEnabled(cacheable=true)
public static List<Vendor_Customization__c> searchVendorPrograms(String vendorProgramNameSearchText)
```

**Purpose:** Searches for vendor programs by name.

**Parameters:**

- `vendorProgramNameSearchText` (String) - Search text (partial match)

**Returns:** `List<Vendor_Customization__c>` - List of matching vendor programs (limit 10)

**Usage:** Used by `vendorProgramOnboardingVendorProgramSearchOrCreate` component.

#### createVendorProgram

```apex
@AuraEnabled
public static Id createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId)
```

**Purpose:** Creates a new draft vendor program.

**Parameters:**

- `vendorProgram` (Vendor_Customization**c) - Vendor program record (must include `Label**c`, `Retail_Option**c`, `Business_Vertical**c`)
- `vendorId` (Id) - Vendor ID to link

**Returns:** `Id` - ID of created vendor program record

**Default Values:**

- `Status__c = 'Draft'`
- `Active__c = false`
- `Vendor__c = vendorId`

**Usage:** Used by `vendorProgramOnboardingVendorProgramSearchOrCreate` component.

#### getRecentVendorPrograms

```apex
@AuraEnabled(cacheable=true)
public static List<Vendor_Customization__c> getRecentVendorPrograms(Integer limitCount)
```

**Purpose:** Gets recent vendor programs.

**Parameters:**

- `limitCount` (Integer) - Maximum number of records to return

**Returns:** `List<Vendor_Customization__c>` - List of recent vendor programs

**Usage:** Used for displaying recent programs.

#### getRetailOptionPicklistValues

```apex
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getRetailOptionPicklistValues()
```

**Purpose:** Gets Retail Option picklist values for `Vendor_Customization__c.Retail_Option__c`.

**Returns:** `List<Map<String, String>>` - List of picklist options with 'label' and 'value' keys

**Usage:** Used by `vendorProgramOnboardingVendorProgramSearchOrCreate` component via `@wire`.

#### getBusinessVerticalPicklistValues

```apex
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getBusinessVerticalPicklistValues()
```

**Purpose:** Gets Business Vertical picklist values for `Vendor_Customization__c.Business_Vertical__c`.

**Returns:** `List<Map<String, String>>` - List of picklist options with 'label' and 'value' keys

**Usage:** Used by `vendorProgramOnboardingVendorProgramSearchOrCreate` component via `@wire`.

#### getVendorProgramLabel

```apex
@AuraEnabled(cacheable=true)
public static String getVendorProgramLabel(Id vendorProgramId)
```

**Purpose:** Gets the `Label__c` field value from a Vendor Program.

**Parameters:**

- `vendorProgramId` (Id) - Vendor Program ID

**Returns:** `String` - Label value

**Usage:** Used for naming conventions in various steps.

### Requirement Set Management

#### searchOnboardingRequirementSets

```apex
@AuraEnabled(cacheable=true)
public static List<Onboarding_Requirement_Set__c> searchOnboardingRequirementSets(String searchText, Id vendorProgramId)
```

**Purpose:** Searches for Onboarding Requirement Sets.

**Parameters:**

- `searchText` (String) - Search text (partial match on Name)
- `vendorProgramId` (Id) - Vendor Program ID (optional filter)

**Returns:** `List<Onboarding_Requirement_Set__c>` - List of matching requirement sets (limit 10)

**Usage:** Used by `vendorProgramOnboardingRequirementSetOrCreate` component.

#### linkRequirementSetToVendorProgram

```apex
@AuraEnabled
public static void linkRequirementSetToVendorProgram(Id requirementSetId, Id vendorProgramId)
```

**Purpose:** Links an existing Requirement Set to a Vendor Program.

**Parameters:**

- `requirementSetId` (Id) - Requirement Set ID
- `vendorProgramId` (Id) - Vendor Program ID

**Returns:** `void`

**Usage:** Used by `vendorProgramOnboardingRequirementSetOrCreate` component when confirming selection.

#### createRequirementSetFromExisting

```apex
@AuraEnabled
public static Id createRequirementSetFromExisting(Id existingRequirementSetId, Id vendorProgramId, String vendorProgramLabel)
```

**Purpose:** Creates a new Requirement Set by copying an existing one.

**Parameters:**

- `existingRequirementSetId` (Id) - Existing Requirement Set ID to copy from
- `vendorProgramId` (Id) - Vendor Program ID to link
- `vendorProgramLabel` (String) - Vendor Program Label for naming convention

**Returns:** `Id` - ID of created Requirement Set

**Naming Convention:** `"Vendor Program Label - Onboarding Set"`

**Usage:** Used by `vendorProgramOnboardingRequirementSetOrCreate` component when making changes.

#### getTemplatesForRequirementSet

```apex
@AuraEnabled(cacheable=true)
public static List<Vendor_Program_Onboarding_Req_Template__c> getTemplatesForRequirementSet(Id requirementSetId)
```

**Purpose:** Gets all templates for a Requirement Set.

**Parameters:**

- `requirementSetId` (Id) - Requirement Set ID

**Returns:** `List<Vendor_Program_Onboarding_Req_Template__c>` - List of templates

**Usage:** Used by `vendorProgramOnboardingRequirementSetOrCreate` component.

#### createRequirementFromTemplate

```apex
@AuraEnabled
public static Id createRequirementFromTemplate(Id templateId, Id vendorProgramId)
```

**Purpose:** Creates a `Vendor_Program_Requirement__c` record from a template.

**Parameters:**

- `templateId` (Id) - Template ID
- `vendorProgramId` (Id) - Vendor Program ID

**Returns:** `Id` - ID of created requirement record

**Note:** The `Name` field is auto-number and cannot be set directly. The `Requirement_Template__c` field links to the template.

**Usage:** Used by `vendorProgramOnboardingRequirementSetOrCreate` component.

### Requirement Group Linking

#### getHistoricalGroupMembers

```apex
@AuraEnabled(cacheable=true)
public static List<Vendor_Program_Group_Member__c> getHistoricalGroupMembers(Id requirementSetId)
```

**Purpose:** Gets historical group members from a Requirement Set's Vendor Program.

**Parameters:**

- `requirementSetId` (Id) - Requirement Set ID

**Returns:** `List<Vendor_Program_Group_Member__c>` - List of historical group members with related data

**Includes:** `Vendor_Program_Group__r.Label__c`, `Inherited_Program_Requirement_Group__r.Name`

**Usage:** Used by `vendorProgramOnboardingRequirementGroupLinking` component.

#### createRequirementGroupComponents

```apex
@AuraEnabled
public static Id createRequirementGroupComponents(Id vendorProgramId, Id requirementSetId, Boolean useHistorical)
```

**Purpose:** Creates and links all Requirement Group components (Vendor Program Group, Requirement Group, Group Member).

**Parameters:**

- `vendorProgramId` (Id) - Vendor Program ID
- `requirementSetId` (Id) - Requirement Set ID (optional, for historical data)
- `useHistorical` (Boolean) - Whether to use historical values

**Returns:** `Id` - ID of created Group Member record

**Naming Conventions:**

- Vendor Program Group: `"Vendor Program Label - Vendor Program Group"`
- Requirement Group: `"Vendor Program Label - Requirement Group"`

**Usage:** Used by `vendorProgramOnboardingRequirementGroupLinking` component.

### Status Rules Engine

#### getHistoricalStatusRulesEngines

```apex
@AuraEnabled(cacheable=true)
public static List<Onboarding_Status_Rules_Engine__c> getHistoricalStatusRulesEngines(Id requirementSetId)
```

**Purpose:** Gets historical Status Rules Engines from a Requirement Set's Vendor Program.

**Parameters:**

- `requirementSetId` (Id) - Requirement Set ID

**Returns:** `List<Onboarding_Status_Rules_Engine__c>` - List of historical engines

**Usage:** Used by `vendorProgramOnboardingStatusRulesEngine` component.

#### searchStatusRulesEngines

```apex
@AuraEnabled(cacheable=true)
public static List<Onboarding_Status_Rules_Engine__c> searchStatusRulesEngines(String nameSearchText)
```

**Purpose:** Searches for Status Rules Engines by name.

**Parameters:**

- `nameSearchText` (String) - Search text (partial match)

**Returns:** `List<Onboarding_Status_Rules_Engine__c>` - List of matching engines (limit 10)

**Usage:** Used by `vendorProgramOnboardingStatusRulesEngine` component.

#### createOnboardingStatusRulesEngine

```apex
@AuraEnabled
public static Id createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine)
```

**Purpose:** Creates a new Status Rules Engine.

**Parameters:**

- `onboardingStatusRulesEngine` (Onboarding_Status_Rules_Engine**c) - Engine record (must include `Name`, `Evaluation_Logic**c`, `Required_Status**c`, `Target_Onboarding_Status**c`)

**Returns:** `Id` - ID of created engine record

**Default Values:** Sets `Active__c = true` if not provided

**Usage:** Used by `vendorProgramOnboardingStatusRulesEngine` component.

#### getEvaluationLogicPicklistValues

```apex
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getEvaluationLogicPicklistValues()
```

**Purpose:** Gets Evaluation Logic picklist values for `Onboarding_Status_Rules_Engine__c.Evaluation_Logic__c`.

**Returns:** `List<Map<String, String>>` - List of picklist options

**Usage:** Used by `vendorProgramOnboardingStatusRulesEngine` component via `@wire`.

#### getRequiredStatusPicklistValues

```apex
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getRequiredStatusPicklistValues()
```

**Purpose:** Gets Required Status picklist values for `Onboarding_Status_Rules_Engine__c.Required_Status__c`.

**Returns:** `List<Map<String, String>>` - List of picklist options

**Usage:** Used by `vendorProgramOnboardingStatusRulesEngine` component via `@wire`.

#### getTargetOnboardingStatusPicklistValues

```apex
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getTargetOnboardingStatusPicklistValues()
```

**Purpose:** Gets Target Onboarding Status picklist values for `Onboarding_Status_Rules_Engine__c.Target_Onboarding_Status__c`.

**Returns:** `List<Map<String, String>>` - List of picklist options

**Usage:** Used by `vendorProgramOnboardingStatusRulesEngine` component via `@wire`.

### Recipient Groups

#### searchRecipientGroups

```apex
@AuraEnabled(cacheable=true)
public static List<Recipient_Group__c> searchRecipientGroups(String recipientGroupNameSearchText)
```

**Purpose:** Searches for Recipient Groups by name.

**Parameters:**

- `recipientGroupNameSearchText` (String) - Search text (partial match)

**Returns:** `List<Recipient_Group__c>` - List of matching groups (limit 10)

**Usage:** Used by `vendorProgramOnboardingRecipientGroup` component.

#### createRecipientGroup

```apex
@AuraEnabled
public static Id createRecipientGroup(Recipient_Group__c recipientGroup)
```

**Purpose:** Creates a new Recipient Group.

**Parameters:**

- `recipientGroup` (Recipient_Group**c) - Group record (must include `Name`, `Group_Type**c`)

**Returns:** `Id` - ID of created group record

**Default Values:**

- `Group_Type__c = 'User'` if not provided
- `Is_Active__c = true` if not provided

**Usage:** Used by `vendorProgramOnboardingRecipientGroup` component.

#### createRecipientGroupMember

```apex
@AuraEnabled
public static Id createRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember)
```

**Purpose:** Creates a new Recipient Group Member.

**Parameters:**

- `recipientGroupMember` (Recipient_Group_Member**c) - Member record (must include `Recipient_Group**c`, `Recipient_User\_\_c`)

**Returns:** `Id` - ID of created member record

**Default Values:**

- `Member_Type__c = 'User'` if not provided
- `Recipient_Type__c = 'To'` if not provided

**Usage:** Used by `vendorProgramOnboardingRecipientGroup` component.

#### getRecipientGroupsForVendorProgram

```apex
@AuraEnabled(cacheable=true)
public static List<Vendor_Program_Recipient_Group__c> getRecipientGroupsForVendorProgram(Id vendorProgramId)
```

**Purpose:** Gets all Recipient Groups linked to a Vendor Program.

**Parameters:**

- `vendorProgramId` (Id) - Vendor Program ID

**Returns:** `List<Vendor_Program_Recipient_Group__c>` - List of linked groups with related data

**Includes:** `Recipient_Group__r.Name`

**Usage:** Used by `vendorProgramOnboardingRecipientGroup` and `vendorProgramOnboardingCommunicationTemplate` components.

#### getRecipientGroupMembers

```apex
@AuraEnabled(cacheable=true)
public static List<Recipient_Group_Member__c> getRecipientGroupMembers(Id recipientGroupId)
```

**Purpose:** Gets all members for a Recipient Group.

**Parameters:**

- `recipientGroupId` (Id) - Recipient Group ID

**Returns:** `List<Recipient_Group_Member__c>` - List of members with related user data

**Includes:** `Recipient_User__r.Name`, `Recipient_User__r.Email`

**Usage:** Used by `vendorProgramOnboardingRecipientGroup` component.

#### getAssignableUsers

```apex
@AuraEnabled(cacheable=true)
public static List<User> getAssignableUsers()
```

**Purpose:** Gets all assignable users for Recipient Group Members.

**Returns:** `List<User>` - List of users with `Id`, `Name`, `Email`

**Usage:** Used by `vendorProgramOnboardingRecipientGroup` component.

#### getGroupTypePicklistValues

```apex
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getGroupTypePicklistValues()
```

**Purpose:** Gets Group Type picklist values for `Recipient_Group__c.Group_Type__c`.

**Returns:** `List<Map<String, String>>` - List of picklist options

**Usage:** Used by `vendorProgramOnboardingRecipientGroup` component via `@wire`.

#### createVendorProgramRecipientGroupLink

```apex
@AuraEnabled
public static Id createVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId)
```

**Purpose:** Creates a link between Vendor Program and Recipient Group.

**Parameters:**

- `vendorProgramId` (Id) - Vendor Program ID
- `recipientGroupId` (Id) - Recipient Group ID

**Returns:** `Id` - ID of created link record

**Default Values:** Sets `Status__c = 'Draft'`

**Usage:** Used by `vendorProgramOnboardingRecipientGroup` component.

### Communication Templates

#### getCommunicationTemplates

```apex
@AuraEnabled(cacheable=true)
public static List<Communication_Template__c> getCommunicationTemplates()
```

**Purpose:** Gets all Communication Templates.

**Returns:** `List<Communication_Template__c>` - List of all templates

**Usage:** Used by `vendorProgramOnboardingCommunicationTemplate` component.

#### createVendorProgramRecipientGroupWithTemplate

```apex
@AuraEnabled
public static Id createVendorProgramRecipientGroupWithTemplate(
    Id vendorProgramId,
    Id recipientGroupId,
    Id communicationTemplateId,
    String triggerCondition
)
```

**Purpose:** Creates a Vendor Program Recipient Group link with Communication Template and trigger condition.

**Parameters:**

- `vendorProgramId` (Id) - Vendor Program ID
- `recipientGroupId` (Id) - Recipient Group ID
- `communicationTemplateId` (Id) - Communication Template ID
- `triggerCondition` (String) - Trigger condition text (e.g., "Onboarding Status = 'Setup Complete'")

**Returns:** `Id` - ID of created link record

**Default Values:** Sets `Status__c = 'Active'`, `Is_Active__c = true`

**Usage:** Used by `vendorProgramOnboardingCommunicationTemplate` component.

**Note:** The trigger condition is stored as text. Actual trigger logic may be implemented via Flows or Process Builder.

### Component Library

#### syncRendererComponents

```apex
@InvocableMethod(label='Sync Component Library' category='Onboarding')
public static void syncRendererComponents()
```

**Purpose:** Syncs the Component Library with all available wizard components.

**Returns:** `void`

**Usage:** Can be called from Flow or Process Builder. Creates/updates `Onboarding_Component_Library__c` records for all wizard components.

## Service Layer: Consolidated Domain Services

**Note:** The `VendorOnboardingWizardService` facade has been removed. The controller now calls domain services directly.

**Consolidated Domain Services:**

- **VendorDomainService** - Vendor, VendorProgram, VendorProgramGroup operations
- **RequirementDomainService** - VendorProgramRequirement, VendorProgramRequirementGroup operations
- **CommunicationDomainService** - CommunicationTemplate, RecipientGroup operations
- **OnboardingRequirementSetService** - Requirement Set operations
- **StatusRulesEngineService** - Status Rules Engine operations

**Security:** All services use `with sharing`

All service methods delegate to the repository layer and add business logic (default values, validation, naming conventions).

## Repository Layer: VendorOnboardingWizardRepository

**Location:** `force-app/main/default/classes/repository/VendorOnboardingWizardRepository.cls`

**Security:** `with sharing`

All repository methods handle SOQL queries and DML operations directly.

## Error Handling

All methods follow consistent error handling:

- Service layer validates inputs and throws `AuraHandledException` for validation errors
- Repository layer throws standard DML exceptions
- Controllers catch exceptions and return user-friendly error messages
- LWC components display errors via toast notifications

## Performance Considerations

- All search methods use `LIKE` with wildcards and apply limits (typically 10 records)
- Cacheable methods use `@AuraEnabled(cacheable=true)` for client-side caching
- Picklist value methods are cacheable and loaded via `@wire` in LWC
- Bulk operations are handled at the service layer when needed

## Security

- All classes use `with sharing` to respect sharing rules
- Field-level security is enforced by Salesforce automatically
- All methods are `@AuraEnabled` for LWC access only
