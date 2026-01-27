/**
 * Utility class for applying default values to records
 * Centralizes default value logic to eliminate duplication
 */
public with sharing class DefaultValueHelper {
    
    /**
     * Applies default values to a Vendor_Customization__c record
     * @param vendorProgram The vendor program to set defaults on
     */
    public static void applyVendorProgramDefaults(Vendor_Customization__c vendorProgram) {
        if (vendorProgram == null) {
            return;
        }
        
        // Set default Status if not provided
        if (String.isBlank(vendorProgram.Status__c) ||
            !PicklistHelper.isPicklistValueValid('Vendor_Customization__c', 'Status__c', vendorProgram.Status__c)) {
            vendorProgram.Status__c = PicklistHelper.getValidPicklistValue(
                'Vendor_Customization__c',
                'Status__c',
                'Draft'
            );
        }
        
        // Set Active = false for new programs (draft)
        if (vendorProgram.Active__c == null) {
            vendorProgram.Active__c = false;
        }
    }
    
    /**
     * Applies default values to a Vendor__c record
     * @param vendor The vendor to set defaults on
     */
    public static void applyVendorDefaults(Vendor__c vendor) {
        if (vendor == null) {
            return;
        }
        
        // Set Active = false for new vendors (draft)
        if (vendor.Active__c == null) {
            vendor.Active__c = false;
        }
    }
    
    /**
     * Applies default values to an Onboarding_Status_Rules_Engine__c record
     * @param rulesEngine The rules engine to set defaults on
     */
    public static void applyStatusRulesEngineDefaults(Onboarding_Status_Rules_Engine__c rulesEngine) {
        if (rulesEngine == null) {
            return;
        }
        
        // Set Active = true for new rules engines
        if (rulesEngine.Active__c == null) {
            rulesEngine.Active__c = true;
        }
    }
    
    /**
     * Applies default values to a Training_System__c record
     * @param trainingSystem The training system to set defaults on
     */
    public static void applyTrainingSystemDefaults(Training_System__c trainingSystem) {
        if (trainingSystem == null) {
            return;
        }
        
        // Set Active = true for new training systems (user-controlled via checkbox)
        if (trainingSystem.Active__c == null) {
            trainingSystem.Active__c = true;
        }
    }
    
    /**
     * Default onboarding opportunity values (placeholder until wired to custom metadata).
     */
    public static Opportunity applyOnboardingOpportunityDefaults(Opportunity opp) {
        if (opp == null) {
            opp = new Opportunity();
        }
        if (String.isBlank(opp.StageName)) {
            opp.StageName = 'Prospecting';
        }
        if (opp.CloseDate == null) {
            opp.CloseDate = Date.today().addDays(14);
        }
        return opp;
    }
}
