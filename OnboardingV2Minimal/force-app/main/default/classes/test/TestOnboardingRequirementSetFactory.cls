@isTest
public class TestOnboardingRequirementSetFactory {

    public static Onboarding_Requirement_Set__c create(Boolean doInsert) {
        Vendor_Customization__c vendorProgram = TestVendorProgramFactory.createVendorWithCustomization(doInsert).customization;

        Onboarding_Requirement_Set__c onboardingRequirementSet = new Onboarding_Requirement_Set__c();

        TestDataFactoryUtil.maybeInsert(onboardingRequirementSet, doInsert);
        
        // Link via junction object
        if (doInsert && onboardingRequirementSet.Id != null) {
            Vendor_Program_Requirement_Set__c junction = new Vendor_Program_Requirement_Set__c(
                Vendor_Program__c = vendorProgram.Id,
                Onboarding_Requirement_Set__c = onboardingRequirementSet.Id
            );
            insert junction;
        }
        
        return onboardingRequirementSet;
    }
}