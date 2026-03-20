# Best-Practices Review Checklist (2026-03-12)

Checkbox status list extracted from the source plan.

## High-Confidence Strengths Observed
- [x] `ObjectRelatedListController` uses `with sharing`, `WITH SECURITY_ENFORCED`, parameter validation, safe dynamic SOQL patterns, bind variables, and limits.
- [x] `objectRelatedList` LWC is LDS-first (`uiRecordApi`, `getObjectInfo`, `NavigationMixin`, refresh framework), supports batch `updateRecord`, defensive parsing, and strong UX behavior.
- [x] Triggers are minimal and delegate to helper/handler classes.
- [x] Automated testing footprint is broad (`*Test.cls`, Jest setup present).

## A. Apex (Architecture, Security, Limits, Testability)
- [ ] Enforce sharing model consistency and security annotations.
- [x] Confirm all exposed UI/Flow-invoked services/controllers use `with sharing`.
- [ ] Ensure SOQL parity with `WITH SECURITY_ENFORCED` where appropriate.
- [ ] Add `WITH USER_MODE` / user-mode DML (`Database.insert(records, AccessLevel.USER_MODE)`) for UI-context writes where appropriate.
- [x] Document and encapsulate explicit system-mode exceptions.
- [x] Adopt invocable Apex facades for Flow-bound operations where possible.
- [x] Add `@InvocableMethod` + typed `@InvocableVariable` DTO wrappers for selected operations.
- [ ] Standardize exception handling.
- [ ] Centralize domain exception base type and user-safe error messaging for UI calls.
- [x] Keep production code free of ad hoc `System.debug`.
- [ ] Verify bulkification and governor safety in helpers.
- [ ] Confirm no SOQL/DML in loops and collection-first signatures.
- [x] Add 200-record mixed-state tests and recursion safety assertions.
- [ ] Tighten logging strategy.
- [ ] Confirm `LoggingUtil` avoids PII, supports log levels, and feature toggles.
- [ ] Evaluate platform events or transaction finalizers for async failure telemetry.
- [ ] Normalize async patterns.
- [ ] Prefer Queueable over `@future`; use `System.Finalizer` for chained queueable cleanup/telemetry.
- [ ] Ensure Batchable queries are selective and `Database.Stateful` is used only when necessary.

## B. Triggers (Governance, Recursion, Tests)
- [x] One-trigger-per-object pattern appears in place (`Territory_Assignments__c`, `Vendor_Customization__c`).
- [x] Add/verify recursion guards and context-phase routing in handlers.
- [x] Use `Trigger.newMap` / `oldMap` diffs to minimize unnecessary work.
- [ ] Add comprehensive trigger tests:
- [x] Bulk insert/update over 200 records.
- [ ] Mixed DML-path behavior validation.
- [ ] Assertions for no governor limit overruns or uncommitted work issues.
- [ ] Negative tests for helper precondition failures and graceful handling.

## C. LWC (LDS-First, Accessibility, Testing, Performance)
- [ ] Evaluate `lightning/graphql` wire adapter for complex read-heavy data shapes.
- [ ] Keep Apex for business logic, writes, or unsupported query shapes.
- [ ] Candidate components for read-path modernization: `objectRelatedList`, `programDatesRelatedList*`.
- [ ] Accessibility and SLDS compliance hardening.
- [ ] Validate `aria-*` coverage, keyboard behavior, and custom datatable editor accessibility.
- [ ] Expand Jest coverage for high-traffic components:
- [x] `objectRelatedList`
- [x] `programDatesRelatedList*`
- [x] Add cases for inline edit save success/error toasts, navigation, query config derivation, CSV parsing, and picklist fallback/caching.
- [ ] Performance tuning:
- [ ] Debounce heavy refresh patterns.
- [ ] Verify picklist fetch batching by record type.
- [ ] Improve LDS cache orchestration for large related lists.

## D. Flows (Fault Handling, Modularity, Governance)
- [x] Naming/modularity taxonomy is strong (`DOMAIN_`, `BLL_`, `EXP_`; `SFL`/`SCR`/`RCD` conventions).
- [ ] Ensure every Screen, Subflow, and Apex action has a fault connector.
- [x] Document platform exceptions for fault connectors (before-save Fast Field Updates flows cannot attach fault connectors on `Update Records`; tracked for governance and excluded from deployable remediation scope).
- [x] Introduce/standardize a common fault-handler subflow to:
- [ ] Log context (`recordId`, user, flow version, element label, error).
- [ ] Show user-friendly messages.
- [ ] Emit platform event or write custom log record.
- [ ] Optionally notify ops channel (email/PEN).
- [ ] Extract large flows into idempotent subflows (retrieval, validation, rule evaluation, DML).
- [x] Define duplicate-reconciliation behavior for `Onboarding_Requirement_Subject__c.Unique_Key__c` conflicts instead of relying only on the database uniqueness constraint.
- [x] For high-volume record-triggered flows, tighten entry criteria:
- [x] Use "Only when updated to meet condition" where valid, and equivalent early decision-gating for `CreateAndUpdate` flows that must preserve create behavior.

## E. Data Model, FLS, and Metadata Hygiene
- [ ] Prefer object-level requiredness (field requiredness/validation rules) over repeated Flow-only checks.
- [ ] Standardize shared picklists with global value sets; remove duplicate local picklists where feasible.
- [ ] Prefer permission sets over profile-based net-new grants.
- [ ] Add drift checks or validation so `Vendor_Program_Requirement__c.Fulfillment_Policy_Key__c` values stay aligned with active `Onboarding_Fulfillment_Policy__mdt` records.
- [ ] Expand custom-permission gating for admin actions in LWCs and Flows.
- [ ] Externalize hard-coded user-facing strings to Custom Labels for i18n readiness.

## F. Deployment and CI/CD
- [x] `package.xml` variants and `destructiveChanges.xml` patterns already exist.
- [x] Ensure scripts use `sf` CLI consistently (avoid legacy `sfdx` command drift).
- [ ] Standardize deploy/retrieve/test script outputs for CI parsability (JUnit/JUnit JSON as needed).
- [ ] Implement org-shape-aware test runs (`sf apex run test --tests` from curated reports).
- [ ] Add CI gates for coverage thresholds and class-level failure summaries.

## G. Documentation Alignment and Drift Control
- [x] Documentation and report baseline is strong (`docs/`, `reports/`).
- [ ] Integrate doc-vs-metadata drift checks into CI and fail on significant drift.
- [x] Add a simple make/script target that runs existing audit automation under `scripts/automation/*`.

## Immediate Concrete Actions (Proposed Diffs)
- [ ] Add missing `with sharing` and SOQL security enforcement in key services/controllers (`VendorOnboarding*`, `EmailTemplateSync*`, `FollowUp*`, `Twilio*`).
- [x] Create reusable invocable facade class (`OnboardingInvocables.cls`) with typed request/response DTOs.
- [x] Add standard trigger-handler base/recursion guard where missing; add bulk safety tests.
- [ ] Introduce GraphQL read-path proof of concept for `objectRelatedList` behind a feature flag, keep Apex fallback.
- [x] Add a standard Flow Fault Handler subflow and wire at least one representative flow.
- [x] Build the remaining onboarding-requirement subject evaluator layer so real evidence sources update `Onboarding_Requirement_Subject__c.Status__c`; `Training_Assignment__c` is wired and now `Agreement` + `External_Contact_Credential__c` evidence are wired through `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_By_Evidence` (with `Out for Signature` mapped to `Paperwork Sent`).
- [ ] Expand Jest tests for `objectRelatedList` and `programDatesRelatedList*`; add Apex negative-path and bulk tests. (Jest portion complete on 2026-03-20; Apex follow-up remains.)

## Targeted Gap Review (2026-03-18)
- [x] `P0` `BLL_Onboarding_Requirement_RCD_Logical_Process` now has a fault connector on `Evaluate_Onboarding_Status`; invocable output `errorMessage` is mapped and escalated through shared fault handling (completed 2026-03-18).
- [x] `P0` `DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records` now emits deterministic failure output for the unsupported `OnboardingRecord` branch (`errorMessage` assignment), and parent orchestration now consumes related-record error outputs explicitly (completed 2026-03-18).
- [x] `P0` `EXP_Opportunity_SCR_Create_Record` now has fault connectors for `Get_Available_Vendors`, `Get_Default_Vendor_Program`, `Queue_Opportunity_Create_Chain`, and `Update_Account_Record`, and it now routes queue/output failures to explicit failure UX instead of false-success continuation (completed 2026-03-18).
- [x] `P0` `BLL_BRE_Evaluate_Business_Rules` now has fault routing on all four audited action calls and routes failures through `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` (completed 2026-03-18).
- [x] `P1` CMDT source hygiene drift for onboarding rule/config metadata (`Onboarding_Default_Vendor_Program*`, `Onboarding_Fulfillment_Policy*`, `Onboarding_Status_Normalization*`) is remediated in source: canonicalized to `Type__mdt.*` naming and duplicate aliases removed.
- [x] `P1` evaluator/code parity is aligned with current `Onboarding_Status_Evaluation_Rule__mdt` set: removed dead branches `HAS_REQUIREMENTS_NOT_ALL_SETUP_COMPLETE` and `OPPORTUNITY_UNCANCELED` from `OnboardingStatusEvaluatorService`.
- [x] `P1` test coverage for status/default-vendor invocables now includes deterministic rule and contract assertions (rule precedence branch coverage, null-input contract, missing-scenario, ambiguous match, and `Vendor_Program_Name_Contains__c`), validated in dry-run deploys `0AfRL00000dPzHx0AK` and `0AfRL00000dPyqZ0AS`.
- [x] Focal chain has zero no-fault entries in `make audit-fault-connectors` (`BLL_BRE_Evaluate_Business_Rules`, `BLL_Onboarding_Requirement_RCD_Logical_Process`, `EXP_Opportunity_SCR_Create_Record`).
- [x] `DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records` has explicit and test-validated error propagation for all runtime branches.
- [x] No duplicate onboarding CMDT aliases remain in source for the same record.
- [x] New/updated tests pass and assert both success and fault-path behavior for status evaluation and default-vendor resolution.
- [x] `P1` `objectRelatedList` inline picklist regression resolved: related-list inline `Status__c` now loads record-type-scoped options via `getPicklistValuesByRecordType` queueing, parity matches direct record edit, and user validation confirmed expected behavior/performance on 2026-03-18.
- [x] 2026-03-19 flow fault-connector remediation wave reduced raw audit gaps from `43` to `26` with valid metadata updates; 5 remaining gaps are known Fast Field Updates platform exceptions.
- [x] 2026-03-19 follow-up flow hardening wave completed for remaining `DOMAIN_OmniSObject_*` + `EXP_Contract_SCR_Send_Adobe_Agreement` gaps and validated in dry-run deploy `0AfRL00000dRAo10AG`; current fault-connector audit now reports only the 5 known before-save platform exceptions (`26` -> `5`).
- [x] 2026-03-19 deployment blocker in `BLL_Training_Assignment_SCD_Training_Reminder_Emails` resolved with bulk invocable send (`CommunicationTemplateBulkSendAction`) using list-based flow inputs and standard email logging semantics; validated with dry-run + tests (`0AfRL00000dRDkI0AW`, `4/4` passing) and deployed to `OnboardV2` (`0AfRL00000dRDdq0AG`).
- [x] 2026-03-19 `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements` no longer performs per-item `RecordType` gets in the vendor-program-requirement loop; it now preloads record types once and routes missing-mapping fail-fast through a single outside-loop gate before create DML (validated `0AfRL00000dRIjx0AG`, deployed `0AfRL00000dRIYg0AO`).
- [x] 2026-03-19 flow loop hygiene is now audited in automation (`make audit-flow-loop-shape`, `make audit-flow-loop-connectors`): scan reports `0` direct `nextValueConnector -> recordLookups/recordCreates/recordUpdates/recordDeletes/actionCalls` patterns.
- [x] 2026-03-19 `BLL_Onboarding_SFL_Dispatch_Communication_By_Context` loop dispatch-policy refactor completed: removed `Loop_Communication_Templates.nextValueConnector -> Get_Communication_Dispatch_Policy` and replaced with preloaded dispatch-policy cache (`Contact`, `PrincipalOwner`, `Agent`, `Input RecipientType`) plus in-loop assignment-based selection; post-refactor loop connector audit now reports zero `nextValue -> subflow` review candidates.
- [x] 2026-03-19 `BLL_Onboarding_SFL_Dispatch_Communication_By_Context` now uses bulk email action (`CommunicationTemplateBulkSendAction`) per template batch instead of per-recipient `DOMAIN_OmniSObject_ACTION_Send_Communication_Template` calls inside `Loop_Recipient_Ids`; shared bulk send Apex now enforces email-invocation guardrails (`Limits.getLimitEmailInvocations`) to avoid overrun, validated via dry-run (`0AfRL00000dRRiP0AW`), deployed to `OnboardV2` (`0AfRL00000dRSmX0AW`), and `CommunicationTemplateBulkSendActionTest` passed (`4/4`).
- [x] 2026-03-19 record-triggered entry hardening was applied where valid: `BLL_Order_RCD_Business_Logic` now uses `doesRequireRecordChangedToMeetCriteria=true` ("Only when updated to meet condition"), while `BLL_Agreement_RCD_Logical_Process` and `BLL_Onboarding_Requirement_Subject_RCD_Logical_Process` intentionally keep `IsChanged` start-filter semantics (Salesforce rejects combining that operator with `doesRequireRecordChangedToMeetCriteria=true`); validated by dry-run `0AfRL00000dRTCM0A4` and deployed `0AfRL00000dRN8Y0AW`.
- [x] 2026-03-19 `BLL_External_Contact_Credential_RCD_Logical_Process` entry criteria were tightened to align with "Only when updated to meet condition": start filter now includes `POE_Process_Status__c = Training Sent` alongside existing guards (`Training_Sent_Date__c is null`, `POE_Program__c = Verizon Fios D2D`) and uses `doesRequireRecordChangedToMeetCriteria=true`; validated by dry-run `0AfRL00000dRV7h0AG` and deployed `0AfRL00000dRV9J0AW`.
- [x] 2026-03-19 `BLL_Onboarding_Requirement_RCD_Logical_Process` hardened in place (no new flow split): start now gates on `Is_Create_Event` first, create path still performs the existing onboarding/opportunity/account/vendor-program retrieval chain before approval/related-record logic, and update path now bypasses create-only retrievals and evaluates normalization directly; onboarding status evaluation now sources `OnboardingId` from `$Record.Onboarding__c` so update normalization no longer depends on preloaded `OnboardingRecord`. Validated by dry-run `0AfRL00000dROpO0AW` and deployed `0AfRL00000dRVxJ0AW`.
- [x] 2026-03-19 `BLL_Onboarding_RCD_Logical_Process` hardened in place (no new flow split): start now evaluates `Determine_Execution_Path` before vendor-program retrieval, and only create/communication-update branches set `ExecutionPath` then call `Get_Vendor_Program`; post-retrieval routing is now explicit via `Route_After_Vendor_Program` (`Create -> Get_Vendor_Program_Requirements`, `CommunicationUpdate -> Determine_Send_Training`). This avoids vendor-program lookup work on no-op updates while preserving existing create + communication behavior. Validated by dry-run `0AfRL00000dRWN70AO` and deployed `0AfRL00000dRQ9h0AG`.
- [x] 2026-03-19 `BLL_OmniSObject_RCD_SYNC_Training_Assignments` hardened in place (no new flow split): start now routes to `Should_Process_Training_Assignment_Change`, which executes only for create or relevant update diffs (`Status__c`, `Contact__c`, `Onboarding__c`) before entering onboarding/evidence sync work. This skips heavy evaluation on irrelevant updates while preserving create + meaningful update behavior. Validated by dry-run `0AfRL00000dRWbd0AG` and deployed `0AfRL00000dRWgT0AW`.
- [x] 2026-03-19 `BLL_OmniSObject_RCD_SYNC_Training_Assignments` parent rollup loop was bulkified: replaced per-id loop/subflow calls to `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_Parent` with one Apex action call `Evaluate_Changed_Onboarding_Requirements_Bulk` (`OnbReqParentBulkEvalInvocable`), then hardened the invocable for record-type-restricted `Onboarding_Requirement__c.Status__c` values with ordered fallback status attempts and `Completed__c`-only fallback when status cannot be written. Validated/deployed with tests (`0AfRL00000dRZsr0AG`, `5/5` passing).
- [ ] Deferred (user-prioritized): hardening for `DOMAIN_OmniSObject_SFL_Send_Email_Communication` is intentionally paused for now and queued for a later pass.
- [x] 2026-03-19 P0 single-owner onboarding status pattern finalized in source and deployed to `OnboardV2`: `OnboardingStatusEvaluatorInvocable` now bulk-processes all request rows and supports collection id input, `BLL_Order_RCD_Business_Logic` no longer directly writes `Onboarding__c.Onboarding_Status__c` and now routes through evaluator action, and parent rollup callers (`BLL_Onboarding_Requirement_Subject_RCD_Logical_Process`, `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_For_Onb_Rec`) now use `OnbReqParentBulkEvalInvocable` bulk path instead of per-id `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_Parent` subflow calls. Validated by dry-run `0AfRL00000dRf8f0AC` and deployed `0AfRL00000dRee20AC` (`OnboardingStatusEvaluatorTest` `10/10`).
- [x] 2026-03-19 Business/admin documentation for CMDT-driven status governance was added: `docs/user-guides/onboarding-status-business-rules-guide.md`, `docs/implementation-notes/onboarding-status-single-owner-flow-plan-2026-03-19.md`, and refreshed `docs/processes/status-evaluation.md`.
- [x] 2026-03-19 Added owner-write guardrail automation for onboarding status: new `make audit-onboarding-status-owner` target scans flows + non-test Apex for direct `Onboarding__c.Onboarding_Status__c` writes outside `OnboardingStatusEvaluatorService`, and current run reports `0` violations (`.analysis/automation-audit/onboarding_status_owner_audit.tsv`).
- [x] 2026-03-19 Hardened `BLL_Agreement_RCD_Logical_Process` using supported subflow error-contract routing (no flow split): `Get_Onboarding_Record` and `Evaluate_Agreement_Subjects` now map `errorMessage` outputs and route through explicit failure decisions to `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` handlers. Validated by dry-run `0AfRL00000dRZWI0A4` and deployed `0AfRL00000dRhK90AK`.
- [x] 2026-03-19 Confirmed platform constraint for record-triggered flow subflow metadata: `FlowSubflow` does not accept `faultConnector` (`0AfRL00000dRgnt0AC` parse failure), so hardening pattern is output-contract + decision-based fault routing instead of direct subflow fault connectors.
- [x] 2026-03-19 Added `make audit-subflow-error-contracts` governance check to enforce supported subflow failure contracts (child flow exposes `errorMessage` output -> parent must map it); current baseline reports `0` missing mappings (`.analysis/automation-audit/subflow_error_contract_audit.tsv`).
- [x] 2026-03-19 User-visible fault messaging + richer fault logging hardened on active screen flow path: `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` now logs `SourceElementLabel` and `InterviewGuid` context and returns `UserFacingMessage` with a short reference code; `EXP_Opportunity_SCR_Create_Record` now maps `UserFacingMessage` (instead of `ResolvedFaultMessage`) for all six handled fault branches and supplies `SourceElementLabel`, `InterviewGuid`, and per-branch `UserFacingMessageOverride`. Validated by dry-run `0AfRL00000dRbl00AC` and deployed `0AfRL00000dRiGD0A0`.
- [x] 2026-03-19 `EXP_Opportunity_SCR_Create_Record` error formula hardening follow-up: `ResolvedFlowErrorMessage` now prioritizes handler-returned `errorMessage` (user-safe) before `QueueChainMessage`, preventing raw queue output from leaking to end users on handled faults. Validated by dry-run `0AfRL00000dRPaB0AW` and deployed `0AfRL00000dRiPt0AK`.
- [x] 2026-03-19 Extended the same user-safe fault + logging pattern to `EXP_Contract_SCR_Send_Adobe_Agreement`: `Adobe_Agreement_Created` no-result branch now logs via `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message`, `Capture_Update_Contract_Fault` now logs via dedicated handler (no direct screen bypass), all three handlers pass `SourceElementLabel` + `$Flow.InterviewGuid`, map `UserFacingMessage` back to `errorMessage`, and error screens now render `{!errorMessage}` (reference-bearing user-safe text). Validated by dry-run `0AfRL00000dRijF0AS` and deployed `0AfRL00000dRio50AC`.
- [x] 2026-03-19 Added screen-flow UX fault-contract governance (`make audit-screen-flow-fault-user-messaging`): for Screen Flows that call `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message`, automation now enforces `UserFacingMessage` output mapping plus `InterviewGuid` and `SourceElementLabel` inputs; current baseline reports `0` violations.
- [x] 2026-03-19 Step 1 fault-context standardization completed across active non-deferred handlers: added `SourceElementLabel` + `$Flow.InterviewGuid` on all `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` calls in 12 flows (`BLL_*` + `DOMAIN_OmniSObject_*` scope). Validation/deploy succeeded (`dry-run 0AfRL00000dRov70AC`, `deploy 0AfRL00000dRozx0AC`) and governance checks remained clean (`make audit-subflow-error-contracts` = `0`, `make audit-screen-flow-fault-user-messaging` = `0`). `DOMAIN_OmniSObject_SFL_Send_Email_Communication` remains intentionally deferred.
- [x] 2026-03-19 Step 2 hardening guardrail added: new global audit target `make audit-fault-message-context-contract` (`scripts/automation/audit-fault-message-context-contract.sh`) now enforces `SourceElementApiName`, `SourceElementLabel`, `SourceFlowApiName`, and `InterviewGuid` on every `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` subflow call across flow types (excluding user-deferred `DOMAIN_OmniSObject_SFL_Send_Email_Communication`).
- [x] 2026-03-19 Step 3 screen-flow UX contract tightened: `audit-screen-flow-fault-user-messaging` now also enforces `SourceElementApiName` + `SourceFlowApiName` inputs and rejects `ResolvedFaultMessage` output mappings on screen-flow fault handlers to prevent raw admin fault leakage.
- [x] 2026-03-19 Step 4 validation complete: both new/updated audits passed at baseline (`make audit-fault-message-context-contract` = `0` violations, `make audit-screen-flow-fault-user-messaging` = `0` violations).
- [x] 2026-03-19 Deployable hardening on Record Collection Editor write/read path completed: `RecordCollectionEditorConfigService` now executes child + relationship DML in `AccessLevel.USER_MODE`, enforces relationship-field create/update FLS gates before DML, filters inaccessible fields from returned editor config metadata, and uses `WITH SECURITY_ENFORCED` for relationship existence lookup; `RecordCollectionEditorGetRecordsService` now safely reads optionally-unqueried fields (no runtime blow-up on sparse SOQL rows), filters inaccessible configured field names before extraction/query, applies `WITH SECURITY_ENFORCED` on fallback relationship query, and returns user-safe reference-bearing error messages with detailed internal logging. Validated by dry-run deploys `0AfRL00000dRpeH0AS`, `0AfRL00000dRpfu0AC`, `0AfRL00000dSGZd0AO`, `0AfRL00000dSGxp0AG`; deployed via `0AfRL00000dRlAs0AK`, `0AfRL00000dRqC90AK`, `0AfRL00000dSGcr0AG`, `0AfRL00000dSH2f0AG`; verification tests passed (`RecordCollectionEditorConfigServiceTest`, runs `707RL00001Ih0Ym`, `707RL00001IjQqI`, and `707RL00001IjW2a`, all `4/4`).
- [x] 2026-03-19 Deployable SOQL security parity hardening applied to async opportunity-create path: `ExperienceOpportunityCreateAsyncService` vendor-program resolution queries now include `WITH SECURITY_ENFORCED` (both selected-vendor match and PerfectVision fallback lookup branches). Validated by dry-run deploy `0AfRL00000dRqGz0AK`, deployed `0AfRL00000dRpj80AC`, and verified by `ExpOppCreateAsyncServiceTest` run `707RL00001Ih0f8` (`3/3` passing).
- [x] 2026-03-20 `ObjectRelatedListController` defensive hardening deployed without regressing inline-edit behavior: dynamic SOQL input fields/order paths are now describe-validated (`requireSimpleField` / `requireFieldPath`), object names are sourced from describe metadata, and label/sort fields in lookup option queries are validated before query assembly. Added targeted regression/safety test class `ObjectRelatedListCtrlTest` and validated with dry-run `0AfRL00000dSJio0AG`; deployed to `OnboardV2` via `0AfRL00000dSSNt0AO` with `5/5` specified tests passing.
- [x] 2026-03-20 Follow-up fix for App Builder regression: parent relationship filter paths are explicitly supported again in `ObjectRelatedListController` (`parentFieldApiName` now validates via relationship-path parser), restoring configs like `Parent.Onboarding__c` for `Onboarding_Requirement_History`. Regression test coverage added (`testGetRelatedRecordsWithParentRelationshipPath` in `ObjectRelatedListCtrlTest`) and validated/deployed (`dry-run 0AfRL00000dSSe10AG`, deploy `0AfRL00000dSP0F0AW`, `6/6` passing).
- [x] 2026-03-20 Follow-up compatibility completion: dotted paths are now supported in all query-field inputs for `ObjectRelatedListController` (`parentFieldApiName`, `fieldApiNames`, `relationshipFieldApiNames`, `orderByField`) so App Builder configs can use relationship paths consistently across objects (example `CreatedBy.Name`, `Parent.Requirement_Type__c`, `Parent.Onboarding__c`). Added regression `testGetRelatedRecordsWithRelationshipPathInFieldApiNames`; validated/deployed (`dry-run 0AfRL00000dSSXb0AO`, deploy `0AfRL00000dSO7T0AW`, `7/7` passing).
- [x] 2026-03-20 Added LWC Jest regression coverage for `objectRelatedList` dotted-path behavior: new test suite `force-app/test/lwc/objectRelatedList.test.js` verifies dotted-path wire config assembly (`parentFieldApiName`, `fieldApiNamesCsv`, `relationshipFieldApiNamesCsv`, `orderByField`), dotted parent-id source field handling (`parentRecordIdSourceFieldApiName`), and dotted exclusion/transform behavior in rendered rows. Test run passed via `npx sfdx-lwc-jest -- --runTestsByPath force-app/test/lwc/objectRelatedList.test.js` (`3/3`).
- [x] 2026-03-20 Added targeted `objectRelatedList` picklist-by-recordType Jest regressions covering the incident paths: recordType success option hydration, wire-error fallback to object-info picklist metadata, and multi-recordType queue release/advance behavior. Updated suite now passes `6/6` via `npx sfdx-lwc-jest -- --runTestsByPath force-app/test/lwc/objectRelatedList.test.js` (and full `npx sfdx-lwc-jest` run).
- [x] 2026-03-20 Jest deployability fix applied: moved `objectRelatedList` Jest tests out of the LWC bundle path into `force-app/test/lwc` so Salesforce metadata deploy no longer attempts to compile test harness files; post-fix dry-run deploy `0AfRL00000dSNxi0AG` and deploy `0AfRL00000dSWbB0AW` both succeeded.
- [x] 2026-03-20 Added Jest regression suites for `programDatesRelatedList` and `programDatesQuickAction` in `force-app/test/lwc` with DOM-driven coverage for wire data/error rendering, inline save success/error toasts, row delete actions, quick-action submit defaults (account/vendor), and success/error close/toast behavior; targeted run passed `11/11` and full LWC Jest baseline now passes `17/17`.
