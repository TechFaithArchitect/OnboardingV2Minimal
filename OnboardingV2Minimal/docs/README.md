# Onboarding V2 Documentation

Welcome to the Onboarding V2 documentation. This documentation provides comprehensive information about the onboarding system architecture, components, processes, and usage.

## Terminology

- Dealer: Account record participating in onboarding.
- Vendor Program: Vendor-specific program configuration (`Vendor_Customization__c`).
- Program Specialist (Sales): Internal sales selling programs to Dealers; initiates onboarding.
- Program Manager: Internal owner selling us to Vendors; configures vendor program requirements, rules, and stage dependencies.
- Onboarding Manager (Account Services): Works with Dealers to complete requirements and move status forward.
- Compliance Manager: Owns compliance requirement changes and effective-date updates.
- Finance Manager: Owns agreements and payment structures tied to vendor programs.

## 📖 Table of Contents

### Architecture
- [System Overview](./architecture/overview.md) - High-level architecture and design patterns
- [Layered Architecture](./architecture/layers.md) - Application, Business Logic, and Domain layers
- [Apex Patterns](./architecture/apex-patterns.md) - Apex architectural patterns and conventions
- [Data Model](./architecture/data-model.md) - Custom objects, relationships, and data flow
- [Variable Library](../VARIABLE_LIBRARY.md) - Variable naming conventions and standards for consistent code

### Components
- [Lightning Web Components](./components/lwc-components.md) - UI components and their usage
- [Vendor Program Onboarding Wizard Components](./components/vendor-program-onboarding-wizard-components.md) - Comprehensive documentation of all wizard step components
- [Home Dashboard](./components/DASHBOARD.md) - Home page dashboard component documentation
- [Apex Classes](./components/apex-classes.md) - Service layer, controllers, and business logic
- [Flows](./components/flows.md) - Salesforce Flow automation
- [Triggers](./components/triggers.md) - Apex trigger handlers

### Processes
- [Onboarding Process](./processes/onboarding-process.md) - Main onboarding workflow
- [Vendor Program Onboarding Flow](./processes/vendor-program-onboarding-flow.md) - Complete architecture for building vendor programs from scratch
- [Status Evaluation](./processes/status-evaluation.md) - Rules-based status evaluation engine
- [Application Flow Engine](./processes/application-flow-engine.md) - Dynamic flow rendering
- [Stage Dependency Management](./processes/stage-dependency-management.md) - Stage dependency rules and validation

### Objects
- [Custom Objects](./objects/custom-objects.md) - All custom objects and their purposes

### Setup & Configuration
- [Installation](./setup/installation.md) - Deployment and setup instructions
- [Configuration](./setup/configuration.md) - Configuration guide
- [Component Library Setup](./setup/component-library-setup.md) - How to populate the component library for wizard flows
- [Sample Data](./setup/sample-data.md) - Sample data scripts and setup

### User Guides
- [Getting Started](./user-guides/getting-started.md) - Quick start for end users
- [User Journey Summary](./user-guides/user-journey-summary.md) - End-to-end onboarding flow and roles
- [Onboarding Workflow](./user-guides/onboarding-workflow.md) - Step-by-step onboarding process
- [Managing Requirements](./user-guides/managing-requirements.md) - How to manage requirements
- [Configuring Rules](./user-guides/configuring-rules.md) - How to configure status rules
- [Troubleshooting](./user-guides/troubleshooting.md) - Common issues and solutions

### Security
- [Security Model](./security/security-model.md) - Security architecture and permissions

### Performance
- [Optimization Guide](./performance/optimization-guide.md) - Performance best practices and optimization

### Deployment
- [Pre-Production Checklist](./deployment/pre-production-checklist.md) - Production readiness validation

### API Reference
- [Apex API](./api/apex-api.md) - Apex class API documentation
- [Vendor Onboarding Wizard API](./api/vendor-onboarding-wizard-api.md) - Complete API reference for Vendor Program Onboarding Wizard methods

## 📊 Reports & Historical Documentation

For historical reports, changelogs, optimization summaries, and one-off documentation, see the [Reports Directory](./reports/README.md).

Key reports include:
- [Architecture Summary](./reports/architecture/ARCHITECTURE-SUMMARY.md) - Complete architecture overview with patterns
- [Code Quality Review Summary](./reports/architecture/code-quality-review-summary.md) - SOLID principles compliance review
- [Pattern Violations](./reports/architecture/pattern-violations.md) - Historical pattern violations and fixes
- [Quick Reference Guide](./reports/QUICK-REFERENCE.md) - Quick reference for flow, context passing, and key methods

## 🔍 Additional Resources

- [Main README](../README.md)
- [Existing Documentation](../Onboarding_Application_Documentation.txt)
