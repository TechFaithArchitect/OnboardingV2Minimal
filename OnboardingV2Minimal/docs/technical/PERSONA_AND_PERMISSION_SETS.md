# Persona and Permission Sets

This document maps **business personas** to **permission sets shipped in source** for OnboardingV2. It extends [Security and Access](./SECURITY_AND_ACCESS.md). Assign in Salesforce per **least privilege** and your org’s segregation of duties. For what users **see** on record pages and flows, see [Onboarding UI and custom components](../reference/ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md).

**End-to-end context:** Step 0 of [Baseline setup guide](../BASELINE_SETUP_GUIDE.md).

## Quick Assignment Guide

If you are onboarding a new user:

1. Identify their primary role (Sales, Operations, Compliance, Finance, Service, or Admin).
2. Assign the matching permission set from the table below.
3. Do not assign config/admin permission sets to general users.
4. Validate access by running one real workflow for that role.

## Permission sets in repository

| Permission set API name                       | Typical persona                                                   | Notes                                                                                              |
| --------------------------------------------- | ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `Onboarding_Program_Sales_Team`               | Sales / reps creating opportunities and running onboarding intake | Align with [Sales User Guide](../sales/SALES_USER_GUIDE.md)                                        |
| `Onboarding_Account_Services`                 | Account services                                                  | Account-level follow-up and onboarding support                                                     |
| `Onboarding_Program_Specialists`              | Onboarding specialists / operations                               | Day-to-day requirement and status work ([Business User Guide](../business/BUSINESS_USER_GUIDE.md)) |
| `Onboarding_Compliance_Team`                  | Compliance                                                        | Policy-sensitive objects and reviews                                                               |
| `Onboarding_Finance_Team`                     | Finance                                                           | Billing / terms-related access as modeled in org                                                   |
| `Onboarding_Customer_Service`                 | Customer service                                                  | Case or onboarding support                                                                         |
| `Onboarding_Status_Rule_Config`               | **Admins / architects**                                           | Status CMDT and related configuration surfaces — **not** for all operators                         |
| `Onboarding_Can_Send_Special_Chuzo_Agreement` | Restricted agreement send                                         | Narrow exception for specific Chuzo agreement flow                                                 |
| `Standard_User`                               | Org standard access baseline                                      | Often bundled with org policy — confirm whether still required in your org                         |

## Source-of-truth details (metadata in repo)

The tables below summarize **what ships in `force-app/main/default/permissionsets`**. Re-run after permission-set edits:

```bash
npm run audit:permissions:highrisk
```

That script **fails** if any set enables blocked **user** permissions (for example **Author Apex**, **Modify All Data**). It **prints** (but does not fail on) object rows with **`modifyAllRecords` true** — review those during access reviews.

### Apex classes enabled by permission set

Operational LWCs call server code **only if** the user’s effective permissions include the corresponding class. Inventory:

| Permission set | `apexClass` entries (enabled) |
| --- | --- |
| `Onboarding_Program_Sales_Team` | `ContactECCController`, `ExpOpportunityCreateAsyncService`, `ExpOpportunityCreateRecord`, `ObjectRelatedListController`, `OnboardingProgressController`, `RecordCollectionEditorAsyncService`, `RecordCollectionEditorConfigService`, `RecordCollectionEditorGetRecordsService`, `VendorOnboardingDTO`, `VendorOptionDTO`, `VendorRetailOptionGroup`, `ers_DatatableController` |
| `Onboarding_Account_Services` | `ContactECCController`, `ObjectRelatedListController`, `OnboardingOrderController`, `OnboardingProgressController`, `VendorFilterController`, `VendorOnboardingDTO`, `VendorOptionDTO`, `VendorRetailOptionGroup`, `ers_DatatableController` |
| `Onboarding_Program_Specialists` | `ContactECCController`, `ObjectRelatedListController` |
| `Onboarding_Compliance_Team` | `ContactECCController`, `ObjectRelatedListController`, `OnboardingProgressController`, `VendorFilterController`, `VendorOnboardingDTO`, `VendorOptionDTO`, `VendorRetailOptionGroup`, `ers_DatatableController` |
| `Onboarding_Finance_Team` | Same class list as Compliance (plus finance custom permissions in metadata). |
| `Onboarding_Customer_Service` | `ContactECCController`, `ObjectRelatedListController` |
| `Onboarding_Can_Send_Special_Chuzo_Agreement` | `ContactECCController`, `ObjectRelatedListController`, `OnboardingProgressController`, `VendorOnboardingDTO`, `VendorOptionDTO`, `VendorRetailOptionGroup`, `ers_DatatableController` |
| `Onboarding_Status_Rule_Config` | `OnboardingStatusEvaluatorInvocable`, `OnboardingStatusEvaluatorService` |
| `Standard_User` | *(no `classAccesses` in this repo’s metadata — signing/template objects only; see below)* |

**Screen flow create path:** `expCreateRecord` + `recordCollectionEditor` require **`ExpOpportunityCreateRecord`**, **`ExpOpportunityCreateAsyncService`** (async tail), **`RecordCollectionEditor*`** services, and lookup rows use **`ObjectRelatedListController`** — all granted on **`Onboarding_Program_Sales_Team`** as of the hardening pass.

### Elevated object permissions (`modifyAllRecords` / broad `viewAllRecords`)

- **`Standard_User`**: Adobe Sign package objects **`echosign_dev1__Agreement_Template__c`**, **`echosign_dev1__Library_Template__c`**, **`echosign_dev1__SIGN_Agreement__c`** use **`modifyAllRecords` true** (plus **`viewAllRecords` true** on those rows). Treat this set as a **signing/template capability bundle**, not a minimal read-only baseline; avoid assigning it broadly unless your policy requires users to maintain agreement templates across the org.
- **`Onboarding_Account_Services`**: **`Order`** — **`modifyAllRecords` was narrowed to `false`** (April 2026 hardening) while retaining edit/delete/read where metadata allows; **`viewAllRecords` remains true** for visibility. If Account Services users must correct **any** order regardless of sharing, restore **`modifyAllRecords` true** deliberately and document the exception.

### Org-level user permission toggles in these sets

Several onboarding permission sets enable **`ActivateContract`**; **`Onboarding_Account_Services`** also enables **`ActivateOrder`**. No **`AuthorApex`** / **`ModifyAllData`** user permissions are enabled in source (verified by `audit:permissions:highrisk`).

## Suggested assignment patterns (verify in your org)

- **Baseline testing:** At minimum, a **sales** test user and an **operations** test user so you can validate create vs manage paths separately.
- **Status rule editing:** Limit `Onboarding_Status_Rule_Config` to people who own CMDT change control.
- **Integration credentials:** Users do **not** substitute for **Named Credentials** / integration users; keep those separate ([Integrations](./INTEGRATIONS.md)).

## Training checklist for new team members

| Step | Action                                                                                                                                    |
| ---- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Confirm **persona** and assigned **permission sets** in target org                                                                        |
| 2    | Skim [Object catalog](./OBJECT_CATALOG.md) and [Onboarding UI and custom components](../reference/ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md) |
| 3    | Read the relevant user guide (Sales, Business, or Admin runbook)                                                                          |
| 4    | For **create path**, optionally walk [Screen flow click-path runbook](../business/SCREEN_FLOW_CLICK_PATH_RUNBOOK.md)                      |
| 5    | Know how to escalate with artifacts ([Support](../support/SUPPORT_AND_TROUBLESHOOTING.md#required-artifacts-for-any-ticket))              |

## Related

- [Security and Access](./SECURITY_AND_ACCESS.md)
- [FAQ — Users](../support/FAQ_USERS.md)
- [FAQ — Admins](../support/FAQ_ADMINS.md)
