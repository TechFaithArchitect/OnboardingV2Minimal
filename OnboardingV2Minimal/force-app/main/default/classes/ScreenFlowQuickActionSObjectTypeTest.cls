@isTest
private class ScreenFlowQuickActionSObjectTypeTest {
    @isTest
    static void testGetTypesReturnsSObjectType() {
        Account acct = TestAccountFactory.create('Screen Flow QA Test', true);

        Test.startTest();
        List<ScreenFlowQuickActionSObjectType.Result> results =
            ScreenFlowQuickActionSObjectType.getTypes(new List<Id>{ acct.Id });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one result');
        ScreenFlowQuickActionSObjectType.Result result = results[0];
        System.assertEquals(true, result.success, 'Expected success for valid Id');
        System.assertEquals('Account', result.sObjectTypeName);
        System.assertEquals(null, result.errorMessage);
    }

    @isTest
    static void testGetTypesHandlesNullId() {
        List<ScreenFlowQuickActionSObjectType.Result> results =
            ScreenFlowQuickActionSObjectType.getTypes(new List<Id>{ null });

        System.assertEquals(1, results.size(), 'Expected one result');
        ScreenFlowQuickActionSObjectType.Result result = results[0];
        System.assertEquals(false, result.success, 'Expected failure for null Id');
        System.assertEquals(null, result.sObjectTypeName);
        System.assertEquals('Record Id is null.', result.errorMessage);
    }

    @isTest
    static void testGetTypesHandlesNullList() {
        List<ScreenFlowQuickActionSObjectType.Result> results =
            ScreenFlowQuickActionSObjectType.getTypes(null);

        System.assertEquals(0, results.size(), 'Expected empty results for null list');
    }
}
