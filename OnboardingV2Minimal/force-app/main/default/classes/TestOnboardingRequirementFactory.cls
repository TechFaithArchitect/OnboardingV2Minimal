@isTest
public class TestOnboardingRequirementFactory {

    public static Onboarding_Requirement__c create(
        Boolean doInsert,
        Boolean completed,
        Boolean isInherited,
        Boolean isOverridden,
        Onboarding__c onboarding,
        String requirementType,
        Boolean requiresFiles,
        Integer sequence,
        String status,
        Vendor_Program_Requirement__c vendorProgramRequirement
    ) {
        Onboarding_Requirement__c onboardingRequirement = new Onboarding_Requirement__c(
            Completed__c = completed != null ? completed : false,
            Is_Inherited__c = isInherited != null ? isInherited : false,
            Is_Overridden__c = isOverridden != null ? isOverridden : false,
            Onboarding__c = onboarding != null ? onboarding.Id : null,
            Requires_Files__c = requiresFiles != null ? requiresFiles : false,
            Sequence__c = sequence != null ? sequence : 1,
            Vendor_Program_Requirement__c = vendorProgramRequirement != null ? vendorProgramRequirement.Id : null
        );

        // Use valid picklist values
        if (String.isNotBlank(requirementType)) {
            List<String> validTypes = TestDataFactoryUtil.getPicklistValues(
                Onboarding_Requirement__c.SObjectType,
                'Requirement_Type__c'
            );
            if (validTypes.contains(requirementType)) {
                onboardingRequirement.Requirement_Type__c = requirementType;
            } else {
                onboardingRequirement.Requirement_Type__c = TestDataFactoryUtil.getDefaultPicklistValue(
                    Onboarding_Requirement__c.SObjectType,
                    'Requirement_Type__c'
                );
            }
        } else {
            onboardingRequirement.Requirement_Type__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Onboarding_Requirement__c.SObjectType,
                'Requirement_Type__c'
            );
        }

        if (String.isNotBlank(status)) {
            List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
                Onboarding_Requirement__c.SObjectType,
                'Status__c'
            );
            if (validStatuses.contains(status)) {
                onboardingRequirement.Status__c = status;
            } else {
                onboardingRequirement.Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                    Onboarding_Requirement__c.SObjectType,
                    'Status__c'
                );
            }
        } else {
            onboardingRequirement.Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Onboarding_Requirement__c.SObjectType,
                'Status__c'
            );
        }

        TestDataFactoryUtil.maybeInsert(onboardingRequirement, doInsert);
        return onboardingRequirement;
    }

    public static Onboarding_Requirement__c create(
        Boolean doInsert,
        Onboarding__c onboarding,
        Vendor_Program_Requirement__c vendorProgramRequirement
    ) {
        return create(
            doInsert,
            false,      
            false,      
            false,      
            onboarding,
            null,   // Will use default from picklist
            false,      
            1,          
            null,   // Will use default from picklist
            vendorProgramRequirement
        );
    }

    public static Onboarding_Requirement__c create(Boolean doInsert) {
        Onboarding__c onboarding = TestOnboardingFactory.create(
            TestDataFactory.createAccount('Acct', doInsert),
            TestVendorProgramFactory.createVendorWithCustomization(doInsert).customization,
            doInsert
        );

        Vendor_Program_Requirement__c vendorProgramRequirement = TestVendorProgramRequirementFactory.create(doInsert);

        return create(doInsert, onboarding, vendorProgramRequirement);
    }
}