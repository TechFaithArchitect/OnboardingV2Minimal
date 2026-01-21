/**
 * Service for Vendor Program Requirement Group domain operations
 * Handles all business logic related to Vendor_Program_Requirement_Group__c records
 */
public with sharing class VendorProgramRequirementGroupService {
    
    /**
     * Searches for requirement groups by name
     * @param requirementGroupName The group name to search for
     * @return List of matching requirement groups
     */
    public static List<Vendor_Program_Requirement_Group__c> searchVendorProgramRequirementGroups(String requirementGroupName) {
        return VendorOnboardingWizardRepository.searchVendorProgramRequirementGroups(requirementGroupName);
    }
    
    /**
     * Gets all requirement groups
     * @return List of all requirement groups
     */
    public static List<Vendor_Program_Requirement_Group__c> getAllVendorProgramRequirementGroups() {
        return VendorOnboardingWizardRepository.getAllVendorProgramRequirementGroups();
    }
    
    /**
     * Creates a new requirement group
     * @param vendorProgramRequirementGroup The group record to create
     * @return The ID of the created group
     * @throws AuraHandledException if group is null or name is blank
     */
    public static Id createVendorProgramRequirementGroup(Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup) {
        ValidationHelper.requireRecord(vendorProgramRequirementGroup, 'Vendor Program Requirement Group');
        ValidationHelper.requireField(vendorProgramRequirementGroup.Name, 'Name');
        
        // Apply default values
        DefaultValueHelper.applyRequirementGroupDefaults(vendorProgramRequirementGroup);
        
        return VendorOnboardingWizardRepository.insertVendorProgramRequirementGroup(vendorProgramRequirementGroup);
    }
}