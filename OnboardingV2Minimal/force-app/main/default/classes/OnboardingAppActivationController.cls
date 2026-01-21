public with sharing class OnboardingAppActivationController {
    @AuraEnabled
    public static void activate(Id recordId, String objectApiName) {
        OnboardingAppActivationOrchestrator.activate(recordId, objectApiName); // ✅
    }
}