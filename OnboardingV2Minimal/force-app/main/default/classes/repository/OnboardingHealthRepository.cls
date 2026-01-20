/**
 * Data access for onboarding health checks.
 */
public with sharing class OnboardingHealthRepository {
    public static Map<String, Id> getComponentLibraryByApiName() {
        return VendorOnboardingWizardRepository.getComponentLibraryByApiName();
    }

    public static List<Onboarding_Application_Process__c> fetchActiveProcessesByName(String name) {
        return OnboardingApplicationRepository.fetchActiveProcessesByName(name);
    }

    public static List<Onboarding_Application_Stage__c> fetchStagesForProcess(Id processId) {
        return OnboardingApplicationRepository.fetchStagesForProcess(processId);
    }
}