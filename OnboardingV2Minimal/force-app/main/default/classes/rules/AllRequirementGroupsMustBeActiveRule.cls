public with sharing class AllRequirementGroupsMustBeActiveRule implements OnboardingAppActivationRule {

    public void apply(Id recordId, String objectApiName) {
        applyBulk(new Set<Id>{ recordId }, objectApiName);
    }

    public void applyBulk(Set<Id> recordIds, String objectApiName) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        // Query all vendor programs in one query
        List<Vendor_Customization__c> vendorPrograms = [
            SELECT Id, Vendor_Program_Requirement_Group__c
            FROM Vendor_Customization__c
            WHERE Id IN :recordIds
        ];

        // Collect vendor program requirement group IDs
        Set<Id> vendorProgramRequirementGroupIds = new Set<Id>();
        Map<Id, Id> vendorProgramToGroupMap = new Map<Id, Id>();
        for (Vendor_Customization__c vendorProgram : vendorPrograms) {
            if (vendorProgram.Vendor_Program_Requirement_Group__c != null) {
                vendorProgramRequirementGroupIds.add(vendorProgram.Vendor_Program_Requirement_Group__c);
                vendorProgramToGroupMap.put(vendorProgram.Id, vendorProgram.Vendor_Program_Requirement_Group__c);
            }
        }

        if (vendorProgramRequirementGroupIds.isEmpty()) {
            // No requirement groups linked - this might be valid
            return;
        }

        // Query all vendor program requirement groups in one query
        Map<Id, Vendor_Program_Requirement_Group__c> vendorProgramRequirementGroups = new Map<Id, Vendor_Program_Requirement_Group__c>([
            SELECT Id, Name, Active__c
            FROM Vendor_Program_Requirement_Group__c
            WHERE Id IN :vendorProgramRequirementGroupIds
        ]);

        // Validate each vendor program
        for (Id vendorProgramId : recordIds) {
            Id vendorProgramRequirementGroupId = vendorProgramToGroupMap.get(vendorProgramId);
            if (vendorProgramRequirementGroupId == null) {
                // No requirement group linked - this might be valid
                continue;
            }

            Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup = vendorProgramRequirementGroups.get(vendorProgramRequirementGroupId);
            if (vendorProgramRequirementGroup == null || !vendorProgramRequirementGroup.Active__c) {
                throw new AuraHandledException('Cannot activate Vendor Program because its Requirement Group is not active.');
            }
        }
    }
}