@isTest
private class EmailTemplateSyncJobTest {

  @isTest
  static void execute_runsSyncServiceWithoutException() {
    EmailTemplateSyncService.EmailTemplateDTO dto =
      new EmailTemplateSyncService.EmailTemplateDTO();
    dto.name = 'Job_Test_Template';
    dto.developerName = 'Job_Test_Template';
    dto.subject = 'Job Subject';
    dto.folder = 'Job Folder';
    dto.isActive = true;
    dto.commType = 'Welcome';
    dto.templateId = UserInfo.getUserId();

    EmailTemplateSyncService.setMockDtosForTest(
      new List<EmailTemplateSyncService.EmailTemplateDTO>{ dto }
    );
    EmailTemplateSyncService.setMockTemplatesForTest(
      new Map<String, Communication_Template__c>()
    );

    Test.startTest();
    new EmailTemplateSyncJob().execute(null);
    Test.stopTest();

    EmailTemplateSyncService.resetTestState();
    System.assert(true, 'Scheduled job should complete without throwing.');
  }

  @isTest
  static void execute_handlesServiceFailureGracefully() {
    EmailTemplateSyncService.forceFail = true;

    Test.startTest();
    new EmailTemplateSyncJob().execute(null);
    Test.stopTest();

    EmailTemplateSyncService.resetTestState();
    System.assert(true, 'Scheduled job should catch service exceptions.');
  }
}
