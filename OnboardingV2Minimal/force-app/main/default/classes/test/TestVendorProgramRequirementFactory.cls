@isTest
public class TestVendorProgramRequirementFactory {

    public static Vendor_Program_Requirement__c create(Boolean doInsert) {
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorWithCustomization(doInsert).customization;
        Vendor_Program_Onboarding_Req_Template__c template = TestVdrPrgrmOnboardingReqTemplateFactory.create(doInsert);
        
        // Check what Requirement_Group_Member__c actually references
        // If it's not required, set it to null to avoid type mismatch errors
        Schema.SObjectType referenceType = TestDataFactoryUtil.getLookupReferenceType(
            Vendor_Program_Requirement__c.SObjectType, 
            'Requirement_Group_Member__c'
        );
        Boolean isRequired = TestDataFactoryUtil.isFieldRequired(
            Vendor_Program_Requirement__c.SObjectType, 
            'Requirement_Group_Member__c'
        );
        
        Id requirementGroupMemberId = null;
        // Only set if required and we can determine the correct type
        // For now, set to null since the field appears to reference a different object type
        // than Vendor_Program_Group_Member__c

        Vendor_Program_Requirement__c vendorProgramRequirement = new Vendor_Program_Requirement__c(
            Vendor_Program__c = vendorProgram.Id,
            Requirement_Template__c = template.Id,
            Requirement_Group_Member__c = requirementGroupMemberId,
            Is_Inherited__c = false,
            Is_Overridden__c = false,
            Is_Required__c = true,
            Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Vendor_Program_Requirement__c.SObjectType, 
                'Status__c'
            ),
            Sequence__c = 1
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
        Vendor_Program_Onboarding_Req_Template__c template = TestVdrPrgrmOnboardingReqTemplateFactory.create(true);
        
        Vendor_Program_Requirement__c vendorProgramRequirement = new Vendor_Program_Requirement__c(
            Vendor_Program__c = vendorProgram != null ? vendorProgram.Id : null,
            Requirement_Template__c = template != null ? template.Id : null,
            Requirement_Group_Member__c = null,
            Is_Inherited__c = false,
            Is_Overridden__c = false,
            Is_Required__c = true,
            Active__c = isActive != null ? isActive : true,
            Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Vendor_Program_Requirement__c.SObjectType, 
                'Status__c'
            ),
            Sequence__c = 1
        );

        TestDataFactoryUtil.maybeInsert(vendorProgramRequirement, doInsert);
        return vendorProgramRequirement;
    }
}