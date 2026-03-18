# Dealer Onboarding Workflow (MVP)

This guide covers the MVP onboarding flow for Dealers (Accounts) tied to Vendor Programs.

## Overview

Each `Onboarding__c` represents one Dealer'''s onboarding to a specific Vendor Program. Requirements are created from `Vendor_Program_Requirement__c`, and status updates are driven by the status rules engine.

## Start an Onboarding

1. Open the Account record.
2. Launch `accountProgramOnboardingModal`.
3. Select a Vendor Program (`Vendor_Customization__c`).
4. Submit to create:
   - `Onboarding__c`
   - `Onboarding_Requirement__c` (one per `Vendor_Program_Requirement__c`)
   - Optional `Account_Vendor_Program_Onboarding__c`

## Work Requirements

Use `onboardingHomeDashboard` and `onboardingRequirementsPanel` to:
- Review requirements
- Update requirement statuses
- Track progress

## Status Evaluation

The system evaluates status rules when requirements change. Status evaluation is driven by Flow (e.g., `BLL_Onboarding_Requirement_RCD_Logical_Process`) and configurable via `Onboarding_Status_Normalization__mdt` (per-requirement) and `Onboarding_Status_Evaluation_Rule__mdt` (aggregation rules, when implemented).

External overrides (`Onboarding_Requirement__c.Is_Overridden__c` and `Onboarding_Next_Step_Override__c`) can temporarily suppress automated updates. Override/status changes are captured through `Onboarding_Requirement__History`.

## Common Actions

- **Add/Edit Requirements**: Update `Vendor_Program_Requirement__c` for the program.
- **Configure Status Rules**: Use `Onboarding_Status_Normalization__mdt` (per-requirement) and `Onboarding_Status_Evaluation_Rule__mdt` (aggregation rules).
- **Manual Overrides**: Apply override records when manual control is needed.

## Notes

- Every onboarding is tied to a Vendor Program.
- Wizard stages, recipient groups, and application process tracking are removed in MVP v2.
