@IsTest
private class OnboardingAccessServiceTest {

    @IsTest
    static void testGetUserIdsForViewFilter_myView() {
        Test.startTest();
        Set<Id> ids = OnboardingAccessService.getUserIdsForViewFilter('MY_VIEW');
        Test.stopTest();

        System.assertEquals(1, ids.size(), 'MY_VIEW should only return the current user');
        System.assert(ids.contains(UserInfo.getUserId()), 'Current user should be included');
    }

    @IsTest
    static void testGetUserIdsForViewFilter_myView_default() {
        Test.startTest();
        Set<Id> ids = OnboardingAccessService.getUserIdsForViewFilter(null);
        Test.stopTest();

        System.assertEquals(1, ids.size(), 'Null filter should default to MY_VIEW');
        System.assert(ids.contains(UserInfo.getUserId()), 'Current user should be included');
    }

    @IsTest
    static void testGetUserIdsForViewFilter_myView_blank() {
        Test.startTest();
        Set<Id> ids = OnboardingAccessService.getUserIdsForViewFilter('');
        Test.stopTest();

        System.assertEquals(1, ids.size(), 'Blank filter should default to MY_VIEW');
        System.assert(ids.contains(UserInfo.getUserId()), 'Current user should be included');
    }

    @IsTest
    static void testGetUserIdsForViewFilter_orgWide() {
        Test.startTest();
        Set<Id> ids = OnboardingAccessService.getUserIdsForViewFilter('ORG_WIDE');
        Test.stopTest();

        System.assertEquals(0, ids.size(), 'ORG_WIDE should return an empty set (no owner filter)');
    }

    @IsTest
    static void testGetAccountIdsForOwners_accountOwner() {
        User testUser = TestDataFactory.createStandardUser(true);
        Account testAccount = TestDataFactory.createAccount('Test Account', false);
        testAccount.OwnerId = testUser.Id;
        insert testAccount;

        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser.Id });
        Test.stopTest();

        System.assertEquals(1, accountIds.size(), 'Should return 1 account');
        System.assert(accountIds.contains(testAccount.Id), 'Should include the owned account');
    }

    @IsTest
    static void testGetAccountIdsForOwners_multipleAccounts() {
        User testUser = TestDataFactory.createStandardUser(true);
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account acc = TestDataFactory.createAccount('Test Account ' + i, false);
            acc.OwnerId = testUser.Id;
            accounts.add(acc);
        }
        insert accounts;

        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>{ testUser.Id });
        Test.stopTest();

        System.assertEquals(5, accountIds.size(), 'Should return 5 accounts');
        for (Account acc : accounts) {
            System.assert(accountIds.contains(acc.Id), 'Should include account: ' + acc.Name);
        }
    }

    @IsTest
    static void testGetAccountIdsForOwners_emptyUserSet() {
        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, accountIds.size(), 'Empty user set should return empty account set');
    }

    @IsTest
    static void testGetAccountIdsForOwners_nullUserSet() {
        Test.startTest();
        Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(null);
        Test.stopTest();

        System.assertEquals(0, accountIds.size(), 'Null user set should return empty account set');
    }

    @IsTest
    static void testBuildOwnerClause_emptySet() {
        Test.startTest();
        String clause = OnboardingAccessService.buildOwnerClauseForOnboarding(new Set<Id>());
        Test.stopTest();

        System.assertEquals('', clause, 'Empty user set should return empty clause');
    }

    @IsTest
    static void testBuildOwnerClause_nonEmpty() {
        Set<Id> ids = new Set<Id>{ UserInfo.getUserId() };

        Test.startTest();
        String clause = OnboardingAccessService.buildOwnerClauseForOnboarding(ids);
        Test.stopTest();

        System.assertNotEquals('', clause, 'Non-empty user set should return a clause');
        System.assert(clause.contains('Account__r.OwnerId'), 'Clause should reference Account__r.OwnerId');
    }
}
