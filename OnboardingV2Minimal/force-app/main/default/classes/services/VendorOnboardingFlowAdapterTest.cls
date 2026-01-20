@isTest
private class VendorOnboardingFlowAdapterTest {
  @isTest
  static void testGetEligibleVendorsForFlow() {
    // Setup test Account
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    // Setup test Vendor
    Vendor__c vendor = new Vendor__c(Name = 'Test Vendor', Active__c = true);
    insert vendor;

    // Setup Customization
    Vendor_Customization__c vc = new Vendor_Customization__c(
      Vendor__c = vendor.Id,
      Retail_Option__c = 'National Agent',
      Business_Vertical__c = 'D2D'
    );
    insert vc;

    // Mock prerequisites — skip logic for now unless testing the full evaluator
    Test.startTest();
    List<Id> accountIds = new List<Id>{ acct.Id };
    List<VendorOnboardingDTO> results = VendorOnboardingService.getEligibleVendorsForFlow(
      accountIds
    );
    Test.stopTest();

    System.assertNotEquals(
      0,
      results.size(),
      'Expected at least one DTO returned'
    );
    VendorOnboardingDTO dto = results[0];
    System.assertEquals(vendor.Id, dto.vendorId);
    System.assertEquals(vendor.Name, dto.vendorName);
    System.assert(dto.availableRetailOptions.contains('National Agent'));
  }
}
