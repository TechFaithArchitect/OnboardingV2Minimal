@isTest
private class OnboardingPrimaryContactTest {
  @isTest
  static void createsAvoWithPrimaryContact() {
    Account acct = TestDataFactory.createAccount(
      'Primary Contact Account',
      true
    );
    Contact contact = TestDataFactory.createContact(
      'Primary',
      'Contact',
      true,
      acct
    );

    Opportunity opp = new Opportunity(
      Name = 'Onboarding Opp',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(5),
      AccountId = acct.Id
    );
    insert opp;

    Vendor__c vendor = TestDataFactory.createVendor(true);
    Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
      vendor,
      'Active',
      true,
      null,
      true
    );
    Onboarding__c onboarding = TestDataFactory.createOnboarding(
      acct,
      vendorProgram,
      true
    );

    Test.startTest();
    Id avoId = VendorOnboardingWizardController.createAccountVendorProgramOnboarding(
      acct.Id,
      onboarding.Id,
      opp.Id,
      'Intake',
      contact.Id
    );
    Test.stopTest();

    Account_Vendor_Program_Onboarding__c avo = [
      SELECT Primary_Contact__c
      FROM Account_Vendor_Program_Onboarding__c
      WHERE Id = :avoId
    ];

    System.assertEquals(
      contact.Id,
      avo.Primary_Contact__c,
      'AVO should store primary contact'
    );
  }
}
