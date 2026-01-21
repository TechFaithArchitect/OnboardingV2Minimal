/**
 * Service for Vendor Program domain operations
 * Handles all business logic related to Vendor_Customization__c records
 */
public with sharing class VendorProgramService {
    
    /**
     * Searches for vendor programs by name
     * @param vendorProgramName The vendor program name to search for
     * @return List of matching vendor programs
     */
    public static List<Vendor_Customization__c> searchVendorPrograms(String vendorProgramName) {
        return VendorOnboardingWizardRepository.searchVendorPrograms(vendorProgramName);
    }

    /**
     * Account-aware vendor program search with eligibility gating (PerfectVision fallback).
     * @param accountId Account context (reserved for future logic)
     * @param vendorProgramName Search text
     * @param eligibilityPassed If false/null, only PerfectVision is returned; if true, PerfectVision is excluded
     */
    public static List<Vendor_Customization__c> searchVendorProgramsForAccount(
        Id accountId,
        String vendorProgramName,
        Boolean eligibilityPassed,
        Boolean accountHasNda,
        Boolean accountHasProgramBase
    ) {
        return VendorOnboardingWizardRepository.searchVendorProgramsForAccount(
            accountId,
            vendorProgramName,
            eligibilityPassed,
            accountHasNda,
            accountHasProgramBase
        );
    }
    
    /**
     * Gets recent vendor programs
     * @param limitCount Maximum number of records to return
     * @return List of recent vendor programs
     */
    public static List<Vendor_Customization__c> getRecentVendorPrograms(Integer limitCount) {
        return VendorOnboardingWizardRepository.getRecentVendorPrograms(limitCount);
    }
    
    /**
     * Creates a new vendor program record.
     * Applies server-side guards to prevent accidental duplicate draft programs
     * for the same vendor when using the default wizard path.
     *
     * Guard behaviour:
     * - If a Draft, inactive Vendor_Customization__c already exists for the same Vendor__c
     *   with the same Name (typically 'New Vendor Program' from the dashboard/wizard),
     *   this method will return the existing Id instead of creating a new record.
     *
     * @param vendorProgram The vendor program record to create
     * @param vendorId The ID of the associated vendor
     * @return The ID of the created or existing vendor program
     * @throws AuraHandledException if vendorProgram is null or vendorId is null
     */
    public static Id createVendorProgram(Vendor_Customization__c vendorProgram, Id vendorId) {
        ValidationHelper.requireRecord(vendorProgram, 'Vendor Program');
        ValidationHelper.requireId(vendorId, 'Vendor ID');
        
        vendorProgram.Vendor__c = vendorId;
        
        // Apply default values
        DefaultValueHelper.applyVendorProgramDefaults(vendorProgram);

        // Server-side duplicate guard:
        // If this is the default "New Vendor Program" path (or no Name was provided),
        // and there is already a Draft, inactive program for this vendor with the same Name,
        // reuse the existing record instead of creating a duplicate.
        String effectiveName = String.isBlank(vendorProgram.Name)
            ? 'New Vendor Program'
            : vendorProgram.Name;

        // Only apply the guard when using the default name pattern to avoid blocking
        // legitimate custom-named programs.
        if (effectiveName == 'New Vendor Program') {
            String draftStatus = PicklistHelper.getValidPicklistValue(
                'Vendor_Customization__c',
                'Status__c',
                'Draft'
            );
            List<Vendor_Customization__c> existingDrafts;
            if (String.isBlank(draftStatus)) {
                existingDrafts = [
                    SELECT Id
                    FROM Vendor_Customization__c
                    WHERE Vendor__c = :vendorId
                      AND Name = :effectiveName
                      AND (Active__c = false OR Active__c = null)
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            } else {
                existingDrafts = [
                    SELECT Id
                    FROM Vendor_Customization__c
                    WHERE Vendor__c = :vendorId
                      AND Name = :effectiveName
                      AND Status__c = :draftStatus
                      AND (Active__c = false OR Active__c = null)
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            }

            if (!existingDrafts.isEmpty()) {
                return existingDrafts[0].Id;
            }
        }

        return VendorOnboardingWizardRepository.insertVendorProgram(vendorProgram);
    }
    
    /**
     * Finalizes a vendor program by linking it to groups
     * @param vendorProgramId The vendor program ID
     * @param vendorId The vendor ID
     * @param vendorProgramGroupId The vendor program group ID
     * @param vendorProgramRequirementGroupId The requirement group ID
     * @throws AuraHandledException if required IDs are null
     */
    public static void finalizeVendorProgram(
        Id vendorProgramId, 
        Id vendorId, 
        Id vendorProgramGroupId, 
        Id vendorProgramRequirementGroupId
    ) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        ValidationHelper.requireId(vendorId, 'Vendor ID');
        
        VendorOnboardingWizardRepository.linkVendorProgramToGroups(
            vendorProgramId,
            vendorId,
            vendorProgramGroupId,
            vendorProgramRequirementGroupId
        );
    }
    
    /**
     * Gets the vendor program group ID for a vendor program
     * @param vendorProgramId The vendor program ID
     * @return The vendor program group ID, or null if not found
     * @throws AuraHandledException if vendorProgramId is null
     */
    public static Id getVendorProgramGroupForVendorProgram(Id vendorProgramId) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        return VendorOnboardingWizardRepository.getVendorProgramGroupForVendorProgram(vendorProgramId);
    }
    
    /**
     * Gets the requirement group ID for a vendor program
     * @param vendorProgramId The vendor program ID
     * @return The requirement group ID, or null if not found
     * @throws AuraHandledException if vendorProgramId is null
     */
    public static Id getVendorProgramRequirementGroupForVendorProgram(Id vendorProgramId) {
        ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
        return VendorOnboardingWizardRepository.getVendorProgramRequirementGroupForVendorProgram(vendorProgramId);
    }
}