@isTest
public class RecipientGroupEmailOrchestratorTest {
  private static void setupRecipientGroupWithUser(
    Id vendorProgramId,
    Id userId
  ) {
    Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(
      true,
      true
    );
    User user = [SELECT Id FROM User WHERE Id = :userId];

    Vendor_Customization__c vendorProgram = [
      SELECT Id
      FROM Vendor_Customization__c
      WHERE Id = :vendorProgramId
    ];
    TestDataFactory.createVendorProgramRecipientGroup(
      vendorProgram,
      recipientGroup,
      true
    );

    TestDataFactory.createRecipientGroupMember(true, recipientGroup, user);
  }

  @isTest
  static void testGetEmails() {
    // CREATE DATA
    User standardUser = TestDataFactory.createStandardUser(true);
    Vendor__c vendor = TestDataFactory.createVendor(true);
    Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(
      vendor,
      true
    );

    setupRecipientGroupWithUser(vendorProgram.Id, standardUser.Id);

    // ACTIVATE
    List<String> emails = RecipientGroupEmailService.getEmails(
      vendorProgram.Id
    );

    // ASSERT
    System.assertEquals(1, emails.size(), 'Expected one email address');
    System.assertEquals(
      standardUser.Email,
      emails[0],
      'Email should match the user'
    );
  }

  @isTest
  static void testOrchestratorCallsService() {
    // CREATE DATA
    User user = TestDataFactory.createStandardUser(true);
    Vendor__c vendor = TestDataFactory.createVendor(true);
    Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(
      vendor,
      true
    );

    setupRecipientGroupWithUser(vendorProgram.Id, user.Id);

    // ACTIVATE
    Test.startTest();
    List<String> emails = RecipientGroupEmailService.getEmails(
      vendorProgram.Id
    );
    Test.stopTest();

    // ASSERT
    System.assertEquals(
      1,
      emails.size(),
      'Orchestrator should return one email'
    );
    System.assertEquals(
      user.Email,
      emails[0],
      'Email should match the expected user'
    );
  }
}
