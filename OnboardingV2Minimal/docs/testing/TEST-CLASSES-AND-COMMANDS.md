# Test Classes and Commands

This document lists all test classes in the OnboardingV2 project and provides commands to run them.

## Test Summary

- **Apex Test Classes**: 100 test classes
- **Jest Test Files (LWC)**: 16 test files
- **Total Tests**: 141 Jest tests + ~100+ Apex test methods

## Apex Test Classes (100 classes)

### Main Package Test Classes

#### Controllers

- `OnboardingAppActivationControllerTest` - Tests `OnboardingAppActivationService` (controller consolidated into service)
- `OnboardingAppECCControllerTest` - Tests `OnboardingAppECCService` (controller consolidated into service)
- `OnboardingAppVendorProgramReqCtlrTest` - Tests `OnboardingAppVendorProgramReqSvc` (controller consolidated into service)
- `OnboardingRequirementsPanelCtlrTest`
- `OnboardingStatusRuleControllerTest`
- `OnboardingStatusRulesEngineCtlrTest`
- `OrgWideEmailSyncControllerTest`
- `VendorOnboardingWizardControllerTest`
- `EmailTemplateSyncControllerTest`

#### Services

- `VendorOnboardingWizardServiceTest` - **Removed** (facade service eliminated, tests moved to domain service tests)
- `OnboardingAppECCServiceTest`
- `VendorDomainServiceTest` - Tests consolidated Vendor/VendorProgram/VendorProgramGroup operations
- `RequirementDomainServiceTest` - Tests consolidated Requirement/RequirementGroup operations
- `CommunicationDomainServiceTest` - Tests consolidated CommunicationTemplate/RecipientGroup operations
- `OnboardingEligibilityServiceTest`
- `OnboardingRulesServiceTest`
- `EmailTemplateSyncServiceTest`

#### Repositories

- `OnboardingRepositoryTest`
- `OnboardingRulesRepositoryTest`
- `OnboardingAppVendorProgramReqRepoTest`
- `OnboardingAppECCRepositoryTest`
- `OnboardingAppActivationRepositoryTest`
- `OrgWideEmailRepositoryTest`
- `OrgWideEmailCMDTRepositoryTest`
- `EmailCatalogCMDTRepositoryTest`
- `CommunicationTemplateRepositoryTest`
- `EmailTemplateRepositoryTest`
- `EmailAttachmentRepositoryTest`
- `VendorOnboardingWizardRepositoryTest`

#### Handlers

- `VersioningTriggerHandlerTest`
- `VendorProgramTriggerHandlerTest`
- `VendorProgramReqGroupTriggerHandlerTest`
- `OnboardingAppVendorProgramReqHdlrTest`

#### Orchestrators

- `OrgWideEmailSyncOrchestratorTest`
- `EmailTemplateSyncOrchestratorTest`
- `RecipientGroupEmailOrchestratorTest`
- `OnboardingAppActivationOrchestratorTest`
- `OnboardingAppVendorProgramReqOrchTest`

#### Actions

- `OnboardingAppActivationActionTest`
- `RecipientGroupEmailActionTest`
- `EmailTemplateSyncFlowActionTest`

#### Jobs

- `EmailCommTerritoryRoleSyncJobTest`

#### Helpers

- `EmailCommTerritoryRoleHelperTest`
- `UtilitiesSyncLogHelperTest`

#### Resolvers

- `RecipientGroupResolverTest`

#### Rules

- `OnlyOneActiveRecGrpPerPrgrmRuleTest`
- `RequireParentVersionOnActivationRuleTest`
- `RecipientAndProgramMustBeActiveRuleTest`
- `PreventDupRecGrpAssignmentRuleTest`

#### DTOs

- `OrgWideEmailDTOTest`

#### Test Directory Classes

- `FollowUpDetectionServiceTest`
- `FollowUpProcessorTest`
- `FollowUpExecutionServiceTest`
- `FollowUpProcessorSchedulerTest`
- `FollowUpProcessorBatchSchedulerTest`
- `FollowUpFatigueServiceTest`
- `OnboardingStageDependencyServiceTest`
- `OnboardingStageDependencyControllerTest`
- `OnboardingDashboardFilterServiceTest`
- `OnboardingBlockingDetectionServiceTest`
- `OnboardingHealthServiceTest`
- `OnboardingAccessServiceTest`
- `OnboardingExternalOverrideServiceTest`
- `OnboardingPrimaryContactTest`
- `OnboardingRequirementTriggerHandlerTest`
- `RequirementFieldExternalValidatorTest`
- `RequirementFieldAsyncValidatorTest`
- `RequirementFieldValueTriggerHandlerTest`
- `RequirementFieldValueControllerTest`
- `RequirementFieldValueRepositoryTest`
- `AVOTriggerHandlerTest`
- `TwilioSettingsControllerTest`
- `TwilioSMSProviderTest`

### Unpackaged Test Classes

- `ContactECCControllerTest`
- `OnboardingOrderControllerTest`
- `VendorFilterControllerTest`
- `VendorOnboardingControllerTest`
- `VendorOnboardingFlowAdapterTest`
- `VendorOnboardingJsonAdapterTest`
- `VendorOnboardingLWCAdapterTest`
- `VendorOnboardingServiceTest`
- `VendorPrerequisiteEvaluatorTest`
- `VendorProgramGrpMmbrTrgHndlrTest`
- `RepOnBoardingControllerTest`

## Jest Test Files (LWC Components) - 16 files

1. `onboardingAppVendorProgramECCManager.test.js`
2. `onboardingFlowEngine.test.js`
3. `onboardingRequirementsPanel.test.js`
4. `onboardingStageRenderer.test.js`
5. `onboardingStatusRulesEngine.test.js`
6. `onboardingStatusRulesManager.test.js`
7. `onboardingWorkQueue.test.js`
8. `messagingIssuesPanel.test.js`
9. `onboardingRuleModal.test.js`
10. `requirementConditionsList.test.js`
11. `twilioSettings.test.js`
12. `vendorProgramOnboardingCommunicationTemplate.test.js`
13. `vendorProgramOnboardingStatusRuleBuilder.test.js`
14. `vendorProgramOnboardingStatusRulesEngine.test.js`
15. `vendorProgramOnboardingVendorProgramRequirements.test.js`
16. `vendorProgramOnboardingFlow.test.js`

## Commands to Run Tests

### Run All Jest Tests (LWC Components)

```bash
# Run all Jest tests
npm run test:unit

# Run with coverage report
npm run test:unit:coverage

# Run in watch mode (auto-rerun on file changes)
npm run test:unit:watch

# Run in debug mode
npm run test:unit:debug
```

### Run All Apex Tests

#### Option 1: Using the provided script (Recommended)

```bash
# Run all Apex tests in default org
./scripts/deploy/run-tests.sh

# Run all Apex tests in specific org
./scripts/deploy/run-tests.sh myorg

# Run specific test classes
./scripts/deploy/run-tests.sh myorg "OnboardingRulesServiceTest,OnboardingStatusEvaluatorTest"
```

#### Option 2: Using Salesforce CLI directly

```bash
# Run all Apex tests
sf apex run test --target-org myorg --result-format human --code-coverage --wait 10

# Run all tests with JUnit output
sf apex run test --target-org myorg --result-format junit --code-coverage --wait 10 --output-dir test-results

# Run specific test classes
sf apex run test --class-names "OnboardingRulesServiceTest,OnboardingStatusEvaluatorTest" --target-org myorg --result-format human --code-coverage --wait 10

# Run tests and get detailed coverage
sf apex run test --target-org myorg --result-format human --code-coverage --wait 10 --detailed-coverage
```

#### Option 3: Using VS Code Salesforce Extension

1. Open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)
2. Type: "SFDX: Run Apex Tests"
3. Select "Run All Tests" or specific test classes

### Run Both Jest and Apex Tests

```bash
# Run Jest tests first
npm run test:unit

# Then run Apex tests
./scripts/deploy/run-tests.sh myorg
```

Or create a combined script:

```bash
#!/bin/bash
echo "Running Jest tests..."
npm run test:unit
echo ""
echo "Running Apex tests..."
./scripts/deploy/run-tests.sh myorg
```

## Test Coverage Goals

- **Apex Tests**: ≥75% coverage (Current: 78% ✅)
- **Jest Tests (LWC)**: ≥80% coverage for critical components
- **All Tests**: 100% pass rate

## Test Results Location

- **Jest Results**: Console output + coverage reports in `coverage/` directory
- **Apex Results**:
  - Console output
  - JUnit XML files in `test-results/` directory
  - Coverage shown in console and Salesforce org

## Quick Reference

### Most Common Commands

```bash
# Run all Jest tests
npm test

# Run Jest tests with coverage
npm run test:unit:coverage

# Run all Apex tests
sf apex run test --target-org myorg --code-coverage

# Run Apex tests using script
./scripts/deploy/run-tests.sh myorg
```

### Check Test Status

```bash
# Check Jest test status
npm run test:unit 2>&1 | grep -E "(PASS|FAIL|Test Suites:|Tests:)"

# Check Apex test results
sf apex get test --target-org myorg --test-run-id <test-run-id>
```

## Notes

- Jest tests run locally and don't require a Salesforce org
- Apex tests require an authenticated Salesforce org
- Apex tests count toward Salesforce deployment requirements
- Jest tests are for development-time testing only
