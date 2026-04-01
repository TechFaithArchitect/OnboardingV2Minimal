# Manual Vendor Program Setup (From Scratch)

This guide is for **administrators** defining a **new vendor program** using Salesforce UI and metadata that already exists in the org. In this product, the vendor program record is **`Vendor_Customization__c`** (often labeled “Vendor Program” in the app). It sits under **`Vendor__c`**.

For how this fits into a **minimal end-to-end story** (baseline vs. approvals, next steps, program-specific comms, and more), read [Baseline setup guide](../BASELINE_SETUP_GUIDE.md) and use [FAQ — Admins & Platform](../support/FAQ_ADMINS.md) when you extend beyond that baseline. For **where to click in the Onboarding app** before diving into field tables, use [Baseline UI walkthrough](../BASELINE_UI_WALKTHROUGH.md).

For how communication and template assignment work after the program exists, see [Admin Operations Runbook](./ADMIN_OPERATIONS_RUNBOOK.md). For data relationships, see [Data Model](../technical/DATA_MODEL.md) and [Configuration and Rules](../technical/CONFIGURATION_AND_RULES.md).

## 10-Minute Starter Checklist

If you just need a safe first setup:

1. Create/confirm `Vendor__c` and set `Active__c = true`.
2. Create `Vendor_Customization__c` with stable `Name`, set `Active__c = true`.
3. Add at least one active `Vendor_Program_Requirement__c` with `Sequence__c` and valid `Fulfillment_Policy_Key__c`.
4. Leave advanced fields blank unless your process requires them (`Approval_Policy_Key__c`, group inheritance, special contract paths).
5. Run one onboarding create test and confirm requirements are generated.

Then return to the full sections below for advanced configuration.

## 1. Before you start

- **Vendor identity:** Confirm the **`Vendor__c`** parent exists (or create it first). Set **`Vendor__c.Name`** to the exact name your policies will use: **default vendor resolution** (`Onboarding_Default_Vendor_Program__mdt`) matches programs where **`Vendor__r.Name`** equals the configured vendor name. Keep **`Vendor__c.Active__c`** accurate if your process uses it for filtering.
- **Contract record types:** If this program must use a specific contract record type, ensure the corresponding **`Contract_Record_Type_Reference__c`** row exists before you point the program at it.
- **Fulfillment policy keys:** Requirement rows use text keys that must align with **`Onboarding_Fulfillment_Policy__mdt`** [`Policy_Key__c`](../technical/CONFIGURATION_AND_RULES.md#fulfillment-policies-in-source) values already deployed (for example `ACCOUNT_ONLY`, `ALL_CONTACTS`, `PRINCIPAL_OWNER`, `PRIMARY_CONTACT_OR_ACCOUNT`). Do **not** invent a new key without adding matching CMDT in a deployment.
- **Program “key” for communications:** Event and dispatch policies use **`Vendor_Program_Key__c`**, which the runtime resolves from the program’s **`Name`**: trimmed, uppercased, and **spaces replaced with underscores**. Plan **`Vendor_Customization__c.Name`** so it stays stable and matches the keys you (or your team) put in communication CMDT and template routing. Renaming the program later can silently break program-specific comms until metadata is updated.

Simple example: if program name is `Frontier Retail`, policy key must be `FRONTIER_RETAIL`.

## 2. Create or choose a Vendor Program Group (optional)

Use **`Vendor_Program_Group__c`** when the program belongs to a **governance stack** (shared rules, inheritance, or grouping). For a **standalone** program with no group behavior, you can leave **`Vendor_Customization__c.Vendor_Program_Group__c`** empty.

| Field / area                                                                                     | Fill?                       | Why                                                                                                                       |
| ------------------------------------------------------------------------------------------------ | --------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `Label__c` / name                                                                                | Yes                         | Identifies the group for admins.                                                                                          |
| `Active__c`                                                                                      | Yes, when in use            | Inactive groups should not drive production logic.                                                                        |
| `Rule_Key__c`, `Logic_Type__c`, `Parent_Group__c`, `Requires_NDA__c`, `Requires_Program_Base__c` | Per your eligibility design | These shape group behavior; align with `Vendor_Onboarding_Eligibility_Rule__mdt` and related configuration your org uses. |

The program’s field **`Vendor_Program_Group__c`** documents that **“inheritance”** paths expect a group link—if you rely on inherited requirements from a group model, set it; otherwise optional.

## 3. Create the vendor program (`Vendor_Customization__c`)

Create the record from the **Onboarding** app (or your standard admin entry). Use the following field guidance.

### 3.1 Required or strongly recommended

| Field       | Guidance                                                                            | Why                                                                                                                                                                                                                 |
| ----------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Name**    | **Required.** Pick a **durable**, unique value (not a one-off sentence).            | Drives **communication** policy matching (`Vendor_Program_Key__c`) as described above. Also used when **`Onboarding_Default_Vendor_Program__mdt.Vendor_Program_Name_Contains__c`** narrows programs for a scenario. |
| `Vendor__c` | **Required** (master-detail).                                                       | Program must roll up to a vendor; default-vendor and many queries filter by vendor.                                                                                                                                 |
| `Active__c` | **true** when the program should appear in onboarding flows and default resolution. | Inactive programs are excluded from at least the default vendor program query path and should not be offered for new onboardings.                                                                                   |

### 3.2 Optional but common

| Field                              | Fill?                                                                              | Why                                                                                                                                                                                                                                                                                                                              |
| ---------------------------------- | ---------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Label__c`                         | Optional                                                                           | Short label for quick identification; not a substitute for a deliberate **Name**.                                                                                                                                                                                                                                                |
| `Description__c`                   | Optional                                                                           | Operational notes for admins.                                                                                                                                                                                                                                                                                                    |
| `Business_Vertical__c`             | As needed; **`N/A`** is valid                                                      | Used in filtering and in some resolution paths when multiple programs exist under one vendor.                                                                                                                                                                                                                                    |
| `Retail_Option__c`                 | As needed; **`N/A`** is valid                                                      | Distinguishes retail/channel variants where eligibility or rules depend on it.                                                                                                                                                                                                                                                   |
| `Contract_Record_Type__c`          | Set if this program dictates contract record type                                  | Lookup to **`Contract_Record_Type_Reference__c`**. Leave blank only if your contract path does not depend on this program field.                                                                                                                                                                                                 |
| `Associated_Agreement_Template__c` | Set if this program should default **Adobe EchoSign** agreement template context   | Lookup to **`echosign_dev1__Agreement_Template__c`**. Leave blank if agreement templates are always chosen elsewhere.                                                                                                                                                                                                            |
| `Vendor_Program_Group__c`          | Set if the program participates in that group model                                | See section 2.                                                                                                                                                                                                                                                                                                                   |
| `Approval_Policy_Key__c`           | Set **only** if you use **`Vendor_Program_Approval_Policy__mdt`** for this program | Must match **`Policy_Key__c`** on deployed CMDT rows. Approval gating in requirement creation combines this key with each **`Vendor_Program_Requirement__c.Requirement_Type__c`**. **Leave blank** if you have **no** approval-policy CMDT for this program—no match means blocking rules from that CMDT mechanism do not apply. |

### 3.3 Usually leave blank (unless you have a documented exception)

| Field            | Guidance                      | Why                                                                                                                                                                 |
| ---------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Opportunity__c` | **Leave blank** in most cases | There is no broad automation contract in this repository that requires a program-level opportunity; filling it without a platform-approved use case adds confusion. |

## 4. Add program requirements (`Vendor_Program_Requirement__c`)

Create one row per template requirement that should spawn **`Onboarding_Requirement__c`** rows for onboardings on this program. Order matters: the gate service loads requirements by **`Sequence__c` ascending** (nulls last).

| Field                                  | Guidance                                                | Why                                                                                                                                                                                                                                    |
| -------------------------------------- | ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Vendor_Program__c`                    | **Required** — your new program                         | Owns the template row.                                                                                                                                                                                                                 |
| `Requirement_Type__c`                  | **Required**                                            | Picklist; must align with normalization and status rules your org uses.                                                                                                                                                                |
| `Sequence__c`                          | **Set** (e.g. 10, 20, 30)                               | Defines creation and **approval gate** order (`OnboardingRequirementVPRGateService`).                                                                                                                                                  |
| `Fulfillment_Policy_Key__c`            | **Set** to a deployed policy key                        | Must match **`Onboarding_Fulfillment_Policy__mdt.Policy_Key__c`** (see [Configuration and Rules](../technical/CONFIGURATION_AND_RULES.md#fulfillment-policies-in-source)). Wrong or missing keys break or mis-route subject expansion. |
| `Active__c`                            | **true** for live rows                                  | Inactive templates should not drive new onboarding requirements (confirm with your org’s conventions).                                                                                                                                 |
| `Is_Required__c`                       | Usually **true**                                        | Default in metadata is true; set false only for optional work.                                                                                                                                                                         |
| `Status__c`                            | Use an **active** lifecycle value for production        | Field uses restricted catalog **`Lifecycle_Status_Values`**; prefer values your team treats as “in use” (commonly active-style, not draft/deprecated).                                                                                 |
| `Source_Type__c`                       | Optional                                                | Documents template vs custom provenance for reporting.                                                                                                                                                                                 |
| `Is_Inherited__c` / `Is_Overridden__c` | **Usually false** unless you maintain group inheritance | Leave at defaults for programs created fully manually on this record.                                                                                                                                                                  |

**Contract vs agreement ordering:** Record-triggered automation can enforce **contract/agreement sequence** on requirement updates. If your program mixes contract- and agreement-type requirements, keep **`Sequence__c`** consistent with business intent so gating and sequence rules behave predictably.

## 5. Training links (optional)

If this program includes **LearnUpon / training** assignments driven off program templates:

- Create **`Vendor_Program_Training_Requirement__c`** rows linking **`Vendor_Program__c`** (your `Vendor_Customization__c`) to a **`Training_Requirement__c`** record.
- **`Training_Requirement__c`** is required on each link.
- **`Unique_Key__c`** is optional but is a **unique external id** when set—use a stable dedupe key if you maintain many rows or re-import.

If the program has **no** training-driven onboarding, you can skip this object entirely.

## 6. Communications and templates (per program)

After the program exists:

1. Ensure **`Communication_Template__c`** records exist and are active for the types you send.
2. Create **`Communication_Template_Assignment__c`** rows linking **this vendor program** to each template that applies.
3. Deploy or maintain **`Communication_Event_Policy__mdt`** and **`Communication_Dispatch_Policy__mdt`** with **`Vendor_Program_Key__c`** equal to the **normalized program Name** (uppercase, spaces → `_`), or rely on **`DEFAULT`** only if that is intentional.

Step-by-step for those objects is in [Admin Operations Runbook](./ADMIN_OPERATIONS_RUNBOOK.md#communication-setup-procedure-how-to).

## 7. Scenario fallback (optional)

If business rules sometimes resolve a **default** program without user selection, **`Onboarding_Default_Vendor_Program__mdt`** rows reference **`Vendor_Name__c`** and optionally **`Vendor_Program_Name_Contains__c`** against **`Vendor_Customization__c.Name`**. Add or update CMDT only in a **controlled metadata deployment** so production behavior stays traceable.

## 8. Validate the program

1. **Active vendor + program:** `Vendor__c.Active__c = true` and `Vendor_Customization__c.Active__c = true`.
2. **At least one** active **`Vendor_Program_Requirement__c`** with sensible **`Sequence__c`**, **`Requirement_Type__c`**, and **`Fulfillment_Policy_Key__c`**.
3. Run a **test onboarding** (or your UAT create path) selecting this program and confirm requirements appear in the expected order.
4. If **`Approval_Policy_Key__c`** is set, confirm **`Vendor_Program_Approval_Policy__mdt`** rows exist for the requirement types you expect to gate.
5. Trigger a test **communication** event and confirm templates resolve for the program’s normalized key.

## Related documents

- [Admin Operations Runbook](./ADMIN_OPERATIONS_RUNBOOK.md)
- [Deployment Runbook](./DEPLOYMENT_RUNBOOK.md)
- [Metadata Drift Checklist](./METADATA_DRIFT_CHECKLIST.md)
- [Support and Troubleshooting](../support/SUPPORT_AND_TROUBLESHOOTING.md)
