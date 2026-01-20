@isTest
private class VendorOnboardingServiceTest {
  @isTest
  static void testGetEligibleVendorsReturnsCorrectDTOs() {
    Account acct = TestDataFactory.createAccount('Test Account', true);

    TestDataFactoryWrapper.VendorCustomizationWrapper setup = TestDataFactoryWrapper.createDraftVendorCustomizationWrapper(
      true
    );

    // Link customization to required fields
    setup.customization.Retail_Option__c = 'National Agent';
    setup.customization.Business_Vertical__c = 'D2D';
    update setup.customization;

    Test.startTest();
    List<List<VendorOptionDTO>> result = VendorOnboardingService.getEligibleVendors(
      new List<Id>{ acct.Id }
    );
    Test.stopTest();

    System.assertEquals(
      1,
      result.size(),
      'Should return one result list for one account'
    );
    System.assertEquals(1, result[0].size(), 'Should return one vendor option');

    VendorOptionDTO dto = result[0][0];
    System.assertEquals(setup.vendor.Id, dto.vendorId);
    System.assertEquals(setup.vendor.Name, dto.vendorName);
    System.assertEquals('National Agent', dto.retailOption);
    System.assert(dto.businessVerticals.contains('D2D'));
  }

  @isTest
  static void testGetEligibleVendorsWithOnboardedVendorReturnsNone() {
    Account acct = TestDataFactory.createAccount('Onboarded Account', true);

    TestDataFactoryWrapper.VendorCustomizationWrapper setup = TestDataFactoryWrapper.createDraftVendorCustomizationWrapper(
      true
    );

    // Simulate an existing onboarding with the same customization (Vendor Program)
    Onboarding__c ob = new Onboarding__c(
      Account__c = acct.Id,
      Vendor_Customization__c = setup.customization.Id
    );
    insert ob;

    setup.customization.Retail_Option__c = 'National Agent';
    setup.customization.Business_Vertical__c = 'D2D';
    update setup.customization;

    Test.startTest();
    List<List<VendorOptionDTO>> result = VendorOnboardingService.getEligibleVendors(
      new List<Id>{ acct.Id }
    );
    Test.stopTest();

    System.assertEquals(1, result.size(), 'Should return one list');
    System.assertEquals(
      0,
      result[0].size(),
      'Should not return onboarded vendors'
    );
  }

  @isTest
  static void testGetEligibleVendorsHandlesEmptyList() {
    Test.startTest();
    List<List<VendorOptionDTO>> result = VendorOnboardingService.getEligibleVendors(
      new List<Id>()
    );
    Test.stopTest();

    System.assertEquals(
      0,
      result.size(),
      'Should return empty list for no accounts'
    );
  }
}
