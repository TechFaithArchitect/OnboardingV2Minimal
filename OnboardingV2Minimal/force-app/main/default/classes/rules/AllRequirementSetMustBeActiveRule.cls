public with sharing class AllRequirementSetMustBeActiveRule implements OnboardingAppActivationRule {

    public void apply(Id recordId, String objectApiName) {
        applyBulk(new Set<Id>{ recordId }, objectApiName);
    }

    public void applyBulk(Set<Id> recordIds, String objectApiName) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        // Get requirement sets linked to templates via junction object
        Set<Id> requirementSetIds = new Set<Id>();
        Map<Id, List<Id>> templateIdToRequirementSetIds = new Map<Id, List<Id>>();
        
        for (Requirement_Set_Template__c junction : [
            SELECT Requirement_Template__c, Onboarding_Requirement_Set__c
            FROM Requirement_Set_Template__c
            WHERE Requirement_Template__c IN :recordIds
        ]) {
            requirementSetIds.add(junction.Onboarding_Requirement_Set__c);
            if (!templateIdToRequirementSetIds.containsKey(junction.Requirement_Template__c)) {
                templateIdToRequirementSetIds.put(junction.Requirement_Template__c, new List<Id>());
            }
            templateIdToRequirementSetIds.get(junction.Requirement_Template__c).add(junction.Onboarding_Requirement_Set__c);
        }
        
        if (requirementSetIds.isEmpty()) {
            // No requirement sets linked - templates can be activated independently
            return;
        }
        
        // Query requirement sets to check Active__c status
        Map<Id, Onboarding_Requirement_Set__c> requirementSetsMap = new Map<Id, Onboarding_Requirement_Set__c>([
            SELECT Id, Active__c
            FROM Onboarding_Requirement_Set__c
            WHERE Id IN :requirementSetIds
        ]);

        // Validate each vendor program onboarding requirement template
        for (Id templateId : recordIds) {
            List<Id> linkedRequirementSetIds = templateIdToRequirementSetIds.get(templateId);
            if (linkedRequirementSetIds != null && !linkedRequirementSetIds.isEmpty()) {
                for (Id reqSetId : linkedRequirementSetIds) {
                    Onboarding_Requirement_Set__c reqSet = requirementSetsMap.get(reqSetId);
                    if (reqSet != null && !reqSet.Active__c) {
                        throw new AuraHandledException(
                            'Cannot activate Template because the associated Requirement Set is not active.'
                        );
                    }
                }
            }
        }
    }
}