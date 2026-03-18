# SOP: Linking Two Vendor Programs via Onboarding Next Step Rule

This SOP describes how to configure **Onboarding Next Step Rule** custom metadata to link two Vendor Programs (Vendor_Customization__c) so that one program becomes the "next step" when a specific condition is met on the Onboarding record's Opportunity.

**Example scenario:** Vendor Program `aDFRL00000116Sb4AI` links to Vendor Program `aDFRL00000116Sc4AI` **if and only if** the Onboarding record's Opportunity `Program_Base_App_Selection__c` = `Program Base Application - with Chuzo`.

---

## Prerequisites

- **Onboarding Next Step Rule** custom metadata type is deployed to your org
- Both Vendor Programs (source and target) exist and are active
- The consuming logic (Apex/UI) that evaluates these rules is deployed and active

> **Note:** Per [how-to-setup-records.md](./how-to-setup-records.md), `Onboarding_Next_Step_Rule__mdt` is used by Apex/UI, not flows. Ensure the Apex classes or Lightning components that read this metadata are present in your org.

---

## Onboarding Next Step Rule Schema

| Field | Type | Purpose |
|-------|------|---------|
| **Action__c** | Picklist | `Auto Create`, `Manual Unlock`, or `None` – controls whether the linked program is auto-created or manually unlocked |
| **Scope_Key__c** | Text (255) | Typically the **target Vendor Program ID** or a unique key identifying the linked program |
| **Field_API_Name__c** | Text | API name of the field to evaluate (use relationship path when evaluating from Onboarding) |
| **Expected_Value__c** | Text | Value the field must match for the rule to apply |
| **Operator__c** | Picklist | Comparison operator (e.g., `Equals`) |
| **Sequence__c** | Number | Evaluation order when multiple rules apply |
| **Active__c** | Checkbox | Must be checked for the rule to be evaluated |

---

## Step-by-Step: Link Vendor Program A → Vendor Program B When Program Base App Selection = "with Chuzo"

### 1. Identify Source and Target Vendor Programs

- **Source Vendor Program:** `aDFRL00000116Sb4AI` (the program whose Onboarding is being evaluated)
- **Target Vendor Program:** `aDFRL00000116Sc4AI` (the program to link to when the condition is met)

### 2. Create the Onboarding Next Step Rule Record

1. Go to **Setup** → **Custom Metadata Types** → **Onboarding Next Step Rule** → **Manage Records**
2. Click **New**
3. Fill in the fields as follows:

| Field | Value |
|-------|-------|
| **Label** | e.g., `Link to Chuzo Program when Program Base App = with Chuzo` |
| **Onboarding Next Step Rule Name** (Developer Name) | e.g., `Link_Chuzo_When_Program_Base_With_Chuzo` |
| **Active** | ✓ Checked |
| **Action** | `Auto Create` (or `Manual Unlock` if the linked program should be manually unlocked) |
| **Scope Key** | `aDFRL00000116Sc4AI` *(Target Vendor Program Id)* |
| **Field API Name** | `Opportunity__r.Program_Base_App_Selection__c` |
| **Expected Value** | `Program Base Application - with Chuzo` |
| **Operator** | `Equals` |
| **Sequence** | `10` (or another number for evaluation order) |

4. Save

### 3. Field API Name: Context Matters

The **Field API Name** must be the API path **from the Onboarding record**. Since Onboarding has a lookup to Opportunity:

- Use: `Opportunity__r.Program_Base_App_Selection__c`

If the consuming code evaluates from a different context (e.g., Opportunity directly), the path may differ. Confirm with your Apex/UI implementation.

### 4. Scope Key: Target Program Identifier

**Scope_Key__c** is used to identify the linked (target) Vendor Program. In most implementations:

- Store the **target Vendor Program Id** (e.g., `aDFRL00000116Sc4AI`)
- Or a stable key (e.g., DeveloperName) if the implementation resolves it to an Id

The **source** Vendor Program is typically implied by the Onboarding record’s current Vendor Program when the rule is evaluated.

---

## Verification

### Query existing Onboarding Next Step Rules

```soql
SELECT DeveloperName, MasterLabel, Active__c, Action__c, Scope_Key__c,
       Field_API_Name__c, Expected_Value__c, Operator__c, Sequence__c
FROM Onboarding_Next_Step_Rule__mdt
WHERE Active__c = true
ORDER BY Sequence__c
```

### Confirm Program Base App Selection values

```soql
SELECT Id, Name, Program_Base_App_Selection__c
FROM Opportunity
WHERE Program_Base_App_Selection__c = 'Program Base Application - with Chuzo'
LIMIT 5
```

---

## Important Notes

1. **Consuming logic:** This metadata is used by Apex/UI, not flows. The exact behavior of `Scope_Key__c`, `Action__c`, and evaluation context depends on the Apex classes or Lightning components that read it. If behavior differs from this SOP, review that code.

2. **Source program scope:** The current schema does not have an explicit "Source Vendor Program" field. Rules are usually evaluated in the context of the current Onboarding’s Vendor Program. If you need rules to apply only when the source program is a specific one, the implementation may use `Scope_Key__c` or another convention—check the consuming code.

3. **Picklist value:** Use the exact API value `Program Base Application - with Chuzo` (with Chuzo, not "Chuzo" alone). Picklist API values are case-sensitive.

4. **Multiple rules:** Use **Sequence__c** to control evaluation order when several rules could apply.

---

## Related Documentation

- [How to Setup Records](./how-to-setup-records.md) – Setup order and Vendor Program configuration
- [DOMAIN_OmniSObject_SFL_CREATE_Contract.flow-meta.xml](../../force-app/main/default/flows/DOMAIN_OmniSObject_SFL_CREATE_Contract.flow-meta.xml) – Example of `Program_Base_App_Selection__c` usage in flows
