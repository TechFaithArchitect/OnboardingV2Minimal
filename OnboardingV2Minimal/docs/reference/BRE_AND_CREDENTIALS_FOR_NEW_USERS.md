# Business Rules and External Credentials (For New Users)

Two topics confuse people early: **BRE** (“business rules”) and **external credentials** (ECC). This is a **plain-English** introduction with links to deeper material.

## Part A — Business rules engine (BRE)

### What problem it solves

During onboarding, the business needs **conditional decisions**: for example, “if the account looks like X, require path Y” or “block/allow the next automation step.” Rather than hard-coding only in Apex, parts of the product call a flow named **`BLL_BRE_Evaluate_Business_Rules`**, which uses Salesforce **business rules** capabilities (including **Expression Sets** backed by `ExpressionSet` / `ExpressionSetVersion` in metadata).

### What you should know as a new user

- **You will not “see BRE” as an object on the onboarding record.** You see **outcomes**: which branch the flow took, requirement behavior, or errors in **`Error_Log__c`**.
- **`OnboardingRecordBREGateInvocable`** runs `BLL_BRE_Evaluate_Business_Rules` with **`RuleContext = CommunicationDispatch`** (same inputs the onboarding record flow uses for “may we send?”). It wraps that call in Apex so failures **do not roll back** the parent transaction—faults become `dispatchAllowed = false` and a **diagnostic** on the invocable result instead of an exception. Other BRE entry points (pure Flow subflows, different contexts) are not covered by this class.
- **Next step** hints after certain gates are related to **`Onboarding_Next_Step_Rule__mdt`** (separate but often feels like “what the business rule implied should happen next”). See [FAQ — Admins: Next step rules](../support/FAQ_ADMINS.md#scenario-next-step-rules-onboarding_next_step_rule__mdt).

### Where to go deeper

- Flow: [Flow catalog](../developer/FLOW_CATALOG.md) (search `BLL_BRE_Evaluate_Business_Rules`).
- Domain: `DOMAIN_OmniSObject_SFL_CREATE_Process_Status_Per_Business` ties **process status** to business-rule context.
- Changing BRE definitions is **admin/architect** work: coordinate with whoever owns **Expression Sets** in your org.

### Start Onboarding — blocking duplicate Program Base / NDA while one is active

Some experience flows (for example **`EXP_Opportunity_SCR_Create_Record`**) call the domain subflow **`DOMAIN_OmniSObject_SFL_GET_Onboarding_Records`**, then **`BLL_BRE_Evaluate_Business_Rules`** with **`RuleContext = OnboardingOrchestrator`**. Together they can block users from starting another onboarding when a **Program Base Application** (with/without Chuzo / no-PG) or **NDA** onboarding is still **active** (onboarding status is not a terminal state such as **Setup Complete**, **Approved**, **Denied**, **Canceled**, or **Expired**).

**Exception — vendor program after Credit / Background requirements are done**

Credit and Background progress are tracked on **`Onboarding_Requirement__c`** (not the check status fields on **`Onboarding__c`** for this gate). To avoid running **Get Records** inside the per-onboarding loop, the domain flow **prefetches once**: after **`HasAnyOnboardingRecordForAccount_Filter`**, it builds an Id list, runs **`Get_All_Program_Base_Credit_And_Background_Requirements`** (Credit Check or Background Check for those onboardings), then in the account onboarding **`Loop_OnboardingRecordsForAccount_Filter`** it uses **`Filter_Program_Base_Credit_Req_For_Current_Onboarding`** / **`Filter_Program_Base_Background_Req_For_Current_Onboarding`** and small extract loops to set **`Program_Base_Credit_Check_Requirement`** and **`Program_Base_Background_Check_Requirement`** for the current iteration. It then evaluates **`Program_Base_Credit_And_Background_Satisfied_Decision`**: both rows must exist, and for **each** row either **`Completed__c` = true** or **`Status__c`** is **`Complete`** or **`Waived`**. If that passes, that Program Base onboarding **does not** set **`HasActiveProgramBaseOrNdaPipeline`**, so users can proceed (including **Vendor Program** paths the BRE exposes). If multiple requirement rows match a type for one onboarding, the first row in the filtered collection order is used (same class of ambiguity as the previous **`getFirstRecordOnly`** lookups).

**How to change this behavior (admins / architects)**

1. Open **Setup → Flows** → **`DOMAIN_OmniSObject_SFL_GET_Onboarding_Records`** in **Flow Builder**.
2. Find the bulk requirement load and filters (**`Get_All_Program_Base_Credit_And_Background_Requirements`**, then **Filter** / extract steps after **Active Program Base Onboarding**), then **Program Base Credit and Background Requirements Satisfied**.
3. Adjust **filters** (for example if requirement type labels differ in your org) or **decision** outcomes (for example add another **Status__c** value that should count as “satisfied”).

**Related output:** `HasActiveProgramBaseOrNdaPipeline` is passed into **`BLL_BRE_Evaluate_Business_Rules`** as input **`HasActiveProgramBaseOrNdaPipeline`**; **`Gate_Onboarding_Pipeline_Not_Active`** assigns **`BLOCK_ACTIVE_ONBOARDING_PIPELINE`** when that flag is true.

---

## Part B — External contact credentials (ECC)

### What problem it solves

Dealer or partner onboarding often requires **proof** (license, certification, background result). The product models many of these as:

1. **`Required_Credential__c`** — “this **program** needs credential type T.”
2. **`External_Contact_Credential_Type__c`** — the **catalog of types**.
3. **`POE_External_Contact_Credential__c`** — the **actual evidence row** on a contact (status, dates, etc.).

When credential records **change**, automation (`BLL_External_Contact_Credential_*` flows and related **DOMAIN** flows) can **update onboarding requirements/subjects** so status and work stay aligned.

### What you should know as a new user

- **Credentials are evidence**, not the same thing as **Onboarding Requirement** rows—but they **drive** requirement/subject updates through automation.
- The **`onboardingECC`** component on **`Onboarding__c`** is there to **surface** ECC context for that onboarding ([UI guide](./ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md)).
- If “credential is done but requirement not green,” triage **normalization + status rules** and **subject expansion**, not only the credential field values ([FAQ — Admins](../support/FAQ_ADMINS.md)).

### Where to go deeper

- [Object catalog](../technical/OBJECT_CATALOG.md) — Tier 3.
- [Automation catalog](../technical/AUTOMATION_CATALOG.md) — rows for `POE_External_Contact_Credential__c`.
- [Data model](../technical/DATA_MODEL.md) — evidence list.

---

### How to set up credentials (admin path)

Use this order so config stays consistent:

1. Create/update **credential types** (`External_Contact_Credential_Type__c`).
2. Create/update **program-required credentials** (`Required_Credential__c`) that point to those types.
3. Let automation create/update **contact evidence rows** (`POE_External_Contact_Credential__c`) and link rows (`Required_External_Contact_Credential__c`).
4. Validate with one real onboarding test.

Setup details:

Step 1 — Configure `External_Contact_Credential_Type__c`

- Set `Vendor_Customization__c` (required), `Active__c`, and `Sort_Order__c` (required).
- Use `Unique_Key__c` if your org uses integration/dedupe patterns.

Step 2 — Configure `Required_Credential__c`

- Set `Vendor_Customization__c` (program), `External_Contact_Credential_Type__c`, and (recommended) `Sequence__c`.
- Set `Is_Required__c` based on business policy.
- Validation rules enforce that each required credential row is linked to a credential type.

Step 3 — Let automation create evidence links (normal path)

- `POE_External_Contact_Credential__c` (evidence rows) and `Required_External_Contact_Credential__c` (link rows) are usually populated/maintained by flow automation.
- Key automation touchpoints: `DOMAIN_OmniSObject_SFL_GET_External_Contact_Credential_Types`, `DOMAIN_OmniSObject_SFL_CREATE_External_Contact_Credentials`, `DOMAIN_OmniSObject_SFL_CREATE_Required_External_Contact_Credenti`, `BLL_External_Contact_Credential_RCD_Logical_Process`.

Step 4 — Validate end-to-end

- Create a test onboarding for the target vendor program.
- Confirm required credential records are present for that program.
- Confirm expected ECC evidence rows exist for the responsible contact(s).
- Update one ECC row to `Complete` and verify downstream requirement/subject status behavior.

### Scenario playbooks (how in practice)

#### Scenario 1: Add a new required credential for one vendor program

Use this when a vendor adds a new compliance artifact.

1. Add `External_Contact_Credential_Type__c` for that program (`Active__c = true`, set `Sort_Order__c`).
2. Add `Required_Credential__c` pointing to that type.
3. Run one onboarding create test and confirm expected ECC rows appear.
4. Verify the new credential participates in requirement status progression.

Expected result: new onboardings for that program include and track the new credential path.

#### Scenario 2: Retire a credential type without deleting history

Use this when a credential is no longer needed for future work.

1. Set `External_Contact_Credential_Type__c.Active__c = false` (instead of deleting).
2. Deactivate or remove associated `Required_Credential__c` rows for future runs.
3. Leave historical `POE_External_Contact_Credential__c` rows intact for audit/reporting.
4. Test a new onboarding to ensure retired type is not regenerated.

Expected result: old records remain for history; new onboarding runs do not use the retired credential.

#### Scenario 3: Credential is complete but requirement is still not complete

Use this when users say “I marked the credential done but onboarding is stuck.”

1. Verify the ECC row is on the correct contact and credential type.
2. Verify the ECC status value is one your normalization/rules treat as complete.
3. Verify required credential mapping exists for that vendor program.
4. Check `Error_Log__c` for ECC evaluation faults.

Expected result: you isolate whether the issue is data mismatch, mapping/config gap, or automation fault.

---

## Quick comparison

| Topic | “Looks like”                 | Primary objects / flows                                                       |
| ----- | ---------------------------- | ----------------------------------------------------------------------------- |
| BRE   | Strategy / branching         | `BLL_BRE_Evaluate_Business_Rules`, Expression Sets                            |
| ECC   | Paperwork / proof per person | `Required_Credential__c`, `POE_External_Contact_Credential__c`, BLL ECC flows |

---

## Related

- [FAQ — Admins](../support/FAQ_ADMINS.md)
- [Support and troubleshooting](../support/SUPPORT_AND_TROUBLESHOOTING.md)
