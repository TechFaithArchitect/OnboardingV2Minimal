@isTest
private class VendorOnboardingControllerTest {
  @isTest
  static void testGetEligibleVendorOptions() {
    // Create mock data
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    Vendor__c vendor = new Vendor__c(Name = 'Vendor A', Active__c = true);
    insert vendor;

    Vendor_Customization__c customization = new Vendor_Customization__c(
      Vendor__c = vendor.Id,
      Retail_Option__c = 'National Agent',
      Business_Vertical__c = 'D2D'
    );
    insert customization;

    Test.startTest();
    List<VendorOptionDTO> results = VendorOnboardingController.getEligibleVendorOptions(
      testAccount.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, results);
  }

  @isTest
  static void testGetEligibleVendorOptionsForAccounts() {
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    Vendor__c vendor = new Vendor__c(Name = 'Vendor B', Active__c = true);
    insert vendor;

    Vendor_Customization__c customization = new Vendor_Customization__c(
      Vendor__c = vendor.Id,
      Retail_Option__c = 'National Retail',
      Business_Vertical__c = 'D2D'
    );
    insert customization;

    List<Id> accountIds = new List<Id>{ testAccount.Id };

    Test.startTest();
    List<List<VendorOptionDTO>> result = VendorOnboardingController.getEligibleVendorOptionsForAccounts(
      accountIds
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
  }

  @isTest
  static void testGetEligibleVendorOptionsAsJson() {
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    Vendor__c vendor = new Vendor__c(Name = 'Vendor C', Active__c = true);
    insert vendor;

    Vendor_Customization__c customization = new Vendor_Customization__c(
      Vendor__c = vendor.Id,
      Retail_Option__c = 'Amendment',
      Business_Vertical__c = 'D2D'
    );
    insert customization;

    Test.startTest();
    String jsonResult = VendorOnboardingController.getEligibleVendorOptionsAsJson(
      testAccount.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, jsonResult);
    System.assert(jsonResult.contains('Vendor C'));
  }
}
