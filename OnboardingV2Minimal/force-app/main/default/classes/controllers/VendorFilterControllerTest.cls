@isTest
public with sharing class VendorFilterControllerTest {
  @isTest
  static void testGetVendorsAsJson() {
    // Setup test Account
    Account acct = new Account(Name = 'Json Adapter Account');
    insert acct;

    // Setup test Vendor
    Vendor__c vendor = new Vendor__c(Name = 'JSON Vendor', Active__c = true);
    insert vendor;

    // Setup Customization
    Vendor_Customization__c vc = new Vendor_Customization__c(
      Vendor__c = vendor.Id,
      Retail_Option__c = 'National Agent',
      Business_Vertical__c = 'D2D'
    );
    insert vc;

    // No Onboarding__c to ensure vendor is considered eligible

    // Execute Adapter
    Test.startTest();
    List<String> results = VendorFilterController.getVendorsAsJson(
      new List<Id>{ acct.Id }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one JSON string');

    String jsonOutput = results[0];
    System.assert(
      jsonOutput.contains('National Agent'),
      'JSON should include Nation Agent option'
    );
    System.assert(
      jsonOutput.contains(vendor.Name),
      'JSON should include vendor name'
    );
  }

  @isTest
  static void testEmptyInputReturnsEmptyJsonArray() {
    Test.startTest();
    List<String> results = VendorFilterController.getVendorsAsJson(
      new List<Id>()
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals(
      '[]',
      results[0],
      'Should return empty JSON array for empty input'
    );
  }
}
