# Onboarding V2 — Repository logic specification

**Scope:** This document is derived **only** from metadata and code under `force-app/main/default` in this workspace (March 2026 snapshot). It intentionally does **not** incorporate other narrative docs in the repo or external runbooks, which may be stale.

**Purpose:** Give product and engineering a single map of what **actually ships here**: data model, automation, rules, UI, and known gaps relative to a full “Onboarding V2” mental model.

---

## 1. High-level overview

Onboarding V2 centers on an **`Onboarding__c`** record per account (and linked **Opportunity**, **Contract**, **Vendor program**). Each onboarding owns **`Onboarding_Requirement__c`** rows (one per requirement type for that program). Requirements can be fulfilled at the **account** level or via per-person **`Onboarding_Requirement_Subject__c`** rows, depending on configuration and flows.

**Driving themes in code:**

1. **Vendor eligibility** — Which vendor programs an account may start, given existing onboardings, completion, cancellation, vendor-specific CMDT rules, and **program prerequisite groups** (`Vendor_Program_Group_Member__c`).
2. **Requirement lifecycle** — Record-triggered flows create related records, run **BRE** (`BLL_BRE_Evaluate_Business_Rules`), dispatch communications, and roll up subject → requirement → onboarding.
3. **Onboarding status** — **`OnboardingStatusNormalizationService`** loads **`Onboarding_Status_Normalization__mdt`**; **`OnboardingStatusEvaluatorService`** builds context and delegates rule matching to **`IOnboardingStatusRuleEngine`** (default **`OnboardingStatusCmdtRuleEngine`** → **`OnboardingStatusPredicateInterpreter`** reading **`Predicate_Config__c`** JSON on **`Onboarding_Status_Evaluation_Rule__mdt`**). First matching rule wins; DML updates **`Onboarding__c.Onboarding_Status__c`** and **Opportunity** stage. See [ADR-001](adr/ADR-001-onboarding-status-evaluation-engine.md) and [onboarding-status-predicate-config.md](onboarding-status-predicate-config.md).

**Orchestration style:** Heavy use of **after-save record-triggered flows** on `Onboarding__c`, `Onboarding_Requirement__c`, and related objects, calling **subflows** prefixed `DOMAIN_OmniSObject_SFL_*` (data retrieval / creation) and **`BLL_*`** (business logic). There are **no Apex triggers** on onboarding objects in this package (only `TerritoryAssignmentsTrigger` elsewhere).

---

## 2. Business user guide (“How to”)

This section describes how the application *behaves* as implied by metadata and UI components—not a substitute for org-specific training.

### 2.1 Where to work

- Open the **Onboarding** Lightning console app (`applications/Onboarding.app-meta.xml`). Primary tabs include **Onboardings**, **Accounts**, **Vendor Programs** (`Vendor_Customization__c`), **Vendor Program Requirements**, **Onboarding Requirements**, **Contracts**, and **Agreements** (Adobe Sign). Onboarding status behavior is configured via **custom metadata** (`Onboarding_Status_Normalization__mdt`, `Onboarding_Status_Evaluation_Rule__mdt`), not custom objects in this package.
- **Onboarding** and **Onboarding Requirement** record pages and LWCs show program progress, requirement completion, and actions such as **View** / **Launch wizard** on vendor programs (`onboardingVendorProgramGrid`).

### 2.2 Typical lifecycle (conceptual)

1. **Choose a vendor program** for an account. Eligibility is computed in **`VendorOnboardingService`**: inactive vendors or programs are excluded; existing onboardings block the same customization unless status is canceled/denied; vendor-program keys (vendor + retail option) block duplicates; optional **prerequisite groups** require prior programs to be **completed** (and optionally use **OR** group logic).
2. **Create an onboarding** (`Onboarding__c`) linked to **Account**, **Vendor_Customization__c**, and often **Opportunity** / **Contract**. After save, **`BLL_Onboarding_RCD_Logical_Process`** runs: creates requirements, may align opportunity from contract, dispatches communications, and invokes **BRE**.
3. **Requirements** (`Onboarding_Requirement__c`) update as agreements/contracts/trainings/evidence progress. **`BLL_Onboarding_Requirement_RCD_Logical_Process`** creates related rows when needed, calls BRE, then **`OnboardingStatusEvaluatorInvocable`** with **apply updates = true** to refresh **`Onboarding_Status__c`** and opportunity stage from CMDT rules.
4. **Per-contact fulfillment** uses **subjects** and **fulfillment policy** CMDT (`Onboarding_Fulfillment_Policy__mdt` with `Subject_Model__c`: Account, All Contacts, Primary Contact Or Account, Principal Owner). DOMAIN flows resolve who gets requirement subjects.
5. **Training / LearnUpon** — Flows link **Training_Assignment_Onboarding__c**, **LearnUpon** enrollments, and onboarding records; scheduled / record-triggered flows **review and assign missing** training or onboarding links.
6. **Follow-ups** — **`OnboardingFollowUpInvocables`** delegates to **`FollowUpDetectionService.evaluateAndCreateFollowUpsBulk`** when flows request evaluation for a requirement.

### 2.3 What admins configure

| Area | Mechanism |
|------|-----------|
| Raw requirement status → normalized category | **`Onboarding_Status_Normalization__mdt`** (~173 records) via **`OnboardingStatusNormalizationService`** (sole source for the evaluator path). BRE **OnboardingStatusNormalization** is **not** invoked by this Apex path—avoid duplicating mappings there. |
| Which rule → onboarding status / opportunity stage | **`Onboarding_Status_Evaluation_Rule__mdt`**: **`Predicate_Config__c`** JSON (required for a rule to match). Optional **`Condition_Type__c`** is documentation/UI only. Permission set **`Onboarding_Status_Rule_Config`** + custom permission **`Onboarding_Status_Rule_Config`** for future rules UI. |
| Default vendor program when a scenario (e.g. NDA) applies | **`Onboarding_Default_Vendor_Program__mdt`** + **`OnboardingDefaultVendorProgramInvocable`** |
| Who receives requirement subjects | **`Onboarding_Fulfillment_Policy__mdt`** (`Policy_Key__c`, `Subject_Model__c`) |
| Vendor-specific eligibility (block modes, prerequisites on/off) | **`Vendor_Onboarding_Eligibility_Rule__mdt`** (type exists; **no sample rows in `customMetadata/`** — defaults apply in code) |
| Approval / block behavior for vendor programs | **`Vendor_Program_Approval_Policy__mdt`** + BRE **VendorProgramApprovalPolicyResolver** |
| Program prerequisite ordering | **`Vendor_Program_Group__c`**, **`Vendor_Program_Group_Member__c`** (target vs required programs, `Logic_Type__c` AND/OR) |
| Communications tied to onboarding events | **CommunicationDispatchResolver** BRE (includes **`IsOnboardingCreatedEvent`**) and dispatch subflows **`BLL_Onboarding_SFL_Dispatch_Communication_*`** |

---

## 3. Technical reference

### 3.1 Core custom objects (spine)

| Object | Role |
|--------|------|
| **`Onboarding__c`** | Header: account, vendor program, opportunity, contract, agreement links, **Onboarding_Status__c**, **Assigned_Team__c**, many legacy/parallel status fields (agreement, contract, insurance, ERP, LearnUpon, etc.). |
| **`Onboarding_Requirement__c`** | One row per requirement type on an onboarding: **Requirement_Type__c**, **Status__c**, **Is_Overridden__c**, **Completed__c**, links to parent onboarding. |
| **`Onboarding_Requirement_Subject__c`** | Person/account-scoped fulfillment; **Unique_Key__c** for idempotent creation. |
| **`Account_Vendor_Program_Onboarding__c`** | Junction linking account / vendor program context to onboarding (used in broader automation). |
| **`Vendor__c`**, **`Vendor_Customization__c`** | Vendor master and **vendor program** (retail option, vertical, templates, record types). |
| **`Vendor_Program_Requirement__c`** | Template of which requirements a program needs. |
| **`Vendor_Program_Group__c`**, **`Vendor_Program_Group_Member__c`** | Prerequisite groups: **Is_Target__c** program vs **Required_Program__c**, **Logic_Type__c**. |
| **`Vendor_Program_Training_Requirement__c`**, **`Training_Assignment_Onboarding__c`** | Training requirement definition and junction to training assignments. |

### 3.2 Custom metadata types (CMDT)

| Type | Bundled records (repo) | Used by |
|------|-------------------------|---------|
| **`Onboarding_Status_Normalization__mdt`** | ~173 | `OnboardingStatusNormalizationService` |
| **`Onboarding_Status_Evaluation_Rule__mdt`** | 10 | `OnboardingStatusCmdtRuleEngine` / `OnboardingStatusPredicateInterpreter` via `OnboardingStatusEvaluatorService` |
| **`Onboarding_Fulfillment_Policy__mdt`** | Yes | DOMAIN GET fulfillment policy flow |
| **`Onboarding_Default_Vendor_Program__mdt`** | e.g. REQUIRE_NDA | `OnboardingDefaultVendorProgramInvocable` |
| **`Onboarding_Logging_Config__mdt`** | Default | Logging |
| **`Vendor_Program_Approval_Policy__mdt`** | Sample (e.g. Verizon) | BRE resolver |
| **`Vendor_Onboarding_Eligibility_Rule__mdt`** | **None in repo** | `VendorOnboardingEligibilityRuleEngine` |
| **`Onboarding_Automation_Config__mdt`**, **`Onboarding_Next_Step_Rule__mdt`** | Types only (listed in manifest) | **No references in Apex/flows in this repo** |

### 3.3 Onboarding status evaluation (Apex)

| Component | Role |
|-----------|------|
| **`OnboardingStatusNormalizationService`** | Loads active **`Onboarding_Status_Normalization__mdt`** map; normalizes requirement raw status. |
| **`OnboardingStatusEvaluatorService`** | Loads onboarding, requirements, opportunity, and **active required `Vendor_Program_Requirement__c` types** for the onboarding’s vendor program; builds **`EvaluationContext`**; queries rules once per bulk call; uses injectable **`IOnboardingStatusRuleEngine`**; **`evaluateAndApply*`** DMLs onboarding + **one opportunity stage per opp** (first onboarding in bulk wins for stage). |
| **`OnboardingStatusCmdtRuleEngine`** | Default engine: **`OnboardingStatusPredicateInterpreter.ruleMatchesRule`**. |
| **`OnboardingStatusPredicateInterpreter`** | Parses **`Predicate_Config__c`** JSON (`all` / `any` / `op`); blank JSON never matches. New **semantic** = new `op` branch in **one** class (see [onboarding-status-predicate-config.md](onboarding-status-predicate-config.md)). |
| **`OnboardingStatusEvaluatorInvocable`** | Flow entry (`evaluate` / `evaluateAndApply`). |

**Bundled rule order and outcomes** (each row includes JSON in **`Predicate_Config__c`** in repo):

| Order | Target onboarding status |
|------:|---------------------------|
| 10 | Denied |
| 20 | Canceled |
| 22 | Canceled |
| 25 | Expired |
| 30 | Setup Complete |
| 40 | Paperwork Sent |
| 50 | Pending Initial Review |
| 60 | In Process |
| 70 | Pending Sales |
| 80 | In Process |

**BRE OnboardingStatusNormalization:** Not called by this evaluator. Prefer **CMDT-only** normalization here; retire or repurpose the expression set to avoid drift.

### 3.3.1 Flow hygiene

Onboarding **`Onboarding_Status__c`** should not be derived from large Flow decision trees. **Grep** shows triggers use field **change detection** and **queries** only; status **assignment** for business outcomes should go through **`OnboardingStatusEvaluatorInvocable`**. Order flow **`BLL_Order_RCD_Business_Logic`** also invokes the evaluator—keep that pattern for cross-object updates.

### 3.4 Vendor eligibility (Apex)

**`VendorOnboardingService.getEligibleVendors`**

- Ignores existing onboardings whose status normalizes to **CANCELED/CANCELLED/DENIED** for blocking.
- Treats **COMPLETE / SETUP COMPLETE** (and variants) as **completed** for prerequisite and vendor-level rules.
- Blocks same **`Vendor_Customization__c`** if an active onboarding exists.
- Blocks same **vendor + retail option** key across customizations.
- Loads **`Vendor_Onboarding_Eligibility_Rule__mdt`** by vendor name (uppercase). **Default rule:** block same program, **use prerequisites = true**.
- **`BLOCK_VENDOR_ON_ANY_COMPLETE`**: hide all programs for that vendor if any program completed.
- **`VendorPrerequisiteEvaluator`**: loads active **`Vendor_Program_Group_Member__c`**; builds target → required map; **AND** default or **OR** group logic.

**Entry points:** `@AuraEnabled` `getVendorOptions`, `@InvocableMethod` `getVendorsAsJson`, `OnboardingInvocables.getEligibleVendorsJson`, DTO helpers for flows.

### 3.5 Requirement subjects and evidence (Apex)

| Class | Role |
|-------|------|
| **`OnboardingRequirementSubjectInvocable`** | Idempotent insert of subjects by **Unique_Key__c**. |
| **`OnbReqParentBulkEvalInvocable`** | Bulk roll-up **subject statuses → requirement Status__c / Completed__c**. Used by DOMAIN eval subflows. |
| **`OnbReqContractEvidenceInvocable`** | Contract-scoped evidence: update subjects, roll up parents, optional **onboarding status** evaluation. |

### 3.6 Default vendor program (Apex)

**`OnboardingDefaultVendorProgramInvocable`** — resolves **`Vendor_Customization__c`** by **`Onboarding_Default_Vendor_Program__mdt.Scenario_Key__c`**, **Vendor_Name__c**, optional **Vendor_Program_Name_Contains__c**, with documented fallbacks and logging.

### 3.7 Follow-ups (Apex)

**`OnboardingFollowUpInvocables.evaluateFollowUps`** → **`FollowUpDetectionService.evaluateAndCreateFollowUpsBulk`** (implementation not expanded here; grep shows broader follow-up services in the package).

---

## 4. Flows and automation matrix

### 4.1 Record-triggered (primary)

| Flow API name | Object | When | Main behavior |
|---------------|--------|------|----------------|
| **`BLL_Onboarding_RCD_Logical_Process`** | `Onboarding__c` | After save, create & update | Branches on create vs **LearnUpon_Triggered__c** / **Onboarding_Status__c** changes; subflows: **CREATE_Onboarding_Requirements**, **Dispatch_Communication_By_Event** (×2), **BLL_BRE_Evaluate_Business_Rules** (×2), GET contract / vendor program / program requirements; aligns **Opportunity__c** from contract when applicable. |
| **`BLL_Onboarding_Requirement_RCD_Logical_Process`** | `Onboarding_Requirement__c` | After save, create & update | Creates related records (**CREATE_Related_Onboarding_Requirement_Records**), BRE, GETs account/onboarding/opportunity/vendor program; **OnboardingStatusEvaluatorInvocable**; fault handling via **CREATE_Fault_Message**. |
| **`BLL_Onboarding_Requirement_Subject_RCD_Logical_Process`** | `Onboarding_Requirement_Subject__c` | After update | Subject-level logic (downstream eval — see DOMAIN EVAL flows). |
| **`BLL_Onboarding_RCD_Prevent_Duplicates`** | `Onboarding__c` | Create & update | Duplicate prevention. |
| **`BLL_Training_Assignment_Onboarding_RCD_Prevent_Duplicates`** | `Training_Assignment_Onboarding__c` | Create & update | Duplicate prevention. |

### 4.2 Autolaunched DOMAIN / BLL subflows (onboarding-named)

**Creation / retrieval**

- `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record`
- `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements`
- `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirement_Subjects`
- `DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records`
- `DOMAIN_OmniSObject_SFL_GET_Onboarding_Records`
- `DOMAIN_OmniSObject_SFL_GET_Onboarding_Requirement`
- `DOMAIN_OmniSObject_SFL_GET_Onboarding_Requirement_Subjects`
- `DOMAIN_OmniSObject_SFL_GET_Onboarding_Fullfilment_Policy` (spelling as in metadata)
- Plus related **GET_Vendor_Program**, **GET_Vendor_Program_Requirements**, **GET_Vendor_Program_Group_Members**, etc.

**Evaluation**

- `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_For_Onb_Rec` — calls **`OnbReqParentBulkEvalInvocable`**
- `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_Parent`
- `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_By_Evidence`

**Communications / training / LearnUpon**

- `BLL_Onboarding_SFL_Dispatch_Communication_By_Context`
- `BLL_Onboarding_SFL_Dispatch_Communication_By_Event`
- `BLL_Onboarding_SFL_Assign_LearnUpon_Credentials`
- `BLL_Onboarding_SCD_Review_and_Assign_Missing_Training_Records`
- `BLL_LearnUponContactEnrollment_SCD_Review_Assign_Missing_Onboarding_Records`

**Related**

- `BLL_Vendor_Program_Requirement_RCD_Enforce_Contract_Agreement_Sequence`
- `BLL_Vendor_Program_Training_Requirement_RCD_Prevent_Duplicates`
- `BLL_BRE_Evaluate_Business_Rules` — central BRE invocation (also used from Order/Opportunity/Contract flows that mention onboarding)

Other flows in the repo reference onboarding fields or objects (e.g. Order, Opportunity); treat them as **adjacent pipelines** that share BRE or data.

### 4.3 Flow definition pin

- `flowDefinitions/BLL_External_Contact_Credential_RCD_Execute_Supplemental_Onboarding_Requirements.flowDefinition-meta.xml` — version pin for a supplemental onboarding requirements flow.

---

## 5. Business Rules Engine (BRE) / expression sets

| Definition API name | processType | Purpose (from metadata) |
|-------------------|-------------|-------------------------|
| **OnboardingStatusNormalization** | Bre | Maps requirement type + status → normalized status via decision table **OnboardingStatusNormalization**. |
| **VendorProgramApprovalPolicyResolver** | Bre | Resolves **ApprovalRequired**, **BlockAction**, **Priority**, **Approval_Process_DevName** from **`Vendor_Program_Approval_Policy__mdt`**. |
| **CommunicationDispatchResolver** | Bre | Resolves communication dispatch; branches include **`IsOnboardingCreatedEvent`**. |

**Gap:** Decision table **XML** for the above names is **not present** in this repository; tables are referenced by expression sets and likely live in the org or another package. Deploy/review BRE in Setup alongside CMDT.

---

## 6. Lightning UI

**LWCs** (prefix `onboarding*`): `onboardingWorkQueue`, `onboardingOrderStatusViewer`, `onboardingDealerOnboardingModal`, `onboardingECC`, `onboardingRuleModal`, `onboardingRecentActivity`, `onboardingVendorProgramGrid`, `onboardingInsights`, `onboardingKpiRow`, `onboardingPathSelector`.

**Flexipage:** `Onboarding_Record_Page` references **`onboardingCompletionProgress`** — that bundle is **not** in `lwc/` in this repo (broken or split package).

**Permission set:** `Onboarding_Account_Services` grants Apex classes **`OnboardingOrderController`**, **`OnboardingProgressController`**, **`VendorFilterController`** — **source `.cls` files are not in this workspace** (“minimal” slice).

---

## 7. Custom permissions

Multiple **`Onboarding_Edit_*`**, **`Onboarding_Bypass_Flow`**, **`OnboardingAppAdmin`**, **`Onboarding_Allowed_to_Send_Special_Agreement`**, etc., under `customPermissions/` — gate edit surfaces and flow bypass.

---

## 8. Plan to review

Work through these items to confirm the repository matches business expectations and deployment reality. (This replaces a loose “validation checklist”; treat it as a living review backlog.)

| # | Topic | What to verify |
|---|--------|----------------|
| 1 | **Normalization parity** | ~173 `Onboarding_Status_Normalization__mdt` rows in repo vs BRE **OnboardingStatusNormalization** / decision table in the org—keep aligned if both paths are used. |
| 2 | **Evaluation rules** | Every active rule ships non-blank **`Predicate_Config__c`** JSON and documented **`op`** values; new **semantics** need one branch in **`OnboardingStatusPredicateInterpreter`**. |
| 3 | **Vendor eligibility CMDT** | No bundled `Vendor_Onboarding_Eligibility_Rule__mdt` rows here—defaults in `VendorOnboardingEligibilityRuleEngine` apply unless org has data. |
| 4 | **Prerequisites** | `Vendor_Program_Group_Member__c` AND/OR semantics match business rules. |
| 5 | **Minimal package / split repo** | Missing Apex (`OnboardingOrderController`, `OnboardingProgressController`, `VendorFilterController` per permission set), missing `onboardingCompletionProgress` LWC on flexipage, decision tables not in source—confirm companion packages or retrieve list. |
| 6 | **Unused CMDT types** | `Onboarding_Automation_Config__mdt`, `Onboarding_Next_Step_Rule__mdt` have no Apex/flow references in this tree—confirm intent (use vs retire). |
| 7 | **Stale generated docs** | `reports/*.md` and some `docs/` entries may still mention removed objects or classes—regenerate or edit when you next refresh inventory. |
| 8 | **Org cleanup** | If upgrading from an org that had `Onboarding_Status_Rule__c` / `Onboarding_Status_Rules_Engine__c`, confirm metadata deletion and data migration are handled in the deployment path (this repo no longer ships those types). |

---

## 9. File index (quick navigation)

- **Evaluator:** `classes/OnboardingStatusEvaluatorService.cls`, `classes/OnboardingStatusEvaluatorInvocable.cls`, `classes/OnboardingStatusNormalizationService.cls`, `classes/OnboardingStatusPredicateInterpreter.cls`, `classes/OnboardingStatusCmdtRuleEngine.cls`, `classes/IOnboardingStatusRuleEngine.cls`
- **ADR / predicate docs:** `docs/adr/ADR-001-onboarding-status-evaluation-engine.md`, `docs/onboarding-status-predicate-config.md`
- **Rule config access:** `permissionsets/Onboarding_Status_Rule_Config.permissionset-meta.xml`, `customPermissions/Onboarding_Status_Rule_Config.customPermission-meta.xml`
- **Vendor eligibility:** `classes/VendorOnboardingService.cls`, `classes/VendorPrerequisiteEvaluator.cls`, `classes/VendorOnboardingEligibilityRuleEngine.cls`
- **Flows:** `flows/BLL_Onboarding_*`, `flows/DOMAIN_OmniSObject_SFL_*Onboarding*`, `flows/DOMAIN_OmniSObject_SFL_EVAL_Onb_*`
- **CMDT records:** `customMetadata/Onboarding_Status_Normalization__mdt.*`, `customMetadata/Onboarding_Status_Evaluation_Rule__mdt.*`, etc.
- **BRE:** `expressionSetDefinition/*.expressionSetDefinition-meta.xml`
- **App:** `applications/Onboarding.app-meta.xml`

---

*End of specification. Update this document when metadata changes; treat it as the contract for “what the repo implements,” not legacy narrative.*
