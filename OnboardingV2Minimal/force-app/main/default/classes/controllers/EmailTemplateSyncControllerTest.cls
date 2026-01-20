@isTest
private class EmailTemplateSyncControllerTest {
    @isTest
    static void testScheduledExecution() {
        
        Test.startTest();
        EmailTemplateSyncController controller = new EmailTemplateSyncController();
        controller.execute(null);
        Test.stopTest();

        List<Sync_Log__c> logs = [SELECT Id FROM Sync_Log__c];
        System.assert(!logs.isEmpty(), 'Log should exist after scheduled run');
    }
}