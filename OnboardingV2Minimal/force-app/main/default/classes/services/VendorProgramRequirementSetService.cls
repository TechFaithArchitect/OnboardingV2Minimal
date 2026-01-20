/**
 * Service for managing the many-to-many relationship between
 * Vendor Programs and Requirement Sets via the Vendor_Program_Requirement_Set__c junction object
 */
public with sharing class VendorProgramRequirementSetService {
    
    /**
     * Links a vendor program to a requirement set via junction object
     * @param vendorProgramId The vendor program ID
     * @param requirementSetId The requirement set ID
     * @return The created junction record ID
     */
    public static Id linkVendorProgramToRequirementSet(Id vendorProgramId, Id requirementSetId) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        ValidationHelper.requireId(requirementSetId, 'Requirement Set ID');
        
        // Check if link already exists
        List<Vendor_Program_Requirement_Set__c> existing = [
            SELECT Id
            FROM Vendor_Program_Requirement_Set__c
            WHERE Vendor_Program__c = :vendorProgramId
            AND Onboarding_Requirement_Set__c = :requirementSetId
            LIMIT 1
        ];
        
        if (!existing.isEmpty()) {
            return existing[0].Id;
        }
        
        Vendor_Program_Requirement_Set__c junction = new Vendor_Program_Requirement_Set__c(
            Vendor_Program__c = vendorProgramId,
            Onboarding_Requirement_Set__c = requirementSetId
        );
        
        insert junction;
        return junction.Id;
    }
    
    /**
     * Links multiple requirement sets to a vendor program
     * @param requirementSetIds List of requirement set IDs
     * @param vendorProgramId The vendor program ID
     * @return List of created junction record IDs
     */
    public static List<Id> linkRequirementSetsToVendorProgram(List<Id> requirementSetIds, Id vendorProgramId) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        ValidationHelper.requireNotEmpty(requirementSetIds, 'Requirement Set IDs');
        
        // Get existing links to avoid duplicates
        Set<Id> existingRequirementSetIds = new Set<Id>();
        for (Vendor_Program_Requirement_Set__c existing : [
            SELECT Onboarding_Requirement_Set__c
            FROM Vendor_Program_Requirement_Set__c
            WHERE Onboarding_Requirement_Set__c IN :requirementSetIds
            AND Vendor_Program__c = :vendorProgramId
        ]) {
            existingRequirementSetIds.add(existing.Onboarding_Requirement_Set__c);
        }
        
        List<Vendor_Program_Requirement_Set__c> junctionsToCreate = new List<Vendor_Program_Requirement_Set__c>();
        
        for (Id requirementSetId : requirementSetIds) {
            if (!existingRequirementSetIds.contains(requirementSetId)) {
                junctionsToCreate.add(new Vendor_Program_Requirement_Set__c(
                    Vendor_Program__c = vendorProgramId,
                    Onboarding_Requirement_Set__c = requirementSetId
                ));
            }
        }
        
        if (!junctionsToCreate.isEmpty()) {
            insert junctionsToCreate;
        }
        
        List<Id> junctionIds = new List<Id>();
        for (Vendor_Program_Requirement_Set__c junction : junctionsToCreate) {
            junctionIds.add(junction.Id);
        }
        return junctionIds;
    }
    
    /**
     * Unlinks a requirement set from a vendor program
     * @param vendorProgramId The vendor program ID
     * @param requirementSetId The requirement set ID
     */
    public static void unlinkRequirementSetFromVendorProgram(Id vendorProgramId, Id requirementSetId) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        ValidationHelper.requireId(requirementSetId, 'Requirement Set ID');
        
        List<Vendor_Program_Requirement_Set__c> toDelete = [
            SELECT Id
            FROM Vendor_Program_Requirement_Set__c
            WHERE Vendor_Program__c = :vendorProgramId
            AND Onboarding_Requirement_Set__c = :requirementSetId
        ];
        
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }
    
    /**
     * Gets all requirement sets for a vendor program
     * @param vendorProgramId The vendor program ID
     * @return List of requirement set IDs
     */
    public static List<Id> getRequirementSetsForVendorProgram(Id vendorProgramId) {
        if (vendorProgramId == null) {
            return new List<Id>();
        }
        
        List<Id> requirementSetIds = new List<Id>();
        for (Vendor_Program_Requirement_Set__c junction : [
            SELECT Onboarding_Requirement_Set__c
            FROM Vendor_Program_Requirement_Set__c
            WHERE Vendor_Program__c = :vendorProgramId
        ]) {
            requirementSetIds.add(junction.Onboarding_Requirement_Set__c);
        }
        
        return requirementSetIds;
    }
    
    /**
     * Gets all vendor programs for a requirement set
     * @param requirementSetId The requirement set ID
     * @return List of vendor program IDs
     */
    public static List<Id> getVendorProgramsForRequirementSet(Id requirementSetId) {
        if (requirementSetId == null) {
            return new List<Id>();
        }
        
        List<Id> vendorProgramIds = new List<Id>();
        for (Vendor_Program_Requirement_Set__c junction : [
            SELECT Vendor_Program__c
            FROM Vendor_Program_Requirement_Set__c
            WHERE Onboarding_Requirement_Set__c = :requirementSetId
        ]) {
            vendorProgramIds.add(junction.Vendor_Program__c);
        }
        
        return vendorProgramIds;
    }
    
    
    /**
     * Gets requirement sets with full details for a vendor program
     * @param vendorProgramId The vendor program ID
     * @return List of requirement sets
     */
    public static List<Onboarding_Requirement_Set__c> getRequirementSetsWithDetailsForVendorProgram(Id vendorProgramId) {
        if (vendorProgramId == null) {
            return new List<Onboarding_Requirement_Set__c>();
        }
        
        Set<Id> requirementSetIds = new Set<Id>();
        for (Vendor_Program_Requirement_Set__c junction : [
            SELECT Onboarding_Requirement_Set__c
            FROM Vendor_Program_Requirement_Set__c
            WHERE Vendor_Program__c = :vendorProgramId
        ]) {
            requirementSetIds.add(junction.Onboarding_Requirement_Set__c);
        }
        
        if (requirementSetIds.isEmpty()) {
            return new List<Onboarding_Requirement_Set__c>();
        }
        
        return [
            SELECT Id, Name, Display_Label__c, Status__c, CreatedDate, LastModifiedDate
            FROM Onboarding_Requirement_Set__c
            WHERE Id IN :requirementSetIds
            ORDER BY Name
        ];
    }
}