@IsTest
private class RecordCollectionEditorAsyncServiceTest {
    @IsTest
    static void queueRecordCollectionDml_queuesJob() {
        RecordCollectionEditorAsyncService.QueueRequest requestItem =
            new RecordCollectionEditorAsyncService.QueueRequest();
        requestItem.configKey = 'CONTACT_ON_ACCOUNT';
        requestItem.recordsJson = '[]';

        Test.startTest();
        List<RecordCollectionEditorAsyncService.QueueResult> results =
            RecordCollectionEditorAsyncService.queueRecordCollectionDml(
                new List<RecordCollectionEditorAsyncService.QueueRequest>{ requestItem }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one result item.');
        System.assertEquals('Queued', results[0].status, 'Expected queued status.');
        System.assertNotEquals(null, results[0].jobId, 'Queue job id should be set.');
    }

    @IsTest
    static void queueRecordCollectionDml_rejectsInvalidRequest() {
        RecordCollectionEditorAsyncService.QueueRequest requestItem =
            new RecordCollectionEditorAsyncService.QueueRequest();
        requestItem.configKey = 'CONTACT_ON_ACCOUNT';
        requestItem.recordsJson = null;

        List<RecordCollectionEditorAsyncService.QueueResult> results =
            RecordCollectionEditorAsyncService.queueRecordCollectionDml(
                new List<RecordCollectionEditorAsyncService.QueueRequest>{ requestItem }
            );

        System.assertEquals(1, results.size(), 'Expected one result item.');
        System.assertEquals('InvalidRequest', results[0].status, 'Expected invalid request status.');
    }
}