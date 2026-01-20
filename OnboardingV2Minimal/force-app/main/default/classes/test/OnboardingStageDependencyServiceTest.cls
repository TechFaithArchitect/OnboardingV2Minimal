/**
 * Test class for OnboardingStageDependencyService
 */
@isTest
private class OnboardingStageDependencyServiceTest {

    /**
     * Helper method to create vendor program
     */
    private static Vendor_Customization__c createTestVendorProgram() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        return TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
    }

    @isTest
    static void testCanStartStage_NoDependencies() {
        // Arrange
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(3, true);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[0].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.canStart, 'Stage should be startable when no dependencies');
        System.assertEquals(0, result.blockingDependencies.size(), 'Should have no blocking dependencies');
    }

    @isTest
    static void testCanStartStage_ALL_Logic_AllMet() {
        // Arrange
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(3, true);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1 AND Stage 2
        List<String> logicTypes = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Application_Stage_Dependency__c.SObjectType,
            'Logic_Type__c'
        );
        String allLogic = logicTypes.contains('ALL') ? 'ALL' : logicTypes[0];
        TestDataFactory.createOnboardingStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            allLogic,
            true,
            true
        );

        // Complete Stage 1 and Stage 2
        TestDataFactory.createOnboardingStageCompletion(vendorProgram.Id, process.Id, stages[0].Id, true);
        TestDataFactory.createOnboardingStageCompletion(vendorProgram.Id, process.Id, stages[1].Id, true);

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.canStart, 'Stage should be startable when ALL dependencies met');
        System.assertEquals(0, result.blockingDependencies.size(), 'Should have no blocking dependencies');
    }

    @isTest
    static void testCanStartStage_ALL_Logic_NotAllMet() {
        // Arrange
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(3, true);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1 AND Stage 2
        List<String> logicTypes = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Application_Stage_Dependency__c.SObjectType,
            'Logic_Type__c'
        );
        String allLogic = logicTypes.contains('ALL') ? 'ALL' : logicTypes[0];
        TestDataFactory.createOnboardingStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            allLogic,
            true,
            true
        );

        // Complete only Stage 1 (not Stage 2)
        TestDataFactory.createOnboardingStageCompletion(vendorProgram.Id, process.Id, stages[0].Id, true);

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.canStart, 'Stage should NOT be startable when ALL dependencies not met');
        System.assertEquals(1, result.blockingDependencies.size(), 'Should have 1 blocking dependency');
        System.assertEquals(2, result.blockingDependencies[0].requiredStageIds.size(), 'Should require 2 stages');
        System.assertEquals(1, result.blockingDependencies[0].completedStageIds.size(), 'Should have 1 completed stage');
        System.assertEquals(1, result.blockingDependencies[0].missingStageIds.size(), 'Should have 1 missing stage');
    }

    @isTest
    static void testCanStartStage_ANY_Logic_OneMet() {
        // Arrange
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(3, true);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1 OR Stage 2
        List<String> logicTypes = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Application_Stage_Dependency__c.SObjectType,
            'Logic_Type__c'
        );
        String anyLogic = logicTypes.contains('ANY') ? 'ANY' : 
            (logicTypes.contains('OR') ? 'OR' : logicTypes[0]);
        TestDataFactory.createOnboardingStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            anyLogic,
            true,
            true
        );

        // Complete only Stage 1
        TestDataFactory.createOnboardingStageCompletion(vendorProgram.Id, process.Id, stages[0].Id, true);

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.canStart, 'Stage should be startable when ANY dependency met');
        System.assertEquals(0, result.blockingDependencies.size(), 'Should have no blocking dependencies');
    }

    @isTest
    static void testCanStartStage_ANY_Logic_NoneMet() {
        // Arrange
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(3, true);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1 OR Stage 2
        List<String> logicTypes = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Application_Stage_Dependency__c.SObjectType,
            'Logic_Type__c'
        );
        String anyLogic = logicTypes.contains('ANY') ? 'ANY' : 
            (logicTypes.contains('OR') ? 'OR' : logicTypes[0]);
        TestDataFactory.createOnboardingStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            anyLogic,
            true,
            true
        );

        // Don't complete any stages

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.canStart, 'Stage should NOT be startable when ANY dependency not met');
        System.assertEquals(1, result.blockingDependencies.size(), 'Should have 1 blocking dependency');
    }

    @isTest
    static void testCanStartStage_CUSTOM_Logic() {
        // Arrange
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(3, true);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1 AND Stage 2
        List<String> logicTypes = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Application_Stage_Dependency__c.SObjectType,
            'Logic_Type__c'
        );
        String customLogic = logicTypes.contains('CUSTOM') ? 'CUSTOM' : logicTypes[0];
        TestDataFactory.createOnboardingStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            customLogic,
            true,
            true
        );

        // Complete both stages
        TestDataFactory.createOnboardingStageCompletion(vendorProgram.Id, process.Id, stages[0].Id, true);
        TestDataFactory.createOnboardingStageCompletion(vendorProgram.Id, process.Id, stages[1].Id, true);

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.canStart, 'Stage should be startable when CUSTOM dependencies met (defaults to ALL)');
    }

    @isTest
    static void testCanStartStage_NotRequiredDependency() {
        // Arrange
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(3, true);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1, but dependency is not required
        List<String> logicTypes = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Application_Stage_Dependency__c.SObjectType,
            'Logic_Type__c'
        );
        String allLogic = logicTypes.contains('ALL') ? 'ALL' : logicTypes[0];
        TestDataFactory.createOnboardingStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id },
            allLogic,
            false,
            true
        );

        // Don't complete Stage 1

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.canStart, 'Stage should be startable when dependency is not required');
        System.assertEquals(0, result.blockingDependencies.size(), 'Should have no blocking dependencies');
    }

    @isTest
    static void testGetDependencyInfo_NoDependencies() {
        // Arrange
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(2, true);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        Test.startTest();
        List<OnboardingStageDependencyService.DependencyInfo> result = 
            OnboardingStageDependencyService.getDependencyInfo(
                stages[0].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(0, result.size(), 'Should return no dependency info when no dependencies exist');
    }

    @isTest
    static void testGetDependencyInfo_WithDependencies() {
        // Arrange
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(3, true);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency: Stage 3 requires Stage 1 AND Stage 2
        List<String> logicTypes = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Application_Stage_Dependency__c.SObjectType,
            'Logic_Type__c'
        );
        String allLogic = logicTypes.contains('ALL') ? 'ALL' : logicTypes[0];
        Onboarding_Application_Stage_Dependency__c dependency = TestDataFactory.createOnboardingStageDependency(
            stages[2].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            allLogic,
            true,
            true
        );

        // Complete Stage 1 only
        TestDataFactory.createOnboardingStageCompletion(vendorProgram.Id, process.Id, stages[0].Id, true);

        Test.startTest();
        List<OnboardingStageDependencyService.DependencyInfo> result = 
            OnboardingStageDependencyService.getDependencyInfo(
                stages[2].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(1, result.size(), 'Should return 1 dependency info');
        System.assertEquals(dependency.Id, result[0].dependencyId, 'Dependency ID should match');
        // Logic type should match what we set
        String expectedLogic = allLogic;
        System.assertEquals(expectedLogic, result[0].logicType, 'Logic type should match');
        System.assertEquals(2, result[0].requiredStageIds.size(), 'Should require 2 stages');
        System.assertEquals(1, result[0].completedStageIds.size(), 'Should have 1 completed stage');
        System.assertEquals(1, result[0].missingStageIds.size(), 'Should have 1 missing stage');
    }

    @isTest
    static void testCanStartStage_MultipleDependencies() {
        // Arrange
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(4, true);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create first dependency: Stage 4 requires Stage 1 AND Stage 2
        List<String> logicTypes = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Application_Stage_Dependency__c.SObjectType,
            'Logic_Type__c'
        );
        String allLogic = logicTypes.contains('ALL') ? 'ALL' : logicTypes[0];
        TestDataFactory.createOnboardingStageDependency(
            stages[3].Id,
            new List<Id>{ stages[0].Id, stages[1].Id },
            allLogic,
            true,
            true
        );

        // Create second dependency: Stage 4 requires Stage 3
        TestDataFactory.createOnboardingStageDependency(
            stages[3].Id,
            new List<Id>{ stages[2].Id },
            allLogic,
            true,
            true
        );

        // Complete Stage 1 and Stage 2, but not Stage 3
        TestDataFactory.createOnboardingStageCompletion(vendorProgram.Id, process.Id, stages[0].Id, true);
        TestDataFactory.createOnboardingStageCompletion(vendorProgram.Id, process.Id, stages[1].Id, true);

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[3].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.canStart, 'Stage should NOT be startable when multiple dependencies not met');
        System.assertEquals(1, result.blockingDependencies.size(), 'Should have 1 blocking dependency');
    }

    @isTest
    static void testCanStartStage_EmptyRequiredStages() {
        // Arrange
        Onboarding_Application_Process__c process = TestDataFactory.createOnboardingApplicationProcessWithStages(2, true);
        Vendor_Customization__c vendorProgram = createTestVendorProgram();
        
        List<Onboarding_Application_Stage__c> stages = [
            SELECT Id
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :process.Id
            ORDER BY Display_Order__c
        ];

        // Create dependency with no required stages (empty members)
        List<String> logicTypes = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Application_Stage_Dependency__c.SObjectType,
            'Logic_Type__c'
        );
        String allLogic = logicTypes.contains('ALL') ? 'ALL' : logicTypes[0];
        TestDataFactory.createOnboardingStageDependency(
            stages[1].Id,
            null, // No required stages
            allLogic,
            true,
            true
        );

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO result = 
            OnboardingStageDependencyService.canStartStage(
                stages[1].Id,
                vendorProgram.Id,
                process.Id
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.canStart, 'Stage should be startable when dependency has no required stages');
    }
}