@isTest
private class OnboardingRecordFlowSupportTest {
  @isTest
  static void loadOnboardingForFlow_null_returnsNull() {
    System.assertEquals(null, OnboardingRecordFlowSupport.loadOnboardingForFlow(null));
  }

  @isTest
  static void loadVendorProgramForFlow_null_returnsNull() {
    System.assertEquals(null, OnboardingRecordFlowSupport.loadVendorProgramForFlow(null));
  }

  @isTest
  static void loadOnboardingForFlow_returnsMatchingRow() {
    Account acc = TestAccountFactory.create('OnbRecFlowSup', true);
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Onboarding__c onb = TestOnboardingFactory.create(acc, vpw.customization, true);

    Onboarding__c loaded = OnboardingRecordFlowSupport.loadOnboardingForFlow(onb.Id);
    System.assertNotEquals(null, loaded, 'Expected a row loaded by dynamic SOQL');
    System.assertEquals(onb.Id, loaded.Id);
  }

  @isTest
  static void loadVendorProgramForFlow_returnsMatchingRow() {
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );

    Vendor_Customization__c loaded = OnboardingRecordFlowSupport.loadVendorProgramForFlow(
      vpw.customization.Id
    );
    System.assertNotEquals(null, loaded);
    System.assertEquals(vpw.customization.Id, loaded.Id);
  }

  @isTest
  static void runAutolaunchedFlow_blankApiName_failsWithoutThrowing() {
    OnboardingRecordFlowSupport.InterviewRunResult r = OnboardingRecordFlowSupport.runAutolaunchedFlow(
      '',
      new Map<String, Object>()
    );
    System.assertEquals(false, r.succeeded);
    System.assertNotEquals(null, r.errorMessage);
  }

  @isTest
  static void runAutolaunchedFlow_unknownFlow_failsWithoutThrowing() {
    OnboardingRecordFlowSupport.InterviewRunResult r = OnboardingRecordFlowSupport.runAutolaunchedFlow(
      'NoSuchFlow_' + String.valueOf(Math.abs(Crypto.getRandomInteger())),
      new Map<String, Object>()
    );
    System.assertEquals(false, r.succeeded);
    System.assertNotEquals(null, r.errorMessage);
  }

  @isTest
  static void interviewRunResult_getVariableValue_afterFailure_returnsNull() {
    OnboardingRecordFlowSupport.InterviewRunResult r = OnboardingRecordFlowSupport.runAutolaunchedFlow(
      '',
      null
    );
    System.assertEquals(null, r.getVariableValue('AnyVariable'));
  }

  @isTest
  static void dispatchByEvent_emptyAndNullRequests() {
    System.assertEquals(
      0,
      OnboardingRecordFlowSupport.dispatchCommunicationByEvent(
          new List<OnboardingRecordFlowSupport.DispatchByEventRequest>()
        )
        .size()
    );
    System.assertEquals(0, OnboardingRecordFlowSupport.dispatchCommunicationByEvent(null).size());
  }

  @isTest
  static void dispatchByEvent_missingOnboarding_returnsDiagnostic() {
    OnboardingRecordFlowSupport.DispatchByEventRequest req = new OnboardingRecordFlowSupport.DispatchByEventRequest();
    req.eventKey = 'SetupComplete';
    req.onboardingId = null;
    List<OnboardingRecordFlowSupport.DispatchByEventResult> results = OnboardingRecordFlowSupport.dispatchCommunicationByEvent(
      new List<OnboardingRecordFlowSupport.DispatchByEventRequest>{ req }
    );
    System.assertEquals(1, results.size());
    System.assertEquals(false, results[0].ranSuccessfully);
    System.assertNotEquals(null, results[0].diagnosticMessage);
  }

  @isTest
  static void dispatchByEvent_runsFlowPath_withOnboarding() {
    Account acc = TestAccountFactory.create('OnbDispByEv', true);
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    Onboarding__c onb = TestOnboardingFactory.create(acc, vpw.customization, true);
    OnboardingRecordFlowSupport.DispatchByEventRequest req = new OnboardingRecordFlowSupport.DispatchByEventRequest();
    req.eventKey = 'SetupComplete';
    req.onboardingId = onb.Id;
    req.vendorProgramId = vpw.customization.Id;
    List<OnboardingRecordFlowSupport.DispatchByEventResult> results = OnboardingRecordFlowSupport.dispatchCommunicationByEvent(
      new List<OnboardingRecordFlowSupport.DispatchByEventRequest>{ req }
    );
    System.assertEquals(1, results.size());
    System.assertNotEquals(null, results[0]);
  }

}
