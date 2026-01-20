@isTest
private class VendorOnboardingLWCAdapterTest {
  @isTest
  static void testGetVendorOptionsReturnsExpectedData() {
    // Setup test account
    Account acct = new Account(Name = 'LWC Adapter Account');
    insert acct;

    // Setup active vendor
    Vendor__c vendor = new Vendor__c(Name = 'LWC Vendor', Active__c = true);
    insert vendor;

    // Setup vendor customization
    Vendor_Customization__c vc = new Vendor_Customization__c(
      Vendor__c = vendor.Id,
      Retail_Option__c = 'National Agent',
      Business_Vertical__c = 'D2D'
    );
    insert vc;

    // No Onboarding__c record = vendor is eligible

    Test.startTest();
    List<VendorOptionDTO> options = VendorOnboardingService.getVendorOptions(
      acct.Id
    );
    Test.stopTest();

    System.assertEquals(1, options.size(), 'Should return one vendor option');
    System.assertEquals(vendor.Id, options[0].vendorId);
    System.assertEquals('National Agent', options[0].retailOption);
    System.assert(options[0].businessVerticals.contains('D2D'));
  }

  @isTest
  static void testNullAccountIdReturnsEmptyList() {
    Test.startTest();
    List<VendorOptionDTO> options = VendorOnboardingService.getVendorOptions(
      null
    );
    Test.stopTest();

    System.assertEquals(
      0,
      options.size(),
      'Should return empty list for null input'
    );
  }
}
