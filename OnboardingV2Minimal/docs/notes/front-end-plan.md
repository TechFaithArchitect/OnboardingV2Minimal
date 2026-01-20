Front-end Plan: Admin / Developer / User Friendly

Guiding principles
- Thin controllers, strong services: Flows and LWCs orchestrate; complex logic stays in Invocable Apex services.
- Single entry points: Minimize proliferation of flows/components with clear surfaces per role.
- Observable by design: Preview/trace, version indicators, and refresh UX to handle mid-flow rule changes.

Role-based surfaces
- Admin
  - Status Rules Console (extend onboardingStatusRulesEngine)
  - Vendor Program Builder (vendorProgramOnboardingFlow + onboardingFlowEngine + onboardingStageRenderer)
  - Evaluation Preview screen flow (new)
- Operations (Account Services)
  - Requirements Workbench (augment onboardingRequirementsPanel)
  - Onboarding Home Dashboard enhancements (onboardingHomeDashboard)
- End users (broader org)
  - Read-only dashboards and quick actions to guided work surfaces

Phase plan (incremental)
Phase 1: Quick wins
- Admin: Add “Preview Evaluation” to onboardingStatusRulesEngine
  - New Apex (previewStatusEvaluation) returns evaluation trace (engines considered, per-rule pass/fail, short-circuit reason, final status).
  - Modal datatable with filter by Group/Engine/Rule# and export CSV.
- Ops: onboardingRequirementsPanel banner + refresh
  - Banner: “Rules changed since page load. Refresh to evaluate with latest rules.”
  - Button triggers re-fetch of rules version + re-run evaluation (single Apex call).
- Dashboard: At-Risk panel
  - Wire OnboardingBlockingDetectionService to show blocked/at-risk counts and quick links.

Phase 2: Observability and guidance
- Admin: Evaluation Trace Modal v2
  - “As Of” datetime to simulate effective-dated rules.
  - “Pin rules version” toggle for previewing pinned vs latest behavior.
- Ops: Next-best guidance in workbench
  - Side panel lists blocking requirements and recommended next actions (based on current matched engine).
- End-user: Quick links
  - Dashboard rows open directly into the workbench context for the selected onboarding.

Phase 3: Builder experience
- Admin: Stage Library
  - Tile list generated from Onboarding_Component_Library__c with descriptions and prerequisites.
- Admin: “Test Run” mode
  - Vendor Program builder screen simulates the process without DML; collects a UI trace (stage renders, validation outcomes).

Phase 4: Version-aware UX (optional)
- Rules version context provider
  - Capture “active rules version” (Id/Version__c) at session start; pass in requests; show “using pinned version” chip with “Switch to latest” action.
- Promote/Clone quick actions
  - On rules engines, add “Promote to Active” and “Clone to New Version”.

LWC surface changes (mapping to repo)
- onboardingStatusRulesEngine (Admin)
  - Add “Preview” button → opens modal
  - Apex: previewStatusEvaluation(onboardingId, asOfDateTime?, rulesEngineIds?) → TraceDTO[]
- onboardingRequirementsPanel (Ops)
  - Add rules-changed banner; “Refresh” calls a small Apex to fetch current rules version + re-run evaluator
  - Batch update + re-evaluate in one click; show final status toast
- onboardingHomeDashboard (Ops/Managers)
  - Add “Blocked/At Risk” card with drill-in (getBlockedOnboardingCount, getOnboardingWithBlockingInfo)
  - Quick links to open workbench (with onboardingId)
- vendorProgramOnboardingFlow / onboardingFlowEngine / onboardingStageRenderer (Admin)
  - “Stage Library” panel (query Onboarding_Component_Library__c)
  - “Test Run” toggle (bypass DML, log UI trace)

Apex APIs to expose/extend
- Preview evaluator (new)
  - @AuraEnabled(cacheable=true) previewStatusEvaluation(onboardingId, asOfDateTime?, rulesEngineIds?) → List<TraceDTO>
- Rules version utility (new)
  - @AuraEnabled(cacheable=true) getActiveRulesVersion(groupIds?, asOfDateTime?) → RulesVersionInfo
- Existing services (reuse)
  - OnboardingStatusEvaluator (deterministic status)
  - OnboardingBlockingDetectionService (blocked/at-risk)
  - OnboardingApplicationService (stages, progress)
  - OnboardingRulesService (rules lookup)

UX details and SLDS patterns
- Use slds-card and slds-grid for all panels; datatables for trace and work queues
- Focus management for modals; keyboard navigation; proper aria labels
- Toast conventions: success on evaluated status, warning on rules changed, error on validation issues

Testing approach
- Apex: unit tests for preview/trace logic, effective dating filters, version pinning
- LWC: Jest tests for banner visibility logic, modal interactions, quick link navigation
- Manual flows: Screen flow preview for evaluation scenarios

Documentation
- docs/notes/front-end-plan.md (this doc)
- docs/README.md link under “Front-end Surfaces” and “How to change rules safely”
- Short runbooks for admins (preview, promote, clone) and ops (workbench usage)

Expected outcomes
- Admins: High-confidence changes with preview and promotion; discoverable stage library; optional version pinning.
- Developers: Fewer flows, compact Apex API surface, clear responsibilities.
- Ops/Users: Clear blocking info, next steps, consistent and responsive UI with minimal surprises.
