@isTest
private class VersioningTriggerHandlerTest {

    @isTest
    static void testSkipsVersioningWhenObjectIsNotVersioned() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        Vendor_Program_Group__c vendorProgramGroup = TestDataFactory.createVendorProgramGroup(false);
        vendorProgramGroup.Name = 'Skip Test Group';
        vendorProgramGroup.Label__c = 'Skip Test Group Label';
        insert vendorProgramGroup;

        Vendor_Program_Group_Member__c vendorProgramGroupMember = TestVendorProgramGroupMemberFactory.create(
            false, vendorProgramGroup, vendorProgram, null, true
        );

        // Act
        Test.startTest();
        insert vendorProgramGroupMember;
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, vendorProgramGroupMember.Id, 'Insert should succeed with non-versioned object');
    }

    @isTest
    static void testSkipsUnknownObjectApiName() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c draft = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', true, null, false
        );

        // Should return immediately because the object API name is not describable
        VersioningTriggerHandler.run(
            new List<SObject>{ draft },
            null,
            'Nonexistent__c'
        );

        System.assertEquals(true, draft.Active__c, 'Handler should not mutate records for unknown objects');
    }

    @isTest
    static void testSingleActivePerParentEnforced() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c parentVendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        Vendor_Customization__c v1 = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, parentVendorProgram.Id, false
        );
        Vendor_Customization__c v2 = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, parentVendorProgram.Id, false
        );

        // Act & Assert
        Test.startTest();
        try {
            insert new List<Vendor_Customization__c>{ v1, v2 };
            System.assert(false, 'Expected error due to multiple active versions');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Only one active version is allowed'), 'Expected validation error');
        }
        Test.stopTest();
    }

    @isTest
    static void testExistingActiveCountsInAggregate() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c parentVendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        // Existing active child
        Vendor_Customization__c existingActive = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, parentVendorProgram.Id, true
        );

        // New active child referencing same parent should fail; aggregate should pick up existingActive
        Vendor_Customization__c secondActive = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, parentVendorProgram.Id, false
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(secondActive, false);
        Test.stopTest();

        System.assert(!result.isSuccess(), 'Second active version should be rejected when one already exists');
        System.assert(
            result.getErrors()[0].getMessage().contains('Only one active version'),
            'Expected only one active version validation error'
        );
    }

    @isTest
    static void testRootActiveVersionWithoutParent_isAllowed() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);

        Vendor_Customization__c orphanVendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, false
        );

        // Act
        Test.startTest();
        insert orphanVendorProgram;
        Test.stopTest();

        // Assert
        Vendor_Customization__c result = [
            SELECT Id, Status__c, Active__c, Previous_Version__c
            FROM Vendor_Customization__c
            WHERE Id = :orphanVendorProgram.Id
        ];

        System.assertEquals(true, result.Active__c, 'Should allow root active version without parent');
        System.assertEquals(null, result.Previous_Version__c, 'Should not be auto-linked');
    }

    @isTest
    static void testAutoCorrectsActiveDrafts() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);

        Vendor_Customization__c draftVendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', true, null, false
        );

        // Act
        Test.startTest();
        insert draftVendorProgram;
        Test.stopTest();

        // Assert
        draftVendorProgram = [SELECT Status__c, Active__c FROM Vendor_Customization__c WHERE Id = :draftVendorProgram.Id];
        System.assertEquals(false, draftVendorProgram.Active__c, 'Draft record should not be active');
    }
}