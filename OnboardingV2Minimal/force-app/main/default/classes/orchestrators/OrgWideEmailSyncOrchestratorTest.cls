@isTest
private class OrgWideEmailSyncOrchestratorTest {
  @isTest
  static void testRunFullSync_success() {
    // MOCK DATA SETUP
    OrgWideEmailDTO orgWideEmailDTO = new OrgWideEmailDTO();
    orgWideEmailDTO.developerName = 'mock_dev';
    orgWideEmailDTO.emailAddress = 'test@example.com';
    orgWideEmailDTO.masterLabel = 'Test Sender';
    orgWideEmailDTO.isActive = true;

    EmailSyncDomainService.setMockDtos(
      new List<OrgWideEmailDTO>{ orgWideEmailDTO }
    );

    // MOCK CMDT (using actual metadata type name)
    OrgWideEmailCMDTRepository.setMockCatalogs(
      new Map<String, Org_Wide_Email__mdt>()
    );

    Test.startTest();
    EmailSyncDomainService.runOrgWideEmailSync(true);
    Test.stopTest();

    // VERIFY SUCCESS LOG
    Sync_Log__c syncLog = [SELECT Id, Status__c FROM Sync_Log__c LIMIT 1];
    System.assertEquals(
      'Success',
      syncLog.Status__c,
      'Log should indicate success'
    );
  }

  @isTest
  static void testRunFullSync_failure() {
    // 💣 Simulate failure with invalid data
    OrgWideEmailDTO orgWideEmailDTO = new OrgWideEmailDTO();
    orgWideEmailDTO.developerName = null; // Null dev name will cause DML error

    EmailSyncDomainService.setMockDtos(
      new List<OrgWideEmailDTO>{ orgWideEmailDTO }
    );

    Test.startTest();
    EmailSyncDomainService.runOrgWideEmailSync(false);
    Test.stopTest();

    // ✅ Verify failure log
    Sync_Log__c syncLog = [
      SELECT Id, Status__c, Error_Message__c
      FROM Sync_Log__c
      LIMIT 1
    ];
    System.assertEquals(
      'Failed',
      syncLog.Status__c,
      'Log should indicate failure'
    );
    System.assertNotEquals(
      null,
      syncLog.Error_Message__c,
      'Error message should be recorded'
    );
  }
}
