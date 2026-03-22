@isTest
private class OnboardingNextStepRuleInvocableTest {
  @isTest
  static void invocable_nullAndEmptyRequests() {
    System.assertEquals(
      0,
      OnboardingNextStepRuleInvocable.applyAfterSetupComplete(
          new List<OnboardingNextStepRuleInvocable.Request>()
        )
        .size()
    );
    System.assertEquals(0, OnboardingNextStepRuleInvocable.applyAfterSetupComplete(null).size());
  }

  @isTest
  static void invocable_nullOnboardingId_returnsEmptyError() {
    OnboardingNextStepRuleInvocable.Request req = new OnboardingNextStepRuleInvocable.Request();
    req.onboardingId = null;
    List<OnboardingNextStepRuleInvocable.Result> results = OnboardingNextStepRuleInvocable.applyAfterSetupComplete(
      new List<OnboardingNextStepRuleInvocable.Request>{ req }
    );
    System.assertEquals(1, results.size());
    System.assertEquals('', results[0].errorMessage);
  }

  @isTest
  static void swallowingFaults_nullId_returnsBlank() {
    System.assertEquals('', OnboardingNextStepRuleService.applyAfterSetupCompleteSwallowingFaults(null));
  }

  @isTest
  static void swallowingFaults_forcedThrow_returnsMessage() {
    Account acc = TestAccountFactory.create('SwallowThrow', true);
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Vendor_Customization__c = vpw.customization.Id,
      Onboarding_Status__c = 'Setup Complete'
    );
    insert onb;
    try {
      OnboardingNextStepRuleService.forceThrowForTest = true;
      String msg = OnboardingNextStepRuleService.applyAfterSetupCompleteSwallowingFaults(onb.Id);
      System.assert(String.isNotBlank(msg), 'Expected non-blank error message');
      System.assert(msg.contains('forced test throw'), msg);
    } finally {
      OnboardingNextStepRuleService.forceThrowForTest = false;
    }
  }

  @isTest
  static void invocable_multipleRequests_nullThenForcedThrow() {
    Account acc = TestAccountFactory.create('InvMulti', true);
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Vendor_Customization__c = vpw.customization.Id,
      Onboarding_Status__c = 'Setup Complete'
    );
    insert onb;
    OnboardingNextStepRuleInvocable.Request rNull = new OnboardingNextStepRuleInvocable.Request();
    rNull.onboardingId = null;
    OnboardingNextStepRuleInvocable.Request rId = new OnboardingNextStepRuleInvocable.Request();
    rId.onboardingId = onb.Id;
    try {
      OnboardingNextStepRuleService.forceThrowForTest = true;
      List<OnboardingNextStepRuleInvocable.Result> results = OnboardingNextStepRuleInvocable.applyAfterSetupComplete(
        new List<OnboardingNextStepRuleInvocable.Request>{ rNull, rId }
      );
      System.assertEquals(2, results.size());
      System.assertEquals('', results[0].errorMessage);
      System.assert(String.isNotBlank(results[1].errorMessage), results[1].errorMessage);
    } finally {
      OnboardingNextStepRuleService.forceThrowForTest = false;
    }
  }

  @isTest
  static void readPath_readsOpportunityPicklist() {
    Account acc = TestAccountFactory.create('NextStepPath', true);
    Opportunity opp = new Opportunity(
      Name = 'Next Step Opp',
      AccountId = acc.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Program_Base_App_Selection__c = 'Program Base Application - with Chuzo'
    );
    insert opp;
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Vendor_Customization__c = vpw.customization.Id,
      Opportunity__c = opp.Id
    );
    insert onb;

    Onboarding__c row = [
      SELECT Id, Opportunity__r.Program_Base_App_Selection__c
      FROM Onboarding__c
      WHERE Id = :onb.Id
    ];
    String val = OnboardingNextStepRuleService.readPathAsStringForTest(
      row,
      'Opportunity__r.Program_Base_App_Selection__c'
    );
    System.assertEquals('Program Base Application - with Chuzo', val);
  }

  @isTest
  static void applyAfterSetupComplete_skipsWhenStatusNotSetupComplete() {
    Account acc = TestAccountFactory.create('NextStepSkip', true);
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Vendor_Customization__c = vpw.customization.Id,
      Onboarding_Status__c = 'Pending Initial Review'
    );
    insert onb;

    Test.startTest();
    OnboardingNextStepRuleService.applyAfterSetupComplete(onb.Id);
    Test.stopTest();

    System.assertEquals(
      1,
      [SELECT COUNT() FROM Onboarding__c WHERE Account__c = :acc.Id],
      'No sibling onboarding should be created when status is not Setup Complete'
    );
  }

  @isTest
  static void applyRuleSnapshotsForTest_createsLinkedOnboardingWhenMatch() {
    Account acc = TestAccountFactory.create('SnapMatch', true);
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Vendor_Customization__c vp2 = TestVendorProgramFactory.createCustomizationOnly(
      vpw.vendor,
      'Draft',
      true,
      null,
      true
    );
    Opportunity opp = new Opportunity(
      Name = 'Snap Opp',
      AccountId = acc.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Program_Base_App_Selection__c = 'Program Base Application - with Chuzo'
    );
    insert opp;
    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Vendor_Customization__c = vpw.customization.Id,
      Opportunity__c = opp.Id,
      Onboarding_Status__c = 'Setup Complete'
    );
    insert onb;

    OnboardingNextStepRuleService.RuleSnapshot snap = new OnboardingNextStepRuleService.RuleSnapshot();
    snap.developerName = 'Test_Rule';
    snap.action = 'Auto Create';
    snap.scopeKey = String.valueOf(vp2.Id);
    snap.fieldApiName = 'Opportunity__r.Program_Base_App_Selection__c';
    snap.expectedValue = 'Program Base Application - with Chuzo';
    snap.operator = 'Equals';

    Test.startTest();
    OnboardingNextStepRuleService.applyRuleSnapshotsForTest(
      onb.Id,
      new List<OnboardingNextStepRuleService.RuleSnapshot>{ snap }
    );
    Test.stopTest();

    List<Onboarding__c> linked = [
      SELECT Id, Vendor_Customization__c
      FROM Onboarding__c
      WHERE Account__c = :acc.Id AND Vendor_Customization__c = :vp2.Id
    ];
    System.assertEquals(1, linked.size(), 'Expected one auto-created onboarding for target vendor program');
  }

  @isTest
  static void applyRuleSnapshotsForTest_skipsWhenExpectedValueMismatch() {
    Account acc = TestAccountFactory.create('SnapMismatch', true);
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Vendor_Customization__c vp2 = TestVendorProgramFactory.createCustomizationOnly(
      vpw.vendor,
      'Draft',
      true,
      null,
      true
    );
    Opportunity opp = new Opportunity(
      Name = 'Snap Opp 2',
      AccountId = acc.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Program_Base_App_Selection__c = 'Program Base Application - with Chuzo'
    );
    insert opp;
    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Vendor_Customization__c = vpw.customization.Id,
      Opportunity__c = opp.Id,
      Onboarding_Status__c = 'Setup Complete'
    );
    insert onb;

    OnboardingNextStepRuleService.RuleSnapshot snap = new OnboardingNextStepRuleService.RuleSnapshot();
    snap.developerName = 'Test_Rule_Mismatch';
    snap.action = 'Auto Create';
    snap.scopeKey = String.valueOf(vp2.Id);
    snap.fieldApiName = 'Opportunity__r.Program_Base_App_Selection__c';
    snap.expectedValue = 'Program Base Application - without Chuzo';
    snap.operator = 'Equals';

    OnboardingNextStepRuleService.applyRuleSnapshotsForTest(
      onb.Id,
      new List<OnboardingNextStepRuleService.RuleSnapshot>{ snap }
    );

    System.assertEquals(
      1,
      [SELECT COUNT() FROM Onboarding__c WHERE Account__c = :acc.Id],
      'Mismatch should not create a sibling onboarding'
    );
  }

  @isTest
  static void applyRuleSnapshotsForTest_skipsNonEqualsOperator() {
    Account acc = TestAccountFactory.create('SnapOp', true);
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Vendor_Customization__c vp2 = TestVendorProgramFactory.createCustomizationOnly(
      vpw.vendor,
      'Draft',
      true,
      null,
      true
    );
    Opportunity opp = new Opportunity(
      Name = 'Snap Opp 3',
      AccountId = acc.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Program_Base_App_Selection__c = 'Program Base Application - with Chuzo'
    );
    insert opp;
    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Vendor_Customization__c = vpw.customization.Id,
      Opportunity__c = opp.Id,
      Onboarding_Status__c = 'Setup Complete'
    );
    insert onb;

    OnboardingNextStepRuleService.RuleSnapshot snap = new OnboardingNextStepRuleService.RuleSnapshot();
    snap.developerName = 'Test_Rule_Op';
    snap.action = 'Auto Create';
    snap.scopeKey = String.valueOf(vp2.Id);
    snap.fieldApiName = 'Opportunity__r.Program_Base_App_Selection__c';
    snap.expectedValue = 'Program Base Application - with Chuzo';
    snap.operator = 'NotEquals';

    OnboardingNextStepRuleService.applyRuleSnapshotsForTest(
      onb.Id,
      new List<OnboardingNextStepRuleService.RuleSnapshot>{ snap }
    );

    System.assertEquals(1, [SELECT COUNT() FROM Onboarding__c WHERE Account__c = :acc.Id]);
  }

  @isTest
  static void applyRuleSnapshotsForTest_skipsWhenTargetVendorProgramMissing() {
    Account acc = TestAccountFactory.create('SnapMissingVp', true);
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Opportunity opp = new Opportunity(
      Name = 'Snap Opp 4',
      AccountId = acc.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Program_Base_App_Selection__c = 'Program Base Application - with Chuzo'
    );
    insert opp;
    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Vendor_Customization__c = vpw.customization.Id,
      Opportunity__c = opp.Id,
      Onboarding_Status__c = 'Setup Complete'
    );
    insert onb;

    OnboardingNextStepRuleService.RuleSnapshot snap = new OnboardingNextStepRuleService.RuleSnapshot();
    snap.developerName = 'Test_Rule_MissingVp';
    snap.action = 'Auto Create';
    snap.scopeKey = vpw.customization.Id + '00';
    snap.fieldApiName = 'Opportunity__r.Program_Base_App_Selection__c';
    snap.expectedValue = 'Program Base Application - with Chuzo';
    snap.operator = 'Equals';

    OnboardingNextStepRuleService.applyRuleSnapshotsForTest(
      onb.Id,
      new List<OnboardingNextStepRuleService.RuleSnapshot>{ snap }
    );

    System.assertEquals(1, [SELECT COUNT() FROM Onboarding__c WHERE Account__c = :acc.Id]);
  }

  @isTest
  static void applyRuleSnapshotsForTest_skipsUnsafeFieldPath() {
    Account acc = TestAccountFactory.create('SnapUnsafe', true);
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Vendor_Customization__c vp2 = TestVendorProgramFactory.createCustomizationOnly(
      vpw.vendor,
      'Draft',
      true,
      null,
      true
    );
    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Vendor_Customization__c = vpw.customization.Id,
      Onboarding_Status__c = 'Setup Complete'
    );
    insert onb;

    OnboardingNextStepRuleService.RuleSnapshot snap = new OnboardingNextStepRuleService.RuleSnapshot();
    snap.developerName = 'Test_Unsafe';
    snap.action = 'Auto Create';
    snap.scopeKey = String.valueOf(vp2.Id);
    snap.fieldApiName = 'Opportunity__r.Name; DROP OBJECT';
    snap.expectedValue = 'x';
    snap.operator = 'Equals';

    OnboardingNextStepRuleService.applyRuleSnapshotsForTest(
      onb.Id,
      new List<OnboardingNextStepRuleService.RuleSnapshot>{ snap }
    );

    System.assertEquals(1, [SELECT COUNT() FROM Onboarding__c WHERE Account__c = :acc.Id]);
  }

  @isTest
  static void applyRuleSnapshotsForTest_skipsManualUnlockAction() {
    Account acc = TestAccountFactory.create('SnapManual', true);
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Vendor_Customization__c vp2 = TestVendorProgramFactory.createCustomizationOnly(
      vpw.vendor,
      'Draft',
      true,
      null,
      true
    );
    Opportunity opp = new Opportunity(
      Name = 'Snap Opp 5',
      AccountId = acc.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Program_Base_App_Selection__c = 'Program Base Application - with Chuzo'
    );
    insert opp;
    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Vendor_Customization__c = vpw.customization.Id,
      Opportunity__c = opp.Id,
      Onboarding_Status__c = 'Setup Complete'
    );
    insert onb;

    OnboardingNextStepRuleService.RuleSnapshot snap = new OnboardingNextStepRuleService.RuleSnapshot();
    snap.developerName = 'Test_Manual';
    snap.action = 'Manual Unlock';
    snap.scopeKey = String.valueOf(vp2.Id);
    snap.fieldApiName = 'Opportunity__r.Program_Base_App_Selection__c';
    snap.expectedValue = 'Program Base Application - with Chuzo';
    snap.operator = 'Equals';

    OnboardingNextStepRuleService.applyRuleSnapshotsForTest(
      onb.Id,
      new List<OnboardingNextStepRuleService.RuleSnapshot>{ snap }
    );

    System.assertEquals(1, [SELECT COUNT() FROM Onboarding__c WHERE Account__c = :acc.Id]);
  }

  @isTest
  static void applyRuleSnapshotsForTest_nullOrEmptyRules_noOp() {
    Account acc = TestAccountFactory.create('SnapEmptyRules', true);
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Vendor_Customization__c = vpw.customization.Id,
      Onboarding_Status__c = 'Setup Complete'
    );
    insert onb;

    OnboardingNextStepRuleService.applyRuleSnapshotsForTest(onb.Id, null);
    OnboardingNextStepRuleService.applyRuleSnapshotsForTest(
      onb.Id,
      new List<OnboardingNextStepRuleService.RuleSnapshot>()
    );
    OnboardingNextStepRuleService.applyRuleSnapshotsForTest(null, new List<OnboardingNextStepRuleService.RuleSnapshot>());

    System.assertEquals(1, [SELECT COUNT() FROM Onboarding__c WHERE Account__c = :acc.Id]);
  }
}
