# Apex API Reference

## OnboardingApplicationService

### getStagesForProcess

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<Onboarding_Application_Stage__c> getStagesForProcess(Id processId)
```

**Description**: Returns stages for an onboarding process, ordered by display order. Includes Label**c, Next_Stage**c, Required\_\_c, and component library relationship.

**Parameters:**

- `processId` (Id) - Onboarding Application Process ID

**Returns**: List of Onboarding_Application_Stage\_\_c records with:

- `Id`, `Name`, `Display_Order__c`
- `Label__c` - Display label for the stage
- `Next_Stage__c` - ID of next stage (for navigation)
- `Required__c` - Whether stage is required
- `Onboarding_Component_Library__r.Component_API_Name__c` - Component API name
- `Onboarding_Component_Library__c` - Component library ID

**Usage:**

```apex
List<Onboarding_Application_Stage__c> stages =
    OnboardingApplicationService.getStagesForProcess(processId);
```

### getProcessDetails

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static Onboarding_Application_Process__c getProcessDetails(Id processId)
```

**Description**: Returns process details.

**Parameters:**

- `processId` (Id) - Onboarding Application Process ID

**Returns**: Onboarding_Application_Process\_\_c record

### saveProgress

**Signature:**

```apex
@AuraEnabled
public static Id saveProgress(Id processId, Id vendorProgramId, Id stageId)
```

**Description**: Upserts progress record and creates stage completion log. Uses upsert for progress (handles both insert and update) and insert for completion (completion records are always new).

**Parameters:**

- `processId` (Id) - Onboarding Application Process ID
- `vendorProgramId` (Id) - Vendor Program ID
- `stageId` (Id) - Current stage ID

**Returns**: Onboarding_Application_Progress\_\_c ID

**Implementation Details:**

- Attempts to query existing progress record
- Uses try-catch to handle QueryException if no record exists
- Upserts progress record (inserts if new, updates if exists)
- Always inserts new completion record

### getProgress

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static Onboarding_Application_Progress__c getProgress(Id vendorProgramId, Id processId)
```

**Description**: Retrieves saved progress.

**Parameters:**

- `vendorProgramId` (Id) - Vendor Program ID
- `processId` (Id) - Onboarding Application Process ID

**Returns**: Onboarding_Application_Progress\_\_c record

### getProcessIdForVendorProgram

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static Id getProcessIdForVendorProgram(Id vendorProgramId)
```

**Description**: Resolves process ID for a vendor program.

**Parameters:**

- `vendorProgramId` (Id) - Vendor Program ID

**Returns**: Onboarding_Application_Process\_\_c ID

## OnboardingRulesService

### getRulesEngineRecords

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<Onboarding_Status_Rule__c> getRulesEngineRecords(Id engineId)
```

**Description**: Returns rules for a rules engine.

**Parameters:**

- `engineId` (Id) - Onboarding Status Rules Engine ID

**Returns**: List of Onboarding_Status_Rule\_\_c records

### createOrUpdateRule

**Signature:**

```apex
@AuraEnabled
public static Onboarding_Status_Rule__c createOrUpdateRule(Onboarding_Status_Rule__c rule)
```

**Description**: Creates or updates a rule.

**Parameters:**

- `rule` (Onboarding_Status_Rule\_\_c) - Rule record

**Returns**: Onboarding_Status_Rule\_\_c record

### deleteRule

**Signature:**

```apex
@AuraEnabled
public static void deleteRule(Id ruleId)
```

**Description**: Deletes a rule.

**Parameters:**

- `ruleId` (Id) - Onboarding Status Rule ID

### getRequirementsByVPR

**Signature:**

```apex
public static Map<Id, Onboarding_Requirement__c> getRequirementsByVPR(Id onboardingId)
```

**Description**: Returns requirements mapped by Vendor Program Requirement ID.

**Parameters:**

- `onboardingId` (Id) - Onboarding ID

**Returns**: Map of Vendor Program Requirement ID to Onboarding_Requirement\_\_c

### getVendorProgramId

**Signature:**

```apex
public static Id getVendorProgramId(Id onboardingId)
```

**Description**: Gets vendor program ID from onboarding.

**Parameters:**

- `onboardingId` (Id) - Onboarding ID

**Returns**: Vendor Program ID

### getVendorProgramGroupIds

**Signature:**

```apex
public static List<Id> getVendorProgramGroupIds(Id vendorProgramId)
```

**Description**: Gets group IDs for a vendor program by querying Vendor_Program_Group_Member\_\_c records.

**Parameters:**

- `vendorProgramId` (Id) - Vendor Program ID (Vendor_Customization\_\_c)

**Returns**: List of Vendor Program Group IDs

**Implementation Note**: Queries `Vendor_Program_Group_Member__c` where `Required_Program__c` equals the vendor program ID.

### getRulesForGroups

**Signature:**

```apex
public static List<Onboarding_Status_Rules_Engine__c> getRulesForGroups(List<Id> groupIds)
```

**Description**: Gets rules engines for vendor program groups, including child rules.

**Parameters:**

- `groupIds` (List<Id>) - List of Vendor Program Group IDs

**Returns**: List of Onboarding_Status_Rules_Engine**c records with child `Onboarding_Status_Rules**r` relationship populated

**Fields Returned:**

- `Id`, `Evaluation_Logic__c`, `Custom_Evaluation_Logic__c`, `Override_Status__c`
- Child relationship: `Onboarding_Status_Rules__r` (Id, Rule_Number**c, Requirement**c, Expected_Status\_\_c)

## OnboardingStatusEvaluator

### evaluateAndApplyStatus

**Signature:**

```apex
public static void evaluateAndApplyStatus(Onboarding__c onboarding)
```

**Description**: Evaluates rules and updates onboarding status.

**Parameters:**

- `onboarding` (Onboarding\_\_c) - Onboarding record to evaluate

**Flow:**

1. Gets requirements for onboarding
2. Gets vendor program ID
3. Gets vendor program group IDs
4. Gets rules for groups
5. Evaluates each rule
6. Updates onboarding status when rule passes

**Usage:**

```apex
Onboarding__c onboarding = [SELECT Id FROM Onboarding__c WHERE Id = :onboardingId];
OnboardingStatusEvaluator.evaluateAndApplyStatus(onboarding);
```

## OnboardingRuleEvaluator

### evaluateRule

**Signature:**

```apex
public static Boolean evaluateRule(
    Onboarding_Status_Rules_Engine__c rule,
    Map<Id, Onboarding_Requirement__c> reqByVPR
)
```

**Description**: Evaluates a rule against requirement statuses.

**Parameters:**

- `rule` (Onboarding_Status_Rules_Engine\_\_c) - Rule to evaluate
- `reqByVPR` (Map<Id, Onboarding_Requirement\_\_c>) - Requirements mapped by VPR ID

**Returns**: Boolean indicating if rule passed

**Logic:**

- Supports ALL, ANY, and CUSTOM evaluation logic
- Uses OnboardingExpressionEngine for custom expressions

## OnboardingExpressionEngine

### evaluate

**Signature:**

```apex
public static Boolean evaluate(String expr)
```

**Description**: Parses and evaluates boolean expressions.

**Parameters:**

- `expr` (String) - Boolean expression

**Returns**: Boolean result

**Expression Syntax:**

- Rule numbers (e.g., "1", "2", "3")
- Operators: AND, OR
- Parentheses for grouping
- Case-insensitive

**Examples:**

```
"1 AND 2"           → true && true
"(1 AND 2) OR 3"   → (true && true) || false
"1 AND (2 OR 3)"   → true && (false || true)
```

## OnboardingRequirementsPanelController

### getRequirements

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<RequirementDTO> getRequirements(Id onboardingId)
```

**Description**: Returns requirements for an onboarding as DTO objects.

**Parameters:**

- `onboardingId` (Id) - Onboarding ID

**Returns**: List of RequirementDTO objects

**RequirementDTO Class:**

- `Id` - Requirement record ID
- `Name` - Requirement name
- `Status` - Requirement status

### updateRequirementStatuses

**Signature:**

```apex
@AuraEnabled
public static void updateRequirementStatuses(List<RequirementDTO> updates)
```

**Description**: Updates requirement statuses.

**Parameters:**

- `updates` (List<RequirementDTO>) - Requirements to update (as DTO objects)

### runRuleEvaluation

**Signature:**

```apex
@AuraEnabled
public static void runRuleEvaluation(Id onboardingId)
```

**Description**: Triggers status re-evaluation.

**Parameters:**

- `onboardingId` (Id) - Onboarding ID

## OnboardingStatusRulesEngineController

### getVendorProgramGroups

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getVendorProgramGroups()
```

**Description**: Returns vendor program groups for picklist.

**Returns**: List of maps with label and value

### getRequirementGroups

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getRequirementGroups()
```

**Description**: Returns requirement groups for picklist.

**Returns**: List of maps with label and value

### getRules

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<Onboarding_Status_Rules_Engine__c> getRules(
    Id vendorProgramGroupId,
    Id requirementGroupId
)
```

**Description**: Returns rules engines for selected vendor program group and requirement group.

**Parameters:**

- `vendorProgramGroupId` (Id) - Vendor Program Group ID
- `requirementGroupId` (Id) - Requirement Group ID (Vendor_Program_Requirement_Group\_\_c)

**Returns**: List of Onboarding_Status_Rules_Engine\_\_c records

**Note**: Queries rules where `Vendor_Program_Group__c` and `Requirement_Group__c` match the provided IDs.

### saveRules

**Signature:**

```apex
@AuraEnabled
public static void saveRules(List<Onboarding_Status_Rule__c> rules)
```

**Description**: Saves rule changes.

**Parameters:**

- `rules` (List<Onboarding_Status_Rule\_\_c>) - Rules to save

## OnboardingAppECCService

**Note:** The `OnboardingAppECCController` has been removed. LWC components now call the service directly.

### getRequiredCredentials

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<Required_Credential__c> getRequiredCredentials(Id vendorProgramId)
```

**Description**: Returns required credentials for a vendor program.

**Parameters:**

- `vendorProgramId` (Id) - Vendor_Customization\_\_c ID

**Returns**: List of Required_Credential\_\_c records

**Usage:** Called directly by LWC components via `@salesforce/apex/OnboardingAppECCService.getRequiredCredentials`

### getAvailableCredentialTypes

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<External_Contact_Credential_Type__c> getAvailableCredentialTypes()
```

**Description**: Returns all available credential types.

**Returns**: List of External_Contact_Credential_Type\_\_c records

**Usage:** Called directly by LWC components

### createCredentialType

**Signature:**

```apex
@AuraEnabled
public static External_Contact_Credential_Type__c createCredentialType(String name)
```

**Description**: Creates a new credential type.

**Parameters:**

- `name` (String) - Name of the credential type

**Returns**: Created External_Contact_Credential_Type\_\_c record

**Usage:** Called directly by LWC components

### linkCredentialTypeToRequiredCredential

**Signature:**

```apex
@AuraEnabled
public static void linkCredentialTypeToRequiredCredential(Id requiredCredentialId, Id credentialTypeId)
```

**Description**: Links a credential type to a required credential.

**Parameters:**

- `requiredCredentialId` (Id) - Required_Credential\_\_c ID
- `credentialTypeId` (Id) - External_Contact_Credential_Type\_\_c ID

**Usage:** Called directly by LWC components

## OnboardingAppActivationService

**Note:** The `OnboardingAppActivationController` and `OnboardingAppActivationOrchestrator` have been consolidated into this service.

### activate

**Signature:**

```apex
@AuraEnabled
public static void activate(Id recordId, String objectApiName)
```

**Description**: Activates a versioned record (vendor program, etc.) with validation.

**Parameters:**

- `recordId` (Id) - Record ID to activate
- `objectApiName` (String) - Object API name (e.g., 'Vendor_Customization\_\_c')

**Flow:**

1. Validates record using OnboardingAppRuleRegistry
2. Applies activation rules
3. Activates the record
4. Handles errors

**Usage:** Called directly by LWC components via `@salesforce/apex/OnboardingAppActivationService.activate`

## OnboardingHomeDashboardController

### getMyActiveOnboarding

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<OnboardingDTO> getMyActiveOnboarding(
    String timeFilter,
    List<Id> vendorIds,
    List<Id> programIds,
    String viewFilter
)
```

**Description**: Returns active onboarding records with filters applied.

**Parameters:**

- `timeFilter` (String) - Time range filter: LAST_30_DAYS, LAST_90_DAYS, YEAR_TO_DATE, ALL_TIME (optional, defaults to LAST_90_DAYS)
- `vendorIds` (List<Id>) - List of vendor IDs to filter by (optional)
- `programIds` (List<Id>) - List of vendor program IDs to filter by (optional)
- `viewFilter` (String) - View filter: MY_VIEW, MY_TEAM, ORG_WIDE (optional, defaults to MY_VIEW)

**Returns**: List of OnboardingDTO objects

**Usage:**

```apex
List<OnboardingDTO> onboardings =
    OnboardingHomeDashboardController.getMyActiveOnboarding(
        'LAST_90_DAYS',
        new List<Id>{ vendorId },
        null,
        'MY_VIEW'
    );
```

### getOnboardingSummary

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static Map<String, Integer> getOnboardingSummary(
    String timeFilter,
    List<Id> vendorIds,
    List<Id> programIds,
    String viewFilter
)
```

**Description**: Returns summary statistics grouped by onboarding status with filters applied.

**Parameters:**

- `timeFilter` (String) - Time range filter (optional, defaults to LAST_90_DAYS)
- `vendorIds` (List<Id>) - List of vendor IDs to filter by (optional)
- `programIds` (List<Id>) - List of vendor program IDs to filter by (optional)
- `viewFilter` (String) - View filter (optional, defaults to MY_VIEW)

**Returns**: Map<String, Integer> with status counts

### getVendorProgramMetrics

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<VendorProgramMetricsDTO> getVendorProgramMetrics(
    String timeFilter,
    List<Id> vendorIds
)
```

**Description**: Returns vendor program health metrics.

**Parameters:**

- `timeFilter` (String) - Time range filter (optional)
- `vendorIds` (List<Id>) - List of vendor IDs to filter by (optional)

**Returns**: List of VendorProgramMetricsDTO objects

### getBlockedOnboardingCount

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static Integer getBlockedOnboardingCount(
    String timeFilter,
    List<Id> vendorIds,
    List<Id> programIds
)
```

**Description**: Returns count of blocked/at-risk onboarding records.

**Parameters:**

- `timeFilter` (String) - Time range filter (optional)
- `vendorIds` (List<Id>) - List of vendor IDs to filter by (optional)
- `programIds` (List<Id>) - List of vendor program IDs to filter by (optional)

**Returns**: Integer count

### getTeamOnboarding

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<OnboardingDTO> getTeamOnboarding(
    String viewFilter,
    String timeFilter,
    List<Id> vendorIds,
    List<Id> programIds
)
```

**Description**: Returns team/org queue data.

**Parameters:**

- `viewFilter` (String) - View filter: MY_TEAM or ORG_WIDE
- `timeFilter` (String) - Time range filter (optional)
- `vendorIds` (List<Id>) - List of vendor IDs to filter by (optional)
- `programIds` (List<Id>) - List of vendor program IDs to filter by (optional)

**Returns**: List of OnboardingDTO objects

### getOnboardingWithBlockingInfo

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<OnboardingWithBlockingDTO> getOnboardingWithBlockingInfo(
    List<Id> onboardingIds
)
```

**Description**: Returns onboarding records with blocking information.

**Parameters:**

- `onboardingIds` (List<Id>) - List of onboarding IDs

**Returns**: List of OnboardingWithBlockingDTO objects

### getVendors

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getVendors()
```

**Description**: Returns list of vendors for filter dropdown.

**Returns**: List of maps with 'label' and 'value' keys

### getVendorPrograms

**Signature:**

```apex
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getVendorPrograms()
```

**Description**: Returns list of vendor programs for filter dropdown.

**Returns**: List of maps with 'label' and 'value' keys

## OnboardingAccessService

### getUserIdsForViewFilter

**Signature:**

```apex
public static Set<Id> getUserIdsForViewFilter(String viewFilter)
```

**Description**: Returns the user IDs that should be treated as owners for the given view filter.

**Parameters:**

- `viewFilter` (String) - One of 'MY_VIEW', 'MY_TEAM', 'ORG_WIDE' (null/blank defaults to 'MY_VIEW')

**Returns**: Set of User IDs representing owners for this view

### getAccountIdsForOwners

**Signature:**

```apex
public static Set<Id> getAccountIdsForOwners(Set<Id> userIds)
```

**Description**: Returns the set of Account IDs that should be considered "owned" by the given user IDs, based on Account ownership and territory assignments.

**Parameters:**

- `userIds` (Set<Id>) - Set of User IDs to treat as owners

**Returns**: Set of Account IDs that are owned by the specified users

## OnboardingBlockingDetectionService

### getBlockedOnboardingIds

**Signature:**

```apex
public static Set<Id> getBlockedOnboardingIds(List<Id> onboardingIds)
```

**Description**: Identifies blocked onboarding records.

**Parameters:**

- `onboardingIds` (List<Id>) - List of onboarding IDs to check

**Returns**: Set of blocked onboarding IDs

### getBlockingReasons

**Signature:**

```apex
public static List<String> getBlockingReasons(Id onboardingId)
```

**Description**: Returns list of blocking reasons for an onboarding record.

**Parameters:**

- `onboardingId` (Id) - Onboarding ID

**Returns**: List of blocking reason strings

### isAtRisk

**Signature:**

```apex
public static Boolean isAtRisk(Id onboardingId, Integer daysThreshold)
```

**Description**: Checks if onboarding is at risk based on age threshold.

**Parameters:**

- `onboardingId` (Id) - Onboarding ID
- `daysThreshold` (Integer) - Days threshold for at-risk determination

**Returns**: Boolean indicating if at risk

## Related Documentation

- [Apex Classes](../components/apex-classes.md)
- [Architecture Overview](../architecture/overview.md)
