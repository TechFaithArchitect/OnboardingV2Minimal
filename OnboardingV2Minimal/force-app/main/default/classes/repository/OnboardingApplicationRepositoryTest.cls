@isTest
private class OnboardingApplicationRepositoryTest {

    // ------------------------------------------------------------
    // Helper: Create minimal valid Process + Stage
    // ------------------------------------------------------------
    private static Onboarding_Application_Process__c createProcess() {
        Onboarding_Application_Process__c p = new Onboarding_Application_Process__c(
            Name = 'Test Process',
            Description__c = 'Unit test process'
        );
        insert p;
        return p;
    }

    private static Onboarding_Application_Stage__c createStage(Id processId, Integer order) {
        Onboarding_Application_Stage__c s = new Onboarding_Application_Stage__c(
            Name = 'Stage ' + order,
            Display_Order__c = order,
            Onboarding_Application_Process__c = processId
        );
        insert s;
        return s;
    }

    // ------------------------------------------------------------
    // Test: fetchStagesForProcess
    // ------------------------------------------------------------
    @isTest
    static void testFetchStagesForProcess() {
        Onboarding_Application_Process__c process = createProcess();

        Onboarding_Application_Stage__c s1 = createStage(process.Id, 1);
        Onboarding_Application_Stage__c s2 = createStage(process.Id, 2);

        Test.startTest();
        List<Onboarding_Application_Stage__c> stages =
            OnboardingApplicationRepository.fetchStagesForProcess(process.Id);
        Test.stopTest();

        System.assertEquals(2, stages.size(), 'Should return two stages');
        System.assertEquals(1, stages[0].Display_Order__c, 'Stages should be ordered ASC');
    }

    // ------------------------------------------------------------
    // Test: fetchProcessDetails
    // ------------------------------------------------------------
    @isTest
    static void testFetchProcessDetails() {
        Onboarding_Application_Process__c process = createProcess();

        Test.startTest();
        Onboarding_Application_Process__c result =
            OnboardingApplicationRepository.fetchProcessDetails(process.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Process should be returned');
        System.assertEquals(process.Id, result.Id);
    }

    // ------------------------------------------------------------
    // Test: fetchProgress
    // ------------------------------------------------------------
    @isTest
    static void testFetchProgress() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram =
            TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);

        Onboarding_Application_Process__c process = createProcess();

        Onboarding_Application_Progress__c progress =
            new Onboarding_Application_Progress__c(
                Vendor_Program__c = vendorProgram.Id,
                Onboarding_Application_Process__c = process.Id
            );
        insert progress;

        Test.startTest();
        Onboarding_Application_Progress__c fetched =
            OnboardingApplicationRepository.fetchProgress(vendorProgram.Id, process.Id);
        Test.stopTest();

        System.assertNotEquals(null, fetched, 'Should fetch existing progress');
        System.assertEquals(progress.Id, fetched.Id);
    }

    // ------------------------------------------------------------
    // Test: fetchProgressByVendorProgram
    // ------------------------------------------------------------
    @isTest
    static void testFetchProgressByVendorProgram() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram =
            TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);

        Onboarding_Application_Process__c process = createProcess();

        Onboarding_Application_Progress__c progress =
            new Onboarding_Application_Progress__c(
                Vendor_Program__c = vendorProgram.Id,
                Onboarding_Application_Process__c = process.Id
            );
        insert progress;

        Test.startTest();
        Onboarding_Application_Progress__c fetched =
            OnboardingApplicationRepository.fetchProgressByVendorProgram(vendorProgram.Id);
        Test.stopTest();

        System.assertNotEquals(null, fetched, 'Should return progress');
        System.assertEquals(progress.Id, fetched.Id);
    }

    // ------------------------------------------------------------
    // Test: upsertProgress
    // ------------------------------------------------------------
    @isTest
    static void testUpsertProgress() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram =
            TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);

        Onboarding_Application_Process__c process = createProcess();

        Onboarding_Application_Progress__c progress =
            new Onboarding_Application_Progress__c(
                Vendor_Program__c = vendorProgram.Id,
                Onboarding_Application_Process__c = process.Id
            );

        Test.startTest();
        Id resultId = OnboardingApplicationRepository.upsertProgress(progress);
        Test.stopTest();

        System.assertNotEquals(null, resultId, 'Upsert should return Id');
    }

    // ------------------------------------------------------------
    // Test: insertStageCompletion
    // ------------------------------------------------------------
    @isTest
    static void testInsertStageCompletion() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram =
            TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);

        Onboarding_Application_Process__c process = createProcess();
        Onboarding_Application_Stage__c stage = createStage(process.Id, 1);

        Onboarding_Application_Stage_Completion__c completion =
            new Onboarding_Application_Stage_Completion__c(
                Onboarding_Application_Process__c = process.Id,
                Onboarding_Application_Stage__c = stage.Id,
                Vendor_Program__c = vendorProgram.Id,
                Completed_By__c = UserInfo.getUserId(),
                Completed_Date__c = DateTime.now()
            );

        Test.startTest();
        OnboardingApplicationRepository.insertStageCompletion(completion);
        Test.stopTest();

        System.assertNotEquals(null, completion.Id, 'Stage completion should be inserted');
    }
}