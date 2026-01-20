@isTest
public class TestVendorFactory {

    // Internal helpers
    @testVisible
    public static Vendor__c createVendorInternal(Boolean doInsert) {
        Vendor__c vendor = new Vendor__c(Name = 'Test Vendor ' + DateTime.now().getTime());
        TestDataFactoryUtil.maybeInsert(vendor, doInsert);
        return vendor;
    }

    @testVisible
    public static Vendor_Customization__c createCustomizationInternal(
        Vendor__c vendor,
        String status,
        Boolean isActive,
        Id parentVersionId,
        Boolean doInsert
    ) {
        // Validate status against picklist values - use utility if invalid or null
        String validStatus = status;
        if (String.isBlank(status)) {
            validStatus = TestDataFactoryUtil.getDefaultPicklistValue(
                Vendor_Customization__c.SObjectType, 
                'Status__c'
            );
        } else {
            // Check if the provided status is a valid picklist value
            List<String> validValues = TestDataFactoryUtil.getPicklistValues(
                Vendor_Customization__c.SObjectType, 
                'Status__c'
            );
            if (!validValues.contains(status)) {
                // Use default if provided status is invalid
                validStatus = TestDataFactoryUtil.getDefaultPicklistValue(
                    Vendor_Customization__c.SObjectType, 
                    'Status__c'
                );
            }
        }
        
        Vendor_Customization__c record = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Status__c = validStatus,
            Active__c = isActive
        );
        if (parentVersionId != null) {
            record.Previous_Version__c = parentVersionId;
        }
        TestDataFactoryUtil.maybeInsert(record, doInsert);
        return record;
    }

    // ✅ Public methods used by TestVendorProgramFactory

    public static Vendor__c createVendor(Boolean doInsert) {
        return createVendorInternal(doInsert);
    }

    public static Vendor_Customization__c createVendorCustomization(
        Vendor__c vendor,
        String status,
        Boolean isActive,
        Id parentVersionId,
        Boolean doInsert
    ) {
        return createCustomizationInternal(vendor, status, isActive, parentVersionId, doInsert);
    }
}