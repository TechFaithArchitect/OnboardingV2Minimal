# Developer Guide

## First Day Setup (Developer)

1. Read [System Overview](../technical/SYSTEM_OVERVIEW.md) to understand execution paths.
2. Skim [Object catalog](../technical/OBJECT_CATALOG.md) and [Onboarding UI and custom components](../reference/ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md) so you know what users see.
3. Read [FLOW_CATALOG.md](./FLOW_CATALOG.md) and [APEX_CLASS_INVENTORY.md](./APEX_CLASS_INVENTORY.md) for code location.
4. Scan [Scripts README](../../scripts/README.md) before running repo scripts.
5. Run local quality commands (`lint`, unit tests, prettier verify).
6. Validate changed automation with one real end-to-end scenario before opening PR.

## Repository Structure

- `force-app/main/default`: Salesforce metadata source
- `force-app/main/default/flows`: Flow automation
- `force-app/main/default/classes`: Apex services/invocables/controllers
- `force-app/main/default/lwc`: LWC UI components
- `force-app/main/default/customMetadata`: Policy and rules configuration
- `scripts`: automation and utility scripts

## Layering Conventions

- `EXP_*`: screen flows and guided UX orchestration
- `BLL_*`: business logic and record-triggered orchestration
- `DOMAIN_*` : reusable subflow units

Follow this layering for new automation to avoid circular dependencies and flow sprawl.

## Local Tooling

From `package.json`:

- `npm run lint`
- `npm run test:unit`
- `npm run test:unit:coverage`
- `npm run prettier`
- `npm run prettier:verify`

CLI baseline:

- `sf project deploy start`
- `sf project retrieve start`
- `sf apex run test`

Documentation metrics (flow/Apex/CMDT/object-folder counts for reconciling with [FLOW_CATALOG.md](./FLOW_CATALOG.md) / [APEX_CLASS_INVENTORY.md](./APEX_CLASS_INVENTORY.md)):

- `npm run doc:metrics`

## Coding Patterns

- Prefer metadata-driven behavior for business policies
- Keep flow fault paths explicit and wired to shared fault handler
- Keep Apex services bulk-safe and idempotent where retries are possible
- Preserve security posture (`with sharing`, `WITH SECURITY_ENFORCED`, user mode where needed)

## Required Review Focus for Changes

- Does this change preserve layered boundaries?
- Does this introduce or remove SOQL/DML in loops?
- Are flow fault paths wired and user/admin outcomes clear?
- Does status logic remain consistent with CMDT ordering?
- Are permission and field access requirements documented?

## Critical Files to Understand First

- `OnboardingStatusEvaluatorService.cls`
- `OnboardingStatusPredicateInterpreter.cls`
- `OnboardingStatusNormalizationService.cls`
- `VendorOnboardingService.cls`
- `ObjectRelatedListController.cls`
- `EXP_Opportunity_SCR_Create_Record.flow-meta.xml`
- `BLL_Onboarding_RCD_Logical_Process.flow-meta.xml`
