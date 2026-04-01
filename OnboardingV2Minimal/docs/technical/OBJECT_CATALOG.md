# Object Catalog (What Exists and Why It Matters)

Use this page **after** [Data Model](./DATA_MODEL.md). The data model doc explains **how the core graph fits together**. This catalog answers: **“Is this object part of main onboarding or something else?”**

Counts and names come from source under `force-app/main/default/objects`. Packaged objects (e.g. some LearnUpon or Adobe types) may exist in your org but not in this repo.

## Tier 1 — Core onboarding graph (learn these first)

| Object                                 | Role in one sentence                                                                                                                     |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `Onboarding__c`                        | The main **living record** for one account’s onboarding on a program.                                                                    |
| `Onboarding_Requirement__c`            | One **milestone** under that onboarding (from the program template).                                                                     |
| `Onboarding_Requirement_Subject__c`    | **Who** owes work for that milestone (contact/account slice).                                                                            |
| `Vendor_Customization__c`              | The **vendor program** definition (what requirements exist, contract hints, etc.).                                                       |
| `Vendor__c`                            | The **vendor** parent of programs (master-detail parent for `Vendor_Customization__c`).                                                  |
| `Vendor_Program_Requirement__c`        | **Template** rows that become onboarding requirements.                                                                                   |
| `Account_Vendor_Program_Onboarding__c` | **Account-level** program onboarding rollup/sync row (ties account + program context; synced from automation—see deployment/admin docs). |

## Tier 2 — Policy and messaging (mostly CMDT and comms)

| Object / CMDT family                                                                                                       | Role                                                                             |
| -------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `Onboarding_*__mdt` (normalization, evaluation, next step, fulfillment, performance, logging, automation, default vendor…) | **Rules** that drive status, subjects, speed, and defaults.                      |
| `Communication_Event_Policy__mdt`, `Communication_Dispatch_Policy__mdt`                                                    | **When** and **to whom** communications may send.                                |
| `Communication_Template__c`, `Communication_Template_Assignment__c`                                                        | **Which email template** belongs to which program.                               |
| `Vendor_Program_Approval_Policy__mdt`                                                                                      | **Gates** that pause requirement creation until approval.                        |
| `Vendor_Onboarding_Eligibility_Rule__mdt`                                                                                  | **Which programs** an account may select.                                        |
| `Child_Record_Editor_Config__mdt`                                                                                          | **Field layouts** for the flow `recordCollectionEditor` component.               |
| `Contract_Record_Type_Reference__c`                                                                                        | Maps programs to **contract record types**.                                      |
| `Error_Log__c`                                                                                                             | **Automation errors** for triage (not a business object users fill for process). |
| `Onboarding_Opportunity_Chain__e`                                                                                          | **Platform event** for deferred onboarding tail progress (technical signal).     |

## Tier 3 — Evidence, training, credentials

| Object                                                                                                  | Role                                                                          |
| ------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `POE_External_Contact_Credential__c`                                                                    | Stores **credential evidence** per contact (background check, license, etc.). |
| `External_Contact_Credential_Type__c`                                                                   | **Types** of credentials.                                                     |
| `Required_Credential__c`                                                                                | **Which credentials** a program or path requires.                             |
| `Required_External_Contact_Credential__c`                                                               | Links required credentials into flows that create ECC rows.                   |
| `Training_Requirement__c`, `Training_System__c`                                                         | **Catalog** of training courses/systems.                                      |
| `Training_Assignment__c`, `Training_Assignment_Onboarding__c`, `Vendor_Program_Training_Requirement__c` | **Assignments** and **program links** for training evidence.                  |

## Tier 4 — Compliance, finance, and program satellites

These objects are **real** in many orgs and may appear on layouts or flows, but they are **not** the same as Tier 1 “spine” objects. Treat them as **domain satellites** until your business confirms scope:

`Background_Check__c`, `Chuzo_Agreement__c`, `Clearing_House__c`, `Commercial_L_I_Information__c`, `Credit_Check__c`, `Dealer_Compliance__c`, `Dealer_Insurance__c`, `Interview__c`, `Labor_Form__c`, `License__c`, `Net_Terms__c`, `Personal_Guarantee__c`, `POE_Dealer_Code__c`, `Territory_Assignments__c`, `Vendor_Order_Entry_Platform__c`, and related **ECC field configuration** objects (`ECC_Field_*`).

## Tier 5 — Salesforce rules engine artifacts

| Object                                  | Notes                                                                                                                                                 |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ExpressionSet`, `ExpressionSetVersion` | Used with **business rules** flows (see [BRE and credentials primer](../reference/BRE_AND_CREDENTIALS_FOR_NEW_USERS.md)). Not “onboarding data” rows. |

## Standard objects you will touch constantly

`Account`, `Contact`, `Opportunity`, `OpportunityContactRole`, `AccountContactRelation`, `Contract` — the **create path** links these to `Onboarding__c`.

## Related docs

- [Data Model](./DATA_MODEL.md)
- [Manual Vendor Program Setup](../admin/MANUAL_VENDOR_PROGRAM_SETUP.md)
- [Baseline setup guide](../BASELINE_SETUP_GUIDE.md)
