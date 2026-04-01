# Onboarding UI: Record Pages, Flows, and Custom Components

This page is for **new users** who see custom Lightning pieces in Salesforce and want to know **what they are for**—without reading code.

**See also:** [Screen flow click-path runbook](../business/SCREEN_FLOW_CLICK_PATH_RUNBOOK.md) · [Data model](../technical/DATA_MODEL.md) · [Object catalog](../technical/OBJECT_CATALOG.md)

## Where custom UI shows up

1. **Record pages** — e.g. **`Onboarding_Record_Page`** on `Onboarding__c`: related lists, progress, sometimes credentials.
2. **Screen flows** — steps in flows whose API name starts with **`EXP_`**: guided “wizard” screens when creating an opportunity/onboarding path.
3. **Other Lightning pages** — a few components also allow **App** or **Record** placement; the table below says which.

Components marked **internal** are used as building blocks inside other components; you normally do not add them yourself in App Builder.

## Record page: `Onboarding__c` (high level)

The onboarding record page mixes **standard Salesforce** pieces (highlights, feed, activities, standard related lists) with **custom** pieces:

| Custom piece (bundle name)         | What it does for a new user                                                                                                                                                                                                     |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`objectRelatedList`**            | A **configurable related list**: admins point it at a child object (API name) and fields so teams see the right rows (requirements, subjects, program dates, etc.) without code changes.                                        |
| **`onboardingECC`**                | Shows **external contact credential** context tied to this onboarding (evidence the business collects per contact). Goes with the **credential** story in [BRE and credentials primer](./BRE_AND_CREDENTIALS_FOR_NEW_USERS.md). |
| **`onboardingCompletionProgress`** | **Referenced** on the Onboarding flexipage metadata for a “completion progress” area. If you do not see it in your org, the component bundle may not be deployed in that branch—treat as optional until your admin confirms.    |

## Flow screens (screen flows)

These bundles are built for **`lightning__FlowScreen`** (unless noted):

| Component                      | Plain-English role                                                                                                                                                                                                                  |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`vendorSelector`**           | Picks a **vendor** during a flow; options usually come from Apex (`VendorOptionDTO` JSON) so eligibility rules stay consistent.                                                                                                     |
| **`vendorProgramSelector`**    | Picks a **vendor program** (`Vendor_Customization__c`). Can appear on record or app surfaces too (metadata allows it).                                                                                                              |
| **`recordCollectionEditor`**   | Lets the user **add or edit many child rows** on one screen (contacts, program dates, etc.). **Configuration** comes from **`Child_Record_Editor_Config__mdt`** via the `configKey` property—your admin defines field layout there. |
| **`onboardingPathSelector`**   | Chooses an onboarding **path** or program branch inside a screen flow context.                                                                                                                                                      |
| **`programDatesScreenAction`** | Program-dates interaction step inside a flow.                                                                                                                                                                                       |
| **`reactStylePhoneInput`**     | Phone input used where phone formatting matters (flow, record, or app page).                                                                                                                                                        |

## Quick actions and wrappers

| Component                                            | Where                       | Role                                                                                                                                                            |
| ---------------------------------------------------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`programDatesQuickAction`**                        | Record action / record page | Opens or drives program-date maintenance from a record.                                                                                                         |
| **`relatedObjectActionModal`** (“New Program Dates”) | Record action / record page | Modal pattern for creating related program-date rows.                                                                                                           |
| **`programDatesRelatedListWrapper`**                 | Record page                 | Wrapper that hosts the program dates related list UX (see small [README](../../force-app/main/default/lwc/programDatesRelatedListWrapper/README.md) in source). |

## Internal building blocks (not exposed in App Builder)

These have **`isExposed = false`** in metadata: **`onboardingWorkQueue`**, **`onboardingInsights`**, **`onboardingVendorProgramGrid`**, **`onboardingRuleModal`**, **`onboardingRecentActivity`**, **`onboardingKpiRow`**, **`objectRelatedListDatatable`**, **`programDatesRelatedList`**, **`onboardingDealerOnboardingModal`**. Another component **composes** them—if you are debugging UI, start with the **parent** that **is** exposed.

## Other record-page components

| Component                         | Typical use                                                                                  |
| --------------------------------- | -------------------------------------------------------------------------------------------- |
| **`onboardingOrderStatusViewer`** | Read-only or status view when **order**-flavored onboarding objects are in play on the page. |

## If something looks wrong on the page

1. **Blank component** — check **field- and object-level security** and **permission sets** ([Persona and permission sets](../technical/PERSONA_AND_PERMISSION_SETS.md)).
2. **Wrong rows in `objectRelatedList`** — admin checks **child object**, **parent lookup field**, and **parent id source** in Lightning App Builder (see bundle description in `objectRelatedList.js-meta.xml`).
3. **Flow screen misbehaves** — use [FAQ — Admins](../support/FAQ_ADMINS.md) and flow debug; **`recordCollectionEditor`** errors often trace to **`Child_Record_Editor_Config__mdt`** mismatch.

## Source locations

All bundles live under `force-app/main/default/lwc/<bundleName>/`. Flexipage XML lives under `force-app/main/default/flexipages/`.
