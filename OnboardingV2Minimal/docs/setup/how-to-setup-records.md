# How to Setup Records (End-to-End)

This guide describes how to set up records for the onboarding system **as implemented in this repo and deployed to OnboardV2**. It covers only setup required by **active flows last modified after Jan 1, 2026** (85 flows in OnboardV2 org). Objects and CMDTs used only by older flows, Apex, or UI components are excluded.

---

## How Onboarding Works (Current Flow)

1. **Opportunity** is created with **Vendor_Customization__c** (Vendor Program) populated.
2. **BLL_Opportunity_RCD_Logical_Process** (record-triggered on Opportunity create) runs and calls **DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record**, which creates an **Onboarding__c** record linked to the Opportunity and Vendor Program.
3. **BLL_Onboarding_RCD_Logical_Process** (record-triggered on Onboarding create) runs and calls **DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements**, which:
   - Creates **Onboarding_Requirement__c** from active **Vendor_Program_Requirement__c** records
   - Calls **DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirement_Subjects** to create **Onboarding_Requirement_Subject__c** rows based on fulfillment policy
4. **Onboarding__c** record page shows requirements via **objectRelatedList** and **lst:dynamicRelatedList** (standard Lightning components).
5. Requirement status changes trigger **BLL_Onboarding_Requirement_RCD_Logical_Process**, which can update **Onboarding__c.Onboarding_Status__c** via the Business Rules Engine.

---

## Setup Order Overview

```
1. Account (for Vendor)
2. Vendor__c
3. Vendor_Program_Group__c
4. Vendor_Customization__c (Vendor Program)
5. Vendor_Program_Group_Member__c
6. Vendor_Program_Requirement__c (with Fulfillment_Policy_Key__c)
7. (Optional) Onboarding_Fulfillment_Policy__mdt (for new subject models)
8. (Optional) Vendor_Program_Approval_Policy__mdt (for approval-gated requirements)
9. (Optional) Onboarding_Status_Normalization__mdt (for new requirement types/status mappings; used by BRE)
10. (Optional) Training_System__c, Training_Requirement__c, Vendor_Program_Training_Requirement__c
11. (Optional) External_Contact_Credential_Type__c, Required_Credential__c (for credential requirements)
12. (Optional) Communication_Template__c (for vendor program email/SMS)
13. (Optional) Communication_Event_Policy__mdt, Communication_Dispatch_Policy__mdt (for comm dispatch; defaults deployed)
14. (For PRINCIPAL_OWNER) AccountContactRelation with Roles

*Steps 7–9 are CMDT configuration; 10–14 are standard records. Excluded (used by Apex/UI, not flows): Vendor_Onboarding_Eligibility_Rule__mdt, Onboarding_Next_Step_Rule__mdt, Child_Record_Editor_Config__mdt, Follow_Up_Rule__mdt, Follow_Up_Suppression__mdt, Twilio_Configuration__mdt.*
```

**Auto-created records (no manual setup):**
- **Onboarding_Requirement_Subject__c** – Created by `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirement_Subjects` when onboarding requirements are created
- **Training_Assignment_Onboarding__c** – Created by flows when training assignments are linked to onboarding records
- **Required_External_Contact_Credential__c** – Created by `DOMAIN_OmniSObject_SFL_CREATE_Required_External_Contact_Credenti` from Required_Credential__c
- **Follow_Up_Queue__c** – Created by `DOMAIN_OmniSObject_SFL_CREATE_Follow_Up_Queue` when communication faults are queued

---

## Step 1: Create Account (for Vendor)

1. Go to **Accounts** → **New**
2. Create an Account (e.g., "Sample Vendor Account", Type = Vendor)
3. Save

---

## Step 2: Create Vendor__c

1. Go to **Vendors** tab
2. Create a record:
   - **Name**: Vendor name (e.g., "Sample Vendor")
   - **Active__c**: Checked
   - (If your org has **Account__c** on Vendor__c, link to the vendor Account)
3. Save

---

## Step 3: Create Vendor_Program_Group__c

Groups organize vendor programs. Vendor Programs link to groups for program grouping and inheritance.

1. Go to **Vendor Program Groups** tab
2. Create a record:
   - **Name**: Group name (e.g., "Sample Program Group")
   - **Label__c**: Display label (if present)
   - **Active__c**: Checked (if present)
   - **Logic_Type__c**: AND or OR (if present)
3. Save

---

## Step 4: Create Vendor_Customization__c (Vendor Program)

1. Go to **Vendor Programs** tab (object: Vendor_Customization__c)
2. Create a record:
   - **Name**: Program name (e.g., "Sample Vendor Program")
   - **Vendor__c**: Link to Vendor__c
   - **Vendor_Program_Group__c**: Link to the Vendor Program Group
   - **Active__c**: Checked
   - **Approval Policy Key** (`Approval_Policy_Key__c`): (Optional) Matches **Vendor_Program_Approval_Policy__mdt.Policy_Key__c** for this program (onboarding gate and BRE policy resolution)
3. Save

---

## Step 5: Create Vendor_Program_Group_Member__c

Links the Vendor Program to the group.

1. Go to **Vendor Program Group Members** tab
2. Create a record:
   - **Vendor_Program_Group__c**: Link to the group
   - **Required_Program__c**: Link to the Vendor Program (Vendor_Customization__c)
   - **Is_Target__c**: Checked if this is the target program
   - **Active__c**: Checked
3. Save

---

## Step 6: Create Vendor_Program_Requirement__c

1. Go to **Vendor Program Requirements** tab
2. Create a record:
   - **Name**: Requirement name (e.g., "Background Check")
   - **Vendor_Program__c**: Link to the Vendor Program (Vendor_Customization__c)
   - **Requirement_Type__c**: From global value set (e.g., Training, Background Check, Contract, Agreement)
   - **Fulfillment_Policy_Key__c**: See table below
   - **Active__c**: Checked
   - **Is_Required__c**: Checked if mandatory
   - **Sequence__c**: Display order
3. Save

### Fulfillment Policy Keys

| Key | Subject Model | Use Case |
|-----|---------------|----------|
| `ACCOUNT_ONLY` | Account | Requirement satisfied at account level |
| `ALL_CONTACTS` | All Contacts | Every contact on the account must satisfy |
| `PRINCIPAL_OWNER` | Principal Owner | Only the principal owner contact must satisfy |
| `PRIMARY_CONTACT_OR_ACCOUNT` | Primary Contact Or Account | Primary contact or account fallback (default when blank) |

If `Fulfillment_Policy_Key__c` is blank, the system defaults to `PRIMARY_CONTACT_OR_ACCOUNT`. **Onboarding_Fulfillment_Policy__mdt** records for `ACCOUNT_ONLY`, `ALL_CONTACTS`, `PRINCIPAL_OWNER`, and `PRIMARY_CONTACT_OR_ACCOUNT` are deployed with the metadata.

---

## Step 7: (Optional) Onboarding_Fulfillment_Policy__mdt

The four policies (`ACCOUNT_ONLY`, `ALL_CONTACTS`, `PRINCIPAL_OWNER`, `PRIMARY_CONTACT_OR_ACCOUNT`) are deployed with metadata. Add records only when you need a new subject model.

1. Go to **Setup** → **Custom Metadata Types** → **Onboarding Fulfillment Policy** → **Manage Records**
2. Create a record:
   - **Policy Key**: Unique key (e.g., `CUSTOM_MODEL`)
   - **Subject Model**: Account, AllContacts, PrincipalOwner, or PrimaryContactOrAccount
   - **Active**: Checked

**Note:** Adding new subject models may require flow changes in `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirement_Subjects`.

---

## Step 8: (Optional) Vendor_Program_Approval_Policy__mdt

Used when requirements need approval before completion. **Vendor_Customization__c** (Vendor Program) **Approval_Policy_Key__c** matches the **Policy_Key__c** of these records together with each requirement’s **Requirement_Type__c**.

1. Go to **Setup** → **Custom Metadata Types** → **Vendor Program Approval Policy** → **Manage Records**
2. Create a record (example: `VERIZON_FIOS` for Agreement type):
   - **Policy Key**: Unique key (e.g., `VERIZON_FIOS`) – same value as **Vendor_Customization__c.Approval_Policy_Key__c** on programs that use this policy
   - **Type**: Requirement type (e.g., Agreement, Contract)
   - **Approval Required**: Checked if approval is required
   - **Approval Process DevName**: Salesforce approval process API name
   - **Reason Code**: Approval reason code
   - **Block Action**: Whether to block until approved
   - **Priority**: Numeric priority
   - **Active**: Checked

---

## Step 9: (Optional) Onboarding_Status_Normalization__mdt

Status evaluation uses **Onboarding_Status_Normalization__mdt** custom metadata. The BRE maps each requirement’s `Requirement_Type__c` + `Status__c` to a `Normalized_Status__c`, which drives `Onboarding__c.Onboarding_Status__c`.

Deployed metadata includes many records (e.g., Training, Contract, Agreement, Workers Comp). Add records only when you need mappings for new requirement types or status values.

1. Go to **Setup** → **Custom Metadata Types** → **Onboarding Status Normalization** → **Manage Records**
2. Create a record:
   - **Requirement Type**: From global value set (e.g., Training, Contract)
   - **Status**: Raw requirement status (e.g., Complete, Denied, N/A)
   - **Normalized Status**: Output for the BRE (e.g., Setup Complete, Denied)
   - **Active**: Checked

---

## Step 10: (Optional) Training Requirements

For training-driven requirements:

1. Create **Training_System__c** records first (e.g., LearnUpon, External Portal). **Training_Requirement__c** has a validation rule requiring **Training_System__c**.
2. Create **Training_Requirement__c** records:
   - **Training_System__c**: Link to the training system
   - **Training_Type__c**, **Training_Code__c**, **External_Course_Code__c** as needed
   - **Active__c**: Checked
3. Create **Vendor_Program_Training_Requirement__c** records:
   - **Vendor_Program__c**: Link to the Vendor Program
   - **Training_Requirement__c**: Link to the training requirement

**Training_Assignment_Onboarding__c** is auto-created by flows when training assignments are linked to onboarding; no manual creation of these junction records is required.

Training completion updates subject status via **DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_By_Evidence** when **BLL_OmniSObject_RCD_SYNC_Training_Assignments** runs.

---

## Step 11: (Optional) Required Credentials (External Contact Credentials)

For credential requirements (e.g., OSHA 10, Driver's License):

1. Create **External_Contact_Credential_Type__c** records (defines credential types).
2. Create **Required_Credential__c** records (Master-Detail to Vendor Program):
   - **Vendor_Customization__c**: Link to the Vendor Program
   - **External_Contact_Credential_Type__c**: Link to the credential type
   - **Is_Required__c**: Checked if mandatory
   - **Sequence__c**: Display order

**Required_External_Contact_Credential__c** is created by `DOMAIN_OmniSObject_SFL_CREATE_Required_External_Contact_Credenti` from **Required_Credential__c**; no manual creation of junction records.

---

## Step 12: (Optional) Communication_Template__c

For vendor program email/SMS templates used in onboarding communications:

1. Go to **Communication Templates** tab
2. Create a record:
   - **Name**: Template name
   - **Vendor_Program__c**: Link to the Vendor Program
   - **Communication_Type__c**, **Recipient_Type__c** as configured
   - Channel/type fields (Email/SMS) as needed

---

## Step 13: (Optional) Communication CMDTs

**Communication_Event_Policy__mdt** and **Communication_Dispatch_Policy__mdt** control when and to whom communications are sent. Default records (e.g., `def_onb_created_train_block`, `default_welcome_contact_allow`) are deployed. Add records only when you need vendor-specific or event-specific overrides.

- **Communication_Event_Policy__mdt**: Event keys, allow/block
- **Communication_Dispatch_Policy__mdt**: Vendor_Program_Key__c, Communication_Type__c, Recipient_Type__c, Send_Enabled__c

---

## Step 14: AccountContactRelation (for PRINCIPAL_OWNER)

For `PRINCIPAL_OWNER` fulfillment policies, subjects are resolved from **AccountContactRelation**.

1. Ensure the dealer Account has Contacts linked via **Account Contact Relationships**
2. On each **AccountContactRelation**, set **Roles** to include "Principal Owner" (or a role containing that text)

---

## Creating an Onboarding Record

Onboarding is created automatically when:

1. An **Opportunity** is created
2. **Vendor_Customization__c** is populated on the Opportunity
3. **BLL_Opportunity_RCD_Logical_Process** runs and creates the Onboarding record

To create onboarding manually or via another path, ensure the flow **DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record** is invoked with the correct Opportunity and Vendor Program inputs.

---

## Managing Requirements

1. Open the **Onboarding__c** record
2. The **Onboarding Record Page** flexipage shows:
   - **objectRelatedList** for Onboarding_Requirement__c (inline edit for Status)
   - **lst:dynamicRelatedList** for Onboarding_Requirements__r
3. Update requirement **Status__c** as needed; status evaluation runs via **BLL_Onboarding_Requirement_RCD_Logical_Process** and the Business Rules Engine

---

## Activating the Vendor Program

Before the program can be used:

1. All child **Vendor_Program_Requirement__c** records must be **Active**
2. Ensure the Vendor Program has **Active__c** checked.

---

## Verification Queries

### Vendor Program

```soql
SELECT Id, Name, Vendor__c, Vendor_Program_Group__c, Active__c
FROM Vendor_Customization__c
WHERE Name = 'Sample Vendor Program'
```

### Requirements with Fulfillment Policy

```soql
SELECT Id, Name, Requirement_Type__c, Fulfillment_Policy_Key__c, Active__c
FROM Vendor_Program_Requirement__c
WHERE Vendor_Program__r.Name = 'Sample Vendor Program'
```

### Vendor Program approval policy key

```soql
SELECT Id, Name, Approval_Policy_Key__c
FROM Vendor_Customization__c
WHERE Name = 'Sample Vendor Program'
```

### Status Normalization (Custom Metadata)

```soql
SELECT DeveloperName, MasterLabel, Requirement_Type__c, Status__c, Normalized_Status__c, Active__c
FROM Onboarding_Status_Normalization__mdt
WHERE Active__c = true
ORDER BY Requirement_Type__c, Status__c
```

### Fulfillment Policies (Custom Metadata)

```soql
SELECT DeveloperName, MasterLabel, Policy_Key__c, Subject_Model__c, Active__c
FROM Onboarding_Fulfillment_Policy__mdt
WHERE Active__c = true
```

### Approval Policies (Custom Metadata)

```soql
SELECT DeveloperName, MasterLabel, Policy_Key__c, Type__c, Approval_Required__c, Active__c
FROM Vendor_Program_Approval_Policy__mdt
WHERE Active__c = true
```

### Vendor Program Training Requirements

```soql
SELECT Id, Name, Vendor_Program__c, Training_Requirement__c
FROM Vendor_Program_Training_Requirement__c
WHERE Vendor_Program__r.Name = 'Sample Vendor Program'
```

### Required Credentials

```soql
SELECT Id, Name, Vendor_Customization__c, External_Contact_Credential_Type__c, Is_Required__c
FROM Required_Credential__c
WHERE Vendor_Customization__r.Name = 'Sample Vendor Program'
```

### Communication Templates

```soql
SELECT Id, Name, Vendor_Program__c, Communication_Type__c, Recipient_Type__c
FROM Communication_Template__c
WHERE Vendor_Program__r.Name = 'Sample Vendor Program'
```

### Onboarding with Requirements and Subjects

```soql
SELECT Id, Name, Onboarding_Status__c,
       (SELECT Id, Requirement_Type__c, Status__c, Completed__c,
        (SELECT Id, Requirement_Type__c, Status__c, Account__c, Contact__c
         FROM Requirement_Subjects__r)
        FROM Onboarding_Requirements__r
        ORDER BY Sequence__c)
FROM Onboarding__c
WHERE Id = :onboardingId
```

---

## Sample Data Scripts

```bash
# Create vendor program (Account, Vendor__c, Vendor_Program_Group__c, Vendor_Customization__c, Vendor_Program_Group_Member__c)
sf apex run --file scripts/sample-data/seed-vendor-program.apex
```

**Note:** The seed script may assume org-specific fields (e.g., **Account__c** on Vendor__c). If it fails, check that required fields exist in your org. Status evaluation is driven by **Onboarding_Status_Normalization__mdt** (deployed with metadata); no additional status-rules setup is required.

---

## Related Documentation

- [Installation Guide](./installation.md) – Deployment
- [Sample Data Setup](./sample-data.md) – Seed script details
- [Data Model](../architecture/data-model.md) – Object relationships
- [Onboarding Requirement Subject Fulfillment](../implementation-notes/onboarding-requirement-subject-fulfillment-2026-03-16.md) – Subject expansion design
