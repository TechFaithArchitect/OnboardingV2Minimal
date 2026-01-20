/**
 * Test class for OnboardingStageDependencyController
 */
@isTest
private class OnboardingStageDependencyControllerTest {

    @isTest
    static void testGetStagesWithDependencies_Basic() {
        // Create test data
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(3, true);
        
        // Get stages
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id, Name, Display_Order__c
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results
        System.assertEquals(3, result.size(), 'Should return 3 stages');
        System.assertEquals('Stage 1', result[0].stageName, 'First stage should be Stage 1');
        System.assertEquals(1, result[0].sequence, 'First stage sequence should be 1');
        System.assertEquals(false, result[0].isCompleted, 'Stage should not be completed');
        System.assertEquals(false, result[0].isBlocked, 'Stage should not be blocked');
        System.assertEquals(0, result[0].requiredStageIds.size(), 'No dependencies');
    }

    @isTest
    static void testGetStagesWithDependencies_WithVendorProgram() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(3, true);
        
        // Get stages
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Mark first stage as completed
        TestDataFactory.createOnboardingStageCompletion(testProgram.Id, process.Id, stages[0].Id, true);

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, testProgram.Id);
        Test.stopTest();

        // Verify results
        System.assertEquals(3, result.size(), 'Should return 3 stages');
        System.assertEquals(true, result[0].isCompleted, 'First stage should be completed');
        System.assertEquals(false, result[1].isCompleted, 'Second stage should not be completed');
        System.assertEquals(false, result[2].isCompleted, 'Third stage should not be completed');
    }

    @isTest
    static void testGetStagesWithDependencies_WithDependencies() {
        // Create test data
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(3, true);
        
        // Get stages
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 2 requires Stage 1
        TestDataFactory.createOnboardingStageDependency(stages[1].Id, stages[0].Id, true, true);

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results
        System.assertEquals(3, result.size(), 'Should return 3 stages');
        
        // Stage 1 should have no dependencies
        System.assertEquals(0, result[0].requiredStageIds.size(), 'Stage 1 should have no dependencies');
        System.assertEquals(false, result[0].isBlocked, 'Stage 1 should not be blocked');
        
        // Stage 2 should have Stage 1 as dependency
        System.assertEquals(1, result[1].requiredStageIds.size(), 'Stage 2 should have 1 dependency');
        System.assertEquals(stages[0].Id, result[1].requiredStageIds[0], 'Stage 2 should depend on Stage 1');
        System.assertEquals(true, result[1].isBlocked, 'Stage 2 should be blocked (Stage 1 not completed)');
    }

    @isTest
    static void testGetStagesWithDependencies_WithCompletedDependencies() {
        // Create test data
        Account testAccount = TestDataFactory.createAccount('Test Account', true);
        Vendor__c testVendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c testProgram = TestDataFactory.createVendorCustomization(
            testVendor, 'Active', true, null, true
        );
        
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(3, true);
        
        // Get stages
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 2 requires Stage 1
        TestDataFactory.createOnboardingStageDependency(stages[1].Id, stages[0].Id, true, true);
        
        // Mark Stage 1 as completed
        TestDataFactory.createOnboardingStageCompletion(testProgram.Id, process.Id, stages[0].Id, true);

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, testProgram.Id);
        Test.stopTest();

        // Verify results
        System.assertEquals(3, result.size(), 'Should return 3 stages');
        
        // Stage 2 should have dependency but not be blocked (Stage 1 is completed)
        System.assertEquals(1, result[1].requiredStageIds.size(), 'Stage 2 should have 1 dependency');
        System.assertEquals(false, result[1].isBlocked, 'Stage 2 should not be blocked (dependency met)');
    }

    @isTest
    static void testGetStagesWithDependencies_NullProcessId() {
        Test.startTest();
        try {
            OnboardingStageDependencyController.getStagesWithDependencies(null, null);
            System.assert(false, 'Should throw exception for null process ID');
        } catch (AuraHandledException e) {
            // AuraHandledException.getMessage() returns "Script-thrown exception" in test context
            System.assertNotEquals(null, e, 'Should throw AuraHandledException');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetStagesWithDependencies_NoStages() {
        // Create process with no stages
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
            Name = 'Empty Process',
            Active__c = true
        );
        insert process;

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results
        System.assertEquals(0, result.size(), 'Should return empty list for process with no stages');
    }

    @isTest
    static void testGetStagesWithDependencies_ComplexDependencies() {
        // Create test data
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(4, true);
        
        // Get stages
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create complex dependencies:
        // Stage 2 requires Stage 1
        // Stage 3 requires Stage 1 and Stage 2
        TestDataFactory.createOnboardingStageDependency(stages[1].Id, stages[0].Id, true, true);
        TestDataFactory.createOnboardingStageDependency(stages[2].Id, stages[0].Id, true, true);
        TestDataFactory.createOnboardingStageDependency(stages[2].Id, stages[1].Id, true, true);

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results
        System.assertEquals(4, result.size(), 'Should return 4 stages');
        
        // Stage 1 should have no dependencies
        System.assertEquals(0, result[0].requiredStageIds.size(), 'Stage 1 should have no dependencies');
        
        // Stage 2 should depend on Stage 1
        System.assertEquals(1, result[1].requiredStageIds.size(), 'Stage 2 should have 1 dependency');
        System.assertEquals(true, result[1].isBlocked, 'Stage 2 should be blocked');
        
        // Stage 3 should depend on Stage 1 and Stage 2
        System.assertEquals(2, result[2].requiredStageIds.size(), 'Stage 3 should have 2 dependencies');
        System.assertEquals(true, result[2].isBlocked, 'Stage 3 should be blocked');
    }

    @isTest
    static void testGetStagesWithDependencies_NonRequiredDependency() {
        // Create test data
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(2, true);
        
        // Get stages
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create non-required dependency: Stage 2 has optional dependency on Stage 1
        TestDataFactory.createOnboardingStageDependency(
            stages[1].Id,
            new List<Id>{ stages[0].Id },
            null,
            false,
            true
        );

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results
        System.assertEquals(2, result.size(), 'Should return 2 stages');
        
        // Stage 2 should not have dependencies (non-required dependencies are ignored)
        System.assertEquals(0, result[1].requiredStageIds.size(), 'Non-required dependencies should be ignored');
        System.assertEquals(false, result[1].isBlocked, 'Stage 2 should not be blocked');
    }

    @isTest
    static void testGetStagesWithDependencies_SortedBySequence() {
        // Create test data with stages in random order
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
            Name = 'Test Process',
            Active__c = true
        );
        insert process;

        List<Onboarding_Application_Stage__c> stages = new List<Onboarding_Application_Stage__c>();
        // Create stages in reverse order
        for (Integer i = 3; i >= 1; i--) {
            Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
                Name = 'Stage ' + i,
                Label__c = 'Stage ' + i,
                Display_Order__c = i,
                Onboarding_Application_Process__c = process.Id,
                Required__c = true
            );
            stages.add(stage);
        }
        insert stages;

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results are sorted by sequence
        System.assertEquals(3, result.size(), 'Should return 3 stages');
        System.assertEquals(1, result[0].sequence, 'First result should have sequence 1');
        System.assertEquals(2, result[1].sequence, 'Second result should have sequence 2');
        System.assertEquals(3, result[2].sequence, 'Third result should have sequence 3');
    }

    @isTest
    static void testGetStagesWithDependencies_NullDisplayOrder() {
        // Create test data with null Display_Order__c
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
            Name = 'Test Process',
            Active__c = true
        );
        insert process;

        Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
            Name = 'Stage 1',
            Label__c = 'Stage 1',
            Display_Order__c = null,
            Onboarding_Application_Process__c = process.Id,
            Required__c = true
        );
        insert stage;

        Test.startTest();
        List<OnboardingStageDependencyController.StageWithDependencyDTO> result = 
            OnboardingStageDependencyController.getStagesWithDependencies(process.Id, null);
        Test.stopTest();

        // Verify results
        System.assertEquals(1, result.size(), 'Should return 1 stage');
        System.assertEquals(0, result[0].sequence, 'Null Display_Order__c should default to 0');
    }
}