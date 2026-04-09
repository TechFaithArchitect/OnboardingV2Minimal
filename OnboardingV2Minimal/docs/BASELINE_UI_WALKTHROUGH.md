# Baseline UI walkthrough (where to click)

Use this guide when you need a **task-first** path: **open this app, click this tab, press New**, then validate. It pairs with the **conceptual** baseline story in [Baseline setup guide](./BASELINE_SETUP_GUIDE.md), which explains what is in or out of baseline and links to extension scenarios in the FAQ.

| If you are asking…                                                                             | Read this page | For field meanings and baseline vs extensions |
| ---------------------------------------------------------------------------------------------- | -------------- | --------------------------------------------- |
| Where do I click to set up a vendor and program?                                               | ✅ Below       | [Manual vendor program setup](./admin/MANUAL_VENDOR_PROGRAM_SETUP.md) |
| What objects are involved and what does “baseline” exclude (approvals, groups, program comms)? | Link only      | [Baseline setup guide](./BASELINE_SETUP_GUIDE.md) |
| How does Sales create the first onboarding from an Opportunity?                                | Summary below  | [Sales User Guide](./sales/SALES_USER_GUIDE.md) · [Screen flow click-path runbook](./business/SCREEN_FLOW_CLICK_PATH_RUNBOOK.md) |
| What do I see on Lightning record pages (components, related lists)?                           | Link           | [Onboarding UI and custom components](./reference/ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md) |

**App:** Use the **Onboarding** Lightning console app (see [Onboarding.app-meta.xml](../force-app/main/default/applications/Onboarding.app-meta.xml) for tab order). Tab labels in your org may use Salesforce’s plural names (for example **Vendors** for `Vendor__c`).

---

## 1. Open the Onboarding app

1. In the App Launcher (waffle), search for **Onboarding** and open it.
2. You should see tabs such as **Home**, **Onboardings**, **Accounts**, **Vendors**, the vendor program tab (often labeled **Vendor Programs** or similar for `Vendor_Customization__c`), **Vendor Program Requirements**, and others depending on your org.

If a tab is missing, check **permission sets** and tab visibility ([Persona and permission sets](./technical/PERSONA_AND_PERMISSION_SETS.md)).

---

## 2. How do I set up or confirm a vendor?

**Goal:** An active **`Vendor__c`** record that your program will point to.

1. In the Onboarding app, open the **Vendors** tab (`Vendor__c`).
2. Use list views or search to see if the vendor already exists.
3. If you need a new one: click **New**, set at least **Vendor Name** (and **Active** = checked if your process relies on active vendors), then **Save**.
4. Prefer a **stable name**: default vendor resolution and some metadata match on vendor name ([Manual vendor program setup § Before you start](./admin/MANUAL_VENDOR_PROGRAM_SETUP.md#1-before-you-start)).

---

## 3. How do I set up a new vendor program?

**Goal:** An active **`Vendor_Customization__c`** row linked to that vendor (the product’s “vendor program” record).

1. In the Onboarding app, open the tab for vendor programs (API **`Vendor_Customization__c`**; label is often **Vendor Program(s)**).
2. Click **New**.
3. Fill **Name** (required, durable—drives communication keys when you use program-specific policies), **Vendor** (lookup to your `Vendor__c`), and set **Active**.
4. For a **minimal baseline**, leave **Approval Policy Key** blank and leave **Vendor Program Group** blank unless you already use group-based eligibility ([baseline vs extensions](./BASELINE_SETUP_GUIDE.md#what-baseline-means)).
5. **Save**.

**Deeper field-by-field guidance:** [Manual vendor program setup § Create the vendor program](./admin/MANUAL_VENDOR_PROGRAM_SETUP.md#3-create-the-vendor-program-vendor_customization__c).

**Optional — open the program from the vendor:** You can also open your **`Vendor__c`** record and use the **Related** list or sub-tabs for vendor programs (layout-dependent), then **New Vendor Program** if that action exists.

---

## 4. How do I add requirements to the program?

**Goal:** At least one active **`Vendor_Program_Requirement__c`** row with valid type, **Sequence**, and **Fulfillment Policy Key** aligned to deployed CMDT.

1. Open the **Vendor Program Requirements** tab (`Vendor_Program_Requirement__c`), or stay on the vendor program record and use the related list for program requirements if your page layout exposes it.
2. Click **New**.
3. Set **Vendor Program** to the program you just created, **Requirement Type**, **Fulfillment Policy Key** (must match [Configuration and rules](./technical/CONFIGURATION_AND_RULES.md)), **Sequence** (for example 10, 20, 30), and **Active** as appropriate.
4. **Save**. Repeat for each template requirement.

**Why these fields matter:** [Manual vendor program setup § Add program requirements](./admin/MANUAL_VENDOR_PROGRAM_SETUP.md#4-add-program-requirements-vendor_program_requirement__c).

---

## 5. Communications (optional for baseline)

You do **not** need communication rows to **create** onboarding records for a first test. If you want email behavior later, start with **DEFAULT** program keys in policy metadata ([Baseline setup guide — Step 3](./BASELINE_SETUP_GUIDE.md#step-3--communications-optional-for-baseline)). Operational steps for templates and assignments: [Admin operations runbook](./admin/ADMIN_OPERATIONS_RUNBOOK.md#communication-setup-procedure-how-to).

---

## 5A. How do I configure required external credentials (ECC) for this program?

Use this when the program needs credential values (for example login usernames/codes) per contact.

`ECC Type` = `External_Contact_Credential_Type__c`.

1. Open **External Contact Credential Types** (`External_Contact_Credential_Type__c`) and click **New**.
2. Create shared **ECC Type** rows (`Name`, `Active`, `Sort Order`).
3. Open **Required Credentials** (`Required_Credential__c`) and click **New**.
4. Set **Vendor Customization** (your program) + **ECC Type** (`External_Contact_Credential_Type__c`) + **Sequence** + **Is Required**.
5. Save and repeat for each required type.
6. Run one onboarding create test; confirm ECC evidence rows exist for the onboarding contact and are scoped to the program.

If sending credential emails, use ECC tokens in the template (for example `{{ECC_VALUE:Username N#}}`) and dispatch via `OnboardingEccEmailDispatchInvocable`.
Advanced token form is also supported: `{{ECC_VALUE:<TypeLookupKey>|<FieldApiName>}}` (for example `{{ECC_VALUE:SSO_LOGIN|POE_N_Number__c}}`).

---

## 6. How do I run a first test onboarding?

**Goal:** Prove requirements materialize on an **Onboarding** for your new program.

**Sales-led path (typical):**

1. Open an **Opportunity** (and Account) your test user can access—often via **Sales** app or global search; the Onboarding app also includes standard **Account** if configured for your profile.
2. Launch the screen flow **`EXP_Opportunity_SCR_Create_Record`** (button or action label may differ per org).
3. Complete intake, select your **vendor program**, set **primary contact** per policy, and finish through contract/opportunity outcomes.
4. Open the resulting **Onboarding** record (related list, **Onboardings** tab, or search) and confirm **Vendor Program** and **Requirements** match expectations.

**Click-path template for screenshots:** [Screen flow click-path runbook](./business/SCREEN_FLOW_CLICK_PATH_RUNBOOK.md). **Concepts and handoff checks:** [Sales User Guide](./sales/SALES_USER_GUIDE.md).

**If onboarding appears late:** Async tail may be enabled—refresh after a short wait ([FAQ — Users](./support/FAQ_USERS.md)).

---

## 7. Validate (baseline checklist)

Use the same checks as the manual guide: active vendor + program, at least one sensible program requirement, successful test create ([Manual vendor program setup § Validate](./admin/MANUAL_VENDOR_PROGRAM_SETUP.md#8-validate-the-program)).

---

## 8. Quick “where is it?”

| I need…                   | Typical place in Onboarding app        |
| ------------------------  | -------------------------------------- |
| Vendor                    | **Vendors** tab                        |
| Vendor program            | **Vendor Program(s)** tab (or related list on Vendor) |
| Template requirements     | **Vendor Program Requirements** tab or related list on program |
| One onboarding record     | **Onboardings** tab or Opportunity/Account related lists |
| Per-requirement rows      | Onboarding record → **Onboarding Requirements** related list / component |

When something fails or you extend beyond baseline (approvals, groups, integrations), use [FAQ — Admins & Platform](./support/FAQ_ADMINS.md) scenario index.

## Related

- [Baseline setup guide](./BASELINE_SETUP_GUIDE.md)
- [Manual vendor program setup](./admin/MANUAL_VENDOR_PROGRAM_SETUP.md)
- [Object catalog](./technical/OBJECT_CATALOG.md)
