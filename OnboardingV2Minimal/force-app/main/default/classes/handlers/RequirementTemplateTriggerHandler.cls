/**
 * Handler for Vendor_Program_Onboarding_Req_Template__c trigger logic
 * Handles versioning, duplicate prevention, and field auto-population
 */
public with sharing class RequirementTemplateTriggerHandler {
    
    /**
     * Before insert/update logic
     */
    public static void run(List<Vendor_Program_Onboarding_Req_Template__c> newList, Map<Id, Vendor_Program_Onboarding_Req_Template__c> oldMap) {
        preventDuplicateLabels(newList, oldMap);
        setVersionNumbers(newList, oldMap);
    }
    
    /**
     * After insert logic - set version numbers and link previous versions
     */
    public static void afterInsert(List<Vendor_Program_Onboarding_Req_Template__c> newList) {
        // Version number logic is handled in before insert to ensure it's available
    }
    
    /**
     * Prevents duplicate Requirement_Label__c within the same Onboarding_Requirement_Set__c
     * Uses junction objects to find requirement sets linked to templates
     * Note: For before insert, junction records don't exist yet, so duplicate checking is skipped
     * Duplicate checking occurs in before update when junction records exist
     * Only prevents if Status is 'Active' or if the template is the current version
     */
    private static void preventDuplicateLabels(
        List<Vendor_Program_Onboarding_Req_Template__c> newList, 
        Map<Id, Vendor_Program_Onboarding_Req_Template__c> oldMap
    ) {
        Set<Id> templateIds = new Set<Id>();
        Set<String> labelsToCheck = new Set<String>();
        
        // Collect template IDs (only for updates - inserts won't have IDs yet)
        // and labels for new/updated records
        for (Vendor_Program_Onboarding_Req_Template__c requirementTemplate : newList) {
            if (String.isNotBlank(requirementTemplate.Requirement_Label__c)) {
                if (requirementTemplate.Id != null) {
                    templateIds.add(requirementTemplate.Id);
                }
                labelsToCheck.add(requirementTemplate.Requirement_Label__c.trim().toLowerCase());
            }
        }
        
        // Skip duplicate checking for inserts - junction records don't exist yet
        // Duplicate checking will happen in after insert or on first update
        if (templateIds.isEmpty()) {
            return;
        }
        
        // Get requirement set IDs via junction for templates being updated
        Map<Id, Set<Id>> templateIdToRequirementSetIds = new Map<Id, Set<Id>>();
        Set<Id> requirementSetIds = new Set<Id>();
        
        for (Requirement_Set_Template__c junction : [
            SELECT Requirement_Template__c, Onboarding_Requirement_Set__c
            FROM Requirement_Set_Template__c
            WHERE Requirement_Template__c IN :templateIds
        ]) {
            if (!templateIdToRequirementSetIds.containsKey(junction.Requirement_Template__c)) {
                templateIdToRequirementSetIds.put(junction.Requirement_Template__c, new Set<Id>());
            }
            templateIdToRequirementSetIds.get(junction.Requirement_Template__c).add(junction.Onboarding_Requirement_Set__c);
            requirementSetIds.add(junction.Onboarding_Requirement_Set__c);
        }
        
        if (requirementSetIds.isEmpty()) {
            return; // No requirement sets linked via junction
        }
        
        // Get all templates linked to these requirement sets via junction
        Set<Id> allLinkedTemplateIds = new Set<Id>();
        Map<Id, Set<Id>> allTemplateIdToRequirementSetIds = new Map<Id, Set<Id>>();
        for (Requirement_Set_Template__c junction : [
            SELECT Requirement_Template__c, Onboarding_Requirement_Set__c
            FROM Requirement_Set_Template__c
            WHERE Onboarding_Requirement_Set__c IN :requirementSetIds
        ]) {
            allLinkedTemplateIds.add(junction.Requirement_Template__c);
            if (!allTemplateIdToRequirementSetIds.containsKey(junction.Requirement_Template__c)) {
                allTemplateIdToRequirementSetIds.put(junction.Requirement_Template__c, new Set<Id>());
            }
            allTemplateIdToRequirementSetIds.get(junction.Requirement_Template__c).add(junction.Onboarding_Requirement_Set__c);
        }
        
        // Build existing templates map keyed by requirementSetId|label
        Map<String, Vendor_Program_Onboarding_Req_Template__c> existingTemplates = new Map<String, Vendor_Program_Onboarding_Req_Template__c>();
        for (Vendor_Program_Onboarding_Req_Template__c existing : [
            SELECT Id, Requirement_Label__c, Status__c, Is_Current_Version__c
            FROM Vendor_Program_Onboarding_Req_Template__c
            WHERE Id IN :allLinkedTemplateIds
            AND Requirement_Label__c IN :labelsToCheck
        ]) {
            Set<Id> reqSetIds = allTemplateIdToRequirementSetIds.get(existing.Id);
            if (reqSetIds != null) {
                for (Id reqSetId : reqSetIds) {
                    String key = reqSetId + '|' + existing.Requirement_Label__c.trim().toLowerCase();
                    // Only consider as duplicate if it's active or current version
                    if (existing.Status__c == 'Active' || existing.Is_Current_Version__c == true) {
                        if (!existingTemplates.containsKey(key) || 
                            existingTemplates.get(key).Id != existing.Id) {
                            existingTemplates.put(key, existing);
                        }
                    }
                }
            }
        }
        
        // Check for duplicates in updated records
        for (Vendor_Program_Onboarding_Req_Template__c requirementTemplate : newList) {
            if (requirementTemplate.Id == null || String.isBlank(requirementTemplate.Requirement_Label__c)) {
                continue;
            }
            
            // Get requirement sets for this template
            Set<Id> reqSetIds = templateIdToRequirementSetIds.get(requirementTemplate.Id);
            if (reqSetIds == null || reqSetIds.isEmpty()) {
                continue;
            }
            
            // Only check if this record is active or current version
            Boolean isActiveOrCurrent = requirementTemplate.Status__c == 'Active' || 
                                       requirementTemplate.Is_Current_Version__c == true;
            
            if (isActiveOrCurrent) {
                for (Id reqSetId : reqSetIds) {
                    String key = reqSetId + '|' + requirementTemplate.Requirement_Label__c.trim().toLowerCase();
                    Vendor_Program_Onboarding_Req_Template__c existing = existingTemplates.get(key);
                    
                    if (existing != null && requirementTemplate.Id != existing.Id) {
                        requirementTemplate.addError('A template with the label "' + 
                                        requirementTemplate.Requirement_Label__c + 
                                        '" already exists in this Requirement Set. Please use a different label or edit the existing template.');
                        break; // Only need one error per template
                    }
                }
            }
        }
    }
    
    /**
     * Auto-sets Version__c field based on existing templates in the same Requirement Set
     * Uses junction objects to find requirement sets linked to templates
     * Note: For before insert, junction records don't exist yet, so version defaults to '1'
     * For updates, version is calculated based on junction-linked requirement sets
     * Version numbers increment based on the highest existing version
     */
    private static void setVersionNumbers(
        List<Vendor_Program_Onboarding_Req_Template__c> newList,
        Map<Id, Vendor_Program_Onboarding_Req_Template__c> oldMap
    ) {
        Set<Id> templateIds = new Set<Id>();
        List<Vendor_Program_Onboarding_Req_Template__c> insertsWithoutVersions = new List<Vendor_Program_Onboarding_Req_Template__c>();
        
        // Separate inserts from updates
        for (Vendor_Program_Onboarding_Req_Template__c requirementTemplate : newList) {
            if (requirementTemplate.Id != null) {
                templateIds.add(requirementTemplate.Id);
            } else if (String.isBlank(requirementTemplate.Version__c)) {
                // For inserts without junction records yet, default to version 1
                insertsWithoutVersions.add(requirementTemplate);
            }
        }
        
        // Set version 1 for inserts (junction records don't exist yet)
        for (Vendor_Program_Onboarding_Req_Template__c requirementTemplate : insertsWithoutVersions) {
            requirementTemplate.Version__c = '1';
        }
        
        // For updates, get requirement sets via junction
        if (templateIds.isEmpty()) {
            return;
        }
        
        // Get requirement set IDs via junction for templates being updated
        Map<Id, Set<Id>> templateIdToRequirementSetIds = new Map<Id, Set<Id>>();
        Set<Id> requirementSetIds = new Set<Id>();
        
        for (Requirement_Set_Template__c junction : [
            SELECT Requirement_Template__c, Onboarding_Requirement_Set__c
            FROM Requirement_Set_Template__c
            WHERE Requirement_Template__c IN :templateIds
        ]) {
            if (!templateIdToRequirementSetIds.containsKey(junction.Requirement_Template__c)) {
                templateIdToRequirementSetIds.put(junction.Requirement_Template__c, new Set<Id>());
            }
            templateIdToRequirementSetIds.get(junction.Requirement_Template__c).add(junction.Onboarding_Requirement_Set__c);
            requirementSetIds.add(junction.Onboarding_Requirement_Set__c);
        }
        
        if (requirementSetIds.isEmpty()) {
            // No junction records - set version 1 for any templates without version
            for (Vendor_Program_Onboarding_Req_Template__c requirementTemplate : newList) {
                if (requirementTemplate.Id != null && String.isBlank(requirementTemplate.Version__c)) {
                    requirementTemplate.Version__c = '1';
                }
            }
            return;
        }
        
        // Get all templates linked to these requirement sets via junction
        Set<Id> allLinkedTemplateIds = new Set<Id>();
        Map<Id, Set<Id>> allTemplateIdToRequirementSetIds = new Map<Id, Set<Id>>();
        for (Requirement_Set_Template__c junction : [
            SELECT Requirement_Template__c, Onboarding_Requirement_Set__c
            FROM Requirement_Set_Template__c
            WHERE Onboarding_Requirement_Set__c IN :requirementSetIds
        ]) {
            allLinkedTemplateIds.add(junction.Requirement_Template__c);
            if (!allTemplateIdToRequirementSetIds.containsKey(junction.Requirement_Template__c)) {
                allTemplateIdToRequirementSetIds.put(junction.Requirement_Template__c, new Set<Id>());
            }
            allTemplateIdToRequirementSetIds.get(junction.Requirement_Template__c).add(junction.Onboarding_Requirement_Set__c);
        }
        
        // Query existing templates to find max version per requirement set
        Map<Id, Decimal> maxVersionByRequirementSet = new Map<Id, Decimal>();
        
        for (Vendor_Program_Onboarding_Req_Template__c existing : [
            SELECT Id, Version__c
            FROM Vendor_Program_Onboarding_Req_Template__c
            WHERE Id IN :allLinkedTemplateIds
            AND Version__c != null
        ]) {
            Set<Id> reqSetIds = allTemplateIdToRequirementSetIds.get(existing.Id);
            if (reqSetIds != null) {
                try {
                    Decimal versionNum = Decimal.valueOf(existing.Version__c);
                    for (Id reqSetId : reqSetIds) {
                        Decimal currentMax = maxVersionByRequirementSet.get(reqSetId);
                        if (currentMax == null || versionNum > currentMax) {
                            maxVersionByRequirementSet.put(reqSetId, versionNum);
                        }
                    }
                } catch (TypeException typeEx) {
                    System.debug('Invalid version format: ' + existing.Version__c);
                }
            }
        }
        
        // Set version numbers for updated records without versions
        // Use the maximum version across all requirement sets the template belongs to
        for (Vendor_Program_Onboarding_Req_Template__c requirementTemplate : newList) {
            if (requirementTemplate.Id != null && String.isBlank(requirementTemplate.Version__c)) {
                Set<Id> reqSetIds = templateIdToRequirementSetIds.get(requirementTemplate.Id);
                Decimal maxVersion = null;
                
                if (reqSetIds != null) {
                    for (Id reqSetId : reqSetIds) {
                        Decimal reqSetMax = maxVersionByRequirementSet.get(reqSetId);
                        if (reqSetMax != null && (maxVersion == null || reqSetMax > maxVersion)) {
                            maxVersion = reqSetMax;
                        }
                    }
                }
                
                if (maxVersion == null) {
                    requirementTemplate.Version__c = '1';
                } else {
                    requirementTemplate.Version__c = String.valueOf(maxVersion + 1);
                }
            }
        }
    }
}