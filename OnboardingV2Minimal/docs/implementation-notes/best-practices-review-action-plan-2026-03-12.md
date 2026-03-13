# Best-Practices Review Action Plan (2026-03-12)

## Goal
Capture the initial best-practices review recommendations as a prioritized, actionable checklist that can be executed incrementally.

## High-Confidence Strengths Observed
- [x] `ObjectRelatedListController` uses `with sharing`, `WITH SECURITY_ENFORCED`, parameter validation, safe dynamic SOQL patterns, bind variables, and limits.
- [x] `objectRelatedList` LWC is LDS-first (`uiRecordApi`, `getObjectInfo`, `NavigationMixin`, refresh framework), supports batch `updateRecord`, defensive parsing, and strong UX behavior.
- [x] Triggers are minimal and delegate to helper/handler classes.
- [x] Automated testing footprint is broad (`*Test.cls`, Jest setup present).

## Priority Roadmap
- `P0` Security and correctness guardrails: sharing/FLS enforcement, fault handling, trigger bulk safety.
- `P1` Operability and maintainability: invocable facades, exception/logging standards, async/finalizer consistency.
- `P2` Performance and modernization: GraphQL read paths, expanded LWC test coverage, CI drift gates.

## Execution Log
- 2026-03-12: Started `P0` step 1 (Apex sharing/FLS enforcement audit + fixes).
- 2026-03-12: Updated `VendorOnboardingService`, `VendorPrerequisiteEvaluator`, `TwilioSettingsController`, `FollowUpMessagingService`, and `TwilioSMSProvider` for stronger sharing/query security posture.
- 2026-03-12: Targeted dry-run deploy compile validation succeeded for the above class changes.
- 2026-03-12: Extended security hardening to `FollowUpDetectionService`, `FollowUpExecutionService`, `FollowUpFatigueService`, `FollowUpRuleRepository`, `SalesforceMessagingProvider`, and `VendorOnboardingEligibilityRuleEngine`.
- 2026-03-12: Additional targeted dry-run deploy compile validation succeeded for all newly updated classes.
- 2026-03-12: Focused org test run (`707RL00001HofRVYAZ`) completed with 2 failures in existing org code (`VendorOnboardingJsonAdapterTest.testGetVendorsAsJson`, `VendorOnboardingLWCAdapterTest.testGetVendorOptionsReturnsExpectedData`); local changes were dry-run only and not deployed during this pass.
- 2026-03-12: Optimized `EmailCommTerritoryRoleHelper` with recursion-safe processing, precomputed user lookup field detection, and guarded DML execution.
- 2026-03-12: Trigger/helper dry-run compile validation succeeded for `TerritoryAssignmentsTrigger` + `EmailCommTerritoryRoleHelper`.
- 2026-03-12: `VersioningTriggerHandler` was intentionally removed from this repo and the org; that retired path is out of scope for current remediation.
- 2026-03-12: Added `EmailCommTerritoryRoleHelperTest` coverage for trigger-created role assignments and operation-aware idempotency behavior.
- 2026-03-12: Territory helper + trigger + new test dry-run compile validation succeeded.
- 2026-03-12: Hardened `TerritoryAssignmentsTrigger` + `EmailCommTerritoryRoleHelper` to diff user-lookup fields on update, skip unnecessary resync work, and delete stale role assignments when lookups are cleared.
- 2026-03-12: Expanded `EmailCommTerritoryRoleHelperTest` with clear-to-null regression coverage and a 210-record mixed-state update scenario.
- 2026-03-12: Targeted dry-run validation with `RunSpecifiedTests` succeeded for territory trigger/helper/test updates (`0AfRL00000dJTiz0AG`).
- 2026-03-12: Replaced ad hoc `System.debug` usage in `EmailTemplateSyncService`, `EmailTemplateSyncOrchestrator`, and `EmailTemplateSyncJob` with standardized `LoggingUtil` calls.
- 2026-03-12: EmailTemplateSync logging cleanup dry-run compile validation succeeded.
- 2026-03-12: Added typed Flow facades (`OnboardingInvocables`, `OnboardingFollowUpInvocables`) with request/response DTOs for vendor eligibility JSON retrieval and follow-up evaluation operations.
- 2026-03-12: Added `OnboardingInvocablesTest` coverage for valid/invalid request handling across both new invocable actions.
- 2026-03-12: Replaced remaining ad hoc follow-up/twilio `System.debug` usage in `FollowUpDetectionService`, `FollowUpExecutionService`, `FollowUpMessagingService`, `FollowUpFatigueService`, and `TwilioSMSProvider` with `LoggingUtil`.
- 2026-03-12: Adjusted invocable implementation after compile validation: Apex supports one `@InvocableMethod` per class, so follow-up evaluation moved into `OnboardingFollowUpInvocables`.
- 2026-03-12: Targeted dry-run compile validation succeeded for invocable/logging updates (`0AfRL00000dJHYB0A4`).
- 2026-03-12: Targeted dry-run validation with `RunSpecifiedTests` succeeded for `OnboardingInvocablesTest` (`0AfRL00000dJAQH0A4`), including class-level coverage on both new invocable classes.
- 2026-03-12: Began `P0` step 2 (flow fault-handler wiring) with representative implementation on `DOMAIN_OmniSObject_ACTION_Send_Communication_Template`.
- 2026-03-12: Added fault-path routing from `Send_Email_Action` to queue-based fault logging (`DOMAIN_OmniSObject_SFL_CREATE_Follow_Up_Queue`) with guarded onboarding checks and standardized trigger-reason/message formulas.
- 2026-03-12: Flow metadata constraint observed: `faultConnector` is invalid on `FlowSubflow` elements; representative fault wiring must target elements that support fault connectors (e.g., `actionCalls`).
- 2026-03-12: Targeted dry-run compile validation succeeded for `DOMAIN_OmniSObject_ACTION_Send_Communication_Template` (`0AfRL00000dJNH00AO`).
- 2026-03-12: Added reusable fault-message subflow `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` to standardize communication-fault message normalization, trigger-reason generation, and conditional follow-up queue creation.
- 2026-03-12: Updated `DOMAIN_OmniSObject_ACTION_Send_Communication_Template` and `BLL_Onboarding_SFL_Dispatch_Communication_By_Context` to call `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` instead of duplicating queue-routing logic.
- 2026-03-13: Targeted dry-run validation succeeded for the flow standardization work plus trigger/helper updates (`0AfRL00000dJUOv0AO`).
- 2026-03-13: Deployed trigger/helper hardening plus standardized fault-message flow updates to `OnboardV2` (`0AfRL00000dJUbp0AG`); deploy success was confirmed via `sf project deploy report` after a CLI reporting bug on the initial deploy command output.
- 2026-03-13: Extended `DOMAIN_OmniSObject_SFL_CREATE_Follow_Up_Queue` and `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` so shared communication-fault handling can override initial queue status and create terminal fault records even when no onboarding context is available.
- 2026-03-13: Updated `BLL_Training_Assignment_SCD_Training_Reminder_Emails` to route `EmailCommBatchSendAction` faults through the shared fault handler, skip empty batch sends, and reset email payload state between loop iterations to prevent cross-record carryover.
- 2026-03-13: Targeted dry-run validation succeeded for the queue/fault/training-reminder flow bundle (`0AfRL00000dJVpd0AG`).
- 2026-03-13: Deployed updated queue/fault/training-reminder flows to `OnboardV2` (`0AfRL00000dJU3z0AG`).
- 2026-03-13: Hardened legacy `DOMAIN_OmniSObject_SFL_Send_Email_Communication` with shared fault routing so email-send failures no longer fall through to `Training_Sent_Date__c` updates.
- 2026-03-13: Updated legacy orchestrator `BLL_External_Contact_Credential_RCD_Execute_Supplemental_Onboarding_Requirements` in place to pass onboarding context into the email subflow and remove stale `DOMAIN_OmniSObject_SFL_GET_Vendor_Program` step mappings that no longer match the current subflow contract; this became the final in-place hardening pass before the later `BLL_External_Contact_Credential_RCD_Logical_Process` replacement.
- 2026-03-13: Replaced the legacy external-credential orchestrator in source with standard record-triggered autolaunched flow `BLL_External_Contact_Credential_RCD_Logical_Process`, preserving the ECC update, signer-gated onboarding lookup, SSO-email dispatch, and process-status completion behavior without orchestrator stages.
- 2026-03-13: Targeted dry-run validation succeeded for the legacy external-credential flow bundle (`0AfRL00000dJZzi0AG`).
- 2026-03-13: Deployed legacy external-credential flow hardening to `OnboardV2` (`0AfRL00000dJd410AC`).
- 2026-03-13: Targeted dry-run validation succeeded for the new `BLL_External_Contact_Credential_RCD_Logical_Process` flow (`0AfRL00000dJdYf0AK`).
- 2026-03-13: Deployed `BLL_External_Contact_Credential_RCD_Logical_Process` to `OnboardV2` (`0AfRL00000dJdbt0AC`); the CLI surfaced a non-blocking reporting bug, so deploy success was confirmed via `sf project deploy report`.
- 2026-03-13: Targeted dry-run validation succeeded for the legacy-flow deactivation metadata (`0AfRL00000dJYxC0AW`).
- 2026-03-13: Deployed `BLL_External_Contact_Credential_RCD_Execute_Supplemental_Onboarding_Requirements.flowDefinition` with `activeVersionNumber=0` to inactivate the retired legacy flow in `OnboardV2` (`0AfRL00000dJZrf0AG`).
- 2026-03-13: Salesforce still reports a non-blocking info warning on `DOMAIN_OmniSObject_SFL_Send_Email_Communication` about the hard-coded email template id, so that legacy configuration remains a follow-up cleanup item.
- 2026-03-13: Hardened `RecordCollectionEditorConfigService` and `RecordCollectionEditorGetRecordsService` so metadata-driven field configs and relationship queries now filter inaccessible fields, enforce `WITH SECURITY_ENFORCED` on dynamic relationship lookups, and use user-mode DML for record-editor writes.
- 2026-03-13: Updated `RecordCollectionEditorAsyncService` to use `LoggingUtil` instead of ad hoc async debug logging, and tightened `ExperienceOpportunityCreateAsyncService` vendor-program fallback queries with `WITH SECURITY_ENFORCED`.
- 2026-03-13: Added `RecordCollectionEditorConfigServiceTest` coverage for config parsing, record/relationship creation, and relationship JSON serialization.
- 2026-03-13: Targeted dry-run validation succeeded for the record-editor async security batch (`0AfRL00000dKFu60AG`) with specified tests passing `10/10`.
- 2026-03-13: Deployed the record-editor async security batch to `OnboardV2` (`0AfRL00000dKGBp0AO`) with specified tests passing `10/10`.
- 2026-03-13: Hardened `Onboarding_Program_Sales_Team` and `Onboarding_Account_Services` permissions for the Record Collection Editor path by granting the active editor Apex classes plus `Contact` create/edit/read and the currently supported `Contact` / `AccountContactRelation` field permissions required by the tightened user-mode/FLS enforcement.
- 2026-03-13: Normalized the repo copies of those permission sets against `OnboardV2` by removing stale legacy object, field, tab, and Apex-class grants that no longer exist in the target org (for example `Background_Check__c`, dead `Onboarding__c` lookup fields, and retired `VendorOnboarding*` service classes).
- 2026-03-13: Targeted dry-run validation succeeded for the normalized permission-set bundle (`0AfRL00000dKKqX0AW`); the initial CLI response surfaced a temp-path packaging bug, so success was confirmed via `sf project deploy report`.
- 2026-03-13: Deployed the normalized permission-set bundle to `OnboardV2` (`0AfRL00000dKCEg0AO`); deploy success was again confirmed via `sf project deploy report` because the initial CLI output surfaced the same non-blocking temp-path bug.
- 2026-03-13: Replaced the remaining ad hoc `System.debug` usage in production classes `PicklistHelper` and `SalesforceMessagingProvider` with standardized `LoggingUtil` calls, preserving the existing fallback behavior while removing direct debug statements from the runtime path.
- 2026-03-13: Targeted dry-run validation succeeded for the logging cleanup batch (`0AfRL00000dKLcv0AG`) using a metadata-format deploy package to avoid the repo-local `UnsafeFilepathError` CLI bug on source-format deploys.
- 2026-03-13: Deployed the logging cleanup batch to `OnboardV2` (`0AfRL00000dKEZs0AO`).
- 2026-03-13: Added fault connectors to the reusable Record Collection Editor create subflows `DOMAIN_OmniSObject_SFL_Create_Contact` and `DOMAIN_OmniSObject_SFL_CREATE_Opportunity_Contact_Role` so unexpected Apex faults are now captured into the flows' existing output error variables instead of hard-failing the interview.
- 2026-03-13: Targeted dry-run validation succeeded for the Record Collection Editor flow-fault batch (`0AfRL00000dKM170AG`) using a metadata-format deploy package to avoid the repo-local `UnsafeFilepathError` CLI bug on source-format deploys.
- 2026-03-13: Deployed the Record Collection Editor flow-fault batch to `OnboardV2` (`0AfRL00000dKMCP0A4`).
- 2026-03-13: Added fault connectors to the experience-layer Record Collection Editor screen flows `EXP_Contact_SCR_Create_Contact` and `EXP_Opportunity_Contacts_SCR_CREATE_Opportunity_Contacts` so get-records and async-queue action faults now populate `errorMessage` instead of failing the screen flow outright; the opportunity-contact formatter now also maps the underlying `errorMessage` output from `RecordCollectionEditorGetRecordsService`.
- 2026-03-13: Targeted dry-run validation succeeded for the Record Collection Editor screen-flow fault batch (`0AfRL00000dKQzB0AW`) using a metadata-format deploy package to avoid the repo-local `UnsafeFilepathError` CLI bug on source-format deploys.
- 2026-03-13: Deployed the Record Collection Editor screen-flow fault batch to `OnboardV2` (`0AfRL00000dKQxa0AG`); the initial CLI response surfaced a non-blocking finalization/reporting bug, so deploy success was confirmed via `sf project deploy report`.
- 2026-03-13: Salesforce surfaced a non-blocking info warning that `EXP_Opportunity_Contacts_SCR_CREATE_Opportunity_Contacts` references `EXP_Contact_SCR_Create_Contact` as a subflow without an active version in the org; this did not block deployment but remains metadata hygiene follow-up debt.

## A. Apex (Architecture, Security, Limits, Testability)
- [ ] Enforce sharing model consistency and security annotations.
- [ ] Confirm all exposed UI/Flow-invoked services/controllers use `with sharing`.
- [ ] Ensure SOQL parity with `WITH SECURITY_ENFORCED` where appropriate.
- In progress: `RecordCollectionEditorGetRecordsService` and `ExperienceOpportunityCreateAsyncService` now enforce `WITH SECURITY_ENFORCED` on remaining dynamic/lookup query paths touched in the current P0 pass.
- [ ] Add `WITH USER_MODE` / user-mode DML (`Database.insert(records, AccessLevel.USER_MODE)`) for UI-context writes where appropriate.
- In progress: `RecordCollectionEditorConfigService` now performs metadata-driven record-editor inserts and updates in `AccessLevel.USER_MODE`, including relationship-record DML.
- [ ] Document and encapsulate explicit system-mode exceptions.
- [ ] Adopt invocable Apex facades for Flow-bound operations where possible.
- [ ] Add `@InvocableMethod` + typed `@InvocableVariable` DTO wrappers for selected operations.
- [ ] Standardize exception handling.
- [ ] Centralize domain exception base type and user-safe error messaging for UI calls.
- [ ] Keep production code free of ad hoc `System.debug`.
- In progress: `RecordCollectionEditorAsyncService`, `PicklistHelper`, and `SalesforceMessagingProvider` now route runtime diagnostics through `LoggingUtil`; remaining raw `System.debug` usage is intentionally centralized inside `LoggingUtil` itself.
- [ ] Verify bulkification and governor safety in helpers.
- [ ] Confirm no SOQL/DML in loops and collection-first signatures.
- [ ] Add 200-record mixed-state tests and recursion safety assertions.
- [ ] Tighten logging strategy.
- [ ] Confirm `LoggingUtil` avoids PII, supports log levels, and feature toggles.
- [ ] Evaluate platform events or transaction finalizers for async failure telemetry.
- [ ] Normalize async patterns.
- [ ] Prefer Queueable over `@future`; use `System.Finalizer` for chained queueable cleanup/telemetry.
- [ ] Ensure Batchable queries are selective and `Database.Stateful` is used only when necessary.

## B. Triggers (Governance, Recursion, Tests)
- [x] One-trigger-per-object pattern appears in place (`Territory_Assignments__c`, `Vendor_Customization__c`).
- [ ] Add/verify recursion guards and context-phase routing in handlers.
In progress: `TerritoryAssignmentsTrigger` now routes `after update` work through `oldMap`-aware helper logic; the retired `VersioningTriggerHandler` path is intentionally out of scope.
- [ ] Use `Trigger.newMap` / `oldMap` diffs to minimize unnecessary work.
In progress: `TerritoryAssignmentsTrigger` now skips unchanged user-lookup updates and only refreshes role assignments when relevant lookups change.
- [ ] Add comprehensive trigger tests:
- [ ] Bulk insert/update over 200 records.
- [ ] Mixed DML-path behavior validation.
- [ ] Assertions for no governor limit overruns or uncommitted work issues.
- [ ] Negative tests for helper precondition failures and graceful handling.
In progress: `EmailCommTerritoryRoleHelperTest` now covers clear-to-null cleanup, operation idempotency, and a 210-record mixed-state update path.

## C. LWC (LDS-First, Accessibility, Testing, Performance)
- [ ] Evaluate `lightning/graphql` wire adapter for complex read-heavy data shapes.
- [ ] Keep Apex for business logic, writes, or unsupported query shapes.
- [ ] Candidate components for read-path modernization: `objectRelatedList`, `programDatesRelatedList*`.
- [ ] Accessibility and SLDS compliance hardening.
- [ ] Validate `aria-*` coverage, keyboard behavior, and custom datatable editor accessibility.
- [ ] Expand Jest coverage for high-traffic components:
- [ ] `objectRelatedList`
- [ ] `programDatesRelatedList*`
- [ ] Add cases for inline edit save success/error toasts, navigation, query config derivation, CSV parsing, and picklist fallback/caching.
- [ ] Performance tuning:
- [ ] Debounce heavy refresh patterns.
- [ ] Verify picklist fetch batching by record type.
- [ ] Improve LDS cache orchestration for large related lists.

## D. Flows (Fault Handling, Modularity, Governance)
- [x] Naming/modularity taxonomy is strong (`DOMAIN_`, `BLL_`, `EXP_`; `SFL`/`SCR`/`RCD` conventions).
- [ ] Ensure every Screen, Subflow, and Apex action has a fault connector.
- In progress: `DOMAIN_OmniSObject_ACTION_Send_Communication_Template`, `BLL_Training_Assignment_SCD_Training_Reminder_Emails`, and the legacy `DOMAIN_OmniSObject_SFL_Send_Email_Communication` path now route supported action faults into the shared handler; `DOMAIN_OmniSObject_SFL_Create_Contact`, `DOMAIN_OmniSObject_SFL_CREATE_Opportunity_Contact_Role`, `EXP_Contact_SCR_Create_Contact`, and `EXP_Opportunity_Contacts_SCR_CREATE_Opportunity_Contacts` now capture Record Collection Editor fault paths into output error variables; broader flow audit remains.
- [ ] Introduce/standardize a common fault-handler subflow to:
In progress: `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` now centralizes fault-message normalization, trigger-reason generation, explicit queue-status overrides, and queue-routing for communication flows across `DOMAIN_OmniSObject_ACTION_Send_Communication_Template`, `BLL_Onboarding_SFL_Dispatch_Communication_By_Context`, `BLL_Training_Assignment_SCD_Training_Reminder_Emails`, and the legacy `DOMAIN_OmniSObject_SFL_Send_Email_Communication` path.
- [ ] Log context (`recordId`, user, flow version, element label, error).
- [ ] Show user-friendly messages.
- [ ] Emit platform event or write custom log record.
- [ ] Optionally notify ops channel (email/PEN).
- [ ] Extract large flows into idempotent subflows (retrieval, validation, rule evaluation, DML).
- In progress: `BLL_Training_Assignment_SCD_Training_Reminder_Emails` now guards empty batch sends and resets payload state after each send/fault path to avoid duplicate carryover between training-assignment iterations.
- Completed: legacy `BLL_External_Contact_Credential_RCD_Execute_Supplemental_Onboarding_Requirements` has now been replaced in source by `BLL_External_Contact_Credential_RCD_Logical_Process`; the hard-coded email configuration in `DOMAIN_OmniSObject_SFL_Send_Email_Communication` remains follow-up debt.
- [ ] For high-volume record-triggered flows, tighten entry criteria:
- [ ] Use "Only when updated to meet condition".
- [ ] Minimize repeated `Get Records`; prefer collection-based filtering patterns.

## E. Data Model, FLS, and Metadata Hygiene
- [ ] Prefer object-level requiredness (field requiredness/validation rules) over repeated Flow-only checks.
- [ ] Standardize shared picklists with global value sets; remove duplicate local picklists where feasible.
- [ ] Prefer permission sets over profile-based net-new grants.
- In progress: `Onboarding_Program_Sales_Team` and `Onboarding_Account_Services` now carry the Record Collection Editor access through permission sets, and the source copies were normalized against the current `OnboardV2` metadata shape on 2026-03-13.
- [ ] Expand custom-permission gating for admin actions in LWCs and Flows.
- [ ] Externalize hard-coded user-facing strings to Custom Labels for i18n readiness.

## F. Deployment and CI/CD
- [x] `package.xml` variants and `destructiveChanges.xml` patterns already exist.
- [ ] Ensure scripts use `sf` CLI consistently (avoid legacy `sfdx` command drift).
- [ ] Standardize deploy/retrieve/test script outputs for CI parsability (JUnit/JUnit JSON as needed).
- [ ] Implement org-shape-aware test runs (`sf apex run test --tests` from curated reports).
- [ ] Add CI gates for coverage thresholds and class-level failure summaries.

## G. Documentation Alignment and Drift Control
- [x] Documentation and report baseline is strong (`docs/`, `reports/`).
- [ ] Integrate doc-vs-metadata drift checks into CI and fail on significant drift.
- [ ] Add a simple make/script target that runs existing audit automation under `scripts/automation/*`.

## Immediate Concrete Actions (Proposed Diffs)
- [ ] Add missing `with sharing` and SOQL security enforcement in key services/controllers (`VendorOnboarding*`, `EmailTemplateSync*`, `FollowUp*`, `Twilio*`).
In progress: `VendorOnboardingService`, `VendorOnboardingEligibilityRuleEngine`, `VendorPrerequisiteEvaluator`, `TwilioSettingsController`, `TwilioSMSProvider`, `FollowUpDetectionService`, `FollowUpExecutionService`, `FollowUpFatigueService`, `FollowUpMessagingService`, `FollowUpRuleRepository`, `SalesforceMessagingProvider`, `RecordCollectionEditorConfigService`, `RecordCollectionEditorGetRecordsService`, `RecordCollectionEditorAsyncService`, `ExperienceOpportunityCreateAsyncService`, and `PicklistHelper` updated through 2026-03-13.
- [ ] Create reusable invocable facade class (`OnboardingInvocables.cls`) with typed request/response DTOs.
- In progress: `OnboardingInvocables.cls`, `OnboardingFollowUpInvocables.cls`, and `OnboardingInvocablesTest.cls` added on 2026-03-12.
- [ ] Add standard trigger-handler base/recursion guard where missing; add bulk safety tests.
- In progress: `TerritoryAssignmentsTrigger`, `EmailCommTerritoryRoleHelper`, and `EmailCommTerritoryRoleHelperTest` now use `oldMap` diff filtering, clear stale role rows on lookup removal, and validate a 210-record mixed-state trigger path (2026-03-12); the retired `VersioningTriggerHandler` path is intentionally out of scope.
- [ ] Introduce GraphQL read-path proof of concept for `objectRelatedList` behind a feature flag, keep Apex fallback.
- [ ] Add a standard Flow Fault Handler subflow and wire at least one representative flow.
- In progress: `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` plus `DOMAIN_OmniSObject_SFL_CREATE_Follow_Up_Queue` now standardize queue-based fault handling across `DOMAIN_OmniSObject_ACTION_Send_Communication_Template`, `BLL_Onboarding_SFL_Dispatch_Communication_By_Context`, `BLL_Training_Assignment_SCD_Training_Reminder_Emails`, and the legacy `DOMAIN_OmniSObject_SFL_Send_Email_Communication` path, including terminal scheduler-fault logging without onboarding context (2026-03-13).
- [ ] Expand Jest tests for `objectRelatedList` and `programDatesRelatedList*`; add Apex negative-path and bulk tests.

## Suggested Execution Sequence
1. `P0` sharing/FLS enforcement audit + fixes in Apex services/controllers.
2. `P0` flow fault-handler subflow + sample wiring.
3. `P0` trigger bulk/recursion verification + test additions.
4. `P1` invocable facade + tests.
5. `P1` logging/exception standardization pass.
6. `P2` GraphQL LWC proof of concept + feature flag.
7. `P2` CI drift and test-gate tightening.
