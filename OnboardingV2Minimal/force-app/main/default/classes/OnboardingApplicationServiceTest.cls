@isTest
private class OnboardingApplicationServiceTest {

    @isTest
    static void testSaveProgress() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(Name = 'Test Process');
        insert process;

        Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
            Name = 'Stage 1',
            Display_Order__c = 1,
            Onboarding_Application_Process__c = process.Id
        );
        insert stage;

        Test.startTest();
        Id progressId = OnboardingApplicationService.saveProgress(process.Id, vendorProgram.Id, stage.Id);
        Test.stopTest();

        System.assertNotEquals(null, progressId, 'Progress ID should be returned from service');
    }

    @isTest
    static void testGetStagesForProcess() {
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(Name = 'Test Process');
        insert process;
        Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
            Name = 'Stage 1',
            Display_Order__c = 1,
            Onboarding_Application_Process__c = process.Id
        );
        insert stage;

        Test.startTest();
        List<Onboarding_Application_Stage__c> stages = OnboardingApplicationService.getStagesForProcess(process.Id);
        Test.stopTest();

        System.assertNotEquals(null, stages, 'Stages should not be null');
        System.assert(stages.size() > 0, 'Should return at least one stage');
    }

    @isTest
    static void testGetProcessDetails() {
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(Name = 'Test Process');
        insert process;

        Test.startTest();
        Onboarding_Application_Process__c result = OnboardingApplicationService.getProcessDetails(process.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Process should not be null');
        System.assertEquals(process.Id, result.Id, 'Should return correct process');
    }

    @isTest
    static void testGetRequirements() {
        Account acct = TestDataFactory.createAccount('Test Account', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Onboarding__c onboarding = TestDataFactory.createOnboarding(acct, vendorProgram, true);
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true, onboarding, vpr);

        Test.startTest();
        List<OnboardingApplicationService.RequirementDTO> results = OnboardingApplicationService.getRequirements(onboarding.Id);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() > 0, 'Should return at least one requirement');
    }

    @isTest
    static void testUpdateRequirementStatuses() {
        Account acct = TestDataFactory.createAccount('Test Account', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Onboarding__c onboarding = TestDataFactory.createOnboarding(acct, vendorProgram, true);
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true, onboarding, vpr);

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Status__c'
        );
        String completeStatus = validStatuses.contains('Complete') ? 'Complete' : validStatuses[validStatuses.size() - 1];
        
        OnboardingApplicationService.RequirementDTO dto = new OnboardingApplicationService.RequirementDTO(req);
        dto.Status = completeStatus;

        Test.startTest();
        OnboardingApplicationService.updateRequirementStatuses(new List<OnboardingApplicationService.RequirementDTO>{ dto });
        Test.stopTest();

        Onboarding_Requirement__c updated = [SELECT Status__c FROM Onboarding_Requirement__c WHERE Id = :req.Id];
        System.assertEquals(completeStatus, updated.Status__c, 'Status should be updated');
    }

    @isTest
    static void testUpdateRequirementStatuses_EmptyList() {
        Test.startTest();
        OnboardingApplicationService.updateRequirementStatuses(new List<OnboardingApplicationService.RequirementDTO>());
        OnboardingApplicationService.updateRequirementStatuses(null);
        Test.stopTest();

        System.assert(true, 'Should handle empty/null list gracefully');
    }

    @isTest
    static void testRunRuleEvaluation() {
        Account acct = TestDataFactory.createAccount('Test Account', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Onboarding__c onboarding = TestDataFactory.createOnboarding(acct, vendorProgram, true);

        Test.startTest();
        OnboardingApplicationService.runRuleEvaluation(onboarding.Id);
        Test.stopTest();

        System.assert(true, 'Should not throw exception');
    }

    @isTest
    static void testGetProgress() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(Name = 'Test Process');
        insert process;
        Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
            Name = 'Stage 1',
            Display_Order__c = 1,
            Onboarding_Application_Process__c = process.Id
        );
        insert stage;
        OnboardingApplicationService.saveProgress(process.Id, vendorProgram.Id, stage.Id);

        Test.startTest();
        Onboarding_Application_Progress__c progress = OnboardingApplicationService.getProgress(vendorProgram.Id, process.Id);
        Test.stopTest();

        System.assertNotEquals(null, progress, 'Progress should not be null');
    }

    @isTest
    static void testGetUserFacingStage() {
        Test.startTest();
        String result = OnboardingApplicationService.getUserFacingStage('Draft');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a stage string');
    }

    @isTest
    static void testIsCurrentUserAdmin() {
        Test.startTest();
        Boolean isAdmin = OnboardingApplicationService.isCurrentUserAdmin();
        Test.stopTest();

        System.assertNotEquals(null, isAdmin, 'Should return a boolean');
    }

    @isTest
    static void testGetStageCompletions() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(Name = 'Test Process');
        insert process;
        Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
            Name = 'Stage 1',
            Display_Order__c = 1,
            Onboarding_Application_Process__c = process.Id
        );
        insert stage;
        OnboardingApplicationService.saveProgress(process.Id, vendorProgram.Id, stage.Id);

        Test.startTest();
        List<Onboarding_Application_Stage_Completion__c> completions = 
            OnboardingApplicationService.getStageCompletions(vendorProgram.Id, process.Id);
        Test.stopTest();

        System.assertNotEquals(null, completions, 'Completions should not be null');
    }

    @isTest
    static void testGetStageCompletions_NullParams() {
        Test.startTest();
        List<Onboarding_Application_Stage_Completion__c> completions = 
            OnboardingApplicationService.getStageCompletions(null, null);
        Test.stopTest();

        System.assertEquals(0, completions.size(), 'Should return empty list for null params');
    }

    @isTest
    static void testAutoCompleteStagesAndAdvanceProgress() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);
        // Vendor__c is set automatically when creating vendor program, no need to update
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(Name = 'Test Process');
        insert process;

        Test.startTest();
        Id stageId = OnboardingApplicationService.autoCompleteStagesAndAdvanceProgress(vendorProgram.Id, process.Id);
        Test.stopTest();

        // May return null if no stages match, but should not throw
        System.assert(true, 'Should not throw exception');
    }

    @isTest
    static void testGetProcessIdForVendorProgram() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(Name = 'Test Process');
        insert process;
        Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
            Name = 'Stage 1',
            Display_Order__c = 1,
            Onboarding_Application_Process__c = process.Id
        );
        insert stage;
        OnboardingApplicationService.saveProgress(process.Id, vendorProgram.Id, stage.Id);

        Test.startTest();
        Id processId = OnboardingApplicationService.getProcessIdForVendorProgram(vendorProgram.Id);
        Test.stopTest();

        System.assertEquals(process.Id, processId, 'Should return correct process ID');
    }

    @isTest
    static void testGetVendorProgramData() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);

        Test.startTest();
        Vendor_Customization__c result = OnboardingApplicationService.getVendorProgramData(vendorProgram.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return vendor program data');
        System.assertEquals(vendorProgram.Id, result.Id, 'Should return correct vendor program');
    }

    @isTest
    static void testGetVendorProgramData_Null() {
        Test.startTest();
        Vendor_Customization__c result = OnboardingApplicationService.getVendorProgramData(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for null ID');
    }

    @isTest
    static void testGetVendorProgramMetadata() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);

        Test.startTest();
        OnboardingApplicationService.VendorProgramMetadataDTO metadata = 
            OnboardingApplicationService.getVendorProgramMetadata(vendorProgram.Id);
        Test.stopTest();

        System.assertNotEquals(null, metadata, 'Metadata should not be null');
        System.assertEquals(vendorProgram.Id, metadata.vendorProgramId, 'Should return correct vendor program ID');
    }

    @isTest
    static void testGetVendorProgramMetadata_Null() {
        Test.startTest();
        OnboardingApplicationService.VendorProgramMetadataDTO metadata = 
            OnboardingApplicationService.getVendorProgramMetadata(null);
        Test.stopTest();

        System.assertEquals(null, metadata, 'Should return null for null ID');
    }

    @isTest
    static void testGetDefaultVendorProgramOnboardingProcessId() {
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
            Name = 'Vendor Program Onboarding',
            Active__c = true
        );
        insert process;

        Test.startTest();
        Id processId = OnboardingApplicationService.getDefaultVendorProgramOnboardingProcessId();
        Test.stopTest();

        System.assertNotEquals(null, processId, 'Should return a process ID');
    }

    @isTest
    static void testCanStartStage() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(Name = 'Test Process');
        insert process;
        Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
            Name = 'Stage 1',
            Display_Order__c = 1,
            Onboarding_Application_Process__c = process.Id
        );
        insert stage;

        Test.startTest();
        OnboardingStageDependencyService.StageDependencyValidationDTO validation = 
            OnboardingApplicationService.canStartStage(stage.Id, vendorProgram.Id, process.Id);
        Test.stopTest();

        System.assertNotEquals(null, validation, 'Validation should not be null');
    }

    @isTest
    static void testGetStageDependencies() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(Name = 'Test Process');
        insert process;
        Onboarding_Application_Stage__c stage = new Onboarding_Application_Stage__c(
            Name = 'Stage 1',
            Display_Order__c = 1,
            Onboarding_Application_Process__c = process.Id
        );
        insert stage;

        Test.startTest();
        List<OnboardingStageDependencyService.DependencyInfo> dependencies = 
            OnboardingApplicationService.getStageDependencies(stage.Id, vendorProgram.Id, process.Id);
        Test.stopTest();

        System.assertNotEquals(null, dependencies, 'Dependencies should not be null');
    }

    @isTest
    static void testGetResumeContext() {
        Account acct = TestDataFactory.createAccount('Test Account', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Onboarding__c onboarding = TestDataFactory.createOnboarding(acct, vendorProgram, true);
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true, onboarding, vpr);
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Status__c'
        );
        String completeStatus = validStatuses.contains('Complete') ? 'Complete' : validStatuses[validStatuses.size() - 1];
        req.Status__c = completeStatus;
        update req;

        Test.startTest();
        OnboardingApplicationService.ResumeContext context = 
            OnboardingApplicationService.getResumeContext(onboarding.Id);
        Test.stopTest();

        System.assertNotEquals(null, context, 'Context should not be null');
        System.assertEquals(onboarding.Id, context.onboardingId, 'Should return correct onboarding ID');
    }

    @isTest
    static void testGetResumeContext_NullId() {
        Test.startTest();
        try {
            OnboardingApplicationService.getResumeContext(null);
            System.assert(false, 'Should throw exception for null ID');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for null ID');
        }
        Test.stopTest();
    }
}