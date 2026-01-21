/**
 * Service for Vendor domain operations
 * Handles all business logic related to Vendor__c records
 */
public with sharing class VendorService {
    
    /**
     * Searches for vendors by name
     * @param vendorName The vendor name to search for
     * @return List of matching vendors
     */
    public static List<Vendor__c> searchVendors(String vendorName) {
        return VendorOnboardingWizardRepository.searchVendors(vendorName);
    }
    
    /**
     * Creates a new vendor record
     * @param vendor The vendor record to create
     * @return The ID of the created vendor
     * @throws AuraHandledException if vendor is null or name is blank
     */
    public static Id createVendor(Vendor__c vendor) {
        ValidationHelper.requireRecord(vendor, 'Vendor');
        ValidationHelper.requireField(vendor.Name, 'Vendor Name');
        
        // Apply default values
        DefaultValueHelper.applyVendorDefaults(vendor);
        
        return VendorOnboardingWizardRepository.insertVendor(vendor);
    }
    
    /**
     * Gets all vendors with their associated vendor programs for hierarchical display
     * @return List of vendors with related programs
     */
    public static List<Vendor__c> getVendorsWithPrograms() {
        return VendorOnboardingWizardRepository.getVendorsWithPrograms();
    }
    
    /**
     * Gets vendors with programs filtered by search text
     * @param searchText The search text to filter by
     * @return List of matching vendors with programs
     */
    public static List<Vendor__c> searchVendorsWithPrograms(String searchText) {
        if (String.isBlank(searchText)) {
            return getVendorsWithPrograms();
        }
        return VendorOnboardingWizardRepository.searchVendorsWithPrograms(searchText.trim());
    }
}