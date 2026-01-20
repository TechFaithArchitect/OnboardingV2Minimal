@IsTest
private class PreventDupRecGrpAssignmentRuleTest {

    @IsTest
    static void testFailsWhenDuplicateAlreadyInDatabase() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Vendor_Program_Recipient_Group__c.SObjectType,
            'Status__c'
        );
        String activeStatus = validStatuses.contains('Active') ? 'Active' : validStatuses[0];
        
        Vendor_Program_Recipient_Group__c existing = TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            activeStatus,
            '1.0',
            true,
            null,
            true
        );

        Vendor_Program_Recipient_Group__c duplicate = TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            activeStatus,
            '2.0',
            true,
            null,
            false
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(duplicate, false);
        Test.stopTest();

        System.assert(!saveResult.isSuccess(), 'Duplicate record should fail due to existing DB record.');
        System.assert(
            TestDataFactoryUtil.saveResultHasError(saveResult, 'already has this Recipient Group'),
            'Expected duplicate error from DB presence. Errors: ' +
                TestDataFactoryUtil.joinErrorMessages(saveResult)
        );
    }

    @IsTest
    static void testFailsOnInMemoryDuplicate() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Vendor_Program_Recipient_Group__c.SObjectType,
            'Status__c'
        );
        String activeStatus = validStatuses.contains('Active') ? 'Active' : validStatuses[0];
        
        Vendor_Program_Recipient_Group__c vendorProgramRecipientGroup1 = TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            activeStatus,
            '1.0',
            true,
            null,
            false
        );

        Vendor_Program_Recipient_Group__c vendorProgramRecipientGroup2 = TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            activeStatus,
            '2.0',
            true,
            null,
            false
        );

        Test.startTest();
        Database.SaveResult[] saveResults = Database.insert(new List<Vendor_Program_Recipient_Group__c> { vendorProgramRecipientGroup1, vendorProgramRecipientGroup2 }, false);
        Test.stopTest();

        System.assert(saveResults[1].isSuccess() == false, 'Second record in same transaction should fail.');
        System.assert(
            TestDataFactoryUtil.saveResultHasError(saveResults[1], 'already has this Recipient Group assigned in this transaction') ||
            TestDataFactoryUtil.saveResultHasError(saveResults[1], 'in this transaction'),
            'Expected in-memory duplicate validation error. Errors: ' +
                TestDataFactoryUtil.joinErrorMessages(saveResults[1])
        );
    }

    @IsTest
    static void testAllowsDraftOrVersionedDuplicate() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Vendor_Program_Recipient_Group__c.SObjectType,
            'Status__c'
        );
        String activeStatus = validStatuses.contains('Active') ? 'Active' : validStatuses[0];
        String draftStatus = validStatuses.contains('Draft') ? 'Draft' : null;
        String nonActiveStatus = draftStatus;
        if (nonActiveStatus == null) {
            for (String status : validStatuses) {
                if (status != activeStatus) {
                    nonActiveStatus = status;
                    break;
                }
            }
        }

        Vendor_Program_Recipient_Group__c existing = TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            activeStatus,
            '1.0',
            true,
            null,
            true
        );

        Id parentVersionId = draftStatus == null ? existing.Id : null;
        Vendor_Program_Recipient_Group__c duplicateDraft = TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            nonActiveStatus,
            '2.0',
            false,
            parentVersionId,
            false
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(duplicateDraft, false);
        Test.stopTest();

        System.assert(saveResult.isSuccess(), 'Expected draft/versioned duplicate to be allowed.');
    }
}