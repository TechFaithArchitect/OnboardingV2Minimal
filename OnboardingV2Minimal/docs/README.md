# Onboarding V2 Documentation

Documentation for the Onboarding V2 MVP system—a rules-driven onboarding workflow for managing dealer onboarding against vendor program requirements.

## Terminology

- **Dealer**: Account record participating in onboarding
- **Vendor Program**: Vendor-specific program configuration (`Vendor_Customization__c`)
- **Program Specialist (Sales)**: Internal sales selling programs to Dealers; initiates onboarding
- **Program Manager**: Internal owner selling us to Vendors; configures vendor program requirements
- **Onboarding Manager (Account Services)**: Works with Dealers to complete requirements and move status forward

## Table of Contents

### Architecture
- [System Overview](./architecture/overview.md) - High-level architecture and design patterns
- [Layered Architecture](./architecture/layers.md) - Application, Business Logic, and Domain layers
- [Apex Patterns](./architecture/apex-patterns.md) - Apex architectural patterns
- [Data Model](./architecture/data-model.md) - Custom objects, relationships, and data flow
- [Variable Library](./VARIABLE_LIBRARY.md) - Variable naming conventions

### Components
- [Apex Classes](./components/apex-classes.md) - Service layer, invocables, and business logic
- [Lightning Web Components](./components/lwc-components.md) - UI components in this repo
- [Flows](./components/flows.md) - Salesforce Flow automation
- [Triggers](./components/triggers.md) - Apex triggers

### Processes
- [Onboarding Process](./processes/onboarding-process.md) - Main onboarding workflow
- [Status Evaluation](./processes/status-evaluation.md) - Rules-based status evaluation
- [Account Onboarding Quick Action](./processes/account-onboarding-quick-action.md) - Quick action flow

### Objects
- [Custom Objects](./objects/custom-objects.md) - Custom objects and their purposes

### Setup & Configuration
- [Installation](./setup/installation.md) - Deployment and setup
- [Configuration](./setup/configuration.md) - Configuration guide
- [Sample Data](./setup/sample-data.md) - Sample data setup

### User Guides
- [Getting Started](./user-guides/getting-started.md) - Quick start for end users
- [Onboarding Workflow](./user-guides/onboarding-workflow.md) - Step-by-step process
- [Managing Requirements](./user-guides/managing-requirements.md) - Requirement management
- [Troubleshooting](./user-guides/troubleshooting.md) - Common issues and solutions

### Security & Performance
- [Security Model](./security/security-model.md) - Security architecture
- [Optimization Guide](./performance/optimization-guide.md) - Performance best practices

### Deployment & Testing
- [Pre-Production Checklist](./deployment/pre-production-checklist.md) - Production readiness
- [Test Classes and Commands](./testing/TEST-CLASSES-AND-COMMANDS.md) - Running tests
