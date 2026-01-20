@isTest
private class OnboardingAppVendorProgramReqRepoTest {

    @isTest
    static void testFetchRequiredCredentials() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        External_Contact_Credential_Type__c credentialType = TestCredentialFactory.createCredentialType(
            'Test Type', 1, customization, true, true
        );
        Required_Credential__c credential = TestCredentialFactory.createRequiredCredential(
            credentialType, customization, true, true
        );

        // Act
        Test.startTest();
        List<Required_Credential__c> result = OnboardingAppVendorProgramReqRepo.fetchRequiredCredentials(customization.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one required credential');
        System.assertEquals(credential.Id, result[0].Id, 'Credential Ids should match');
    }

    @isTest
    static void testFetchTrainingRequirements() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Training_System__c trainingSystem = TestDataFactory.createTrainingSystem(true);
        
        // Create training requirement
        Training_Requirement__c requirement = TestDataFactory.createTrainingRequirement(customization, trainingSystem, true);

        // Act
        Test.startTest();
        List<Training_Requirement__c> result = OnboardingAppVendorProgramReqRepo.fetchTrainingRequirements(customization.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one training requirement');
        System.assertEquals(requirement.Id, result[0].Id, 'Requirement Ids should match');
    }
}