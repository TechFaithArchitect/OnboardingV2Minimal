@isTest
public class TestVendorProgramRequirementFactory {

    public static Vendor_Program_Requirement__c create(Boolean doInsert) {
        Vendor_Customization__c vendorProgram =
            TestVendorProgramFactory.createVendorWithCustomization(doInsert).customization;
        Vendor_Program_Requirement__c vendorProgramRequirement = buildRequirement(
            vendorProgram,
            null
        );
        TestDataFactoryUtil.maybeInsert(vendorProgramRequirement, doInsert);
        return vendorProgramRequirement;
    }

    /**
     * Creates a Vendor_Program_Requirement__c linked to a specific vendor program
     * @param vendorProgram The vendor program to link the requirement to
     * @param isActive Whether the requirement should be active
     * @param doInsert Whether to insert the record
     * @return Vendor_Program_Requirement__c record
     */
    public static Vendor_Program_Requirement__c create(
        Vendor_Customization__c vendorProgram,
        Boolean isActive,
        Boolean doInsert
    ) {
        Vendor_Customization__c resolvedVendorProgram = vendorProgram;
        if (resolvedVendorProgram == null) {
            resolvedVendorProgram =
                TestVendorProgramFactory.createVendorWithCustomization(doInsert).customization;
        }

        Vendor_Program_Requirement__c vendorProgramRequirement = buildRequirement(
            resolvedVendorProgram,
            isActive
        );
        TestDataFactoryUtil.maybeInsert(vendorProgramRequirement, doInsert);
        return vendorProgramRequirement;
    }

    private static Vendor_Program_Requirement__c buildRequirement(
        Vendor_Customization__c vendorProgram,
        Boolean isActive
    ) {
        return new Vendor_Program_Requirement__c(
            Vendor_Program__c = vendorProgram != null ? vendorProgram.Id : null,
            Is_Inherited__c = false,
            Is_Overridden__c = false,
            Is_Required__c = true,
            Active__c = isActive != null ? isActive : true,
            Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Vendor_Program_Requirement__c.SObjectType,
                'Status__c'
            ),
            Source_Type__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Vendor_Program_Requirement__c.SObjectType,
                'Source_Type__c'
            ),
            Sequence__c = 1
        );
    }
}
