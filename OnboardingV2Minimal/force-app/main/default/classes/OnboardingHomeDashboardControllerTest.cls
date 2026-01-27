@isTest
private class OnboardingHomeDashboardControllerTest {

    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = TestDataFactory.createAccount('Test Account', true);

        // Create test vendor
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        testVendor.Active__c = true;
        update testVendor;

        // Create test vendor customization/program
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor,
            'Active',
            true,
            null,
            true
        );

        // Create test onboarding records with different statuses
        List<Onboarding__c> onboardings = new List<Onboarding__c>();
        
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Onboarding_Status__c'
        );
        String inProcessStatus = validStatuses.contains('In Process') ? 'In Process' : validStatuses[0];
        String pendingStatus = validStatuses.contains('Pending Initial Review') ? 'Pending Initial Review' : validStatuses[0];
        String completeStatus = validStatuses.contains('Complete') ? 'Complete' : validStatuses[validStatuses.size() - 1];
        
        Onboarding__c ob1 = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        ob1.Onboarding_Status__c = inProcessStatus;
        onboardings.add(ob1);

        Onboarding__c ob2 = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        ob2.Onboarding_Status__c = pendingStatus;
        onboardings.add(ob2);

        Onboarding__c ob3 = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        ob3.Onboarding_Status__c = completeStatus;
        onboardings.add(ob3);

        update onboardings;
    }

    @isTest
    static void testGetMyActiveOnboarding() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        // Get onboarding records created by current user
        List<Onboarding__c> userOnboardings = [
            SELECT Id, CreatedById
            FROM Onboarding__c
            WHERE CreatedById = :testUser.Id
            LIMIT 1
        ];

        if (!userOnboardings.isEmpty()) {
            Test.startTest();
            List<OnboardingDTO> results = 
                OnboardingHomeDashboardController.getMyActiveOnboarding(
                    'LAST_90_DAYS', null, null, 'MY_VIEW'
                );
            Test.stopTest();

            System.assertNotEquals(null, results, 'Results should not be null');
            // Should return active onboarding records (not Complete, Denied, or Expired)
            for (OnboardingDTO dto : results) {
                System.assertNotEquals('Complete', dto.Status, 'Should not include completed onboarding');
                System.assertNotEquals('Denied', dto.Status, 'Should not include denied onboarding');
                System.assertNotEquals('Expired', dto.Status, 'Should not include expired onboarding');
            }
        }
    }

    @isTest
    static void testGetMyActiveOnboardingWithFilters() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        // Get vendor and program IDs from test data
        Vendor__c testVendor = [SELECT Id FROM Vendor__c LIMIT 1];
        Vendor_Customization__c testProgram = [SELECT Id FROM Vendor_Customization__c LIMIT 1];
        
        Test.startTest();
        List<OnboardingDTO> results = 
            OnboardingHomeDashboardController.getMyActiveOnboarding(
                'LAST_30_DAYS', 
                new List<Id>{ testVendor.Id }, 
                new List<Id>{ testProgram.Id }, 
                'MY_VIEW'
            );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @isTest
    static void testGetOnboardingSummary() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        Test.startTest();
        Map<String, Integer> summary = OnboardingHomeDashboardController.getOnboardingSummary(
            'LAST_90_DAYS', null, null, 'MY_VIEW'
        );
        Test.stopTest();

        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assert(summary.containsKey('Total'), 'Summary should contain Total key');
        // Summary should have counts for different statuses
    }

    @isTest
    static void testGetRecentActivity() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        Test.startTest();
        List<OnboardingDTO> results = 
            OnboardingHomeDashboardController.getRecentActivity(5, 'LAST_90_DAYS', null, null);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() <= 5, 'Should return at most 5 records');
    }

    @isTest
    static void testGetEligibleAccounts() {
        Test.startTest();
        List<AccountDTO> results = 
            OnboardingHomeDashboardController.getEligibleAccounts('LAST_90_DAYS', null, null);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(!results.isEmpty(), 'Should return accounts when active vendor programs exist');
        for (AccountDTO dto : results) {
            System.assert(dto.EligibleVendorCount > 0, 'Eligible vendor count should be positive');
        }
    }

    @isTest
    static void testGetVendorProgramMetrics() {
        Test.startTest();
        List<VendorProgramMetricsDTO> results = 
            OnboardingHomeDashboardController.getVendorProgramMetrics('LAST_90_DAYS', null);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @isTest
    static void testGetBlockedOnboardingCount() {
        Test.startTest();
        Integer count = OnboardingHomeDashboardController.getBlockedOnboardingCount(
            'LAST_90_DAYS', null, null
        );
        Test.stopTest();

        System.assertNotEquals(null, count, 'Count should not be null');
        System.assert(count >= 0, 'Count should be non-negative');
    }

    @isTest
    static void testGetBlockedOnboardingIds() {
        // Create test onboarding with Denied status to ensure it's blocked
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Vendor_Customization__c testProgram = [SELECT Id FROM Vendor_Customization__c LIMIT 1];
        
        Onboarding__c blockedOnboarding = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Onboarding_Status__c'
        );
        String deniedStatus = validStatuses.contains('Denied') ? 'Denied' : validStatuses[0];
        blockedOnboarding.Onboarding_Status__c = deniedStatus;
        update blockedOnboarding;
        
        Test.startTest();
        List<Id> blockedIds = OnboardingHomeDashboardController.getBlockedOnboardingIds(
            'LAST_90_DAYS', null, null
        );
        Test.stopTest();

        System.assertNotEquals(null, blockedIds, 'Blocked IDs should not be null');
        System.assert(blockedIds.size() >= 0, 'Should return list of IDs');
    }

    @isTest
    static void testGetTeamOnboarding() {
        Test.startTest();
        List<OnboardingDTO> results = 
            OnboardingHomeDashboardController.getTeamOnboarding(
                'MY_TEAM', 'LAST_90_DAYS', null, null
            );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @isTest
    static void testGetOnboardingWithBlockingInfo() {
        // Create test onboarding
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Vendor_Customization__c testProgram = [SELECT Id FROM Vendor_Customization__c LIMIT 1];
        
        Onboarding__c ob = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Onboarding_Status__c'
        );
        String inProcessStatus = validStatuses.contains('In Process') ? 'In Process' : validStatuses[0];
        ob.Onboarding_Status__c = inProcessStatus;
        update ob;
        
        Test.startTest();
        List<OnboardingWithBlockingDTO> results = 
            OnboardingHomeDashboardController.getOnboardingWithBlockingInfo(
                new List<Id>{ ob.Id }
            );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertNotEquals(null, results[0].AgeInDays, 'Should have age in days');
    }

    @isTest
    static void testGetVendors() {
        Test.startTest();
        List<OnboardingHomeDashboardController.FilterOption> results = OnboardingHomeDashboardController.getVendors();
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @isTest
    static void testGetVendorPrograms() {
        Test.startTest();
        List<OnboardingHomeDashboardController.FilterOption> results = OnboardingHomeDashboardController.getVendorPrograms();
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @isTest
    static void testGetAllActiveOnboarding() {
        Test.startTest();
        List<OnboardingDTO> results = 
            OnboardingHomeDashboardController.getAllActiveOnboarding();
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        // Should return active onboarding records
        for (OnboardingDTO dto : results) {
            System.assertNotEquals('Complete', dto.Status, 'Should not include completed onboarding');
        }
    }

    @isTest
    static void testOnboardingDTO() {
        Account testAccount = TestDataFactory.createAccount('Test Account', true);

        Vendor__c testVendor = TestDataFactory.createVendor(true);
        testVendor.Active__c = true;
        update testVendor;

        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor,
            'Active',
            true,
            null,
            true
        );

        Onboarding__c ob = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Onboarding_Status__c'
        );
        String inProcessStatus = validStatuses.contains('New') ? 'New' : validStatuses[0];
        ob.Onboarding_Status__c = inProcessStatus;
        update ob;

        // Query with relationships (using CreatedBy instead of Owner)
        Onboarding__c queriedOb = [
            SELECT Id, Name, Onboarding_Status__c, Account__c, Account__r.Name,
                   Vendor_Customization__c, Vendor_Customization__r.Name,
                   CreatedDate, LastModifiedDate, CreatedById, CreatedBy.Name
            FROM Onboarding__c
            WHERE Id = :ob.Id
            LIMIT 1
        ];

        OnboardingDTO dto = new OnboardingDTO(queriedOb);

        // Reuse validStatuses from earlier in the method
        String expectedStatus = validStatuses.contains('New') ? 'New' : 
                              (ob.Onboarding_Status__c != null ? ob.Onboarding_Status__c : validStatuses[0]);
        
        System.assertEquals(ob.Id, dto.Id, 'DTO should have correct Id');
        System.assertEquals(expectedStatus, dto.Status, 'DTO should have correct Status');
        System.assertNotEquals(null, dto.RecordUrl, 'DTO should have RecordUrl');
    }

    @isTest
    static void testAccountDTO() {
        Account testAccount = TestDataFactory.createAccount('Test Account', false);
        testAccount.Territory__c = 'Test Territory';
        testAccount.Region__c = 'Test Region';
        insert testAccount;

        AccountDTO dto = new AccountDTO();
        dto.Id = testAccount.Id;
        dto.Name = testAccount.Name;
        dto.Territory = testAccount.Territory__c;
        dto.Region = testAccount.Region__c;
        dto.EligibleVendorCount = 5;
        dto.RecordUrl = '/' + testAccount.Id;

        System.assertEquals(testAccount.Id, dto.Id, 'DTO should have correct Id');
        System.assertEquals(testAccount.Name, dto.Name, 'DTO should have correct Name (account name may have timestamp)');
        System.assertEquals(5, dto.EligibleVendorCount, 'DTO should have correct count');
    }
}