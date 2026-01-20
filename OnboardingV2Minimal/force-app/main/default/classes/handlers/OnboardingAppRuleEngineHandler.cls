public with sharing class OnboardingAppRuleEngineHandler {

    public static void apply(String sObjectType, List<SObject> newList, Map<Id, SObject> oldMap) {
        List<OnboardingAppValidationRule> validationRules = getRulesFor(sObjectType);
        for (OnboardingAppValidationRule validationRule : validationRules) {
            validationRule.validate(newList, oldMap);
        }
    }

    @TestVisible
    private static List<OnboardingAppValidationRule> getRulesFor(String sObjectName) {
        Map<String, List<OnboardingAppValidationRule>> rulesByObject = OnboardingAppRuleRegistry.getValidationRules();
        return rulesByObject.containsKey(sObjectName)
            ? rulesByObject.get(sObjectName)
            : new List<OnboardingAppValidationRule>();
    }
}