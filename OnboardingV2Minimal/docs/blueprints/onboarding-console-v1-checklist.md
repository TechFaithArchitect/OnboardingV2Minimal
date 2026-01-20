# Onboarding Console v1 – Tracked Checklist and Scaffolding Plan

Scope decisions (locked)

- Experience surface: Use existing Experience Cloud site with LWC + Screen Flows on an Experience page (1A)
- Enrollment model: Multiple concurrent Vendor Program enrollments with deduped shared requirements (2A)
- Dealer actions (v1): Forms only via lightning-record-edit-form (3A)
- Rep interventions (v1): Due date overrides (4B)
- SLA & Risk (v1): Include progress + risk badges (5A)
- Deferred for later phases: notifications, analytics, branding

Milestone 1 — Foundation and Contracts

- [x] Confirm or create Experience Cloud page for “Onboarding Console”
- [x] Define data contracts (Apex DTOs) for:
  - [x] EvaluateOnboardingStatusResult (removed - replaced by existing DTOs)
  - [x] DealerChecklistResult (removed - replaced by existing DTOs)
  - [x] ProgramValidationIssue (removed - replaced by existing validation approach)
- [x] GraphQL query design (LDS-first read surfaces):
  - [x] Removed - replaced by existing Apex service calls
  - [x] Fields: Status, Due_Date**c, Template, Program names, Risk_Score**c (now via Apex)
  - [x] Aggregates: completed vs total, earliest due date (now via Apex)
- [x] Security model verification:
  - [x] with sharing for Apex classes
  - [x] WITH USER_MODE queries and AccessLevel.USER_MODE DML
  - [x] WITH SECURITY_ENFORCED on queries where applicable
  - [x] Permission sets outline (Dealer Community, Onboarding Rep, Program Manager)

Milestone 2 — Apex Services (Invocable + Services)

- [x] Service: EvaluateOnboardingStatus (replaced by existing services)
  - [x] Uses existing Apex services for status evaluation
- [x] Service: GetDealerChecklist (replaced by existing services)
  - [x] Uses OnboardingRequirementsPanelController.getRequirements()
- [x] Service: CreateOrUpdateEnrollments (replaced by existing services)
  - [x] Uses VendorOnboardingWizardController.createOnboardingWithRequirements()
- [x] Service: OverrideRequirementDueDate (new controller added)
  - [x] New controller: OnboardingRequirementDueDateController
  - [x] Updates Due_Date\_\_c, writes audit record (or uses Field History)
  - [x] FLS check, reason captured, unit tests
- [x] Service: ValidateProgramSetup (replaced by existing services)
  - [x] Uses existing validation in consolidated domain services
- [x] Enums (ALL_CAPS_SNAKE_CASE):
  - [x] REQUIREMENT_STATUS (existing)
  - [x] ISSUE_SEVERITY (existing)
- [x] ApexDocs for all classes

Milestone 3 — LWC (Experience page + Internal app)
Dealer Experience page LWCs

- [x] lwc/progressHeader
  - [x] Inputs: progressPercent, riskBadge, activePrograms[]
  - [x] Renders SLA/risk badges
  - [x] Jest tests
- [x] lwc/requirementChecklist
  - [x] Apex wire to fetch grouped stages/requirements (OnboardingRequirementsPanelController.getRequirements)
  - [x] Renders by stage with status, due date, risk
  - [x] “Open Form” action
  - [x] Jest tests
- [x] lwc/requirementFormPanel
  - [x] Wraps lightning-record-edit-form
  - [x] Success -> refresh checklist
  - [x] Jest tests
- [x] lwc/nextBestActionsPanel
  - [x] Calls EvaluateOnboardingStatus/GetDealerChecklist (Apex)
  - [x] Shows actionable next steps and lock explanations
  - [x] Jest tests

Onboarding Rep (Lightning App)

- [x] lwc/repDealerQueue
  - [x] GraphQL list, columns: Dealer, Programs, Stage, Open Count, SLA Risk, Next Action, Nearest Due
  - [x] Row action: “Override Due Date”
  - [x] Jest tests
- [x] lwc/repOverrideDueDateForm
  - [x] Inputs: requirementIds, new date, reason
  - [x] Calls OverrideRequirementDueDate (via new controller)
  - [x] Jest tests

Program Manager (Lightning App)

- [x] lwc/programSetupWizardContainer
  - [x] Hosts Screen Flow and runs ValidateProgramSetup
  - [x] Shows validation summary panel
  - [x] Jest tests

Milestone 4 — Flows

- [x] Dealer Enrollment Flow (Screen Flow)
  - [x] Inputs DealerId (from logged-in Experience user)
  - [x] Multi-select programs, dedupe summary
  - [x] Invokes VendorOnboardingWizardController.createOnboardingWithRequirements
  - [x] Flow test coverage (or Apex assertions)
- [x] Rep Override Due Date Flow (optional if not using LWC form)
  - [x] Validates permissions and reason
  - [x] Invokes OnboardingRequirementDueDateController.updateDueDate
- [x] Program Setup Wizard Flow
  - [x] Basics -> Eligibility -> Requirements (from templates) -> Stage/SLAs -> Review -> Activate
  - [x] Validate step using existing validation services

Milestone 5 — Pages, Navigation, and Permissions

- [x] Experience page “Onboarding Console”
  - [x] Place ProgressHeader, RequirementChecklist, NextBestActionsPanel
  - [x] Embed Dealer Enrollment Flow entry point
- [x] Lightning App pages:
  - [x] Onboarding Rep “Dealer Queue” page (repDealerQueue + override form subtab)
  - [x] Program Manager “Program Setup Wizard” page
- [x] Permission sets
  - [x] Dealer Community: CRUD on own Onboarding_Requirement\_\_c; form fields FLS
  - [x] Onboarding Rep: Read-all + Due_Date\_\_c override via new controller
  - [x] Program Manager: program configuration CRUD
- [x] Sharing and guest access constraints validated

Milestone 6 — SLA/Risk, Validation, and UX polish

- [x] Risk buckets: On Track / At Risk / Overdue (computed server-side)
- [x] Display badges in ProgressHeader and Rep queue
- [x] Empty state messages, load/error states
- [x] Accessibility passes on LWCs
- [x] Final review against docs/notes/email-comm-removal.md (avoid hardcoded email)

Testing and Quality Gates

- [x] Apex coverage ≥ 75% with assertions
- [x] LWC Jest tests for key components and flows
- [x] Flow tests/automation
- [x] SOQL/DML limits validation, no SOQL/DML in loops
- [x] Static Code Analysis clean (PMD/ESLint if applicable)

Deliverables for v1 (Definition of Done)

- [x] Experience Onboarding Console page deployed
- [x] Dealer can enroll in multiple programs and sees deduped requirement checklist
- [x] Dealer can complete requirements via forms
- [x] Progress and risk badges visible
- [x] Rep queue available with due date override
- [x] PM setup wizard container and validation available
- [x] Permissions configured and verified
- [x] Tests passing locally and in CI

Appendix — Object references (indicative)

- Vendor_Program\_\_c
- Onboarding\_\_c (Dealer-Program join)
- Onboarding_Requirement**c (link to Vendor_Program_Requirement**c)
- Vendor_Program_Requirement\_\_c
- Onboarding_Stage\_\_c

Notes

- LDS-first for CRUD; Apex wire for complex reads and aggregates
- with sharing; WITH USER_MODE; WITH SECURITY_ENFORCED
- Enums over string constants; return early; bulkify
- No hardcoded IDs/URLs; no System.debug in prod code
