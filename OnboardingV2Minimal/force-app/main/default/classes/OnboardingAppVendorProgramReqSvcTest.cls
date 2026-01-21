@isTest
private class OnboardingAppVendorProgramReqSvcTest {

    @isTest
    static void testCreateAndRetrieveRequiredCredential() {

        // -------------------------------
        // Setup Vendor Program
        // -------------------------------
        TestDataFactoryWrapper.VendorCustomizationWrapper wrapper =
            TestDataFactory.createDraftVendorCustomizationWrapper(true);

        // -------------------------------
        // Create test Required Credential
        // -------------------------------
        // Create credential type first
        External_Contact_Credential_Type__c credentialType = TestCredentialFactory.createCredentialType(
            'Test Type', 1, wrapper.customization, true, true
        );
        
        Required_Credential__c req = new Required_Credential__c(
            Is_Required__c = true,
            Notes__c = 'Test required credential',
            Sequence__c = 1,
            Vendor_Customization__c = wrapper.customization.Id,
            External_Contact_Credential_Type__c = credentialType.Id
        );

        Test.startTest();
        Id createdId = OnboardingAppVendorProgramReqSvc.createRequiredCredential(req);
        List<Required_Credential__c> results =
            OnboardingAppVendorProgramReqSvc.getRequiredCredentials(wrapper.customization.Id);
        Test.stopTest();

        System.assertNotEquals(null, createdId,
            'Required Credential ID should not be null');
        System.assertEquals(1, results.size(),
            'Should return exactly 1 required credential');
    }


    @isTest
    static void testCreateAndRetrieveTrainingRequirement() {

        // -------------------------------
        // Setup Vendor Program
        // -------------------------------
        TestDataFactoryWrapper.VendorCustomizationWrapper wrapper =
            TestDataFactory.createDraftVendorCustomizationWrapper(true);

        // -------------------------------
        // Setup Training System
        // -------------------------------
        Training_System__c trainingSystem = TestTrainingSystemFactory.create(true);

        // -------------------------------
        // Create Training Requirement
        // -------------------------------
        List<String> trainingTypes = TestDataFactoryUtil.getPicklistValues(
            Training_Requirement__c.SObjectType,
            'Training_Type__c'
        );
        String trainingType = trainingTypes.contains('Internal') ? 'Internal' : trainingTypes[0];
        
        Training_Requirement__c trainingRequirement = new Training_Requirement__c(
            External_Course_Code__c = 'COURSE-100',
            External_Course_Name__c = 'Test Course',
            Training_Code__c = 'INT-001',
            Sequence__c = 1,
            Is_Required__c = true,
            Vendor_Customization__c = wrapper.customization.Id,
            Training_System__c = trainingSystem.Id,
            Training_Type__c = trainingType
        );

        Test.startTest();
        Id createdId = OnboardingAppVendorProgramReqSvc.createTrainingRequirement(trainingRequirement);
        List<Training_Requirement__c> results =
            OnboardingAppVendorProgramReqSvc.getTrainingRequirements(wrapper.customization.Id);
        Test.stopTest();

        System.assertNotEquals(null, createdId,
            'Training Requirement ID should not be null');
        System.assertEquals(1, results.size(),
            'Should return exactly 1 training requirement');
    }

    @isTest
    static void testUpdateRequiredCredentials() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        External_Contact_Credential_Type__c type = TestCredentialFactory.createCredentialType('Type A', 1, vendorProgram, true, true);
        Required_Credential__c cred = TestCredentialFactory.createRequiredCredential(type, vendorProgram, true, true);
        cred.Notes__c = 'Updated notes';
        
        Test.startTest();
        OnboardingAppVendorProgramReqSvc.updateRequiredCredentials(new List<Required_Credential__c>{ cred });
        Test.stopTest();
        
        Required_Credential__c updated = [SELECT Notes__c FROM Required_Credential__c WHERE Id = :cred.Id];
        System.assertEquals('Updated notes', updated.Notes__c, 'Credential should be updated');
    }

    @isTest
    static void testGetCredentialTypes() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        External_Contact_Credential_Type__c type = TestCredentialFactory.createCredentialType('Type A', 1, vendorProgram, true, true);
        
        Test.startTest();
        List<External_Contact_Credential_Type__c> results = OnboardingAppVendorProgramReqSvc.getCredentialTypes();
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @isTest
    static void testCreateCredentialType() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        External_Contact_Credential_Type__c type = new External_Contact_Credential_Type__c(
            Name = 'New Type',
            Vendor_Customization__c = vendorProgram.Id,
            Active__c = true,
            Sort_Order__c = 1
        );
        
        Test.startTest();
        External_Contact_Credential_Type__c created = OnboardingAppVendorProgramReqSvc.createCredentialType(type);
        Test.stopTest();
        
        System.assertNotEquals(null, created.Id, 'Credential type should be created');
    }

    @isTest
    static void testGetTrainingSystems() {
        Training_System__c testTrainingSystem = TestTrainingSystemFactory.create(true);
        
        Test.startTest();
        List<Training_System__c> results = OnboardingAppVendorProgramReqSvc.getTrainingSystems();
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @isTest
    static void testCreateTrainingSystem() {
        Training_System__c newTrainingSystem = new Training_System__c(
            Name = 'Test System',
            Active__c = true,
            System_Type__c = 'External'
        );
        
        Test.startTest();
        Id trainingSystemId = OnboardingAppVendorProgramReqSvc.createTrainingSystem(newTrainingSystem);
        Test.stopTest();
        
        System.assertNotEquals(null, trainingSystemId, 'Training system should be created');
    }

    @isTest
    static void testUpdateTrainingRequirementRequiredStatus() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Training_System__c trainingSystem = TestTrainingSystemFactory.create(true);
        Training_Requirement__c trainingReq = TestTrainingRequirementFactory.create(true, vendorProgram, trainingSystem);
        trainingReq.Is_Required__c = false;
        update trainingReq;
        
        Test.startTest();
        OnboardingAppVendorProgramReqSvc.updateTrainingRequirementRequiredStatus(
            new List<Id>{ trainingReq.Id }, true
        );
        Test.stopTest();
        
        Training_Requirement__c updated = [SELECT Is_Required__c FROM Training_Requirement__c WHERE Id = :trainingReq.Id];
        System.assertEquals(true, updated.Is_Required__c, 'Is_Required should be updated');
    }

    @isTest
    static void testUpdateTrainingRequirementRequiredStatus_EmptyList() {
        Test.startTest();
        OnboardingAppVendorProgramReqSvc.updateTrainingRequirementRequiredStatus(new List<Id>(), true);
        Test.stopTest();
        
        System.assert(true, 'Should handle empty list gracefully');
    }
}