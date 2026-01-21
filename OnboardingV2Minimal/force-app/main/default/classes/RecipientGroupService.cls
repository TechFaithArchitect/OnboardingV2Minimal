/**
 * Service for Recipient Group domain operations
 * Handles all business logic related to Recipient_Group__c and related records
 */
public with sharing class RecipientGroupService {
    
    /**
     * Searches for recipient groups by name
     * @param recipientGroupName The group name to search for
     * @return List of matching recipient groups
     */
    public static List<Recipient_Group__c> searchRecipientGroups(String recipientGroupName) {
        return VendorOnboardingWizardRepository.searchRecipientGroups(recipientGroupName);
    }
    
    /**
     * Creates a new recipient group
     * @param recipientGroup The recipient group record to create
     * @return The ID of the created group
     * @throws AuraHandledException if group is null or name is blank
     */
    public static Id createRecipientGroup(Recipient_Group__c recipientGroup) {
        ValidationHelper.requireRecord(recipientGroup, 'Recipient Group');
        ValidationHelper.requireField(recipientGroup.Name, 'Name');
        
        // Apply default values
        DefaultValueHelper.applyRecipientGroupDefaults(recipientGroup);
        
        return VendorOnboardingWizardRepository.insertRecipientGroup(recipientGroup);
    }
    
    /**
     * Creates a new recipient group member
     * @param recipientGroupMember The member record to create
     * @return The ID of the created member
     * @throws AuraHandledException if member is null or recipient group ID is null
     */
    public static Id createRecipientGroupMember(Recipient_Group_Member__c recipientGroupMember) {
        ValidationHelper.requireRecord(recipientGroupMember, 'Recipient Group Member');
        ValidationHelper.requireId(recipientGroupMember.Recipient_Group__c, 'Recipient Group ID');
        
        // Apply default values
        DefaultValueHelper.applyRecipientGroupMemberDefaults(recipientGroupMember);
        
        return VendorOnboardingWizardRepository.insertRecipientGroupMember(recipientGroupMember);
    }
    
    /**
     * Gets recipient groups for a vendor program
     * @param vendorProgramId The vendor program ID
     * @return List of recipient groups linked to the vendor program
     * @throws AuraHandledException if vendorProgramId is null
     */
    public static List<Vendor_Program_Recipient_Group__c> getRecipientGroupsForVendorProgram(Id vendorProgramId) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        return VendorOnboardingWizardRepository.getRecipientGroupsForVendorProgram(vendorProgramId);
    }
    
    /**
     * Gets members of a recipient group
     * @param recipientGroupId The recipient group ID
     * @return List of recipient group members
     * @throws AuraHandledException if recipientGroupId is null
     */
    public static List<Recipient_Group_Member__c> getRecipientGroupMembers(Id recipientGroupId) {
        ValidationHelper.requireId(recipientGroupId, 'Recipient Group ID');
        return VendorOnboardingWizardRepository.getRecipientGroupMembers(recipientGroupId);
    }
    
    /**
     * Searches for vendor program recipient groups
     * @param vprgName The search text
     * @return List of matching vendor program recipient groups
     */
    public static List<Vendor_Program_Recipient_Group__c> searchVendorProgramRecipientGroups(String vprgName) {
        return VendorOnboardingWizardRepository.searchVendorProgramRecipientGroups(vprgName);
    }
    
    /**
     * Creates a link between a vendor program and a recipient group
     * @param vendorProgramId The vendor program ID
     * @param recipientGroupId The recipient group ID
     * @return The ID of the created link
     * @throws AuraHandledException if either ID is null
     */
    public static Id createVendorProgramRecipientGroupLink(Id vendorProgramId, Id recipientGroupId) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        ValidationHelper.requireId(recipientGroupId, 'Recipient Group ID');
        
        return VendorOnboardingWizardRepository.insertVendorProgramRecipientGroupLink(vendorProgramId, recipientGroupId);
    }
    
    /**
     * Creates a vendor program recipient group link with template information
     * @param vendorProgramId The vendor program ID
     * @param recipientGroupId The recipient group ID
     * @param communicationTemplateId Optional communication template ID
     * @param triggerCondition Optional trigger condition
     * @return The ID of the created link
     * @throws AuraHandledException if vendorProgramId or recipientGroupId is null
     */
    public static Id createVendorProgramRecipientGroupWithTemplate(
        Id vendorProgramId, 
        Id recipientGroupId, 
        Id communicationTemplateId,
        String triggerCondition
    ) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        ValidationHelper.requireId(recipientGroupId, 'Recipient Group ID');
        
        // Create or update Vendor_Program_Recipient_Group__c link
        Vendor_Program_Recipient_Group__c link = new Vendor_Program_Recipient_Group__c(
            Vendor_Program__c = vendorProgramId,
            Recipient_Group__c = recipientGroupId,
            Status__c = 'Active',
            Is_Active__c = true
        );
        
        return VendorOnboardingWizardRepository.insertVendorProgramRecipientGroup(link);
    }
}