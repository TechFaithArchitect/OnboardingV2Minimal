# Business User Guide

## If You Only Read One Section

Daily success pattern:

1. Open an `Onboarding__c` record.
2. Check requirement rows and subject rows.
3. If status looks wrong, check `Error_Log__c` (if you have access) and escalate with ids.

This catches most issues early without needing Flow debug tools.

## Where in Salesforce

- **App:** open the **Onboarding** Lightning console app (label from [Onboarding.app-meta.xml](../../force-app/main/default/applications/Onboarding.app-meta.xml)).
- **Primary tabs:** include Onboarding, Account, Contact, Contract, Vendor, Vendor Program (customization), Onboarding Requirement, Communication Template, and related standard/custom objects configured on the app.
- **Daily work:** use **Onboarding** and related lists for `Onboarding__c`, `Onboarding_Requirement__c`, and `Onboarding_Requirement_Subject__c`; use **Error Log** when automation health is in question.
- **Sales-led creation** (handoff context): onboarding is often created via the screen flow `EXP_Opportunity_SCR_Create_Record` from opportunity context — see [Sales User Guide](../sales/SALES_USER_GUIDE.md).

If behavior looks wrong after verifying data, start with [FAQ — Sales and Business Users](../support/FAQ_USERS.md), then [Support and Troubleshooting](../support/SUPPORT_AND_TROUBLESHOOTING.md). For communication rules and CMDT, see [Admin Operations Runbook](../admin/ADMIN_OPERATIONS_RUNBOOK.md).

## Who This Is For

- Onboarding specialists
- Compliance operators
- Account services users
- Customer service users supporting onboarding cases

## Daily Operating Workflow

| Step | What To Do                                                         | Why This Matters                                             |
| ---- | ------------------------------------------------------------------ | ------------------------------------------------------------ |
| 1    | Review new/active `Onboarding__c` records.                         | Confirms records entered lifecycle and are linked correctly. |
| 2    | Review related `Onboarding_Requirement__c` records.                | Ensures required work is progressing and not stalled.        |
| 3    | Review `Onboarding_Requirement_Subject__c` rows.                   | Verifies responsibility and per-subject completion behavior. |
| 4    | Review exceptions in `Error_Log__c` when status appears incorrect. | Distinguishes data issue vs automation issue quickly.        |

## Quick “Is This Healthy?” Checklist

- Onboarding has Account, Opportunity, and Contract links populated (where expected).
- At least one requirement exists for the selected vendor program.
- Requirement subjects exist for contact/account responsibility when policy expects them.
- No unexplained recent `Error_Log__c` entries tied to this onboarding.

## Field Guide: Onboarding Record

| Field                                         | How To Use It                                                        | Why It Matters                                                                  |
| --------------------------------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `Onboarding__c.Account__c`                    | Confirm account linkage is correct.                                  | Recipient expansion and account-level responsibility depend on account context. |
| `Onboarding__c.Opportunity__c`                | Confirm opportunity linkage is present and expected.                 | Opportunity stage/ownership context can influence downstream logic.             |
| `Onboarding__c.Contract__c`                   | Confirm contract linkage is present when required.                   | Contract evidence participates in status evaluation.                            |
| `Onboarding__c.Vendor_Customization__c`       | Confirm selected/fallback vendor program is correct.                 | Controls requirement creation scope and communications.                         |
| `Onboarding__c.Onboarding_Status__c`          | Track progression over time; do not manually force lifecycle states. | Status is rule-evaluated from evidence and precedence.                          |
| `Onboarding__c.Assigned_Team__c`              | Confirm work is routed to expected team.                             | Helps avoid ownership gaps.                                                     |
| `Onboarding__c.Onb_Reqs_Awaiting_Approval__c` | Check when onboarding appears paused for approvals.                  | Indicates approval-gated requirement creation path.                             |

## Field Guide: Onboarding Requirement

| Field                                                 | How To Use It                                                  | Why It Matters                                                      |
| ----------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------- |
| `Onboarding_Requirement__c.Status__c`                 | Monitor current lifecycle state per requirement.               | Feeds onboarding-level status evaluation.                           |
| `Onboarding_Requirement__c.Completed__c`              | Confirm completion flag aligns with subject/evidence state.    | Prevents false-positive setup completion.                           |
| `Onboarding_Requirement__c.Due_Date__c`               | Monitor deadline-sensitive requirements.                       | Supports operational prioritization and follow-up.                  |
| `Onboarding_Requirement__c.Requirement_Type__c`       | Use for grouping (Compliance, Agreement, etc.).                | Different requirement types map to different evidence/status logic. |
| `Onboarding_Requirement__c.Fulfillment_Policy_Key__c` | Validate policy key if responsibility expansion appears wrong. | Drives subject expansion model.                                     |
| `Onboarding_Requirement__c.Sequence__c`               | Use for expected processing order review.                      | Helps troubleshoot gating/order issues.                             |

## Field Guide: Onboarding Requirement Subject

| Field                                                         | How To Use It                                                        | Why It Matters                                              |
| ------------------------------------------------------------- | -------------------------------------------------------------------- | ----------------------------------------------------------- |
| `Onboarding_Requirement_Subject__c.Onboarding_Requirement__c` | Confirm subject points to intended requirement.                      | Prevents cross-requirement confusion.                       |
| `Onboarding_Requirement_Subject__c.Contact__c`                | Confirm contact-assigned responsibility where expected.              | Contact-level completion depends on this link.              |
| `Onboarding_Requirement_Subject__c.Account__c`                | Confirm account-level subject when policy requires account fallback. | Supports non-contact responsibility paths.                  |
| `Onboarding_Requirement_Subject__c.Role_Snapshot__c`          | Validate role captured at expansion time.                            | Useful for role-history troubleshooting.                    |
| `Onboarding_Requirement_Subject__c.Status__c`                 | Track per-subject evidence progress.                                 | Parent requirement rollup is derived from subject outcomes. |
| `Onboarding_Requirement_Subject__c.Unique_Key__c`             | Use for dedupe/idempotency troubleshooting with admins.              | Protects against duplicate subject creation.                |

## Scenario Playbooks

### Scenario 1: Requirement Looks Complete But Onboarding Is Not Setup Complete

1. Check all `Onboarding_Requirement__c.Status__c` rows for the onboarding.
2. Confirm no requirements remain in non-terminal status.
3. Check related `Onboarding_Requirement_Subject__c.Status__c` rows for stuck subjects.
4. Review `Error_Log__c` for recent evaluator/subject faults.

Expected result: identify whether issue is data incompleteness or automation failure.

### Scenario 2: Responsibility Looks Wrong (Wrong Contact or Missing Subject)

1. Open requirement and subject rows.
2. Validate `Fulfillment_Policy_Key__c` on requirement.
3. Validate `Contact__c`, `Account__c`, and `Role_Snapshot__c` on subjects.
4. Escalate with record ids if policy/data mismatch is confirmed.

Expected result: policy or role-data correction request can be made with clear evidence.

### Scenario 3: Default Vendor Fallback Path

When onboarding path returns a default-vendor scenario, the program is selected from metadata automatically.

If fallback resolution fails, the user sees onboarding-flow error text and admins must verify `Onboarding_Default_Vendor_Program__mdt` setup.

## Understanding Status Changes

Onboarding status changes are rule-driven, not manually sequenced. Final status reflects:

- normalized requirement evidence
- rule order precedence
- first matching active status rule

## Escalation Data Checklist

Provide the following in escalation tickets:

- Onboarding record id
- Requirement and subject ids affected
- Expected status versus actual status
- Timestamp of issue
- `Error_Log__c` id (if available)
- Recent user action path (screen flow or record update)

For triage patterns and escalation data, see [Support and Troubleshooting](../support/SUPPORT_AND_TROUBLESHOOTING.md).
