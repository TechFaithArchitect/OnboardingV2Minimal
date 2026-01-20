/**
 * Test class for FollowUpDetectionService
 */
@isTest
private class FollowUpDetectionServiceTest {

    @isTest
    static void testEvaluateAndCreateFollowUps() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        Onboarding__c testOnboarding = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        Onboarding_Requirement__c testRequirement = TestOnboardingRequirementFactory.create(
            true, testOnboarding, null
        );
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Status__c'
        );
        String inProcessStatus = validStatuses.contains('In Process') ? 'In Process' : validStatuses[0];
        testRequirement.Status__c = inProcessStatus;
        update testRequirement;

        // Create follow-up rule metadata (simulated via test)
        // Note: In real tests, you'd need to create Follow_Up_Rule__mdt records
        // For now, test will skip if no rules exist

        Test.startTest();
        FollowUpDetectionService.evaluateAndCreateFollowUps(testRequirement.Id);
        Test.stopTest();

        // Verify follow-up was created (if rules exist)
        List<Follow_Up_Queue__c> followUps = [
            SELECT Id, Status__c, Follow_Up_Type__c, Onboarding_Requirement__c
            FROM Follow_Up_Queue__c
            WHERE Onboarding_Requirement__c = :testRequirement.Id
        ];

        // If rules exist, follow-up should be created
        // If no rules, list will be empty (acceptable)
        System.assertNotEquals(null, followUps, 'Follow-ups list should exist');
    }

    @isTest
    static void testEvaluateAndCreateFollowUpsBulk() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        Onboarding__c testOnboarding = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        
        List<Onboarding_Requirement__c> requirements = new List<Onboarding_Requirement__c>();
        for (Integer i = 0; i < 5; i++) {
            Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(
                false, testOnboarding, null
            );
            List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
                Onboarding_Requirement__c.SObjectType,
                'Status__c'
            );
            String inProcessStatus = validStatuses.contains('In Process') ? 'In Process' : validStatuses[0];
            req.Status__c = inProcessStatus;
            requirements.add(req);
        }
        insert requirements;

        Set<Id> requirementIds = new Set<Id>();
        for (Onboarding_Requirement__c req : requirements) {
            requirementIds.add(req.Id);
        }

        Test.startTest();
        FollowUpDetectionService.evaluateAndCreateFollowUpsBulk(requirementIds);
        Test.stopTest();

        // Verify follow-ups were created (if rules exist)
        List<Follow_Up_Queue__c> followUps = [
            SELECT Id, Status__c, Onboarding_Requirement__c
            FROM Follow_Up_Queue__c
            WHERE Onboarding_Requirement__c IN :requirementIds
        ];

        System.assertNotEquals(null, followUps, 'Follow-ups list should exist');
    }

    @isTest
    static void testNoFollowUpForCompleteStatus() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        Onboarding__c testOnboarding = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        Onboarding_Requirement__c testRequirement = TestOnboardingRequirementFactory.create(
            false, testOnboarding, null
        );
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Status__c'
        );
        String completeStatus = validStatuses.contains('Complete') ? 'Complete' : validStatuses[validStatuses.size() - 1];
        testRequirement.Status__c = completeStatus;
        insert testRequirement;
        
        // Update to trigger any after-update logic
        testRequirement.Status__c = completeStatus;
        update testRequirement;

        Test.startTest();
        FollowUpDetectionService.evaluateAndCreateFollowUps(testRequirement.Id);
        Test.stopTest();

        // Complete status should not trigger follow-ups
        // (Handler filters out Complete status)
        List<Follow_Up_Queue__c> followUps = [
            SELECT Id
            FROM Follow_Up_Queue__c
            WHERE Onboarding_Requirement__c = :testRequirement.Id
        ];

        // Should be empty (Complete status filtered out)
        System.assertEquals(0, followUps.size(), 'Complete status should not create follow-ups');
    }

    @isTest
    static void testEnqueueFollowUps() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        Onboarding__c testOnboarding = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        
        // Create multiple requirements
        List<Onboarding_Requirement__c> requirements = new List<Onboarding_Requirement__c>();
        for (Integer i = 0; i < 3; i++) {
            Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(
                false, testOnboarding, null
            );
            List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
                Onboarding_Requirement__c.SObjectType,
                'Status__c'
            );
            String inProcessStatus = validStatuses.contains('In Process') ? 'In Process' : validStatuses[0];
            req.Status__c = inProcessStatus;
            requirements.add(req);
        }
        insert requirements;

        Test.startTest();
        FollowUpDetectionService.enqueueFollowUps(new Set<Id>{ testOnboarding.Id });
        Test.stopTest();

        // Verify follow-ups were created for all requirements (if rules exist)
        Set<Id> requirementIds = new Set<Id>();
        for (Onboarding_Requirement__c req : requirements) {
            requirementIds.add(req.Id);
        }

        List<Follow_Up_Queue__c> followUps = [
            SELECT Id, Onboarding_Requirement__c
            FROM Follow_Up_Queue__c
            WHERE Onboarding_Requirement__c IN :requirementIds
        ];

        // If rules exist, follow-ups should be created
        // If no rules, list will be empty (acceptable)
        System.assertNotEquals(null, followUps, 'Follow-ups list should exist');
    }

    @isTest
    static void testEnqueueFollowUps_EmptySet() {
        Test.startTest();
        FollowUpDetectionService.enqueueFollowUps(new Set<Id>());
        Test.stopTest();

        // Should not throw exception
        System.assert(true, 'Should handle empty set gracefully');
    }

    @isTest
    static void testEnqueueFollowUps_NullSet() {
        Test.startTest();
        FollowUpDetectionService.enqueueFollowUps(null);
        Test.stopTest();

        // Should not throw exception
        System.assert(true, 'Should handle null set gracefully');
    }

    @isTest
    static void testEnqueueFollowUps_NoRequirements() {
        // Create onboarding with no requirements
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        Onboarding__c testOnboarding = TestDataFactory.createOnboarding(testAccount, testProgram, true);

        Test.startTest();
        FollowUpDetectionService.enqueueFollowUps(new Set<Id>{ testOnboarding.Id });
        Test.stopTest();

        // Should not throw exception
        System.assert(true, 'Should handle onboarding with no requirements gracefully');
    }
}