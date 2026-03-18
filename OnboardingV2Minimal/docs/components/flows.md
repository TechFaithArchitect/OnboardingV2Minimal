# Salesforce Flows

## Overview

The onboarding system uses Salesforce Flows for automation across Business Logic Layer (BLL), Domain Layer (DOMAIN), and Experience Layer (EXP). Flows follow consistent naming conventions.

## Naming Conventions

### Business Logic Layer (BLL)
**Pattern**: `BLL_[Object]_[Type]_[Description]`

- **RCD** - Record-triggered (Create/Update)
- **SFL** - Subflow
- **SCD** - Scheduled
- **ACTION** - Action flow

### Domain Layer (DOMAIN)
**Pattern**: `DOMAIN_[Object]_[Type]_[Operation]_[Description]`

- **SFL** - Subflow
- **OmniSObject** - Generic SObject operations

### Experience Layer (EXP)
**Pattern**: `EXP_[Object]_[Type]_[Description]`

- **SCR** - Screen flow

## Key Flows

### BLL_Onboarding_Requirement_RCD_Logical_Process

**Type**: Record-Triggered Flow (After Save)  
**Object**: `Onboarding_Requirement__c`

**Purpose**: Main status evaluation flow. Runs when an Onboarding Requirement is created or updated. When status, override, or requirement type changes, it calls `OnboardingStatusEvaluatorInvocable` to evaluate and update `Onboarding__c.Onboarding_Status__c` and `Opportunity.StageName`.

**Path**: Start → Get Onboarding Record → Get Opportunity/Contact/Account/Vendor Program → Is Create Event? → (On Create) Evaluate Approval Policy → Create Required Related Records if needed → Should Evaluate Normalization? → Assign Onboarding Id → Evaluate Onboarding Status (Invocable)

### BLL_Onboarding_RCD_Logical_Process

**Type**: Record-Triggered Flow  
**Object**: `Onboarding__c`

**Purpose**: Handles onboarding record changes; dispatches communications, evaluates setup complete.

### BLL_BRE_Evaluate_Business_Rules

**Type**: Subflow  
**Purpose**: Business Rules Engine—evaluates OnboardingStatusNormalization, VendorProgramApprovalPolicy, CommunicationDispatchResolver, etc.

### DOMAIN_OmniSObject_SFL_* Flows

Subflows for data operations:

- `DOMAIN_OmniSObject_SFL_GET_Onboarding_Records` - Get onboarding records
- `DOMAIN_OmniSObject_SFL_GET_Onboarding_Requirement` - Get onboarding requirements
- `DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records` - Create related requirements
- `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record` - Create/update onboarding record
- `DOMAIN_OmniSObject_SFL_GET_Opportunity_Record`, `GET_Account_Record`, `GET_Vendor_Program`, etc.

### EXP_* Screen Flows

- `EXP_Opportunity_SCR_Create_Record` - Create opportunity (Experience Cloud)
- `EXP_Contact_SCR_Create_Contact` - Create contact
- `EXP_Opportunity_Contacts_SCR_CREATE_Opportunity_Contacts` - Create opportunity contacts

## Flow Inventory (This Repo)

Flows in `force-app/main/default/flows/` include:

**BLL (Business Logic)**:
- BLL_Onboarding_Requirement_RCD_Logical_Process
- BLL_Onboarding_RCD_Logical_Process
- BLL_Onboarding_Requirement_Subject_RCD_Logical_Process
- BLL_BRE_Evaluate_Business_Rules
- BLL_Onboarding_SFL_Assign_LearnUpon_Credentials
- BLL_Onboarding_SFL_Dispatch_Communication_By_Event
- BLL_Onboarding_SFL_Dispatch_Communication_By_Context
- BLL_Onboarding_SCD_Review_and_Assign_Missing_Training_Records
- BLL_Agreement_RCD_Logical_Process
- BLL_Opportunity_RCD_Logical_Process
- BLL_External_Contact_Credential_RCD_Logical_Process
- BLL_External_Contact_Credential_RCD_Prevent_Duplicates
- BLL_LearnUponContactEnrollment_* flows
- BLL_Training_Assignment_* flows
- BLL_Vendor_Program_* flows

**DOMAIN**:
- DOMAIN_OmniSObject_SFL_GET_* (Onboarding, Opportunity, Account, Vendor Program, etc.)
- DOMAIN_OmniSObject_SFL_CREATE_* (Onboarding, Agreement, Training Assignment, etc.)
- DOMAIN_Agreement_SFL_CREATE_Agreement

**EXP (Experience)**:
- EXP_Opportunity_SCR_Create_Record
- EXP_Contact_SCR_Create_Contact
- EXP_Contract_SCR_Send_Adobe_Agreement
- EXP_Opportunity_Contacts_SCR_CREATE_Opportunity_Contacts

## Related Documentation

- [Status Evaluation](../processes/status-evaluation.md)
- [Onboarding Process](../processes/onboarding-process.md)
- [Architecture Layers](../architecture/layers.md)
