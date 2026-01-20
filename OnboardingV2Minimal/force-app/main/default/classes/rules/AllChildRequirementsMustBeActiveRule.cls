public with sharing class AllChildRequirementsMustBeActiveRule implements OnboardingAppActivationRule {

    public void apply(Id recordId, String objectApiName) {
        applyBulk(new Set<Id>{ recordId }, objectApiName);
    }

    public void applyBulk(Set<Id> recordIds, String objectApiName) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        // Query all vendor program requirements for all vendor programs in one query
        List<Vendor_Program_Requirement__c> vendorProgramRequirements = [
            SELECT Id, Active__c, Vendor_Program__c
            FROM Vendor_Program_Requirement__c
            WHERE Vendor_Program__c IN :recordIds
        ];

        // Group vendor program requirements by vendor program
        Map<Id, List<Vendor_Program_Requirement__c>> vendorProgramRequirementsByVendorProgram = new Map<Id, List<Vendor_Program_Requirement__c>>();
        for (Vendor_Program_Requirement__c vendorProgramRequirement : vendorProgramRequirements) {
            if (!vendorProgramRequirementsByVendorProgram.containsKey(vendorProgramRequirement.Vendor_Program__c)) {
                vendorProgramRequirementsByVendorProgram.put(vendorProgramRequirement.Vendor_Program__c, new List<Vendor_Program_Requirement__c>());
            }
            vendorProgramRequirementsByVendorProgram.get(vendorProgramRequirement.Vendor_Program__c).add(vendorProgramRequirement);
        }

        // Validate each vendor program
        for (Id vendorProgramId : recordIds) {
            List<Vendor_Program_Requirement__c> vendorProgramRequirementsForValidation = vendorProgramRequirementsByVendorProgram.get(vendorProgramId);
            if (vendorProgramRequirementsForValidation == null) {
                // No requirements found - this might be valid, but we'll allow it
                continue;
            }

            for (Vendor_Program_Requirement__c vendorProgramRequirement : vendorProgramRequirementsForValidation) {
                if (!vendorProgramRequirement.Active__c) {
                    throw new AuraHandledException('Cannot activate Vendor Program because there are inactive requirements. All requirements must be active before activation.');
                }
            }
        }
    }
}