/**
 * Service for managing the many-to-many relationship between
 * Requirement Sets and Templates via the Requirement_Set_Template__c junction object
 */
public with sharing class RequirementSetTemplateService {
    
    /**
     * Links a template to a requirement set via junction object
     * @param templateId The template ID
     * @param requirementSetId The requirement set ID
     * @return The created junction record ID
     */
    public static Id linkTemplateToRequirementSet(Id templateId, Id requirementSetId) {
        ValidationHelper.requireId(templateId, 'Template ID');
        ValidationHelper.requireId(requirementSetId, 'Requirement Set ID');
        
        // Check if link already exists
        List<Requirement_Set_Template__c> existing = [
            SELECT Id
            FROM Requirement_Set_Template__c
            WHERE Requirement_Template__c = :templateId
            AND Onboarding_Requirement_Set__c = :requirementSetId
            LIMIT 1
        ];
        
        if (!existing.isEmpty()) {
            return existing[0].Id;
        }
        
        Requirement_Set_Template__c junction = new Requirement_Set_Template__c(
            Requirement_Template__c = templateId,
            Onboarding_Requirement_Set__c = requirementSetId
        );
        
        insert junction;
        return junction.Id;
    }
    
    /**
     * Links multiple templates to a requirement set
     * @param templateIds List of template IDs
     * @param requirementSetId The requirement set ID
     * @return List of created junction record IDs
     */
    public static List<Id> linkTemplatesToRequirementSet(List<Id> templateIds, Id requirementSetId) {
        ValidationHelper.requireId(requirementSetId, 'Requirement Set ID');
        ValidationHelper.requireNotEmpty(templateIds, 'Template IDs');
        
        // Get existing links to avoid duplicates
        Set<Id> existingTemplateIds = new Set<Id>();
        for (Requirement_Set_Template__c existing : [
            SELECT Requirement_Template__c
            FROM Requirement_Set_Template__c
            WHERE Requirement_Template__c IN :templateIds
            AND Onboarding_Requirement_Set__c = :requirementSetId
        ]) {
            existingTemplateIds.add(existing.Requirement_Template__c);
        }
        
        List<Requirement_Set_Template__c> junctionsToCreate = new List<Requirement_Set_Template__c>();
        
        for (Id templateId : templateIds) {
            if (!existingTemplateIds.contains(templateId)) {
                junctionsToCreate.add(new Requirement_Set_Template__c(
                    Requirement_Template__c = templateId,
                    Onboarding_Requirement_Set__c = requirementSetId
                ));
            }
        }
        
        if (!junctionsToCreate.isEmpty()) {
            insert junctionsToCreate;
        }
        
        List<Id> junctionIds = new List<Id>();
        for (Requirement_Set_Template__c junction : junctionsToCreate) {
            junctionIds.add(junction.Id);
        }
        return junctionIds;
    }
    
    /**
     * Unlinks a template from a requirement set
     * @param templateId The template ID
     * @param requirementSetId The requirement set ID
     */
    public static void unlinkTemplateFromRequirementSet(Id templateId, Id requirementSetId) {
        ValidationHelper.requireId(templateId, 'Template ID');
        ValidationHelper.requireId(requirementSetId, 'Requirement Set ID');
        
        List<Requirement_Set_Template__c> toDelete = [
            SELECT Id
            FROM Requirement_Set_Template__c
            WHERE Requirement_Template__c = :templateId
            AND Onboarding_Requirement_Set__c = :requirementSetId
        ];
        
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }
    
    /**
     * Gets all requirement sets for a template
     * @param templateId The template ID
     * @return List of requirement set IDs
     */
    public static List<Id> getRequirementSetsForTemplate(Id templateId) {
        if (templateId == null) {
            return new List<Id>();
        }
        
        List<Id> requirementSetIds = new List<Id>();
        for (Requirement_Set_Template__c junction : [
            SELECT Onboarding_Requirement_Set__c
            FROM Requirement_Set_Template__c
            WHERE Requirement_Template__c = :templateId
        ]) {
            requirementSetIds.add(junction.Onboarding_Requirement_Set__c);
        }
        
        return requirementSetIds;
    }
    
    /**
     * Gets all templates for a requirement set
     * @param requirementSetId The requirement set ID
     * @return List of template IDs
     */
    public static List<Id> getTemplatesForRequirementSet(Id requirementSetId) {
        if (requirementSetId == null) {
            return new List<Id>();
        }
        
        List<Id> templateIds = new List<Id>();
        for (Requirement_Set_Template__c junction : [
            SELECT Requirement_Template__c
            FROM Requirement_Set_Template__c
            WHERE Onboarding_Requirement_Set__c = :requirementSetId
        ]) {
            templateIds.add(junction.Requirement_Template__c);
        }
        
        return templateIds;
    }
    
    /**
     * Gets templates with full details for a requirement set
     * @param requirementSetId The requirement set ID
     * @return List of templates
     */
    public static List<Vendor_Program_Onboarding_Req_Template__c> getTemplatesWithDetailsForRequirementSet(Id requirementSetId) {
        if (requirementSetId == null) {
            return new List<Vendor_Program_Onboarding_Req_Template__c>();
        }
        
        Set<Id> templateIds = new Set<Id>();
        for (Requirement_Set_Template__c junction : [
            SELECT Requirement_Template__c
            FROM Requirement_Set_Template__c
            WHERE Onboarding_Requirement_Set__c = :requirementSetId
        ]) {
            templateIds.add(junction.Requirement_Template__c);
        }
        
        if (templateIds.isEmpty()) {
            return new List<Vendor_Program_Onboarding_Req_Template__c>();
        }
        
        return [
            SELECT Id, Requirement_Label__c, Requirement_Type__c, Status__c, Is_Current_Version__c, 
                   Category_Group__c, Onboarding_Status_Field_API_Name__c, 
                   Onboarding_Status_Value_When_Complete__c, Onboarding_Status_Value_When_Denied__c, 
                   Description__c, Default_Status_Options__c, Version__c, Previous_Version__c, Active__c
            FROM Vendor_Program_Onboarding_Req_Template__c
            WHERE Id IN :templateIds
            ORDER BY Requirement_Label__c
        ];
    }
}