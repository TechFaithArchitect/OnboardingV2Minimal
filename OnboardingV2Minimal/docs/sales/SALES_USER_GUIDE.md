# Sales User Guide

## Fast Path (2-Minute Version)

1. Run `EXP_Opportunity_SCR_Create_Record` from the Opportunity.
2. Pick the right primary contact.
3. Submit and confirm Opportunity + Contract + Onboarding are linked.
4. Hand off only after those links are correct.

If one of those links is wrong, onboarding operations will inherit bad context.

## Where in Salesforce

- **App:** use the **Onboarding** Lightning console app when working onboarding records and related tabs (same app as operations; see [Onboarding.app-meta.xml](../../force-app/main/default/applications/Onboarding.app-meta.xml)).
- **Create path:** launch screen flow **`EXP_Opportunity_SCR_Create_Record`** from **Opportunity** (and account) context so required records and links are created in one path — details below.

If something fails or stalls after submission, see [FAQ — Sales and Business Users](../support/FAQ_USERS.md) and [Support and Troubleshooting](../support/SUPPORT_AND_TROUBLESHOOTING.md). For admin-owned configuration (fallback vendor, communications), see [Admin Operations Runbook](../admin/ADMIN_OPERATIONS_RUNBOOK.md).

## Purpose

This guide explains how sales users create onboarding records correctly, why each required step matters, and what to check before handing off to onboarding operations.

## Primary Entry Point

Use `EXP_Opportunity_SCR_Create_Record` from account/opportunity context.

## Step-by-Step Procedure

| Step | What To Do                                                          | Why This Matters                                                                |
| ---- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| 1    | Launch `EXP_Opportunity_SCR_Create_Record`.                         | Ensures all required create logic runs in one controlled path.                  |
| 2    | Complete intake fields and select the intended vendor program path. | Drives downstream requirement creation and communication routing.               |
| 3    | Select the correct primary opportunity contact.                     | Responsibility expansion and communications depend on the primary contact path. |
| 4    | Submit and confirm Opportunity + Contract creation.                 | Onboarding record creation relies on these links.                               |
| 5    | Verify the Onboarding record is created and linked.                 | Confirms handoff to onboarding lifecycle automation.                            |
| 6    | Re-open the created records and validate key field values.          | Catches setup mistakes before onboarding operations begin work.                 |

## Field Guide For Sales

| Field                                   | Where You See It                         | How To Fill / Validate                                                                                 | Why It Is Important                                               |
| --------------------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------- |
| `OpportunityContactRole.ContactId`      | Primary contact selection in create flow | Choose the person accountable for onboarding communications and responsibility-sensitive requirements. | Drives recipient resolution and responsibility fallback behavior. |
| `OpportunityContactRole.IsPrimary`      | Opportunity Contact Role                 | Ensure one and only one primary OCR for the opportunity.                                               | Primary-contact logic depends on this flag.                       |
| `AccountContactRelation.Roles`          | Account Contact Relationship             | Use an eligible role for primary-contact selection (`Principal Owner`, `Owner`, `Authorized Signer`).  | The create path filters to approved responsibility roles.         |
| `Onboarding__c.Vendor_Customization__c` | Onboarding record                        | Confirm it matches the intended vendor program or configured fallback.                                 | Determines requirement set and template assignment context.       |
| `Onboarding__c.Opportunity__c`          | Onboarding record                        | Confirm it references the Opportunity created in the same flow run.                                    | Keeps opportunity-level status and onboarding status aligned.     |
| `Onboarding__c.Contract__c`             | Onboarding record                        | Confirm contract link exists and is the expected contract.                                             | Contract evidence and agreement paths depend on it.               |
| `Onboarding__c.Onboarding_Status__c`    | Onboarding record                        | Expect initial non-terminal status on create; monitor progression after evidence updates.              | Main lifecycle health indicator for sales follow-up.              |

## Scenario Playbooks

### Scenario 1: Standard Program Selection

Use when a seller knows exactly which vendor program should be used.

1. Run create flow and explicitly choose vendor program.
2. Set a valid primary contact.
3. Submit and verify `Onboarding__c.Vendor_Customization__c` equals selected program.

Expected result: onboarding starts with correct requirement scope and no fallback behavior.

### Scenario 2: Default Vendor Fallback (`REQUIRE_NDA`)

Use when path logic returns a scenario requiring fallback vendor selection.

1. Run create flow; do not manually force an out-of-policy program.
2. Flow resolves default from `Onboarding_Default_Vendor_Program__mdt`.
3. Verify created onboarding shows the fallback program.

Expected result: fallback is automatic. If fallback config is missing, flow surfaces a user-facing error and logs technical detail for admin.

### Scenario 3: Primary Contact Cannot Be Selected

Use when the intended contact is not available in signer/primary selection.

1. Check `AccountContactRelation` for active direct relationship.
2. Confirm relationship role is allowed (`Principal Owner`, `Owner`, `Authorized Signer`).
3. Correct relationship data, rerun flow.

Expected result: corrected contact becomes selectable and responsibility paths resolve correctly.

## What To Validate Before Handoff

- Opportunity exists and has expected stage/status.
- Contract exists and is linked to onboarding.
- Onboarding exists and links to account/opportunity/contract.
- Primary OCR is set for the opportunity.
- Vendor program on onboarding matches intent or approved fallback.

## Common User Errors and Fixes

| Issue                              | Typical Cause                                               | Action                                                                |
| ---------------------------------- | ----------------------------------------------------------- | --------------------------------------------------------------------- |
| Flow exits with validation error   | Missing required intake fields                              | Correct required fields and rerun.                                    |
| Onboarding not visible immediately | Deferred onboarding tail is enabled                         | Wait for async completion and refresh.                                |
| Contact cannot be selected         | Contact role/relationship does not meet allowed constraints | Update relationship role or choose eligible contact.                  |
| Fallback vendor error              | No active default vendor metadata for scenario              | Escalate to admin to update `Onboarding_Default_Vendor_Program__mdt`. |
| Agreement send fails               | Integration or contract state issue                         | Retry after admin checks `Error_Log__c` and contract data.            |

## Example Scenario: “Frontier setup”

Example flow for a new sales user:

1. Open the target Opportunity.
2. Run `EXP_Opportunity_SCR_Create_Record`.
3. Choose the intended vendor program (or allow approved fallback path).
4. Set the primary contact to the person accountable for onboarding.
5. Submit, then verify the new `Onboarding__c` has correct Opportunity + Contract links.

## When you need help

Use [Support and Troubleshooting](../support/SUPPORT_AND_TROUBLESHOOTING.md) with record ids, the flow you ran, and any `Error_Log__c` id. Operational context for onboarding specialists is in the [Business User Guide](../business/BUSINESS_USER_GUIDE.md).
