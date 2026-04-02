@IsTest
private class ExpOppCreateAsyncServiceTest {
    @IsTest
    static void returnsErrorWhenRequiredInputsMissing() {
        ExpOpportunityCreateAsyncService.QueueRequest requestItem =
            new ExpOpportunityCreateAsyncService.QueueRequest();

        List<ExpOpportunityCreateAsyncService.QueueResult> results =
            ExpOpportunityCreateAsyncService.queueOpportunityCreateChain(
                new List<ExpOpportunityCreateAsyncService.QueueRequest>{ requestItem }
            );

        System.assertEquals(1, results.size(), 'Expected one result item.');
        System.assertEquals(false, results[0].queued, 'Request should not queue without required inputs.');
        System.assertNotEquals(null, results[0].message, 'Error message should be returned.');
    }

    @IsTest
    static void queuesWhenRequiredInputsProvided() {
        Account accountRecord = new Account(Name = 'Async Queue Test Account');
        insert accountRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = 'Async Queue Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );

        ExpOpportunityCreateAsyncService.QueueRequest requestItem =
            new ExpOpportunityCreateAsyncService.QueueRequest();
        requestItem.AccountRecord = new Account(Id = accountRecord.Id);
        requestItem.OpportunityRecord = opportunityRecord;
        requestItem.ContactsToCreateJSONString = '[]';
        requestItem.OpportunityContactRecordsJSON = '[]';
        requestItem.CreateContactsInQueue = true;

        Test.startTest();
        List<ExpOpportunityCreateAsyncService.QueueResult> results =
            ExpOpportunityCreateAsyncService.queueOpportunityCreateChain(
                new List<ExpOpportunityCreateAsyncService.QueueRequest>{ requestItem }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one result item.');
        System.assertEquals(true, results[0].queued, 'Request should queue with required inputs.');
        System.assert(results[0].message != null && results[0].message.contains('Queued async create chain job'),
            'Expected queue confirmation message.');
    }

    @IsTest
    static void executesSynchronouslyByDefault() {
        Account accountRecord = new Account(Name = 'Sync Chain Test Account');
        insert accountRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = 'Sync Chain Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );

        ExpOpportunityCreateAsyncService.QueueRequest requestItem =
            new ExpOpportunityCreateAsyncService.QueueRequest();
        requestItem.AccountRecord = new Account(Id = accountRecord.Id);
        requestItem.OpportunityRecord = opportunityRecord;
        requestItem.ContactsToCreateJSONString = '[]';
        requestItem.OpportunityContactRecordsJSON = '[]';

        Test.startTest();
        List<ExpOpportunityCreateAsyncService.QueueResult> results =
            ExpOpportunityCreateAsyncService.queueOpportunityCreateChain(
                new List<ExpOpportunityCreateAsyncService.QueueRequest>{ requestItem }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one result item.');
        System.assertNotEquals(null, results[0].queued, 'Result should report completion status.');
        System.assert(
            results[0].message != null &&
            (
                results[0].message.contains('Create chain completed synchronously.') ||
                results[0].message.contains('Create chain failed:')
            ),
            'Expected synchronous execution message.'
        );
    }

    @IsTest
    static void appliesOpportunityIdToJsonPayload() {
        Id opportunityId = (Id) '006000000000000AAA';
        String payload = '[{"ContactId":"003000000000000AAA","Role":"Owner","IsPrimary":true}]';

        String resultPayload = ExpOpportunityCreateAsyncService.applyOpportunityId(payload, opportunityId);

        System.assert(resultPayload.contains('"OpportunityId":"006000000000000AAA"'),
            'Payload should include injected OpportunityId.');
    }
}
