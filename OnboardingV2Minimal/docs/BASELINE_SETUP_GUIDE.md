# Baseline setup guide (vendor program and first onboarding)

This document describes a **minimal, opinionated path** from **no program** to **first successful onboarding** in a typical org. It is the **reference story** for documentation: other guides and the [FAQ — Admins & Platform](./support/FAQ_ADMINS.md) assume you understand what is **in** the baseline versus what is an **extension**.

**Companion pieces**

- **“Where do I click?” (vendor, program, requirements, first test):** [Baseline UI walkthrough](./BASELINE_UI_WALKTHROUGH.md)
- **Program record setup (manual UI — field semantics):** [Manual Vendor Program Setup](./admin/MANUAL_VENDOR_PROGRAM_SETUP.md)
- **What all the objects mean (tiers):** [Object catalog](./technical/OBJECT_CATALOG.md)
- **What you see in Lightning (components, flows):** [Onboarding UI and custom components](./reference/ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md)
- **Sales create path (who clicks what):** [Sales User Guide](./sales/SALES_USER_GUIDE.md) · [Screen flow click-path runbook](./business/SCREEN_FLOW_CLICK_PATH_RUNBOOK.md)
- **Business rules vs external credentials:** [BRE and credentials primer](./reference/BRE_AND_CREDENTIALS_FOR_NEW_USERS.md)
- **When something breaks or you add complexity:** [FAQ — Admins & Platform](./support/FAQ_ADMINS.md) (scenario index at top)
- **Integrations by environment:** [Environment and integrations matrix](./technical/ENVIRONMENT_AND_INTEGRATIONS_MATRIX.md)
- **Who gets which access:** [Persona and permission sets](./technical/PERSONA_AND_PERMISSION_SETS.md)
- **Releases:** [Release notes and smoke-test template](./admin/RELEASE_NOTES_AND_SMOKE_TEST_TEMPLATE.md)

## What “baseline” means

The baseline is **intentionally simple**. It gets **one vendor**, **one active program**, **template requirements**, and **one happy-path onboarding** working without relying on advanced governance features.

| Included in baseline                                                                                      | Excluded from baseline (extensions)                                                                                                                                                                              |
| --------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Vendor__c` + active **`Vendor_Customization__c`** program                                                | **Approval gates** via `Approval_Policy_Key__c` + `Vendor_Program_Approval_Policy__mdt` → [FAQ scenario: Approval gates](./support/FAQ_ADMINS.md#scenario-approval-gates-and-vendor-program-requirement-policy) |
| **`Vendor_Program_Requirement__c`** rows with valid **`Fulfillment_Policy_Key__c`** and **`Sequence__c`** | **Next Step** UX/rules via `Onboarding_Next_Step_Rule__mdt` → [FAQ scenario: Next step rules](./support/FAQ_ADMINS.md#scenario-next-step-rules-onboarding_next_step_rule__mdt)                                  |
| Optional **email** using **`Vendor_Program_Key__c = DEFAULT`** only (global fallback for all programs)    | **Program-specific** communication keys tied to normalized program **Name** → [FAQ scenario: Program-specific communications](./support/FAQ_ADMINS.md#scenario-program-specific-communications-beyond-default)  |
| No **`Vendor_Program_Group__c`** required (standalone program)                                            | **Groups, prerequisites, eligibility** CMDT → [FAQ scenario: Vendor program groups and eligibility](./support/FAQ_ADMINS.md#scenario-vendor-program-groups-and-eligibility)                                     |
| Status behavior matches **deployed** normalization + evaluation CMDT (no custom tuning in this doc)       | **Tuning** status order or predicates → [FAQ scenario: Status rules](./support/FAQ_ADMINS.md#scenario-status-normalization-and-evaluation-rules)                                                                |
| First test may **skip** Adobe Sign / LearnUpon if your template requirements do not force those paths     | **Adobe / LearnUpon / template sync** operational setup → [FAQ scenario: Integrations](./support/FAQ_ADMINS.md#scenario-integrations-adobe-learnupon-email-catalog)                                             |
| Accept default **async** onboarding tail as configured in **`Onboarding_Performance_Config__mdt`**        | **Diagnosing** slow creation / queue backlog → [FAQ scenario: Performance and async](./support/FAQ_ADMINS.md#scenario-performance-async-tail-and-queueables)                                                    |

If you need a row in the right-hand column, use the linked FAQ scenario for **what it means**, **what to configure**, and **how it interacts** with the baseline.

## Baseline workflow (ordered)

### Step 0 — Access and environment

1. Confirm testers have the correct **permission sets** ([Persona and permission sets](./technical/PERSONA_AND_PERMISSION_SETS.md)).
2. Fill in—or verify—your org row(s) in the [environment and integrations matrix](./technical/ENVIRONMENT_AND_INTEGRATIONS_MATRIX.md) so support knows which connectors apply.

### Step 1 — Vendor and program (manual)

For a **UI click order** before the field-by-field manual, start with [Baseline UI walkthrough](./BASELINE_UI_WALKTHROUGH.md). Then follow [Manual Vendor Program Setup](./admin/MANUAL_VENDOR_PROGRAM_SETUP.md) through:

- **`Vendor__c`** (name stable for any future default-vendor CMDT you add later),
- **`Vendor_Customization__c`** with **`Active__c = true`**,
- **`Approval_Policy_Key__c` left blank** for baseline (no approval-gate CMDT),
- **`Vendor_Program_Group__c` left blank** unless you already committed to group-based eligibility (if so, read the [eligibility FAQ](./support/FAQ_ADMINS.md#scenario-vendor-program-groups-and-eligibility) first).

### Step 2 — Program requirements

Create **`Vendor_Program_Requirement__c`** rows for that program:

- **`Requirement_Type__c`** and **`Fulfillment_Policy_Key__c`** must align with deployed CMDT ([Configuration and Rules](./technical/CONFIGURATION_AND_RULES.md)).
- Set **`Sequence__c`** in clear increments (for example 10, 20, 30) so ordering is obvious before you add approval gates later.

### Step 3 — Communications (optional for baseline)

- Minimum: none required for **record creation**.
- If you want simple email behavior, use **`Vendor_Program_Key__c = DEFAULT`** in communication policy metadata.
- `DEFAULT` means: “use this rule for every vendor program unless a program-specific key exists.”
- Add program-specific keys later only when you truly need different behavior per program ([FAQ](./support/FAQ_ADMINS.md#scenario-program-specific-communications-beyond-default)).

### Step 4 — First onboarding

1. Run the opportunity-led create path per [Sales User Guide](./sales/SALES_USER_GUIDE.md).
2. Optional: use [Screen flow click-path runbook](./business/SCREEN_FLOW_CLICK_PATH_RUNBOOK.md) to document screenshots for your org.
3. Confirm **Onboarding**, **Requirements**, and (where applicable) **Subjects** appear; see [Manual Vendor Program Setup § Validate](./admin/MANUAL_VENDOR_PROGRAM_SETUP.md#8-validate-the-program).

### Step 5 — Release discipline (when promoting beyond a sandbox)

Use [Release notes and smoke-test template](./admin/RELEASE_NOTES_AND_SMOKE_TEST_TEMPLATE.md) with [Deployment Runbook](./admin/DEPLOYMENT_RUNBOOK.md).

## After the baseline

| Goal                                                                      | Where to go                                                                                    |
| ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| User can’t complete intake / errors                                       | [FAQ — Users](./support/FAQ_USERS.md)                                                         |
| Platform triage / Error_Log                                               | [FAQ — Admins](./support/FAQ_ADMINS.md) (incident-style questions at bottom of that page)     |
| Add approvals, next steps, program comms keys, groups, integrations depth | [FAQ — Admins: scenario index](./support/FAQ_ADMINS.md#scenario-index-extending-the-baseline) |

## Related

- [Business Process Guide](./business/BUSINESS_PROCESS_GUIDE.md)
- [System Overview](./technical/SYSTEM_OVERVIEW.md)
- [Data Model](./technical/DATA_MODEL.md)
