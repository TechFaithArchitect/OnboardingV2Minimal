@isTest
private class OnboardingInvocablesTest {
  @isTest
  static void testGetEligibleVendorsJsonReturnsPayload() {
    Account accountRecord = new Account(Name = 'Invocable Vendor Account');
    insert accountRecord;

    Vendor__c vendorRecord = new Vendor__c(
      Name = 'Invocable Vendor',
      Active__c = true
    );
    insert vendorRecord;

    Vendor_Customization__c customizationRecord = new Vendor_Customization__c(
      Vendor__c = vendorRecord.Id,
      Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
        Vendor_Customization__c.SObjectType,
        'Status__c'
      ),
      Active__c = true,
      Retail_Option__c = 'National Agent',
      Business_Vertical__c = TestDataFactoryUtil.getDefaultPicklistValue(
        Vendor_Customization__c.SObjectType,
        'Business_Vertical__c'
      )
    );
    insert customizationRecord;

    OnboardingInvocables.VendorOptionsRequest requestItem = new OnboardingInvocables.VendorOptionsRequest();
    requestItem.accountId = accountRecord.Id;

    Test.startTest();
    List<OnboardingInvocables.VendorOptionsResult> results = OnboardingInvocables.getEligibleVendorsJson(
      new List<OnboardingInvocables.VendorOptionsRequest>{ requestItem }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Expected one result row.');
    System.assertEquals(
      accountRecord.Id,
      results[0].accountId,
      'Account should be echoed in result.'
    );
    System.assertEquals(
      null,
      results[0].errorMessage,
      'No error expected for valid request.'
    );
    System.assert(
      results[0].eligibleVendorsJson.contains('National Agent'),
      'Expected retail option in JSON payload.'
    );
    System.assert(
      results[0].eligibleVendorCount > 0,
      'Expected at least one eligible vendor option.'
    );
  }

  @isTest
  static void testGetEligibleVendorsJsonHandlesMissingAccountId() {
    OnboardingInvocables.VendorOptionsRequest requestItem = new OnboardingInvocables.VendorOptionsRequest();

    Test.startTest();
    List<OnboardingInvocables.VendorOptionsResult> results = OnboardingInvocables.getEligibleVendorsJson(
      new List<OnboardingInvocables.VendorOptionsRequest>{ requestItem }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Expected one result row.');
    System.assertEquals(
      'Account Id is required.',
      results[0].errorMessage,
      'Missing account id should return validation message.'
    );
    System.assertEquals(
      0,
      results[0].eligibleVendorCount,
      'Invalid requests should not return vendor results.'
    );
  }

  @isTest
  static void testGetEligibleVendorsJsonHandlesEmptyRequests() {
    Test.startTest();
    List<OnboardingInvocables.VendorOptionsResult> nullResults = OnboardingInvocables.getEligibleVendorsJson(
      null
    );
    List<OnboardingInvocables.VendorOptionsResult> emptyResults = OnboardingInvocables.getEligibleVendorsJson(
      new List<OnboardingInvocables.VendorOptionsRequest>()
    );
    Test.stopTest();

    System.assertEquals(0, nullResults.size(), 'Null request list should return empty response.');
    System.assertEquals(0, emptyResults.size(), 'Empty request list should return empty response.');
  }

  @isTest
  static void testGetEligibleVendorsJsonHandlesServiceFailure() {
    Account accountRecord = new Account(Name = 'Invocable Error Account');
    insert accountRecord;

    OnboardingInvocables.VendorOptionsRequest requestItem = new OnboardingInvocables.VendorOptionsRequest();
    requestItem.accountId = accountRecord.Id;

    Test.startTest();
    OnboardingInvocables.forceFailureForTests = true;
    List<OnboardingInvocables.VendorOptionsResult> results = OnboardingInvocables.getEligibleVendorsJson(
      new List<OnboardingInvocables.VendorOptionsRequest>{ requestItem }
    );
    OnboardingInvocables.forceFailureForTests = false;
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Expected one result row.');
    System.assertEquals(
      'Unable to retrieve eligible vendors.',
      results[0].errorMessage,
      'Forced failures should return a user-safe error message.'
    );
  }
}
