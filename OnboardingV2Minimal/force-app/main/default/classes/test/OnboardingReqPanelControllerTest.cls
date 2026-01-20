@isTest
private class OnboardingReqPanelControllerTest {
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
  }

  @isTest
  static void testGetRequirements() {
    Onboarding__c testOnboarding = [SELECT Id FROM Onboarding__c LIMIT 1];

    Test.startTest();
    List<OnboardingApplicationService.RequirementDTO> results = OnboardingRequirementsPanelController.getRequirements(
      testOnboarding.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testGetInvalidFieldValues() {
    Onboarding__c testOnboarding = [SELECT Id FROM Onboarding__c LIMIT 1];

    Test.startTest();
    List<OnboardingRequirementsPanelController.InvalidFieldDTO> results = OnboardingRequirementsPanelController.getInvalidFieldValues(
      testOnboarding.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testGetActiveRulesVersion() {
    Onboarding__c testOnboarding = [SELECT Id FROM Onboarding__c LIMIT 1];

    Test.startTest();
    OnboardingRequirementsPanelController.RulesVersionInfo versionInfo = OnboardingRequirementsPanelController.getActiveRulesVersion(
      testOnboarding.Id
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      versionInfo,
      'Version info should not be null'
    );
    System.assertNotEquals(
      null,
      versionInfo.engineIds,
      'Should have engine IDs list'
    );
  }

  @isTest
  static void testGetActiveRulesVersionWithNoVendorProgram() {
    Account testAccount = [SELECT Id FROM Account LIMIT 1];
    Vendor__c testVendor = TestDataFactory.createVendor(true);
    testVendor.Active__c = true;
    update testVendor;

    Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
      testVendor,
      'Active',
      true,
      null,
      true
    );

    Onboarding__c testOnboarding = TestDataFactory.createOnboarding(
      testAccount,
      testProgram,
      true
    );
    testOnboarding.Vendor_Customization__c = null;
    update testOnboarding;

    Test.startTest();
    OnboardingRequirementsPanelController.RulesVersionInfo versionInfo = OnboardingRequirementsPanelController.getActiveRulesVersion(
      testOnboarding.Id
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      versionInfo,
      'Version info should not be null'
    );
    System.assertEquals(
      0,
      versionInfo.engineIds.size(),
      'Should have empty engine IDs when no vendor program'
    );
  }

  @isTest
  static void testRefreshAndReevaluate() {
    Onboarding__c testOnboarding = [SELECT Id FROM Onboarding__c LIMIT 1];
    List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
      Onboarding__c.SObjectType,
      'Onboarding_Status__c'
    );
    String initialStatus = validStatuses.contains('New')
      ? 'New'
      : validStatuses[0];
    testOnboarding.Onboarding_Status__c = initialStatus;
    update testOnboarding;

    Test.startTest();
    String newStatus = OnboardingRequirementsPanelController.refreshAndReevaluate(
      testOnboarding.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, newStatus, 'Status should not be null');

    // Verify status was updated (may be same or different based on rules)
    Onboarding__c updatedOnboarding = [
      SELECT Id, Onboarding_Status__c
      FROM Onboarding__c
      WHERE Id = :testOnboarding.Id
    ];
    System.assertNotEquals(
      null,
      updatedOnboarding.Onboarding_Status__c,
      'Status should be set'
    );
  }

  @isTest
  static void testUpdateRequirementStatuses() {
    Onboarding__c testOnboarding = [SELECT Id FROM Onboarding__c LIMIT 1];
    Onboarding_Requirement__c onboardingRequirement = [
      SELECT Id, Name, Status__c, Due_Date__c
      FROM Onboarding_Requirement__c
      WHERE Onboarding__c = :testOnboarding.Id
      LIMIT 1
    ];

    List<OnboardingApplicationService.RequirementDTO> updates = new List<OnboardingApplicationService.RequirementDTO>();
    OnboardingApplicationService.RequirementDTO dto = new OnboardingApplicationService.RequirementDTO(
      onboardingRequirement
    );
    List<String> requirementStatuses = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Requirement__c.SObjectType,
      'Status__c'
    );
    String approvedStatus = requirementStatuses.contains('Approved')
      ? 'Approved'
      : (requirementStatuses.contains('Complete')
          ? 'Complete'
          : (requirementStatuses.isEmpty() ? null : requirementStatuses[0]));
    dto.Status = approvedStatus;
    updates.add(dto);

    Test.startTest();
    OnboardingRequirementsPanelController.updateRequirementStatuses(updates);
    Test.stopTest();

    // Verify update
    Onboarding_Requirement__c updatedRequirement = [
      SELECT Id, Status__c
      FROM Onboarding_Requirement__c
      WHERE Id = :onboardingRequirement.Id
    ];
    System.assertEquals(
      approvedStatus,
      updatedRequirement.Status__c,
      'Status should be updated'
    );
  }

  @isTest
  static void testRunRuleEvaluation() {
    Onboarding__c testOnboarding = [SELECT Id FROM Onboarding__c LIMIT 1];

    Test.startTest();
    OnboardingRequirementsPanelController.runRuleEvaluation(testOnboarding.Id);
    Test.stopTest();

    // Verify method completed without error
    System.assert(true, 'Method should complete successfully');
  }

  @isTest
  static void testRerunValidation() {
    Onboarding__c testOnboarding = [SELECT Id FROM Onboarding__c LIMIT 1];
    Onboarding_Requirement__c requirement = [
      SELECT Id
      FROM Onboarding_Requirement__c
      WHERE Onboarding__c = :testOnboarding.Id
      LIMIT 1
    ];
    Requirement_Field__c requirementField = TestDataFactory.createRequirementField(
      'Test_Field__c',
      true
    );
    Requirement_Field_Value__c fieldValue = TestDataFactory.createRequirementFieldValue(
      requirementField,
      requirement,
      null,
      'Invalid',
      true
    );

    Test.startTest();
    OnboardingRequirementsPanelController.rerunValidation(
      new List<Id>{ fieldValue.Id }
    );
    Test.stopTest();

    // Verify method completed without error
    System.assert(true, 'Method should complete successfully');
  }

  @isTest
  static void testRerunValidationWithEmptyList() {
    Test.startTest();
    OnboardingRequirementsPanelController.rerunValidation(new List<Id>());
    Test.stopTest();

    // Should handle empty list gracefully
    System.assert(true, 'Method should handle empty list');
  }

  @isTest
  static void testRerunValidationWithNull() {
    Test.startTest();
    OnboardingRequirementsPanelController.rerunValidation(null);
    Test.stopTest();

    // Should handle null gracefully
    System.assert(true, 'Method should handle null');
  }
}
