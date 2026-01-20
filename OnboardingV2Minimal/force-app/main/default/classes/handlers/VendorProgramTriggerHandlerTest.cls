@IsTest
private class VendorProgramTriggerHandlerTest {

    @IsTest
    static void testValidInsert() {
        // Arrange - create vendor + base program setup
        TestDataFactoryWrapper.VendorCustomizationWrapper setup = 
            TestDataFactoryWrapper.createVendorProgram(true);

        Vendor__c vendor = setup.vendor;
        Vendor_Customization__c rootCustomization = setup.customization; // this is Draft by default

        // Valid child Active version referencing root
        Vendor_Customization__c activeVersion = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, rootCustomization.Id, false
        );

        // Act
        Test.startTest();
        Database.SaveResult result = Database.insert(activeVersion, false);
        Test.stopTest();

        // Assert
        System.assert(result.isSuccess(), 
            'Expected active version with parent to insert successfully');
    }

    @IsTest
    static void testOnlyOneActivePerParent() {
        // Arrange
        TestDataFactoryWrapper.VendorCustomizationWrapper setup = 
            TestDataFactoryWrapper.createVendorProgram(true);

        Vendor__c vendor = setup.vendor;
        Vendor_Customization__c rootCustomization = setup.customization; // draft root

        // First valid active child
        Vendor_Customization__c firstActive = 
            TestDataFactory.createVendorCustomization(
                vendor, 'Active', true, rootCustomization.Id, true
            );

        // Second active child referencing same parent - should fail
        Vendor_Customization__c secondActive = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, rootCustomization.Id, false
        );

        // Act
        Test.startTest();
        Database.SaveResult saveResult = Database.insert(secondActive, false);
        Test.stopTest();

        // Assert
        System.assert(!saveResult.isSuccess(), 
            'Second active version under same parent should fail');

        System.assert(
            saveResult.getErrors()[0].getMessage().contains('Only one active version'),
            'Expected only one active version validation error'
        );
    }

    @IsTest
    static void testNonDraftMustHaveParent() {
        // Arrange
        TestDataFactoryWrapper.VendorCustomizationWrapper setup =
            TestDataFactoryWrapper.createVendorProgram(true);

        Vendor__c vendor = setup.vendor;

        // Create active version with NO parent (first active allowed)
        Vendor_Customization__c orphan = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, false
        );

        // Act
        Test.startTest();
        Database.SaveResult saveResult = Database.insert(orphan, false);
        Test.stopTest();

        // Assert
        System.assert(saveResult.isSuccess(), 
            'First active version without parent should succeed as root active');

        Vendor_Customization__c inserted = [
            SELECT Id, Previous_Version__c 
            FROM Vendor_Customization__c 
            WHERE Id = :orphan.Id
        ];

        System.assertEquals(null, inserted.Previous_Version__c,
            'Orphan active version should remain without a parent');
    }
}