public with sharing class AllLinkedEngineMustBeActiveRule implements OnboardingAppActivationRule {

    public void apply(Id recordId, String objectApiName) {
        applyBulk(new Set<Id>{ recordId }, objectApiName);
    }

    public void applyBulk(Set<Id> recordIds, String objectApiName) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        // Query all status rules in one query
        List<Onboarding_Status_Rule__c> onboardingStatusRules = [
            SELECT Id, Parent_Rule__r.Active__c, Requirement__r.Active__c
            FROM Onboarding_Status_Rule__c
            WHERE Id IN :recordIds
        ];

        // Validate each status rule
        for (Onboarding_Status_Rule__c statusRule : onboardingStatusRules) {
            if (statusRule.Parent_Rule__r == null || !statusRule.Parent_Rule__r.Active__c) {
                throw new AuraHandledException(
                    'Cannot activate Status Rule because its parent Rules Engine is not active.'
                );
            }
            if (statusRule.Requirement__r == null || !statusRule.Requirement__r.Active__c) {
                throw new AuraHandledException(
                    'Cannot activate Status Rule because its Requirement is not active.'
                );
            }
        }
    }
}