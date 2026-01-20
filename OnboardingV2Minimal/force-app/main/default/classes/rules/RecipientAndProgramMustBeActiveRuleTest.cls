@IsTest
private class RecipientAndProgramMustBeActiveRuleTest {

    @IsTest
    static void testFailsIfRecipientOrProgramInactive() {
        Vendor__c vendor = TestDataFactory.createVendor(true);

        Recipient_Group__c inactiveGroup = TestDataFactory.createRecipientGroup(true, false);
        String inactiveProgramStatus = null;
        List<String> validProgramStatuses = TestDataFactoryUtil.getPicklistValues(
            Vendor_Customization__c.SObjectType,
            'Status__c'
        );
        if (validProgramStatuses.contains('Draft')) {
            inactiveProgramStatus = 'Draft';
        } else {
            for (String status : validProgramStatuses) {
                if (status != 'Active') {
                    inactiveProgramStatus = status;
                    break;
                }
            }
        }
        if (String.isBlank(inactiveProgramStatus) && !validProgramStatuses.isEmpty()) {
            inactiveProgramStatus = validProgramStatuses[0];
        }

        Vendor_Customization__c inactiveProgram = TestDataFactory.createVendorCustomization(
            vendor,
            inactiveProgramStatus,
            false,
            null,
            true
        );

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Vendor_Program_Recipient_Group__c.SObjectType,
            'Status__c'
        );
        String activeStatus = validStatuses.contains('Active') ? 'Active' : validStatuses[0];
        
        Vendor_Program_Recipient_Group__c vendorProgramRecipientGroup = TestDataFactory.createVendorProgramRecipientGroup(
            inactiveProgram,
            inactiveGroup,
            activeStatus,
            '1.0',
            true,
            null,
            false
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(vendorProgramRecipientGroup, false);
        Test.stopTest();

        System.assert(!saveResult.isSuccess(), 'Expected failure when Recipient Group or Program is inactive.');
        System.assert(
            saveResult.getErrors()[0].getMessage().contains('Recipient Group must be active') ||
            saveResult.getErrors()[0].getMessage().contains('Vendor Program must be active'),
            'Expected error about inactive Recipient Group or Program.'
        );
    }
}