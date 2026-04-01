# Business Rules and External Credentials (For New Users)

Two topics confuse people early: **BRE** (“business rules”) and **external credentials** (ECC). This is a **plain-English** introduction with links to deeper material.

## Part A — Business rules engine (BRE)

### What problem it solves

During onboarding, the business needs **conditional decisions**: for example, “if the account looks like X, require path Y” or “block/allow the next automation step.” Rather than hard-coding only in Apex, parts of the product call a flow named **`BLL_BRE_Evaluate_Business_Rules`**, which uses Salesforce **business rules** capabilities (including **Expression Sets** backed by `ExpressionSet` / `ExpressionSetVersion` in metadata).

### What you should know as a new user

- **You will not “see BRE” as an object on the onboarding record.** You see **outcomes**: which branch the flow took, requirement behavior, or errors in **`Error_Log__c`**.
- **`OnboardingRecordBREGateInvocable`** wraps the BRE flow so failures **do not roll back** the whole transaction— failures surface as controlled outcomes instead.
- **Next step** hints after certain gates are related to **`Onboarding_Next_Step_Rule__mdt`** (separate but often feels like “what the business rule implied should happen next”). See [FAQ — Admins: Next step rules](../support/FAQ_ADMINS.md#scenario-next-step-rules-onboarding_next_step_rule__mdt).

### Where to go deeper

- Flow: [Flow catalog](../developer/FLOW_CATALOG.md) (search `BLL_BRE_Evaluate_Business_Rules`).
- Domain: `DOMAIN_OmniSObject_SFL_CREATE_Process_Status_Per_Business` ties **process status** to business-rule context.
- Changing BRE definitions is **admin/architect** work: coordinate with whoever owns **Expression Sets** in your org.

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

## Quick comparison

| Topic | “Looks like”                 | Primary objects / flows                                                       |
| ----- | ---------------------------- | ----------------------------------------------------------------------------- |
| BRE   | Strategy / branching         | `BLL_BRE_Evaluate_Business_Rules`, Expression Sets                            |
| ECC   | Paperwork / proof per person | `Required_Credential__c`, `POE_External_Contact_Credential__c`, BLL ECC flows |

---

## Related

- [FAQ — Admins](../support/FAQ_ADMINS.md)
- [Support and troubleshooting](../support/SUPPORT_AND_TROUBLESHOOTING.md)
