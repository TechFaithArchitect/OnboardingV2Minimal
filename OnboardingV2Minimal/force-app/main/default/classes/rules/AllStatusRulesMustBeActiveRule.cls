public with sharing class AllStatusRulesMustBeActiveRule implements OnboardingAppActivationRule {

    public void apply(Id recordId, String objectApiName) {
        applyBulk(new Set<Id>{ recordId }, objectApiName);
    }

    public void applyBulk(Set<Id> recordIds, String objectApiName) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        // Query all child status rules for all parent engines in one query
        List<Onboarding_Status_Rule__c> statusRules = [
            SELECT Id, Active__c, Parent_Rule__c
            FROM Onboarding_Status_Rule__c
            WHERE Parent_Rule__c IN :recordIds
        ];

        // Group rules by parent engine
        Map<Id, List<Onboarding_Status_Rule__c>> rulesByParent = new Map<Id, List<Onboarding_Status_Rule__c>>();
        for (Onboarding_Status_Rule__c statusRule : statusRules) {
            if (!rulesByParent.containsKey(statusRule.Parent_Rule__c)) {
                rulesByParent.put(statusRule.Parent_Rule__c, new List<Onboarding_Status_Rule__c>());
            }
            rulesByParent.get(statusRule.Parent_Rule__c).add(statusRule);
        }

        // Validate each rules engine
        for (Id rulesEngineId : recordIds) {
            List<Onboarding_Status_Rule__c> engineRules = rulesByParent.get(rulesEngineId);
            if (engineRules == null) {
                // No child rules found - this might be valid
                continue;
            }

            for (Onboarding_Status_Rule__c statusRule : engineRules) {
                if (!statusRule.Active__c) {
                    throw new AuraHandledException('Cannot activate Rules Engine unless all Status Rules are active.');
                }
            }
        }
    }
}