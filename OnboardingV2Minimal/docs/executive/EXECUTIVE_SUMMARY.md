# Executive Summary

## What This System Is

OnboardingV2 is a Salesforce-native onboarding platform that manages account onboarding through configurable requirements, subject-level responsibility, evidence-driven status transitions, and operational communication workflows.

It is built as a layered automation system:

- Experience flows (`EXP_*`) for guided user execution
- Business logic flows (`BLL_*`) for orchestration and policy
- Domain flows (`DOMAIN_*`) for reusable data operations
- Apex services for rules, resilience, async orchestration, and API-backed components

## Business Outcomes It Enables

- Standardized onboarding across vendor programs
- Reduced manual handoffs through flow orchestration and policy metadata
- Consistent status progression driven by normalized requirement evidence
- Improved operational resiliency via fault logging, follow-up queueing, and isolated async tails
- Faster cycle times for sales and onboarding teams through guided screen flows

## Current Capability Highlights

- End-to-end opportunity-to-onboarding creation path
- Requirement expansion by fulfillment policy (`ACCOUNT_ONLY`, `ALL_CONTACTS`, `PRINCIPAL_OWNER`, `PRIMARY_CONTACT_OR_ACCOUNT`)
- Subject-level requirement evaluation and parent roll-up
- CMDT-driven onboarding status evaluation with ordered rules
- Communication dispatch by event/context with policy-driven recipient resolution
- Deferred onboarding tail execution to shorten user-visible wait time

## Governance and Control Model

- Configuration-first behavior through custom metadata for status normalization, evaluation rules, fulfillment policies, communication policies, and performance settings
- Security-aware data access patterns (`WITH SECURITY_ENFORCED`, `WITH USER_MODE`, `update as user` in key paths)
- Permission-set-centered access model for onboarding personas
- Centralized fault capture into `Error_Log__c` and flow-integrated fault handlers

## Strategic Next Priorities

- Continue retiring legacy patterns and historical fallback logic after planned data cleanup
- Expand validation hardening for relationship ownership constraints
- Complete explicit orchestration consolidation for requirement subject evaluators
- Expand automated tests for critical negative and bulk scenarios
- Add operational dashboards over error logs and onboarding chain events
