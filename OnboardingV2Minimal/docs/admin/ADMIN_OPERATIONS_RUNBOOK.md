# Admin Operations Runbook

For user-reported incidents and first-pass symptom routing, see [Support and Troubleshooting](../support/SUPPORT_AND_TROUBLESHOOTING.md). For release and org parity discipline, see [Metadata Drift Checklist](./METADATA_DRIFT_CHECKLIST.md) and [Deployment Runbook](./DEPLOYMENT_RUNBOOK.md). For defining a **new vendor program** manually (fields, order, comms keys), see [Manual Vendor Program Setup](./MANUAL_VENDOR_PROGRAM_SETUP.md). For the **full minimal onboarding story** and links into extension scenarios, see [Baseline setup guide](../BASELINE_SETUP_GUIDE.md).

## New Admin Quick Start

If you are new to operations:

1. Do the Daily Checks.
2. Confirm communication rules in the Communication Configuration section.
3. Run one test onboarding and verify requirement + status + communication behavior.

## Daily Checks

### 1) Automation Health

- Review `Error_Log__c` for new failures.
- Filter by provider `OnboardingV2` and subtype for triage priority.
- Validate no repeated fault loops for the same record.

### 2) Fault Monitoring Health

- Monitor `Error_Log__c` trend volume by type/subtype.
- Confirm no repeated fault patterns for the same automation context.

### 3) Lifecycle Continuity

- Spot check onboarding records with stale statuses.
- Verify requirement and subject rows are advancing from new evidence updates.

## Weekly Checks

- Verify CMDT records still align with business policy.
- Review onboarding status rules for unintended precedence changes.
- Validate communication policy records and template availability.
- Confirm deferred onboarding tail behavior is stable.

## Communication Configuration (Where To Set Rules)

Use these three admin configuration points together:

1. `Communication_Event_Policy__mdt`

- Purpose: decide **when** to send and **what kind of message** to send.
- Key fields: `Event_Key__c`, `Communication_Type__c`, `Vendor_Program_Key__c`, `Dispatch_Order__c`, `Send_Enabled__c`, `Active__c`.

2. `Communication_Dispatch_Policy__mdt`

- Purpose: decide **who is allowed to receive** that message type (`Contact`, `PrincipalOwner`, `Agent`).
- Key fields: `Communication_Type__c`, `Recipient_Type__c`, `Vendor_Program_Key__c`, `Send_Enabled__c`, `Active__c`.

3. `Communication_Template_Assignment__c`

- Purpose: decide **which template record** can be used for a vendor program.
- Key fields: `Vendor_Program__c`, `Communication_Template__c`, `Active__c`.

Plain-English key rule:

- `Vendor_Program_Key__c = DEFAULT` means "global rule for all programs."
- A program-specific key only overrides `DEFAULT` for that one program.
- Org-Wide Email Address is only the "from address" setting; it is not a policy key.

Operational behavior:

- Onboarding lifecycle sends are event-driven.
- Reminder sends are schedule-driven by `BLL_Training_Assignment_SCD_Training_Reminder_Emails`.
- Current source does not include a separate communication event trigger directly on `Onboarding_Requirement__c`.

## Communication Setup Procedure (How To)

### Procedure A: Add/Change Event-Driven Email Behavior

1. Decide the event key and meaning (example: `SetupComplete`, `LearnUponTriggered`).
2. Create/update `Communication_Event_Policy__mdt` rows for that event and communication type.
3. Create/update `Communication_Dispatch_Policy__mdt` rows for each recipient type you want to allow.
4. Ensure target `Communication_Template__c` records exist and are `Active__c = true`.
   - Optional internal-copy routing: set `BCC_User_Ids__c` and/or `BCC_Public_Group_DeveloperNames__c` on the template.
   - Both fields accept comma, semicolon, or newline-separated values.
5. Create/update `Communication_Template_Assignment__c` rows linking templates to vendor program.
6. Validate in UAT with one positive and one blocked-recipient test case.

Why this order matters (simple view):

- Event policy = when/type.
- Dispatch policy = who can receive.
- Template assignment = which actual email template is used.

### Procedure B: Add New Event Key

1. Add the new value to `Communication_Event_Policy__mdt.Event_Key__c` picklist metadata.
2. Deploy metadata change.
3. Add `Communication_Event_Policy__mdt` rows using that new key.

Reason: `Event_Key__c` is a strict picklist; new keys are not data-only changes.

### Procedure C: Configure ECC-Token Email (Type + Value Merge at Send-Time)

Use this when your email body needs credential values from `POE_External_Contact_Credential__c` (for example Username N# and Pin IDIQ) without copying those values onto Contact fields first.

`ECC Type` = `External_Contact_Credential_Type__c` (type name used in dynamic tokens).

1. Build or update a Salesforce Email Template (the actual `00X...` template):
   - Add ECC tokens in subject/body where values should appear.
   - Example: `{{ECC_VALUE:Username N#}}`, `{{ECC_VALUE:Pin IDIQ}}`.
   - Advanced syntax: `{{ECC_VALUE:<TypeLookupKey>|<FieldApiName>}}` and `{{ECC_TYPE_VALUE:<TypeLookupKey>|<FieldApiName>}}`.
   - Prefer `<TypeLookupKey> = External_Contact_Credential_Type__c.Unique_Key__c`.
   - If the type key itself contains `|` (for example `GLOBAL|SSO ID`), field syntax remains valid: `{{ECC_VALUE:GLOBAL|SSO ID|POE_N_Number__c}}`.
   - Optional table token: `{{ECC_TYPE_VALUE_TABLE}}`.
   - If label and ECC Type name differ, keep label static and put the ECC Type in the token (example: `<strong>Username N#:</strong> {{ECC_VALUE:SSO ID}}`).
   - `{{ECC_TYPE_VALUE:SSO ID}}` renders both label and value in one token (`SSO ID: <value>`).
   - Allowed `<FieldApiName>` values: `POE_Username__c`, `POE_N_Number__c`, `POE_Code__c`, `POE_Process_Status__c`, `Training_Sent_Date__c`, `Activation_Date__c`, `POE_Program__c`.
2. Create or update `Communication_Template__c`:
   - `Active__c = true`
   - `Email_Template_Id__c =` Salesforce Email Template Id (`00X...`)
   - `Communication_Type__c` and `Recipient_Type__c` aligned to your event/route policy.
   - Optional internal BCC:
     - `BCC_User_Ids__c =` internal User Id list (`005...`)
     - `BCC_Public_Group_DeveloperNames__c =` Public Group `DeveloperName` list
3. Create or update `Communication_Template_Assignment__c` for the target `Vendor_Program__c`.
4. Ensure policy rows allow the send:
   - `Communication_Event_Policy__mdt` row for the event/type/program key.
   - `Communication_Dispatch_Policy__mdt` row for the type/recipient/program key.
5. In the sending flow, invoke `OnboardingEccEmailDispatchInvocable` (Apex action label: `Dispatch ECC Email (Per Contact)`) once per recipient/template row:
   - Required inputs:
     - `recipientContactId`
     - `communicationTemplateId` (Id of `Communication_Template__c`)
   - Context input:
     - `onboardingId` for onboarding-linked contacts, or
     - `vendorProgramId` for agent/no-onboarding sends.
   - Optional:
     - `defaultSenderAddress` (must match an Org-Wide Email Address to apply),
     - `appendPayloadWhenTokensMissing` (default `true`).
6. Validate with one controlled record:
   - Confirm output result `ranSuccessfully = true`.
   - Confirm email renders credential values where tokens were placed.
   - If a credential row is missing, token output should show `Missing`.

Notes:

- Existing bulk communication action `CommunicationTemplateBulkSendAction` sends templates but does not inject ECC token payloads.
- For ECC token merge behavior, use `OnboardingEccEmailDispatchInvocable`.
- Both send paths honor template-level BCC (`BCC_User_Ids__c`, `BCC_Public_Group_DeveloperNames__c`).
- Invalid BCC user-id tokens or missing public groups are skipped and logged in action diagnostics.

## Field Guide: Communication Event Policy (`Communication_Event_Policy__mdt`)

| Field                   | How To Fill                                                                            | Why It Matters                                            |
| ----------------------- | -------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| `Event_Key__c`          | Use the exact event token your flow/apex dispatch uses.                                | If key mismatches dispatch input, no policy row is found. |
| `Communication_Type__c` | Set type (`Welcome`, `Training`, `Completion`, etc.) consistent with template records. | Drives template filtering and dispatch policy lookup.     |
| `Vendor_Program_Key__c` | Use `DEFAULT` for global behavior, or a normalized program key for overrides.          | Program-specific rows override `DEFAULT` for that program. |
| `Dispatch_Order__c`     | Set numeric order (10, 20, 30...) for multi-send events.                               | Controls deterministic send sequence.                     |
| `Send_Enabled__c`       | `true` to allow this event/type pair, `false` to block.                                | Fast operational toggle without deletion.                 |
| `Active__c`             | Keep `true` for active row, set `false` to retire.                                     | Prevents stale config from being evaluated.               |

## Field Guide: Communication Dispatch Policy (`Communication_Dispatch_Policy__mdt`)

| Field                   | How To Fill                                       | Why It Matters                                          |
| ----------------------- | ------------------------------------------------- | ------------------------------------------------------- |
| `Communication_Type__c` | Match event policy communication type exactly.    | Mismatch causes unintended block/no-send.               |
| `Recipient_Type__c`     | Set route (`Contact`, `PrincipalOwner`, `Agent`). | Controls which recipient channel can send.              |
| `Vendor_Program_Key__c` | `DEFAULT` for global, or a normalized program key | Lets you override recipient rules for one program only. |
| `Send_Enabled__c`       | `true` allow, `false` block.                      | Policy gate for recipient routes.                       |
| `Active__c`             | `true` for active rule.                           | Inactive rules are ignored.                             |

## Field Guide: Communication Template Assignment (`Communication_Template_Assignment__c`)

| Field                             | How To Fill                                              | Why It Matters                                        |
| --------------------------------- | -------------------------------------------------------- | ----------------------------------------------------- |
| `Vendor_Program__c`               | Select vendor program receiving this template mapping.   | Defines per-program template catalog.                 |
| `Communication_Template__c`       | Select template record to include for this program.      | Provides concrete email template candidate.           |
| `Active__c`                       | Set true for in-use mapping.                             | Inactive mappings are skipped in template resolution. |
| `Communication_Template_Label__c` | Auto label from template name (read-only display).       | Improves related-list readability.                    |
| `Vendor_Program_Label__c`         | Auto label from vendor program name (read-only display). | Improves related-list readability.                    |

## Field Guide: Communication Template (`Communication_Template__c`)

| Field                   | How To Fill                                                          | Why It Matters                                         |
| ----------------------- | -------------------------------------------------------------------- | ------------------------------------------------------ |
| `Name`                  | Business-readable template name.                                     | Used by admins in assignment and troubleshooting.      |
| `Active__c`             | `true` for sendable templates.                                       | Inactive templates are excluded from send selection.   |
| `Communication_Type__c` | Match event policy type.                                             | Required for policy-to-template alignment.             |
| `Recipient_Type__c`     | Match intended route (`Contact`, `PrincipalOwner`, `Agent`, `User`). | Ensures correct recipient strategy.                    |
| `Email_Template_Id__c`  | Salesforce Email Template Id (`00X...`).                             | Bulk send action cannot send without this.             |
| `BCC_User_Ids__c`       | Optional internal User Id list (`005...`).                           | Adds template-level BCC recipients without changing the main recipient route. |
| `BCC_Public_Group_DeveloperNames__c` | Optional Public Group `DeveloperName` list.                       | Expands group members (including nested groups) to active users with emails for template-level BCC. |
| `Send_Order__c`         | Optional within-type ordering.                                       | Controls ordering when multiple templates are in play. |

## Default Vendor Program Setup

Configure fallback vendor-program selection in `Onboarding_Default_Vendor_Program__mdt`.

Required fields per row:

- `Scenario_Key__c` (example: `REQUIRE_NDA`)
- `Vendor_Name__c` (must match `Vendor__r.Name`)
- `Active__c = true`

Optional narrowing:

- `Vendor_Program_Name_Contains__c` (token matched against active `Vendor_Customization__c.Name`)

Runtime notes:

- `EXP_Opportunity_SCR_Create_Record` calls `OnboardingDefaultVendorProgramInvocable`.
- If no active matching row exists, flow returns a user-facing default-vendor resolution error.

## Field Guide: Default Vendor Program CMDT (`Onboarding_Default_Vendor_Program__mdt`)

| Field                             | How To Fill                                                               | Why It Matters                                               |
| --------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `Scenario_Key__c`                 | Use exact scenario token returned by path logic (example: `REQUIRE_NDA`). | Key used for runtime lookup.                                 |
| `Vendor_Name__c`                  | Exact `Vendor__c.Name` value.                                             | Runtime query filters active vendor programs by vendor name. |
| `Vendor_Program_Name_Contains__c` | Optional token for narrowing when multiple active programs exist.         | Avoids ambiguous default selection.                          |
| `Active__c`                       | Set true for the row that should resolve.                                 | Inactive rows are ignored.                                   |

## Scenario Playbooks

### Scenario 1: Send Welcome + Completion On Setup Complete

1. Ensure event policy rows exist for `Event_Key__c = SetupComplete` with `Communication_Type__c = Welcome` and `Completion`.
2. Ensure dispatch policy allows intended recipient routes for both types.
3. Ensure assigned templates are active and mapped to program.
4. Execute test onboarding to `Setup Complete` and verify send logs/outcome.

### Scenario 2: Block Agent Sends But Keep Contact Sends

1. Set dispatch policy `Recipient_Type__c = Agent`, `Send_Enabled__c = false`.
2. Keep contact dispatch policy row enabled.
3. Validate same event sends to contact but not agent.

### Scenario 3: Fallback Vendor Not Resolving

1. Check active CMDT row exists for `Scenario_Key__c`.
2. Validate `Vendor_Name__c` exactly matches current vendor name.
3. If multiple active programs exist, set `Vendor_Program_Name_Contains__c`.
4. Re-test flow and verify resolved vendor program on created onboarding.

## Reference: manifests and deployment scripts

Use these when reconciling what **source** expects versus what an org contains (aligns with [Deployment Runbook](./DEPLOYMENT_RUNBOOK.md)):

- **`manifest/`** — package and destructive-change manifests (see folder README files per package).
- **`scripts/deploy/`** — `sf` wrappers for validate, deploy, post-deploy checks, and the [hardening test sweep](../../scripts/deploy/run-best-practices-in-scope-tests.sh).
- **`scripts/automation/`** — read-only audits (flow fault messaging, subflow error contracts, Apex entry sharing, PMD driver).
- **`docs/technical/best-practices-findings.md`** — prioritized hardening checklist and validation history.

## Incident Triage Procedure

1. Gather record ids from user report.
2. Locate related `Error_Log__c` entries.
3. Identify source flow/element and context key.
4. Classify issue type: data issue, configuration issue, automation regression, or integration outage.
5. Apply fix path and document root cause.

## Core Objects for Admin Monitoring

- `Onboarding__c`
- `Onboarding_Requirement__c`
- `Onboarding_Requirement_Subject__c`
- `Error_Log__c`
- `POE_External_Contact_Credential__c`
- `Training_Assignment__c`
- `Training_Assignment_Onboarding__c`

## Recovery Patterns

- Re-run safe/idempotent automation where available
- Use subject unique key model to avoid duplicates on retries
- Re-evaluate parent requirements in bulk using invocable paths
- Re-evaluate onboarding status after data correction
