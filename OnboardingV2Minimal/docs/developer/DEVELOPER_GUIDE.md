# Developer Guide

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
