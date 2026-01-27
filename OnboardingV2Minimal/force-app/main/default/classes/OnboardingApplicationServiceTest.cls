@isTest
private class OnboardingApplicationServiceTest {
  @testSetup
  static void setupTestData() {
    Account testAccount = TestDataFactory.createAccount('Test Account', true);
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

    Vendor_Program_Requirement__c requirement = TestDataFactory.createVendorProgramRequirement(
      testProgram,
      true,
      true
    );

    TestOnboardingRequirementFactory.create(
      true,
      testOnboarding,
      requirement
    );
  }

  @isTest
  static void testGetRequirements() {
    Onboarding__c onboarding = [SELECT Id FROM Onboarding__c LIMIT 1];

    Test.startTest();
    List<OnboardingApplicationService.RequirementDTO> results = OnboardingApplicationService.getRequirements(
      onboarding.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    System.assert(results.size() > 0, 'Should return requirements');
  }

  @isTest
  static void testUpdateRequirementStatuses() {
    Onboarding_Requirement__c requirement = [
      SELECT Id, Status__c
      FROM Onboarding_Requirement__c
      LIMIT 1
    ];

    List<String> statuses = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Requirement__c.SObjectType,
      'Status__c'
    );
    String updatedStatus = statuses.contains('Approved')
      ? 'Approved'
      : (statuses.isEmpty() ? null : statuses[0]);

    OnboardingApplicationService.RequirementDTO dto = new OnboardingApplicationService.RequirementDTO(
      requirement
    );
    dto.Status = updatedStatus;

    Test.startTest();
    OnboardingApplicationService.updateRequirementStatuses(
      new List<OnboardingApplicationService.RequirementDTO>{ dto }
    );
    Test.stopTest();

    Onboarding_Requirement__c updated = [
      SELECT Status__c
      FROM Onboarding_Requirement__c
      WHERE Id = :requirement.Id
    ];
    System.assertEquals(updatedStatus, updated.Status__c, 'Status should update');
  }

  @isTest
  static void testRunRuleEvaluation() {
    Onboarding__c onboarding = [SELECT Id FROM Onboarding__c LIMIT 1];

    Test.startTest();
    OnboardingApplicationService.runRuleEvaluation(onboarding.Id);
    Test.stopTest();

    System.assert(true, 'Rule evaluation should complete');
  }

  @isTest
  static void testGetResumeContext() {
    Onboarding__c onboarding = [SELECT Id FROM Onboarding__c LIMIT 1];

    Test.startTest();
    OnboardingApplicationService.ResumeContext context = OnboardingApplicationService.getResumeContext(
      onboarding.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, context, 'Context should not be null');
    System.assertEquals(onboarding.Id, context.onboardingId, 'Should match onboarding');
  }
}
