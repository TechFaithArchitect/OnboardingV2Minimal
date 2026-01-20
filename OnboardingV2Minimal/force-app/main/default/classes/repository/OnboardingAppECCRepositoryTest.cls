@isTest
private class OnboardingAppECCRepositoryTest {

    @isTest
    static void testFetchRequiredCredentials() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        External_Contact_Credential_Type__c credentialType = TestCredentialFactory.createCredentialType(
            'Test Type', 1, customization, true, true
        );
        Required_Credential__c rc = TestCredentialFactory.createRequiredCredential(
            credentialType, customization, true, true
        );

        // Act
        List<Required_Credential__c> results = OnboardingAppECCRepository.fetchRequiredCredentials(customization.Id);

        // Assert
        System.assertEquals(1, results.size(), 'Should return one required credential');
        System.assertEquals(rc.Id, results[0].Id);
    }

    @isTest
    static void testFetchCredentialTypes() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        External_Contact_Credential_Type__c credentialType = TestCredentialFactory.createCredentialType(
            'Test Type', 1, customization, true, true
        );

        // Act
        List<External_Contact_Credential_Type__c> results = OnboardingAppECCRepository.fetchCredentialTypes();

        // Assert
        System.assertNotEquals(0, results.size(), 'Should return at least one credential type');
    }

    @isTest
    static void testInsertCredentialType() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        // Act
        Test.startTest();
        External_Contact_Credential_Type__c inserted = OnboardingAppECCRepository.insertCredentialType('New Type', 1, customization.Id, true);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, inserted.Id, 'Inserted credential type should have an Id');
        System.assertEquals('New Type', inserted.Name);
        System.assertEquals(1, inserted.Sort_Order__c);
        System.assertEquals(customization.Id, inserted.Vendor_Customization__c);
    }

    @isTest
    static void testUpdateRequiredCredential() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        External_Contact_Credential_Type__c initialType = TestCredentialFactory.createCredentialType(
            'Initial Type', 1, customization, true, true
        );
        Required_Credential__c rc = TestCredentialFactory.createRequiredCredential(
            initialType, customization, true, true
        );
        External_Contact_Credential_Type__c newType = OnboardingAppECCRepository.insertCredentialType('Updated Type', 2, customization.Id, true);

        // Act
        Test.startTest();
        OnboardingAppECCRepository.updateRequiredCredential(rc.Id, newType.Id);
        Test.stopTest();

        // Assert
        Required_Credential__c updated = [SELECT External_Contact_Credential_Type__c FROM Required_Credential__c WHERE Id = :rc.Id];
        System.assertEquals(newType.Id, updated.External_Contact_Credential_Type__c, 'Credential type should be updated');
    }
}