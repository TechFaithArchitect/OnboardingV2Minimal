/**
 * Test for OnboardingDefaultVendorProgramInvocable.
 * Requires Onboarding_Default_Vendor_Program__mdt.REQUIRE_NDA_NAME_CONTAINS
 * to be deployed with Vendor_Name__c = 'PerfectVision' and Name contains token.
 */
@isTest
private class OnboardingDefaultVendorProgramInvocTest {
  @isTest
  static void testGetDefaultVendorProgramReturnsProgramWhenConfigured() {
    Vendor__c vendor = new Vendor__c(Name = 'PerfectVision', Active__c = true);
    insert vendor;

    Vendor_Customization__c vc = buildActiveVendorProgram(vendor.Id, 'Preferred NDA Program');
    insert vc;

    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = 'REQUIRE_NDA_NAME_CONTAINS';

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    OnboardingDefaultVendorProgramInvocable.VendorProgramResult r = results[0];
    System.assertNotEquals(null, r.vendorProgramRecord, 'Expected configured vendor program match');
    System.assertEquals(vc.Id, r.vendorProgramRecord.Id, 'Should return the configured vendor program');
    System.assert(String.isBlank(r.errorMessage), 'No error when program found');
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

  @isTest
  static void testScenarioWithoutConfigReturnsError() {
    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = 'DOES_NOT_EXIST';

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertEquals(
      true,
      String.isNotBlank(results[0].errorMessage),
      'Missing scenario config should return explicit error'
    );
    System.assertEquals(
      null,
      results[0].vendorProgramRecord,
      'Missing scenario config should not return a program'
    );
  }

  @isTest
  static void testAmbiguousMatchReturnsAnyActiveProgramWithoutError() {
    Vendor__c vendor = new Vendor__c(Name = 'PerfectVision', Active__c = true);
    insert vendor;

    Vendor_Customization__c vcA = buildActiveVendorProgram(vendor.Id, 'Preferred NDA Program A');
    Vendor_Customization__c vcB = buildActiveVendorProgram(vendor.Id, 'Preferred NDA Program B');
    insert new List<Vendor_Customization__c>{ vcA, vcB };

    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = 'REQUIRE_NDA_NAME_CONTAINS';

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertNotEquals(null, results[0].vendorProgramRecord, 'Expected one matched vendor program');
    System.assertEquals(
      true,
      results[0].vendorProgramRecord.Id == vcA.Id ||
      results[0].vendorProgramRecord.Id == vcB.Id,
      'Returned program should be one of the active matches'
    );
    System.assertEquals(
      true,
      String.isBlank(results[0].errorMessage),
      'Ambiguous active matches should still return without error'
    );
  }

  @isTest
  static void testNameContainsScenarioUsesContainsFilter() {
    Vendor__c vendor = new Vendor__c(Name = 'PerfectVision', Active__c = true);
    insert vendor;

    Vendor_Customization__c nonMatching = buildActiveVendorProgram(vendor.Id, 'Standard NDA Program');
    Vendor_Customization__c matching = buildActiveVendorProgram(vendor.Id, 'Preferred NDA Program');
    insert new List<Vendor_Customization__c>{ nonMatching, matching };

    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = 'REQUIRE_NDA_NAME_CONTAINS';

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertNotEquals(null, results[0].vendorProgramRecord, 'Expected matching vendor program');
    System.assertEquals(
      matching.Id,
      results[0].vendorProgramRecord.Id,
      'Name contains scenario should return the program matching configured contains token'
    );
    System.assertEquals(
      true,
      String.isBlank(results[0].errorMessage),
      'No error expected when contains filter finds a record'
    );
  }

  private static Vendor_Customization__c buildActiveVendorProgram(Id vendorId, String programName) {
    Vendor_Customization__c program = new Vendor_Customization__c(
      Name = programName,
      Vendor__c = vendorId,
      Active__c = true
    );

    String retailOption = firstActivePicklistValue(
      Vendor_Customization__c.Retail_Option__c
    );
    if (String.isNotBlank(retailOption)) {
      program.Retail_Option__c = retailOption;
    }

    String businessVertical = firstActivePicklistValue(
      Vendor_Customization__c.Business_Vertical__c
    );
    if (String.isNotBlank(businessVertical)) {
      program.Business_Vertical__c = businessVertical;
    }

    return program;
  }

  private static String firstActivePicklistValue(Schema.SObjectField fieldRef) {
    for (Schema.PicklistEntry entry : fieldRef.getDescribe().getPicklistValues()) {
      if (entry.isActive()) {
        return entry.getValue();
      }
    }
    return null;
  }
}
