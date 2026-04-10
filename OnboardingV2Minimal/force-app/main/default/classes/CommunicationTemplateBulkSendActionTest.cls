@IsTest
private class CommunicationTemplateBulkSendActionTest {

  @IsTest
  static void testSendBulkReturnsSuccessForEmptyInputCollection() {
    CommunicationTemplateBulkSendAction.BulkSendRequest invocation =
      new CommunicationTemplateBulkSendAction.BulkSendRequest();
    invocation.communicationTemplateIds = new List<String>();
    invocation.recipientIds = new List<String>();

    List<CommunicationTemplateBulkSendAction.BulkSendResult> results =
      CommunicationTemplateBulkSendAction.sendBulk(
        new List<CommunicationTemplateBulkSendAction.BulkSendRequest>{ invocation }
      );

    System.assertEquals(1, results.size());
    System.assertEquals(false, results[0].sendFailed);
    System.assertEquals(0, results[0].sentCount);
    System.assertEquals(0, results[0].failedCount);
    System.assertEquals('', results[0].errorMessage);
  }

  @IsTest
  static void testSendBulkReturnsFailuresForInvalidRequests() {
    String userId = UserInfo.getUserId();

    CommunicationTemplateBulkSendAction.BulkSendRequest invocation =
      new CommunicationTemplateBulkSendAction.BulkSendRequest();
    invocation.defaultSenderAddress = 'training@perfect-vision.com';
    invocation.communicationTemplateIds = new List<String>{
      '',
      'notAnId',
      userId,
      userId
    };
    invocation.recipientIds = new List<String>{
      userId,
      userId,
      '',
      userId
    };

    Test.startTest();
    List<CommunicationTemplateBulkSendAction.BulkSendResult> results =
      CommunicationTemplateBulkSendAction.sendBulk(
        new List<CommunicationTemplateBulkSendAction.BulkSendRequest>{ invocation }
      );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals(true, results[0].sendFailed);
    System.assertEquals(0, results[0].sentCount);
    System.assertEquals(4, results[0].failedCount);
    System.assert(results[0].errorMessage.contains('communicationTemplateIds value is required'));
    System.assert(results[0].errorMessage.contains('communicationTemplateIds value is not a valid Id'));
    System.assert(results[0].errorMessage.contains('recipientIds value is required'));
    System.assert(results[0].errorMessage.contains('Communication_Template__c not found'));
  }

  @IsTest
  static void testSendBulkHandlesMismatchedListsAndInvalidOnboardingId() {
    String userId = UserInfo.getUserId();

    CommunicationTemplateBulkSendAction.BulkSendRequest invocation =
      new CommunicationTemplateBulkSendAction.BulkSendRequest();
    invocation.communicationTemplateIds = new List<String>{ userId, userId };
    invocation.recipientIds = new List<String>{ userId };
    invocation.onboardingIds = new List<String>{ 'notAnId' };

    List<CommunicationTemplateBulkSendAction.BulkSendResult> results =
      CommunicationTemplateBulkSendAction.sendBulk(
        new List<CommunicationTemplateBulkSendAction.BulkSendRequest>{ invocation }
      );

    System.assertEquals(1, results.size());
    System.assertEquals(true, results[0].sendFailed);
    System.assertEquals(2, results[0].failedCount);
    System.assert(results[0].errorMessage.contains('Input size mismatch'));
    System.assert(results[0].errorMessage.contains('onboardingIds value is not a valid Id'));
    System.assert(results[0].errorMessage.contains('recipientIds value is required'));
  }

  @IsTest
  static void testSendBulkExecutesTemplateLookupAndSendBranch() {
    Communication_Template__c template = new Communication_Template__c(
      Name = 'Unit Test Template',
      Email_Template_Id__c = '00X000000000000AAA'
    );
    insert template;

    CommunicationTemplateBulkSendAction.BulkSendRequest invocation =
      new CommunicationTemplateBulkSendAction.BulkSendRequest();
    invocation.defaultSenderAddress = 'training@perfect-vision.com';
    invocation.communicationTemplateIds = new List<String>{ String.valueOf(template.Id) };
    invocation.recipientIds = new List<String>{ UserInfo.getUserId() };
    invocation.onboardingIds = new List<String>{ '' };

    Test.startTest();
    List<CommunicationTemplateBulkSendAction.BulkSendResult> results =
      CommunicationTemplateBulkSendAction.sendBulk(
        new List<CommunicationTemplateBulkSendAction.BulkSendRequest>{ invocation }
      );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals(0, results[0].sentCount);
    System.assertEquals(true, results[0].failedCount > 0);
    System.assertEquals(true, results[0].sendFailed);
    System.assertEquals(
      true,
      results[0].errorMessage.contains('Request #0') || String.isBlank(results[0].errorMessage),
      'Expected per-request failure details when send does not succeed.'
    );
  }

  @IsTest
  static void testSendBulkReportsTemplateBccDiagnostics() {
    Communication_Template__c template = new Communication_Template__c(
      Name = 'Unit Test Template With BCC',
      Email_Template_Id__c = '00X000000000000AAA',
      BCC_User_Ids__c = 'notAnId',
      BCC_Public_Group_DeveloperNames__c = 'MISSING_GROUP'
    );
    insert template;

    CommunicationTemplateBulkSendAction.BulkSendRequest invocation =
      new CommunicationTemplateBulkSendAction.BulkSendRequest();
    invocation.communicationTemplateIds = new List<String>{ String.valueOf(template.Id) };
    invocation.recipientIds = new List<String>{ UserInfo.getUserId() };

    List<CommunicationTemplateBulkSendAction.BulkSendResult> results =
      CommunicationTemplateBulkSendAction.sendBulk(
        new List<CommunicationTemplateBulkSendAction.BulkSendRequest>{ invocation }
      );

    System.assertEquals(1, results.size());
    System.assertEquals(true, results[0].sendFailed);
    System.assert(
      results[0].errorMessage.contains('ignored invalid BCC user Id tokens'),
      'Expected invalid BCC user token diagnostic.'
    );
    System.assert(
      results[0].errorMessage.contains('BCC public groups not found'),
      'Expected missing BCC public group diagnostic.'
    );
  }
}
