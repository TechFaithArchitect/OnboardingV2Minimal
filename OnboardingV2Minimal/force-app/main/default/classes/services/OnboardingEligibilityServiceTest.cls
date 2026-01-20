@isTest
private class OnboardingEligibilityServiceTest {

    @isTest
    static void testGetEligibleVendorCountsByAccount() {
        Account account1 = TestDataFactory.createAccount('Eligible Account 1', true);
        Account account2 = TestDataFactory.createAccount('Eligible Account 2', true);

        Vendor__c vendor1 = TestDataFactory.createVendor(true);
        Vendor__c vendor2 = TestDataFactory.createVendor(true);

        Vendor_Customization__c program1 = TestDataFactory.createVendorCustomization(
            vendor1,
            'Active',
            true,
            null,
            true
        );
        Vendor_Customization__c program2 = TestDataFactory.createVendorCustomization(
            vendor2,
            'Active',
            true,
            null,
            true
        );

        Test.startTest();
        Map<Id, Integer> counts = OnboardingEligibilityService.getEligibleVendorCountsByAccount(
            new List<Id>{ account1.Id, account2.Id },
            null,
            null
        );
        Map<Id, Integer> filteredByVendor = OnboardingEligibilityService.getEligibleVendorCountsByAccount(
            new List<Id>{ account1.Id },
            new List<Id>{ vendor1.Id },
            null
        );
        Map<Id, Integer> filteredByProgram = OnboardingEligibilityService.getEligibleVendorCountsByAccount(
            new List<Id>{ account2.Id },
            null,
            new List<Id>{ program2.Id }
        );
        Test.stopTest();

        System.assertEquals(2, counts.get(account1.Id), 'Should count both vendors when no filters applied');
        System.assertEquals(2, counts.get(account2.Id), 'Should count both vendors when no filters applied');
        System.assertEquals(1, filteredByVendor.get(account1.Id), 'Vendor filter should reduce eligible vendors');
        System.assertEquals(1, filteredByProgram.get(account2.Id), 'Program filter should reduce eligible vendors');
    }

    @isTest
    static void testGetEligibleVendorCountsByAccount_NoActivePrograms() {
        Account account = TestDataFactory.createAccount('No Programs Account', true);

        Vendor__c vendor = TestDataFactory.createVendor(true);
        // Inactive program should not be counted
        TestDataFactory.createVendorCustomization(
            vendor,
            'Draft',
            false,
            null,
            true
        );

        Test.startTest();
        Map<Id, Integer> counts = OnboardingEligibilityService.getEligibleVendorCountsByAccount(
            new List<Id>{ account.Id },
            null,
            null
        );
        Test.stopTest();

        System.assertEquals(true, counts.isEmpty(), 'Inactive programs should not produce eligibility');
    }
}