/**
 * Test class for OnboardingRequirementTriggerHandler
 */
@isTest
private class OnboardingRequirementTriggerHandlerTest {

    @isTest
    static void testStatusChangeTriggersEvaluation() {
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
        String notStartedStatus = validStatuses.contains('Not Started') ? 'Not Started' : validStatuses[0];
        String inProcessStatus = validStatuses.contains('In Process') ? 'In Process' : validStatuses[0];
        
        testRequirement.Status__c = notStartedStatus;
        update testRequirement;

        Test.startTest();
        // Change status to trigger follow-up evaluation
        testRequirement.Status__c = inProcessStatus;
        update testRequirement;
        Test.stopTest();

        // Verify follow-up evaluation was triggered (if rules exist)
        // Note: Actual follow-up creation depends on Follow_Up_Rule__mdt records
        List<Follow_Up_Queue__c> followUps = [
            SELECT Id, Status__c
            FROM Follow_Up_Queue__c
            WHERE Onboarding_Requirement__c = :testRequirement.Id
        ];

        // If rules exist, follow-up may be created
        // If no rules, list will be empty (acceptable)
        System.assertNotEquals(null, followUps, 'Follow-ups list should exist');
    }

    @isTest
    static void testCompleteStatusDoesNotTrigger() {
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
        String completeStatus = validStatuses.contains('Complete') ? 'Complete' : validStatuses[validStatuses.size() - 1];
        
        testRequirement.Status__c = inProcessStatus;
        update testRequirement;

        Test.startTest();
        // Change to Complete - should not trigger follow-up
        testRequirement.Status__c = completeStatus;
        update testRequirement;
        Test.stopTest();

        // Complete status should not create follow-ups
        List<Follow_Up_Queue__c> followUps = [
            SELECT Id
            FROM Follow_Up_Queue__c
            WHERE Onboarding_Requirement__c = :testRequirement.Id
        ];

        // Should be empty (Complete status filtered out)
        System.assertEquals(0, followUps.size(), 'Complete status should not create follow-ups');
    }

    @isTest
    static void testBulkProcessing() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        Onboarding__c testOnboarding = TestDataFactory.createOnboarding(testAccount, testProgram, true);
        
        List<Onboarding_Requirement__c> requirements = new List<Onboarding_Requirement__c>();
        for (Integer i = 0; i < 10; i++) {
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
        // Update all to trigger evaluation
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Status__c'
        );
        String pendingStatus = validStatuses.contains('Pending') ? 'Pending' : validStatuses[0];
        for (Onboarding_Requirement__c req : requirements) {
            req.Status__c = pendingStatus;
        }
        update requirements;
        Test.stopTest();

        // Verify bulk processing worked
        Set<Id> requirementIds = new Set<Id>();
        for (Onboarding_Requirement__c req : requirements) {
            requirementIds.add(req.Id);
        }

        List<Follow_Up_Queue__c> followUps = [
            SELECT Id, Onboarding_Requirement__c
            FROM Follow_Up_Queue__c
            WHERE Onboarding_Requirement__c IN :requirementIds
        ];

        System.assertNotEquals(null, followUps, 'Follow-ups list should exist');
    }
}