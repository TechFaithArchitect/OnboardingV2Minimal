/**
 * Communication Domain Service
 * Handles business logic related to Communication_Template__c records.
 */
public with sharing class CommunicationDomainService {
    
    // ============================================
    // COMMUNICATION TEMPLATE OPERATIONS
    // ============================================
    
    /**
     * Gets all communication templates
     * @return List of all communication templates
     */
    @AuraEnabled(cacheable=true)
    public static List<Communication_Template__c> getCommunicationTemplates() {
        return VendorOnboardingWizardRepository.fetchCommunicationTemplates();
    }
    
    /**
     * Links a communication template to a vendor program
     * @param vendorProgramId The vendor program ID
     * @param templateId The communication template ID
     * @throws AuraHandledException if either ID is null
     */
    @AuraEnabled
    public static void linkCommunicationTemplateToVendorProgram(Id vendorProgramId, Id templateId) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        ValidationHelper.requireId(templateId, 'Template ID');
        
        VendorOnboardingWizardRepository.linkCommunicationTemplate(vendorProgramId, templateId);
    }
    
}
