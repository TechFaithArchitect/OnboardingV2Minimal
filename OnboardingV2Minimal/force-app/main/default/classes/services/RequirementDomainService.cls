/**
 * Consolidated Requirement Domain Service
 * Combines VendorProgramRequirementService and VendorProgramRequirementGroupService
 * Phase 2: Domain Service Consolidation
 *
 * Handles all business logic related to:
 * - Vendor_Program_Requirement__c records
 * - Vendor_Program_Requirement_Group__c records
 */
public with sharing class RequirementDomainService {
  // ============================================
  // VENDOR PROGRAM REQUIREMENT OPERATIONS
  // ============================================

  /**
   * Searches for vendor program requirements
   * @param vendorProgramRequirements The search text
   * @return List of matching requirements
   */
  @AuraEnabled(cacheable=true)
  public static List<Vendor_Program_Requirement__c> searchVendorProgramRequirements(
    String vendorProgramRequirements
  ) {
    return VendorOnboardingWizardRepository.searchVendorProgramRequirements(
      vendorProgramRequirements
    );
  }

  /**
   * Creates a new vendor program requirement
   * @param vendorProgramRequirement The requirement record to create
   * @return The ID of the created requirement
   * @throws AuraHandledException if requirement is null or vendor program ID is null
   */
  @AuraEnabled
  public static Id createVendorProgramRequirement(
    Vendor_Program_Requirement__c vendorProgramRequirement
  ) {
    ValidationHelper.requireRecord(
      vendorProgramRequirement,
      'Vendor Program Requirement'
    );
    ValidationHelper.requireId(
      vendorProgramRequirement.Vendor_Program__c,
      'Vendor Program ID'
    );

    return VendorOnboardingWizardRepository.insertVendorProgramRequirement(
      vendorProgramRequirement
    );
  }

  /**
   * Bulk creates requirements from templates
   * @param vendorProgramId The vendor program ID
   * @param templateIds List of template IDs to create requirements from
   * @param defaultStatus Default status for new requirements
   * @param defaultIsRequired Default Is_Required__c value
   * @return BulkCreateRequirementsResult with created and skipped IDs
   */
  @AuraEnabled
  public static BulkCreateRequirementsResult bulkCreateRequirementsFromTemplates(
    Id vendorProgramId,
    List<Id> templateIds,
    String defaultStatus,
    Boolean defaultIsRequired
  ) {
    BulkCreateRequirementsResult bulkCreateRequirementsResult = new BulkCreateRequirementsResult();

    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
    ValidationHelper.requireNotEmpty(templateIds, 'Template IDs');

    // Check for existing requirements to prevent duplicates
    Set<Id> templateIdSet = new Set<Id>(templateIds);
    List<Vendor_Program_Requirement__c> existingRequirements = VendorOnboardingWizardRepository.getExistingRequirementsForTemplates(
      vendorProgramId,
      templateIdSet
    );

    Set<Id> existingTemplateIds = new Set<Id>();
    for (Vendor_Program_Requirement__c existing : existingRequirements) {
      existingTemplateIds.add(existing.Requirement_Template__c);
    }

    // Get template details for creating requirements
    List<Vendor_Program_Onboarding_Req_Template__c> requirementTemplates = [
      SELECT Id, Requirement_Label__c, Requirement_Type__c
      FROM Vendor_Program_Onboarding_Req_Template__c
      WHERE Id IN :templateIdSet
    ];

    // Create requirements only for templates that don't already have requirements
    List<Vendor_Program_Requirement__c> requirementsToCreate = new List<Vendor_Program_Requirement__c>();
    Integer sequence = 1;

    for (
      Vendor_Program_Onboarding_Req_Template__c requirementTemplate : requirementTemplates
    ) {
      if (!existingTemplateIds.contains(requirementTemplate.Id)) {
        Vendor_Program_Requirement__c requirement = new Vendor_Program_Requirement__c(
          Vendor_Program__c = vendorProgramId,
          Requirement_Template__c = requirementTemplate.Id,
          Status__c = defaultStatus != null ? defaultStatus : 'Active',
          Is_Required__c = defaultIsRequired != null ? defaultIsRequired : true,
          Sequence__c = sequence++
        );
        requirementsToCreate.add(requirement);
      } else {
        bulkCreateRequirementsResult.skippedTemplateIds.add(
          requirementTemplate.Id
        );
      }
    }

    if (!requirementsToCreate.isEmpty()) {
      List<Vendor_Program_Requirement__c> createdRequirements = VendorOnboardingWizardRepository.bulkInsertVendorProgramRequirements(
        requirementsToCreate
      );
      bulkCreateRequirementsResult.createdRequirementIds = new List<Id>();
      for (
        Vendor_Program_Requirement__c vendorProgramRequirement : createdRequirements
      ) {
        bulkCreateRequirementsResult.createdRequirementIds.add(
          vendorProgramRequirement.Id
        );
      }
    }

    bulkCreateRequirementsResult.success = true;
    return bulkCreateRequirementsResult;
  }

  /**
   * Updates requirement sequences
   * @param requirements List of requirements with updated sequences
   * @throws AuraHandledException if requirements list is null or empty
   */
  @AuraEnabled
  public static void updateRequirementSequences(
    List<Vendor_Program_Requirement__c> requirements
  ) {
    ValidationHelper.requireNotEmpty(requirements, 'Requirements list');
    VendorOnboardingWizardRepository.updateRequirementSequences(requirements);
  }

  /**
   * Gets recent requirements for a vendor program
   * @param vendorProgramId The vendor program ID
   * @return List of recent requirements
   * @throws AuraHandledException if vendorProgramId is null
   */
  @AuraEnabled(cacheable=true)
  public static List<Vendor_Program_Requirement__c> getRecentVendorProgramRequirements(
    Id vendorProgramId
  ) {
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
    return VendorOnboardingWizardRepository.fetchRecentVendorProgramRequirements(
      vendorProgramId
    );
  }

  /**
   * Gets requirements by group ID
   * @param requirementGroupId The requirement group ID
   * @return List of requirements in the group
   * @throws AuraHandledException if requirementGroupId is null
   */
  @AuraEnabled(cacheable=true)
  public static List<Vendor_Program_Requirement__c> getRequirementsByGroup(
    Id requirementGroupId
  ) {
    ValidationHelper.requireId(requirementGroupId, 'Requirement Group ID');
    return VendorOnboardingWizardRepository.getRequirementsByGroup(
      requirementGroupId
    );
  }

  /**
   * Deletes a vendor program requirement
   * @param requirementId The requirement ID to delete
   * @throws AuraHandledException if requirementId is null
   */
  @AuraEnabled
  public static void deleteVendorProgramRequirement(Id requirementId) {
    ValidationHelper.requireId(requirementId, 'Requirement ID');
    VendorOnboardingWizardRepository.deleteVendorProgramRequirement(
      requirementId
    );
  }

  /**
   * Result class for bulk create operations
   */
  public class BulkCreateRequirementsResult {
    @AuraEnabled
    public Boolean success = false;
    @AuraEnabled
    public List<Id> createdRequirementIds = new List<Id>();
    @AuraEnabled
    public List<Id> skippedTemplateIds = new List<Id>();
    @AuraEnabled
    public String errorMessage;
  }

  // ============================================
  // VENDOR PROGRAM REQUIREMENT GROUP OPERATIONS
  // ============================================

  /**
   * Searches for requirement groups by name
   * @param requirementGroupName The group name to search for
   * @return List of matching requirement groups
   */
  @AuraEnabled(cacheable=true)
  public static List<Vendor_Program_Requirement_Group__c> searchVendorProgramRequirementGroups(
    String requirementGroupName
  ) {
    return VendorOnboardingWizardRepository.searchVendorProgramRequirementGroups(
      requirementGroupName
    );
  }

  /**
   * Gets all requirement groups
   * @return List of all requirement groups
   */
  @AuraEnabled(cacheable=true)
  public static List<Vendor_Program_Requirement_Group__c> getAllVendorProgramRequirementGroups() {
    return VendorOnboardingWizardRepository.getAllVendorProgramRequirementGroups();
  }

  /**
   * Creates a new requirement group
   * @param vendorProgramRequirementGroup The group record to create
   * @return The ID of the created group
   * @throws AuraHandledException if group is null or name is blank
   */
  @AuraEnabled
  public static Id createVendorProgramRequirementGroup(
    Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup
  ) {
    ValidationHelper.requireRecord(
      vendorProgramRequirementGroup,
      'Vendor Program Requirement Group'
    );
    ValidationHelper.requireField(vendorProgramRequirementGroup.Name, 'Name');

    // Apply default values
    DefaultValueHelper.applyRequirementGroupDefaults(
      vendorProgramRequirementGroup
    );

    return VendorOnboardingWizardRepository.insertVendorProgramRequirementGroup(
      vendorProgramRequirementGroup
    );
  }
}
