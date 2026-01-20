@isTest
private class VendorCustomizationRepositoryTest {

    @isTest
    static void testGetById() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', true, null, true
        );

        Vendor_Customization__c result = VendorCustomizationRepository.getById(customization.Id);

        System.assertNotEquals(null, result, 'Expected to retrieve customization');
        System.assertEquals(customization.Id, result.Id);
    }

    @isTest
    static void testGetByIds() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization1 = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);
        Vendor_Customization__c customization2 = TestDataFactory.createVendorCustomization(vendor, 'Active', false, null, true);

        Set<Id> ids = new Set<Id>{ customization1.Id, customization2.Id };
        List<Vendor_Customization__c> results = VendorCustomizationRepository.getByIds(ids);

        System.assertEquals(2, results.size(), 'Should return 2 customizations');
    }

    @isTest
    static void testGetByIds_NullOrEmpty() {
        List<Vendor_Customization__c> emptyResult = VendorCustomizationRepository.getByIds(null);
        System.assertEquals(0, emptyResult.size(), 'Should return empty list when input is null');

        emptyResult = VendorCustomizationRepository.getByIds(new Set<Id>());
        System.assertEquals(0, emptyResult.size(), 'Should return empty list when input is empty');
    }

    @isTest
    static void testGetActiveSiblingsByParentVersion_withExclusions() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        // Use valid status value - status doesn't matter for this test, only Active__c does
        Vendor_Customization__c parent = TestDataFactory.createVendorCustomization(
            vendor, 
            TestDataFactoryUtil.getDefaultPicklistValue(Vendor_Customization__c.SObjectType, 'Status__c'),
            false, 
            null, 
            true
        );

        Vendor_Customization__c sibling1 = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, parent.Id, true);
        Vendor_Customization__c sibling2 = TestDataFactory.createVendorCustomization(vendor, 'Active', true, parent.Id, true);

        Set<Id> excludeIds = new Set<Id>{ sibling1.Id };

        List<Vendor_Customization__c> results = VendorCustomizationRepository.getActiveSiblingsByParentVersion(parent.Id, excludeIds);

        System.assertEquals(1, results.size(), 'Only one active sibling not excluded should be returned');
        System.assertEquals(sibling2.Id, results[0].Id);
    }

    @isTest
    static void testGetActiveSiblingsByParentVersion_withoutExclusions() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        // Use valid status value - the status doesn't matter for this test, only Active__c does
        Vendor_Customization__c parent = TestDataFactory.createVendorCustomization(
            vendor, 
            TestDataFactoryUtil.getDefaultPicklistValue(Vendor_Customization__c.SObjectType, 'Status__c'),
            false, 
            null, 
            true
        );

        // Create siblings - validation rule only allows one active sibling per parent
        // Create one active and one inactive sibling
        Vendor_Customization__c sibling1 = TestDataFactory.createVendorCustomization(vendor, 'Active', true, parent.Id, true);
        Vendor_Customization__c sibling2 = TestDataFactory.createVendorCustomization(vendor, 'Draft', false, parent.Id, true);

        List<Vendor_Customization__c> results = VendorCustomizationRepository.getActiveSiblingsByParentVersion(parent.Id, null);

        // Should return only the active sibling (validation rule prevents multiple active siblings)
        System.assertEquals(1, results.size(), 'Should return the one active sibling');
        System.assertEquals(sibling1.Id, results[0].Id, 'Should return sibling1 which is active');
    }

    @isTest
    static void testUpdateRecords() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);

        // Use a valid picklist value for Status__c
        String newStatus = TestDataFactoryUtil.getFirstPicklistValue(
            Vendor_Customization__c.SObjectType, 
            'Status__c'
        );
        customization.Status__c = newStatus;

        Test.startTest();
        VendorCustomizationRepository.updateRecords(new List<Vendor_Customization__c>{ customization });
        Test.stopTest();

        Vendor_Customization__c updated = [SELECT Status__c FROM Vendor_Customization__c WHERE Id = :customization.Id];
        System.assertEquals(newStatus, updated.Status__c);
    }

    @isTest
    static void testUpdateRecord() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(vendor, 'Pending', true, null, true);

        // Use a valid picklist value for Status__c
        String newStatus = TestDataFactoryUtil.getFirstPicklistValue(
            Vendor_Customization__c.SObjectType, 
            'Status__c'
        );
        customization.Status__c = newStatus;

        Test.startTest();
        VendorCustomizationRepository.updateRecord(customization);
        Test.stopTest();

        Vendor_Customization__c updated = [SELECT Status__c FROM Vendor_Customization__c WHERE Id = :customization.Id];
        System.assertEquals(newStatus, updated.Status__c);
    }

    @isTest
    static void testUpdateRecord_NullSafe() {
        Test.startTest();
        VendorCustomizationRepository.updateRecord(null);
        VendorCustomizationRepository.updateRecords(null);
        VendorCustomizationRepository.updateRecords(new List<Vendor_Customization__c>());
        Test.stopTest();

        // If no exceptions occur, test passes
        System.assert(true, 'Null and empty update inputs handled safely');
    }

    @isTest
    static void testGetActiveVendorPrograms() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor__c vendor2 = TestDataFactory.createVendor(true);

        Vendor_Customization__c activeProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Vendor_Customization__c filteredOutProgram = TestDataFactory.createVendorCustomization(
            vendor2,
            'Active',
            true,
            null,
            true
        );

        Test.startTest();
        List<Vendor_Customization__c> allActive = VendorCustomizationRepository.getActiveVendorPrograms(null, null);
        List<Vendor_Customization__c> filteredByVendor = VendorCustomizationRepository.getActiveVendorPrograms(
            new List<Id>{ vendor.Id },
            null
        );
        List<Vendor_Customization__c> filteredByProgram = VendorCustomizationRepository.getActiveVendorPrograms(
            null,
            new List<Id>{ activeProgram.Id }
        );
        Test.stopTest();

        System.assert(!allActive.isEmpty(), 'Should return active programs when they exist');
        System.assertEquals(1, filteredByVendor.size(), 'Vendor filter should return only matching vendor programs');
        System.assertEquals(activeProgram.Id, filteredByVendor[0].Id);
        System.assertEquals(1, filteredByProgram.size(), 'Program filter should return only matching program');
        System.assertEquals(activeProgram.Id, filteredByProgram[0].Id);
        System.assert(
            !filteredByVendor.isEmpty() && filteredByVendor[0].Vendor__c == vendor.Id,
            'Returned program should belong to requested vendor'
        );
    }
}