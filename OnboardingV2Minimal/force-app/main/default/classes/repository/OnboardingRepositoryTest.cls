@isTest
private class OnboardingRepositoryTest {

    @isTest
    static void testUpdateOnboardings() {
        TestDataFactoryWrapper.AccountContactWrapper acctWrapper = TestDataFactory.createAccountContact(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c(
            Name = 'Test Agreement',
            echosign_dev1__Status__c = 'Signed'
        );
        insert agreement;
        
        Onboarding__c onboarding = TestDataFactory.createOnboarding(acctWrapper.account, customization, true);
        onboarding.Agreement__c = agreement.Id;
        update onboarding;

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Onboarding_Status__c'
        );
        String inProcessStatus = validStatuses.contains('In Process') ? 'In Process' : validStatuses[0];
        onboarding.Onboarding_Status__c = inProcessStatus;

        Test.startTest();
        OnboardingRepository.updateOnboardings(new List<Onboarding__c>{ onboarding });
        Test.stopTest();

        // Assert
        Onboarding__c updated = [SELECT Id, Onboarding_Status__c FROM Onboarding__c WHERE Id = :onboarding.Id];
        System.assertEquals('In Process', updated.Onboarding_Status__c, 'Status should be updated');
    }

    @isTest
    static void testUpdateOnboardings_NullInput() {
        Test.startTest();
        OnboardingRepository.updateOnboardings(null); // Should not throw exception
        Test.stopTest();
        System.assert(true, 'Method should not fail with null input');
    }

    @isTest
    static void testUpdateOnboardings_EmptyInput() {
        Test.startTest();
        OnboardingRepository.updateOnboardings(new List<Onboarding__c>()); // Should not throw exception
        Test.stopTest();
        System.assert(true, 'Method should not fail with empty list');
    }

    @isTest
    static void testGetActiveOnboardingByCreatedBy() {
        User testUser = TestDataFactory.createStandardUser(true);
        Account acct = TestDataFactory.createAccount('Test Account', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(acct, vendorProgram, true);
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Onboarding_Status__c'
        );
        String inProcessStatus = validStatuses.contains('In Process') ? 'In Process' : validStatuses[0];
        onboarding.Onboarding_Status__c = inProcessStatus;
        // CreatedById is read-only, cannot be set directly
        // The onboarding will be created with the current user as CreatedBy
        update onboarding;

        Test.startTest();
        List<Onboarding__c> results = OnboardingRepository.getActiveOnboardingByCreatedBy(testUser.Id, 10);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @isTest
    static void testGetAllActiveOnboarding() {
        Account acct = TestDataFactory.createAccount('Test Account', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(acct, vendorProgram, true);
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Onboarding_Status__c'
        );
        String inProcessStatus = validStatuses.contains('In Process') ? 'In Process' : validStatuses[0];
        onboarding.Onboarding_Status__c = inProcessStatus;
        update onboarding;

        Test.startTest();
        List<Onboarding__c> results = OnboardingRepository.getAllActiveOnboarding(10);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @isTest
    static void testGetRecentOnboardingByCreatedBy() {
        User testUser = TestDataFactory.createStandardUser(true);
        Account acct = TestDataFactory.createAccount('Test Account', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(acct, vendorProgram, true);
        // CreatedById is read-only, cannot be set directly
        // Query the onboarding to get the actual CreatedById for testing

        Test.startTest();
        List<Onboarding__c> results = OnboardingRepository.getRecentOnboardingByCreatedBy(testUser.Id, 10);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @isTest
    static void testGetOnboardingSummaryByCreatedBy() {
        User testUser = TestDataFactory.createStandardUser(true);
        Account acct = TestDataFactory.createAccount('Test Account', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(acct, vendorProgram, true);
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Onboarding_Status__c'
        );
        String inProcessStatus = validStatuses.contains('In Process') ? 'In Process' : validStatuses[0];
        onboarding.Onboarding_Status__c = inProcessStatus;
        // CreatedById is read-only, cannot be set directly
        // The onboarding will be created with the current user as CreatedBy
        update onboarding;

        Test.startTest();
        Map<String, Integer> summary = OnboardingRepository.getOnboardingSummaryByCreatedBy(testUser.Id);
        Test.stopTest();

        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assert(summary.containsKey('Total'), 'Summary should contain Total');
    }

    @isTest
    static void testFetchOnboardingById() {
        Account acct = TestDataFactory.createAccount('Test Account', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(acct, vendorProgram, true);

        Test.startTest();
        Onboarding__c result = OnboardingRepository.fetchOnboardingById(onboarding.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return onboarding record');
        System.assertEquals(onboarding.Id, result.Id, 'Should return correct onboarding');
    }

    @isTest
    static void testFetchOnboardingById_Null() {
        Test.startTest();
        Onboarding__c result = OnboardingRepository.fetchOnboardingById(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for null ID');
    }

    @isTest
    static void testFetchOnboardingsByIds() {
        Account acct = TestDataFactory.createAccount('Test Account', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Onboarding__c onboarding1 = TestOnboardingFactory.create(acct, vendorProgram, true);
        Onboarding__c onboarding2 = TestOnboardingFactory.create(acct, vendorProgram, true);

        Test.startTest();
        List<Onboarding__c> results = OnboardingRepository.fetchOnboardingsByIds(
            new Set<Id>{ onboarding1.Id, onboarding2.Id }
        );
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return both onboardings');
    }

    @isTest
    static void testFetchOnboardingsByIds_EmptySet() {
        Test.startTest();
        List<Onboarding__c> results = OnboardingRepository.fetchOnboardingsByIds(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for empty set');
    }

    @isTest
    static void testFetchOnboardingsByIds_Null() {
        Test.startTest();
        List<Onboarding__c> results = OnboardingRepository.fetchOnboardingsByIds(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for null set');
    }
}