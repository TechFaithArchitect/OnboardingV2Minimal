@isTest
private class OnboardingAppVendorProgramReqHdlrTest {

    @isTest
    static void testLoadRequiredCredentials() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        External_Contact_Credential_Type__c type1 = TestCredentialFactory.createCredentialType('Type A', 1, vendorProgram, true, true);
        Required_Credential__c rc = TestCredentialFactory.createRequiredCredential(type1, vendorProgram, true, true);
        
        // Act
        Test.startTest();
        List<Required_Credential__c> result = OnboardingAppVendorProgramReqHdlr.loadRequiredCredentials(vendorProgram.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return required credentials');
    }

    @isTest
    static void testLoadTrainingRequirements() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Training_System__c trainingSystem = TestTrainingSystemFactory.create(true);
        Training_Requirement__c trainingReq = TestTrainingRequirementFactory.create(true, vendorProgram, trainingSystem);
        
        // Act
        Test.startTest();
        List<Training_Requirement__c> result = OnboardingAppVendorProgramReqHdlr.loadTrainingRequirements(vendorProgram.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return training requirements');
    }

    @isTest
    static void testInsertRequiredCredential() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        External_Contact_Credential_Type__c type1 = TestCredentialFactory.createCredentialType('Type A', 1, vendorProgram, true, true);
        Required_Credential__c newCredential = new Required_Credential__c(
            Vendor_Customization__c = vendorProgram.Id,
            External_Contact_Credential_Type__c = type1.Id
        );
        
        // Act
        Test.startTest();
        Id credentialId = OnboardingAppVendorProgramReqHdlr.insertRequiredCredential(newCredential);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, credentialId, 'Credential ID should be returned');
        System.assertEquals(newCredential.Id, credentialId, 'Should return the inserted record ID');
        
        List<Required_Credential__c> credentials = [
            SELECT Id 
            FROM Required_Credential__c 
            WHERE Id = :credentialId
        ];
        System.assertEquals(1, credentials.size(), 'Credential should be inserted');
    }

    @isTest
    static void testInsertTrainingRequirement() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Training_System__c trainingSystem = TestTrainingSystemFactory.create(true);
        List<String> trainingTypes = TestDataFactoryUtil.getPicklistValues(
            Training_Requirement__c.SObjectType,
            'Training_Type__c'
        );
        String trainingType = trainingTypes.contains('Internal') ? 'Internal' : trainingTypes[0];
        
        Training_Requirement__c newTraining = new Training_Requirement__c(
            Vendor_Customization__c = vendorProgram.Id,
            Training_System__c = trainingSystem.Id,
            Training_Type__c = trainingType
        );
        
        // Act
        Test.startTest();
        Id trainingId = OnboardingAppVendorProgramReqHdlr.insertTrainingRequirement(newTraining);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, trainingId, 'Training ID should be returned');
        System.assertEquals(newTraining.Id, trainingId, 'Should return the inserted record ID');
        
        List<Training_Requirement__c> trainings = [
            SELECT Id 
            FROM Training_Requirement__c 
            WHERE Id = :trainingId
        ];
        System.assertEquals(1, trainings.size(), 'Training requirement should be inserted');
    }
}