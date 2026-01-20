@isTest
public class TestVdrPrgrmOnboardingReqTemplateFactory {

    public static Vendor_Program_Onboarding_Req_Template__c create(Boolean doInsert,
                                                                   Onboarding_Requirement_Set__c onboardingRequirementSet,
                                                                   Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup) {
        Vendor_Program_Onboarding_Req_Template__c vendorProgramOnboardingRequirementTemplate = new Vendor_Program_Onboarding_Req_Template__c(
            Category_Group__c = vendorProgramRequirementGroup != null ? vendorProgramRequirementGroup.Id : null,
            Requirement_Label__c = 'Test Requirement',
            Requirement_Type__c = 'Document',
            Status__c = 'Active',
            Is_Current_Version__c = true
        );
        TestDataFactoryUtil.maybeInsert(vendorProgramOnboardingRequirementTemplate, doInsert);
        
        // Link via junction object if requirement set is provided
        if (doInsert && onboardingRequirementSet != null && vendorProgramOnboardingRequirementTemplate.Id != null) {
            Requirement_Set_Template__c junction = new Requirement_Set_Template__c(
                Requirement_Template__c = vendorProgramOnboardingRequirementTemplate.Id,
                Onboarding_Requirement_Set__c = onboardingRequirementSet.Id
            );
            insert junction;
        }
        
        return vendorProgramOnboardingRequirementTemplate;
    }
    
    public static Vendor_Program_Onboarding_Req_Template__c create(Boolean doInsert) {
        // Create Onboarding_Requirement_Set__c first
        // Always insert the requirement set first to ensure it has an Id
        Onboarding_Requirement_Set__c onboardingRequirementSet = TestOnboardingRequirementSetFactory.create(true);
        // Now create the template and link via junction
        return create(doInsert, onboardingRequirementSet, null);
    }
}