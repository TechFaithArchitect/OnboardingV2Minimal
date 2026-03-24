@IsTest
private class RecordCollectionEditorGetRecordsTest {
    @IsTest
    static void getRecordsJsonForEditor_contactOnOpportunity_happyPath() {
        Account acc = TestAccountFactory.create('RCE_Happy', true);
        Contact con = new Contact(LastName = 'RCE', AccountId = acc.Id);
        insert con;

        RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest req = new RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest();
        req.configKey = 'CONTACT_ON_OPPORTUNITY';
        req.records = new List<SObject>{ con };

        Test.startTest();
        List<RecordCollectionEditorGetRecordsService.GetRecordsJsonResult> results =
            RecordCollectionEditorGetRecordsService.getRecordsJsonForEditor(
                new List<RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(String.isBlank(results[0].errorMessage), results[0].errorMessage);
        System.assert(String.isNotBlank(results[0].recordsJson), 'Expected JSON payload.');
    }

    @IsTest
    static void getRecordsJsonForEditor_forcedException_writesErrorLog() {
        Account acc = TestAccountFactory.create('RCE_ErrLog', true);
        Contact con = new Contact(LastName = 'RCE', AccountId = acc.Id);
        insert con;

        RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest req = new RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest();
        req.configKey = 'CONTACT_ON_OPPORTUNITY';
        req.records = new List<SObject>{ con };

        RecordCollectionEditorGetRecordsService.forceOuterExceptionForTest = true;
        try {
            Test.startTest();
            List<RecordCollectionEditorGetRecordsService.GetRecordsJsonResult> results =
                RecordCollectionEditorGetRecordsService.getRecordsJsonForEditor(
                    new List<RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest>{ req }
                );
            Test.stopTest();

            System.assertEquals(1, results.size());
            System.assert(
                results[0].errorMessage != null && results[0].errorMessage.contains('Error Log Id:'),
                'Expected durable log id in user message: ' + results[0].errorMessage
            );
        } finally {
            RecordCollectionEditorGetRecordsService.forceOuterExceptionForTest = false;
        }
    }
}
