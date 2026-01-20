# System Architecture Overview

## Introduction

The Onboarding V2 system is a comprehensive, metadata-driven onboarding framework built on Salesforce. It provides a flexible, configurable solution for managing vendor program onboarding processes with full auditability, progress tracking, and dynamic flow rendering.

## Business Goals and User Roles

Onboarding V2 manages the lifecycle of onboarding a Dealer (Account) into a specific Vendor Program (`Vendor_Customization__c`). Each `Onboarding__c` record represents one Account's progress against a single Vendor Program's requirements and status rules.

### Internal User Roles

- Program Specialists (Sales): Internal sales selling a program to a Dealer (Account); initiate onboarding from Accounts and Opportunities, ensure Account Contacts and roles are set, and link Dealers to Vendor Programs.
- Program Managers: Internal owners selling us to Vendors so we can offer their Vendor Program; configure vendor program requirements, requirement groups, rules engines, and stage dependencies; manage versioned program changes.
- Onboarding Managers (Account Services): Drive requirement completion with Dealers, update requirement statuses, and monitor progress to completion.
- Compliance Managers: Maintain compliance-related requirements and rule changes effective on specific dates; audit status and requirement changes.
- Finance Managers: Configure contracts/agreements and payment structures; ensure program requirements reflect new agreements and dealers are updated.

### Status and Override

- `Onboarding__c.Onboarding_Status__c` is the business-facing status for a Dealer's onboarding to a Vendor Program (for example: New, In Process, Pending Initial Review, Setup Complete).
- External overrides are used when a Dealer is granted a pass outside normal requirement criteria; automation should not overwrite status while an override is enabled. See `docs/processes/status-evaluation.md` for evaluation details.

## High-Level Architecture

The system follows a **layered architecture pattern** with three main layers:

┌─────────────────────────────────────────┐
│ APPLICATION LAYER │
│ (Flows, LWC Components, UI) │
└─────────────────────────────────────────┘
↓
┌─────────────────────────────────────────┐
│ SERVICE LAYER (with @AuraEnabled) │
│ (Consolidated Domain Services) │
└─────────────────────────────────────────┘
↓
┌─────────────────────────────────────────┐
│ REPOSITORY LAYER │
│ (Data Access Only) │
└─────────────────────────────────────────┘

### Application Layer

The Application Layer handles user interactions and orchestrates business processes:

- **Lightning Web Components (LWC)**: Dynamic UI components for onboarding flows
- **Salesforce Flows**: High-level process automation (e.g., `APP_Onboarding.flow`)
- **Record Pages**: Lightning pages that host onboarding components

**Key Components:**

- `onboardingHomeDashboard` - Central home page dashboard for onboarding overview
- `onboardingFlowEngine` - Main flow controller
- `onboardingStageRenderer` - Dynamic component renderer
- `vendorProgramOnboardingFlow` - Vendor-specific wrapper
- `onboardingRequirementsPanel` - Requirements management UI
- `onboardingStatusRulesEngine` - Rules configuration UI

### Service Layer

The Service Layer contains consolidated domain services with business logic and LWC/Flow integration:

- **Domain Services**: Consolidated services organized by domain (e.g., `VendorDomainService`, `RequirementDomainService`)
- **Business Logic Services**: Core business logic services (e.g., `OnboardingApplicationService`, `OnboardingRulesService`)
- **Controllers**: Only complex controllers that coordinate multiple services
- **Handlers**: Trigger and event handlers
- **Evaluators**: Rule evaluation engines (e.g., `OnboardingStatusEvaluator`, `OnboardingRuleEvaluator`)

**Key Consolidated Domain Services:**

- `VendorDomainService` - Vendor, VendorProgram, VendorProgramGroup operations
- `RequirementDomainService` - VendorProgramRequirement, VendorProgramRequirementGroup operations
- `CommunicationDomainService` - CommunicationTemplate, RecipientGroup operations
- `VendorOnboardingService` - Vendor eligibility and onboarding logic
- `EmailSyncDomainService` - Email template and org-wide email synchronization

**Key Business Logic Services:**

- `OnboardingApplicationService` - Process and stage management
- `OnboardingRulesService` - Rules engine data access
- `OnboardingStatusEvaluator` - Status evaluation logic
- `OnboardingAppActivationService` - Activation workflow (with @AuraEnabled)

### Domain Layer

The Domain Layer handles data operations and domain-specific logic:

- **Domain Flows**: Subflows for specific data operations (e.g., `DOMAIN_Onboarding_SFL_*`)
- **Record-Triggered Flows**: Before/after save flows for data validation
- **Data Integrity**: Duplicate prevention, unique key creation

**Naming Convention:**

- `DOMAIN_[Object]_SFL_[Operation]_[Description]` - Subflows
- `DOMAIN_[Object]_RCD_[Trigger]_[Description]` - Record-triggered flows

## Key Design Patterns

### 1. Metadata-Driven Configuration

The system uses Custom Objects to define onboarding processes dynamically:

- `Onboarding_Application_Process__c` - Defines reusable onboarding flows
- `Onboarding_Application_Stage__c` - Defines stages within a process
- `Onboarding_Component_Library__c` - Maps LWC components to metadata
- `Onboarding_Application_Progress__c` - Tracks user progress
- `Onboarding_Application_Stage_Completion__c` - Audit log of completed stages

### 2. Rules Engine Pattern

Status evaluation uses a configurable rules engine:

- `Onboarding_Status_Rules_Engine__c` - Rule definitions
- `Onboarding_Status_Rule__c` - Individual rule conditions
- `OnboardingRuleEvaluator` - Rule evaluation logic
- `OnboardingExpressionEngine` - Expression parsing and evaluation

### 3. Validation Rule Pattern

Activation and validation use a registry pattern:

- `OnboardingAppRuleRegistry` - Central registry of validation rules
- `OnboardingAppValidationRule` - Interface for validation rules
- Rule implementations per object (e.g., `RequireParentVersionOnActivationRule`)

### 4. Campaign/Campaign Member Pattern

The system uses the **Campaign/Campaign Member** pattern (similar to Salesforce Campaigns and Account Engagement) for many-to-many relationships. This pattern is ideal for:

- **Many-to-many relationships** between parent objects and members
- **Collaborative workflows** where multiple users work on different parts
- **Versioning support** with Draft/Active/Deprecated statuses
- **Flexible membership attributes** stored on the junction object

**Example Implementation:**

```
Vendor_Program_Group__c (Parent)    Vendor_Program_Group_Member__c (Junction)
├─ Name                              ├─ Vendor_Program_Group__c (lookup)
├─ Active__c                         ├─ Required_Program__c (lookup to Vendor_Customization__c)
├─ Status__c                         ├─ Inherited_Program_Requirement_Group__c (lookup)
└─ Previous_Version__c               ├─ Is_Target__c (member attribute)
                                     └─ Active__c (member attribute)
```

**Benefits:**

- One Vendor Program can belong to multiple Groups
- One Group can contain multiple Vendor Programs
- Junction object stores relationship-specific attributes
- Supports collaborative workflows with versioning

**Objects Using This Pattern:**

- `Vendor_Program_Group__c` / `Vendor_Program_Group_Member__c`
- `Vendor_Program_Requirement_Group__c` / `Vendor_Program_Requirement_Group_Member__c`
- `Recipient_Group__c` / `Recipient_Group_Member__c`

### 5. Versioning Pattern

The system implements versioning to support collaborative, multi-user workflows where users may start but not finish onboarding processes. This allows:

- **Draft versions** for work-in-progress
- **Active versions** for production use
- **Deprecated versions** for historical tracking
- **Version lineage** through `Previous_Version__c` field

**Versioning Fields:**

- `Status__c` - Draft, Active, Deprecated
- `Previous_Version__c` - Links to parent version (tracks lineage)
- `Active__c` - Boolean flag for active status

**Versioning Rules:**

1. Draft records cannot be Active (auto-corrected)
2. Only one Active version per parent context
3. Version lineage maintained through `Previous_Version__c`

**Objects Supporting Versioning:**

- `Vendor_Customization__c` (Vendor Programs)
- `Vendor_Program_Recipient_Group__c`
- `Vendor_Program_Onboarding_Req_Template__c`
- Other objects with `Status__c`, `Previous_Version__c`, `Active__c` fields

**Use Case:**
Multiple users can work on different parts of onboarding simultaneously:

- User A creates a Draft vendor program
- User B adds requirements to the Draft
- User C configures recipient groups
- When ready, the Draft is activated, becoming the Active version
- Previous Active version is automatically deactivated

### 6. Service Layer Pattern

Business logic is organized into consolidated domain services:

- **Domain Services**: Consolidated services by domain (`*DomainService.cls`) - e.g., `VendorDomainService`, `RequirementDomainService`
- **Business Logic Services**: Core business logic (`*Service.cls`) - e.g., `OnboardingApplicationService`
- **Repositories**: Data access layer (`*Repo.cls`, `*Repository.cls`)
- **Controllers**: Only complex controllers that coordinate multiple services (`*Ctlr.cls`)

**Simplified Architecture:**

- LWC components call domain services directly (via `@AuraEnabled` methods)
- Flows call domain services directly (via `@InvocableMethod` annotations)
- Services delegate to repositories for all data access
- Thin orchestrator and facade layers have been eliminated

### 7. Base Class Pattern (LWC)

The Vendor Program Onboarding Wizard uses a base class pattern to eliminate code duplication:

- **Base Class**: `onboardingStepBase` - Provides common functionality for all step components
- **Inheritance**: All 14 wizard step components extend `OnboardingStepBase`
- **Benefits**:
  - Eliminates ~700+ lines of duplicate code
  - Standardizes navigation, validation, and event handling
  - Ensures consistency across all steps
  - Makes adding new steps easier

**Key Features:**

- Footer navigation event handling
- Validation state dispatching
- Toast notification utility
- Dynamic card title generation
- Standardized event dispatching

**Required Overrides:**

- `get canProceed()` - Validation state
- `proceedToNext()` - Next navigation with data
- `stepName` - Step name for card title

## Data Flow

### Onboarding Flow Execution

User Action
↓
vendorProgramOnboardingFlow (LWC)
↓
OnboardingApplicationService.getProcessIdForVendorProgram()
↓
onboardingFlowEngine (LWC)
↓
OnboardingApplicationService.getStagesForProcess()
↓
onboardingStageRenderer (LWC) - Dynamically renders stage components
↓
Stage-specific LWC (e.g., vendorProgramOnboardingVendor)
↓
VendorDomainService.searchVendors() - Direct service call
↓
OnboardingApplicationService.saveProgress() - Persists progress

### Status Evaluation Flow

Onboardingc Record Change
↓
Onboarding_Record_Trigger_Update_Onboarding_Status (Flow)
↓
OnboardingStatusEvaluator.evaluateAndApplyStatus()
↓
OnboardingRulesService.getRulesForGroups()
↓
OnboardingRuleEvaluator.evaluateRule() - For each rule
↓
OnboardingExpressionEngine.evaluate() - Expression evaluation
↓
Update Onboardingc.Onboarding_Status_c

## Technology Stack

- **Platform**: Salesforce Lightning Platform
- **UI Framework**: Lightning Web Components (LWC)
- **Backend**: Apex
- **Automation**: Salesforce Flows
- **Data Model**: Custom Objects

## Scalability Considerations

- **Metadata-Driven**: Processes can be configured without code changes
- **Modular Components**: Stage components are independent and reusable
- **Progress Tracking**: Users can resume onboarding flows
- **Audit Trail**: Complete history of stage completions
- **Rules Engine**: Status evaluation rules are configurable

## Security

- **Sharing Model**: Controlled by parent (Account) for Onboarding records
- **Field-Level Security**: Enforced via profiles and permission sets
- **Apex Sharing**: Uses `with sharing` for data access control
- **Validation Rules**: Prevent invalid data entry

## Related Documentation

- [Data Model](./data-model.md) - Complete object definitions, relationships, and patterns
- [Layered Architecture Details](./layers.md) - Layer responsibilities and communication
- [Apex Patterns](./apex-patterns.md) - Apex class architectural patterns and conventions
- [Component Documentation](../components/lwc-components.md) - LWC component details
