@isTest
private class ContactECCControllerTest {
  @testSetup
  static void setupData() {
    TestDataFactory.createECCTestWrapper(true);
  }

  @isTest
  static void testGetECCRecordsForContact() {
    Contact testContact = [
      SELECT Id
      FROM Contact
      WHERE Principal_Owner__c = FALSE
      LIMIT 1
    ];

    Test.startTest();
    ContactECCDependencyWrapper result = ContactECCController.getECCRecordsForContact(
      testContact.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Wrapper should not be null');
    System.assert(
      result.records.size() > 0,
      'Should return at least one ECC record'
    );
    System.assert(
      result.fieldConfigurations.size() > 0,
      'Field configs should be populated'
    );
    System.assertEquals('other_user', result.records[0].record.POE_Username__c);
  }

  @isTest
  static void testShouldShowECCTrue() {
    Contact contact = [
      SELECT Id
      FROM Contact
      WHERE POE_Commercial_Programs__c = 'Verizon Fios D2D'
      LIMIT 1
    ];
    Boolean result = ContactECCController.shouldShowECC(contact.Id);
    System.assertEquals(
      true,
      result,
      'Should return true for Verizon Fios D2D'
    );
  }

  @isTest
  static void testShouldShowECCFalse() {
    Account acct = [SELECT Id FROM Account LIMIT 1];
    Contact contact = new Contact(
      FirstName = 'No',
      LastName = 'Program',
      AccountId = acct.Id,
      POE_Commercial_Programs__c = 'Spectrum'
    );
    insert contact;

    Boolean result = ContactECCController.shouldShowECC(contact.Id);
    System.assertEquals(false, result, 'Should return false for non-Verizon');
  }

  @isTest
  static void testUpdateECCRecord() {
    POE_External_Contact_Credential__c ecc = [
      SELECT Id, POE_Process_Status__c
      FROM POE_External_Contact_Credential__c
      LIMIT 1
    ];
    ecc.POE_Process_Status__c = 'In Progress';

    Test.startTest();
    ContactECCController.updateECCRecord(ecc);
    Test.stopTest();

    POE_External_Contact_Credential__c updated = [
      SELECT POE_Process_Status__c
      FROM POE_External_Contact_Credential__c
      WHERE Id = :ecc.Id
    ];
    System.assertEquals('In Progress', updated.POE_Process_Status__c);
  }

  @isTest
  static void testGetECCRecordsForOnboarding() {
    Contact principalContact = [
      SELECT Id, AccountId
      FROM Contact
      WHERE Principal_Owner__c = TRUE
      LIMIT 1
    ];
    Id customizationId = [
      SELECT Vendor_Customization__c
      FROM Required_Credential__c
      WHERE Vendor_Customization__c != NULL
      LIMIT 1
    ]
    .Vendor_Customization__c;
    Onboarding__c onboarding = TestDataFactory.createOnboarding(
      new Account(Id = principalContact.AccountId),
      new Vendor_Customization__c(Id = customizationId),
      true
    );

    Test.startTest();
    List<POE_External_Contact_Credential__c> records = ContactECCController.getECCRecordsForOnboarding(
      onboarding.Id
    );
    Test.stopTest();

    System.assert(
      records.size() > 0,
      'Should return ECC records for onboarding'
    );
    System.assertEquals('Verizon Fios D2D', records[0].POE_Program__c);
  }

  @isTest
  static void testGetCredentialDependencies() {
    Set<Id> vendorCustomizationIds = new Set<Id>{
      [SELECT Id FROM Vendor_Customization__c LIMIT 1]
      .Id
    };

    Test.startTest();
    Map<String, Set<String>> deps = ContactECCController.getCredentialDependencies(
      vendorCustomizationIds
    );
    Test.stopTest();

    System.assertNotEquals(0, deps.size(), 'Dependencies should not be empty');
  }
}
