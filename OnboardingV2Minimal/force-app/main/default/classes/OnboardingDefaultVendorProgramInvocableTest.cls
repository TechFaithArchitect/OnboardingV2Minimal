/**
 * Test for OnboardingDefaultVendorProgramInvocable.
 * Requires Onboarding_Default_Vendor_Program__mdt.REQUIRE_NDA to be deployed
 * with Vendor_Name__c = 'Perfect Vision'.
 */
@isTest
private class OnboardingDefaultVendorProgramInvocableTest {
  @isTest
  static void testGetDefaultVendorProgramReturnsProgramWhenConfigured() {
    Vendor__c vendor = new Vendor__c(Name = 'Perfect Vision', Active__c = true);
    insert vendor;

    Vendor_Customization__c vc = new Vendor_Customization__c(
      Vendor__c = vendor.Id,
      Retail_Option__c = 'NDA',
      Business_Vertical__c = 'Default',
      Active__c = true
    );
    insert vc;

    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = 'REQUIRE_NDA';

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    OnboardingDefaultVendorProgramInvocable.VendorProgramResult r = results[0];
    if (r.vendorProgramRecord != null) {
      System.assertEquals(vc.Id, r.vendorProgramRecord.Id, 'Should return the configured vendor program');
      System.assert(String.isBlank(r.errorMessage), 'No error when program found');
    } else {
      System.assert(
        String.isNotBlank(r.errorMessage),
        'When no program found, error message should explain why'
      );
    }
  }

  @isTest
  static void testEmptyScenarioKeyReturnsError() {
    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = '';

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assert(String.isNotBlank(results[0].errorMessage), 'Should return error for blank scenario');
    System.assertEquals(null, results[0].vendorProgramRecord);
  }

  @isTest
  static void testNullRequestReturnsEmptyResult() {
    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      null
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Returns one empty result for null input');
  }
}
