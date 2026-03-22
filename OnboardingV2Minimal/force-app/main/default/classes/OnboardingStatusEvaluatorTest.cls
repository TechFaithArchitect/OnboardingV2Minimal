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
  static void testPredicateJsonBranchCoverage() {
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
      evalPredicateJson('{"op":"reqAnyNormalizedEquals","normalized":"Denied"}', deniedCtx),
      'reqAnyNormalizedEquals Denied should match'
    );
    System.assertEquals(
      false,
      evalPredicateJson(
        '{"all":[{"op":"notReqAnyNormalizedEquals","normalized":"Denied"},{"op":"notAllRequirementsTerminal"}]}',
        deniedCtx
      ),
      'in-process composite should fail when denied exists'
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
      evalPredicateJson('{"op":"allRequirementsTerminal"}', allCompleteCtx),
      'allRequirementsTerminal should match Signed/Complete/Ignore set'
    );
    System.assertEquals(
      true,
      evalPredicateJson('{"op":"agreementAndContractCompleteOthersIgnored"}', allCompleteCtx),
      'agreementAndContractCompleteOthersIgnored should match signed agreement + complete contract'
    );

    OnboardingStatusEvaluatorService.EvaluationContext expiredCtx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Expired')
      }
    );
    System.assertEquals(
      true,
      evalPredicateJson('{"op":"reqAnyNormalizedEquals","normalized":"Expired"}', expiredCtx),
      'reqAnyNormalizedEquals Expired should match'
    );

    OnboardingStatusEvaluatorService.EvaluationContext canceledOpenOppCtx = buildContext(
      'Onboarding',
      'Canceled',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Canceled')
      }
    );
    System.assertEquals(
      false,
      evalPredicateJson('{"op":"anyRequirementCanceledWithStageGate"}', canceledOpenOppCtx),
      'canceled requirement should not match when opportunity stage is open'
    );

    OnboardingStatusEvaluatorService.EvaluationContext canceledClosedOppCtx = buildContext(
      'Onboarding',
      'Canceled',
      'Closed Lost',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Canceled')
      }
    );
    System.assertEquals(
      true,
      evalPredicateJson('{"op":"anyRequirementCanceledWithStageGate"}', canceledClosedOppCtx),
      'canceled requirement should match when opportunity is canceled/lost'
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
      evalPredicateJson(
        '{"op":"onlyRequirementTypeNormalizedInSet","requirementType":"Agreement","allowedNormalized":["Out for signature"]}',
        outForSignatureCtx
      ),
      'onlyRequirementTypeNormalizedInSet should match sole agreement out for signature'
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
      evalPredicateJson(
        '{"op":"onlyRequirementTypeNormalizedInSet","requirementType":"Agreement","allowedNormalized":["Signed","Setup Complete"]}',
        agreementSignedOnlyCtx
      ),
      'onlyRequirementTypeNormalizedInSet should treat Setup Complete as signed-equivalent'
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
      evalPredicateJson(
        '{"all":[{"op":"notReqAnyNormalizedEquals","normalized":"Denied"},{"op":"notAllRequirementsTerminal"},{"op":"assignedTeamEquals","team":"Sales"}]}',
        pendingSalesCtx
      ),
      'pending sales composite should match'
    );
    System.assertEquals(
      true,
      evalPredicateJson(
        '{"all":[{"op":"notReqAnyNormalizedEquals","normalized":"Denied"},{"op":"notAllRequirementsTerminal"}]}',
        pendingSalesCtx
      ),
      'in-process default composite should match incomplete, non-denied requirements'
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
      evalPredicateJson('{"op":"opportunityStageCanceled"}', canceledOppCtx),
      'opportunityStageCanceled should match canceled/lost opportunity stages'
    );

    System.assertEquals(
      false,
      evalPredicateJson('{"op":"unknownOp"}', pendingSalesCtx),
      'Unknown op should not match'
    );
    System.assertEquals(
      false,
      evalPredicateJson('{}', pendingSalesCtx),
      'Missing op should not match'
    );
  }

  @IsTest
  static void testBlankPredicateConfigDoesNotMatch() {
    OnboardingStatusEvaluatorService.EvaluationContext ctx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{ buildReq('Agreement', 'Denied') }
    );
    Onboarding_Status_Evaluation_Rule__mdt rule = new Onboarding_Status_Evaluation_Rule__mdt(
      DeveloperName = 'TestBlankPredicate',
      Predicate_Config__c = null,
      Condition_Type__c = 'ANY_DENIED'
    );
    System.assertEquals(
      false,
      OnboardingStatusPredicateInterpreter.ruleMatchesRule(rule, ctx),
      'Blank Predicate_Config__c must not match regardless of Condition_Type__c'
    );
  }

  @IsTest
  static void testPredicateJsonRepresentativeContexts() {
    assertPredicateTrue(
      buildContext(
        'Onboarding',
        'New',
        'Prospecting',
        new List<OnboardingStatusEvaluatorService.RequirementInfo>{ buildReq('Agreement', 'Denied') }
      ),
      '{"op":"reqAnyNormalizedEquals","normalized":"Denied"}'
    );
    assertPredicateTrue(
      buildContext(
        'Onboarding',
        'New',
        'Prospecting',
        new List<OnboardingStatusEvaluatorService.RequirementInfo>{
          buildReq('Agreement', 'Signed'),
          buildReq('Contract', 'Complete'),
          buildReq('Training', 'Ignore')
        }
      ),
      '{"op":"allRequirementsTerminal"}'
    );
    assertPredicateTrue(
      buildContext(
        'Onboarding',
        'Canceled',
        'Closed Lost',
        new List<OnboardingStatusEvaluatorService.RequirementInfo>{ buildReq('Agreement', 'Canceled') }
      ),
      '{"op":"anyRequirementCanceledWithStageGate"}'
    );
    assertPredicateTrue(
      buildContext(
        'Onboarding',
        'New',
        'Prospecting',
        new List<OnboardingStatusEvaluatorService.RequirementInfo>{
          buildReq('Agreement', 'In Process')
        }
      ),
      '{"all":[{"op":"notReqAnyNormalizedEquals","normalized":"Denied"},{"op":"notAllRequirementsTerminal"}]}'
    );
    assertPredicateTrue(
      buildContext(
        'Sales',
        'New',
        'Prospecting',
        new List<OnboardingStatusEvaluatorService.RequirementInfo>{ buildReq('Agreement', 'In Process') }
      ),
      '{"all":[{"op":"notReqAnyNormalizedEquals","normalized":"Denied"},{"op":"notAllRequirementsTerminal"},{"op":"assignedTeamEquals","team":"Sales"}]}'
    );
  }

  @IsTest
  static void testInjectedRuleEngineShortCircuitsEvaluation() {
    Onboarding__c onb = [SELECT Id FROM Onboarding__c LIMIT 1];
    OnboardingStatusEvaluatorService.setRuleEngineForTest(new FalseRuleEngine());

    Test.startTest();
    OnboardingStatusEvaluatorService.EvaluationResult result = OnboardingStatusEvaluatorService.evaluate(
      onb.Id
    );
    Test.stopTest();

    OnboardingStatusEvaluatorService.setRuleEngineForTest(null);

    System.assertEquals(false, result.shouldUpdate, 'Stub engine should prevent rule match');
  }

  private static Boolean evalPredicateJson(
    String predicateJson,
    OnboardingStatusEvaluatorService.EvaluationContext ctx
  ) {
    Object root = JSON.deserializeUntyped(predicateJson);
    return OnboardingStatusPredicateInterpreter.evaluateNode(root, ctx);
  }

  private static void assertPredicateTrue(
    OnboardingStatusEvaluatorService.EvaluationContext ctx,
    String predicateJson
  ) {
    System.assertEquals(
      true,
      evalPredicateJson(predicateJson, ctx),
      'Predicate should match for this context: ' + predicateJson
    );
  }

  private class FalseRuleEngine implements IOnboardingStatusRuleEngine {
    public Boolean ruleApplies(
      Onboarding_Status_Evaluation_Rule__mdt rule,
      OnboardingStatusEvaluatorService.EvaluationContext context
    ) {
      return false;
    }
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
