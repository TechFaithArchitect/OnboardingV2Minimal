# Apex Classes (MVP – Curated)

This list reflects classes present in this repo that power the MVP onboarding experience.

## Invocables (Flow Actions)
- `OnboardingDefaultVendorProgramInvocable` - Resolves default Vendor Program for flow scenarios (e.g., REQUIRE_NDA) from `Onboarding_Default_Vendor_Program__mdt`.
- `OnboardingStatusEvaluatorInvocable` - Evaluates Onboarding Status from requirement statuses using `Onboarding_Status_Evaluation_Rule__mdt`; called by `BLL_Onboarding_Requirement_RCD_Logical_Process`.
- `OnboardingFollowUpInvocables` - Evaluates follow-ups for Onboarding Requirements.
- `OnboardingInvocables` - Get eligible vendors as JSON for LWC.
- `OnboardingRequirementSubjectInvocable` - Creates Onboarding Requirement Subjects idempotently.
- `RecordCollectionEditorConfigService` - Record creation from config.
- `RecordCollectionEditorGetRecordsService` - Record retrieval for editors.
- `RecordCollectionEditorAsyncService` - Async record operations.
- `ExperienceOpportunityCreateAsyncService` - Queues Contact/Opportunity creation.
- `VendorOnboardingJsonAdapter` - Get eligible vendors as JSON for LWC.
- `FlowAdminGuardService` - Flow admin guard.

## Follow‑Up & Messaging (SMS)
- `FollowUpDetectionService` - Detects follow-up needs.
- `FollowUpExecutionService` - Sends SMS follow-ups (email handled by Flow).
- `FollowUpMessagingService` - Provider-agnostic messaging.
- `FollowUpRuleRepository` - Follow-up rule access (CMDT).
- `FollowUpFatigueService` - Rate-limits outreach.
- `TwilioSMSProvider` - Twilio implementation for SMS.
- `SalesforceMessagingProvider` - Native Messaging fallback.
- `TwilioSettingsController` - Twilio configuration UI.

## Onboarding & Vendor
- `VendorOnboardingService` - Onboarding eligibility and vendor operations.
- `OnboardingStatusEvaluatorService` - Evaluates Onboarding Status from requirement statuses and CMDT rules.
- `VendorOnboardingEligibilityRuleEngine` - Eligibility rule evaluation.
- `VendorPrerequisiteEvaluator` - Prerequisite checks for onboarding.
- `ObjectRelatedListController` - Reusable LWC combobox data.

## Email & Sync
- `EmailTemplateSyncService` - Syncs email templates.
- `EmailTemplateSyncOrchestrator` - Orchestrates template sync.
- `EmailTemplateSyncJob` - Scheduled sync job.
- `EmailCommTerritoryRoleHelper` - Territory-role sync for email.

## Utilities
- `PicklistHelper` - Picklist utilities.
- `LoggingUtil` - Logging helpers.
