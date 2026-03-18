# Executive Summary: Deployed Changes (March 2026)

This document summarizes the changes deployed to the OnboardV2 org as of March 2026.

---

## 1. Onboarding Requirement Subject Fulfillment

**What it does:** Distinguishes *what* must be satisfied from *who* must satisfy it.

- **Problem solved:** Some vendor program requirements are satisfied at the account level (e.g., internal background check where the principal owner passes); others require every contact on the account (e.g., vendor background check); still others target a specific contact (e.g., driver’s license).
- **Solution:** A new runtime object `Onboarding_Requirement_Subject__c` tracks which Account or Contact must satisfy each onboarding requirement. Each requirement gets a **Fulfillment Policy** (e.g., ACCOUNT_ONLY, ALL_CONTACTS, PRINCIPAL_OWNER) that drives how subjects are expanded.
- **Impact:** Requirements can now be evaluated per subject (account or contact). Training completion, credentials, and other evidence can update subject status, which rolls up to the parent `Onboarding_Requirement__c`.

---

## 2. Idempotent Subject Creation (Unique_Key__c)

**What it does:** Prevents duplicate subject records when onboarding requirements are created or re-run.

- **Problem solved:** Re-running subject expansion could create duplicate `Onboarding_Requirement_Subject__c` rows for the same requirement + subject.
- **Solution:** `OnboardingRequirementSubjectInvocable` pre-filters subjects by existing `Unique_Key__c` before insert. Only new subjects are created.
- **Impact:** Safe to re-run subject creation; no duplicate-key errors or redundant rows.

---

## 3. Flow Fault Handling

**What it does:** Captures failures instead of failing flows silently or terminating without context.

- **Flows updated:** `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements`, `BLL_BRE_Evaluate_Business_Rules`, `DOMAIN_OmniSObject_SFL_CREATE_Follow_Up_Queue`, `EXP_Contract_SCR_Send_Adobe_Agreement`, `DOMAIN_OmniSObject_SFL_CREATE_Training_Assignment_Records`, plus communication, Record Collection Editor, and onboarding-create flows.
- **Behavior:** Fault connectors route errors to `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message`, which creates `Follow_Up_Queue__c` records with `Status__c = Failed` and detailed error context.
- **Impact:** Admins can see and triage failures in the Follow Up Queue instead of losing them.

---

## 4. Training Evidence → Subject Status

**What it does:** Connects training assignment completion to onboarding requirement subjects.

- **Flow:** `BLL_OmniSObject_RCD_SYNC_Training_Assignments` syncs training assignments and calls `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_By_Evidence` to update matching subjects (e.g., Training Complete → Setup Complete).
- **Rollup:** Changed subjects trigger parent `Onboarding_Requirement__c` reevaluation via `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_Parent`.
- **Impact:** Training completion automatically updates requirement status for contact-scoped and account-scoped subjects.

---

## 5. Legacy Flow Removal

**What it does:** Removes obsolete flows and quick actions from the org.

- **Removed:** `EXP_Contact_SCR_Set_Up_Agent_Vendor_Programs`, `DOMAIN_Contact_SFL_GET_Account_Information_from_Contact_Record`, `Contact.Set_Up_Agent_on_Vendor` quick action.
- **Reason:** These flows referenced a subflow that no longer exists and are no longer used.
- **Impact:** Cleaner org, no orphaned or broken flow references.

---

## 6. Security, Logging, and Operability

**What it does:** Hardens sharing, FLS, and logging across the codebase.

- **Apex:** `with sharing`, `WITH SECURITY_ENFORCED`, parameter validation, safe dynamic SOQL.
- **Logging:** Replaced ad hoc `System.debug` with `LoggingUtil` in production classes.
- **Invocables:** Typed facades (`OnboardingInvocables`, `OnboardingFollowUpInvocables`) for Flow integration.
- **Makefile:** `make audit` and `audit-flow-fault-connectors.sh` for flow fault-connector gap audits.
- **Impact:** Better security posture, consistent logging, and easier automation audits.

---

## Summary Table

| Area | Change | Benefit |
|------|--------|---------|
| Subject fulfillment | New `Onboarding_Requirement_Subject__c` + fulfillment policies | Per-subject (account/contact) requirement evaluation |
| Duplicate prevention | `OnboardingRequirementSubjectInvocable` + `Unique_Key__c` filtering | Idempotent subject creation |
| Fault handling | Fault connectors on high-priority flows | Failures logged to Follow Up Queue |
| Training evidence | Evidence evaluator + parent rollup | Training completion drives requirement status |
| Cleanup | Legacy flows and quick action removed | No orphaned or broken references |
| Security & ops | Sharing, FLS, logging, invocables, Makefile | Stronger security and auditability |

---

## Next Steps (Not Yet Deployed)

- Evidence evaluators for agreements, credentials, and contract-backed compliance
- Subject-level evidence matching from external systems
- Duplicate reconciliation / idempotency rules beyond `Unique_Key__c` for edge cases
