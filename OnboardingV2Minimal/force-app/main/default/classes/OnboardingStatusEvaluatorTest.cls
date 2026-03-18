/**
 * Test class for OnboardingStatusEvaluatorService and OnboardingStatusEvaluatorInvocable.
 */
@IsTest
private class OnboardingStatusEvaluatorTest {
  @TestSetup
  static void setup() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    Opportunity opp = new Opportunity(
      Name = 'Test Opp',
      AccountId = acc.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30)
    );
    insert opp;

    Vendor__c vendor = new Vendor__c(Name = 'Test Vendor');
    insert vendor;

    Vendor_Customization__c vp = new Vendor_Customization__c(
      Name = 'Test Program',
      Vendor__c = vendor.Id,
      Active__c = true
    );
    insert vp;

    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Vendor_Customization__c = vp.Id,
      Opportunity__c = opp.Id,
      Onboarding_Status__c = 'New',
      Assigned_Team__c = 'Onboarding'
    );
    insert onb;

    Vendor_Program_Requirement__c vpr = new Vendor_Program_Requirement__c(
      Vendor_Program__c = vp.Id,
      Requirement_Type__c = 'Agreement',
      Active__c = true
    );
    insert vpr;

    Onboarding_Requirement__c req = new Onboarding_Requirement__c(
      Onboarding__c = onb.Id,
      Requirement_Type__c = 'Agreement',
      Status__c = 'Signed',
      Is_Overridden__c = false
    );
    insert req;
  }

  @IsTest
  static void testEvaluateReturnsResult() {
    Onboarding__c onb = [SELECT Id FROM Onboarding__c LIMIT 1];

    Test.startTest();
    OnboardingStatusEvaluatorService.EvaluationResult result = OnboardingStatusEvaluatorService.evaluate(
      onb.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
  }

  @IsTest
  static void testEvaluateAndApply() {
    Onboarding__c onb = [
      SELECT Id, Onboarding_Status__c
      FROM Onboarding__c
      LIMIT 1
    ];
    String beforeStatus = onb.Onboarding_Status__c;

    Test.startTest();
    OnboardingStatusEvaluatorService.EvaluationResult result = OnboardingStatusEvaluatorService.evaluateAndApply(
      onb.Id
    );
    Test.stopTest();

    Onboarding__c updated = [
      SELECT Onboarding_Status__c
      FROM Onboarding__c
      WHERE Id = :onb.Id
    ];
    if (result.shouldUpdate && String.isNotBlank(result.targetOnboardingStatus)) {
      System.assertEquals(
        result.targetOnboardingStatus,
        updated.Onboarding_Status__c,
        'Onboarding status should be updated'
      );
    }
  }

  @IsTest
  static void testInvocableWithApply() {
    Onboarding__c onb = [SELECT Id FROM Onboarding__c LIMIT 1];

    OnboardingStatusEvaluatorInvocable.EvaluateRequest req = new OnboardingStatusEvaluatorInvocable.EvaluateRequest();
    req.onboardingId = onb.Id;
    req.applyUpdates = true;

    Test.startTest();
    List<OnboardingStatusEvaluatorInvocable.EvaluateResult> results = OnboardingStatusEvaluatorInvocable.evaluate(
      new List<OnboardingStatusEvaluatorInvocable.EvaluateRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertNotEquals(null, results[0], 'Result should not be null');
  }

  @IsTest
  static void testInvocableWithoutApply() {
    Onboarding__c onb = [SELECT Id FROM Onboarding__c LIMIT 1];

    OnboardingStatusEvaluatorInvocable.EvaluateRequest req = new OnboardingStatusEvaluatorInvocable.EvaluateRequest();
    req.onboardingId = onb.Id;
    req.applyUpdates = false;

    Test.startTest();
    List<OnboardingStatusEvaluatorInvocable.EvaluateResult> results = OnboardingStatusEvaluatorInvocable.evaluate(
      new List<OnboardingStatusEvaluatorInvocable.EvaluateRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
  }

  @IsTest
  static void testInvocableNullRequest() {
    Test.startTest();
    List<OnboardingStatusEvaluatorInvocable.EvaluateResult> results = OnboardingStatusEvaluatorInvocable.evaluate(
      new List<OnboardingStatusEvaluatorInvocable.EvaluateRequest>()
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one empty result');
  }

  @IsTest
  static void testEvaluateNullId() {
    Test.startTest();
    OnboardingStatusEvaluatorService.EvaluationResult result = OnboardingStatusEvaluatorService.evaluate(
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(false, result.shouldUpdate, 'Should not update');
  }
}
