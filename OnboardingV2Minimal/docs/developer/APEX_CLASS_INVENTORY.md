# Apex Class Inventory

Use this file to find classes quickly.  
If you are new, read [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) first so the class list has context.

## Summary

- Total classes: 103
- Annotated test classes (`@isTest` or legacy `testMethod`): 39
- Name-pattern test/support classes (`*Test` or `Test*`): 57
- Non-test classes (excluding `*Test` / `Test*`): 46
- Test classes with `*Test` suffix: 28
- Classes prefixed with `Test`: 29
- Test support classes (prefixed with `Test` but not `@isTest`): 2
- Classes named `*Invocable*` / `*Invocables*`: 19
- Classes named `*Service*`: 25
- Classes named `*Controller*`: 1
- Interface classes: 1
- Queueable implementations: 3

## Class Responsibilities

> Responsibilities are derived from class-level comments when present; otherwise from class naming and role patterns.

| Class | Type | Responsibility |
|---|---|---|
| `CommunicationTemplateBulkSendAction.cls` | Production | Core onboarding domain class supporting business automation. |
| `CommunicationTemplateBulkSendActionTest.cls` | Test | Unit tests for Communication Template Bulk Send Action. |
| `EmailTemplateSyncJob.cls` | Production | Core onboarding domain class supporting business automation. |
| `EmailTemplateSyncOrchestrator.cls` | Production | Core onboarding domain class supporting business automation. |
| `EmailTemplateSyncOrchestratorTest.cls` | Test | Unit tests for Email Template Sync Orchestrator. |
| `EmailTemplateSyncService.cls` | Production | Service-layer logic for Email Template Sync. |
| `EmailTemplateSyncServiceTest.cls` | Test | Unit tests for Email Template Sync Service. |
| `ExceptionUtil.cls` | Production | Custom exception class for onboarding domain logic. |
| `ExceptionUtilTest.cls` | Test | Unit tests for Exception Util. |
| `ExpOppCreateAsyncServiceTest.cls` | Test | Unit tests for Exp Opp Create Async Service. |
| `ExpOpportunityCreateAsyncService.cls` | Production | Service-layer logic for Experience Opportunity Create Async. |
| `ExpOpportunityCreateRecord.cls` | Production | LWC facade for EXP opportunity create flow: loads BRE-gated context, saves contacts/ACR updates, and submits the async create chain payload. |
| `ExpOpportunityCreateRecordTest.cls` | Test | Unit tests for Exp Opportunity Create Record facade. |
| `FlowAdminGuardService.cls` | Production | Service-layer logic for Flow Admin Guard. |
| `FlowAdminGuardServiceTest.cls` | Test | Unit tests for Flow Admin Guard Service. |
| `OnboardingStatusRulesEngineInterface.cls` | Production | Pluggable rule engine contract for onboarding status evaluation (first matching CMDT row wins). |
| `LeadAssignmentServiceTest.cls` | Test | Unit tests for Lead Assignment Service. |
| `LoggingUtil.cls` | Production | Lightweight logging helper to centralize debug formatting. |
| `LoggingUtilTest.cls` | Test | Unit tests for Logging Util. |
| `ObjectRelatedListController.cls` | Production | Object Related List Controller |
| `ObjectRelatedListCtrlTest.cls` | Test | Unit tests for Object Related List Ctrl. |
| `OnbReqContractEvidenceInvocable.cls` | Production | Flow-invocable entry point for Onb Req Contract Evidence workflows. |
| `OnbReqContractEvidenceInvocableTest.cls` | Test | Unit tests for Onb Req Contract Evidence Invocable. |
| `OnbReqParentBulkEvalInvocable.cls` | Production | Flow-invocable entry point for Onb Req Parent Bulk Eval workflows. |
| `OnbReqParentBulkEvalInvocableTest.cls` | Test | Unit tests for Onb Req Parent Bulk Eval Invocable. |
| `OnbReqSubjectInvocableTest.cls` | Test | Unit tests for Onb Req Subject Invocable. |
| `OnboardingChainTailQueueable.cls` | Production | Runs DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record outside the screen-flow interview to shorten user-visible wait. |
| `OnboardingBackgroundRetryScheduler.cls` | Production | Scheduled processor for `Onboarding_Background_Job__c` retry records (every 10 minutes). |
| `OnboardingBackgroundRetryService.cls` | Production | Durable onboarding background fault replay service: captures idempotent retry jobs, executes replay chain, and manages backoff/dead-letter status. |
| `OnboardingBackgroundRetryServiceTest.cls` | Test | Unit tests for Onboarding Background Retry Service. |
| `OnboardingBackgroundRetryWorker.cls` | Production | Queueable worker that processes due onboarding background retry jobs. |
| `OnboardingDefaultVendorProgramInvocTest.cls` | Test | Test for OnboardingDefaultVendorProgramInvocable. |
| `OnboardingDefaultVendorProgramInvocable.cls` | Production | Invocable action to resolve the default Vendor Program for a flow scenario (e.g., REQUIRE_NDA). |
| `OnboardingDomainException.cls` | Production | Custom exception class for onboarding domain logic. |
| `OnboardingEnqueueOnboardingTailInvocable.cls` | Production | Enqueues asynchronous run of DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record with freshly queried inputs. |
| `OnboardingEnqueueOnboardingTailRequest.cls` | Production | Request DTO used by Onboarding Enqueue Onboarding Tail. |
| `OnboardingEnqueueOnboardingTailResponse.cls` | Production | Response DTO used by Onboarding Enqueue Onboarding Tail. |
| `OnboardingErrorLogInvocable.cls` | Production | Flow entry: inserts `Error_Log__c` and queues idempotent onboarding background retry jobs when onboarding context is present. |
| `OnboardingErrorLogInvocableTest.cls` | Test | Unit tests for Onboarding Error Log Invocable. |
| `OnboardingErrorLogService.cls` | Production | Persists categorized rows to Error_Log__c for onboarding automation diagnostics. |
| `OnboardingErrorLogServiceTest.cls` | Test | Unit tests for Onboarding Error Log Service. |
| `OnboardingInvocables.cls` | Production | Collection of Flow-invocable methods for Onboarding. |
| `OnboardingInvocablesTest.cls` | Test | Unit tests for Onboarding Invocables. |
| `OnboardingNextStepRuleInvocable.cls` | Production | Invoked from BLL_Onboarding_RCD_Logical_Process after the Setup Complete BRE gate (dispatch allowed or blocked) |
| `OnboardingNextStepRuleInvocableTest.cls` | Test | Unit tests for Onboarding Next Step Rule Invocable. |
| `OnboardingNextStepRuleService.cls` | Production | Evaluates active Onboarding_Next_Step_Rule__mdt when onboarding reaches Setup Complete. |
| `OnboardingPerformanceRoutingInvocable.cls` | Production | Exposes Onboarding_Performance_Config__mdt flags to Flow (decisions and branching). |
| `OnboardingPerformanceRoutingRequest.cls` | Production | Request DTO used by Onboarding Performance Routing. |
| `OnboardingPerformanceRoutingResponse.cls` | Production | Response DTO used by Onboarding Performance Routing. |
| `OnboardingPerformanceSettings.cls` | Production | Cached access to Onboarding_Performance_Config__mdt (Default record). |
| `OnboardingRecordBREGateInvocable.cls` | Production | Runs BLL_BRE_Evaluate_Business_Rules in a try/catch so failures do not roll back |
| `OnboardingRecordBREGateInvocableTest.cls` | Test | Unit tests for Onboarding Record BREGate Invocable. |
| `OnboardingRecordFlowSupport.cls` | Production | Shared helpers for Onboarding RCD: broad SOQL for records passed into nested autolaunched flows.  |
| `OnboardingRecordFlowSupportTest.cls` | Test | Unit tests for Onboarding Record Flow Support. |
| `OnboardingRequirementSubjectInvocable.cls` | Production | Flow-invocable entry point for Onboarding Requirement Subject workflows. |
| `OnboardingRequirementVPRGateInvocable.cls` | Production | Flow entry: returns Vendor_Program_Requirement__c rows to materialize on this pass (idempotent, sequence-ordered).  |
| `OnboardingRequirementVPRGateService.cls` | Production | Filters Vendor_Program_Requirement__c rows for onboarding requirement creation: idempotent skip of |
| `OnboardingRequirementVPRGateServiceTest.cls` | Test | Unit tests for Onboarding Requirement VPRGate Service. |
| `OnboardingStatusCmdtRuleEngine.cls` | Production | CMDT-driven rule engine: Predicate_Config__c JSON via OnboardingStatusPredicateInterpreter. |
| `OnboardingStatusEvaluatorInvocable.cls` | Production | Invocable action to evaluate and optionally apply Onboarding Status based on CMDT rules. |
| `OnboardingStatusEvaluatorService.cls` | Production | Orchestrates onboarding status evaluation: loads context, applies normalization (CMDT).  |
| `OnboardingStatusEvaluatorTest.cls` | Test | Test class for OnboardingStatusEvaluatorService and OnboardingStatusEvaluatorInvocable. |
| `OnboardingStatusNormalizationService.cls` | Production | Loads and applies Onboarding_Status_Normalization__mdt. Single source for status normalization in the evaluator path. |
| `OnboardingStatusPredicateInterpreter.cls` | Production | Evaluates Onboarding_Status_Evaluation_Rule__mdt.Predicate_Config__c (JSON) against EvaluationContext. |
| `PicklistHelper.cls` | Production | Utility class for retrieving picklist values |
| `RecordCollectionEditorAsyncService.cls` | Production | Service-layer logic for Record Collection Editor Async. |
| `RecordCollectionEditorAsyncServiceTest.cls` | Test | Unit tests for Record Collection Editor Async Service. |
| `RecordCollectionEditorConfigService.cls` | Production | Service-layer logic for Record Collection Editor Config. |
| `RecordCollectionEditorConfigServiceTest.cls` | Test | Unit tests for Record Collection Editor Config Service. |
| `RecordCollectionEditorGetRecordsService.cls` | Production | Service-layer logic for Record Collection Editor Get Records. |
| `RecordCollectionEditorGetRecordsTest.cls` | Test | Unit tests for Record Collection Editor Get Records. |
| `RelatedOnboardingReqFlowTest.cls` | Test | Unit tests for Related Onboarding Req Flow. |
| `TestAVOFactory.cls` | Test | Test data factory for AVO records. |
| `TestAccountFactory.cls` | Test | Test data factory for Account records. |
| `TestCommTemplateFactory.cls` | Test | Test data factory for Comm Template records. |
| `TestContactFactory.cls` | Test | Test data factory for Contact records. |
| `TestCredentialFactory.cls` | Test | Test data factory for Credential records. |
| `TestDataFactory.cls` | Test | Centralized test data factory for onboarding-related objects. |
| `TestDataFactoryUtil.cls` | Test Support | Utility class for test data factories. |
| `TestDataFactoryWrapper.cls` | Test Support | Wrapper DTOs used by test factories. |
| `TestECCFactory.cls` | Test | Test data factory for ECC records. |
| `TestOnboardingFactory.cls` | Test | Test data factory for Onboarding records. |
| `TestOnboardingRequirementFactory.cls` | Test | Test data factory for Onboarding Requirement records. |
| `TestPermissionFactory.cls` | Test | Test data factory for Permission records. |
| `TestProductFactory.cls` | Test | Test data factory for Product records. |
| `TestRequiredCredentialFactory.cls` | Test | Test data factory for Required Credential records. |
| `TestServiceResourceFactory.cls` | Test | Test data factory for Service Resource records. |
| `TestServiceTerritoryFactory.cls` | Test | Test data factory for Service Territory records. |
| `TestServiceTerritoryMemberFactory.cls` | Test | Test data factory for Service Territory Member records. |
| `TestTechnicianFactory.cls` | Test | Test data factory for Technician records. |
| `TestTerritoryFactory.cls` | Test | Test data factory for Territory records. |
| `TestTrainingRequirementFactory.cls` | Test | Test data factory for Training Requirement records. |
| `TestTrainingSystemFactory.cls` | Test | Test data factory for Training System records. |
| `TestUserFactory.cls` | Test | Test data factory for User records. |
| `TestVendorFactory.cls` | Test | Test data factory for Vendor records. |
| `TestVendorProgramFactory.cls` | Test | Test data factory for Vendor Program records. |
| `TestVendorProgramGroupFactory.cls` | Test | Test data factory for Vendor Program Group records. |
| `TestVendorProgramGroupMemberFactory.cls` | Test | Test data factory for Vendor Program Group Member records. |
| `TestVendorProgramRequirementFactory.cls` | Test | Test data factory for Vendor Program Requirement records. |
| `TestWorkFactory.cls` | Test | Test data factory for Work records. |
| `TestWorkOrderFactory.cls` | Test | Test data factory for Work Order records. |
| `VendorOnboardingEligibilityRuleEngine.cls` | Production | Rule engine implementation for Vendor Onboarding Eligibility. |
| `VendorOnboardingJsonAdapter.cls` | Production | Adapter class for Vendor Onboarding Json integration/use-cases. |
| `VendorOnboardingJsonAdapterTest.cls` | Test | Unit tests for Vendor Onboarding Json Adapter. |
| `VendorOnboardingService.cls` | Production | Service for Vendor Onboarding operations |
| `VendorOnboardingServiceTest.cls` | Test | Unit tests for Vendor Onboarding Service. |
| `VendorPrerequisiteEvaluator.cls` | Production | Core onboarding domain class supporting business automation. |
| `VendorProgramSeedService.cls` | Production | Data seed for blank sandboxes / production gaps: vendors, Vendor_Customization__c, agreements, credentials.  |
| `ZipCodeTerritoryAssignmentTest.cls` | Test | Unit tests for Zip Code Territory Assignment. |
