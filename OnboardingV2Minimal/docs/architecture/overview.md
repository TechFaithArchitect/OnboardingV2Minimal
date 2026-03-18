# System Architecture Overview

## Introduction

Onboarding V2 is a rules-driven onboarding workflow built on Salesforce. It manages dealer onboarding against vendor program requirements and status rules, with auditability and override controls.

## Business Goals and User Roles

The system manages the lifecycle of onboarding a Dealer (Account) into a Vendor Program (`Vendor_Customization__c`). Each `Onboarding__c` record represents one Account's progress against a single Vendor Program's requirements.

### Status and Override

- `Onboarding__c.Onboarding_Status__c` is the business-facing status (e.g., New, In Process, Pending Initial Review, Setup Complete, Denied).
- Overrides are used when a Dealer is granted a pass outside normal requirement criteria; automation respects overrides. See [Status Evaluation](../processes/status-evaluation.md).

## High-Level Architecture

The system uses a layered architecture:

```
┌─────────────────────────────────────────┐
│ APPLICATION LAYER                       │
│ (Flows, LWC Components, UI)             │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ SERVICE LAYER                            │
│ (Apex services, invocables, @AuraEnabled)│
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ DATA LAYER                               │
│ (SOQL, Flows for CRUD)                  │
└─────────────────────────────────────────┘
```

### Application Layer

- **Lightning Web Components (LWC)**: UI components for onboarding (e.g., `onboardingWorkQueue`, `onboardingDealerOnboardingModal`)
- **Salesforce Flows**: Process automation (record-triggered, screen flows, subflows)
- **Record Pages**: Lightning pages hosting onboarding components

### Service Layer

- **Invocables**: Flow actions (e.g., `OnboardingStatusEvaluatorInvocable`, `OnboardingDefaultVendorProgramInvocable`)
- **Services**: Business logic (e.g., `VendorOnboardingService`, `OnboardingStatusEvaluatorService`)
- **Controllers**: LWC data (e.g., `TwilioSettingsController`, `ObjectRelatedListController`)

### Data Layer

- **Domain Flows**: Subflows for data operations (`DOMAIN_OmniSObject_SFL_*`)
- **Record-Triggered Flows**: Before/after save flows

## Key Design Patterns

### 1. Rules-Driven Configuration

- `Vendor_Program_Requirement__c` - Requirements on vendor programs
- `Onboarding_Status_Normalization__mdt` - Per-requirement normalized status mapping
- `Onboarding_Status_Evaluation_Rule__mdt` - Rules for evaluating Onboarding Status

### 2. Status Evaluation

- `BLL_Onboarding_Requirement_RCD_Logical_Process` - Record-triggered flow on Onboarding Requirement
- Calls `OnboardingStatusEvaluatorInvocable` when status/override/type changes
- Invocable evaluates rules from CMDT and updates `Onboarding__c.Onboarding_Status__c` and `Opportunity.StageName`

### 3. Campaign/Campaign Member Pattern

Used for many-to-many relationships:

- `Vendor_Program_Group__c` / `Vendor_Program_Group_Member__c`

### 4. Versioning Pattern

- `Status__c`, `Previous_Version__c`, `Active__c` on versioned objects
- `Vendor_Customization__c` and related objects support versioning

## Data Flow

### Status Evaluation Flow

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

## Technology Stack

- **Platform**: Salesforce Lightning
- **UI**: Lightning Web Components (LWC)
- **Backend**: Apex
- **Automation**: Salesforce Flows
- **Data**: Custom Objects, Custom Metadata

## Related Documentation

- [Data Model](./data-model.md) - Object definitions and relationships
- [Layered Architecture](./layers.md) - Layer responsibilities
- [Apex Patterns](./apex-patterns.md) - Apex conventions
- [LWC Components](../components/lwc-components.md) - Component details
