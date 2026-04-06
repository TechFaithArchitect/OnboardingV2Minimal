# Salesforce Best Practices Findings and Action Plan

This report summarizes concrete, prioritized actions to align this repository with Salesforce best practices. Each item includes rationale, evidence (when applicable), and explicit remediation steps with suggested diffs or commands.

Scope reviewed in this pass:
- Apex: VendorOnboardingService.cls, OnboardingDefaultVendorProgramInvocable.cls, OnboardingStatusEvaluatorInvocable.cls, ExceptionUtil.cls
- Flows: DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record.flow-meta.xml
- Repo hygiene: presence of .DS_Store, config and manifests overview
- Inventory: Invocable methods across classes (search)

Note: This report is intended to be iterative. Additional classes/flows can be added in subsequent passes.

--------------------------------------------------------------------------------

Execution status (rolling; last major update **2026-04-06**):
- Completed: Repo hygiene hardening for `.DS_Store`
  - Added `.DS_Store` ignore coverage in `.gitignore` and `.forceignore`.
  - Removed existing `.DS_Store` files from the working tree.
- Completed: Entry-point sharing audit pass
  - Verified invocable/Aura entry classes currently declare explicit sharing.
  - Added script: `scripts/automation/audit-apex-entry-sharing.sh`.
- Completed: CI/CD quality gates (local/tooling)
  - Added `pmd-ruleset.xml`.
  - Added scripts:
    - `scripts/automation/run-apex-pmd.sh`
    - `scripts/automation/run-flow-audits.sh`
  - Updated `package.json` scripts:
    - `pmd:apex`
    - `audit:flows`
    - `audit:apex:sharing`
    - `quality:check`
    - `test:apex:hardening` (consolidated in-scope Apex sweep; see script below)
  - Validation run:
    - `npm run audit:apex:sharing` passes.
    - `npm run audit:flows` passes (screen-flow fault messaging, subflow `errorMessage` contracts, and **no `faultConnector` inside `<subflows>`** — see `audit-flow-subflow-no-fault-connector.sh`).
    - PMD CLI installed locally via `pmd-bin` dev dependency.
    - `npm run pmd:apex` runs clean for production classes: `0` findings (see PMD sections below).
    - PMD ruleset excludes `*Test.cls` and `Test*.cls` to focus on production code first.
- Completed: CRUD/FLS write sanitization rollout (documented slices)
  - Added `Security.stripInaccessible` before DML in:
    - `ExpOpportunityCreateRecord.updateAccountFromRequest`
    - `OnboardingRequirementSubjectInvocable.createSubjectsIdempotent`
    - `AccountVendorOnboardingSyncInvocable.sync` (insert + update paths)
    - `OnbReqContractEvidenceInvocable` subject + onboarding update batches
    - `OnbReqParentBulkEvalInvocable` first-pass, retry, and completed-only update batches
  - Validation run in org `OnboardV2`:
    - `OnbReqSubjectInvocableTest`
    - `AccountVendorOnboardingSyncInvocableTest`
    - `ExpOpportunityCreateRecordTest`
    - `OnbReqContractEvidenceInvocableTest`
    - `OnbReqParentBulkEvalInvocableTest`
  - Result: 38 tests passed, 0 failed.
- Completed: PMD `ApexCRUDViolation` burn-down (entry/services-first)
  - Cleared violations in:
    - `AccountVendorOnboardingSyncInvocable`
    - `OnboardingDefaultVendorProgramInvocable`
    - `ExpOpportunityCreateRecord`
    - `AVOTriggerHandler`
    - `OnboardingStatusNormalizationService`
    - `OnboardingPerformanceSettings`
    - `VendorOnboardingEligibilityRuleEngine`
    - `OnboardingErrorLogService`
    - `CommunicationEventDispatchInvocable`
    - `OnboardingStatusEvaluatorService`
    - `OnboardingRequirementVPRGateService`
    - `OnboardingBackgroundRetryService`
    - `LoggingUtil`
    - `CommunicationTemplateBulkSendAction`
    - `RecordCollectionEditorGetRecordsService`
    - `RecordCollectionEditorConfigService`
    - `VendorProgramSeedService` (wave 1-3 slices: full query pass completed with `WITH USER_MODE` across seed + cleanup paths)
  - Validation run in org `OnboardV2`:
    - `AccountVendorOnboardingSyncInvocableTest`
    - `OnboardingDefaultVendorProgramInvocTest`
    - `ExpOpportunityCreateRecordTest`
    - `AVOTriggerHandlerTest`
    - `OnboardingStatusEvaluatorTest`
    - `OnboardingErrorLogInvocableTest`
    - `CommunicationEventDispatchInvocableTest`
    - `OnboardingRequirementVPRGateServiceTest`
    - `OnboardingBackgroundRetryServiceTest`
    - `LoggingUtilTest`
    - `CommunicationTemplateBulkSendActionTest`
    - `RecordCollectionEditorGetRecordsTest`
    - `RecordCollectionEditorConfigServiceTest`
    - `OnboardingNextStepRuleInvocableTest`
  - Result (targeted recent runs): 25 tests passed, 0 failed (`RecordCollectionEditorConfigServiceTest` + `OnboardingNextStepRuleInvocableTest`).
  - Current PMD backlog: `ApexCRUDViolation` findings in production classes are now `0`.
- Completed: PMD non-CRUD backlog burn-down (current ruleset)
  - Cleared warnings in:
    - `OnboardingRequirementSubjectInvocable` (true bulk processing across invocable request batch)
    - `OnbReqParentBulkEvalInvocable` (preloaded requirement/subject reads; retained bounded status-fallback retry loop with explicit suppression)
    - `RecordCollectionEditorAsyncService` (single queue job per invocable batch + queueable finalizer)
    - `ExpOpportunityCreateAsyncService` (single queue job for async branch + queueable finalizer)
    - `OnboardingBackgroundRetryWorker` (queueable finalizer)
    - `OnboardingChainTailQueueable` (queueable finalizer)
    - `ObjectRelatedListController` (validated dynamic SOQL paths explicitly suppressed)
    - `PicklistHelper` (deferred describes)
    - `OnboardingPerformanceSettings` (centralized warn logging)
    - `LoggingUtil` and `CommunicationTemplateBulkSendAction` (targeted PMD suppressions for intentional patterns)
  - Validation run in org `OnboardV2`:
    - `OnbReqSubjectInvocableTest`
    - `OnbReqParentBulkEvalInvocableTest`
    - `RecordCollectionEditorAsyncServiceTest`
    - `ExpOppCreateAsyncServiceTest`
    - `ExpOpportunityCreateRecordTest`
    - `OnboardingBackgroundRetryServiceTest`
    - `CommunicationTemplateBulkSendActionTest`
    - `LoggingUtilTest`
  - Result: all targeted test runs passed.
  - Current PMD backlog: production-class findings under `pmd-ruleset.xml` are now `0`.
- Completed (org-connected): consolidated Apex sweep for all classes exercised above
  - Script: `scripts/deploy/run-best-practices-in-scope-tests.sh`
  - npm: `npm run test:apex:hardening` (default target org: `OnboardV2`; pass another alias as the first argument, or set `SF_TARGET_ORG`)
  - Scope: 20 test classes (union of CRUD/FLS validation + both PMD burn-down validation lists + `ObjectRelatedListCtrlTest` for `ObjectRelatedListController`).
  - Validation run in org `OnboardV2` (2026-04-06): **74 tests, 100% pass** for the 19-class union (test run id `707RL00001Kq9wL`; CLI may stop polling early—use `sf apex get test -i <id> -o <alias> --result-format human --code-coverage` to retrieve). `ObjectRelatedListCtrlTest` is now included in the script for `ObjectRelatedListController`; standalone validation **8 tests, 100% pass** (run id `707RL00001KrKnm`). Script `--wait` is **45** minutes to reduce polling timeouts.
- Completed: LWC security and testing (finding 6 — 2026-04-06)
  - Jest: `force-app/test/lwc/expCreateRecord.test.js` (loadContext missing account, Apex failure, exception `body.message`).
  - Jest: `force-app/test/lwc/recordCollectionEditor.test.js` (required `configKey`, `getConfig` wire error).
  - `jest.config.js` maps `lightning/flowSupport` for screen components (`force-app/test/jest-mocks/lightning/flowSupport.js`).
  - Docs: [ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md](../reference/ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md), [TEST_AND_QUALITY.md](./TEST_AND_QUALITY.md).
  - Validation: `npm run test:unit` — 27 tests passed.
- Completed: Permission sets and least privilege (finding 7 — 2026-04-06)
  - Granted **`ExpOpportunityCreateRecord`**, **`ExpOpportunityCreateAsyncService`**, **`ObjectRelatedListController`** on **`Onboarding_Program_Sales_Team`** (create flow + lookup paths); **`ObjectRelatedListController`** on other onboarding persona sets that lacked it (Specialists, Account Services, Compliance, Finance, Customer Service, Chuzo agreement add-on).
  - Narrowed **`Onboarding_Account_Services`** **`Order`** object: **`modifyAllRecords` false** (retains `viewAllRecords` and edit/delete per metadata).
  - Added `scripts/automation/audit-permission-set-high-risk.js` + `npm run audit:permissions:highrisk` (fails on Author Apex / Modify All Data class of user permissions; reports object-level modify-all).
  - Docs aligned: [PERSONA_AND_PERMISSION_SETS.md](./PERSONA_AND_PERMISSION_SETS.md), [SECURITY_AND_ACCESS.md](./SECURITY_AND_ACCESS.md).
- Completed: Documentation alignment (finding 10 — 2026-04-06)
  - [FLOW_CATALOG.md](../developer/FLOW_CATALOG.md): repo-accurate flow counts (84), `apiVersion` spread, subflow (`flowName`) pinning behavior and fan-in summary; removed obsolete `Onboarding_Subflow_*` / `Opportunity_Subflow_*` table rows not present in source.
  - [BRE_AND_CREDENTIALS_FOR_NEW_USERS.md](../reference/BRE_AND_CREDENTIALS_FOR_NEW_USERS.md): clarified `OnboardingRecordBREGateInvocable` (**CommunicationDispatch** context, non-throwing contract).
  - [DEPLOYMENT_RUNBOOK.md](../admin/DEPLOYMENT_RUNBOOK.md): portable manifest links, optional `npm run test:apex:hardening`.
  - [ADMIN_OPERATIONS_RUNBOOK.md](../admin/ADMIN_OPERATIONS_RUNBOOK.md): manifests / `scripts/deploy` / `scripts/automation` / this document.
  - [docs/README.md](../README.md) architecture note; [scripts/README.md](../../scripts/README.md); [doc-metrics.js](../../scripts/doc-metrics.js) now emits flow prefix + `apiVersion` histogram for `npm run doc:metrics`.
- Completed: Explicit sharing on every production Apex class (2026-04-06)
  - `with sharing` on `OnboardingDomainException` (public domain type; defaults any future logic to user sharing).
  - `inherited sharing` on invocable DTOs only: `OnboardingEnqueueOnboardingTailRequest`, `OnboardingEnqueueOnboardingTailResponse`, `OnboardingPerformanceRoutingRequest`, `OnboardingPerformanceRoutingResponse`.
  - [audit-apex-entry-sharing.sh](../../scripts/automation/audit-apex-entry-sharing.sh) now checks (1) `@InvocableMethod` / `@AuraEnabled` entry classes and (2) all non-test `.cls` files whose first top-level type is a `class` (interfaces skipped).
- Completed: CRUD/FLS + governor/bulk gates (re-verified 2026-04-06)
  - `npm run pmd:apex` / [run-apex-pmd.sh](../../scripts/automation/run-apex-pmd.sh): **0** findings for production classes under [pmd-ruleset.xml](../../pmd-ruleset.xml) (security, errorprone, performance, bestpractices).
- Completed: Flow metadata + fault contracts (2026-04-06)
  - [audit-flow-subflow-no-fault-connector.sh](../../scripts/automation/audit-flow-subflow-no-fault-connector.sh): fails if any `<subflows>` block contains `<faultConnector>` (not deployable); included in [run-flow-audits.sh](../../scripts/automation/run-flow-audits.sh) / `npm run audit:flows`.
  - Related source fix: `DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records` uses post-subflow `errorMessage` decision instead of subflow `faultConnector`.
- Completed: LWC-facing Apex errors (finding 4 — ExceptionUtil, 2026-04-06)
  - [VendorOnboardingService.getVendorOptions](../../force-app/main/default/classes/VendorOnboardingService.cls) (`@AuraEnabled`): unexpected failures now throw `ExceptionUtil.unexpectedAuraError` (reference id + server log via `LoggingUtil`).
  - [RecordCollectionEditorConfigService.getCanAssignAuthorizedSigner](../../force-app/main/default/classes/RecordCollectionEditorConfigService.cls): JSON/permission parse failures still fail-open (`true`) for UX but call `ExceptionUtil.unexpectedUserMessage` so support gets a reference + error log.
  - Already aligned: `RecordCollectionEditorConfigService.getConfig` (`domainError` / `unexpectedAuraError`), `ObjectRelatedListController` (`@AuraEnabled` methods), `ExpOpportunityCreateRecord` (imperative methods use `unexpectedUserMessage` on `LoadContextResponse` / `SaveContactsResponse` / `SubmitResponse`).

--------------------------------------------------------------------------------

1) Enforce explicit sharing models on Apex entry points
Severity: High
Rationale: Explicit sharing (with/without sharing) is required for predictable record access in Apex, especially for code invoked by Flows/LWCs.
Evidence observed:
- VendorOnboardingService.cls: public with sharing class VendorOnboardingService { … } (good)
- OnboardingDefaultVendorProgramInvocable.cls: public with sharing class OnboardingDefaultVendorProgramInvocable { … } (good)
- OnboardingStatusEvaluatorInvocable.cls: public with sharing class OnboardingStatusEvaluatorInvocable { … } (good)
Risk: Other Apex classes might lack explicit sharing declarations.

Action:
- Audit all Apex classes in force-app/main/default/classes for missing explicit sharing keywords.
- Add “with sharing” to classes that expose entry points (Invocable/@AuraEnabled) unless a documented exception requires “without sharing”.

Suggested pattern:
public with sharing class ClassName { … }

--------------------------------------------------------------------------------

2) Standardize CRUD/FLS enforcement
Severity: High
Rationale: Enforcing object/field permissions is mandatory when Apex reads/writes SObjects outside Flow-guarded contexts. Queries use WITH SECURITY ENFORCED in several places, which is good for reads; writes still require sanitization.
Evidence:
- VendorOnboardingService queries include WITH SECURITY ENFORCED (good).
- OnboardingDefaultVendorProgramInvocable queries include WITH SECURITY ENFORCED (good).
- Flow updates are handled via Flow DML (platform-enforced), which is fine. For Apex performing DML, we must sanitize records.

Action:
- In any Apex service that performs DML on records constructed from user/LWC/Flow inputs, sanitize before DML:
List<SObject> sanitized = (List<SObject>) Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();
- For creates, use AccessType.CREATABLE.
- Continue preferring WITH SECURITY ENFORCED for SOQL; where it is too restrictive, supplement with Schema checks and stripInaccessible.

--------------------------------------------------------------------------------

3) Maintain bulkification and governor limit safety
Severity: Medium
Rationale: Prevent SOQL/DML in loops and keep operations bulk-safe.
Evidence:
- Automated scan found no obvious SOQL/DML-in-loop in classes inspected.
- VendorOnboardingService queries once and iterates in-memory collections (good).

Action:
- Keep static analysis in CI (see Section 7) to prevent regressions.
- For any new invocables, accept List<T> inputs and process in bulk to respect Flow bulk execution.

--------------------------------------------------------------------------------

4) Centralize exception handling and user-facing errors
Severity: Medium
Rationale: Consistent user messaging and structured logging is essential across LWCs/Flows.
Evidence:
- ExceptionUtil provides domainError and unexpectedAuraError with reference codes and LoggingUtil (good).
- Some invocables log via LoggingUtil; ensure all controllers funnel unexpected errors through ExceptionUtil.

Action:
- In Apex controllers/LWC adapters, wrap exceptions with ExceptionUtil.unexpectedAuraError('ContextLabel', ex, 'Friendly message') to return an AuraHandledException when used in Aura/LWC contexts, or capture messages for invocable outputs.
- For invocables, set a consistent errorMessage field; avoid exposing raw stack traces to end users.

--------------------------------------------------------------------------------

5) Flow fault handling and contracts
Severity: High
Rationale: Every DML/Action in Flows should have a fault connector with a predictable capture path and user-friendly outputs.
Evidence:
- DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record.flow-meta.xml includes faultConnector elements on Record Create/Updates and uses Capture_* to assign $Flow.FaultMessage to errorMessage (good).
- Global text search missed <faultConnector> tokens, but reviewed flow shows correct usage.

Action:
- Run existing automation scripts in CI:
  - scripts/automation/audit-screen-flow-fault-user-messaging.sh
  - scripts/automation/audit-subflow-error-contracts.sh
  - scripts/automation/audit-flow-subflow-no-fault-connector.sh
- Ensure all flows route DML/Action faults to consistent handlers and surface minimal, helpful messages. Do not attach `faultConnector` to **subflow** elements (Metadata API); use child `errorMessage` outputs and decisions instead.

--------------------------------------------------------------------------------

6) LWC security and testing
Severity: Medium
Rationale: LWCs must respect CRUD/FLS and provide resilient UX for Apex errors. Tests ensure stability.
Evidence:
- expCreateRecord LWC present; tests/mocks infrastructure exists in force-app/test/lwc and jest.config.js.

Action:
- For LWCs using Apex:
  - Prefer @wire with explicit fields when possible; for imperative calls, handle errors via toasts and log via server or frontend logger.
  - Avoid rendering fields a user lacks access to.
- Add/maintain Jest tests for success/error paths and field-level visibility-driven rendering.

--------------------------------------------------------------------------------

7) Permission sets and least privilege
Severity: High
Rationale: Persona-based access should be minimized to necessary CRUD/FLS/record types and flow run permissions.
Evidence:
- Multiple Onboarding_* permission sets exist.

Action:
- Cross-reference docs/technical/PERSONA_AND_PERMISSION_SETS.md with permission set metadata.
- Remove overly broad permissions (e.g., Modify All Data, Author Apex) from general user sets.
- Ensure each persona has only required object/field access and flow permissions.

--------------------------------------------------------------------------------

8) Repository hygiene: exclude transient files, align source API version
Severity: Medium
Rationale: Transient files and drift cause noisy deploys; consistent API version prevents surprises.
Evidence:
- Historical: `.DS_Store` had been committed under `force-app` paths (cleaned per Execution status).
- Flows use `apiVersion` **65.0** in source; `sfdx-project.json` **`sourceApiVersion`** is **65.0**.

Action:
- Update .gitignore (and ensure .forceignore) to exclude .DS_Store throughout.
- Remove committed .DS_Store from the repository history working copy.
- Align sfdx-project.json sourceApiVersion with target orgs (e.g., 65.0, or desired baseline).

Suggested commands (run locally):
- git rm -r --cached .DS_Store
- echo -e "\n# macOS\n.DS_Store\n" >> .gitignore
- Validate sfdx-project.json "sourceApiVersion": "65.0"

--------------------------------------------------------------------------------

9) CI/CD quality gates (recommended additions)
Severity: High
Rationale: Automated gates prevent regressions and enforce standards.
Action:
- Add PMD ruleset for Apex and wire to npm scripts.
- Leverage existing scripts/automation/* for flow audits in CI.
- Run Apex tests with coverage gates and publish reports.
- Run Jest for LWC with coverage.

Local gates are implemented in repo-root [package.json](../../package.json): e.g. `pmd:apex`, `audit:flows`, `audit:apex:sharing`, `audit:permissions:highrisk`, `quality:check`, `test:apex:hardening`, `test:unit`. **`npm run audit:flows`** runs [run-flow-audits.sh](../../scripts/automation/run-flow-audits.sh) (screen-flow messaging, subflow `errorMessage` mapping audit, subflow `faultConnector` ban).

**Still optional for CI:** wire the same commands into a hosted pipeline (e.g. GitHub Actions) with secrets for org-based Apex tests if desired.

Baseline [pmd-ruleset.xml](../../pmd-ruleset.xml) is present (Security, Error Prone, Performance, Best Practices).

--------------------------------------------------------------------------------

10) Documentation alignment
Severity: Medium
Rationale: Up-to-date docs reduce operational risk.
Action:
- Update docs/developer/FLOW_CATALOG.md to reflect active versions and subflow pins.
- Ensure docs/reference/BRE_AND_CREDENTIALS_FOR_NEW_USERS.md matches current behavior.
- Keep admin runbooks aligned with manifests and deployment scripts.

--------------------------------------------------------------------------------

PR / ongoing checklist (after Execution status above)
- **Done in repo:** `.DS_Store` hygiene, PMD + npm scripts, production-class sharing audit, flow audits (including subflow `faultConnector` check), ExceptionUtil on in-package LWC `@AuraEnabled` paths, documented permission-set hardening pass.
- **Optional:** Hosted CI running `npm run quality:check` and/or `npm run test:apex:hardening` (needs org auth).
- **Optional:** Expand manual flow review (`EXP_Opportunity_SCR_Create_Record`, other BLL/DOMAIN) beyond automated audits.
- **Optional:** Written permission-set vs persona **delta** report (metadata + [PERSONA_AND_PERMISSION_SETS.md](./PERSONA_AND_PERMISSION_SETS.md)).
- **Out of scope / org-only:** LWCs reference `OnboardingOrderController` / `ContactECCController` in metadata; Apex sources are not in this package — leave until those classes are retrieved or stubs removed from LWCs/permission sets.

Appendix: Files examined explicitly
- force-app/main/default/classes/VendorOnboardingService.cls
- force-app/main/default/classes/OnboardingDefaultVendorProgramInvocable.cls
- force-app/main/default/classes/OnboardingStatusEvaluatorInvocable.cls
- force-app/main/default/classes/ExceptionUtil.cls
- force-app/main/default/flows/DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record.flow-meta.xml

Next iteration targets (on request)
- Expand review to all invocable classes found by inventory search
- Review EXP_Opportunity_SCR_Create_Record.flow-meta.xml and other BLL/DOMAIN flows for consistent fault and loop patterns (automation covers subflow metadata + `errorMessage` contracts; this is a deeper human pass)
- LWC `expCreateRecord` tests: **addressed** (finding 6; `npm run test:unit`)
- Diff permission sets against documented personas and produce a permissions delta
