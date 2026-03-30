# OnboardingV2 Documentation

This is a complete rebuilt documentation set generated from the current repository implementation.

## Documentation Map

### Executive
- [Executive Summary](./executive/EXECUTIVE_SUMMARY.md)

### Technical
- [System Overview](./technical/SYSTEM_OVERVIEW.md)
- [Automation Catalog](./technical/AUTOMATION_CATALOG.md)
- [Data Model](./technical/DATA_MODEL.md)
- [Configuration and Rules](./technical/CONFIGURATION_AND_RULES.md)
- [Integrations](./technical/INTEGRATIONS.md)
- [Security and Access](./technical/SECURITY_AND_ACCESS.md)
- [Test and Quality](./technical/TEST_AND_QUALITY.md)

### Business and User Guides
- [Business Process Guide](./business/BUSINESS_PROCESS_GUIDE.md)
- [Business User Guide](./business/BUSINESS_USER_GUIDE.md)
- [Sales User Guide](./sales/SALES_USER_GUIDE.md)

### Operations
- [Admin Operations Runbook](./admin/ADMIN_OPERATIONS_RUNBOOK.md)
- [Deployment Runbook](./admin/DEPLOYMENT_RUNBOOK.md)
- [Gearset Include List](./admin/GEARSET_INCLUDE_LIST.md)
- [UAT Flow Deactivation Candidates](./admin/UAT_FLOW_DEACTIVATION_CANDIDATES.md)
- [Support and Troubleshooting](./support/SUPPORT_AND_TROUBLESHOOTING.md)

### Engineering
- [Developer Guide](./developer/DEVELOPER_GUIDE.md)
- [Contributing Standards](./developer/CONTRIBUTING_STANDARDS.md)
- [Flow Catalog](./developer/FLOW_CATALOG.md)
- [Apex Class Inventory](./developer/APEX_CLASS_INVENTORY.md)

### Reference
- [Glossary](./reference/GLOSSARY.md)
- [Known Gaps and Backlog](./reference/KNOWN_GAPS_AND_BACKLOG.md)

## Scope Baseline

This documentation reflects the current source in:

- `force-app/main/default`
- `scripts`
- `config`

Key current footprint:

- 89 Flows
- 131 Apex classes
- 39 Apex test classes
- 27 test factory classes
- 78 object metadata folders
- 151 custom metadata records

## Architecture Pattern Summary

- `EXP_*` flows provide screen and guided user interactions.
- `BLL_*` flows implement business logic, orchestration, and trigger-based automation.
- `DOMAIN_*` and `DOM_*` flows provide reusable CRUD/get/evaluate/create units.
- Apex services provide policy engines, resilience tooling, async orchestration, adapters, and reusable UI APIs.

## Primary Application

- Salesforce app metadata: `Onboarding.app-meta.xml`

## Change Control

When automation or data model changes, update at minimum:

- `technical/SYSTEM_OVERVIEW.md`
- `technical/AUTOMATION_CATALOG.md`
- `technical/DATA_MODEL.md`
- Persona guides affected by behavior changes
