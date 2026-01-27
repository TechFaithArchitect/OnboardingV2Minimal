/**
 * Consolidated Requirement Domain Service
 * Combines VendorProgramRequirementService and VendorProgramRequirementGroupService
 * Phase 2: Domain Service Consolidation
 * 
 * Handles all business logic related to:
 * - Vendor_Program_Requirement__c records
 */
public with sharing class RequirementDomainService {
    
    // ============================================
    // VENDOR PROGRAM REQUIREMENT OPERATIONS
    // ============================================
    
    /**
     * Searches for vendor program requirements
     * @param vendorProgramRequirements The search text
     * @return List of matching requirements
     */
    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Requirement__c> searchVendorProgramRequirements(String vendorProgramRequirements) {
        return VendorOnboardingWizardRepository.searchVendorProgramRequirements(vendorProgramRequirements);
    }
    
    /**
     * Creates a new vendor program requirement
     * @param vendorProgramRequirement The requirement record to create
     * @return The ID of the created requirement
     * @throws AuraHandledException if requirement is null or vendor program ID is null
     */
    @AuraEnabled
    public static Id createVendorProgramRequirement(Vendor_Program_Requirement__c vendorProgramRequirement) {
        ValidationHelper.requireRecord(vendorProgramRequirement, 'Vendor Program Requirement');
        ValidationHelper.requireId(vendorProgramRequirement.Vendor_Program__c, 'Vendor Program ID');
        
        return VendorOnboardingWizardRepository.insertVendorProgramRequirement(vendorProgramRequirement);
    }
    
    /**
     * Updates requirement sequences
     * @param requirements List of requirements with updated sequences
     * @throws AuraHandledException if requirements list is null or empty
     */
    @AuraEnabled
    public static void updateRequirementSequences(List<Vendor_Program_Requirement__c> requirements) {
        ValidationHelper.requireNotEmpty(requirements, 'Requirements list');
        VendorOnboardingWizardRepository.updateRequirementSequences(requirements);
    }
    
    /**
     * Gets recent requirements for a vendor program
     * @param vendorProgramId The vendor program ID
     * @return List of recent requirements
     * @throws AuraHandledException if vendorProgramId is null
     */
    @AuraEnabled(cacheable=true)
    public static List<Vendor_Program_Requirement__c> getRecentVendorProgramRequirements(Id vendorProgramId) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        return VendorOnboardingWizardRepository.fetchRecentVendorProgramRequirements(vendorProgramId);
    }
    
    /**
     * Deletes a vendor program requirement
     * @param requirementId The requirement ID to delete
     * @throws AuraHandledException if requirementId is null
     */
    @AuraEnabled
    public static void deleteVendorProgramRequirement(Id requirementId) {
        ValidationHelper.requireId(requirementId, 'Requirement ID');
        VendorOnboardingWizardRepository.deleteVendorProgramRequirement(requirementId);
    }
    
}
