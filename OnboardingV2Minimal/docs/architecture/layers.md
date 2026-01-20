# Layered Architecture

## Overview

The onboarding system follows a three-layer architecture pattern that separates concerns and promotes maintainability:

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

### Service Layer

**Purpose**: Contains consolidated domain services with business rules, validation, and LWC/Flow integration.

**Components:**

- Apex Domain Services (\*DomainService.cls) - Consolidated services by domain
- Apex Business Logic Services (\*Service.cls) - Core business logic
- Apex Controllers (\*Ctlr.cls) - Only complex controllers
- Apex Handlers (\*Hdlr.cls)
- Salesforce Flows (BLL\_\*)

**Responsibilities:**

- Business rule enforcement
- Validation logic
- LWC integration (via @AuraEnabled methods)
- Flow integration (via @InvocableMethod annotations)
- Status evaluation
- Rules engine execution

**Key Consolidated Domain Services:**

- `VendorDomainService` - Vendor, VendorProgram, VendorProgramGroup operations
- `RequirementDomainService` - VendorProgramRequirement, VendorProgramRequirementGroup operations
- `CommunicationDomainService` - CommunicationTemplate, RecipientGroup operations
- `VendorOnboardingService` - Vendor eligibility and onboarding logic (with LWC/Flow adapters)
- `EmailSyncDomainService` - Email template and org-wide email synchronization

**Key Business Logic Services:**

- `OnboardingApplicationService` - Process management
- `OnboardingRulesService` - Rules data access
- `OnboardingStatusEvaluator` - Status evaluation
- `OnboardingRuleEvaluator` - Rule evaluation
- `OnboardingAppActivationService` - Activation workflow (with @AuraEnabled)
- `OnboardingAccessService` - Ownership and view filter resolution
- `OnboardingDashboardFilterService` - Dashboard filter logic
- `OnboardingBlockingDetectionService` - Blocking and at-risk detection
- `OnboardingRequirementSetService` - Requirement Set operations
- `StatusRulesEngineService` - Status Rules Engine operations

**Utility Classes:**

- `ValidationHelper` - Centralized input validation
- `DefaultValueHelper` - Centralized default value assignment
- `PicklistHelper` - Centralized picklist value retrieval
- `StageCompletionConfig` - Stage completion configuration

**Strategy Classes:**

- `ActivationStrategy` - Activation strategy interface
- `EmailSenderStrategy` - Email sender strategy interface
- `ActivationStrategyFactory` - Activation strategy factory
- `EmailSenderStrategyFactory` - Email sender strategy factory

**Key Flows:**

- `BLL_Training_Assignment_Credential_RCD_Unique_Key_Creation`
- `BLL_Contact_Training_Assignment_RCD_Update_Related_Records`
- `BLL_External_Contact_Credential_RCD_Execute_Supplemental_Onboarding_Requirements`
- `BLL_Order_RCD_GET_Onboarding_Record`

**Communication:**

- Called directly by Application Layer (LWC/Flow)
- Methods annotated with `@AuraEnabled` for LWC integration
- Methods annotated with `@InvocableMethod` for Flow integration
- Calls Repository Layer for data operations
- Contains business logic only (no direct SOQL/DML)
- Repositories handle all data access (SOQL, DML)

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

Application Layer
Onboardingc record changes
↓
Application Layer Flow
Onboarding_Record_Trigger_Update_Onboarding_Status
↓
Business Logic Layer
OnboardingStatusEvaluator.evaluateAndApplyStatus()
↓
Business Logic Layer
OnboardingRulesService.getRulesForGroups()
↓
Business Logic Layer
OnboardingRuleEvaluator.evaluateRule()
↓
Domain Layer (if needed)
Data queries via SOQL
↓
Business Logic Layer
Update Onboardingc.Onboarding_Status_c

### Example: Onboarding Flow

Application Layer
User navigates to Vendor Program record page
↓
Application Layer Component
vendorProgramOnboardingFlow
↓
Business Logic Layer
OnboardingApplicationService.getProcessIdForVendorProgram()
↓
Application Layer Component
onboardingFlowEngine
↓
Business Logic Layer
OnboardingApplicationService.getStagesForProcess()
↓
Application Layer Component
onboardingStageRenderer (dynamically renders stage components)
↓
Application Layer Component
Stage component (e.g., vendorProgramOnboardingVendor)
↓
Business Logic Layer
OnboardingApplicationService.saveProgress()
↓
Domain Layer (if needed)
Data operations via flows

## Benefits of Layered Architecture

### Separation of Concerns

- **Application Layer**: Focuses on user experience
- **Business Logic Layer**: Focuses on business rules
- **Domain Layer**: Focuses on data operations

### Maintainability

- Changes to UI don't affect business logic
- Business logic changes don't affect data operations
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

1. **Direct Service Calls**: Call domain services directly via @AuraEnabled methods
2. **Service Delegation**: Delegate to Service Layer
3. **Error Handling**: Handle errors gracefully
4. **Loading States**: Show loading indicators

### Service Layer

1. **Consolidated Domain Services**: Group related functionality into domain services
2. **@AuraEnabled Methods**: Expose methods directly to LWC components
3. **@InvocableMethod Annotations**: Expose methods to Flows
4. **No Direct Data Access**: Use Repository Layer for data
5. **Validation**: Enforce business rules
6. **Error Handling**: Throw meaningful exceptions

### Domain Layer

1. **Pure Data Operations**: No business logic
2. **Reusable Flows**: Create reusable subflows
3. **Error Handling**: Handle data errors
4. **Naming Convention**: Follow naming convention

## Repository Layer

**Purpose**: Handles all data access operations (SOQL, DML).

**Components:**

- Apex Repositories (*Repo.cls, *Repository.cls)
- Located in `repository/` subdirectory

**Responsibilities:**

- SOQL queries
- DML operations (insert, update, delete, upsert)
- Query optimization
- Data integrity operations

**Must NOT:**

- Contain business logic
- Perform validation (except data integrity)
- Transform data (except for query results)

**Example:**

```apex
public with sharing class OnboardingAppECCRepository {
  public static List<Required_Credential__c> fetchRequiredCredentials(
    Id vendorProgramId
  ) {
    return [
      SELECT Id, Name, External_Contact_Credential_Type__c
      FROM Required_Credential__c
      WHERE Vendor_Customization__c = :vendorProgramId
    ];
  }
}
```

**Communication:**

- Called by Business Logic Layer services
- No business logic (pure data operations)

## Related Documentation

- [Architecture Overview](./overview.md)
- [Data Model](./data-model.md)
- [Apex Patterns](./apex-patterns.md) - Detailed Apex class patterns
- [Flows](../processes/flows.md)
