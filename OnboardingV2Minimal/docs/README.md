# OnboardingV2 Documentation

This is a complete rebuilt documentation set generated from the current repository implementation.

## New Here? Start In This Order

If you are brand new to this project, do not read everything at once. Use this path:

1. Read [Executive Summary](./executive/EXECUTIVE_SUMMARY.md) for what the system does.
2. Read [Baseline setup guide](./BASELINE_SETUP_GUIDE.md) for the default business flow (baseline vs extensions).
3. If you are configuring in the UI and need **click-by-click** steps (for example “how do I set up a new vendor program?”), use [Baseline UI walkthrough](./BASELINE_UI_WALKTHROUGH.md)—then use [Manual vendor program setup](./admin/MANUAL_VENDOR_PROGRAM_SETUP.md) for field-level detail.
4. Skim [Object catalog](./technical/OBJECT_CATALOG.md) (what all the Salesforce objects are for) and [Onboarding UI and custom components](./reference/ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md) (what you click in Lightning).
5. If you are in Sales, read [Sales User Guide](./sales/SALES_USER_GUIDE.md).
6. If you are in Operations/Business, read [Business User Guide](./business/BUSINESS_USER_GUIDE.md).
7. If you are an Admin/Platform owner, read [Admin Operations Runbook](./admin/ADMIN_OPERATIONS_RUNBOOK.md).
8. If you are a Developer, read [Developer Guide](./developer/DEVELOPER_GUIDE.md) and [Scripts README](../scripts/README.md).
9. If something breaks, use [FAQ — Sales and Business Users](./support/FAQ_USERS.md) or [FAQ — Admins & Platform](./support/FAQ_ADMINS.md).
10. For **business rules vs credentials**, read [BRE and credentials (for new users)](./reference/BRE_AND_CREDENTIALS_FOR_NEW_USERS.md).

Quick rule: if you are unsure where to look, start with the baseline doc and the matching FAQ.

## Documentation Map

### Executive

- [Executive Summary](./executive/EXECUTIVE_SUMMARY.md)

### Technical

- [System Overview](./technical/SYSTEM_OVERVIEW.md)
- [Automation Catalog](./technical/AUTOMATION_CATALOG.md)
- [Data Model](./technical/DATA_MODEL.md)
- [Object Catalog](./technical/OBJECT_CATALOG.md)
- [Configuration and Rules](./technical/CONFIGURATION_AND_RULES.md)
- [Integrations](./technical/INTEGRATIONS.md)
- [Environment and Integrations Matrix](./technical/ENVIRONMENT_AND_INTEGRATIONS_MATRIX.md)
- [Security and Access](./technical/SECURITY_AND_ACCESS.md)
- [Persona and Permission Sets](./technical/PERSONA_AND_PERMISSION_SETS.md)
- [Test and Quality](./technical/TEST_AND_QUALITY.md)

### Business and User Guides

- [Business Process Guide](./business/BUSINESS_PROCESS_GUIDE.md)
- [Business User Guide](./business/BUSINESS_USER_GUIDE.md)
- [Sales User Guide](./sales/SALES_USER_GUIDE.md)
- [Screen Flow Click-Path Runbook](./business/SCREEN_FLOW_CLICK_PATH_RUNBOOK.md)
- [Onboarding UI and Custom Components](./reference/ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md)

### Operations

- [Baseline UI walkthrough](./BASELINE_UI_WALKTHROUGH.md) — where to click for vendor, program, requirements, and first onboarding test
- [Baseline setup guide](./BASELINE_SETUP_GUIDE.md) — vendor program + first onboarding story; links to extensions in FAQ (admins)
- [Admin Operations Runbook](./admin/ADMIN_OPERATIONS_RUNBOOK.md)
- [Manual Vendor Program Setup](./admin/MANUAL_VENDOR_PROGRAM_SETUP.md)
- [Deployment Runbook](./admin/DEPLOYMENT_RUNBOOK.md)
- [Release Notes and Smoke-Test Template](./admin/RELEASE_NOTES_AND_SMOKE_TEST_TEMPLATE.md)
- [Metadata Drift Checklist](./admin/METADATA_DRIFT_CHECKLIST.md)
- [Gearset Include List](./admin/GEARSET_INCLUDE_LIST.md)
- [UAT Flow Deactivation Candidates](./admin/UAT_FLOW_DEACTIVATION_CANDIDATES.md)
- [Support and Troubleshooting](./support/SUPPORT_AND_TROUBLESHOOTING.md)
- [FAQ — Sales and Business Users](./support/FAQ_USERS.md)
- [FAQ — Admins & Platform](./support/FAQ_ADMINS.md)

### Engineering

- [Developer Guide](./developer/DEVELOPER_GUIDE.md)
- [Scripts README](../scripts/README.md)
- [Contributing Standards](./developer/CONTRIBUTING_STANDARDS.md)
- [Flow Catalog](./developer/FLOW_CATALOG.md)
- [Apex Class Inventory](./developer/APEX_CLASS_INVENTORY.md)

### Reference

- [Glossary](./reference/GLOSSARY.md)
- [Known Gaps and Backlog](./reference/KNOWN_GAPS_AND_BACKLOG.md)
- [Baseline setup guide](./BASELINE_SETUP_GUIDE.md) (also listed under Operations)
- [Baseline UI walkthrough](./BASELINE_UI_WALKTHROUGH.md) (also listed under Operations)
- [BRE and Credentials (for New Users)](./reference/BRE_AND_CREDENTIALS_FOR_NEW_USERS.md)
- [Engineering Reports (how to read)](./reference/ENGINEERING_REPORTS_HOW_TO_READ.md)


### Engineering reports (repo coverage)

Generated or maintained markdown under `reports/` (metadata/class/trigger coverage vs docs, dependency snapshots). **How to interpret these files:** [Engineering reports (how to read)](./reference/ENGINEERING_REPORTS_HOW_TO_READ.md). Start with:

- [Object dependency inventory](../reports/object-dependency-inventory.md)
- [Docs vs metadata coverage](../reports/docs-metadata-coverage.md)
- [Docs vs class coverage](../reports/docs-class-coverage.md)
- [Dependency missing objects summary](../reports/dependency-missing-objects-summary.md)

## Scope Baseline

This documentation reflects the current source in:

- `force-app/main/default`
- `scripts`
- `config`

**Quantitative footprint:** Use the generated inventories as the source of truth for totals (they are maintained against the same tree):

- Flow counts and listing: [developer/FLOW_CATALOG.md](./developer/FLOW_CATALOG.md)
- Apex inventory (totals, test vs production taxonomy): [developer/APEX_CLASS_INVENTORY.md](./developer/APEX_CLASS_INVENTORY.md)

To print quick counts from your local checkout (flows, Apex classes, custom metadata rows, object folders), run from the DX project root:

```bash
npm run doc:metrics
```

(See [scripts/doc-metrics.js](../scripts/doc-metrics.js).)

## Architecture Pattern Summary

- `EXP_*` flows provide screen and guided user interactions.
- `BLL_*` flows implement business logic, orchestration, and trigger-based automation.
- `DOMAIN_*` flows provide reusable CRUD/get/evaluate/create units (this repo’s flows are `DOMAIN_*`, `BLL_*`, and `EXP_*` only).
- Apex services provide policy engines, resilience tooling, async orchestration, adapters, and reusable UI APIs.

## Primary Application

- Salesforce Lightning app label: **Onboarding** (console navigation).
- App metadata file: [force-app/main/default/applications/Onboarding.app-meta.xml](../force-app/main/default/applications/Onboarding.app-meta.xml)

## End-to-end coverage

Docs span **intake → onboarding → requirements → status → communications** ([Executive Summary](./executive/EXECUTIVE_SUMMARY.md), [System Overview](./technical/SYSTEM_OVERVIEW.md), [Business Process Guide](./business/BUSINESS_PROCESS_GUIDE.md)).

| Topic                                                                                              | Document                                                                                                                                        |
| -------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **Baseline story** (minimal program, no approvals / next-step / program-specific comms by default) | [Baseline setup guide](./BASELINE_SETUP_GUIDE.md)                                                                                               |
| **Baseline UI** (tabs, New, first test — task-first)                                               | [Baseline UI walkthrough](./BASELINE_UI_WALKTHROUGH.md)                                                                                         |
| **Extending the baseline** (what each feature means and how to configure)                          | [FAQ — Admins & Platform](./support/FAQ_ADMINS.md#scenario-index-extending-the-baseline)                                                        |
| **Click-path / screenshots** for create flow and record page                                       | [Screen flow click-path runbook](./business/SCREEN_FLOW_CLICK_PATH_RUNBOOK.md)                                                                  |
| **Org vs connector endpoints**                                                                     | [Environment and integrations matrix](./technical/ENVIRONMENT_AND_INTEGRATIONS_MATRIX.md)                                                       |
| **Release + smoke tests**                                                                          | [Release notes and smoke-test template](./admin/RELEASE_NOTES_AND_SMOKE_TEST_TEMPLATE.md) · [Deployment Runbook](./admin/DEPLOYMENT_RUNBOOK.md) |
| **Personas ↔ permission sets**                                                                     | [Persona and permission sets](./technical/PERSONA_AND_PERMISSION_SETS.md) · [Security and Access](./technical/SECURITY_AND_ACCESS.md)           |
| **Symptom FAQs (users)**                                                                           | [FAQ — Users](./support/FAQ_USERS.md)                                                                                                           |
| **All Salesforce objects (tiers)**                                                                 | [Object catalog](./technical/OBJECT_CATALOG.md)                                                                                                 |
| **Lightning components & record page**                                                             | [Onboarding UI and custom components](./reference/ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md)                                                       |
| **Business rules vs credentials**                                                                  | [BRE and credentials](./reference/BRE_AND_CREDENTIALS_FOR_NEW_USERS.md)                                                                         |
| **Scripts in the repo**                                                                            | [Scripts README](../scripts/README.md)                                                                                                          |
| **Understanding `reports/` markdown**                                                              | [Engineering reports how-to](./reference/ENGINEERING_REPORTS_HOW_TO_READ.md)                                                                    |

Further media (real screenshots, video) can still be tracked in [Known Gaps and Backlog](./reference/KNOWN_GAPS_AND_BACKLOG.md); the click-path runbook is ready for image paths.

## Change Control

When automation or data model changes, update at minimum:

- `technical/SYSTEM_OVERVIEW.md`
- `technical/AUTOMATION_CATALOG.md`
- `technical/DATA_MODEL.md`
- `technical/OBJECT_CATALOG.md` (when adding/removing major objects)
- `reference/ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md` when shipping new LWCs or flexipage changes
- `reference/BRE_AND_CREDENTIALS_FOR_NEW_USERS.md` when BRE or ECC behavior materially changes
- `scripts/README.md` when adding operator-facing scripts
- `technical/PERSONA_AND_PERMISSION_SETS.md` and `technical/SECURITY_AND_ACCESS.md` when permission sets or LWC-facing Apex classes change
- `technical/TEST_AND_QUALITY.md` when adding or changing LWC Jest coverage
- Persona guides affected by behavior changes
- Relevant [FAQ](./support/FAQ_USERS.md) / [FAQ (admins)](./support/FAQ_ADMINS.md) answers if user-visible symptoms or admin checks change
- [Baseline setup guide](./BASELINE_SETUP_GUIDE.md) (and [Baseline UI walkthrough](./BASELINE_UI_WALKTHROUGH.md) if click-path steps change) if the default onboarding story or baseline assumptions change

After structural changes (many new flows/classes/objects), refresh generated sections or summaries in `developer/FLOW_CATALOG.md` and `developer/APEX_CLASS_INVENTORY.md` as your process dictates, and run `npm run doc:metrics` to reconcile headline numbers if you still mention them in prose elsewhere.
