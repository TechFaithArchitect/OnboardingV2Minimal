@isTest
private class EmailTemplateSyncServiceTest {

  @isTest
  static void testSyncAllTemplates_success() {
    EmailTemplateSyncService.EmailTemplateDTO emailTemplateDTO =
      new EmailTemplateSyncService.EmailTemplateDTO();
    emailTemplateDTO.name = 'Welcome_Email';
    emailTemplateDTO.developerName = 'Welcome_Email';
    emailTemplateDTO.subject = 'Welcome!';
    emailTemplateDTO.folder = 'Mock Folder';
    emailTemplateDTO.isActive = true;
    emailTemplateDTO.commType = 'Welcome';
    emailTemplateDTO.templateId = UserInfo.getUserId();

    EmailTemplateSyncService.setMockDtosForTest(
      new List<EmailTemplateSyncService.EmailTemplateDTO>{ emailTemplateDTO }
    );
    EmailTemplateSyncService.setMockTemplatesForTest(
      new Map<String, Communication_Template__c>{
        'Welcome_Email' => new Communication_Template__c(
          Name = 'Welcome_Email',
          DeveloperName__c = 'Welcome_Email',
          Email_Subject__c = 'Old Subject',
          Communication_Type__c = 'Welcome',
          Active__c = false
        )
      }
    );

    Test.startTest();
    EmailTemplateSyncService service = new EmailTemplateSyncService();
    EmailTemplateSyncService.EmailSyncSummaryDTO summary = service.syncAllTemplates(null);
    Test.stopTest();

    System.assertNotEquals(null, summary, 'Summary should not be null');
    System.assertEquals(1, summary.updatedCount, 'Expected one template update.');
    System.assertEquals(0, summary.insertedCount, 'Expected no inserts in update scenario.');
    EmailTemplateSyncService.resetTestState();
  }

  @isTest
  static void testSyncAllTemplates_handlesEmpty() {
    EmailTemplateSyncService.setMockDtosForTest(
      new List<EmailTemplateSyncService.EmailTemplateDTO>()
    );
    EmailTemplateSyncService.setMockTemplatesForTest(
      new Map<String, Communication_Template__c>()
    );

    Test.startTest();
    EmailTemplateSyncService service = new EmailTemplateSyncService();
    EmailTemplateSyncService.EmailSyncSummaryDTO summary = service.syncAllTemplates(null);
    Test.stopTest();

    System.assertNotEquals(null, summary, 'Summary should not be null');
    System.assertEquals(0, summary.insertedCount, 'Expected 0 inserted templates');
    System.assertEquals(0, summary.updatedCount, 'Expected 0 updated templates');
    System.assertEquals(0, summary.newCMDTCount, 'Expected 0 new CMDT entries');
    EmailTemplateSyncService.resetTestState();
  }
}
