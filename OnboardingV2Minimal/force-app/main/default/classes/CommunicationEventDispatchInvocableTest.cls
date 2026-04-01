@isTest
private class CommunicationEventDispatchInvocableTest {

  @isTest
  static void dispatch_returnsEmptyForNullOrEmptyInput() {
    Test.startTest();
    List<CommunicationEventDispatchInvocable.DispatchResult> nullResults =
      CommunicationEventDispatchInvocable.dispatch(null);
    List<CommunicationEventDispatchInvocable.DispatchResult> emptyResults =
      CommunicationEventDispatchInvocable.dispatch(
        new List<CommunicationEventDispatchInvocable.DispatchRequest>()
      );
    Test.stopTest();

    System.assertEquals(0, nullResults.size());
    System.assertEquals(0, emptyResults.size());
  }

  @isTest
  static void dispatch_returnsDiagnosticWhenEventPolicyMissing() {
    Account account = TestDataFactory.createAccount('Missing Event Policy Account', true);
    Contact contact = TestDataFactory.createContact('No', 'Policy', true, account);

    CommunicationEventDispatchInvocable.DispatchRequest request =
      new CommunicationEventDispatchInvocable.DispatchRequest();
    request.eventKey = 'EventKeyThatDoesNotExist';
    request.recipientIds = new List<String>{ contact.Id };

    Test.startTest();
    List<CommunicationEventDispatchInvocable.DispatchResult> results =
      CommunicationEventDispatchInvocable.dispatch(
        new List<CommunicationEventDispatchInvocable.DispatchRequest>{ request }
      );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals(false, results[0].ranSuccessfully);
    System.assert(
      results[0].diagnosticMessage != null &&
      results[0].diagnosticMessage.contains('No active event policy rows found')
    );
  }

  @isTest
  static void dispatch_resolvesAccountRecipientsAndAssignedTemplates() {
    Account account = TestDataFactory.createAccount('Comm Dispatch Account', true);
    Contact contact = TestDataFactory.createContact('Flow', 'Recipient', true, account);

    Vendor__c vendor = TestDataFactory.createVendor(true);
    Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
      vendor,
      'Active',
      true,
      null,
      true
    );

    Communication_Template__c template = TestDataFactory.createCommunicationTemplate(true, false);
    template.Communication_Type__c = 'Welcome';
    template.Recipient_Type__c = 'Contact';
    // Intentionally unset Email_Template_Id__c so bulk-send returns deterministic validation failure.
    insert template;

    insert new Communication_Template_Assignment__c(
      Vendor_Program__c = vendorProgram.Id,
      Communication_Template__c = template.Id,
      Active__c = true
    );

    CommunicationEventDispatchInvocable.DispatchRequest request =
      new CommunicationEventDispatchInvocable.DispatchRequest();
    request.eventKey = 'SetupComplete';
    request.vendorProgramId = vendorProgram.Id;
    request.recipientType = 'Contact';
    request.accountIds = new List<String>{ account.Id };

    Test.startTest();
    List<CommunicationEventDispatchInvocable.DispatchResult> results =
      CommunicationEventDispatchInvocable.dispatch(
        new List<CommunicationEventDispatchInvocable.DispatchRequest>{ request }
      );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals(1, results[0].resolvedRecipientCount, 'Account expansion should resolve one contact.');
    System.assertEquals(1, results[0].resolvedTemplateCount, 'Template assignment should resolve one template.');
    System.assertEquals(false, results[0].ranSuccessfully, 'Missing Email_Template_Id__c should fail send.');
    System.assert(results[0].failedCount > 0);
  }
}
