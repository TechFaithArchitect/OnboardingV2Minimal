# Apex Classes (MVP – Curated)

This list is intentionally **curated** to reflect the classes that power the MVP onboarding experience.
It does **not** list every class in the repo. If you need the full inventory, generate it from the
filesystem (or ask and I can provide a separate “full list” doc).

## Controllers (LWC / Admin UI)
- `AccountProgramOnboardingController` - Starts onboarding from an Account (program selection, contacts, opportunity).
- `OnboardingHomeDashboardController` - Data for the home dashboard and queues.
- `OnboardingRequirementsPanelController` - Requirement list/status updates for a single Onboarding.
- `OnboardingStatusRulesEngineController` - Admin UI for status rules engine.
- `OnboardingStatusRuleController` - CRUD for `Onboarding_Status_Rule__c`.
- `OnboardingRequirementDueDateController` - Requirement due date utilities.
- `OnboardingAdminDashboardController` - Admin metrics and queue health.
- `OnboardingAppActivationController` - Activation orchestration for vendor programs.
- `TwilioSettingsController` - Twilio configuration UI (CMDT read/validate).

## Core Services (Onboarding + Rules)
- `VendorDomainService` - Vendor + Vendor Program search/create.
- `VendorProgramService` - Vendor Program operations.
- `VendorProgramGroupService` - Vendor Program Group operations.
- `RequirementDomainService` - `Vendor_Program_Requirement__c` CRUD and sequencing.
- `CommunicationDomainService` - `Communication_Template__c` access and linking.
- `StatusRulesEngineService` - `Onboarding_Status_Rules_Engine__c` management.
- `OnboardingRulesService` - `Onboarding_Status_Rule__c` operations.
- `OnboardingRuleEvaluator` - Evaluates status rule logic.
- `OnboardingStatusEvaluator` - Applies status changes and progress fallbacks.
- `OnboardingExpressionEngine` - Expression evaluator for custom rule logic.
- `OnboardingApplicationService` - Requirement DTOs and rule evaluation helpers for the requirements panel.
- `OnboardingBlockingDetectionService` - At‑risk/blocking detection logic for dashboards.

## Activation & Validation (Vendor Program)
- `OnboardingAppActivationService` - Runs activation validations.
- `OnboardingAppRuleRegistry` - Registry for activation rules.
- `OnboardingAppActivationRule` - Activation rule interface.
- `OnboardingAppValidationRule` - Validation rule interface.
- `ActivationStrategyFactory` - Activation strategy selection.
- `VendorProgramActivationService` - Activation orchestration for vendor programs.
- `VendorCustomizationActivationStrategy` - Vendor program activation strategy.
- `GenericActivationStrategy` - Default activation strategy.
- `OnboardingAppActivationOrchestrator` - Activation orchestration invoked by controller.
- `OnboardingAppRuleEngineHandler` - Trigger entry point for activation rule evaluation.
- `EnforceTargetProgramPerGroupHandler` - Ensures a single target program per group.
- `AllStatusRuleGroupMustBeActiveRule`
- `AllTemplatesInReqSetMustBeActiveRule`

## External Credentials & Training
- `OnboardingAppECCService` / `OnboardingAppECCRepository` - External contact credential data.
- `OnboardingAppVendorProgramReqSvc` - Required credentials + training requirements.
- `OnboardingAppVendorProgramReqHdlr` - Data loading helpers.
- `OnboardingAppVendorProgramReqOrch` - Orchestration for credential/training updates.

## Follow‑Up & Messaging (SMS)
- `FollowUpDetectionService` - Detects follow-up needs.
- `FollowUpExecutionService` - Sends SMS follow-ups (email handled by Flow).
- `FollowUpMessagingService` - Provider-agnostic messaging.
- `FollowUpRuleRepository` - Follow-up rule access (CMDT).
- `FollowUpFatigueService` - Rate-limits outreach.
- `TwilioSMSProvider` - Twilio implementation for SMS.
- `SalesforceMessagingProvider` - Native Messaging fallback.

## Repositories & Utilities
- `VendorOnboardingWizardRepository` - Shared data access for onboarding/admin UI.
- `OnboardingRulesRepository` - Status rules data access.
- `OnboardingMetricsRepository` - Metrics for admin dashboards.
- `OnboardingRepository` - Onboarding data access.
- `VendorCustomizationRepository` - Vendor customization data access.
- `PicklistHelper`, `DefaultValueHelper`, `ValidationHelper`, `FLSCheckUtil`, `CustomMetadataUtil`, `LoggingUtil`
- `VendorProgramStatusMapper` - Admin permission checks.
- `OnboardingDashboardFilterService` - Dashboard filter logic.
- `OnboardingEligibilityService` - Eligibility checks for onboarding.
- `OnboardingAccessService` - Owner/team access filtering for dashboard data.

## Optional / Admin Sync (Keep only if used)
- `EmailTemplateSyncService` / `EmailTemplateSyncOrchestrator` / `EmailTemplateSyncJob` / `EmailTemplateSyncFlowAction`
- `EmailTemplateSyncController` (scheduled entry point)
- `EmailCommTerritoryRoleHelper` / `EmailCommTerritoryRoleSyncJob` (territory-role sync)
