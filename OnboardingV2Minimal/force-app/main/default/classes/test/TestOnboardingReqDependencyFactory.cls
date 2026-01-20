@isTest
public class TestOnboardingReqDependencyFactory {

    public static Onboarding_Requirement_Dependency__c create(
        Boolean doInsert,
        Onboarding_Requirement__c onboardingRequirement,
        Onboarding_Requirement__c dependentOnboardingRequirement
    ) {
        if (onboardingRequirement == null || dependentOnboardingRequirement == null) {
            Onboarding__c onboarding = TestOnboardingFactory.create(TestDataFactory.createAccount('Acct', doInsert), null, doInsert);
            Vendor_Program_Requirement__c vendorProgramRequirement = TestVendorProgramRequirementFactory.create(doInsert);
            
            onboardingRequirement = onboardingRequirement != null
                ? onboardingRequirement
                : TestOnboardingRequirementFactory.create(doInsert, onboarding, vendorProgramRequirement);
            dependentOnboardingRequirement = dependentOnboardingRequirement != null
                ? dependentOnboardingRequirement
                : TestOnboardingRequirementFactory.create(doInsert, onboarding, vendorProgramRequirement);
        }

        Onboarding_Requirement_Dependency__c onboardingRequirementDependency = new Onboarding_Requirement_Dependency__c(
            Onboarding_Requirement__c = onboardingRequirement.Id,
            Dependent_Requirement__c = dependentOnboardingRequirement.Id
        );

        TestDataFactoryUtil.maybeInsert(onboardingRequirementDependency, doInsert);
        return onboardingRequirementDependency;
    }
}