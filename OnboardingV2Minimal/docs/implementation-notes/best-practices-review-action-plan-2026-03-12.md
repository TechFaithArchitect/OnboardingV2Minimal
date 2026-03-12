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

## A. Apex (Architecture, Security, Limits, Testability)
- [ ] Enforce sharing model consistency and security annotations.
- [ ] Confirm all exposed UI/Flow-invoked services/controllers use `with sharing`.
- [ ] Ensure SOQL parity with `WITH SECURITY_ENFORCED` where appropriate.
- [ ] Add `WITH USER_MODE` / user-mode DML (`Database.insert(records, AccessLevel.USER_MODE)`) for UI-context writes where appropriate.
- [ ] Document and encapsulate explicit system-mode exceptions.
- [ ] Adopt invocable Apex facades for Flow-bound operations where possible.
- [ ] Add `@InvocableMethod` + typed `@InvocableVariable` DTO wrappers for selected operations.
- [ ] Standardize exception handling.
- [ ] Centralize domain exception base type and user-safe error messaging for UI calls.
- [ ] Keep production code free of ad hoc `System.debug`.
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
- [ ] Use `Trigger.newMap` / `oldMap` diffs to minimize unnecessary work.
- [ ] Add comprehensive trigger tests:
- [ ] Bulk insert/update over 200 records.
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
- [ ] Introduce/standardize a common fault-handler subflow to:
- [ ] Log context (`recordId`, user, flow version, element label, error).
- [ ] Show user-friendly messages.
- [ ] Emit platform event or write custom log record.
- [ ] Optionally notify ops channel (email/PEN).
- [ ] Extract large flows into idempotent subflows (retrieval, validation, rule evaluation, DML).
- [ ] For high-volume record-triggered flows, tighten entry criteria:
- [ ] Use "Only when updated to meet condition".
- [ ] Minimize repeated `Get Records`; prefer collection-based filtering patterns.

## E. Data Model, FLS, and Metadata Hygiene
- [ ] Prefer object-level requiredness (field requiredness/validation rules) over repeated Flow-only checks.
- [ ] Standardize shared picklists with global value sets; remove duplicate local picklists where feasible.
- [ ] Prefer permission sets over profile-based net-new grants.
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
- [ ] Create reusable invocable facade class (`OnboardingInvocables.cls`) with typed request/response DTOs.
- [ ] Add standard trigger-handler base/recursion guard where missing; add bulk safety tests.
- [ ] Introduce GraphQL read-path proof of concept for `objectRelatedList` behind a feature flag, keep Apex fallback.
- [ ] Add a standard Flow Fault Handler subflow and wire at least one representative flow.
- [ ] Expand Jest tests for `objectRelatedList` and `programDatesRelatedList*`; add Apex negative-path and bulk tests.

## Suggested Execution Sequence
1. `P0` sharing/FLS enforcement audit + fixes in Apex services/controllers.
2. `P0` flow fault-handler subflow + sample wiring.
3. `P0` trigger bulk/recursion verification + test additions.
4. `P1` invocable facade + tests.
5. `P1` logging/exception standardization pass.
6. `P2` GraphQL LWC proof of concept + feature flag.
7. `P2` CI drift and test-gate tightening.
