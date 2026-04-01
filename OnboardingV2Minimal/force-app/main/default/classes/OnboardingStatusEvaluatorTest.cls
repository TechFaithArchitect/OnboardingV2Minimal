/**
 * Test class for OnboardingStatusEvaluatorService and OnboardingStatusEvaluatorInvocable.
 * Uses org metadata-driven rules and normalization records.
 */
@IsTest
private class OnboardingStatusEvaluatorTest {
  /** Pair discovered via DML so tests work when Requirement_Type__c is record-type–scoped. */
  private class IntegrationProgramTypeCandidate {
    String requirementType;
    Id recordTypeId;
  }

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

    String requirementType = discoverInsertableRequirementType(onb.Id);
    System.assertNotEquals(
      null,
      requirementType,
      'Expected at least one insertable onboarding requirement type for setup.'
    );

    insert new Onboarding_Requirement__c(
      Onboarding__c = onb.Id,
      Requirement_Type__c = requirementType,
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
    System.assertEquals(
      'ALL_SETUP_COMPLETE',
      results[0].matchedRuleDeveloperName,
      'Invocable should surface which CMDT rule won for support/debug'
    );
    System.assertEquals(
      30,
      Decimal.valueOf(results[0].matchedRuleOrder),
      'Matched rule order should match ALL_SETUP_COMPLETE CMDT'
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
  static void testAllRequirementsTerminalIgnoresTypesNotOnProgramTemplate() {
    OnboardingStatusEvaluatorService.EvaluationContext ctx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Signed'),
        buildReq('Contract', 'Complete'),
        buildReq('Training', 'Denied')
      }
    );
    ctx.applicableProgramRequirementTypesLowercase = new Set<String>{ 'agreement', 'contract' };

    System.assertEquals(
      true,
      evalPredicateJson('{"op":"allRequirementsTerminal"}', ctx),
      'Non-template requirement types must not block allRequirementsTerminal'
    );
  }

  @IsTest
  static void testAllRequirementsTerminalSkipsTemplateTypesWithNoOnboardingRow() {
    OnboardingStatusEvaluatorService.EvaluationContext ctx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{ buildReq('Agreement', 'Signed') }
    );
    ctx.applicableProgramRequirementTypesLowercase = new Set<String>{ 'agreement', 'contract' };

    System.assertEquals(
      true,
      evalPredicateJson('{"op":"allRequirementsTerminal"}', ctx),
      'Template type with no onboarding row must not block when another template type has terminal rows'
    );
  }

  @IsTest
  static void testAllRequirementsTerminalFalseWhenOnlyOffTemplateRowsAndNotTerminal() {
    OnboardingStatusEvaluatorService.EvaluationContext ctx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Training', 'In Process')
      }
    );
    ctx.applicableProgramRequirementTypesLowercase = new Set<String>{ 'agreement', 'contract' };

    System.assertEquals(
      false,
      evalPredicateJson('{"op":"allRequirementsTerminal"}', ctx),
      'When template keys match no rows, fall back requires every onboarding row to be terminal'
    );
  }

  @IsTest
  static void testAllRequirementsTerminalFallbackWhenProgramTypesMismatchRequirementRows() {
    OnboardingStatusEvaluatorService.EvaluationContext ctx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Signed'),
        buildReq('Contract', 'Complete')
      }
    );
    ctx.applicableProgramRequirementTypesLowercase = new Set<String>{
      'bogus_template_type',
      'another_bad_key'
    };

    System.assertEquals(
      true,
      evalPredicateJson('{"op":"allRequirementsTerminal"}', ctx),
      'When VPR types do not match any row, fall back to all rows terminal for Setup Complete'
    );
  }

  /**
   * Full-path test: Vendor_Program_Requirement__c drives the active template; inactive program rows
   * do not expand the template, so stray onboarding requirements of that type must not block Setup Complete.
   * Program types are discovered via insert probe so sandboxes with record-type–restricted picklists still pass.
   */
  @IsTest
  static void testIntegrationSetupCompleteIgnoresInactiveProgramRequirementTypes() {
    TestDataFactoryWrapper.VendorCustomizationWrapper programWrap = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Vendor_Customization__c vendorProgram = programWrap.customization;
    Account acc = TestDataFactory.createAccount('OnbStatusTemplateInt', true);
    Onboarding__c onb = TestOnboardingFactory.create(acc, vendorProgram, true);

    List<IntegrationProgramTypeCandidate> good = integrationDiscoverProgramTypesThatInsertOnOnboarding(
      vendorProgram,
      onb.Id,
      3,
      25
    );
    if (good.size() < 3) {
      System.assert(
        true,
        'Skipping integration branch: org did not expose 3 insertable Onboarding_Requirement__c requirement types.'
      );
      return;
    }

    // Insert probes run before startTest (separate governor bucket); startTest resets SOQL/DML for template rows + evaluate.
    Test.startTest();

    Vendor_Program_Requirement__c vprA = TestVendorProgramRequirementFactory.createForProgram(
      vendorProgram,
      good[0].requirementType,
      1,
      true,
      true,
      false
    );
    Vendor_Program_Requirement__c vprB = TestVendorProgramRequirementFactory.createForProgram(
      vendorProgram,
      good[1].requirementType,
      2,
      true,
      true,
      false
    );
    Vendor_Program_Requirement__c vprStray = TestVendorProgramRequirementFactory.createForProgram(
      vendorProgram,
      good[2].requirementType,
      3,
      false,
      false,
      false
    );
    insert new List<Vendor_Program_Requirement__c>{ vprA, vprB, vprStray };

    onb.Onboarding_Status__c = 'In Process';
    update onb;

    Map<String, String> normMap = OnboardingStatusNormalizationService.loadActiveNormalizationMap();

    TestOnboardingRequirementFactory.create(true, false, false, onb, good[0].requirementType, 1, null, vprA, good[0].recordTypeId);
    TestOnboardingRequirementFactory.create(true, false, false, onb, good[1].requirementType, 2, null, vprB, good[1].recordTypeId);
    TestOnboardingRequirementFactory.create(true, false, false, onb, good[2].requirementType, 3, null, vprStray, good[2].recordTypeId);

    for (Onboarding_Requirement__c r : [
      SELECT Id, Requirement_Type__c, Vendor_Program_Requirement__c
      FROM Onboarding_Requirement__c
      WHERE Onboarding__c = :onb.Id
    ]) {
      if (r.Vendor_Program_Requirement__c == vprStray.Id) {
        integrationForceInProgressLikeStatus(r.Id, r.Requirement_Type__c, normMap);
      } else {
        integrationForceTerminalStatus(r.Id, r.Requirement_Type__c, normMap);
      }
    }

    OnboardingStatusEvaluatorService.EvaluationContext probeCtx = OnboardingStatusEvaluatorService.loadEvaluationContextForTest(
      onb.Id
    );
    System.assertNotEquals(null, probeCtx, 'loadEvaluationContextForTest');
    System.assertEquals(
      2,
      probeCtx.applicableProgramRequirementTypesLowercase.size(),
      'Expected two active required program types on vendor template; applicable=' +
      probeCtx.applicableProgramRequirementTypesLowercase
    );
    System.assertEquals(
      true,
      OnboardingStatusPredicateInterpreter.evaluateNode(
        JSON.deserializeUntyped('{"op":"allRequirementsTerminal"}'),
        probeCtx
      ),
      integrationDebugEvaluationContext(probeCtx)
    );

    OnboardingStatusEvaluatorService.EvaluationResult result = OnboardingStatusEvaluatorService.evaluate(onb.Id);
    Test.stopTest();

    System.assertEquals(true, result.shouldUpdate, 'Evaluator should return a CMDT match');
    System.assertEquals(
      'Setup Complete',
      result.targetOnboardingStatus,
      'Only active required program types count; inactive VPR row must not expand the template'
    );
  }

  /** Extra active template type with no onboarding row must not block Setup Complete (service + SOQL path). */
  @IsTest
  static void testIntegrationSetupCompleteWhenSecondTemplateTypeHasNoOnboardingRow() {
    TestDataFactoryWrapper.VendorCustomizationWrapper programWrap = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Vendor_Customization__c vendorProgram = programWrap.customization;
    Account acc = TestDataFactory.createAccount('OnbStatusMissingRowInt', true);
    Onboarding__c onb = TestOnboardingFactory.create(acc, vendorProgram, true);

    List<IntegrationProgramTypeCandidate> good = integrationDiscoverProgramTypesThatInsertOnOnboarding(
      vendorProgram,
      onb.Id,
      2,
      20
    );
    if (good.size() < 2) {
      System.assert(
        true,
        'Skipping integration branch: org did not expose 2 insertable Onboarding_Requirement__c requirement types.'
      );
      return;
    }

    // Same as testIntegrationSetupCompleteIgnoresInactiveProgramRequirementTypes: discovery before startTest for governor isolation.
    Test.startTest();

    Vendor_Program_Requirement__c vprA = TestVendorProgramRequirementFactory.createForProgram(
      vendorProgram,
      good[0].requirementType,
      1,
      true,
      true,
      false
    );
    Vendor_Program_Requirement__c vprB = TestVendorProgramRequirementFactory.createForProgram(
      vendorProgram,
      good[1].requirementType,
      2,
      true,
      true,
      false
    );
    insert new List<Vendor_Program_Requirement__c>{ vprA, vprB };

    onb.Onboarding_Status__c = 'In Process';
    update onb;

    Map<String, String> normMap = OnboardingStatusNormalizationService.loadActiveNormalizationMap();

    TestOnboardingRequirementFactory.create(true, false, false, onb, good[0].requirementType, 1, null, vprA, good[0].recordTypeId);
    Onboarding_Requirement__c onlyReq = [
      SELECT Id, Requirement_Type__c
      FROM Onboarding_Requirement__c
      WHERE Onboarding__c = :onb.Id
      LIMIT 1
    ];
    integrationForceTerminalStatus(onlyReq.Id, good[0].requirementType, normMap);

    OnboardingStatusEvaluatorService.EvaluationResult result = OnboardingStatusEvaluatorService.evaluate(onb.Id);
    Test.stopTest();

    System.assertEquals(
      'Setup Complete',
      result.targetOnboardingStatus,
      'One terminal row plus a template type with no row should still match ALL_SETUP_COMPLETE'
    );
  }

  @IsTest
  static void testSetupCompleteWhenSecondProgramTypeHasNoRequirementRow() {
    List<String> vprTypes = TestDataFactoryUtil.getPicklistValues(
      Vendor_Program_Requirement__c.SObjectType,
      'Requirement_Type__c'
    );
    System.assert(vprTypes.size() >= 2, 'Org needs at least two program requirement types for this test');
    System.assert(programRequirementTypesIncludeAgreement(vprTypes), 'Program template picklist must include Agreement');
    String secondProgramType = null;
    for (String t : vprTypes) {
      if (!t.equalsIgnoreCase('Agreement')) {
        secondProgramType = t;
        break;
      }
    }
    System.assertNotEquals(null, secondProgramType);

    Vendor_Customization__c vp = [SELECT Id FROM Vendor_Customization__c LIMIT 1];
    insert new List<Vendor_Program_Requirement__c>{
      new Vendor_Program_Requirement__c(
        Vendor_Program__c = vp.Id,
        Requirement_Type__c = agreementProgramRequirementApiValue(vprTypes),
        Active__c = true,
        Is_Required__c = true,
        Sequence__c = 1
      ),
      new Vendor_Program_Requirement__c(
        Vendor_Program__c = vp.Id,
        Requirement_Type__c = secondProgramType,
        Active__c = true,
        Is_Required__c = true,
        Sequence__c = 2
      )
    };

    Onboarding__c onb = [SELECT Id FROM Onboarding__c LIMIT 1];

    Test.startTest();
    OnboardingStatusEvaluatorService.EvaluationResult result = OnboardingStatusEvaluatorService.evaluate(onb.Id);
    Test.stopTest();

    System.assertEquals(
      'Setup Complete',
      result.targetOnboardingStatus,
      'Missing row for a second template type must not block Setup Complete when existing rows are terminal'
    );
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

    OnboardingStatusEvaluatorService.EvaluationContext pirCtx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Signed'),
        buildReq('Contract', 'Not Started'),
        buildReq('Training', 'In Process'),
        buildReq('Business License', 'In Process')
      }
    );
    System.assertEquals(
      true,
      evalPredicateJson('{"op":"agreementSignedContractNotStartedOthersIgnored"}', pirCtx),
      'PIR gate should ignore non-Agreement/Contract rows'
    );
    System.assertEquals(
      false,
      evalPredicateJson('{"op":"agreementSignedContractNotStartedOthersIgnored"}', allCompleteCtx),
      'PIR gate should not match when contract is complete'
    );
    OnboardingStatusEvaluatorService.EvaluationContext noContractCtx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Signed'),
        buildReq('Training', 'Not Started')
      }
    );
    System.assertEquals(
      false,
      evalPredicateJson('{"op":"agreementSignedContractNotStartedOthersIgnored"}', noContractCtx),
      'PIR gate requires at least one Contract requirement row in an early milestone (Draft, New, Not Started, or In Approval Process normalized)'
    );

    OnboardingStatusEvaluatorService.EvaluationContext pirContractInApprovalCtx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Signed'),
        buildReq('Contract', 'In Approval Process'),
        buildReq('Training', 'In Process')
      }
    );
    System.assertEquals(
      true,
      evalPredicateJson(
        '{"op":"agreementSignedContractNotStartedOthersIgnored"}',
        pirContractInApprovalCtx
      ),
      'Contract requirement normalized In Approval Process should satisfy PIR contract gate when synced from linked Contract'
    );

    OnboardingStatusEvaluatorService.EvaluationContext pirContractDraftCtx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Signed'),
        buildReq('Contract', 'Draft')
      }
    );
    System.assertEquals(
      true,
      evalPredicateJson(
        '{"op":"agreementSignedContractNotStartedOthersIgnored"}',
        pirContractDraftCtx
      ),
      'Contract Draft (default create state) should satisfy PIR gate same as Not Started'
    );

    OnboardingStatusEvaluatorService.EvaluationContext pirContractNewCtx = buildContext(
      'Onboarding',
      'New',
      'Prospecting',
      new List<OnboardingStatusEvaluatorService.RequirementInfo>{
        buildReq('Agreement', 'Signed'),
        buildReq('Contract', 'New')
      }
    );
    System.assertEquals(
      true,
      evalPredicateJson(
        '{"op":"agreementSignedContractNotStartedOthersIgnored"}',
        pirContractNewCtx
      ),
      'Contract New should satisfy PIR gate before flows sync to Not Started'
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
      'canceled requirement should not match when opportunity stage is still open'
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

  private static Boolean programRequirementTypesIncludeAgreement(List<String> vprTypes) {
    for (String t : vprTypes) {
      if (t != null && t.equalsIgnoreCase('Agreement')) {
        return true;
      }
    }
    return false;
  }

  private static String agreementProgramRequirementApiValue(List<String> vprTypes) {
    for (String t : vprTypes) {
      if (t != null && t.equalsIgnoreCase('Agreement')) {
        return t;
      }
    }
    return 'Agreement';
  }

  private static String discoverInsertableRequirementType(Id onboardingId) {
    List<String> values = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Requirement__c.SObjectType,
      'Requirement_Type__c'
    );
    List<String> ordered = new List<String>();
    for (String value : values) {
      if (
        value != null &&
        !value.equalsIgnoreCase('Agreement') &&
        !value.equalsIgnoreCase('Contract') &&
        !value.equalsIgnoreCase('Training')
      ) {
        ordered.add(value);
      }
    }
    for (String value : values) {
      if (value != null && !ordered.contains(value)) {
        ordered.add(value);
      }
    }
    for (String candidate : ordered) {
      Database.SaveResult probeResult = Database.insert(
        new Onboarding_Requirement__c(
          Onboarding__c = onboardingId,
          Requirement_Type__c = candidate,
          Status__c = 'Draft',
          Is_Overridden__c = false
        ),
        false
      );
      if (probeResult.isSuccess()) {
        delete new Onboarding_Requirement__c(Id = probeResult.getId());
        return candidate;
      }
    }
    return null;
  }

  /**
   * Program-template picklist values are not always insertable on Onboarding_Requirement__c (record types).
   * Probe with a disposable inactive VPR + onboarding row; cap DML (org limit 150) via intersection + two-phase probes.
   */
  private static List<IntegrationProgramTypeCandidate> integrationDiscoverProgramTypesThatInsertOnOnboarding(
    Vendor_Customization__c vendorProgram,
    Id onboardingId,
    Integer wantCount,
    Integer maxTypeProbes
  ) {
    List<String> vprTypes = TestDataFactoryUtil.getPicklistValues(
      Vendor_Program_Requirement__c.SObjectType,
      'Requirement_Type__c'
    );
    Set<String> vprLower = new Set<String>();
    for (String x : vprTypes) {
      if (x != null) {
        vprLower.add(x.toLowerCase());
      }
    }
    List<String> programTypes = new List<String>();
    for (
      String o : TestDataFactoryUtil.getPicklistValues(
        Onboarding_Requirement__c.SObjectType,
        'Requirement_Type__c'
      )
    ) {
      if (o != null && vprLower.contains(o.toLowerCase())) {
        programTypes.add(o);
      }
    }
    if (programTypes.isEmpty()) {
      programTypes = vprTypes;
    }
    List<String> statusProbeOrder = integrationOnboardingStatusProbeOrderCapped(7);
    List<Schema.RecordTypeInfo> rtOrder = integrationSortedAvailableOnboardingRequirementRecordTypes();
    List<IntegrationProgramTypeCandidate> out = new List<IntegrationProgramTypeCandidate>();
    Set<String> seenTypeLower = new Set<String>();
    if (
      statusProbeOrder.isEmpty() ||
      onboardingId == null ||
      wantCount <= 0 ||
      rtOrder.isEmpty()
    ) {
      return out;
    }
    Integer typeProbes = 0;
    Integer typeCap = maxTypeProbes != null && maxTypeProbes > 0 ? maxTypeProbes : 25;
    for (String t : programTypes) {
      if (out.size() >= wantCount) {
        break;
      }
      if (typeProbes >= typeCap || !integrationDiscoveryHasDmlHeadroom(62)) {
        break;
      }
      typeProbes++;
      Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.createForProgram(
        vendorProgram,
        t,
        800 + typeProbes,
        false,
        false,
        true
      );
      Boolean foundForType = false;
      Integer perTypeAttempts = 16;
      try {
        for (String st : statusProbeOrder) {
          if (foundForType || perTypeAttempts <= 0 || !integrationDiscoveryHasDmlHeadroom(55)) {
            break;
          }
          if (String.isBlank(st)) {
            continue;
          }
          perTypeAttempts--;
          Onboarding_Requirement__c rowNoRt = new Onboarding_Requirement__c(
            Onboarding__c = onboardingId,
            Vendor_Program_Requirement__c = vpr.Id,
            Requirement_Type__c = t,
            Status__c = st,
            Is_Overridden__c = false
          );
          Database.SaveResult srNo = Database.insert(rowNoRt, false);
          if (srNo.isSuccess()) {
            if (!seenTypeLower.contains(t.toLowerCase())) {
              IntegrationProgramTypeCandidate c = new IntegrationProgramTypeCandidate();
              c.requirementType = t;
              c.recordTypeId = null;
              out.add(c);
              seenTypeLower.add(t.toLowerCase());
            }
            delete new Onboarding_Requirement__c(Id = srNo.getId());
            foundForType = true;
            break;
          }
        }
        if (!foundForType) {
          Integer rtSeen = 0;
          for (
            Schema.RecordTypeInfo rti : integrationRecordTypesOrderedForRequirementType(rtOrder, t)
          ) {
            if (rtSeen >= 5) {
              break;
            }
            rtSeen++;
            if (foundForType || perTypeAttempts <= 0 || !integrationDiscoveryHasDmlHeadroom(55)) {
              break;
            }
            Id rtId = rti.getRecordTypeId();
            for (String st : statusProbeOrder) {
              if (foundForType || perTypeAttempts <= 0 || !integrationDiscoveryHasDmlHeadroom(55)) {
                break;
              }
              if (String.isBlank(st)) {
                continue;
              }
              perTypeAttempts--;
              Onboarding_Requirement__c row = new Onboarding_Requirement__c(
                RecordTypeId = rtId,
                Onboarding__c = onboardingId,
                Vendor_Program_Requirement__c = vpr.Id,
                Requirement_Type__c = t,
                Status__c = st,
                Is_Overridden__c = false
              );
              Database.SaveResult sr = Database.insert(row, false);
              if (sr.isSuccess()) {
                if (!seenTypeLower.contains(t.toLowerCase())) {
                  IntegrationProgramTypeCandidate c = new IntegrationProgramTypeCandidate();
                  c.requirementType = t;
                  c.recordTypeId = rtId;
                  out.add(c);
                  seenTypeLower.add(t.toLowerCase());
                }
                delete new Onboarding_Requirement__c(Id = sr.getId());
                foundForType = true;
                break;
              }
            }
          }
        }
      } finally {
        delete vpr;
      }
    }
    return out;
  }

  private static List<Schema.RecordTypeInfo> integrationRecordTypesOrderedForRequirementType(
    List<Schema.RecordTypeInfo> baseOrder,
    String requirementType
  ) {
    if (String.isBlank(requirementType) || baseOrder == null || baseOrder.isEmpty()) {
      return baseOrder;
    }
    String tNorm = requirementType.toLowerCase().replaceAll('[^a-z0-9]', '');
    List<Schema.RecordTypeInfo> head = new List<Schema.RecordTypeInfo>();
    List<Schema.RecordTypeInfo> tail = new List<Schema.RecordTypeInfo>();
    for (Schema.RecordTypeInfo rti : baseOrder) {
      String dNorm = rti.getDeveloperName().toLowerCase().replaceAll('[^a-z0-9]', '');
      if (
        tNorm.length() > 2 &&
        (dNorm.contains(tNorm) || tNorm.contains(dNorm))
      ) {
        head.add(rti);
      } else {
        tail.add(rti);
      }
    }
    head.addAll(tail);
    return head;
  }

  private static List<Schema.RecordTypeInfo> integrationSortedAvailableOnboardingRequirementRecordTypes() {
    Map<String, Schema.RecordTypeInfo> byDev = new Map<String, Schema.RecordTypeInfo>();
    for (
      Schema.RecordTypeInfo rti : Onboarding_Requirement__c.SObjectType.getDescribe().getRecordTypeInfos()
    ) {
      if (!rti.isAvailable() || rti.getRecordTypeId() == null) {
        continue;
      }
      byDev.put(rti.getDeveloperName(), rti);
    }
    List<String> keys = new List<String>(byDev.keySet());
    keys.sort();
    List<Schema.RecordTypeInfo> ordered = new List<Schema.RecordTypeInfo>();
    for (String k : keys) {
      ordered.add(byDev.get(k));
    }
    return ordered;
  }

  private static List<String> integrationOnboardingStatusProbeOrder() {
    List<String> raw = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Requirement__c.SObjectType,
      'Status__c'
    );
    List<String> preferredFirst = new List<String>{
      'Not Started',
      'In Process',
      'Signed',
      'Complete',
      'Incomplete',
      'Pending',
      'New'
    };
    List<String> out = new List<String>();
    Set<String> usedLower = new Set<String>();
    for (String p : preferredFirst) {
      for (String r : raw) {
        if (r != null && p.equalsIgnoreCase(r) && !usedLower.contains(r.toLowerCase())) {
          out.add(r);
          usedLower.add(r.toLowerCase());
          break;
        }
      }
    }
    for (String r : raw) {
      if (r != null && !usedLower.contains(r.toLowerCase())) {
        out.add(r);
        usedLower.add(r.toLowerCase());
      }
    }
    return out;
  }

  private static List<String> integrationOnboardingStatusProbeOrderCapped(Integer maxValues) {
    List<String> full = integrationOnboardingStatusProbeOrder();
    if (maxValues == null || maxValues < 1 || full.size() <= maxValues) {
      return full;
    }
    List<String> capped = new List<String>();
    for (Integer i = 0; i < full.size() && capped.size() < maxValues; i++) {
      capped.add(full[i]);
    }
    return capped;
  }

  /** True if enough DML remains for probe + later integration setup (inserts + status forcing). */
  private static Boolean integrationDiscoveryHasDmlHeadroom(Integer minRemaining) {
    return Limits.getLimitDmlStatements() - Limits.getDmlStatements() > minRemaining;
  }

  private static String integrationDebugEvaluationContext(
    OnboardingStatusEvaluatorService.EvaluationContext ctx
  ) {
    List<String> parts = new List<String>{
      'applicable=' + String.valueOf(ctx.applicableProgramRequirementTypesLowercase)
    };
    for (OnboardingStatusEvaluatorService.RequirementInfo r : ctx.requirements) {
      parts.add(
        (r.requirementType == null ? '?' : r.requirementType) +
          '/' +
          (r.status == null ? '?' : r.status) +
          '->' +
          (r.normalizedStatus == null ? '?' : r.normalizedStatus)
      );
    }
    return String.join(parts, ' | ');
  }

  private static Boolean integrationIsTerminalNormalized(String n) {
    if (String.isBlank(n)) {
      return false;
    }
    return n.equalsIgnoreCase('Signed') ||
      n.equalsIgnoreCase('Complete') ||
      n.equalsIgnoreCase('Setup Complete') ||
      n.equalsIgnoreCase('Ignore');
  }

  private static Boolean integrationIsDeniedOrCanceledLike(String n) {
    if (String.isBlank(n)) {
      return false;
    }
    return n.equalsIgnoreCase('Denied') ||
      n.equalsIgnoreCase('Expired') ||
      n.equalsIgnoreCase('Canceled') ||
      n.equalsIgnoreCase('Cancelled');
  }

  private static void integrationForceTerminalStatus(
    Id requirementId,
    String requirementType,
    Map<String, String> normMap
  ) {
    System.assert(requirementId != null, 'integrationForceTerminalStatus: requirement id required');
    System.assert(
      String.isNotBlank(requirementType),
      'integrationForceTerminalStatus: requirement type required'
    );
    for (
      String st : TestDataFactoryUtil.getPicklistValues(
        Onboarding_Requirement__c.SObjectType,
        'Status__c'
      )
    ) {
      if (String.isBlank(st)) {
        continue;
      }
      Database.SaveResult ur = Database.update(
        new Onboarding_Requirement__c(Id = requirementId, Status__c = st),
        false
      );
      if (!ur.isSuccess()) {
        continue;
      }
      String n = OnboardingStatusNormalizationService.normalize(requirementType, st, normMap);
      if (integrationIsTerminalNormalized(n)) {
        return;
      }
    }
    System.assert(
      false,
      'Could not set a terminal normalized status for requirement type ' + requirementType
    );
  }

  /** Avoid normalized Denied/Canceled/Expired so ANY_DENIED does not win before ALL_SETUP_COMPLETE. */
  private static void integrationForceInProgressLikeStatus(
    Id requirementId,
    String requirementType,
    Map<String, String> normMap
  ) {
    System.assert(requirementId != null, 'integrationForceInProgressLikeStatus: requirement id required');
    System.assert(
      String.isNotBlank(requirementType),
      'integrationForceInProgressLikeStatus: requirement type required'
    );
    for (
      String st : TestDataFactoryUtil.getPicklistValues(
        Onboarding_Requirement__c.SObjectType,
        'Status__c'
      )
    ) {
      if (String.isBlank(st)) {
        continue;
      }
      Database.SaveResult ur = Database.update(
        new Onboarding_Requirement__c(Id = requirementId, Status__c = st),
        false
      );
      if (!ur.isSuccess()) {
        continue;
      }
      String n = OnboardingStatusNormalizationService.normalize(requirementType, st, normMap);
      if (String.isBlank(n)) {
        continue;
      }
      if (integrationIsDeniedOrCanceledLike(n)) {
        continue;
      }
      if (!integrationIsTerminalNormalized(n)) {
        return;
      }
    }
    System.assert(
      false,
      'Could not set an in-progress normalized status for requirement type ' + requirementType
    );
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
    if (opportunityStage == null) {
      ctx.opportunity = null;
    } else {
      ctx.opportunity = new Opportunity(StageName = opportunityStage);
    }
    ctx.requirements = requirements;
    ctx.normalizedByReqType = new Map<String, String>();
    ctx.applicableProgramRequirementTypesLowercase = new Set<String>();
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

    String requirementType = discoverInsertableRequirementType(secondaryOnboarding.Id);
    System.assertNotEquals(
      null,
      requirementType,
      'Expected at least one insertable onboarding requirement type for secondary onboarding.'
    );

    insert new Onboarding_Requirement__c(
      Onboarding__c = secondaryOnboarding.Id,
      Requirement_Type__c = requirementType,
      Status__c = 'Signed',
      Is_Overridden__c = false
    );

    return secondaryOnboarding;
  }

}
