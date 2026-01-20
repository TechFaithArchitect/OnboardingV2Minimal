@isTest
public class TestVendorProgramRecipientGroupFactory {

    public static Vendor_Program_Recipient_Group__c create(Boolean doInsert) {
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorWithCustomization(doInsert).customization;
        Recipient_Group__c recipientGroup = TestRecipientGroupFactory.create(doInsert);

        return create(vendorProgram, recipientGroup, doInsert);
    }

    public static Vendor_Program_Recipient_Group__c create(
        Vendor_Customization__c vendorProgram,
        Recipient_Group__c recipientGroup,
        Boolean doInsert
    ) {
        return create(vendorProgram, recipientGroup, null, null, null, null, doInsert);
    }

    public static Vendor_Program_Recipient_Group__c create(
        Vendor_Customization__c vendorProgram,
        Recipient_Group__c recipientGroup,
        String status,
        String version,
        Boolean isActive,
        Id parentVersionId,
        Boolean doInsert
    ) {
        Vendor_Program_Recipient_Group__c vendorProgramRecipientGroup = new Vendor_Program_Recipient_Group__c(
            Vendor_Program__c = vendorProgram != null ? vendorProgram.Id : null,
            Recipient_Group__c = recipientGroup != null ? recipientGroup.Id : null,
            Is_Active__c = isActive != null ? isActive : true,
            Parent_Version__c = parentVersionId
        );

        // Use dynamic picklist values for Status__c
        if (String.isNotBlank(status)) {
            List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
                Vendor_Program_Recipient_Group__c.SObjectType,
                'Status__c'
            );
            if (validStatuses.contains(status)) {
                vendorProgramRecipientGroup.Status__c = status;
            } else if (validStatuses.size() > 0) {
                vendorProgramRecipientGroup.Status__c = validStatuses[0];
            }
        } else {
            List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
                Vendor_Program_Recipient_Group__c.SObjectType,
                'Status__c'
            );
            if (validStatuses.contains('Active')) {
                vendorProgramRecipientGroup.Status__c = 'Active';
            } else if (validStatuses.size() > 0) {
                vendorProgramRecipientGroup.Status__c = validStatuses[0];
            }
        }

        // Use dynamic picklist values for Filter_Logic__c
        List<String> validFilterLogics = TestDataFactoryUtil.getPicklistValues(
            Vendor_Program_Recipient_Group__c.SObjectType,
            'Filter_Logic__c'
        );
        if (validFilterLogics.contains('AND')) {
            vendorProgramRecipientGroup.Filter_Logic__c = 'AND';
        } else if (validFilterLogics.size() > 0) {
            vendorProgramRecipientGroup.Filter_Logic__c = validFilterLogics[0];
        }

        vendorProgramRecipientGroup.Version__c = String.isNotBlank(version) ? version : '1.0';

        TestDataFactoryUtil.maybeInsert(vendorProgramRecipientGroup, doInsert);
        return vendorProgramRecipientGroup;
    }
}