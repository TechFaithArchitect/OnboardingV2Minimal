@isTest
private class OnboardingRecordBREGateInvocableTest {
  @isTest
  static void evaluate_emptyAndNullRequests() {
    System.assertEquals(
      0,
      OnboardingRecordBREGateInvocable.evaluate(new List<OnboardingRecordBREGateInvocable.Request>()).size()
    );
    System.assertEquals(0, OnboardingRecordBREGateInvocable.evaluate(null).size());
  }

  @isTest
  static void evaluate_missingEventKey_returnsDiagnostic() {
    OnboardingRecordBREGateInvocable.Request req = new OnboardingRecordBREGateInvocable.Request();
    req.eventKey = '';
    List<OnboardingRecordBREGateInvocable.Result> results = OnboardingRecordBREGateInvocable.evaluate(
      new List<OnboardingRecordBREGateInvocable.Request>{ req }
    );
    System.assertEquals(1, results.size());
    System.assertEquals(false, results[0].dispatchAllowed);
    System.assertNotEquals(null, results[0].diagnosticMessage);
  }

  @isTest
  static void evaluate_runsFlowPath_withVendorProgram() {
    TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );
    OnboardingRecordBREGateInvocable.Request req = new OnboardingRecordBREGateInvocable.Request();
    req.eventKey = 'SetupComplete';
    req.vendorProgramId = vpw.customization.Id;
    List<OnboardingRecordBREGateInvocable.Result> results = OnboardingRecordBREGateInvocable.evaluate(
      new List<OnboardingRecordBREGateInvocable.Request>{ req }
    );
    System.assertEquals(1, results.size());
    System.assertNotEquals(null, results[0]);
  }
}
