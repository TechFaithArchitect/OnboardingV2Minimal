@isTest
private class OnboardingAppActivationRepositoryTest {

    @isTest
    static void testGetById() {
        // Setup
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', true, null, true
        );

        // Act
        SObject result = OnboardingAppActivationRepository.getById(
            'Vendor_Customization__c',
            customization.Id,
            new List<String>{ 'Id', 'Name', 'Active__c' }
        );

        // Assert
        System.assertNotEquals(null, result, 'Should retrieve the customization record');
        System.assertEquals(customization.Id, result.get('Id'), 'Id should match');
    }

    @isTest
    static void testGetActiveSiblingsByParentVersion() {
        // Setup
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c parentCustomization = TestDataFactory.createVendorCustomization(
            vendor, 'Deprecated', false, null, true
        );

        Vendor_Customization__c child1 = TestDataFactory.createVendorCustomization(
            vendor, 'Deprecated', false, parentCustomization.Id, true
        );

        Vendor_Customization__c child2 = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, parentCustomization.Id, true
        );

        // Act
        List<SObject> siblings = OnboardingAppActivationRepository.getActiveSiblingsByParentVersion(
            'Vendor_Customization__c',
            parentCustomization.Id,
            child1.Id,
            'Active__c'
        );

        // Assert
        System.assertEquals(1, siblings.size(), 'Should return one sibling (excluding the original)');
        System.assertEquals(child2.Id, siblings[0].get('Id'), 'Sibling should be child2');
    }

    @isTest
    static void testUpdateRecords() {
        // Setup
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', true, null, true
        );

        // Use a valid picklist value for Status__c
        String newStatus = TestDataFactoryUtil.getFirstPicklistValue(
            Vendor_Customization__c.SObjectType, 
            'Status__c'
        );
        customization.Status__c = newStatus;

        // Act
        Test.startTest();
        OnboardingAppActivationRepository.updateRecords(new List<SObject>{ customization });
        Test.stopTest();

        // Assert
        Vendor_Customization__c updated = [
            SELECT Id, Status__c FROM Vendor_Customization__c WHERE Id = :customization.Id
        ];
        System.assertEquals(newStatus, updated.Status__c, 'Status should be updated');
    }

    @isTest
    static void testUpdateRecord() {
        // Setup
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', true, null, true
        );

        // Use a valid picklist value for Status__c
        String newStatus = TestDataFactoryUtil.getFirstPicklistValue(
            Vendor_Customization__c.SObjectType, 
            'Status__c'
        );
        customization.Status__c = newStatus;

        // Act
        Test.startTest();
        OnboardingAppActivationRepository.updateRecord(customization);
        Test.stopTest();

        // Assert
        Vendor_Customization__c updated = [
            SELECT Id, Status__c FROM Vendor_Customization__c WHERE Id = :customization.Id
        ];
        System.assertEquals(newStatus, updated.Status__c, 'Status should be updated');
    }

    @isTest
    static void testUpdateRecordNullAndEmptySafety() {
        Test.startTest();
        OnboardingAppActivationRepository.updateRecords(null);   // should not throw
        OnboardingAppActivationRepository.updateRecords(new List<SObject>()); // should not throw
        OnboardingAppActivationRepository.updateRecord(null);    // should not throw
        Test.stopTest();
    }
}