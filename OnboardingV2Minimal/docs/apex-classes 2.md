# Apex Classes Cleanup Tracker (V2)

Date: 2026-02-26

## Current Count
- Removed from OnboardV2 in Wave 18: 16
- Removed from OnboardV2 in Wave 20: 9
- Removed from OnboardV2 in Wave 21: 4
- Removed from OnboardV2 in Wave 22: 1
- Removed from OnboardV2 in Wave 23: 5
- Removed from OnboardV2 in Wave 24: 7
- Removed from OnboardV2 in Wave 25: 2
- Removed from OnboardV2 in Wave 26: 2
- Removed from OnboardV2 in Wave 27: 3
- Removed from OnboardV2 in Wave 28: 10
- Removed from OnboardV2 in Wave 29: 2
- Removed from OnboardV2 in Wave 30: 2
- Removed from OnboardV2 in Wave 31A: 11
- Removed from OnboardV2 in Wave 31B: 3
- Removed from OnboardV2 in Wave 32: 12
- Removed from OnboardV2 in Wave 34: 6
- Removed from OnboardV2 in Wave 35: 5
- Removed from OnboardV2 in Wave 36: 20
- Removed from OnboardV2 (cumulative): 120
- Explicitly retained (do not remove): 5
- Additional high-confidence removals remaining: 0
- Additional review-needed candidates remaining: 0
- Of those, non-flow-referenced candidates: 0
- Actionable non-flow removals remaining (excluding keep directives): 0
- Unschedule-first candidates: 0

## Explicit Keep (User Directive)
- SalesforceMessagingProvider
- EmailTemplateSyncJob
- FollowUpDetectionService
- TwilioSMSProvider
- TwilioSettingsController

## Removed From OnboardV2 (Wave 18)
- AllTemplatesInReqSetMustBeActiveRule
- CommunicationDomainService
- CustomMetadataUtil
- StatusRulesEngineService
- TestEmailContextFactory
- TestFactoryException
- TestProfileFactory
- OnboardingAppVendorProgramReqHdlr
- EmailTemplateSyncFlowAction
- TestDataFactoryIdUtil
- OnboardingAppVendorProgramReqHdlrTest
- EmailTemplateSyncFlowActionTest
- OrgWideEmailCMDTRepositoryTest
- TestEmailCommSendResultFactory
- TestOrgWideEmailDTOFactory
- TestOrgWideEmailFactory

## Removed From OnboardV2 (Wave 20)
- AllStatusRuleGroupMustBeActiveRule
- AllStatusRuleGroupMustBeActiveRuleTest
- EnforceTargetProgramPerGroupHandler
- OnboardingDashboardFilterService
- OnboardingDashboardFilterServiceTest
- OnboardingReqDueDateControllerTest
- OnboardingRequirementDueDateController
- RequirementDomainService
- VendorProgramRequirementServiceTest

## Removed From OnboardV2 (Wave 21)
- EmailCommTerritoryRoleSyncJob
- EmailCommTerritoryRoleSyncJobTest
- EmailTemplateSyncController
- EmailTemplateSyncControllerTest

## Removed From OnboardV2 (Wave 22)
- AccountProgramOnboardingController

## Removed From OnboardV2 (Wave 23)
- OnboardingAppVendorProgramReqSvc
- OnboardingAppVendorProgramReqCtlr
- OnboardingAppVendorProgramReqSvcTest
- OnboardingAppVendorProgramReqCtlrTest
- OnboardingAppVendorProgramReqOrchTest

## Removed From OnboardV2 (Wave 24)
- OnboardingRequirementsPanelController
- OnboardingReqPanelControllerTest
- OnboardingStatusRuleController
- OnboardingStatusRuleControllerTest
- OnboardingStatusRulesEngineController
- OnboardingStatusRulesEngineCtlrTest
- OnboardingStatusRulesEngineCntlrTest

## Removed From OnboardV2 (Wave 25)
- AccountContactRelationRoleHandler
- OnboardingAppRuleEngineHandler

## Removed From OnboardV2 (Wave 26)
- OnboardingAppActivationController
- OnboardingAppActivationControllerTest

## Removed From OnboardV2 (Wave 27)
- OnboardingAdminDashboardController
- OnboardingHomeDashboardController
- OnboardingHomeDashboardControllerTest

## Removed From OnboardV2 (Wave 28)
- FLSCheckUtil
- OnboardingRequirementService
- OnboardingAppActivationOrchestrator
- OnboardingAppActivationOrchestratorTest
- OnboardingAppVendorProgramReqOrch
- OnboardingBlockingDetectionService
- OnboardingBlockingDetectionServiceTest
- OnboardingEligibilityService
- OnboardingEligibilityServiceTest
- OnboardingMetricsRepository

## Removed From OnboardV2 (Wave 29)
- OnboardingApplicationService
- OnboardingApplicationServiceTest

## Removed From OnboardV2 (Wave 30)
- OnboardingStatusEvaluator
- OnboardingStatusEvaluatorTest

## Removed From OnboardV2 (Wave 31A)
- OnboardingExternalOverrideServiceTest
- OnboardingRepository
- OnboardingRepositoryTest
- OnboardingRequirementTriggerHandlerTest
- OnboardingRuleEvaluator
- OnboardingRuleEvaluatorTest
- OnboardingRulesService
- OnboardingRulesServiceTest
- OnlyOneTargetProgramInGroupRuleTest
- OnboardingAccessServiceTest
- OnboardingAppActivationServiceTest

## Removed From OnboardV2 (Wave 31B)
- OnboardingExpressionEngine
- OnboardingExpressionEngineTest
- OnboardingExternalOverrideService

## Removed From OnboardV2 (Wave 32)
- OnboardingAccessService
- OnboardingAppActivationRule
- OnboardingAppActivationService
- OnboardingAppActivationAction
- OnboardingAppActivationActionTest
- OnboardingAppRuleRegistryTest
- AllChildRequirementsMustBeActiveRule
- AllChildRequirementsMustBeActiveRuleTest
- AllLinkedEngineMustBeActiveRule
- AllLinkedEngineMustBeActiveRuleTest
- AllStatusRulesMustBeActiveRule
- VendorProgramActivationServiceTest

## Removed From OnboardV2 (Wave 34)
- VendorDomainService
- VendorOnboardingJsonService
- VendorOnboardingServiceLWC
- VendorProgramGroupService
- VendorProgramService
- VendorProgramStatusMapperTest

## Removed From OnboardV2 (Wave 35)
- VendorProgramActivationService
- VendorCustomizationActivationStrategy
- VendorCustomizationRepository
- VendorProgramStatusMapper
- VendorCustomizationRepositoryTest

## Removed From OnboardV2 (Wave 36)
- ActivationStrategy
- ActivationStrategyFactory
- CommunicationTemplateService
- GenericActivationStrategy
- OnboardingAppECCController
- OnboardingAppECCControllerTest
- OnboardingAppECCRepository
- OnboardingAppECCRepositoryTest
- OnboardingAppECCService
- OnboardingAppECCServiceTest
- OnboardingAppRuleRegistry
- OnboardingAppValidationRule
- OnboardingNextStepService
- OnboardingRequirementTriggerHandler
- OnboardingRulesRepository
- OnboardingRulesRepositoryTest
- OnlyOneTargetProgramInGroupRule
- ValidationHelper
- VendorOnboardingWizardRepository
- VendorService

## Remaining Candidates (Review Needed)

### Retained By User Directive (3)
- FollowUpDetectionService
- TwilioSMSProvider
- TwilioSettingsController

### Flow-Protected (Do Not Remove)
- ScreenFlowQuickActionSObjectType

### Wave 36 Status
- Full non-UAT deferred chain was removed after LWC unwind.

## OnboardV2 vs UAT2 Signal
- Wave 19 baseline showed 22/22 backlog candidates present in `OnboardV2` and absent in `UAT2`.
- Wave 20 removed 5 production classes from that V2-only backlog.
- Wave 21 removed 2 additional production classes (plus their tests) after unscheduling cron jobs.
- Wave 22 removed 1 additional production class with its dependent orphan LWC bundle.
- Wave 23 removed a closed req-service cluster (2 production classes + 3 tests) and 2 dependent LWC bundles.
- Wave 24 removed a closed status/requirements cluster (3 production classes + 4 tests) and 11 dependent LWC bundles.
- Wave 25 removed two closed trigger chains (2 production classes + 2 paired triggers).
- Wave 26 untied `Vendor_Customization_Record_Page` from `onboardingAppHeaderBar`, then removed the activation class chain.
- Wave 27 untied `Getting_Started_Home` from `onboardingHomeDashboard`, then removed the dashboard class/LWC chain.
- Wave 28 removed 10 non-ECC classes after closed-chain validation and deferred ECC classes per user direction.
- Wave 29 removed an isolated application service chain (`OnboardingApplicationService` + `onboardingResumePanel`).
- Wave 30 removed an isolated status evaluator pair (`OnboardingStatusEvaluator` + `OnboardingStatusEvaluatorTest`) after UAT2 absence confirmation.
- Wave 31A removed 11 classes from the rule/repository/test chain after UAT2 absence and dependency validation.
- Wave 31B removed a final orphan pair + service (`OnboardingExpressionEngine`, `OnboardingExpressionEngineTest`, `OnboardingExternalOverrideService`).
- Wave 32 unwound and removed the access/activation stack (`OnboardingAccessService`, `OnboardingAppActivationRule`, `OnboardingAppActivationService`) plus its obsolete dependent classes.
- Wave 34 removed 6 Vendor-stack classes after confirming zero `Flow` and zero `LightningComponentBundle` dependencies in OnboardV2.
- Wave 35 removed org-only `vendorProgramHeaderBar`, then removed 5 Vendor activation-chain Apex classes after dependency re-validation.
- Wave 36 removed the full remaining non-UAT deferred closure (20 Apex classes + 1 trigger + 1 LWC).
- Remaining review-needed classes are now cleared for this cleanup stream.
- Baseline matrix file: `.analysis/automation-audit/wave19-execution-2026-02-25/onboardv2_vs_uat2_candidate_presence.tsv`

## Flow Reference Guardrail (Do Not Remove)
- Guardrail rule: if a class is referenced by any flow source, it is protected from deletion.
- Sources checked:
  - Active org flow dependency map
  - Repo flow action bindings (`<actionName>`, `<nameSegment>`)
  - Org metadata dependencies where `Flow` depends on `ApexClass`
- Protected classes:
  - `RecordCollectionEditorConfigService`
  - `RecordCollectionEditorGetRecordsService`
  - `ScreenFlowQuickActionSObjectType`
  - `VendorOnboardingJsonAdapter`
- Guardrail file: `.analysis/automation-audit/wave19-execution-2026-02-25/flow_protected_classes.tsv`

## Evidence
- .analysis/automation-audit/wave18-execution-2026-02-24/apex_removal_ledger_2026-02-25_final.tsv
- .analysis/automation-audit/wave20-execution-2026-02-25/apex_removal_ledger_wave20.tsv
- .analysis/automation-audit/wave21-execution-2026-02-25/apex_removal_ledger_wave21.tsv
- .analysis/automation-audit/wave22-execution-2026-02-25/apex_removal_ledger_wave22.tsv
- .analysis/automation-audit/wave23-execution-2026-02-25/apex_removal_ledger_wave23.tsv
- .analysis/automation-audit/wave24-execution-2026-02-25/apex_removal_ledger_wave24.tsv
- .analysis/automation-audit/wave25-execution-2026-02-25/apex_removal_ledger_wave25.tsv
- .analysis/automation-audit/wave26-execution-2026-02-25/apex_removal_ledger_wave26.tsv
- .analysis/automation-audit/wave27-execution-2026-02-25/apex_removal_ledger_wave27.tsv
- .analysis/automation-audit/wave28-execution-2026-02-25/apex_removal_ledger_wave28.tsv
- .analysis/automation-audit/wave29-execution-2026-02-25/apex_removal_ledger_wave29.tsv
- .analysis/automation-audit/wave30-execution-2026-02-25/apex_removal_ledger_wave30.tsv
- .analysis/automation-audit/wave31-execution-2026-02-25/apex_removal_ledger_wave31.tsv
- .analysis/automation-audit/wave31-execution-2026-02-25/apex_removal_ledger_wave31b.tsv
- .analysis/automation-audit/wave32-execution-2026-02-25/apex_removal_ledger_wave32.tsv
- .analysis/automation-audit/wave34-execution-2026-02-26/apex_removal_ledger_wave34.tsv
- .analysis/automation-audit/wave35-execution-2026-02-26/apex_removal_ledger_wave35.tsv
- .analysis/automation-audit/wave36-execution-2026-02-26/apex_removal_ledger_wave36.tsv
- .analysis/automation-audit/wave26-execution-2026-02-25/apex_removal_ledger_2026-02-25_consolidated.tsv
- .analysis/automation-audit/wave27-execution-2026-02-25/apex_removal_ledger_2026-02-25_consolidated.tsv
- .analysis/automation-audit/wave28-execution-2026-02-25/apex_removal_ledger_2026-02-25_consolidated.tsv
- .analysis/automation-audit/wave29-execution-2026-02-25/apex_removal_ledger_2026-02-25_consolidated.tsv
- .analysis/automation-audit/wave30-execution-2026-02-25/apex_removal_ledger_2026-02-25_consolidated.tsv
- .analysis/automation-audit/wave31-execution-2026-02-25/apex_removal_ledger_2026-02-25_consolidated.tsv
- .analysis/automation-audit/wave32-execution-2026-02-25/apex_removal_ledger_2026-02-25_consolidated.tsv
- .analysis/automation-audit/wave34-execution-2026-02-26/apex_removal_ledger_2026-02-25_consolidated.tsv
- .analysis/automation-audit/wave35-execution-2026-02-26/apex_removal_ledger_2026-02-25_consolidated.tsv
- .analysis/automation-audit/wave36-execution-2026-02-26/apex_removal_ledger_2026-02-25_consolidated.tsv
- .analysis/automation-audit/wave20-execution-2026-02-25/candidate_dependency_decision.tsv
- .analysis/automation-audit/wave26-execution-2026-02-25/wave26_remaining_candidates.tsv
- .analysis/automation-audit/wave27-execution-2026-02-25/wave27_remaining_candidates.tsv
- .analysis/automation-audit/wave28-execution-2026-02-25/wave28_remaining_candidates.tsv
- .analysis/automation-audit/wave29-execution-2026-02-25/wave29_remaining_candidates.tsv
- .analysis/automation-audit/wave30-execution-2026-02-25/wave30_remaining_candidates.tsv
- .analysis/automation-audit/wave31-execution-2026-02-25/wave31_remaining_candidates.tsv
- .analysis/automation-audit/wave31-execution-2026-02-25/wave31b_remaining_candidates.tsv
- .analysis/automation-audit/wave32-execution-2026-02-25/wave32_remaining_candidates.tsv
- .analysis/automation-audit/wave34-execution-2026-02-26/wave34_remaining_candidates.tsv
- .analysis/automation-audit/wave35-execution-2026-02-26/wave35_remaining_candidates.tsv
- .analysis/automation-audit/wave35-execution-2026-02-26/wave35_deferred_review.tsv
- .analysis/automation-audit/wave36-execution-2026-02-26/wave36_remaining_candidates.tsv
- .analysis/automation-audit/wave26-execution-2026-02-25/wave26_cleanup_execution_postdeploy.md
- .analysis/automation-audit/wave27-execution-2026-02-25/wave27_cleanup_execution_postdeploy.md
- .analysis/automation-audit/wave28-execution-2026-02-25/wave28_cleanup_execution_postdeploy.md
- .analysis/automation-audit/wave29-execution-2026-02-25/wave29_cleanup_execution_postdeploy.md
- .analysis/automation-audit/wave30-execution-2026-02-25/wave30_cleanup_execution_postdeploy.md
- .analysis/automation-audit/wave31-execution-2026-02-25/wave31_cleanup_execution_postdeploy.md
- .analysis/automation-audit/wave31-execution-2026-02-25/wave31b_cleanup_execution_postdeploy.md
- .analysis/automation-audit/wave32-execution-2026-02-25/wave32_cleanup_execution_postdeploy.md
- .analysis/automation-audit/wave34-execution-2026-02-26/wave34_cleanup_execution_postdeploy.md
- .analysis/automation-audit/wave35-execution-2026-02-26/wave35_cleanup_execution_postdeploy.md
- .analysis/automation-audit/wave36-execution-2026-02-26/wave36_cleanup_execution_postdeploy.md
- .analysis/automation-audit/wave27-execution-2026-02-25/onboardv2_flscheckutil_dependents.csv
- .analysis/automation-audit/wave19-execution-2026-02-25/apex_class_usage_matrix.tsv
- .analysis/automation-audit/wave19-execution-2026-02-25/candidates_test_only.tsv
- .analysis/automation-audit/wave19-execution-2026-02-25/candidates_meta_only.tsv
- .analysis/automation-audit/wave19-execution-2026-02-25/flow_reference_guardrail.tsv
