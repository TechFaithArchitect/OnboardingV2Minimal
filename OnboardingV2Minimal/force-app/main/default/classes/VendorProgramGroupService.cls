/**
 * Service for Vendor Program Group domain operations
 * Handles all business logic related to Vendor_Program_Group__c records
 */
public with sharing class VendorProgramGroupService {
    
    /**
     * Searches for vendor program groups by name
     * @param vendorProgramGroupName The group name to search for
     * @return List of matching vendor program groups
     */
    public static List<Vendor_Program_Group__c> searchVendorProgramGroups(String vendorProgramGroupName) {
        return VendorOnboardingWizardRepository.searchVendorProgramGroups(vendorProgramGroupName);
    }
    
    /**
     * Gets all vendor program groups
     * @return List of all vendor program groups
     */
    public static List<Vendor_Program_Group__c> getAllVendorProgramGroups() {
        return VendorOnboardingWizardRepository.getAllVendorProgramGroups();
    }
    
    /**
     * Creates a new vendor program group
     * @param vendorProgramGroup The group record to create
     * @return The ID of the created group
     * @throws AuraHandledException if required fields are blank
     */
    public static Id createVendorProgramGroup(Vendor_Program_Group__c vendorProgramGroup) {
        // Validate required fields - user must provide values (no auto-filling)
        ValidationHelper.requireFieldForObject(
            vendorProgramGroup.Label__c, 
            'Vendor Program Group', 
            'Label__c'
        );
        ValidationHelper.requireFieldForObject(
            vendorProgramGroup.Logic_Type__c, 
            'Vendor Program Group', 
            'Logic_Type__c'
        );
        
        return VendorOnboardingWizardRepository.insertVendorProgramGroup(vendorProgramGroup);
    }
    
    /**
     * Gets a default Logic_Type__c value for Vendor_Program_Group__c
     * Tries to get the default picklist value, falls back to 'ALL'
     * @return The default logic type value
     */
    public static String getDefaultLogicType() {
        try {
            // Try to get default picklist value using schema describe
            Schema.DescribeFieldResult fieldDescribe = Vendor_Program_Group__c.Logic_Type__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            
            // Look for a default value first
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isDefaultValue()) {
                    return entry.getValue();
                }
            }
            
            // If no default, use the first active value
            if (!picklistValues.isEmpty()) {
                return picklistValues[0].getValue();
            }
        } catch (Exception ex) {
            System.debug('Error getting default Logic_Type__c: ' + ex.getMessage());
        }
        
        // Fallback to 'ALL' if unable to get from picklist
        return 'ALL';
    }
}