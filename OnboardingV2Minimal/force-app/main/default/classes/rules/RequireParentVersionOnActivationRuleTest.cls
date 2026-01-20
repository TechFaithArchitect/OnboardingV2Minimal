@isTest
private class RequireParentVersionOnActivationRuleTest {

    @isTest
    static void testFailsIfNoParentOnNonDraft() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Vendor_Program_Recipient_Group__c.SObjectType,
            'Status__c'
        );
        String activeStatus = validStatuses.contains('Active') ? 'Active' : validStatuses[0];
        String draftStatus = validStatuses.contains('Draft') ? 'Draft' : validStatuses[0];

        // Seed an existing version so the rule enforces Parent_Version__c on non-draft inserts.
        TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            draftStatus,
            '0.9',
            false,
            null,
            true
        );
        
        Vendor_Program_Recipient_Group__c vendorProgramRecipientGroup = TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            activeStatus,
            '1.0',
            true,
            null,
            false
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(vendorProgramRecipientGroup, false);
        Test.stopTest();

        // 🔍 Always print errors first
        for (Database.Error error : saveResult.getErrors()) {
            System.debug('❌ DML ERROR: ' + error.getStatusCode() + ' - ' + error.getMessage());
        }

        // ✅ THEN assert
        System.assert(!saveResult.isSuccess(), 'Insert should fail without Parent_Version__c.');
        System.assert(
            saveResult.getErrors()[0].getMessage().contains('Non-draft versions must reference a parent version'),
            '❌ ERROR: ' + saveResult.getErrors()[0].getMessage()
        );
    }

    @isTest
    static void testPassesIfDraft() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Vendor_Program_Recipient_Group__c.SObjectType,
            'Status__c'
        );
        String draftStatus = validStatuses.contains('Draft') ? 'Draft' : validStatuses[0];
        
        Vendor_Program_Recipient_Group__c draft = TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            draftStatus,
            '0.9',
            false,
            null,
            false
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(draft, false);
        Test.stopTest();

        System.assert(saveResult.isSuccess(), 'Draft without parent should be allowed.');
    }

    @isTest
    static void testPassesIfParentVersionPresent() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Vendor_Program_Recipient_Group__c.SObjectType,
            'Status__c'
        );
        String draftStatus = validStatuses.contains('Draft') ? 'Draft' : validStatuses[0];
        String activeStatus = validStatuses.contains('Active') ? 'Active' : validStatuses[0];
        
        Vendor_Program_Recipient_Group__c draft = TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            draftStatus,
            '1.0',
            false,
            null,
            true
        );

        Vendor_Program_Recipient_Group__c child = TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            activeStatus,
            '2.0',
            true,
            draft.Id,
            false
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(child, false);
        Test.stopTest();

        System.assert(saveResult.isSuccess(), 'Should pass with valid Parent_Version__c');
    }
}