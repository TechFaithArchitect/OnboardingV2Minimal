@IsTest
private class OnlyOneActiveRecGrpPerPrgrmRuleTest {

    @IsTest
    static void testSecondActiveFailsDueToExistingActive() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Recipient_Group__c secondRecipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c parent = TestDataFactory.createVendorCustomization(vendor, 'Draft', false, null, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, parent.Id, true);

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Vendor_Program_Recipient_Group__c.SObjectType,
            'Status__c'
        );
        String activeStatus = validStatuses.contains('Active') ? 'Active' : validStatuses[0];

        Vendor_Program_Recipient_Group__c version1 = TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            activeStatus,
            '1.0',
            true,
            null,
            true
        );

        Vendor_Program_Recipient_Group__c version2 = TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            secondRecipientGroup,
            activeStatus,
            '2.0',
            true,
            version1.Id,
            false
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(version2, false);
        Test.stopTest();

        System.assert(!saveResult.isSuccess(), 'Expected second active version to be rejected.');
        String errors = TestDataFactoryUtil.joinErrorMessages(saveResult);
        System.assert(
            TestDataFactoryUtil.saveResultHasError(saveResult, 'Only one active Recipient Group') ||
            TestDataFactoryUtil.saveResultHasError(saveResult, 'Only one active'),
            'Expected error about only one active Recipient Group per Vendor Program. Errors: ' + errors
        );
    }
}