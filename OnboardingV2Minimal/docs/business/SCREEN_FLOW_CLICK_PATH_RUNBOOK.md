# Screen Flow Click-Path Runbook (Onboarding Create)

Use this runbook to capture **org-specific navigation** for the main onboarding **creation** experience (`EXP_Opportunity_SCR_Create_Record`). It complements the narrative in the [Sales User Guide](./SALES_USER_GUIDE.md) and the system path in [System Overview](../technical/SYSTEM_OVERVIEW.md#1-opportunity-led-onboarding-creation).

**End-to-end context:** Admin-side UI steps (vendor → program → requirements) are in [Baseline UI walkthrough](../BASELINE_UI_WALKTHROUGH.md). This runbook is **Step 4** optional screenshot detail in [Baseline setup guide](../BASELINE_SETUP_GUIDE.md).

## What This Is (and is not)

- This is a screenshot-ready click checklist.
- It is not a policy/config guide.
- Use it to standardize user training and UAT evidence.

## Before you document

- Confirm which **permission sets** grant the flow ([Persona and permission sets](../technical/PERSONA_AND_PERMISSION_SETS.md)).
- Note the **Lightning app** users launch from (typically **Onboarding**).

## Click path (fill in for your org)

Replace bracketed hints with your org’s exact labels, tabs, and URLs if you publish internally.

| Step | Where to click / what to open                                                                    | What to verify (baseline)                                                                | Screenshot slot                         |
| ---- | ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | --------------------------------------- |
| 1    | Open **Salesforce** as a test user with sales onboarding access                                  | User lands in expected app                                                               | `![Step 1](images/onboard-flow-01.png)` |
| 2    | Navigate to **Opportunity** (or Account then related opportunity)                                | Opportunity is suitable for test (record type, stage if required)                        | `![Step 2](images/onboard-flow-02.png)` |
| 3    | Launch **`EXP_Opportunity_SCR_Create_Record`** (button, action, or utility—the label may differ) | Screen flow starts; no immediate error                                                   | `![Step 3](images/onboard-flow-03.png)` |
| 4    | Complete **intake** and choose **vendor program** when prompted                                  | Selection matches an **Active** `Vendor_Customization__c`                                | `![Step 4](images/onboard-flow-04.png)` |
| 5    | Set **primary opportunity contact** per policy                                                   | Role/eligibility matches [Sales User Guide](./SALES_USER_GUIDE.md#field-guide-for-sales) | `![Step 5](images/onboard-flow-05.png)` |
| 6    | Finish flow through **contract/opportunity** outcomes described in your org                      | Success or documented next screen                                                        | `![Step 6](images/onboard-flow-06.png)` |
| 7    | Open **Onboarding** record (related list, tab, or global search)                                 | Record exists; links to Account, Opportunity, Contract as expected                       | `![Step 7](images/onboard-flow-07.png)` |
| 8    | If tail is **deferred**, wait and **refresh**                                                    | Onboarding appears after async work ([FAQ — Users](../support/FAQ_USERS.md))             | Optional                                |

## Optional: Onboarding record page highlights

Document where operations usually work (related lists, key fields). Add screenshots under `docs/business/images/` (or your static site) when ready.

| Area         | API / object                        | Notes                                  |
| ------------ | ----------------------------------- | -------------------------------------- |
| Requirements | `Onboarding_Requirement__c`         | Related list or component name: \_\_\_ |
| Subjects     | `Onboarding_Requirement_Subject__c` | Often via requirement                  |
| Error log    | `Error_Log__c`                      | If visible to this persona             |

## Maintenance

When the **Flow API name** or **entry button** changes after a release, update this table and record the change in [Release notes template](../admin/RELEASE_NOTES_AND_SMOKE_TEST_TEMPLATE.md).
