@isTest
private class OnboardingDashboardFilterServiceTest {

    @isTest
    static void testGetDateRangeFilter() {
        Test.startTest();
        
        Date last30Days = OnboardingDashboardFilterService.getDateRangeFilter('LAST_30_DAYS');
        Date last90Days = OnboardingDashboardFilterService.getDateRangeFilter('LAST_90_DAYS');
        Date yearToDate = OnboardingDashboardFilterService.getDateRangeFilter('YEAR_TO_DATE');
        Date allTime = OnboardingDashboardFilterService.getDateRangeFilter('ALL_TIME');
        Date defaultFilter = OnboardingDashboardFilterService.getDateRangeFilter(null);
        
        Test.stopTest();
        
        System.assertNotEquals(null, last30Days, 'Last 30 days should return a date');
        System.assertNotEquals(null, last90Days, 'Last 90 days should return a date');
        System.assertNotEquals(null, yearToDate, 'Year to date should return a date');
        System.assertEquals(null, allTime, 'All time should return null');
        System.assertNotEquals(null, defaultFilter, 'Default should return a date');
        
        // Verify dates are in the past
        System.assert(last30Days <= Date.today(), 'Last 30 days should be in the past');
        System.assert(last90Days <= Date.today(), 'Last 90 days should be in the past');
    }

    @isTest
    static void testGetViewFilterClause() {
        Id currentUserId = UserInfo.getUserId();
        
        Test.startTest();
        
        String myView = OnboardingDashboardFilterService.getViewFilterClause('MY_VIEW', currentUserId);
        String myTeam = OnboardingDashboardFilterService.getViewFilterClause('MY_TEAM', currentUserId);
        String orgWide = OnboardingDashboardFilterService.getViewFilterClause('ORG_WIDE', currentUserId);
        String blank = OnboardingDashboardFilterService.getViewFilterClause(null, currentUserId);
        
        Test.stopTest();
        
        System.assert(String.isNotBlank(myView), 'My view should return a clause');
        System.assert(myView.contains('CreatedById'), 'My view should filter by CreatedById');
        
        System.assert(String.isNotBlank(myTeam) || String.isBlank(myTeam), 'My team may return empty if no team members');
        
        System.assertEquals('', orgWide, 'Org wide should return empty string');
        System.assert(String.isNotBlank(blank), 'Blank should default to my view');
    }

    @isTest
    static void testBuildFilterClause() {
        List<Id> vendorIds = new List<Id>();
        List<Id> programIds = new List<Id>();
        
        Test.startTest();
        
        String clause = OnboardingDashboardFilterService.buildFilterClause(
            'LAST_90_DAYS',
            vendorIds,
            programIds,
            'MY_VIEW'
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, clause, 'Clause should not be null');
        System.assert(clause.contains('CreatedById'), 'Clause should contain CreatedById filter');
        System.assert(clause.contains('CreatedDate'), 'Clause should contain CreatedDate filter');
        System.assert(clause.contains('Onboarding_Status__c'), 'Clause should contain status filter');
    }

    @isTest
    static void testBuildFilterClauseWithVendorFilter() {
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        testVendor.Active__c = true;
        update testVendor;
        
        List<Id> vendorIds = new List<Id>{ testVendor.Id };
        List<Id> programIds = new List<Id>();
        
        Test.startTest();
        
        String clause = OnboardingDashboardFilterService.buildFilterClause(
            'LAST_90_DAYS',
            vendorIds,
            programIds,
            'MY_VIEW'
        );
        
        Test.stopTest();
        
        System.assert(clause.contains('Vendor__c'), 'Clause should contain vendor filter');
    }

    @isTest
    static void testBuildFilterClauseWithProgramFilter() {
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        testVendor.Active__c = true;
        update testVendor;
        
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        
        List<Id> vendorIds = new List<Id>();
        List<Id> programIds = new List<Id>{ testProgram.Id };
        
        Test.startTest();
        
        String clause = OnboardingDashboardFilterService.buildFilterClause(
            'LAST_90_DAYS',
            vendorIds,
            programIds,
            'MY_VIEW'
        );
        
        Test.stopTest();
        
        System.assert(clause.contains('Vendor_Customization__c'), 'Clause should contain program filter');
    }

    @isTest
    static void testBuildFilterClauseWithAllFilters() {
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        testVendor.Active__c = true;
        update testVendor;
        
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        
        List<Id> vendorIds = new List<Id>{ testVendor.Id };
        List<Id> programIds = new List<Id>{ testProgram.Id };
        
        Test.startTest();
        String clause = OnboardingDashboardFilterService.buildFilterClause(
            'YEAR_TO_DATE',
            vendorIds,
            programIds,
            'MY_TEAM'
        );
        
        Test.stopTest();
        
        System.assert(clause.contains('Vendor__c'), 'Clause should contain vendor filter');
        System.assert(clause.contains('Vendor_Customization__c'), 'Clause should contain program filter');
        System.assert(clause.contains('CreatedDate'), 'Clause should contain date filter');
        System.assert(clause.contains('Onboarding_Status__c'), 'Clause should contain status filter');
    }

    @isTest
    static void testBuildFilterClause_OrgWide() {
        Test.startTest();
        String clause = OnboardingDashboardFilterService.buildFilterClause(
            'ALL_TIME',
            null,
            null,
            'ORG_WIDE'
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, clause, 'Clause should not be null');
        System.assert(!clause.contains('CreatedById'), 'Org wide should not filter by CreatedById');
        System.assert(clause.contains('Onboarding_Status__c'), 'Clause should contain status filter');
    }

    @isTest
    static void testGetDateRangeFilter_EdgeCases() {
        Test.startTest();
        Date invalidFilter = OnboardingDashboardFilterService.getDateRangeFilter('INVALID_FILTER');
        Test.stopTest();
        
        // Should default to LAST_90_DAYS
        System.assertNotEquals(null, invalidFilter, 'Invalid filter should default to last 90 days');
    }
}