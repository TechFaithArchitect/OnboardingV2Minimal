@isTest
private class VendorProgramRequirementServiceTest {

    @isTest
    static void testSearchVendorProgramRequirements() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Vendor_Program_Requirement__c requirement = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            true
        );
        Vendor_Program_Requirement__c requirementWithName = [
            SELECT Name
            FROM Vendor_Program_Requirement__c
            WHERE Id = :requirement.Id
        ];

        Test.startTest();
        List<Vendor_Program_Requirement__c> results = RequirementDomainService.searchVendorProgramRequirements(
            requirementWithName.Name
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(!results.isEmpty(), 'Should return requirements');
    }

    @isTest
    static void testCreateVendorProgramRequirement() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Vendor_Program_Requirement__c requirement = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            false
        );

        Test.startTest();
        Id requirementId = RequirementDomainService.createVendorProgramRequirement(
            requirement
        );
        Test.stopTest();

        System.assertNotEquals(null, requirementId, 'Requirement ID should be returned');
    }

    @isTest
    static void testCreateVendorProgramRequirement_NullRecord_Throws() {
        Test.startTest();
        try {
            RequirementDomainService.createVendorProgramRequirement(null);
            System.assert(false, 'Should throw exception for null record');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateRequirementSequences() {
        Vendor_Program_Requirement__c requirementOne = TestVendorProgramRequirementFactory.create(
            true
        );
        Vendor_Program_Requirement__c requirementTwo = TestVendorProgramRequirementFactory.create(
            true
        );
        requirementOne.Sequence__c = 1;
        requirementTwo.Sequence__c = 2;

        Test.startTest();
        RequirementDomainService.updateRequirementSequences(
            new List<Vendor_Program_Requirement__c>{ requirementOne, requirementTwo }
        );
        Test.stopTest();

        Vendor_Program_Requirement__c updatedOne = [
            SELECT Sequence__c
            FROM Vendor_Program_Requirement__c
            WHERE Id = :requirementOne.Id
        ];
        System.assertEquals(1, updatedOne.Sequence__c, 'Sequence should be updated');
    }

    @isTest
    static void testGetRecentVendorProgramRequirements() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        TestVendorProgramRequirementFactory.create(vendorProgram, true, true);

        Test.startTest();
        List<Vendor_Program_Requirement__c> results = RequirementDomainService.getRecentVendorProgramRequirements(
            vendorProgram.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(!results.isEmpty(), 'Should return recent requirements');
    }

    @isTest
    static void testDeleteVendorProgramRequirement() {
        Vendor_Program_Requirement__c requirement = TestVendorProgramRequirementFactory.create(
            true
        );

        Test.startTest();
        RequirementDomainService.deleteVendorProgramRequirement(requirement.Id);
        Test.stopTest();

        List<Vendor_Program_Requirement__c> remaining = [
            SELECT Id
            FROM Vendor_Program_Requirement__c
            WHERE Id = :requirement.Id
        ];
        System.assertEquals(0, remaining.size(), 'Requirement should be deleted');
    }
}
