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
- Salesforce Flows (APP\_\*, EXP\_\*)
- Lightning Record Pages
- Screen Flows

**Responsibilities:**

- User interface rendering
- User input handling
- Process orchestration
- Navigation management
- Progress tracking

**Key Components:**

- `onboardingWorkQueue` - Work queue list
- `onboardingDealerOnboardingModal` - Start dealer onboarding modal
- `recordCollectionEditor` - Record collection editor

**Communication:**

- Calls Business Logic Layer services
- Receives data from Business Logic Layer
- Delegates data operations to Domain Layer

### Service Layer

**Purpose**: Contains business logic, validation, and LWC/Flow integration.

**Components:**

- Apex Services (\*Service.cls)
- Apex Invocables (\*Invocable.cls)
- Apex Controllers (\*Ctlr.cls)
- Salesforce Flows (BLL\_\*)

**Responsibilities:**

- Business rule enforcement
- Validation logic
- LWC integration (via @AuraEnabled methods)
- Flow integration (via @InvocableMethod annotations)
- Status evaluation
- Rules engine execution

**Key Services:**

- `VendorOnboardingService` - Vendor eligibility and onboarding logic
- `OnboardingStatusEvaluatorService` - Status evaluation from CMDT rules
- `OnboardingDefaultVendorProgramInvocable` - Default vendor program assignment
- `OnboardingStatusEvaluatorInvocable` - Flow-callable status evaluation
- `RecordCollectionEditorConfigService` - Record collection configuration
- `FlowAdminGuardService` - Flow admin guard

**Key Flows:**

- `BLL_Onboarding_Requirement_RCD_Logical_Process` - Status evaluation (calls OnboardingStatusEvaluatorInvocable)
- `BLL_Onboarding_RCD_Logical_Process` - Onboarding record changes
- `BLL_BRE_Evaluate_Business_Rules` - Business rules evaluation

**Communication:**

- Called directly by Application Layer (LWC/Flow)
- Methods annotated with `@AuraEnabled` for LWC integration
- Methods annotated with `@InvocableMethod` for Flow integration
- Contains business logic; may use SOQL/DML for service operations

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

**Key Flows:**

- `DOMAIN_OmniSObject_SFL_GET_*` - Get records
- `DOMAIN_OmniSObject_SFL_CREATE_*` - Create/update records
- `DOMAIN_Agreement_SFL_CREATE_Agreement`

**Naming Convention:**

- `DOMAIN_[Object]_SFL_[Operation]_[Description]` - Subflows

**Communication:**

- Called by Business Logic Layer
- Called by Application Layer (for simple operations)
- No business logic (pure data operations)

## Data Flow

### Example: Status Evaluation

```
Onboarding_Requirement__c Create/Update
        ↓
BLL_Onboarding_Requirement_RCD_Logical_Process (Flow)
        ↓
OnboardingStatusEvaluatorInvocable (Apex)
        ↓
OnboardingStatusEvaluatorService.evaluateAndApply()
        ↓
Updates Onboarding__c.Onboarding_Status__c, Opportunity.StageName
```

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

## Related Documentation

- [Architecture Overview](./overview.md)
- [Data Model](./data-model.md)
- [Apex Patterns](./apex-patterns.md)
- [Flows](../components/flows.md)
