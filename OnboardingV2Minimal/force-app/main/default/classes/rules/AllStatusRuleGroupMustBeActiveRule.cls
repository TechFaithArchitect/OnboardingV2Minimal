public with sharing class AllStatusRuleGroupMustBeActiveRule implements OnboardingAppActivationRule {

    public void apply(Id recordId, String objectApiName) {
        applyBulk(new Set<Id>{ recordId }, objectApiName);
    }

    public void applyBulk(Set<Id> recordIds, String objectApiName) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        // Query all rules engines in one query
        List<Onboarding_Status_Rules_Engine__c> engines = [
            SELECT Id,
                   Requirement_Group__r.Active__c,
                   Vendor_Program_Group__r.Active__c
            FROM Onboarding_Status_Rules_Engine__c
            WHERE Id IN :recordIds
        ];

        // Validate each rules engine
        for (Onboarding_Status_Rules_Engine__c rulesEngine : engines) {
            if (rulesEngine.Requirement_Group__r == null || !rulesEngine.Requirement_Group__r.Active__c ||
                rulesEngine.Vendor_Program_Group__r == null || !rulesEngine.Vendor_Program_Group__r.Active__c) {
                throw new AuraHandledException(
                    'Cannot activate Rules Engine because one or both related groups are not active.'
                );
            }
        }
    }
}