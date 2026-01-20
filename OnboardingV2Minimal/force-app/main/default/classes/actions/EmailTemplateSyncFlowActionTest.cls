@isTest
private class EmailTemplateSyncFlowActionTest {

    @isTest
    static void testRunFullSync() {
        EmailTemplateSyncFlowAction.Request syncRequest = new EmailTemplateSyncFlowAction.Request();
        syncRequest.runAsManual = true;

        Test.startTest();
        List<EmailTemplateSyncFlowAction.Result> results =
            EmailTemplateSyncFlowAction.run(new List<EmailTemplateSyncFlowAction.Request>{ syncRequest });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one result object');
        System.assert(results[0].message.contains('Sync completed'), 'Expected success message');
    }
}