public with sharing class OnboardingStatusRuleController {

    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rules_Engine__c> getRules(Id vendorProgramGroupId) {
        return OnboardingRulesService.getRulesEnginesByVendorProgramGroup(vendorProgramGroupId);
    }

    @AuraEnabled(cacheable=true)
    public static Onboarding_Status_Rules_Engine__c getRule(Id ruleId) {
        return OnboardingRulesService.getRulesEngine(ruleId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rule__c> getConditions(Id ruleId) {
        return OnboardingRulesService.getConditions(ruleId);
    }

    @AuraEnabled
    public static void saveRule(Onboarding_Status_Rules_Engine__c statusRulesEngineRecord) {
        OnboardingRulesService.saveRulesEngine(statusRulesEngineRecord);
    }

    @AuraEnabled
    public static void saveConditions(List<Onboarding_Status_Rule__c> conditions) {
        OnboardingRulesService.saveConditions(conditions);
    }

    @AuraEnabled
    public static void deleteCondition(Id conditionId) {
        OnboardingRulesService.deleteRule(conditionId);
    }
}