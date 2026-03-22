# Test Classes and Commands

This document lists test classes present in this repo and provides commands to run them.

## Apex Test Classes (in repo)

### Services & Invocables
- `VendorOnboardingServiceTest`
- `VendorOnboardingJsonAdapterTest`
- `OnboardingDefaultVendorProgramInvocTest`
- `OnboardingStatusEvaluatorTest`
- `OnboardingInvocablesTest`
- `OnbReqSubjectInvocableTest`
- `RecordCollectionEditorConfigServiceTest`
- `RecordCollectionEditorAsyncServiceTest`
- `ExpOppCreateAsyncServiceTest`
- `FlowAdminGuardServiceTest`

### Follow-Up & Messaging
- `FollowUpDetectionServiceTest`
- `FollowUpExecutionServiceTest`
- `FollowUpFatigueServiceTest`
- `FollowUpProcessorTest`
- `FollowUpProcessorSchedulerTest`
- `FollowUpProcessorBatchSchedulerTest`
- `TwilioSMSProviderTest`
- `TwilioSettingsControllerTest`

### Email & Sync
- `EmailTemplateSyncServiceTest`
- `EmailTemplateSyncOrchestratorTest`
- `EmailCommTerritoryRoleHelperTest`

### Other
- `LeadAssignmentServiceTest`
- `ZipCodeTerritoryAssignmentTest`

### Test Factories (for test data)
- `TestAVOFactory`, `TestAccountFactory`, `TestOnboardingFactory`, `TestOnboardingRequirementFactory`
- `TestVendorFactory`, `TestVendorProgramFactory`, `TestVendorProgramGroupFactory`, etc.

## Commands to Run Tests

### Run All Apex Tests

```bash
./scripts/deploy/run-tests.sh myorg
```

### Run Specific Test Classes

```bash
sf apex run test --class-names "VendorOnboardingServiceTest,OnboardingDefaultVendorProgramInvocTest" --target-org myorg --result-format human --code-coverage --wait 10
```

### Run Jest Tests (LWC)

```bash
npm run test:unit
npm run test:unit:coverage
```

## Notes

- Apex tests require an authenticated Salesforce org
- Jest tests run locally and don't require a Salesforce org
