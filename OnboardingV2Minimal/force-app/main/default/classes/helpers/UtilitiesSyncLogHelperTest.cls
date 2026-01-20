@isTest
private class UtilitiesSyncLogHelperTest {

    @isTest
    static void testCreateAndUpdateLog() {
        Test.startTest();
        Sync_Log__c syncLog = UtilitiesSyncLogHelper.createLogRecord('Test Job', true);

        EmailSyncSummaryDTO emailSyncSummaryDTO = new EmailSyncSummaryDTO();
        emailSyncSummaryDTO.durationSeconds = 5;
        emailSyncSummaryDTO.insertedCount = 1;
        emailSyncSummaryDTO.updatedCount = 2;
        emailSyncSummaryDTO.newCMDTCount = 3;

        UtilitiesSyncLogHelper.updateLogRecord(syncLog.Id, emailSyncSummaryDTO);
        Test.stopTest();

        Sync_Log__c updatedSyncLog = [SELECT Status__c, Inserted_Count__c FROM Sync_Log__c WHERE Id = :syncLog.Id];
        System.assertEquals('Success', updatedSyncLog.Status__c);
        System.assertEquals(1, updatedSyncLog.Inserted_Count__c);
    }

    @isTest
    static void testMarkFailed() {
        Sync_Log__c syncLog = UtilitiesSyncLogHelper.createLogRecord('Fail Job', false);
        Test.startTest();
        UtilitiesSyncLogHelper.markFailed(syncLog.Id, new DmlException('Simulated failure'));
        Test.stopTest();

        Sync_Log__c failedSyncLog = [SELECT Status__c, Error_Message__c FROM Sync_Log__c WHERE Id = :syncLog.Id];
        System.assertEquals('Failed', failedSyncLog.Status__c);
        System.assert(failedSyncLog.Error_Message__c.contains('Simulated failure'));
    }
}