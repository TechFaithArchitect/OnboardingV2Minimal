public with sharing class AllTemplatesInReqSetMustBeActiveRule implements OnboardingAppActivationRule {

    public void apply(Id recordId, String objectApiName) {
        applyBulk(new Set<Id>{ recordId }, objectApiName);
    }

    public void applyBulk(Set<Id> recordIds, String objectApiName) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        List<Vendor_Program_Requirement__c> requirements = [
            SELECT Id, Name, Active__c, Vendor_Program__c
            FROM Vendor_Program_Requirement__c
            WHERE Vendor_Program__c IN :recordIds
        ];

        Map<Id, List<Vendor_Program_Requirement__c>> requirementsByProgram =
            new Map<Id, List<Vendor_Program_Requirement__c>>();

        for (Vendor_Program_Requirement__c requirement : requirements) {
            if (requirement.Vendor_Program__c == null) {
                continue;
            }
            if (!requirementsByProgram.containsKey(requirement.Vendor_Program__c)) {
                requirementsByProgram.put(
                    requirement.Vendor_Program__c,
                    new List<Vendor_Program_Requirement__c>()
                );
            }
            requirementsByProgram.get(requirement.Vendor_Program__c).add(requirement);
        }

        for (Id vendorProgramId : recordIds) {
            List<Vendor_Program_Requirement__c> requirementsForProgram =
                requirementsByProgram.get(vendorProgramId);
            if (requirementsForProgram == null) {
                continue;
            }

            for (Vendor_Program_Requirement__c requirement : requirementsForProgram) {
                if (requirement.Active__c != true) {
                    String requirementLabel = String.isNotBlank(requirement.Name)
                        ? requirement.Name
                        : String.valueOf(requirement.Id);
                    throw new AuraHandledException(
                        'Cannot activate Vendor Program because requirement ' +
                        requirementLabel +
                        ' is not active.'
                    );
                }
            }
        }
    }
}
