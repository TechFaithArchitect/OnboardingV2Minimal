public with sharing class AllTemplatesInGroupMustBeActiveRule implements OnboardingAppActivationRule {

    public void apply(Id recordId, String objectApiName) {
        applyBulk(new Set<Id>{ recordId }, objectApiName);
    }

    public void applyBulk(Set<Id> recordIds, String objectApiName) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        // Query all templates for all requirement groups in one query
        List<Vendor_Program_Onboarding_Req_Template__c> templates = [
            SELECT Id, Name, Active__c, Category_Group__c
            FROM Vendor_Program_Onboarding_Req_Template__c
            WHERE Category_Group__c IN :recordIds
        ];

        // Group templates by vendor program requirement group
        Map<Id, List<Vendor_Program_Onboarding_Req_Template__c>> templatesByVendorProgramRequirementGroup = new Map<Id, List<Vendor_Program_Onboarding_Req_Template__c>>();
        for (Vendor_Program_Onboarding_Req_Template__c vendorProgramOnboardingReqTemplate : templates) {
            if (!templatesByVendorProgramRequirementGroup.containsKey(vendorProgramOnboardingReqTemplate.Category_Group__c)) {
                templatesByVendorProgramRequirementGroup.put(vendorProgramOnboardingReqTemplate.Category_Group__c, new List<Vendor_Program_Onboarding_Req_Template__c>());
            }
            templatesByVendorProgramRequirementGroup.get(vendorProgramOnboardingReqTemplate.Category_Group__c).add(vendorProgramOnboardingReqTemplate);
        }

        // Validate each vendor program requirement group
        for (Id vendorProgramRequirementGroupId : recordIds) {
            List<Vendor_Program_Onboarding_Req_Template__c> vendorProgramRequirementGroupTemplates = templatesByVendorProgramRequirementGroup.get(vendorProgramRequirementGroupId);
            if (vendorProgramRequirementGroupTemplates == null) {
                // No templates found - this might be valid
                continue;
            }

            for (Vendor_Program_Onboarding_Req_Template__c vendorProgramOnboardingReqTemplate : vendorProgramRequirementGroupTemplates) {
                if (!vendorProgramOnboardingReqTemplate.Active__c) {
                    throw new AuraHandledException(
                        'Cannot activate Requirement Group because assigned template '
                        + vendorProgramOnboardingReqTemplate.Name + ' is not active.'
                    );
                }
            }
        }
    }
}