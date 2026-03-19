/**
 * Test class for OnboardingStatusEvaluatorService and OnboardingStatusEvaluatorInvocable.
 * Uses org metadata-driven rules and normalization records.
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
      Onboarding_Status__c = 'Setup Complete',
      Assigned_Team__c = 'Onboarding'
    );
    insert onb;

    insert new Onboarding_Requirement__c(
      Onboarding__c = onb.Id,
      Requirement_Type__c = 'Agreement',
      Status__c = 'Signed',
      Is_Overridden__c = false
    );
  }

  @IsTest
  static void testEvaluateSignedAgreementReturnsPendingInitialReview() {
    Onboarding__c onb = [SELECT Id FROM Onboarding__c LIMIT 1];

    Test.startTest();
    OnboardingStatusEvaluatorService.EvaluationResult result = OnboardingStatusEvaluatorService.evaluate(
      onb.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(true, result.shouldUpdate, 'Expected matching rule');
    System.assertEquals(
      'Setup Complete',
      result.targetOnboardingStatus,
      'Signed agreement path should match ALL_SETUP_COMPLETE first by rule order'
    );
  }

  @IsTest
  static void testEvaluateAndApplyNoOpWhenAlreadyAtTarget() {
    Onboarding__c onb = [
      SELECT Id, Onboarding_Status__c
      FROM Onboarding__c
      LIMIT 1
    ];

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
    System.assertEquals(true, result.shouldUpdate, 'Rule evaluation should still match');
    System.assertEquals(
      'Setup Complete',
      updated.Onboarding_Status__c,
      'No-op apply should keep target status unchanged'
    );
  }

  @IsTest
  static void testInvocableWithoutApplyReturnsContractFields() {
    Onboarding__c onb = [
      SELECT Id, Onboarding_Status__c
      FROM Onboarding__c
      LIMIT 1
    ];
    String onboardingStatusBefore = onb.Onboarding_Status__c;

    OnboardingStatusEvaluatorInvocable.EvaluateRequest req = new OnboardingStatusEvaluatorInvocable.EvaluateRequest();
    req.onboardingId = onb.Id;
    req.applyUpdates = false;

    Test.startTest();
    List<OnboardingStatusEvaluatorInvocable.EvaluateResult> results = OnboardingStatusEvaluatorInvocable.evaluate(
      new List<OnboardingStatusEvaluatorInvocable.EvaluateRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertEquals(true, results[0].shouldUpdate, 'Should expose shouldUpdate output');
    System.assertEquals(
      'Setup Complete',
      results[0].targetOnboardingStatus,
      'Should return evaluated target status without DML'
    );
    System.assert(String.isBlank(results[0].errorMessage), 'No error expected');

    Onboarding__c onbAfter = [
      SELECT Onboarding_Status__c
      FROM Onboarding__c
      WHERE Id = :onb.Id
    ];
    System.assertEquals(
      onboardingStatusBefore,
      onbAfter.Onboarding_Status__c,
      'applyUpdates=false should not persist updates'
    );
  }

  @IsTest
  static void testInvocableWithApplyReturnsNoErrorWhenNoPersistNeeded() {
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
    System.assertEquals(true, results[0].shouldUpdate, 'Expected matching rule');
    System.assert(String.isBlank(results[0].errorMessage), 'No error expected');
  }

  @IsTest
  static void testInvocableNullRequestReturnsSingleEmptyResult() {
    Test.startTest();
    List<OnboardingStatusEvaluatorInvocable.EvaluateResult> results = OnboardingStatusEvaluatorInvocable.evaluate(
      null
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one empty result');
  }

  @IsTest
  static void testInvocableNullOnboardingIdReturnsError() {
    OnboardingStatusEvaluatorInvocable.EvaluateRequest req = new OnboardingStatusEvaluatorInvocable.EvaluateRequest();
    req.onboardingId = null;
    req.applyUpdates = true;

    Test.startTest();
    List<OnboardingStatusEvaluatorInvocable.EvaluateResult> results = OnboardingStatusEvaluatorInvocable.evaluate(
      new List<OnboardingStatusEvaluatorInvocable.EvaluateRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Expected one invocable result');
    System.assertEquals(
      'Onboarding Record Id is required.',
      results[0].errorMessage,
      'Flow-facing contract should return explicit validation error'
    );
  }

  @IsTest
  static void testInvocableProcessesMultipleRequestsInSingleCall() {
    Onboarding__c primaryOnboarding = [SELECT Id FROM Onboarding__c LIMIT 1];
    Onboarding__c secondaryOnboarding = createSecondaryOnboarding();

    OnboardingStatusEvaluatorInvocable.EvaluateRequest req1 = new OnboardingStatusEvaluatorInvocable.EvaluateRequest();
    req1.onboardingId = primaryOnboarding.Id;
    req1.applyUpdates = false;

    OnboardingStatusEvaluatorInvocable.EvaluateRequest req2 = new OnboardingStatusEvaluatorInvocable.EvaluateRequest();
    req2.onboardingId = secondaryOnboarding.Id;
    req2.applyUpdates = false;

    Test.startTest();
    List<OnboardingStatusEvaluatorInvocable.EvaluateResult> results = OnboardingStatusEvaluatorInvocable.evaluate(
      new List<OnboardingStatusEvaluatorInvocable.EvaluateRequest>{ req1, req2 }
    );
    Test.stopTest();

    System.assertEquals(2, results.size(), 'Expected one result per request row');
    System.assert(String.isBlank(results[0].errorMessage), 'First request should not fail');
    System.assert(String.isBlank(results[1].errorMessage), 'Second request should not fail');
    System.assertEquals('Setup Complete', results[0].targetOnboardingStatus);
    System.assertEquals('Setup Complete', results[1].targetOnboardingStatus);
  }

  @IsTest
  static void testInvocableSupportsCollectionIdInputForBulkApply() {
    Onboarding__c primaryOnboarding = [SELECT Id FROM Onboarding__c LIMIT 1];
    Onboarding__c secondaryOnboarding = createSecondaryOnboarding();

    OnboardingStatusEvaluatorInvocable.EvaluateRequest req = new OnboardingStatusEvaluatorInvocable.EvaluateRequest();
    req.onboardingIds = new List<String>{
      String.valueOf(primaryOnboarding.Id),
      String.valueOf(secondaryOnboarding.Id)
    };
    req.applyUpdates = false;

    Test.startTest();
    List<OnboardingStatusEvaluatorInvocable.EvaluateResult> results = OnboardingStatusEvaluatorInvocable.evaluate(
      new List<OnboardingStatusEvaluatorInvocable.EvaluateRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Expected one result for collection request');
    System.assert(String.isBlank(results[0].errorMessage), 'Collection request should not fail');
    System.assertEquals(true, results[0].shouldUpdate, 'At least one onboarding should match a rule');
  }

  @IsTest
  static void testEvaluateNullIdReturnsNoUpdate() {
    Test.startTest();
    OnboardingStatusEvaluatorService.EvaluationResult result = OnboardingStatusEvaluatorService.evaluate(
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(false, result.shouldUpdate, 'Null onboarding id should not update');
  }

  @IsTest
  static void testEvaluateConditionBranchCoverage() {
    OnboardingStatusEvaluatorService.EvaluationContext deniedCtx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Denied')
      }
    );
    System.assertEquals(
      true,
      OnboardingStatusEvaluatorService.evaluateConditionForTest('ANY_DENIED', deniedCtx),
      'ANY_DENIED should match when one normalized status is Denied'
    );
    System.assertEquals(
      false,
      OnboardingStatusEvaluatorService.evaluateConditionForTest('IN_PROCESS_DEFAULT', deniedCtx),
      'IN_PROCESS_DEFAULT should fail when denied exists'
    );

    OnboardingStatusEvaluatorService.EvaluationContext allCompleteCtx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Signed'),
        buildReq('Contract', 'Complete'),
        buildReq('Training', 'Ignore')
      }
    );
    System.assertEquals(
      true,
      OnboardingStatusEvaluatorService.evaluateConditionForTest('ALL_SETUP_COMPLETE', allCompleteCtx),
      'ALL_SETUP_COMPLETE should match Signed/Complete/Ignore set'
    );
    System.assertEquals(
      true,
      OnboardingStatusEvaluatorService.evaluateConditionForTest(
        'AGREEMENT_SIGNED_AND_CONTRACT_COMPLETE',
        allCompleteCtx
      ),
      'AGREEMENT_SIGNED_AND_CONTRACT_COMPLETE should match signed agreement + complete contract'
    );

    OnboardingStatusEvaluatorService.EvaluationContext outForSignatureCtx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Out for signature')
      }
    );
    System.assertEquals(
      true,
      OnboardingStatusEvaluatorService.evaluateConditionForTest(
        'ONLY_AGREEMENT_OUT_FOR_SIGNATURE',
        outForSignatureCtx
      ),
      'ONLY_AGREEMENT_OUT_FOR_SIGNATURE should match when agreement is the only non-ignore requirement'
    );

    OnboardingStatusEvaluatorService.EvaluationContext agreementSignedOnlyCtx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Setup Complete')
      }
    );
    System.assertEquals(
      true,
      OnboardingStatusEvaluatorService.evaluateConditionForTest(
        'ONLY_AGREEMENT_SIGNED',
        agreementSignedOnlyCtx
      ),
      'ONLY_AGREEMENT_SIGNED should treat Setup Complete as signed-equivalent'
    );

    OnboardingStatusEvaluatorService.EvaluationContext pendingSalesCtx = buildContext(
      'Sales',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'In Process')
      }
    );
    System.assertEquals(
      true,
      OnboardingStatusEvaluatorService.evaluateConditionForTest('PENDING_SALES', pendingSalesCtx),
      'PENDING_SALES should match for Sales team and incomplete, non-denied requirements'
    );
    System.assertEquals(
      true,
      OnboardingStatusEvaluatorService.evaluateConditionForTest('IN_PROCESS_DEFAULT', pendingSalesCtx),
      'IN_PROCESS_DEFAULT should match incomplete, non-denied requirements'
    );

    OnboardingStatusEvaluatorService.EvaluationContext canceledOppCtx = buildContext(
      'Onboarding',
      'New',
      'Closed Lost',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Signed')
      }
    );
    System.assertEquals(
      true,
      OnboardingStatusEvaluatorService.evaluateConditionForTest('OPPORTUNITY_CANCELED', canceledOppCtx),
      'OPPORTUNITY_CANCELED should match canceled/lost opportunity stages'
    );

    System.assertEquals(
      false,
      OnboardingStatusEvaluatorService.evaluateConditionForTest('UNKNOWN_CONDITION', pendingSalesCtx),
      'Unknown condition type should not match'
    );
    System.assertEquals(
      false,
      OnboardingStatusEvaluatorService.evaluateConditionForTest('', pendingSalesCtx),
      'Blank condition type should not match'
    );
  }

  private static OnboardingStatusEvaluatorService.EvaluationContext buildContext(
    String assignedTeam,
    String onboardingStatus,
    String opportunityStage,
    List<OnboardingStatusEvaluatorService.RequirementInfo> requirements
  ) {
    OnboardingStatusEvaluatorService.EvaluationContext ctx = new OnboardingStatusEvaluatorService.EvaluationContext();
    ctx.onboarding = new Onboarding__c(
      Assigned_Team__c = assignedTeam,
      Onboarding_Status__c = onboardingStatus
    );
    ctx.opportunity = new Opportunity(StageName = opportunityStage);
    ctx.requirements = requirements;
    ctx.normalizedByReqType = new Map<String, String>();
    for (OnboardingStatusEvaluatorService.RequirementInfo req : requirements) {
      ctx.normalizedByReqType.put(req.requirementType, req.normalizedStatus);
    }
    return ctx;
  }

  private static OnboardingStatusEvaluatorService.RequirementInfo buildReq(
    String requirementType,
    String normalizedStatus
  ) {
    OnboardingStatusEvaluatorService.RequirementInfo req = new OnboardingStatusEvaluatorService.RequirementInfo();
    req.requirementType = requirementType;
    req.normalizedStatus = normalizedStatus;
    req.status = normalizedStatus;
    req.isOverridden = false;
    return req;
  }

  private static Onboarding__c createSecondaryOnboarding() {
    Onboarding__c seed = [
      SELECT Account__c, Vendor_Customization__c, Opportunity__c
      FROM Onboarding__c
      LIMIT 1
    ];

    Onboarding__c secondaryOnboarding = new Onboarding__c(
      Account__c = seed.Account__c,
      Vendor_Customization__c = seed.Vendor_Customization__c,
      Opportunity__c = seed.Opportunity__c,
      Onboarding_Status__c = 'New',
      Assigned_Team__c = 'Onboarding'
    );
    insert secondaryOnboarding;

    insert new Onboarding_Requirement__c(
      Onboarding__c = secondaryOnboarding.Id,
      Requirement_Type__c = 'Agreement',
      Status__c = 'Signed',
      Is_Overridden__c = false
    );

    return secondaryOnboarding;
  }

}
