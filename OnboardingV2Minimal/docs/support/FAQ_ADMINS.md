# FAQ — Admins and Platform

**When users report a break**, use the **incident-style** questions in the [second half of this page](#incident-style-faqs-something-broke). For **adding features** beyond the minimal path, start with the **scenario index** below.

**Baseline story (read first):** [Baseline setup guide: vendor program and first onboarding](../BASELINE_SETUP_GUIDE.md) defines setup **without** approval gates, next-step rules, program-specific comms keys, or vendor-group complexity. This FAQ explains **what those features mean**, **how to configure them**, and **how they relate** to that baseline.

**Related:** [Admin Operations Runbook](../admin/ADMIN_OPERATIONS_RUNBOOK.md) · [Manual Vendor Program Setup](../admin/MANUAL_VENDOR_PROGRAM_SETUP.md) · [Support and Troubleshooting](./SUPPORT_AND_TROUBLESHOOTING.md) · [FAQ — Users](./FAQ_USERS.md) · [BRE and credentials (primer)](../reference/BRE_AND_CREDENTIALS_FOR_NEW_USERS.md) · [Object catalog](../technical/OBJECT_CATALOG.md) · [UI components](../reference/ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md)

## How To Use This Page

- If production behavior is broken: jump to incident-style FAQs.
- If you are adding or changing behavior: use the scenario index.
- If you are brand new: read baseline setup first, then come back to one scenario at a time.
- If **business rules** or **external credentials** are confusing: read [BRE and credentials (primer)](../reference/BRE_AND_CREDENTIALS_FOR_NEW_USERS.md).

---

## Scenario index (extending the baseline)

| Scenario                                                                                                               | When to use                                                                        |
| ---------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| [Approval gates and vendor program requirement policy](#scenario-approval-gates-and-vendor-program-requirement-policy) | Requirements must **pause** until onboarding is **Approved** (or similar gate).    |
| [Next step rules (Onboarding_Next_Step_Rule\_\_mdt)](#scenario-next-step-rules-onboarding_next_step_rule__mdt)         | Guided “what to do next” or UI hints from **metadata** rules.                      |
| [Program-specific communications beyond DEFAULT](#scenario-program-specific-communications-beyond-default)             | Emails per **Vendor_Program_Key\_\_c** (normalized program **Name**).              |
| [Vendor program groups and eligibility](#scenario-vendor-program-groups-and-eligibility)                               | **Prerequisites**, **group** logic, **`Vendor_Onboarding_Eligibility_Rule__mdt`**. |
| [Status normalization and evaluation rules](#scenario-status-normalization-and-evaluation-rules)                       | Onboarding **status** wrong despite “good” data—tuning CMDT order or predicates.   |
| [Fulfillment policy and subject expansion](#scenario-fulfillment-policy-and-subject-expansion)                         | **Subjects** wrong count or wrong party—**Fulfillment_Policy_Key\_\_c** and CMDT.  |
| [Integrations (Adobe, LearnUpon, email catalog)](#scenario-integrations-adobe-learnupon-email-catalog)                 | Agreements, training, **EmailTemplate** sync.                                      |
| [Performance: async tail and queueables](#scenario-performance-async-tail-and-queueables)                              | “Late” onboarding record; **Defer_Onboarding_Tail\_\_c** and queues.               |

---

## Scenario: Approval gates and vendor program requirement policy

**What it means**

- **`Vendor_Customization__c.Approval_Policy_Key__c`** ties the program to rows in **`Vendor_Program_Approval_Policy__mdt`**.
- **`OnboardingRequirementVPRGateService`** (see repo class comments) uses **approval policy key + `Vendor_Program_Requirement__c.Requirement_Type__c`** to decide whether requirement **creation** must **stop** until **`Onboarding__c`** reaches **Approved** (or equivalent gate behavior), and processes requirements in **`Sequence__c`** order.

**Baseline vs this scenario**

- Baseline leaves **`Approval_Policy_Key__c` empty** so CMDT policy matching for the gate does not apply for that program.

**What to configure**

1. Deploy **`Vendor_Program_Approval_Policy__mdt`** rows: **`Policy_Key__c`** must match the program’s **`Approval_Policy_Key__c`**; **`Type__c`** (requirement type), **`Block_Action__c`**, **`Active__c`**, etc., per your governance design.
2. Set **`Approval_Policy_Key__c`** on the **`Vendor_Customization__c`** record.
3. Order **`Vendor_Program_Requirement__c.Sequence__c`** so gated types align with business intent.

**Verify**

- Before approval: creation stops before blocked types; after **Approved**: remaining rows can create on subsequent runs.
- **`Error_Log__c`** if flows throw.

**Incident overlap:** [Onboarding exists but requirement rows are missing](#onboarding-exists-but-requirement-rows-are-missing).

---

## Scenario: Next step rules (Onboarding_Next_Step_Rule\_\_mdt)

**What it means**

- **`Onboarding_Next_Step_Rule__mdt`** drives **next-step** behavior (which action or hint applies) using **field / operator / value** style configuration consumed by **`OnboardingNextStepRuleService`** / related automation.
- This is **metadata UX/coaching** and rule logic—not the same as **approval gating** of requirement rows.

**Baseline vs this scenario**

- Baseline does **not** require custom next-step rows for a first onboarding to work; your org may already ship default CMDT.

**What to configure**

1. Identify which **fields** and **states** should trigger which **next step** (link to product owner for wording).
2. Add or update **`Onboarding_Next_Step_Rule__mdt`** via **deployment** (not ad hoc prod edit unless your process allows).
3. Test with a real onboarding at different statuses.

**Verify**

- Screen or component that shows next steps updates when underlying fields change.
- No conflict with **status evaluation** order ([Configuration and Rules](../technical/CONFIGURATION_AND_RULES.md)).

---

## Scenario: Program-specific communications beyond DEFAULT

**What it means**

- You can keep one global policy for everyone by using **`Vendor_Program_Key__c = DEFAULT`**.
- You can also create program-specific policy rows by setting **`Vendor_Program_Key__c`** to a value based on the program name.
- The app builds that value from **`Vendor_Customization__c.Name`**: trim spaces, uppercase, replace spaces with underscores. Example: `Frontier Retail` -> `FRONTIER_RETAIL` (see [Manual Vendor Program Setup § Before you start](../admin/MANUAL_VENDOR_PROGRAM_SETUP.md#1-before-you-start)).
- If the app does not find a program-specific row, it falls back to **`DEFAULT`**.

**Baseline vs this scenario**

- Baseline uses **only `DEFAULT`** because it is easiest to run and support.
- Program-specific mode means you must keep keys consistent across both policy metadata types.

**What to configure**

1. Keep **`Vendor_Customization__c.Name`** stable (renaming it changes the derived key).
2. Add **`Communication_Template_Assignment__c`** rows for the program.
3. Add matching rows in both **`Communication_Event_Policy__mdt`** and **`Communication_Dispatch_Policy__mdt`** with the same `Vendor_Program_Key__c`.
4. Keep `DEFAULT` rows in place as your safe fallback.
5. Follow [Admin Operations Runbook — Communication setup](../admin/ADMIN_OPERATIONS_RUNBOOK.md#communication-setup-procedure-how-to).

**Verify**

- Positive send for one program-specific key.
- One blocked-recipient test.
- One fallback test where only `DEFAULT` should apply.

**Incident overlap:** [Email or training message not sent](#email-or-training-message-not-sent), [New vendor program and communications never program-specific](#new-vendor-program-and-communications-never-program-specific).

---

## Scenario: Vendor program groups and eligibility

**What it means**

- **`Vendor_Program_Group__c`** groups programs for **inheritance**, **rules**, and **eligibility** (`Vendor_Customization__c.Vendor_Program_Group__c`).
- **`Vendor_Program_Group_Member__c`** and similar structures can express **prerequisite** programs.
- **`Vendor_Onboarding_Eligibility_Rule__mdt`** (and related automation) can restrict which programs appear for an account or path.

**Baseline vs this scenario**

- Baseline uses a **standalone** program with **no** group link.

**What to configure**

1. Design group **Label**, **`Rule_Key__c`**, **`Logic_Type__c`**, **`Parent_Group__c`**, **`Requires_NDA__c`**, **`Requires_Program_Base__c`**, **`Active__c`** on the group record.
2. Link **`Vendor_Customization__c`** to the group if required.
3. Deploy or maintain eligibility **CMDT** and test **LWC**/**Flow** vendor pickers ([Vendor onboarding service](../developer/APEX_CLASS_INVENTORY.md) patterns).

**Verify**

- Account sees expected program options; blocked combinations match policy.

---

## Scenario: Status normalization and evaluation rules

**What it means**

- **`Onboarding_Status_Normalization__mdt`** maps raw evidence to **normalized** statuses.
- **`Onboarding_Status_Evaluation_Rule__mdt`** is evaluated **in order**; **first match** sets onboarding ([Configuration and Rules](../technical/CONFIGURATION_AND_RULES.md)).

**Baseline vs this scenario**

- Baseline assumes **deployed** rules are correct; this scenario is **tuning** or **debugging**.

**What to configure**

1. Change **normalization** when picklist or evidence values drift.
2. Insert or reorder **evaluation** rules carefully—small reorder can change lifecycle outcomes.
3. Restrict edits to holders of **`Onboarding_Status_Rule_Config`** ([Persona and permission sets](../technical/PERSONA_AND_PERMISSION_SETS.md)).

**Verify**

- Table experiment in lower org with known requirement states.
- Watch opportunity stage side-effects if rules update stage.

**Incident overlap:** [Onboarding status is wrong or stuck](#onboarding-status-is-wrong-or-stuck).

---

## Scenario: Fulfillment policy and subject expansion

**What it means**

- **`Vendor_Program_Requirement__c.Fulfillment_Policy_Key__c`** must match **`Onboarding_Fulfillment_Policy__mdt.Policy_Key__c`** ([Configuration and Rules — Fulfillment policies](../technical/CONFIGURATION_AND_RULES.md#fulfillment-policies-in-source)).
- Policies such as **`ACCOUNT_ONLY`**, **`ALL_CONTACTS`**, **`PRINCIPAL_OWNER`**, **`PRIMARY_CONTACT_OR_ACCOUNT`** control **who** gets **`Onboarding_Requirement_Subject__c`** rows.

**Baseline vs this scenario**

- Baseline **requires** valid keys on every template requirement; this scenario is **fixing** wrong or missing keys.

**What to configure**

1. Align **VPR** keys with CMDT.
2. Fix **Account Contact Relationship** roles where **principal** or **primary** paths are used ([FAQ — Users](./FAQ_USERS.md)).

**Verify**

- Subject count matches expectation per policy.

**Incident overlap:** [Subjects are missing or assigned to the wrong party](#subjects-are-missing-or-assigned-to-the-wrong-party).

---

## Scenario: Integrations (Adobe, LearnUpon, email catalog)

**What it means**

- **Adobe Sign** (`echosign_dev1`) for agreement send and evidence ([Integrations](../technical/INTEGRATIONS.md#adobe-agreement-path)).
- **LearnUpon** for enrollments and membership sync ([Integrations](../technical/INTEGRATIONS.md#learnupon-path)).
- **EmailTemplateSync** / **Communication_Template\_\_c** alignment for sends.

**Baseline vs this scenario**

- Baseline **may** skip deep integration testing if template requirements **do not** exercise those integrations; production always needs the [environment matrix](../technical/ENVIRONMENT_AND_INTEGRATIONS_MATRIX.md) filled out.

**What to configure**

1. Named credentials / auth per integration; document in **matrix** (not in public git if sensitive).
2. Validate agreement **templates** and **Associated_Agreement_Template\_\_c** on program when using Adobe defaults.
3. Run template sync jobs per org process if used.

**Verify**

- **`Error_Log__c`** clean on a full path; compare UAT vs prod only with parity discipline.

**Incident overlap:** [Adobe agreement will not send or sign](#adobe-agreement-will-not-send-or-sign), [Email or training message not sent](#email-or-training-message-not-sent).

---

## Scenario: Performance: async tail and queueables

**What it means**

- **`Onboarding_Performance_Config__mdt.Default.Defer_Onboarding_Tail__c`** (when true) defers part of onboarding creation to **`OnboardingChainTailQueueable`** after **`OnboardingEnqueueOnboardingTailInvocable`** ([System Overview](../technical/SYSTEM_OVERVIEW.md#1-opportunity-led-onboarding-creation)).

**Baseline vs this scenario**

- Baseline **accepts** default performance settings; this scenario explains **user-visible delay**.

**What to configure**

- Usually **not** toggled for business reasons without architecture review; if changed, document in release notes.

**Verify**

- Async Apex queue depth, **no infinite fault loops**, **`Onboarding_Opportunity_Chain__e`** (if used) healthy.

**Incident overlap:** [User says onboarding was never created](#user-says-onboarding-was-never-created) (user didn’t wait).

---

## Incident-style FAQs (something broke)

Use with the [fast triage matrix](./SUPPORT_AND_TROUBLESHOOTING.md#fast-triage-matrix).

### User says onboarding was never created

**Check**

1. **`Error_Log__c`** around the reported time; filter by onboarding/opportunity context if fields allow ([Support and Troubleshooting](./SUPPORT_AND_TROUBLESHOOTING.md#where-to-look)).
2. Whether **`Onboarding_Performance_Config__mdt`** defers the onboarding tail: if `Defer_Onboarding_Tail__c` is true, creation can finish **asynchronously** ([Performance scenario](#scenario-performance-async-tail-and-queueables)) — confirm **Async Apex** / queue jobs are healthy and user waited.
3. **Opportunity / Contract / OCR** exist and links match ([Data Model](../technical/DATA_MODEL.md)).
4. **Flow interview** history for failed **`EXP_Opportunity_SCR_Create_Record`** runs if available in the org.

**Common causes:** validation errors, missing permission, integration fault, or async backlog.

---

### Onboarding exists but requirement rows are missing

**Check**

1. **`Vendor_Customization__c` (program)** on the onboarding is **Active** and correct.
2. **`Vendor_Program_Requirement__c`** rows exist for that program, **Active**, sensible **`Sequence__c`**, and **`Fulfillment_Policy_Key__c`** matches deployed **`Onboarding_Fulfillment_Policy__mdt`** keys ([Configuration and Rules](../technical/CONFIGURATION_AND_RULES.md#fulfillment-policies-in-source)).
3. **`Error_Log__c`** for failures in **`BLL_Onboarding_RCD_Logical_Process`** / requirement create path ([Triage matrix](./SUPPORT_AND_TROUBLESHOOTING.md#fast-triage-matrix)).
4. **[Approval gates scenario](#scenario-approval-gates-and-vendor-program-requirement-policy):** **`Approval_Policy_Key__c`** + **`Vendor_Program_Approval_Policy__mdt`** can **block** creation until onboarding is **Approved**.

---

### Subjects are missing or assigned to the wrong party

**Check**

1. **`Onboarding_Requirement__c.Fulfillment_Policy_Key__c`** and alignment with **`Onboarding_Fulfillment_Policy__mdt`**.
2. **Account Contact Relationships** and **roles** for the contacts involved ([FAQ — Users](./FAQ_USERS.md#i-cannot-select-the-right-contact-in-the-create-flow)).
3. **`Error_Log__c`** for subject expansion / evaluation faults.
4. Deep dive: [Fulfillment scenario](#scenario-fulfillment-policy-and-subject-expansion).

---

### Onboarding status is wrong or stuck

**Check**

1. **Normalized statuses** and **`Onboarding_Status_Evaluation_Rule__mdt`** order ([Configuration and Rules](../technical/CONFIGURATION_AND_RULES.md)) — first match wins.
2. **Requirement and subject statuses** — rollup depends on children ([Business User Guide](../business/BUSINESS_USER_GUIDE.md#understanding-status-changes)).
3. **No manual overwriting** of lifecycle fields as a “fix” without understanding rules.
4. Deep dive: [Status rules scenario](#scenario-status-normalization-and-evaluation-rules).

---

### Email or training message not sent

**Check** (communications)

1. **`Communication_Event_Policy__mdt`** and **`Communication_Dispatch_Policy__mdt`**: event key, `Active__c`, `Send_Enabled__c`, **`Vendor_Program_Key__c`** (program-specific vs `DEFAULT`). Program key is derived from **`Vendor_Customization__c.Name`** (normalized: upper case, spaces → `_`) per runtime ([Manual Vendor Program Setup](../admin/MANUAL_VENDOR_PROGRAM_SETUP.md#1-before-you-start)).
2. **`Communication_Template_Assignment__c`**: template **Active**, linked to the right **vendor program**.
3. **`Communication_Template__c`**: **`Email_Template_Id__c`** populated for email sends.
4. **`Error_Log__c`** for dispatch or bulk-send failures.
5. Deep dive: [Program-specific communications](#scenario-program-specific-communications-beyond-default).

**Check** (training / LearnUpon)

- See [Integrations scenario](#scenario-integrations-adobe-learnupon-email-catalog).

---

### Adobe agreement will not send or sign

**Check**

1. [Integrations — Adobe](../technical/INTEGRATIONS.md#adobe-agreement-path) for the supported flow entry points.
2. **Contract and agreement** data prerequisites on the records the flow expects.
3. **`Error_Log__c`** and echosign-side configuration (credentials, template availability).

---

### Something worked yesterday and broke today after a release

**Check**

1. [Metadata Drift Checklist](../admin/METADATA_DRIFT_CHECKLIST.md) and [Deployment Runbook](../admin/DEPLOYMENT_RUNBOOK.md#post-deploy-validation-checklist): flow **Active** status, critical **BLL** flows, permission sets.
2. [Release notes template](../admin/RELEASE_NOTES_AND_SMOKE_TEST_TEMPLATE.md) for what changed this deploy.
3. **Recent CMDT** or communication picklist changes that could change **`Vendor_Program_Key__c`** matching.
4. Compare **sandbox vs production** for the failing automation if parity is suspected.

---

### New vendor program and communications never program-specific

**Check**

1. [Manual Vendor Program Setup](../admin/MANUAL_VENDOR_PROGRAM_SETUP.md): **`Name`** stability and normalized key alignment with **`Communication_*` CMDT**.
2. Template **assignments** and **Active** flags ([Admin Operations Runbook](../admin/ADMIN_OPERATIONS_RUNBOOK.md#communication-setup-procedure-how-to)).
3. [Program-specific communications scenario](#scenario-program-specific-communications-beyond-default).

---

## Where is the technical “source of truth” for symptoms?

| Symptom (short)     | Deep reference                                                                            |
| ------------------- | ----------------------------------------------------------------------------------------- |
| Not created / flow  | [Triage matrix](./SUPPORT_AND_TROUBLESHOOTING.md#fast-triage-matrix)                      |
| Requirements / gate | [Approval gates scenario](#scenario-approval-gates-and-vendor-program-requirement-policy) |
| Status              | [Status rules scenario](#scenario-status-normalization-and-evaluation-rules)              |
| Email               | [Admin Operations Runbook](../admin/ADMIN_OPERATIONS_RUNBOOK.md) (communication)          |
| Async delay         | [Performance scenario](#scenario-performance-async-tail-and-queueables)                   |

---

## Escalation to engineering

Include the [required artifacts](./SUPPORT_AND_TROUBLESHOOTING.md#required-artifacts-for-any-ticket) plus **which scenario or incident FAQ** you followed and what you ruled out.
