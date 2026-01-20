/**
 * Consolidated Vendor Domain Service
 * Combines VendorService, VendorProgramService, and VendorProgramGroupService
 * Phase 2: Domain Service Consolidation
 *
 * Handles all business logic related to:
 * - Vendor__c records
 * - Vendor_Customization__c (Vendor Program) records
 * - Vendor_Program_Group__c records
 */
public with sharing class VendorDomainService {
  // ============================================
  // VENDOR OPERATIONS
  // ============================================

  /**
   * Searches for vendors by name
   * @param vendorName The vendor name to search for
   * @return List of matching vendors
   */
  @AuraEnabled(cacheable=true)
  public static List<Vendor__c> searchVendors(String vendorName) {
    return VendorOnboardingWizardRepository.searchVendors(vendorName);
  }

  /**
   * Creates a new vendor record
   * @param vendor The vendor record to create
   * @return The ID of the created vendor
   * @throws AuraHandledException if vendor is null or name is blank
   */
  @AuraEnabled
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
  @AuraEnabled(cacheable=true)
  public static List<Vendor__c> getVendorsWithPrograms() {
    return VendorOnboardingWizardRepository.getVendorsWithPrograms();
  }

  /**
   * Gets vendors with programs filtered by search text
   * @param searchText The search text to filter by
   * @return List of matching vendors with programs
   */
  @AuraEnabled(cacheable=true)
  public static List<Vendor__c> searchVendorsWithPrograms(String searchText) {
    if (String.isBlank(searchText)) {
      return getVendorsWithPrograms();
    }
    return VendorOnboardingWizardRepository.searchVendorsWithPrograms(
      searchText.trim()
    );
  }

  // ============================================
  // VENDOR PROGRAM OPERATIONS
  // ============================================

  /**
   * Searches for vendor programs by name
   * @param vendorProgramName The vendor program name to search for
   * @return List of matching vendor programs
   */
  @AuraEnabled(cacheable=true)
  public static List<Vendor_Customization__c> searchVendorPrograms(
    String vendorProgramName
  ) {
    return VendorOnboardingWizardRepository.searchVendorPrograms(
      vendorProgramName
    );
  }

  /**
   * Account-aware vendor program search with eligibility gating (PerfectVision fallback).
   * @param accountId Account context (reserved for future logic)
   * @param vendorProgramName Search text
   * @param eligibilityPassed If false/null, only PerfectVision is returned; if true, PerfectVision is excluded
   */
  @AuraEnabled(cacheable=true)
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
  @AuraEnabled(cacheable=true)
  public static List<Vendor_Customization__c> getRecentVendorPrograms(
    Integer limitCount
  ) {
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
  @AuraEnabled
  public static Id createVendorProgram(
    Vendor_Customization__c vendorProgram,
    Id vendorId
  ) {
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
          WHERE
            Vendor__c = :vendorId
            AND Name = :effectiveName
            AND (Active__c = FALSE
            OR Active__c = NULL)
          ORDER BY CreatedDate DESC
          LIMIT 1
        ];
      } else {
        existingDrafts = [
          SELECT Id
          FROM Vendor_Customization__c
          WHERE
            Vendor__c = :vendorId
            AND Name = :effectiveName
            AND Status__c = :draftStatus
            AND (Active__c = FALSE
            OR Active__c = NULL)
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
  @AuraEnabled
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
  @AuraEnabled(cacheable=true)
  public static Id getVendorProgramGroupForVendorProgram(Id vendorProgramId) {
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
    return VendorOnboardingWizardRepository.getVendorProgramGroupForVendorProgram(
      vendorProgramId
    );
  }

  /**
   * Gets the requirement group ID for a vendor program
   * @param vendorProgramId The vendor program ID
   * @return The requirement group ID, or null if not found
   * @throws AuraHandledException if vendorProgramId is null
   */
  @AuraEnabled(cacheable=true)
  public static Id getVendorProgramRequirementGroupForVendorProgram(
    Id vendorProgramId
  ) {
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
    return VendorOnboardingWizardRepository.getVendorProgramRequirementGroupForVendorProgram(
      vendorProgramId
    );
  }

  // ============================================
  // VENDOR PROGRAM GROUP OPERATIONS
  // ============================================

  /**
   * Searches for vendor program groups by name
   * @param vendorProgramGroupName The group name to search for
   * @return List of matching vendor program groups
   */
  @AuraEnabled(cacheable=true)
  public static List<Vendor_Program_Group__c> searchVendorProgramGroups(
    String vendorProgramGroupName
  ) {
    return VendorOnboardingWizardRepository.searchVendorProgramGroups(
      vendorProgramGroupName
    );
  }

  /**
   * Gets all vendor program groups
   * @return List of all vendor program groups
   */
  @AuraEnabled(cacheable=true)
  public static List<Vendor_Program_Group__c> getAllVendorProgramGroups() {
    return VendorOnboardingWizardRepository.getAllVendorProgramGroups();
  }

  /**
   * Creates a new vendor program group
   * @param vendorProgramGroup The group record to create
   * @return The ID of the created group
   * @throws AuraHandledException if required fields are blank
   */
  @AuraEnabled
  public static Id createVendorProgramGroup(
    Vendor_Program_Group__c vendorProgramGroup
  ) {
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

    return VendorOnboardingWizardRepository.insertVendorProgramGroup(
      vendorProgramGroup
    );
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
