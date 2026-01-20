# Building and Testing the Onboarding Console Experience

This guide provides instructions for testing and building the Onboarding Console v1 experience that has been implemented so far.

## Prerequisites

Before beginning, ensure you have:

- A Salesforce DX scratch org or sandbox with the OnboardingV2 package deployed
- Salesforce CLI (sf) installed and authenticated
- Node.js and npm installed
- The project cloned and configured locally

## Testing Approach

### 1. Apex Tests

The project includes comprehensive Apex tests that cover core functionality:

#### Running All Apex Tests

```bash
# Run all tests in your org
./scripts/deploy/run-tests.sh myorg
```

#### Running Specific Test Classes

```bash
# Run specific test classes
./scripts/deploy/run-tests.sh myorg "OnboardingReqDueDateControllerTest,OnboardingReqPanelControllerTest"
```

#### Test Coverage Requirements

- All Apex classes must maintain ≥ 75% code coverage
- Tests should include both positive and negative test cases
- Use `Test.startTest()` and `Test.stopTest()` for governor limit testing

### 2. LWC Jest Tests

The Lightning Web Components include Jest tests for unit testing:

#### Running All LWC Tests

```bash
# Run all Jest tests
npm test
```

#### Running Specific LWC Tests

```bash
# Run specific component tests
npm test -- --testPathPattern=progressHeader
```

#### Watching Tests During Development

```bash
# Watch tests during development
npm run test:unit:watch
```

#### Generating Coverage Reports

```bash
# Generate coverage report
npm run test:unit:coverage
```

## Building the Experience

### 1. Deploy Metadata

To deploy the current implementation to your org:

```bash
# Deploy to your org
sf project deploy start --target-org myorg
```

### 2. Verify Component Dependencies

Ensure all required components are deployed:

- Apex controllers: `OnboardingRequirementsPanelController`, `OnboardingRequirementDueDateController`
- LWC components: `progressHeader`, `requirementChecklist`, `requirementFormPanel`, `nextBestActionsPanel`, `repDealerQueue`, `programSetupWizardContainer`
- Required objects: `Onboarding_Requirement__c`, `Onboarding__c`, `Vendor_Program__c`

### 3. Test Key Functionality

#### Test Dealer Experience

1. Navigate to the Experience Cloud site
2. Verify the Onboarding Console page loads correctly
3. Check that:
   - Progress header displays correctly
   - Requirement checklist renders properly
   - Next best actions panel shows relevant information
   - Requirement form panel can be opened

#### Test Onboarding Rep Functions

1. Access the Onboarding Rep Lightning App
2. Verify the Dealer Queue displays properly
3. Test the due date override functionality using the new controller

#### Test Program Manager Functions

1. Access the Program Manager Lightning App
2. Verify the Program Setup Wizard Container works
3. Test the validation flow

## Component-Specific Testing

### requirementChecklist Component

- Test with valid onboarding ID
- Verify data is fetched via `OnboardingRequirementsPanelController.getRequirements()`
- Validate rendering of stages and requirements
- Test "Open Form" action functionality

### requirementFormPanel Component

- Test with valid requirement ID
- Verify integration with `lightning-record-edit-form`
- Test success callback to refresh checklist

### nextBestActionsPanel Component

- Test with valid onboarding ID
- Verify data fetching from Apex services
- Validate display of actionable next steps

### repDealerQueue Component

- Test with valid user ID
- Verify dealer list display
- Test row actions for due date overrides

### programSetupWizardContainer Component

- Test with valid program ID
- Verify wizard flow navigation
- Test validation summary panel

## Troubleshooting Common Issues

### 1. Component Not Loading

- Check that all Apex methods referenced in components exist
- Verify component metadata files don't have invalid attributes
- Confirm required permission sets are assigned

### 2. Test Failures

- Ensure test data factories create proper records
- Verify test classes use `@TestSetup` appropriately
- Check for proper exception handling in test methods

### 3. Deployment Errors

- Review the error logs for specific component issues
- Ensure all referenced Apex classes are deployed
- Verify field-level security settings for required fields

## Quality Gates

Before considering the implementation complete:

1. ✅ All Apex tests pass with ≥ 75% coverage
2. ✅ All LWC Jest tests pass
3. ✅ All components deploy without errors
4. ✅ Experience Cloud page loads correctly
5. ✅ All key user journeys work as expected
6. ✅ No hardcoded IDs or URLs in production code
7. ✅ No System.debug statements in production code
8. ✅ All security requirements met (with sharing, USER_MODE queries)

## Next Steps

Once the basic functionality is verified:

1. Enhance placeholder implementations with proper business logic
2. Add comprehensive Jest tests for all LWC components
3. Implement proper error handling and user feedback
4. Add accessibility features to meet WCAG standards
5. Optimize performance for large datasets
6. Add comprehensive documentation for all components
