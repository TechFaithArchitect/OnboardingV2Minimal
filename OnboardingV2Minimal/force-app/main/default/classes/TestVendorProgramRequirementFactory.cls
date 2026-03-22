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

    /**
     * Explicit requirement type / flags for tests that need multiple program requirements on one vendor program
     * (e.g. onboarding status template scoping).
     */
    public static Vendor_Program_Requirement__c createForProgram(
        Vendor_Customization__c vendorProgram,
        String requirementType,
        Integer sequence,
        Boolean active,
        Boolean isRequired,
        Boolean doInsert
    ) {
        Vendor_Customization__c vp = vendorProgram;
        if (vp == null) {
            vp = TestVendorProgramFactory.createVendorWithCustomization(doInsert).customization;
        }

        String rt = requirementType;
        if (String.isBlank(rt)) {
            rt = TestDataFactoryUtil.getDefaultPicklistValue(
                Vendor_Program_Requirement__c.SObjectType,
                'Requirement_Type__c'
            );
            if (String.isBlank(rt)) {
                rt = TestDataFactoryUtil.getFirstPicklistValue(
                    Vendor_Program_Requirement__c.SObjectType,
                    'Requirement_Type__c'
                );
            }
        }

        Vendor_Program_Requirement__c vpr = new Vendor_Program_Requirement__c(
            Vendor_Program__c = vp.Id,
            Requirement_Type__c = rt,
            Is_Required__c = isRequired != null ? isRequired : true,
            Active__c = active != null ? active : true,
            Sequence__c = sequence != null ? sequence : 1
        );
        TestDataFactoryUtil.maybeInsert(vpr, doInsert);
        return vpr;
    }

    private static Vendor_Program_Requirement__c buildRequirement(
        Vendor_Customization__c vendorProgram,
        Boolean isActive
    ) {
        return createForProgram(vendorProgram, null, 1, isActive != null ? isActive : true, true, false);
    }
}
