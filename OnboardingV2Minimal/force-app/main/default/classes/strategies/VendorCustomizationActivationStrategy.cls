/**
 * Activation strategy for Vendor_Customization__c objects
 * Handles vendor-specific activation logic
 */
public with sharing class VendorCustomizationActivationStrategy implements ActivationStrategy {
    
    public void activate(Id recordId) {
        VendorProgramActivationService.activate(recordId);
    }
}