@isTest
private class OnboardingStatusRulesEngineCntlrTest {
  @testSetup
  static void setupTestData() {
    // Create test account
    Account testAccount = TestDataFactory.createAccount('Test Account', true);

    // Create test vendor
    Vendor__c testVendor = TestDataFactory.createVendor(true);
    testVendor.Active__c = true;
    update testVendor;

    // Create test vendor customization/program
    Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
      testVendor,
      'Active',
      true,
      null,
      true
    );

    // Create test onboarding
    Onboarding__c testOnboarding = TestDataFactory.createOnboarding(
      testAccount,
      testProgram,
      true
    );
    List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
      Onboarding__c.SObjectType,
      'Onboarding_Status__c'
    );
    String inProcessStatus = validStatuses.contains('In Process')
      ? 'In Process'
      : validStatuses[0];
    testOnboarding.Onboarding_Status__c = inProcessStatus;
    update testOnboarding;

    // Create requirement group
    Vendor_Program_Requirement_Group__c requirementGroup = TestVendorProgramRequirementGroupFactory.create(
      true,
      'Test Requirement Group'
    );

    // Create vendor program group
    Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(
      true,
      'Test Group',
      requirementGroup,
      null
    );

    // Create group member
    Vendor_Program_Group_Member__c groupMember = TestVendorProgramGroupMemberFactory.create(
      true,
      vendorProgramGroup,
      testProgram,
      null,
      true
    );

    // Create rules engine
    Onboarding_Status_Rules_Engine__c statusRulesEngineRecord = TestOnboardingRulesEngineFactory.create(
      true,
      requirementGroup,
      vendorProgramGroup,
      'ALL',
      null,
      inProcessStatus
    );

    // Create vendor program requirement
    Vendor_Program_Requirement__c requirement = TestDataFactory.createVendorProgramRequirement(
      testProgram,
      true,
      true
    );

    // Create onboarding requirement
    Onboarding_Requirement__c onboardingRequirement = TestOnboardingRequirementFactory.create(
      true,
      testOnboarding,
      requirement
    );
    List<String> requirementStatuses = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Requirement__c.SObjectType,
      'Status__c'
    );
    String completeStatus = requirementStatuses.contains('Complete')
      ? 'Complete'
      : (requirementStatuses.contains('Completed')
          ? 'Completed'
          : (requirementStatuses.isEmpty() ? null : requirementStatuses[0]));
    if (String.isNotBlank(completeStatus)) {
      onboardingRequirement.Status__c = completeStatus;
      update onboardingRequirement;
    }

    // Create status rule
    String expectedStatus = String.isNotBlank(completeStatus)
      ? completeStatus
      : TestDataFactoryUtil.getFirstPicklistValue(
          Onboarding_Status_Rule__c.SObjectType,
          'Expected_Status__c'
        );
    Onboarding_Status_Rule__c onboardingStatusRule = TestOnboardingRulesFactory.create(
      true,
      statusRulesEngineRecord,
      requirement,
      expectedStatus,
      1
    );
  }

  @isTest
  static void testGetVendorProgramGroups() {
    Test.startTest();
    List<Map<String, String>> results = OnboardingStatusRulesEngineController.getVendorProgramGroups();
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    System.assert(!results.isEmpty(), 'Should return vendor program groups');
    System.assert(results[0].containsKey('value'), 'Should have value key');
    System.assert(results[0].containsKey('label'), 'Should have label key');
  }

  @isTest
  static void testGetRequirementGroups() {
    Test.startTest();
    List<Map<String, String>> results = OnboardingStatusRulesEngineController.getRequirementGroups();
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    System.assert(!results.isEmpty(), 'Should return requirement groups');
    System.assert(results[0].containsKey('value'), 'Should have value key');
    System.assert(results[0].containsKey('label'), 'Should have label key');
  }

  @isTest
  static void testGetRules() {
    Vendor_Program_Group__c vendorProgramGroup = [
      SELECT Id
      FROM Vendor_Program_Group__c
      LIMIT 1
    ];
    Vendor_Program_Requirement_Group__c requirementGroup = [
      SELECT Id
      FROM Vendor_Program_Requirement_Group__c
      LIMIT 1
    ];

    Test.startTest();
    List<Onboarding_Status_Rules_Engine__c> results = OnboardingStatusRulesEngineController.getRules(
      vendorProgramGroup.Id,
      requirementGroup.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testGetOnboardingOptions() {
    Test.startTest();
    List<Map<String, String>> results = OnboardingStatusRulesEngineController.getOnboardingOptions(
      50
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    System.assert(results.size() <= 50, 'Should respect limit');
    if (!results.isEmpty()) {
      System.assert(results[0].containsKey('value'), 'Should have value key');
      System.assert(results[0].containsKey('label'), 'Should have label key');
    }
  }

  @isTest
  static void testGetOnboardingOptionsWithDefaultLimit() {
    Test.startTest();
    List<Map<String, String>> results = OnboardingStatusRulesEngineController.getOnboardingOptions(
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    System.assert(results.size() <= 50, 'Should default to 50 limit');
  }

  @isTest
  static void testPreviewStatusEvaluation() {
    Onboarding__c testOnboarding = [SELECT Id FROM Onboarding__c LIMIT 1];

    Test.startTest();
    List<StatusEvaluationTraceDTO> results = OnboardingStatusRulesEngineController.previewStatusEvaluation(
      testOnboarding.Id,
      null,
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    // Should return trace data or empty list
  }

  @isTest
  static void testPreviewStatusEvaluationWithNoOnboarding() {
    Test.startTest();
    try {
      List<StatusEvaluationTraceDTO> results = OnboardingStatusRulesEngineController.previewStatusEvaluation(
        null,
        null,
        null
      );
      // If no exception thrown, results should be empty or null
      System.assert(
        results == null || results.isEmpty(),
        'Should return empty or null for invalid input'
      );
    } catch (Exception ex) {
      // ValidationHelper.requireId should throw exception for null
      System.assert(
        ex instanceof AuraHandledException ||
          ex.getMessage().contains('Onboarding ID') ||
          ex.getMessage().contains('required') ||
          ex.getMessage().contains('Script-thrown'),
        'Should throw validation error for null ID'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testPreviewStatusEvaluationWithExternalOverride() {
    Onboarding__c testOnboarding = [SELECT Id FROM Onboarding__c LIMIT 1];
    testOnboarding.External_Override_Enabled__c = true;
    update testOnboarding;

    Test.startTest();
    List<StatusEvaluationTraceDTO> results = OnboardingStatusRulesEngineController.previewStatusEvaluation(
      testOnboarding.Id,
      null,
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    if (!results.isEmpty()) {
      System.assertNotEquals(
        null,
        results[0].shortCircuitReason,
        'Should have short circuit reason'
      );
      System.assert(
        results[0].shortCircuitReason.contains('External Override'),
        'Should indicate external override'
      );
    }
  }

  @isTest
  static void testPreviewStatusEvaluationWithSpecificRulesEngines() {
    Onboarding__c testOnboarding = [SELECT Id FROM Onboarding__c LIMIT 1];
    Onboarding_Status_Rules_Engine__c statusRulesEngineRecord = [
      SELECT Id
      FROM Onboarding_Status_Rules_Engine__c
      LIMIT 1
    ];

    Test.startTest();
    List<StatusEvaluationTraceDTO> results = OnboardingStatusRulesEngineController.previewStatusEvaluation(
      testOnboarding.Id,
      null,
      new List<Id>{ statusRulesEngineRecord.Id }
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testSaveRules() {
    Onboarding_Status_Rules_Engine__c statusRulesEngineRecord = [
      SELECT Id
      FROM Onboarding_Status_Rules_Engine__c
      LIMIT 1
    ];
    List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
      Onboarding__c.SObjectType,
      'Onboarding_Status__c'
    );
    String targetStatus = validStatuses.contains('Approved')
      ? 'Approved'
      : validStatuses[0];

    statusRulesEngineRecord.Target_Onboarding_Status__c = targetStatus;

    Test.startTest();
    OnboardingStatusRulesEngineController.saveRules(
      new List<Onboarding_Status_Rules_Engine__c>{ statusRulesEngineRecord }
    );
    Test.stopTest();

    // Verify update
    Onboarding_Status_Rules_Engine__c updatedRulesEngine = [
      SELECT Id, Target_Onboarding_Status__c
      FROM Onboarding_Status_Rules_Engine__c
      WHERE Id = :statusRulesEngineRecord.Id
    ];
    System.assertEquals(
      targetStatus,
      updatedRulesEngine.Target_Onboarding_Status__c,
      'Status should be updated'
    );
  }
}
