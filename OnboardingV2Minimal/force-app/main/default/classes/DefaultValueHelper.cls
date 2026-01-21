/**
 * Utility class for applying default values to records
 * Centralizes default value logic to eliminate duplication
 */
public with sharing class DefaultValueHelper {
    
    /**
     * Applies default values to a Vendor_Program_Requirement_Group__c record
     * @param requirementGroup The requirement group to set defaults on
     */
    public static void applyRequirementGroupDefaults(Vendor_Program_Requirement_Group__c requirementGroup) {
        if (requirementGroup == null) {
            return;
        }
        
        // Set default Status if not provided
        if (String.isBlank(requirementGroup.Status__c)) {
            requirementGroup.Status__c = 'Active';
        }
        
        // Always set Active = true for new groups
        requirementGroup.Active__c = true;
        
        // Set Effective Date to today if not provided
        if (requirementGroup.Effective_Date__c == null) {
            requirementGroup.Effective_Date__c = Date.today();
        }
    }
    
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
     * Applies default values to a Recipient_Group__c record
     * @param recipientGroup The recipient group to set defaults on
     */
    public static void applyRecipientGroupDefaults(Recipient_Group__c recipientGroup) {
        if (recipientGroup == null) {
            return;
        }
        
        // Set default Group_Type__c if not provided
        if (String.isBlank(recipientGroup.Group_Type__c)) {
            recipientGroup.Group_Type__c = 'User';
        }
        
        // Set Is_Active__c = true for new groups
        if (recipientGroup.Is_Active__c == null) {
            recipientGroup.Is_Active__c = true;
        }
    }
    
    /**
     * Applies default values to a Recipient_Group_Member__c record
     * @param member The recipient group member to set defaults on
     */
    public static void applyRecipientGroupMemberDefaults(Recipient_Group_Member__c recipientGroupMember) {
        if (recipientGroupMember == null) {
            return;
        }
        
        // Set default Member_Type__c if not provided
        if (String.isBlank(recipientGroupMember.Member_Type__c)) {
            recipientGroupMember.Member_Type__c = 'User';
        }
        
        // Set default Recipient_Type__c if not provided
        if (String.isBlank(recipientGroupMember.Recipient_Type__c)) {
            recipientGroupMember.Recipient_Type__c = 'To';
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
     * Applies default values to an Onboarding_Requirement_Set__c record
     * @param requirementSet The requirement set to set defaults on
     */
    public static void applyRequirementSetDefaults(Onboarding_Requirement_Set__c requirementSet) {
        if (requirementSet == null) {
            return;
        }
        
        // Set default Status to Draft if not provided or invalid
        if (String.isBlank(requirementSet.Status__c) ||
            !PicklistHelper.isPicklistValueValid('Onboarding_Requirement_Set__c', 'Status__c', requirementSet.Status__c)) {
            requirementSet.Status__c = PicklistHelper.getValidPicklistValue(
                'Onboarding_Requirement_Set__c',
                'Status__c',
                'Draft'
            );
        }
        
        // Set Active to true when Status is Active
        if (requirementSet.Status__c == 'Active' && (requirementSet.Active__c == null || requirementSet.Active__c == false)) {
            requirementSet.Active__c = true;
        } else if (requirementSet.Active__c == null) {
            requirementSet.Active__c = false;
        }
        
        // Set default Version to 1 if not provided
        if (requirementSet.Version__c == null) {
            requirementSet.Version__c = 1;
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