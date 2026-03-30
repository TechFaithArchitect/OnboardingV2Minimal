# Sales User Guide

## Purpose

This guide explains how sales users initiate and progress onboarding in the current flow model.

## Primary Entry Point

Use `EXP_Opportunity_SCR_Create_Record` to create and kick off onboarding.

## Standard Sales Workflow

1. Start onboarding flow from account/opportunity context.
2. Complete main intake screen fields.
3. Select program path and vendor program options.
4. Confirm opportunity and contract creation succeeds.
5. Ensure opportunity contact roles are created and primary OCR is set.
6. Verify onboarding record is created (immediate or deferred completion path).

## Contact Responsibility Notes

- The primary opportunity contact is central in requirement responsibility when policy is `PRIMARY_CONTACT_OR_ACCOUNT`.
- Primary OCR role selection is constrained in the guided path to approved relationship roles.
- If no valid primary OCR exists, fallback responsibility can land on account-level subject depending on policy.

## Agreement and Contract Path

- Agreement send actions are routed through dedicated contract screen flow.
- User receives clear success or error state from the flow UI.
- Technical fault details are logged for admin triage when needed.

## What Sales Should Validate After Submission

- Opportunity exists and has expected stage/status
- Contract exists and is linked
- Onboarding record exists and is linked to account/opportunity/contract
- Primary contact assignment is present for responsibility-sensitive programs

## Common User Errors and Fixes

| Issue | Typical Cause | Action |
|---|---|---|
| Flow exits with validation error | Missing required intake fields | Correct required fields and rerun |
| Onboarding not visible immediately | Deferred onboarding tail is enabled | Wait for async completion and refresh |
| Contact cannot be selected for signer path | Contact role/relationship does not meet allowed constraints | Update relationship role or choose eligible contact |
| Agreement send fails | Integration or contract state issue | Retry after admin checks Error Log and contract data |
