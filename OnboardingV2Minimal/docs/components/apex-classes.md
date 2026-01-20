# Apex Classes

## Service Layer

### FollowUpFatigueService

**Location:** `force-app/main/default/classes/services/FollowUpFatigueService.cls`

**Purpose:** Handles follow-up fatigue and suppression logic so dealers are not over-contacted.

**Key Methods:**

- `shouldSuppressDueToFatigue(onboardingRequirementId, followUpRuleDeveloperName)` — checks recent follow-up volume, fatigue rule metadata, and active suppression windows.
- `applyFatigueSuppression(followUpQueueId, reason)` / `removeSuppression(followUpQueueId)` — toggles suppression on queue records.
- `updateAttemptTracking(followUpQueueId, wasSuccessful)` — increments attempt counts and consecutive failures.
- `isSuppressedAccount(accountId)` — evaluates active suppression windows (timezone-aware).

### FollowUpExecutionService

**Location:** `force-app/main/default/classes/services/FollowUpExecutionService.cls`

**Purpose:** Service for executing follow-up actions (SMS, Email, etc.). Handles retry logic and integrates with Salesforce Messaging API and Twilio.

**Key Methods:**

- `sendSMSFollowUp(Id followUpQueueId)` - Sends SMS follow-up via Salesforce Messaging or Twilio
  - Determines SMS provider (prefers `SMS_Provider__c` field, falls back to Messaging Channel presence)
  - Builds provider configuration (from phone, account SID, named credential)
  - Validates configuration before callout
  - Handles both Salesforce Messaging and Twilio providers
  - Updates attempt tracking and marks as failed on error

- `sendEmailFollowUp(Id followUpQueueId)` - Sends email follow-up
  - Uses communication template
  - Handles email sending via Salesforce

- `markFollowUpFailed(Id followUpQueueId, String reason)` - Marks follow-up as failed with reason
- `markFollowUpSuccessful(Id followUpQueueId)` - Marks follow-up as successful
- `retryFailedFollowUps(List<Id> followUpQueueIds)` - Retries failed follow-ups

**Provider Configuration:**

- Supports Salesforce Messaging API (via Messaging Channel)
- Supports Twilio SMS (via Named Credential and Custom Metadata)
- Configuration priority: Rule → Active Twilio Config → Default

**Dependencies:**

- `FollowUpMessagingService` - For messaging operations
- `FollowUpRuleRepository` - For rule metadata
- `TwilioSMSProvider` - For Twilio SMS sending
- `Follow_Up_Rule__mdt` - Follow-up rule metadata
- `Twilio_Configuration__mdt` - Twilio configuration metadata

**Usage:**
Used by follow-up processing flows and scheduled jobs to send SMS and email follow-ups.

### FollowUpMessagingService

**Location:** `force-app/main/default/classes/services/FollowUpMessagingService.cls`

**Purpose:** Service for messaging operations including contact retrieval and message sending.

**Key Methods:**

- `getPrimaryContact(Id accountId)` - Gets primary contact for an account
- Messaging-related helper methods for follow-up execution

**Usage:**
Used by `FollowUpExecutionService` for messaging operations.

### FollowUpDetectionService

**Location:** `force-app/main/default/classes/services/FollowUpDetectionService.cls`

**Purpose:** Service for detecting when follow-ups are needed based on requirement status and rules.

**Key Methods:**

- Detects follow-up requirements based on onboarding requirement status
- Creates follow-up queue records when conditions are met
- Evaluates follow-up rules from metadata

**Usage:**
Used to automatically detect and queue follow-ups based on requirement status changes.

### RequirementFieldValidationService

**Location:** `force-app/main/default/classes/services/RequirementFieldValidationService.cls`

**Purpose:** Validates Requirement_Field_Value\_\_c records using metadata-driven rules. Supports required checks, format validation, and cross-field validation.

**Key Methods:**

- `validateAndUpdate(Set<Id> fieldValueIds)` - Validates and persists field values (synchronous)
  - Updates validation status, error message, and last validated timestamp
  - Returns `List<ValidationResult>` with validation results

- `validate(Set<Id> fieldValueIds)` - Pure evaluation helper (no DML)
  - Useful for LWC/Flow preview or tests
  - Returns validation results without updating records

**Validation Types:**

- **Required Check**: Uses `Requirement_Field__c.Required__c`
- **Format Check**: Uses `Requirement_Field_Validation_Rule__mdt` matched by `Field_API_Name__c`
- **Cross-Field Validation**: Validates relationships between fields
- **External Validation**: Calls external validation services

**ValidationResult Class:**

- `fieldValueId` - Field value record ID
- `fieldApiName` - Field API name
- `status` - Validation status (Valid, Invalid, Pending)
- `message` - Error message if invalid

**Dependencies:**

- `Requirement_Field_Validation_Rule__mdt` - Validation rule metadata
- `RequirementFieldValueRepository` - Data access

**Usage:**
Used by `RequirementFieldValueController` and validation flows to validate requirement field values.

### OnboardingEligibilityService

**Location:** `force-app/main/default/classes/services/OnboardingEligibilityService.cls`

**Purpose:** Service for determining vendor eligibility for onboarding by Account. Encapsulates vendor/program filtering so controllers avoid unpackaged dependencies.

**Key Methods:**

- `getEligibleVendorCountsByAccount(List<Id> accountIds, List<Id> vendorIds, List<Id> programIds)` - Gets eligible vendor counts for accounts
  - Uses active vendor programs
  - Counts distinct vendors (not programs) so UI shows vendor availability
  - Supports optional vendor and program filters
  - Returns `Map<Id, Integer>` with account ID to vendor count

**Eligibility Logic:**

- Only considers active vendor programs
- Filters by vendor IDs if provided
- Filters by program IDs if provided
- Returns count of distinct eligible vendors per account

**Dependencies:**

- `VendorCustomizationRepository` - For active vendor program queries

**Usage:**
Used by `OnboardingHomeDashboardController` to determine which accounts can start new onboarding.

### OnboardingApplicationService

**Location:** `force-app/main/default/classes/OnboardingApplicationService.cls`

**Purpose:** Core service for managing onboarding application processes, stages, and progress.

**Key Methods:**

- `getStagesForProcess(Id processId)` - Returns stages for a process, ordered by display order (includes Label**c, Next_Stage**c, Required\_\_c)
- `getProcessDetails(Id processId)` - Returns process details
- `saveProgress(Id processId, Id vendorProgramId, Id stageId)` - Upserts progress record and creates stage completion log (uses upsert for progress, insert for completion)
- `getProgress(Id vendorProgramId, Id processId)` - Retrieves saved progress
- `getProcessIdForVendorProgram(Id vendorProgramId)` - Resolves process ID for a vendor program
- `getUserFacingStage(String technicalStatus)` - Maps Vendor Program technical status to user-friendly stage
  - ⚠️ **ONLY for Vendor_Customization**c.Status**c** - NOT for Onboarding**c.Onboarding_Status**c
  - Delegates to `VendorProgramStatusMapper.getUserFacingStageForCurrentUser()`
- `isCurrentUserAdmin()` - Checks if current user is an admin
- `getResumeContext(Id onboardingId)` - Returns resume context for an onboarding record
  - Returns `ResumeContext` object with:
    - `completionPercentage` - Overall completion percentage (0-100)
    - `nextIncompleteRequirement` - Next incomplete requirement with first incomplete field
    - `lastCompletedRequirement` - Last completed requirement
  - Used by `onboardingResumePanel` to show progress and navigate to next incomplete requirement

**ResumeContext Class:**

- Inner class used for resume functionality
- Fields: `completionPercentage` (Integer), `nextIncompleteRequirement` (RequirementInfo), `lastCompletedRequirement` (RequirementInfo)
- `RequirementInfo` contains: `id`, `name`, `firstIncompleteField` (FieldInfo with `id` and `name`)

**Usage:**
Primary service used by `onboardingFlowEngine`, `onboardingApplicationFlow`, and `onboardingResumePanel` LWC components.

### OnboardingRulesService

**Location:** `force-app/main/default/classes/OnboardingRulesService.cls`

**Purpose:** Service for managing onboarding status rules and requirements.

**Key Methods:**

- `getRulesEngineRecords(Id engineId)` - Returns rules (Onboarding_Status_Rule\_\_c) for a rules engine
- `createOrUpdateRule(Onboarding_Status_Rule__c rule)` - Creates or updates a rule (Onboarding_Status_Rule\_\_c)
- `deleteRule(Id ruleId)` - Deletes a rule (Onboarding_Status_Rule\_\_c)
- `getRulesEngines(Id vendorProgramGroupId, Id requirementGroupId)` - Gets rules engines filtered by both vendor program group and requirement group (cacheable)
  - Returns `List<Onboarding_Status_Rules_Engine__c>`
  - Used by `OnboardingStatusRulesEngineController` for admin UI
- `getRulesEnginesByVendorProgramGroup(Id vendorProgramGroupId)` - Gets rules engines by vendor program group only (cacheable)
  - Returns `List<Onboarding_Status_Rules_Engine__c>`
- `getRulesEngine(Id ruleId)` - Gets a single rules engine by ID (cacheable)
  - Returns `Onboarding_Status_Rules_Engine__c` or null
- `saveRulesEngines(List<Onboarding_Status_Rules_Engine__c> rulesEngines)` - Saves (updates) multiple rules engines
  - Used by `OnboardingStatusRulesEngineController` for saving datatable edits
- `saveRulesEngine(Onboarding_Status_Rules_Engine__c rulesEngine)` - Saves (upserts) a single rules engine
  - Returns the upserted rules engine
- `getConditions(Id ruleId)` - Gets conditions (Onboarding_Status_Rule\_\_c) for a rules engine (cacheable)
  - Returns `List<Onboarding_Status_Rule__c>`
  - Used for displaying rule conditions
- `saveConditions(List<Onboarding_Status_Rule__c> conditions)` - Saves (upserts) conditions in bulk
  - Used for saving rule conditions
- `getEvaluationContext(Id onboardingId)` - Returns evaluation context with requirements, vendor program ID, and group IDs
  - Returns `OnboardingEvaluationContext` inner class
- `getRequirementsByVPRBulk(Set<Id> onboardingIds)` - Returns requirements mapped by Vendor Program Requirement ID for multiple onboardings (bulk)
  - Returns `Map<Id, Map<Id, Onboarding_Requirement__c>>` (onboarding ID → VPR ID → requirement)
- `getVendorProgramIdsBulk(Set<Id> onboardingIds)` - Gets vendor program IDs for multiple onboardings (bulk)
  - Returns `Map<Id, Id>` (onboarding ID → vendor program ID)
- `getVendorProgramGroupIdsBulk(Set<Id> vendorProgramIds)` - Gets group IDs for multiple vendor programs (bulk)
  - Returns `Map<Id, List<Id>>` (vendor program ID → list of group IDs)
- `getVendorProgramGroupIds(Id vendorProgramId)` - Gets group IDs by querying Vendor_Program_Group_Member**c where Required_Program**c matches (single)
  - Returns `List<Id>`
- `getRulesForGroups(List<Id> groupIds)` - Gets rules engines with child rules populated via Onboarding_Status_Rules\_\_r relationship
  - Returns `List<Onboarding_Status_Rules_Engine__c>` with child rules populated
  - Used by status evaluation engine

**Inner Classes:**

- `OnboardingEvaluationContext` - Contains requirementsByVPR (Map), vendorProgramId (Id), groupIds (List<Id>)

**Usage:**
Used by status evaluation engine, rules management UI (`OnboardingStatusRulesEngineController`), and preview evaluation.

### OnboardingStatusEvaluator

**Location:** `force-app/main/default/classes/services/OnboardingStatusEvaluator.cls`

**Purpose:** Evaluates onboarding status based on rules engine configuration.

**Key Methods:**

- `evaluateAndApplyStatus(Onboarding__c onboarding)` - Evaluates rules and updates onboarding status (single record)
- `evaluateAndApplyStatus(List<Onboarding__c> onboardings)` - Evaluates rules and updates onboarding status (bulk)

**Flow:**

1. Gets requirements for onboarding(s) using bulk methods
2. Gets vendor program IDs in bulk
3. Gets vendor program group IDs in bulk
4. Gets rules for groups
5. Evaluates each rule
6. Updates onboarding status when rule passes

**Performance:**

- Uses bulk methods from `OnboardingRulesService` for efficient processing
- Optimized for processing multiple onboarding records simultaneously

**Usage:**
Called from flows when onboarding records change. Supports both single record and bulk processing.

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

### OnboardingAccessService

**Location:** `force-app/main/default/classes/services/OnboardingAccessService.cls`

**Purpose:** Service for resolving "ownership" and visibility for Onboarding**c records. Encapsulates all ownership and view-filter logic, including handling Territory_Assignments**c.

**Key Methods:**

- `getUserIdsForViewFilter(String viewFilter)` - Returns set of User IDs for a view filter (MY_VIEW, MY_TEAM, ORG_WIDE)
- `getAccountIdsForOwners(Set<Id> userIds)` - Resolves Account IDs based on Account ownership and Territory Assignments (avoids nested subquery issues)
- `buildOwnerClauseForOnboarding(Set<Id> userIds)` - **@deprecated** - Builds SOQL WHERE clause (use getAccountIdsForOwners instead to avoid subquery issues)

**Ownership Model:**

- Account Owner: `Account__r.OwnerId` is always considered an owner
- Onboarding Reps via Territory_Assignments**c: Users in `Onboarding_Rep**c`or`Base_App_OB_Rep\_\_c` fields
- Territory_Assignments\_\_c links to Account via Zip Code Territory junction

**View Filters:**

- MY_VIEW: Only the current user
- MY_TEAM: Current user + all users in their role hierarchy subtree
- ORG_WIDE: No owner filter; caller sees all records allowed by sharing

**Design Decisions:**

- Pre-resolves Account IDs to avoid SOQL subquery limitations
- Separates ownership logic from controller for reusability
- Respects role hierarchy for team views

**Usage:**
Used by `OnboardingHomeDashboardController` and `OnboardingRepository` for ownership resolution.

### OnboardingDashboardFilterService

**Location:** `force-app/main/default/classes/services/OnboardingDashboardFilterService.cls`

**Purpose:** Centralizes filter logic and date range calculations for the dashboard.

**Key Methods:**

- `getDateRangeFilter(String timeFilter)` - Converts time filter to Date range
- `getViewFilterClause(String viewFilter, Id currentUserId)` - Builds WHERE clause for view filter
- `buildFilterClause(String timeFilter, List<Id> vendorIds, List<Id> programIds, String viewFilter)` - Builds complete WHERE clause with all filters
- `buildLastModifiedFilterClause(String timeFilter, List<Id> vendorIds, List<Id> programIds, String viewFilter)` - Builds WHERE clause for LastModifiedDate filters

**Time Filters:**

- LAST_30_DAYS: Records from last 30 days
- LAST_90_DAYS: Records from last 90 days (default)
- YEAR_TO_DATE: Records from January 1st of current year
- ALL_TIME: No time restriction

**Usage:**
Used by `OnboardingHomeDashboardController` for filter logic.

### OnboardingBlockingDetectionService

**Location:** `force-app/main/default/classes/services/OnboardingBlockingDetectionService.cls`

**Purpose:** Detects blocked/at-risk onboarding records.

**Key Methods:**

- `getBlockedOnboardingIds(List<Id> onboardingIds)` - Returns IDs of blocked onboarding records
- `getBlockingReasons(Id onboardingId)` - Returns list of blocking reasons
- `isAtRisk(Id onboardingId, Integer daysThreshold)` - Checks if onboarding is at risk
- `getBlockingInfoBulk(List<Id> onboardingIds)` - Gets blocking info for multiple records (returns Map<Id, BlockingInfo>)

**Blocking Detection:**

- Uses `OnboardingStatusEvaluator` to check requirement status
- Uses `OnboardingStageDependencyService` to check stage dependencies
- Combines both sources for comprehensive blocking detection

**Usage:**
Used by `OnboardingHomeDashboardController` for identifying blocked/at-risk records.

## Controllers

### RequirementFieldValueController

**Location:** `force-app/main/default/classes/controllers/RequirementFieldValueController.cls`

**Purpose:** Saves requirement field values (plain or encrypted) and updates the related `Onboarding_Requirement__c` status.

**Key Methods:**

- `saveFieldValue(requirementFieldValueId, requirementFieldId, onboardingRequirementId, fieldApiName, value, isEncrypted)` — upserts a field value, triggers sync validation and async enqueue, then recalculates requirement status.

### OnboardingHomeDashboardController

**Location:** `force-app/main/default/classes/controllers/OnboardingHomeDashboardController.cls`

**Purpose:** Controller for the onboarding home dashboard LWC component. Provides methods for retrieving dashboard data including active onboarding records, summary statistics, eligible accounts, and recent activity.

**Key Methods:**

- `getMyActiveOnboarding(timeFilter, vendorIds, programIds, viewFilter)` - Returns active onboarding records with filters
  - Filters by ownership (via `OnboardingAccessService`) and time range
  - Supports view filters: MY_VIEW, MY_TEAM, ORG_WIDE
  - Excludes Complete, Denied, and Expired statuses
  - Limits to 20 most recently modified records
  - Returns as `List<OnboardingDTO>`

- `getOnboardingSummary(timeFilter, vendorIds, programIds, viewFilter)` - Returns summary statistics grouped by onboarding status
  - Aggregates counts by status with filters applied
  - Supports view filters: MY_VIEW, MY_TEAM, ORG_WIDE
  - Returns `Map<String, Integer>` with status counts
  - Includes Total count

- `getEligibleAccounts(timeFilter, vendorIds, programIds)` - Returns accounts that can start new onboarding
  - Uses `OnboardingEligibilityService.getEligibleVendorCountsByAccount()` to determine eligibility
  - Returns accounts that have eligible vendor programs not yet onboarded
  - Includes Account details (Name, Territory, Region) and eligible vendor count
  - Returns as `List<AccountDTO>`

- `getRecentActivity(recordLimit, timeFilter, vendorIds, programIds)` - Returns recent onboarding activity with filters
  - Shows records with filters applied
  - Ordered by LastModifiedDate descending
  - Default limit of 10 records (configurable)
  - Returns as `List<OnboardingDTO>`

- `getVendorProgramMetrics(timeFilter, vendorIds)` - Returns vendor program health metrics
  - Includes dealer counts, requirement progress, health indicators
  - Returns as `List<VendorProgramMetricsDTO>`

- `getBlockedOnboardingCount(timeFilter, vendorIds, programIds)` - Returns count of blocked/at-risk records
  - Uses `OnboardingBlockingDetectionService` for detection
  - Returns integer count

- `getTeamOnboarding(viewFilter, timeFilter, vendorIds, programIds)` - Returns team/org queue data
  - Supports MY_TEAM and ORG_WIDE view filters
  - Returns as `List<OnboardingDTO>`

- `getOnboardingWithBlockingInfo(onboardingIds)` - Returns onboarding records with blocking information
  - Adds blocking reasons and at-risk indicators
  - Returns as `List<OnboardingWithBlockingDTO>`

- `getVendors()` - Returns list of vendors for filter dropdown
  - Returns as `List<Map<String, String>>` with label/value pairs

- `getVendorPrograms()` - Returns list of vendor programs for filter dropdown
  - Returns as `List<Map<String, String>>` with label/value pairs

- `getAllActiveOnboarding()` - Returns all active onboarding records (not filtered by creator)
  - Useful for admins/managers
  - Excludes Complete, Denied, and Expired statuses
  - Limited to 50 most recently modified records
  - Returns as `List<OnboardingDTO>`

**DTOs (Data Transfer Objects):**

- `OnboardingDTO` - Represents an onboarding record with related data (Dealer Onboarding)
  - Fields: Id, Name, Status, AccountId, AccountName, VendorProgramId, VendorProgramName, CreatedDate, LastModifiedDate, CreatedById, CreatedByName, RecordUrl
  - Note: Uses `CreatedById`/`CreatedByName` instead of `OwnerId`/`OwnerName` because `Onboarding__c` doesn't have Owner field
  - ⚠️ **Important**: The `Status` field contains `Onboarding__c.Onboarding_Status__c` (Dealer Onboarding status) and should be displayed AS-IS without simplification. Do NOT use `VendorProgramStatusMapper` for this status.
  - **Note**: Class is now `virtual` to allow extension by `OnboardingWithBlockingDTO`

- `OnboardingWithBlockingDTO` - Extends OnboardingDTO with blocking information
  - Extends `OnboardingDTO` (which is now `virtual`)
  - Additional Fields: IsBlocked, IsAtRisk, BlockingReasons, AgeInDays
  - Used by blocking detection service to provide comprehensive blocking information

- `AccountDTO` - Represents an account eligible for onboarding
  - Fields: Id, Name, Territory, Region, EligibleVendorCount, RecordUrl

- `VendorProgramMetricsDTO` - Contains vendor program health metrics
  - Fields: Id, Name, Label, VendorId, VendorName, Status, Active, RecordUrl
  - Metrics: DealersOnboarded, InProgressCount, BlockedCount, TotalRequirements, CompleteRequirements
  - Health Indicators: RulesEngineValid, DependenciesValid
  - GroupNames: List of associated group names

**Design Decisions:**

- **Ownership Model:** Uses `OnboardingAccessService` to resolve ownership based on Account Owner and Territory Assignments. Ownership is determined by:
  1. Account Owner (`Account__r.OwnerId`)
  2. Onboarding Reps via `Territory_Assignments__c` (Onboarding_Rep**c, Base_App_OB_Rep**c)
- **Account-Based Sharing:** Access to onboarding records is controlled by Account sharing rules. The `with sharing` keyword ensures proper security.
- **View Filters:** Supports MY_VIEW (current user), MY_TEAM (role hierarchy), ORG_WIDE (all accessible records)

**Security:**

- Uses `with sharing` to respect Account sharing rules
- Only returns records accessible to the current user based on Account access
- Ownership resolution respects role hierarchy for team views

**Performance:**

- All methods are `@AuraEnabled(cacheable=true)` for client-side caching
- Limits are applied to prevent large result sets
- Bulk queries where possible (e.g., eligible accounts checks multiple accounts at once)
- Ownership resolution uses pre-resolved Account IDs to avoid nested subqueries

**Dependencies:**

- `OnboardingAccessService` - Ownership and view filter resolution
- `OnboardingRepository` - Data access layer
- `OnboardingDashboardFilterService` - Filter logic
- `OnboardingBlockingDetectionService` - Blocking detection

**Usage:**
Used by `onboardingHomeDashboard` LWC component. All methods are called via `@wire` for automatic data loading and refresh.

### OnboardingRequirementsPanelController

**Location:** `force-app/main/default/classes/OnboardingRequirementsPanelController.cls`

**Purpose:** Controller for the onboarding requirements panel LWC with rules version tracking and validation management.

**Key Methods:**

- `getRequirements(Id onboardingId)` - Returns requirements as RequirementDTO objects
- `getInvalidFieldValues(Id onboardingId)` - Returns list of invalid field values for an onboarding (returns List<InvalidFieldDTO>)
- `updateRequirementStatuses(List<RequirementDTO> updates)` - Updates requirement statuses using DTOs and automatically triggers status re-evaluation for affected onboardings
- `runRuleEvaluation(Id onboardingId)` - Triggers status re-evaluation for a single onboarding
- `rerunValidation(List<Id> fieldValueIds)` - Re-runs validation for specific field values
- `getActiveRulesVersion(Id onboardingId)` - Returns current rules version timestamp (returns RulesVersionInfo with lastModifiedDate)
- `refreshAndReevaluate(Id onboardingId)` - Refreshes rules and re-evaluates status, returns new status as String

**DTO Classes:**

- `RequirementDTO` - Inner class used for data transfer
  - Fields: `Id`, `Name`, `Status`
- `InvalidFieldDTO` - Inner class for invalid field values
  - Fields: `fieldValueId`, `requirementName`, `fieldName`, `value`, `errorMessage`
- `RulesVersionInfo` - Inner class for rules version information
  - Fields: `lastModifiedDate` (Datetime)

**Usage:**
Used by `onboardingRequirementsPanel` LWC.

### OnboardingStatusRulesEngineController

**Location:** `force-app/main/default/classes/OnboardingStatusRulesEngineController.cls`

**Purpose:** Controller for the status rules engine management UI with preview evaluation capability.

**Key Methods:**

- `getVendorProgramGroups()` - Returns vendor program groups for picklist (returns List<Map<String, String>> with 'value' and 'label' keys)
  - Queries `Vendor_Program_Group__c` ordered by Name, LIMIT 1000 (cacheable)
- `getRequirementGroups()` - Returns Vendor_Program_Requirement_Group\_\_c records for picklist (returns List<Map<String, String>> with 'value' and 'label' keys)
  - Queries `Vendor_Program_Requirement_Group__c` ordered by Name, LIMIT 1000 (cacheable)
- `getRules(Id vendorProgramGroupId, Id requirementGroupId)` - Returns rules engines filtered by both vendor program group and requirement group
  - Returns `List<Onboarding_Status_Rules_Engine__c>` with fields:
    - `Id`
    - `Name` - Rules engine name (displayed in datatable as read-only)
    - `Required_Status__c`
    - `Target_Onboarding_Status__c` - Target onboarding status (editable in datatable)
    - `Evaluation_Logic__c` - Evaluation logic type (editable in datatable)
    - `Custom_Evaluation_Logic__c` - Custom evaluation logic expression (editable in datatable)
  - Results are ordered by `Name`
- `saveRules(List<Onboarding_Status_Rules_Engine__c> statusRulesEngineRecords)` - Saves rules engine changes
  - Updates the provided rules engine records with any field changes from the datatable
- `getOnboardingOptions(Integer limitCount)` - Returns list of onboarding records for preview evaluation selection (returns List<Map<String, String>> with 'value' and 'label' keys, label format: "Account Name - Vendor Program Name")
  - Filters out Complete and Expired statuses
  - Orders by LastModifiedDate DESC
  - Default limit is 50 if not provided
- `previewStatusEvaluation(Id onboardingId, Datetime asOfDateTime, List<Id> rulesEngineIds)` - Preview status evaluation for an onboarding record without applying changes
  - Returns `List<StatusEvaluationTraceDTO>` showing evaluation trace
  - Shows which rules were evaluated, passed/failed status, and resulting status
  - Supports optional datetime for effective-dated rules (future use)
  - Supports optional rules engine ID filtering (if provided, only evaluates those specific engines)
  - **Evaluation Flow:**
    1. Validates onboarding has vendor program and groups
    2. Checks for external override (if `External_Override_Enabled__c` is true, returns early)
    3. Groups rules engines by vendor program group
    4. Evaluates override rules first (if `Override_Status__c` is true, forces status and short-circuits)
    5. Evaluates non-override rules in order
    6. For each rules engine, evaluates individual rule conditions (Onboarding_Status_Rule\_\_c records)
    7. Returns trace with rule order, pass/fail status, and resulting status
    8. Adds summary trace at end with final resulting status (ruleOrder = 9999)
  - **Short-Circuit Reasons:**
    - "No Vendor Program associated"
    - "No Vendor Program Groups found"
    - "No rules engines found for applicable groups"
    - "External Override Enabled - evaluation skipped"
    - "Override rule - status forced"
    - "Rule evaluation failed"
    - "Requirement not found"
    - "Evaluation complete"
  - **Field Mapping:** Collects mapped field API names from rule conditions and fetches full onboarding record with those fields for evaluation
  - **Private Helper Method:** `collectMappedFieldApiNames(List<Onboarding_Status_Rules_Engine__c> rulesEngines)` - Extracts field API names from rule conditions' Requirement**r.Requirement_Template**r.Onboarding_Status_Field_API_Name\_\_c for dynamic field fetching

**Note:** `getRequirementGroups()` queries `Vendor_Program_Requirement_Group__c` object, not a generic requirement group.

**DTOs:**

- `StatusEvaluationTraceDTO` - Contains evaluation trace information for preview evaluation
  - Fields:
    - `engineId` (Id) - Rules engine ID
    - `engineName` (String) - Rules engine name
    - `groupId` (Id) - Vendor program group ID
    - `groupName` (String) - Vendor program group name
    - `ruleOrder` (Integer) - Order in which rule was evaluated
    - `ruleNumber` (Integer) - Rule number within the engine (for individual rule conditions)
    - `ruleName` (String) - Name of the individual rule condition
    - `requirementName` (String) - Name of the requirement being evaluated
    - `expectedStatus` (String) - Expected status for the requirement
    - `passed` (Boolean) - Whether the rule/condition passed
    - `evaluationLogic` (String) - Evaluation logic used (AND, OR, CUSTOM, OVERRIDE)
    - `resultingStatus` (String) - Resulting onboarding status if rule passed
    - `shortCircuitReason` (String) - Reason why evaluation was short-circuited (e.g., "Override rule - status forced", "Rule evaluation failed", "External Override Enabled - evaluation skipped", "No Vendor Program associated", "No Vendor Program Groups found", "No rules engines found for applicable groups", "Requirement not found", "Evaluation complete")

**Usage:**
Used by `onboardingStatusRulesEngine` and `statusEvaluationPreviewModal` LWC components.

### OnboardingStatusRuleController

**Location:** `force-app/main/default/classes/OnboardingStatusRuleController.cls`

**Purpose:** Controller for status rule list and management components.

**Key Methods:**

- `getRules(Id vendorProgramGroupId)` - Returns rules engines for a vendor program group
- `getRule(Id ruleId)` - Returns a single rules engine by ID
- `getConditions(Id ruleId)` - Returns rule conditions for a rules engine
- `saveRule(Onboarding_Status_Rules_Engine__c rule)` - Saves a rules engine
- `saveConditions(List<Onboarding_Status_Rule__c> conditions)` - Saves rule conditions
- `deleteCondition(Id conditionId)` - Deletes a rule condition

**Usage:**
Used by `onboardingStatusRuleList` and related LWC components.

### OnboardingAppECCService

**Location:** `force-app/main/default/classes/services/OnboardingAppECCService.cls`

**Purpose:** Service for External Contact Credential (ECC) management with direct LWC integration.

**Key Methods:**

- `getRequiredCredentials(Id vendorProgramId)` - @AuraEnabled method, returns required credentials for a vendor program
- `getAvailableCredentialTypes()` - @AuraEnabled method, returns available credential types
- `createCredentialType(String name)` - @AuraEnabled method, creates a new credential type
- `linkCredentialTypeToRequiredCredential(Id requiredCredentialId, Id credentialTypeId)` - @AuraEnabled method, links credential type to required credential

**Usage:**
Called directly by `onboardingAppVendorProgramECCManager` LWC component.

**Dependencies:**

- `OnboardingAppECCRepository` - Data access layer

**Note:** The `OnboardingAppECCController` has been removed. LWC components now call the service directly.

### OnboardingAppActivationService

**Location:** `force-app/main/default/classes/services/OnboardingAppActivationService.cls`

**Purpose:** Service for activating versioned records (vendor programs, etc.) with direct LWC integration.

**Key Methods:**

- `activate(Id recordId, String objectApiName)` - @AuraEnabled method, activates a record with validation

**Usage:**
Called directly by `onboardingAppHeaderBar` LWC component.

**Note:** The `OnboardingAppActivationController` and `OnboardingAppActivationOrchestrator` have been consolidated into this service.

### TwilioSettingsController

**Location:** `force-app/main/default/classes/controllers/TwilioSettingsController.cls`

**Purpose:** Controller for Twilio SMS provider configuration management.

**Key Methods:**

- `getTwilioConfigurations()` - Retrieves all Twilio configurations from Custom Metadata (cacheable)
- `validateConfiguration()` - Validates active Twilio configuration with detailed error messages
  - Checks Named Credential existence
  - Validates Account SID and Auth Token
  - Verifies phone number format
  - Returns validation result with error details

**Usage:**
Used by `twilioSettings` LWC component for Twilio SMS provider administration.

**Dependencies:**

- `Twilio_Configuration__mdt` - Custom Metadata Type for Twilio configurations

### OnboardingStageDependencyController

**Location:** `force-app/main/default/classes/controllers/OnboardingStageDependencyController.cls`

**Purpose:** Controller for onboarding stage dependency visualization and management.

**Key Methods:**

- `getStagesWithDependencies(Id processId, Id vendorProgramId)` - Returns stages with dependency information and completion status
  - Includes stage details (Id, Name, Label, Sequence)
  - Includes dependency information (required stages, completed stages)
  - Includes completion status for each stage
  - Calculates dependency relationships

**Usage:**
Used by `onboardingStageDependencyViewer` LWC component for visualizing stage dependencies.

**Dependencies:**

- `OnboardingStageDependencyService` - For dependency validation logic
- `Onboarding_Application_Process__c` - Process records
- `Onboarding_Application_Stage__c` - Stage records
- `Onboarding_Application_Stage_Dependency__c` - Dependency rules

### OnboardingAdminDashboardController

**Location:** `force-app/main/default/classes/controllers/OnboardingAdminDashboardController.cls`

**Purpose:** Controller for the onboarding admin dashboard. Provides system health metrics, validation failures, messaging issues, and monitoring data.

**Key Methods:**

- `getSystemHealthMetrics()` - Returns system health metrics (cacheable)
  - Validation failures (24h count and trend)
  - Message failures (24h count and trend)
  - Webhook failures (24h count and trend)
  - Platform Event volume (1h)
  - Active follow-up queues count
  - Override operations (7d count)
  - Returns `SystemHealthMetrics` wrapper object

- `getValidationFailures(String groupBy, Map<String, Object> filters)` - Returns validation failures with filtering
  - Supports date range filtering (LAST_24_HOURS, LAST_7_DAYS, LAST_30_DAYS, ALL_TIME)
  - Supports validation type filtering (Format, Cross-Field, External, Other)
  - Filters by startDate calculated from dateRange filter
  - Queries Validation_Failure\_\_c records
  - Returns `List<ValidationFailureDTO>`

- `retryValidation(Id failureId)` - Retries validation for a specific failure
  - **Note:** Currently returns placeholder message (to be implemented in Phase 1)
  - Will trigger re-validation of the field value when implemented
  - Returns success message

- `getMessagingIssues(String groupBy, Map<String, Object> filters)` - Returns messaging issues with filtering
  - Supports date range filtering (LAST_24_HOURS, LAST_7_DAYS, LAST_30_DAYS, ALL_TIME)
  - Supports status filtering (Failed, Pending, Pending Retry)
  - Supports type filtering (SMS, Email, In-App)
  - Defaults to showing Failed, Pending Retry, and Pending statuses
  - Returns `List<MessagingIssueDTO>` (limit 1000, ordered by CreatedDate DESC)

- `retryMessaging(Id issueId)` - Retries failed messaging operation
  - Returns success message

- `dismissMessagingIssue(Id issueId)` - Dismisses a messaging issue
  - Returns success message
  - Sets Status**c to 'Resolved' and Is_Archived**c to true

- `getMessagingIssues(String groupBy, Map<String, Object> filters)` - Returns messaging issues with filtering
  - Supports date range filtering (LAST_24_HOURS, LAST_7_DAYS, LAST_30_DAYS, ALL_TIME)
  - Supports status filtering (Failed, Pending, Pending Retry)
  - Supports type filtering (SMS, Email, In-App)
  - Defaults to showing Failed, Pending Retry, and Pending statuses
  - Returns `List<MessagingIssueDTO>` (limit 1000)

- `getAdobeSyncFailures(String groupBy, Map<String, Object> filters)` - Returns Adobe sync failures with filtering
  - Supports date range filtering (LAST_24_HOURS, LAST_7_DAYS, LAST_30_DAYS, ALL_TIME)
  - Supports status filtering (Pending, Retrying, Resolved, Failed)
  - Supports type filtering (Form Submission, Signature Sync, Document Generation)
  - Returns `List<AdobeSyncFailureDTO>`

- `retryAdobeSync(Id failureId)` - Retries Adobe sync for a specific failure
  - **Note:** Currently returns placeholder message (to be implemented in Phase 3)
  - Will trigger Platform Event to retry the webhook when implemented
  - Returns success message

- `resolveAdobeSyncFailure(Id failureId)` - Marks an Adobe sync failure as resolved
  - **Note:** Currently returns placeholder message (to be implemented in Phase 3)
  - Will update failure status to 'Resolved' when implemented
  - Returns success message

**DTO Classes:**

- `SystemHealthMetrics` - Wrapper for system health metrics
  - Fields: validationFailures24h, validationFailuresTrend, messageFailures24h, messageFailuresTrend, webhookFailures24h, webhookFailuresTrend, platformEventVolume1h, activeFollowUpQueues, overrideOperations7d

- `ValidationFailureDTO` - Validation failure data
  - Fields: id, name, ruleName, requirementFieldApiName, validationResult, message, validatedOn, createdBy, createdDate

- `MessagingIssueDTO` - Messaging issue data
  - Fields: id, followUpType, status, onboardingId, onboardingName, accountName, errorMessage, attemptCount, lastAttemptDate, createdDate

- `AdobeSyncFailureDTO` - Adobe sync failure data
  - Fields: id, failureType, status, onboardingId, onboardingName, accountName, errorMessage, retryCount, lastRetryDate, createdDate

**Dependencies:**

- `OnboardingMetricsRepository` - For metrics data access
- `Validation_Failure__c` - Validation failure object
- `Messaging_Issue__c` - Messaging issue object (or similar)

**Usage:**
Used by `onboardingAdminDashboard`, `validationFailuresPanel`, `validationFailuresTab`, `messagingIssuesPanel`, `messagingIssuesTab`, and `adobeSyncFailuresTab` LWC components.

### VendorOnboardingWizardController

**Location:** `force-app/main/default/classes/controllers/VendorOnboardingWizardController.cls`

**Purpose:** Primary controller for the Vendor Program Onboarding Wizard. Exposes all Apex methods needed by wizard components.

**Key Methods:**

#### Vendor Management

- `searchVendors(String vendorNameSearchText)` - Searches for vendors by name
- `createVendor(Vendor__c vendor)` - Creates new vendor record

#### Vendor Program Management

- `searchVendorPrograms(String vendorProgramNameSearchText)` - Searches for vendor programs by name
- `createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId)` - Creates new draft vendor program
- `getRecentVendorPrograms(Integer limitCount)` - Gets recent vendor programs
- `getRetailOptionPicklistValues()` - Gets Retail Option picklist values (cacheable)
- `getBusinessVerticalPicklistValues()` - Gets Business Vertical picklist values (cacheable)
- `getVendorProgramLabel(Id vendorProgramId)` - Gets Vendor Program Label

#### Requirement Set Management

- `searchOnboardingRequirementSets(String searchText, Id vendorProgramId)` - Searches for requirement sets
- `linkRequirementSetToVendorProgram(Id requirementSetId, Id vendorProgramId)` - Links existing requirement set to vendor program
- `createRequirementSetFromExisting(Id existingRequirementSetId, Id vendorProgramId, String vendorProgramLabel)` - Creates new requirement set by copying existing one
- `getTemplatesForRequirementSet(Id requirementSetId)` - Gets templates for a requirement set
- `createRequirementFromTemplate(Id templateId, Id vendorProgramId)` - Creates Vendor_Program_Requirement\_\_c from template

#### Requirement Group Linking

- `getHistoricalGroupMembers(Id requirementSetId)` - Gets historical group members from requirement set
- `createRequirementGroupComponents(Id vendorProgramId, Id requirementSetId, Boolean useHistorical)` - Creates and links all requirement group components

#### Status Rules Engine

- `getHistoricalStatusRulesEngines(Id requirementSetId)` - Gets historical status rules engines from requirement set
- `searchStatusRulesEngines(String nameSearchText)` - Searches for status rules engines
- `createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine)` - Creates new status rules engine
- `getEvaluationLogicPicklistValues()` - Gets Evaluation Logic picklist values (cacheable)
- `getRequiredStatusPicklistValues()` - Gets Required Status picklist values (cacheable)
- `getTargetOnboardingStatusPicklistValues()` - Gets Target Onboarding Status picklist values (cacheable)

#### Recipient Groups

- `searchRecipientGroups(String recipientGroupNameSearchText)` - Searches for recipient groups
- `createRecipientGroup(Recipient_Group__c recipientGroup)` - Creates new recipient group
- `createRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember)` - Creates recipient group member
- `getRecipientGroupsForVendorProgram(Id vendorProgramId)` - Gets recipient groups for vendor program
- `getRecipientGroupMembers(Id recipientGroupId)` - Gets members for a recipient group
- `getAssignableUsers()` - Gets assignable users for recipient group members
- `getGroupTypePicklistValues()` - Gets Group Type picklist values (cacheable)

#### Communication Templates

- `getCommunicationTemplates()` - Gets all communication templates
- `createVendorProgramRecipientGroupWithTemplate(Id vendorProgramId, Id recipientGroupId, Id communicationTemplateId, String triggerCondition)` - Creates link with template and trigger condition

#### Component Library

- `syncRendererComponents()` - Syncs component library (InvocableMethod for Flow/Process Builder)

**Dependencies:**

- **Consolidated Domain Services** - Business logic layer (see below)
- `VendorOnboardingWizardRepository` - Data access layer

**Usage:**
Used by all Vendor Program Onboarding Wizard LWC components.

**Security:**

- Uses `with sharing` to respect sharing rules
- All methods are `@AuraEnabled` for LWC access

## Vendor Onboarding Wizard Service Layer

**Note:** The `VendorOnboardingWizardService` facade has been removed. The controller now calls consolidated domain services directly.

### Consolidated Domain Services

The following domain services have been created by consolidating related services:

- **VendorDomainService** - Consolidates VendorService, VendorProgramService, VendorProgramGroupService
- **RequirementDomainService** - Consolidates VendorProgramRequirementService, VendorProgramRequirementGroupService
- **CommunicationDomainService** - Consolidates CommunicationTemplateService, RecipientGroupService
- **OnboardingRequirementSetService** - Requirement Set operations (unchanged)
- **StatusRulesEngineService** - Status Rules Engine operations (unchanged)

**Key Methods:** See individual domain service documentation below.

#### Vendor Operations

- `searchVendors(String vendorName)` - Searches vendors
- `createVendor(Vendor__c vendor)` - Creates vendor (sets Active\_\_c = false)

#### Vendor Program Operations

- `searchVendorPrograms(String vendorProgramName)` - Searches vendor programs
- `createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId)` - Creates draft vendor program (Status**c = 'Draft', Active**c = false)
- `getRecentVendorPrograms(Integer limitCount)` - Gets recent vendor programs

#### Requirement Set Operations

- `searchOnboardingRequirementSets(String searchText, Id vendorProgramId)` - Searches requirement sets
- `linkRequirementSetToVendorProgram(Id requirementSetId, Id vendorProgramId)` - Links requirement set to vendor program
- `createRequirementSetFromExisting(Id existingRequirementSetId, Id vendorProgramId, String vendorProgramLabel)` - Creates new requirement set with naming convention
- `getTemplatesForRequirementSet(Id requirementSetId)` - Gets templates for requirement set
- `createRequirementFromTemplate(Id templateId, Id vendorProgramId)` - Creates requirement from template

#### Requirement Group Operations

- `getHistoricalGroupMembers(Id requirementSetId)` - Gets historical group members
- `createRequirementGroupComponents(Id vendorProgramId, Id requirementSetId, Boolean useHistorical)` - Creates and links all requirement group components with naming conventions

#### Status Rules Engine Operations

- `getHistoricalStatusRulesEngines(Id requirementSetId)` - Gets historical status rules engines
- `searchStatusRulesEngines(String onboardingStatusRulesEngine)` - Searches status rules engines
- `createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine)` - Creates status rules engine with defaults

#### Recipient Group Operations

- `searchRecipientGroups(String recipientGroupName)` - Searches recipient groups
- `createRecipientGroup(Recipient_Group__c recipientGroup)` - Creates recipient group with defaults
- `createRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember)` - Creates recipient group member with defaults
- `getRecipientGroupsForVendorProgram(Id vendorProgramId)` - Gets recipient groups for vendor program
- `getRecipientGroupMembers(Id recipientGroupId)` - Gets members for recipient group
- `createVendorProgramRecipientGroupWithTemplate(Id vendorProgramId, Id recipientGroupId, Id communicationTemplateId, String triggerCondition)` - Creates link with template and condition

#### Component Library

- `syncComponentLibrary()` - Syncs component library with all wizard components

**Naming Conventions:**

- Requirement Set: `"Vendor Program Label - Onboarding Set"`
- Vendor Program Group: `"Vendor Program Label - Vendor Program Group"`
- Requirement Group: `"Vendor Program Label - Requirement Group"`

**Default Values:**

- New vendors: `Active__c = false`
- New vendor programs: `Status__c = 'Draft'`, `Active__c = false`
- New requirement sets: `Status__c = 'Draft'`
- New recipient groups: `Group_Type__c = 'User'`, `Is_Active__c = true`
- New recipient group members: `Member_Type__c = 'User'`, `Recipient_Type__c = 'To'`

**Dependencies:**

- `VendorOnboardingWizardRepository` - Data access layer

**Security:**

- Uses `with sharing` to respect sharing rules

## Vendor Onboarding Wizard Repository Layer

### VendorOnboardingWizardRepository

**Location:** `force-app/main/default/classes/repository/VendorOnboardingWizardRepository.cls`

**Purpose:** Data access layer for Vendor Program Onboarding Wizard operations. Handles all SOQL queries and DML operations.

**Key Methods:**

#### Vendor Operations

- `searchVendors(String vendorName)` - SOQL query for vendors
- `insertVendor(Vendor__c vendor)` - DML insert for vendor

#### Vendor Program Operations

- `searchVendorPrograms(String vendorProgramName)` - SOQL query for vendor programs
- `insertVendorProgram(Vendor_Customization__c vendorProgram)` - DML insert for vendor program
- `getRecentVendorPrograms(Integer limitCount)` - SOQL query for recent vendor programs
- `getVendorProgramLabel(Id vendorProgramId)` - Gets Label**c from Vendor_Customization**c

#### Requirement Set Operations

- `searchOnboardingRequirementSets(String searchText, Id vendorProgramId)` - SOQL query for requirement sets
- `linkRequirementSetToVendorProgram(Id requirementSetId, Id vendorProgramId)` - DML update to link requirement set
- `getRequirementSetWithTemplates(Id requirementSetId)` - Gets requirement set with child templates
- `getRequirementTemplate(Id templateId)` - Gets single template record
- `insertOnboardingRequirementSet(Onboarding_Requirement_Set__c requirementSet)` - DML insert for requirement set
- `insertVendorProgramRequirement(Vendor_Program_Requirement__c requirement)` - DML insert for requirement

#### Requirement Group Operations

- `getHistoricalGroupMembers(Id requirementSetId)` - Gets historical group members with related data
- `insertVendorProgramGroup(Vendor_Program_Group__c group)` - DML insert for vendor program group
- `insertVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c group)` - DML insert for requirement group
- `insertVendorProgramGroupMember(Vendor_Program_Group_Member__c member)` - DML insert for group member

#### Status Rules Engine Operations

- `getHistoricalStatusRulesEngines(Id requirementSetId)` - Gets historical engines with related data
- `searchStatusRulesEngines(String onboardingStatusRulesEngine)` - SOQL query for status rules engines
- `insertOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c engine)` - DML insert for status rules engine

#### Recipient Group Operations

- `searchRecipientGroups(String recipientGroupName)` - SOQL query for recipient groups
- `insertRecipientGroup(Recipient_Group__c group)` - DML insert for recipient group
- `insertRecipientGroupMember(Recipient_Group_Member__c member)` - DML insert for recipient group member
- `getRecipientGroupsForVendorProgram(Id vendorProgramId)` - Gets recipient groups for vendor program
- `getRecipientGroupMembers(Id recipientGroupId)` - Gets members for recipient group
- `insertVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId)` - DML insert for vendor program recipient group link

#### Communication Template Operations

- `getCommunicationTemplates()` - SOQL query for communication templates

#### User Operations

- `getAssignableUsers()` - SOQL query for assignable users

**Query Patterns:**

- Uses `LIKE` with wildcards for search operations
- Includes related object fields via relationship queries (e.g., `Recipient_Group__r.Name`)
- Applies limits to prevent large result sets
- Uses `ORDER BY` for consistent sorting

**DML Patterns:**

- Single record inserts for new records
- Updates for linking operations
- No bulk operations (handled by service layer if needed)

**Security:**

- Uses `with sharing` to respect sharing rules
- All queries respect field-level security

**Error Handling:**

- Repository methods throw exceptions that are caught by service layer
- Service layer provides user-friendly error messages

**Dependencies:**

- `OnboardingAppActivationOrchestrator` - Orchestrates activation process

### OnboardingAppECCService

**Location:** `force-app/main/default/classes/services/OnboardingAppECCService.cls`

**Purpose:** Service for External Contact Credential (ECC) management with direct LWC integration.

**Key Methods:**

- `getRequiredCredentials(Id vendorProgramId)` - @AuraEnabled method, returns required credentials for a vendor program (cacheable)
- `getAvailableCredentialTypes()` - @AuraEnabled method, returns all available credential types (cacheable)
- `createCredentialType(String name)` - @AuraEnabled method, creates a new credential type
- `linkCredentialTypeToRequiredCredential(Id requiredCredentialId, Id credentialTypeId)` - @AuraEnabled method, links a credential type to a required credential

**Usage:**
Called directly by `onboardingAppVendorProgramECCManager` LWC component.

**Dependencies:**

- `OnboardingAppECCRepository` - Data access layer

**Note:** The `OnboardingAppECCController` has been removed. LWC components now call the service directly.

## Orchestrators (Legacy)

**Note:** Most orchestrators have been consolidated into services. Only complex multi-domain workflows may still use orchestrators.

**Location:** `force-app/main/default/classes/orchestrators/OnboardingAppVendorProgramReqOrch.cls`

**Purpose:** Orchestrates vendor program requirement operations.

## Services

### OnboardingAppActivationService

**Location:** `force-app/main/default/classes/services/OnboardingAppActivationService.cls`

**Purpose:** Generic activation service that handles activation for any object type with versioning support.

**Key Methods:**

- `activateRecord(String objectApiName, Id recordId)` - Activates a record with validation

**Activation Flow:**

1. Executes activation rules from `OnboardingAppRuleRegistry.getActivationRulesForObject()`
2. Prevents re-activation (checks if already active)
3. Deactivates sibling versions if versioning is supported
4. Sets record to active status

**Guards Implemented:**

- ✅ Executes activation rules before activation
- ✅ Prevents re-activation
- ✅ Handles versioning (deactivates siblings)
- ✅ Supports both `Active__c` and `Is_Active__c` fields

### VendorProgramActivationService

**Location:** `force-app/main/default/classes/services/VendorProgramActivationService.cls`

**Purpose:** Specialized activation service for `Vendor_Customization__c` records.

**Key Methods:**

- `activate(Id recordId)` - Activates a vendor program record
- `activateBulk(Set<Id> recordIds)` - Activates multiple vendor programs in bulk

**Activation Flow:**

1. Executes activation rules from `OnboardingAppRuleRegistry.getActivationRulesForObject('Vendor_Customization__c')`
2. Prevents re-activation (checks if already active)
3. Deactivates sibling versions
4. Sets record to active status
5. Executes post-activation hooks

**Guards Implemented:**

- ✅ Executes activation rules before activation
- ✅ Prevents re-activation
- ✅ Handles versioning (deactivates siblings)
- ✅ Supports bulk activation for better performance

### OnboardingAppECCService

**Location:** `force-app/main/default/classes/OnboardingAppECCService.cls`

**Purpose:** Service for External Contact Credential (ECC) operations. Provides business logic for managing required credentials and credential types.

**Key Methods:**

- `getRequiredCredentials(Id vendorProgramId)` - Gets required credentials for a vendor program
- `getAvailableCredentialTypes()` - Gets all available credential types
- `createCredentialType(String name)` - Creates a new credential type
- `linkCredentialTypeToRequiredCredential(Id requiredCredentialId, Id credentialTypeId)` - Links a credential type to a required credential

**Usage:**
Used by `OnboardingAppECCController` for ECC management operations.

### Consolidated Domain Services

**Note:** The `VendorOnboardingWizardService` facade has been removed. The following consolidated domain services are now used directly:

#### VendorDomainService

**Location:** `force-app/main/default/classes/services/VendorDomainService.cls`

**Purpose:** Consolidated service for Vendor, VendorProgram, and VendorProgramGroup operations. Replaces VendorService, VendorProgramService, and VendorProgramGroupService.

**Key Methods:**

**Vendor Operations:**

- `searchVendors(String vendorName)` - Searches for vendors by name (delegates to repository)
- `createVendor(Vendor__c vendor)` - Creates a new vendor record. Sets `Active__c = false` to save as draft before inserting via repository

**Vendor Program Operations:**

- `searchVendorPrograms(String vendorProgramName)` - Searches for vendor programs by name
- `createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId)` - Creates a new vendor program. Sets `Vendor__c`, `Active__c = false`, and `Status__c = 'Draft'` before inserting
- `finalizeVendorProgram(Id vendorProgramId, Id vendorId, Id vendorProgramGroupId, Id vendorProgramRequirementGroupId)` - Links vendor program to vendor, program group, and requirement group. This is the final step in the vendor program setup wizard

**Vendor Program Group Operations:**

- `searchVendorProgramGroups(String vendorProgramGroupName)` - Searches for vendor program groups by name
- `createVendorProgramGroup(Vendor_Program_Group__c vendorProgramGroup)` - Creates a new vendor program group

**Vendor Program Requirement Group Operations:**

- `searchVendorProgramRequirementGroups(String requirementGroupName)` - Searches for requirement groups by name
- `createVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup)` - Creates a new requirement group

**Vendor Program Requirement Operations:**

- `searchVendorProgramRequirements(String vendorProgramRequirements)` - Searches for vendor program requirements by name
- `createVendorProgramRequirement(Vendor_Program_Requirement__c vendorProgramRequirement)` - Creates a new vendor program requirement

**Onboarding Status Rules Engine Operations:**

- `searchStatusRulesEngines(String onboardingStatusRulesEngine)` - Searches for status rules engines by name
- `createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine)` - Creates a new status rules engine

**Onboarding Status Rules Operations:**

- `createStatusRule(Onboarding_Status_Rule__c rule)` - Creates a new status rule
- `searchStatusRules(String nameSearchText)` - Searches for status rules by name

**Communication Templates Operations:**

- `getCommunicationTemplates()` - Retrieves all communication templates (ordered by Name, limit 100)
- `linkCommunicationTemplateToVendorProgram(Id vendorProgramId, Id templateId)` - Links a communication template to a vendor program

**Onboarding Requirement Set Operations:**

- `createOnboardingRequirementSet(Onboarding_Requirement_Set__c requirementSet)` - Creates a new requirement set. Sets `Status__c = 'Draft'` before inserting
- `getOnboardingRequirementSets()` - Retrieves all requirement sets (ordered by CreatedDate DESC, limit 100)

**Onboarding Requirement Templates Operations:**

- `createOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c template)` - Creates a new requirement template
- `getRequirementTemplatesForSet(Id requirementSetId)` - Gets all templates for a specific requirement set
- `assignTemplatesToRequirementGroup(Id requirementGroupId, List<Id> templateIds)` - Assigns multiple templates to a requirement group by updating the `Category_Group__c` field

**Recipient Groups Operations:**

- `searchRecipientGroups(String recipientGroupName)` - Searches for recipient groups by name
- `createRecipientGroup(Recipient_Group__c recipientGroup)` - Creates a new recipient group
- `createRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember)` - Creates a recipient group member

**Vendor Program Recipient Groups Operations:**

- `searchVendorProgramRecipientGroups(String vprgName)` - Searches for vendor program recipient groups by name
- `createVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId)` - Creates a link between vendor program and recipient group. Sets `Status__c = 'Draft'` on the link record

**Miscellaneous Operations:**

- `getTerritoryRoleAssignments()` - Gets all territory role assignments (ordered by Name)
- `getAssignableUsers()` - Gets all active users (ordered by Name)
- `getPublicGroups()` - Gets all public groups (ordered by Name)

**Usage:**
Used by `VendorOnboardingWizardController` and wizard LWC components for vendor onboarding setup workflows. All methods delegate to `VendorOnboardingWizardRepository` for data access operations.

### VendorOnboardingWizardController

**Location:** `force-app/main/default/classes/controllers/VendorOnboardingWizardController.cls`

**Purpose:** Controller for vendor onboarding wizard LWC components. Provides AuraEnabled methods for vendor, vendor program, groups, requirement sets, recipient groups, status rules, and communication templates operations. Coordinates multiple consolidated domain services.

**Key Methods:**

**Vendor Operations:**

- `searchVendors(String vendorNameSearchText)` - Searches vendors by name. Cacheable method that delegates to service layer
- `createVendor(Vendor__c vendor)` - Creates a vendor record. Delegates to service which sets vendor as draft before creating

**Vendor Program Operations:**

- `searchVendorPrograms(String vendorProgramNameSearchText)` - Searches vendor programs by name. Cacheable method
- `createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId)` - Creates a vendor program linked to a vendor. Delegates to service which sets status to 'Draft' and active to false
- `finalizeVendorProgram(Id vendorProgramId, Id vendorId, Id vendorProgramGroupId, Id vendorProgramRequirementGroupId)` - Finalizes vendor program setup by linking it to vendor, program group, and requirement group. This is called from the final step of the wizard

**Vendor Program Group Operations:**

- `searchVendorProgramGroups(String vendorProgramGroupNameSearchText)` - Searches vendor program groups by name. Cacheable method
- `createVendorProgramGroup(Vendor_Program_Group__c vendorProgramGroup)` - Creates a vendor program group. **Note:** Service layer now validates that `Label__c` and `Logic_Type__c` are provided (no auto-filling). Throws exception if missing.

**Vendor Program Requirement Group Operations:**

- `searchVendorProgramRequirementGroups(String requirementGroupNameSearchText)` - Searches requirement groups by name. Cacheable method
- `createVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup)` - Creates a requirement group

**Vendor Program Requirement Operations:**

- `searchVendorProgramRequirements(String vendorProgramRequirements)` - Searches vendor program requirements by name. Cacheable method
- `createVendorProgramRequirement(Vendor_Program_Requirement__c vendorProgramRequirement)` - Creates a vendor program requirement

**Onboarding Status Rules Engine Operations:**

- `searchStatusRulesEngines(String nameSearchText)` - Searches status rules engines by name. Cacheable method
- `createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine)` - Creates a status rules engine

**Onboarding Status Rules Operations:**

- `createStatusRule(Onboarding_Status_Rule__c rule)` - Creates a status rule
- `searchStatusRules(String nameSearchText)` - Searches status rules by name. Cacheable method

**Communication Templates Operations:**

- `getCommunicationTemplates()` - Gets all communication templates. Cacheable method
- `linkCommunicationTemplateToVendorProgram(Id vendorProgramId, Id templateId)` - Links a communication template to a vendor program

**Onboarding Requirement Set Operations:**

- `createOnboardingRequirementSet(Onboarding_Requirement_Set__c requirementSet)` - Creates a requirement set. Service sets status to 'Draft'
- `getOnboardingRequirementSets()` - Gets all requirement sets. Cacheable method

**Onboarding Requirement Templates Operations:**

- `createOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c template)` - Creates a requirement template
- `getRequirementTemplatesForSet(Id requirementSetId)` - Gets templates for a specific requirement set. Cacheable method
- `assignTemplatesToRequirementGroup(Id requirementGroupId, List<Id> templateIds)` - Assigns multiple templates to a requirement group

**Recipient Groups Operations:**

- `searchRecipientGroups(String recipientGroupNameSearchText)` - Searches recipient groups by name. Cacheable method
- `createRecipientGroup(Recipient_Group__c recipientGroup)` - Creates a recipient group
- `createRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember)` - Creates a recipient group member

**Vendor Program Recipient Groups Operations:**

- `searchVendorProgramRecipientGroups(String vprgNameSearchText)` - Searches vendor program recipient groups by name. Cacheable method
- `createVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId)` - Creates a link between vendor program and recipient group. Service sets status to 'Draft'

**Miscellaneous Operations:**

- `getTerritoryRoleAssignments()` - Gets all territory role assignments. Cacheable method
- `getAssignableUsers()` - Gets all active users. Cacheable method
- `getPublicGroups()` - Gets all public groups. Cacheable method

**Picklist Value Methods (New):**
These methods provide picklist values for form dropdowns in the wizard, ensuring users see the correct options from Salesforce. All are cacheable for performance.

- `getLogicTypePicklistValues()` - Returns picklist values for `Logic_Type__c` on `Vendor_Program_Group__c`. Returns list of maps with 'label' and 'value' keys
- `getStatusPicklistValues()` - Returns picklist values for `Status__c` on `Vendor_Program_Requirement_Group__c`
- `getGroupTypePicklistValues()` - Returns picklist values for `Group_Type__c` on `Recipient_Group__c`
- `getEvaluationLogicPicklistValues()` - Returns picklist values for `Evaluation_Logic__c` on `Onboarding_Status_Rules_Engine__c` (ALL, ANY, CUSTOM)
- `getRequiredStatusPicklistValues()` - Returns picklist values for `Required_Status__c` on `Onboarding_Status_Rules_Engine__c`
- `getTargetOnboardingStatusPicklistValues()` - Returns picklist values for `Target_Onboarding_Status__c` on `Onboarding_Status_Rules_Engine__c`
- `getPicklistValues(String objectName, String fieldName, List<String> fallbackValues)` - Private helper method that dynamically fetches picklist values from Salesforce schema. Includes fallback values if schema describe fails

**Validation Changes:**

- All create methods now use `ValidationHelper` for consistent input validation
- `createVendorProgramGroup()` - Validates that `Label__c` and `Logic_Type__c` are provided using `ValidationHelper.requireFieldForObject()`

**Usage:**
Used by vendor onboarding wizard LWC components for multi-step vendor setup workflows. All search methods are cacheable for better performance. All create/finalize methods are not cacheable as they perform DML operations. Picklist methods enable dynamic form dropdowns with proper Salesforce values.

### VendorOnboardingWizardRepository

**Location:** `force-app/main/default/classes/repository/VendorOnboardingWizardRepository.cls`

**Purpose:** Repository for vendor onboarding wizard data access operations. Handles all database queries and DML for vendor onboarding entities. This is the data access layer that performs all SOQL queries and DML operations.

**Key Methods:**

**Vendor Operations:**

- `searchVendors(String vendorName)` - Queries vendors by name using LIKE pattern (`'%' + vendorName + '%'`). Returns `Id` and `Name` fields, limit 10
- `insertVendor(Vendor__c vendor)` - Inserts a vendor record and returns the new record ID

**Vendor Program Operations:**

- `searchVendorPrograms(String vendorProgramName)` - Queries `Vendor_Customization__c` records by name using LIKE pattern. Returns `Id` and `Name` fields, limit 10
- `insertVendorProgram(Vendor_Customization__c vendorProgram)` - Inserts a vendor program record and returns the new record ID
- `linkVendorProgramToGroups(Id vendorProgramId, Id vendorId, Id vendorProgramGroupId, Id vendorProgramRequirementGroupId)` - Updates a vendor program record to link it to vendor, program group, and requirement group. Queries the vendor program first, then updates the lookup fields

**Vendor Program Group Operations:**

- `searchVendorProgramGroups(String vendorProgramGroupName)` - Queries `Vendor_Program_Group__c` records by name using LIKE pattern. Returns `Id` and `Name` fields, limit 10
- `insertVendorProgramGroup(Vendor_Program_Group__c vendorProgramGroup)` - Inserts a vendor program group record and returns the new record ID

**Vendor Program Requirement Group Operations:**

- `searchVendorProgramRequirementGroups(String requirementGroupName)` - Queries `Vendor_Program_Requirement_Group__c` records by name using LIKE pattern. Returns `Id` and `Name` fields, limit 10
- `insertVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup)` - Inserts a requirement group record and returns the new record ID

**Vendor Program Requirement Operations:**

- `searchVendorProgramRequirements(String vendorProgramRequirements)` - Queries `Vendor_Program_Requirement__c` records by name using LIKE pattern. Returns `Id`, `Name`, `Vendor_Program__c` (lookup to `Vendor_Customization__c`), `Inherited_From_Group__c`, `Requirement_Group_Member__c`, and `Requirement_Template__c` fields, limit 10
- `insertVendorProgramRequirement(Vendor_Program_Requirement__c vendorProgramRequirement)` - Inserts a vendor program requirement record and returns the new record ID

**Onboarding Status Rules Engine Operations:**

- `searchStatusRulesEngines(String nameSearchText)` - Queries `Onboarding_Status_Rules_Engine__c` records by name using LIKE pattern. Returns `Id`, `Name`, `Requirement_Group__c`, and `Vendor_Program_Group__c` fields, limit 10
- `insertOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine)` - Inserts a status rules engine record and returns the new record ID

**Onboarding Status Rules Operations:**

- `insertStatusRule(Onboarding_Status_Rule__c rule)` - Inserts a status rule record and returns the new record ID
- `searchStatusRules(String nameSearchText)` - Queries `Onboarding_Status_Rule__c` records by name using LIKE pattern. Returns `Id`, `Name`, `Parent_Rule__c`, and `Requirement__c` fields, limit 10

**Communication Templates Operations:**

- `fetchCommunicationTemplates()` - Queries all `Communication_Template__c` records. Returns `Id` and `Name` fields, ordered by Name, limit 100
- `linkCommunicationTemplate(Id vendorProgramId, Id templateId)` - Updates a communication template to link it to a vendor program. Queries the template first, then updates the `Vendor_Program__c` field (lookup to `Vendor_Customization__c`)

**Onboarding Requirement Set Operations:**

- `insertOnboardingRequirementSet(Onboarding_Requirement_Set__c requirementSet)` - Inserts a requirement set record and returns the new record ID
- `fetchOnboardingRequirementSets()` - Queries all `Onboarding_Requirement_Set__c` records. Returns `Id`, `Name`, and `Status__c` fields, ordered by CreatedDate DESC, limit 100

**Onboarding Requirement Templates Operations:**

- `insertOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c template)` - Inserts a requirement template record and returns the new record ID
- `fetchOnboardingRequirementTemplates(Id requirementSetId)` - Queries `Vendor_Program_Onboarding_Req_Template__c` records filtered by `Onboarding_Requirement_Set__c`. Returns `Id`, `Name`, and `Requirement_Type__c` fields
- `assignRequirementTemplatesToRequirementGroup(Id requirementGroupId, List<Id> templateIds)` - Updates multiple requirement templates to assign them to a requirement group. Queries templates by IDs, then updates the `Category_Group__c` field on each template

**Recipient Groups Operations:**

- `searchRecipientGroups(String recipientGroupName)` - Queries `Recipient_Group__c` records by name using LIKE pattern. Returns `Id` and `Name` fields, limit 10
- `insertRecipientGroup(Recipient_Group__c recipientGroup)` - Inserts a recipient group record and returns the new record ID
- `insertRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember)` - Inserts a recipient group member record and returns the new record ID

**Vendor Program Recipient Groups Operations:**

- `searchVendorProgramRecipientGroups(String vprgName)` - Queries `Vendor_Program_Recipient_Group__c` records by name using LIKE pattern. Returns `Id` and `Name` fields, limit 10
- `insertVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId)` - Creates and inserts a new `Vendor_Program_Recipient_Group__c` record linking a vendor program to a recipient group. Sets `Vendor_Program__c` (lookup to `Vendor_Customization__c`), `Recipient_Group__c`, and `Status__c = 'Draft'` on the new record

**Miscellaneous Operations:**

- `getTerritoryRoleAssignments()` - Queries all `Territory_Role_Assignment__c` records. Returns `Id`, `Name`, and `Role__c` fields, ordered by Name
- `getAssignableUsers()` - Queries all active `User` records (`IsActive = true`). Returns `Id` and `Name` fields, ordered by Name
- `getPublicGroups()` - Queries all `Group` records. Returns `Id` and `Name` fields, ordered by Name

**Usage:**
Used by `VendorOnboardingWizardService` for all data access operations. All methods use `with sharing` to enforce sharing rules.

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

**Location:** `force-app/main/default/classes/rules/OnboardingAppRuleRegistry.cls`

**Purpose:** Central registry of validation rules and activation rules for onboarding application objects.

**Key Methods:**

- `getValidationRules()` - Returns map of object API names to validation rule lists (for trigger-based validation)
- `getActivationRulesForObject(String objectApiName)` - Returns list of activation rules for a specific object (for activation-time validation)

**Validation Rules (Trigger-Based):**

- `Vendor_Program_Recipient_Group__c`:
  - `RequireParentVersionOnActivationRule` - Non-draft versions must have parent
  - `OnlyOneActiveRecGrpPerPrgrmRule` - Only one active version per parent
  - `RecipientAndProgramMustBeActiveRule` - Related records must be active
  - `PreventDupRecGrpAssignmentRule` - No duplicate assignments

**Activation Rules (Activation-Time):**

- `Vendor_Customization__c` (Vendor Program):
  - `AllRequirementGroupsMustBeActiveRule` - Requirement group must be active
- Legacy registry key `Vendor_Program__c`:
  - `AllChildRequirementsMustBeActiveRule` - All child requirements must be active
  - `AllTemplatesInReqSetMustBeActiveRule` - All requirement templates must be active
- `Onboarding_Status_Rule__c`:
  - `AllLinkedEngineMustBeActiveRule` - Parent rules engine must be active
- `Onboarding_Status_Rules_Engine__c`:
  - `AllStatusRulesMustBeActiveRule` - All child status rules must be active
  - `AllStatusRuleGroupMustBeActiveRule` - Related groups must be active

### OnboardingAppValidationRule

**Location:** `force-app/main/default/classes/OnboardingAppValidationRule.cls`

**Purpose:** Interface for validation rules that run on record save (via triggers).

**Key Methods:**

- `validate(List<SObject> newList, Map<Id, SObject> oldMap)` - Validates records before save

### OnboardingAppActivationRule

**Location:** `force-app/main/default/classes/rules/OnboardingAppActivationRule.cls`

**Purpose:** Interface for activation rules that run during activation (not on save).

**Key Methods:**

- `apply(Id recordId, String objectApiName)` - Executes activation rule logic, throws `AuraHandledException` if activation should be blocked

**Note:** Activation rules are separate from validation rules. They are executed by activation services before setting records to active status.

### Validation Rule Implementations (Trigger-Based)

- **RequireParentVersionOnActivationRule** - Requires parent version on activation
- **OnlyOneActiveRecGrpPerPrgrmRule** - Ensures only one active recipient group per program
- **RecipientAndProgramMustBeActiveRule** - Validates recipient and program are active
- **PreventDupRecGrpAssignmentRule** - Prevents duplicate recipient group assignments

### Activation Rule Implementations (Activation-Time)

- **AllChildRequirementsMustBeActiveRule** - Ensures all child requirements are active before activating vendor program
- **AllTemplatesInReqSetMustBeActiveRule** - Ensures all requirement templates are active
- **AllRequirementGroupsMustBeActiveRule** - Ensures requirement group is active before activating vendor customization
- **AllLinkedEngineMustBeActiveRule** - Ensures parent rules engine and requirement are active
- **AllStatusRulesMustBeActiveRule** - Ensures all child status rules are active before activating rules engine
- **AllStatusRuleGroupMustBeActiveRule** - Ensures related groups are active before activating rules engine
- **AllRequirementSetMustBeActiveRule** - Ensures requirement set is active (not currently registered)
- **AllTemplatesInGroupMustBeActiveRule** - Ensures all templates in group are active (not currently registered)

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

Repository classes follow the pattern `*Repo.cls` or `*Repository.cls` and handle data access operations:

- `OnboardingAppVendorProgramReqRepo` - Vendor program requirement data access
- `FollowUpRuleRepository` - Follow-up fatigue metadata and queue access
- `OnboardingMetricsRepository` - Admin dashboard metrics

### FollowUpRuleRepository

**Location:** `force-app/main/default/classes/repository/FollowUpRuleRepository.cls`

**Purpose:** Centralizes data access for fatigue suppression logic.

**Key Methods:**

- `getRuleByDeveloperName(developerName)` - Retrieves fatigue rule metadata.
- `getActiveSuppressions()` - Returns active suppression windows.
- `getRecentFollowUps(onboardingRequirementId, thresholdDateTime)` - Gets recent queue activity for fatigue checks.
- `getFollowUpQueue` / `getFollowUpQueueForTracking` - Loads queue records for suppression/attempt tracking flows.

### OnboardingMetricsRepository

**Location:** `force-app/main/default/classes/repository/OnboardingMetricsRepository.cls`

**Purpose:** Encapsulates dashboard metric queries and validation failure retrieval.

**Key Methods:**

- `getValidationFailureCount`, `getMessageFailureCount`, `getWebhookFailureCount`, `getPlatformEventVolume`, `getActiveFollowUpQueueCount`, `getOverrideOperationCount`
- `getValidationFailures(startDate, filters)` - Returns validation failures with optional type filtering.

### OnboardingRepository

**Location:** `force-app/main/default/classes/repository/OnboardingRepository.cls`

**Purpose:** Repository layer for Onboarding\_\_c data access operations. Centralizes all SOQL queries for onboarding records.

**Key Methods:**

- `getActiveOnboardingWithFilters(ownerUserIds, startDate, vendorIds, programIds, limitCount)` - Returns active onboarding with filters
  - Uses pre-resolved Account IDs from `OnboardingAccessService` to avoid nested subqueries
  - Supports time, vendor, program, and ownership filters
  - Returns `List<Onboarding__c>`

- `getOnboardingSummaryWithFilters(ownerUserIds, startDate, vendorIds, programIds)` - Returns status counts with filters
  - Aggregate query grouped by Onboarding_Status\_\_c
  - Returns `Map<String, Integer>` with status counts

- `getRecentOnboardingWithFilters(ownerUserIds, startDate, vendorIds, programIds, limitCount)` - Returns recent onboarding with filters
  - Uses LastModifiedDate for time filtering
  - Returns `List<Onboarding__c>`

- `getActiveOnboardingByCreatedBy(userId, limitCount)` - Legacy method for backward compatibility
- `getAllActiveOnboarding(limitCount)` - Returns all active onboarding (no ownership filter)
- `getRecentOnboardingByCreatedBy(userId, limitCount)` - Legacy method for backward compatibility
- `getOnboardingSummaryByCreatedBy(userId)` - Legacy method for backward compatibility
- `fetchOnboardingById(onboardingId)` - Fetches single onboarding record
- `fetchOnboardingsByIds(onboardingIds)` - Bulk fetch by IDs
- `updateOnboardings(onboardings)` - Updates onboarding records

**Design Decisions:**

- **Pre-resolved Account IDs:** Methods accept `Set<Id> accountIds` instead of building subqueries to avoid SOQL limitations
- **Filter Support:** All new methods support comprehensive filtering (time, vendor, program, ownership)
- **Early Returns:** Returns empty results when ownership filter is applied but no accounts match (avoids invalid SOQL)

**Dependencies:**

- `OnboardingAccessService` - For ownership resolution (called by controller, not repository)

**Usage:**
Used by `OnboardingHomeDashboardController` for all onboarding data access. Repository methods are called with pre-resolved Account IDs to avoid nested subquery issues.

### OnboardingAppECCRepository

**Location:** `force-app/main/default/classes/OnboardingAppECCRepository.cls`

**Purpose:** Repository for External Contact Credential (ECC) data access operations. Handles database queries and DML for required credentials and credential types.

**Key Methods:**

- `fetchRequiredCredentials(Id vendorProgramId)` - Queries required credentials for a vendor program with credential type relationship
- `fetchCredentialTypes()` - Queries all credential types (ordered by Name ASC)
- `insertCredentialType(String name)` - Inserts a new credential type record
- `updateRequiredCredential(Id requiredCredentialId, Id credentialTypeId)` - Updates a required credential with credential type link

**Usage:**
Used by `OnboardingAppECCService` for all ECC data access operations.

### RequirementFieldValueRepository

**Location:** `force-app/main/default/classes/repository/RequirementFieldValueRepository.cls`

**Purpose:** Repository for Requirement_Field_Value\_\_c data access operations. Centralizes all SOQL queries for requirement field values following the repository pattern.

**Key Methods:**

- `getFieldValuesByIds(Set<Id> fieldValueIds)` - Gets field values by IDs with related field information
  - Includes Requirement_Field**r relationship with Field_API_Name**c, Required**c, Validation_Type**c
  - Includes Onboarding_Requirement\_\_r relationship
  - Returns `List<Requirement_Field_Value__c>`

- `getFieldValuesByRequirement(Id requirementId)` - Gets field values for an onboarding requirement
  - Ordered by Requirement_Field_Group sequence and field sequence
  - Returns `List<Requirement_Field_Value__c>`

- `getInvalidFieldValuesByOnboarding(Id onboardingId)` - Gets invalid field values for an onboarding
  - Filters by Validation_Status\_\_c IN ('Invalid', 'Needs Correction')
  - Includes requirement and field names for display
  - Returns `List<Requirement_Field_Value__c>`

- `getFieldValuesForCrossFieldValidation(Id requirementId, Set<String> fieldApiNames)` - Gets field values for cross-field validation
  - Gets all field values for the same onboarding requirement (siblings)
  - Filters by field API names
  - Returns `List<Requirement_Field_Value__c>`

**Query Patterns:**

- Includes related object fields via relationship queries
- Orders by sequence for consistent display
- Filters by validation status for invalid field retrieval

**Usage:**
Used by `RequirementFieldValidationService` and `RequirementFieldValueController` for field value data access.

### OnboardingRulesRepository

**Location:** `force-app/main/default/classes/repository/OnboardingRulesRepository.cls`

**Purpose:** Repository for Onboarding_Status_Rule**c and Onboarding**c data access operations. Centralizes queries for status rules and onboarding records with requirements.

**Key Methods:**

- `fetchRulesEngineRecords(Id engineId)` - Fetches status rules for a rules engine
  - Returns `List<Onboarding_Status_Rule__c>` ordered by Rule_Number\_\_c
  - Includes Requirement**r relationship with Name and Requirement_Template**r

- `upsertRule(Onboarding_Status_Rule__c statusRuleRecord)` - Upserts a status rule record
  - Returns the upserted record

- `deleteRule(Id ruleId)` - Deletes a single rule by ID
- `deleteRules(List<Id> ruleIds)` - Bulk deletes rules by IDs

- `fetchOnboardingWithRequirements(Id onboardingId)` - Fetches onboarding with related requirements
  - Includes Onboarding_Requirements\_\_r subquery with requirement details
  - Includes Vendor_Program_Requirement\_\_r relationship
  - Returns `Onboarding__c` record

- `fetchOnboardingsByIdsWithFields(Set<Id> onboardingIds, Set<String> fieldApiNames)` - Bulk fetches onboardings with specific fields
  - Dynamically queries fields from fieldApiNames set
  - Used for preview evaluation with mapped fields
  - Returns `List<Onboarding__c>`

**Query Patterns:**

- Uses subqueries for related records
- Includes relationship fields for display
- Orders by sequence fields for consistent results
- Supports dynamic field queries for flexible data access

**Usage:**
Used by `OnboardingRulesService` and `OnboardingStatusRulesEngineController` for rules and onboarding data access.

### VendorCustomizationRepository

**Location:** `force-app/main/default/classes/repository/VendorCustomizationRepository.cls`

**Purpose:** Repository for Vendor_Customization\_\_c data access operations. Handles queries for vendor program records.

**Key Methods:**

- `getById(Id recordId)` - Fetches a vendor program record by ID with standard fields
  - Returns Status**c, Active**c, Previous_Version\_\_c
  - Returns `Vendor_Customization__c` or null

- `getByIds(Set<Id> recordIds)` - Bulk fetches vendor programs by IDs
  - Returns `List<Vendor_Customization__c>`

- `getActiveVendorPrograms(List<Id> vendorIds, List<Id> programIds)` - Fetches active vendor programs for eligibility checks
  - Filters by Active\_\_c = true
  - Supports optional vendor and program filters
  - Returns `List<Vendor_Customization__c>`

- `updateRecord(Vendor_Customization__c record)` - Updates a vendor program record

**Query Patterns:**

- Filters by Active\_\_c for active program queries
- Supports optional ID filters for flexible querying
- Returns null-safe results

**Usage:**
Used by `VendorProgramActivationService`, `OnboardingEligibilityService`, and other services for vendor program data access.

### OnboardingApplicationRepository

**Location:** `force-app/main/default/classes/repository/OnboardingApplicationRepository.cls`

**Purpose:** Repository for Onboarding_Application_Process**c, Onboarding_Application_Stage**c, and Onboarding_Application_Progress\_\_c data access operations.

**Key Methods:**

- `fetchStagesForProcess(Id processId)` - Fetches stages for an onboarding process
  - Returns `List<Onboarding_Application_Stage__c>` ordered by Display_Order\_\_c
  - Includes Component_Library relationship with Component_API_Name\_\_c
  - Includes Label**c, Next_Stage**c, Required\_\_c fields

- `fetchProcessDetails(Id processId)` - Fetches process details
  - Returns `Onboarding_Application_Process__c` with Id, Name, Description\_\_c

- `fetchProgress(Id vendorProgramId, Id processId)` - Fetches progress for a vendor program and process
  - Returns `Onboarding_Application_Progress__c` with Current_Stage\_\_c

- `fetchProgressByVendorProgram(Id vendorProgramId)` - Fetches progress by vendor program only
  - Returns `Onboarding_Application_Progress__c`

- `upsertProgress(Onboarding_Application_Progress__c progress)` - Upserts progress record

**Query Patterns:**

- Orders by Display_Order\_\_c for consistent stage ordering
- Includes relationship fields for component library access
- Returns null-safe results

**Usage:**
Used by `OnboardingApplicationService` for process, stage, and progress data access.

## DTOs (Data Transfer Objects)

DTO classes in `dto/` package provide structured data transfer:

- Various DTO classes for data transfer between layers

## Domain-Specific Services

The Vendor Onboarding Wizard service layer has been consolidated into domain-specific services. Related services have been merged to reduce complexity.

### VendorDomainService

**Location:** `force-app/main/default/classes/services/VendorDomainService.cls`

**Purpose:** Consolidated service for Vendor, VendorProgram, and VendorProgramGroup operations. Replaces VendorService, VendorProgramService, and VendorProgramGroupService.

**Key Methods:**

**Vendor Operations:**

- `searchVendors(String vendorName)` - @AuraEnabled, searches vendors by name
- `createVendor(Vendor__c vendor)` - @AuraEnabled, creates vendor with validation and default values
- `getVendorsWithPrograms()` - @AuraEnabled, gets all vendors with associated programs
- `searchVendorsWithPrograms(String searchText)` - @AuraEnabled, searches vendors with programs

**Vendor Program Operations:**

- `searchVendorPrograms(String vendorProgramName)` - @AuraEnabled, searches vendor programs
- `getRecentVendorPrograms(Integer limitCount)` - @AuraEnabled, gets recent vendor programs
- `createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId)` - @AuraEnabled, creates vendor program
- `finalizeVendorProgram(...)` - @AuraEnabled, finalizes vendor program setup

**Vendor Program Group Operations:**

- `searchVendorProgramGroups(String vendorProgramGroupName)` - @AuraEnabled, searches program groups
- `getAllVendorProgramGroups()` - @AuraEnabled, gets all program groups
- `createVendorProgramGroup(Vendor_Program_Group__c vendorProgramGroup)` - @AuraEnabled, creates program group

**Dependencies:**

- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation
- `DefaultValueHelper` - Default value assignment

### RequirementDomainService

**Location:** `force-app/main/default/classes/services/RequirementDomainService.cls`

**Purpose:** Consolidated service for VendorProgramRequirement and VendorProgramRequirementGroup operations. Replaces VendorProgramRequirementService and VendorProgramRequirementGroupService.

**Key Methods:**

**Vendor Program Requirement Operations:**

- `searchVendorProgramRequirements(String requirementName)` - @AuraEnabled, searches requirements
- `createVendorProgramRequirement(Vendor_Program_Requirement__c requirement)` - @AuraEnabled, creates requirement
- `bulkCreateRequirementsFromTemplates(List<Id> templateIds, Id vendorProgramId)` - @AuraEnabled, bulk creates requirements from templates
- `updateRequirementSequences(List<Vendor_Program_Requirement__c> requirements)` - @AuraEnabled, updates requirement sequences
- `getRecentVendorProgramRequirements(Id vendorProgramId)` - @AuraEnabled, gets recent requirements
- `getRequirementsByGroup(Id requirementGroupId)` - @AuraEnabled, gets requirements by group
- `deleteVendorProgramRequirement(Id requirementId)` - @AuraEnabled, deletes requirement

**Vendor Program Requirement Group Operations:**

- `searchVendorProgramRequirementGroups(String requirementGroupName)` - @AuraEnabled, searches requirement groups
- `getAllVendorProgramRequirementGroups()` - @AuraEnabled, gets all requirement groups
- `createVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup)` - @AuraEnabled, creates requirement group

**Dependencies:**

- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation
- `DefaultValueHelper` - Default value assignment

### OnboardingRequirementSetService

**Location:** `force-app/main/default/classes/services/OnboardingRequirementSetService.cls`

**Purpose:** Service for Onboarding Requirement Set and Template domain operations.

**Key Methods:**

- `createOnboardingRequirementSet(Onboarding_Requirement_Set__c requirementSet)` - Creates requirement set
- `getOnboardingRequirementSets()` - Gets all requirement sets
- `searchOnboardingRequirementSets(String searchText, Id vendorProgramId)` - Searches requirement sets
- `getRequirementSetsWithTemplates()` - Gets requirement sets with templates
- `searchRequirementSetsWithTemplates(String searchText)` - Searches requirement sets with templates
- `linkRequirementSetToVendorProgram(Id requirementSetId, Id vendorProgramId)` - Links requirement set to vendor program
- `createRequirementSetFromExisting(Id existingRequirementSetId, Id vendorProgramId, String vendorProgramLabel)` - Creates requirement set from existing
- `getTemplatesForRequirementSet(Id requirementSetId)` - Gets templates for requirement set
- `createRequirementFromTemplate(Id templateId, Id vendorProgramId)` - Creates requirement from template
- `getHistoricalGroupMembers(Id requirementSetId)` - Gets historical group members
- `getHistoricalStatusRulesEngines(Id requirementSetId)` - Gets historical status rules engines
- `createRequirementGroupComponents(Id vendorProgramId, Id requirementSetId, Boolean useHistorical)` - Creates requirement group components
- `createOnboardingRequirementTemplate(Vendor_Program_Onboarding_Req_Template__c template)` - Creates requirement template
- `getRequirementTemplatesForSet(Id requirementSetId)` - Gets templates for requirement set
- `updateRequirementTemplateGroupLinks(Id requirementGroupId, List<Id> templateIds)` - Updates template group links
- `getRequirementSetById(Id requirementSetId)` - Gets requirement set by ID
- `getOnboardingContext(Id vendorProgramId)` - Gets onboarding context
- `assignTemplatesToRequirementGroup(Id requirementGroupId, List<Id> templateIds)` - Assigns templates to requirement group

**Dependencies:**

- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation
- `DefaultValueHelper` - Default value assignment

### RecipientGroupService

**Location:** `force-app/main/default/classes/services/RecipientGroupService.cls`

**Purpose:** Service for Recipient Group domain operations.

**Key Methods:**

- `searchRecipientGroups(String recipientGroupName)` - Searches recipient groups
- `createRecipientGroup(Recipient_Group__c recipientGroup)` - Creates recipient group
- `createRecipientGroupMember(Recipient_Group_Member__c member)` - Creates recipient group member
- `searchVendorProgramRecipientGroups(String vprgName)` - Searches vendor program recipient groups
- `createVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId)` - Creates vendor program recipient group link
- `getRecipientGroupsForVendorProgram(Id vendorProgramId)` - Gets recipient groups for vendor program
- `getRecipientGroupMembers(Id recipientGroupId)` - Gets recipient group members
- `createVendorProgramRecipientGroupWithTemplate(Id vendorProgramId, Id recipientGroupId, Id communicationTemplateId, String triggerCondition)` - Creates recipient group with template

**Dependencies:**

- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation
- `DefaultValueHelper` - Default value assignment

### StatusRulesEngineService

**Location:** `force-app/main/default/classes/services/StatusRulesEngineService.cls`

**Purpose:** Service for Status Rules Engine and Status Rule domain operations.

**Key Methods:**

- `searchStatusRulesEngines(String nameSearchText)` - Searches status rules engines
- `createOnboardingStatusRulesEngine(Onboarding_Status_Rules_Engine__c rulesEngine)` - Creates status rules engine
- `createStatusRule(Onboarding_Status_Rule__c rule)` - Creates status rule
- `searchStatusRules(String nameSearchText)` - Searches status rules

**Dependencies:**

- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation
- `DefaultValueHelper` - Default value assignment

### CommunicationTemplateService

**Location:** `force-app/main/default/classes/services/CommunicationTemplateService.cls`

**Purpose:** Service for Communication Template domain operations.

**Key Methods:**

- `getCommunicationTemplates()` - Gets all communication templates
- `linkCommunicationTemplateToVendorProgram(Id vendorProgramId, Id templateId)` - Links template to vendor program

**Dependencies:**

- `VendorOnboardingWizardRepository` - Data access
- `ValidationHelper` - Input validation

## Utilities

### ValidationHelper

**Location:** `force-app/main/default/classes/util/ValidationHelper.cls`

**Purpose:** Centralized validation utility class. Provides static methods for input validation across services and orchestrators.

**Key Methods:**

- `requireNotNull(Object value, String fieldName)` - Validates value is not null
- `requireNotBlank(String value, String fieldName)` - Validates string is not blank
- `requireNotEmpty(List<Object> value, String fieldName)` - Validates list is not empty
- `requireId(Id recordId, String fieldName)` - Validates ID is not null
- `requireRecord(SObject record, String recordName)` - Validates record is not null
- `requireField(Object value, String fieldName)` - Validates field value is not null/blank
- `requireFieldForObject(Object value, String objectName, String fieldName)` - Validates field with object context

**Usage:** Used by all service classes and orchestrators for consistent input validation.

### DefaultValueHelper

**Location:** `force-app/main/default/classes/util/DefaultValueHelper.cls`

**Purpose:** Centralized default value assignment utility class. Provides static methods to apply default values to various SObject records.

**Key Methods:**

- `applyRequirementGroupDefaults(Vendor_Program_Requirement_Group__c group)` - Applies defaults to requirement groups
- `applyVendorProgramDefaults(Vendor_Customization__c vendorProgram)` - Applies defaults to vendor programs
- `applyVendorDefaults(Vendor__c vendor)` - Applies defaults to vendors
- `applyRecipientGroupDefaults(Recipient_Group__c recipientGroup)` - Applies defaults to recipient groups
- `applyStatusRulesEngineDefaults(Onboarding_Status_Rules_Engine__c rulesEngine)` - Applies defaults to status rules engines
- `applyTrainingSystemDefaults(Training_System__c trainingSystem)` - Applies defaults to training systems
- `applyRequirementSetDefaults(Onboarding_Requirement_Set__c requirementSet)` - Applies defaults to requirement sets

**Usage:** Used by service classes to ensure consistent default values across the system.

### PicklistHelper

**Location:** `force-app/main/default/classes/util/PicklistHelper.cls`

**Purpose:** Utility class for retrieving picklist values. Eliminates code duplication and provides consistent picklist handling.

**Key Methods:**

- `getPicklistValues(String objectApiName, String fieldApiName)` - Gets picklist values using schema describe
- `getPicklistValuesWithFallback(String objectApiName, String fieldApiName, List<String> fallbackValues)` - Gets picklist values with fallback
- `getPicklistValuesByField(Schema.SObjectField fieldToken, List<String> fallbackValues)` - Gets picklist values using direct field token (faster)

**Usage:** Used by `VendorOnboardingWizardController` for all picklist value retrieval methods.

### StageCompletionConfig

**Location:** `force-app/main/default/classes/util/StageCompletionConfig.cls`

**Purpose:** Configuration for stage completion logic. Centralizes component name checks to follow Open/Closed Principle.

**Key Methods:**

- `isVendorSelectionComponent(String componentApiName)` - Checks if component represents vendor selection stage
- `getVendorSelectionComponents()` - Gets all vendor selection component names

**Usage:** Used by `OnboardingApplicationService` to determine which stages should be auto-completed.

### FLSCheckUtil

**Location:** `force-app/main/default/classes/util/FLSCheckUtil.cls`

**Purpose:** Bulk-safe field-level security checks (`isReadable`, `isUpdateable`, `isCreateable`).

### CustomMetadataUtil

**Location:** `force-app/main/default/classes/util/CustomMetadataUtil.cls`

**Purpose:** Cached custom metadata lookup by DeveloperName with `clearCache` helper.

### LoggingUtil

**Location:** `force-app/main/default/classes/util/LoggingUtil.cls`

**Purpose:** Centralized logging helpers with consistent `[Onboarding]` prefix.

### OnboardingTestDataFactory

**Location:** `force-app/main/default/classes/util/OnboardingTestDataFactory.cls`

**Purpose:** Opinionated factory for onboarding test contexts (account, vendor, program, onboarding, requirement, requirement field).

### VendorProgramStatusMapper

**Location:** `force-app/main/default/classes/util/VendorProgramStatusMapper.cls`

**Purpose:** Maps Vendor Program technical statuses to user-friendly stages for display in the front end.

**⚠️ IMPORTANT**: This mapper is ONLY for `Vendor_Customization__c.Status__c` (Vendor Onboarding).
It does NOT apply to `Onboarding__c.Onboarding_Status__c` (Dealer Onboarding), which should be displayed as-is without simplification.

**Key Methods:**

- `getUserFacingStage(String technicalStatus, Boolean isAdmin)` - Maps technical status to user-friendly stage
- `getUserFacingStageForCurrentUser(String technicalStatus)` - Gets user-facing stage for current user (checks admin status automatically)
- `getStatusVariant(String userFacingStage)` - Gets CSS variant for status badge (brand, warning, success)
- `getStatusIcon(String userFacingStage)` - Gets Lightning icon name for status
- `isCurrentUserAdmin()` - Checks if current user is an admin

**Status Mapping:**

- **Draft/In Process** → "In Progress" 🟡
- **Pending Review/Pending Approval** → "Review Pending" 🟠
- **Complete/Approved** → "Completed" 🟢

**Admin Behavior:**

- Admin users see technical statuses unchanged
- End users see simplified stages

**Usage:**
Used by `OnboardingApplicationService.getUserFacingStage()` for Vendor Program status display in LWC components.

**Note:** Dealer Onboarding statuses (`Onboarding__c.Onboarding_Status__c`) are passed through `OnboardingDTO` and displayed as-is without any simplification.

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
├── strategies/ # Strategy pattern implementations
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

## Stage Dependency Classes

### OnboardingStageDependencyRepository

**Location:** `force-app/main/default/classes/repository/OnboardingStageDependencyRepository.cls`

**Purpose:** Repository layer for Onboarding Stage Dependency queries and data access.

**Key Methods:**

- `getDependenciesForTargetStage(Id targetStageId)` - Gets all dependency rules for a target stage with their members
- `getDependenciesForTargetStages(Set<Id> targetStageIds)` - Bulk query for multiple target stages
- `getCompletedStageIds(Id vendorProgramId, Id processId)` - Gets set of completed stage IDs for a vendor program
- `getDependencyById(Id dependencyId)` - Gets a dependency rule by ID with its members

**Dependencies:**

- `Onboarding_Application_Stage_Dependency__c` - Dependency rule object
- `Onboarding_App_Stage_Dependency_Member__c` - Dependency member object
- `Onboarding_Application_Stage_Completion__c` - Stage completion tracking

**Usage:** Used by `OnboardingStageDependencyService` for dependency queries.

### OnboardingStageDependencyService

**Location:** `force-app/main/default/classes/services/OnboardingStageDependencyService.cls`

**Purpose:** Service layer for Onboarding Stage Dependency validation. Checks if stages can be started based on dependency rules.

**Key Methods:**

- `canStartStage(Id targetStageId, Id vendorProgramId, Id processId)` - Validates if a stage can be started, returns `StageDependencyValidationDTO`
- `getDependencyInfo(Id targetStageId, Id vendorProgramId, Id processId)` - Gets dependency information for display purposes
- `evaluateDependency(String logicType, List<Id> requiredStageIds, Set<Id> completedStageIds)` - Private method that evaluates dependencies based on logic type (ALL, ANY, CUSTOM)

**DTOs:**

- `StageDependencyValidationDTO` - Contains `canStart` flag and list of blocking dependencies
- `DependencyInfo` - Contains dependency details including required, completed, and missing stage IDs

**Logic Types Supported:**

- `ALL` - All required stages must be completed
- `ANY` - At least one required stage must be completed
- `CUSTOM` - Custom logic (defaults to ALL for safety, not yet fully implemented)

**Dependencies:**

- `OnboardingStageDependencyRepository` - For dependency queries
- `Onboarding_Application_Stage_Dependency__c` - Dependency rule object
- `Onboarding_App_Stage_Dependency_Member__c` - Dependency member object

**Usage:** Used by `OnboardingApplicationService.saveProgress()` to validate dependencies before allowing stage progression.

### OnboardingApplicationService Updates

**New Methods:**

- `canStartStage(Id targetStageId, Id vendorProgramId, Id processId)` - Exposes dependency validation to LWC components
- `getStageDependencies(Id targetStageId, Id vendorProgramId, Id processId)` - Gets dependency information for display

**Updated Methods:**

- `saveProgress()` - Now validates dependencies before saving progress. Throws `AuraHandledException` if dependencies are not met.

**Integration:** The `onboardingFlowEngine` LWC component calls `canStartStage()` before allowing navigation to the next stage.

## Related Documentation

- [LWC Components](./lwc-components.md)
- [API Reference](../api/apex-api.md)
- [Architecture Overview](../architecture/overview.md)
- [Apex Patterns](../architecture/apex-patterns.md) - Architectural patterns and conventions
- [Pattern Violations](../reports/architecture/pattern-violations.md) - Identified violations and fixes (historical report)
- [Stage Dependency Management](../processes/stage-dependency-management.md) - **NEW** - Complete guide to stage dependencies
