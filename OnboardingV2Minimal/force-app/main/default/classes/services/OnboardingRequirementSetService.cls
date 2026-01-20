/**
 * Service for Onboarding Requirement Set domain operations
 * Handles all business logic related to Onboarding_Requirement_Set__c and related templates
 */
public with sharing class OnboardingRequirementSetService {
  /**
   * Creates a new requirement set.
   * Note: Vendor_Program__c field is kept for backward compatibility,
   * but requirement sets should primarily be linked to vendor programs via Vendor_Program_Requirement_Set__c junction records.
   * @param requirementSet The requirement set record to create
   * @param vendorProgramIds Optional list of vendor program IDs to link via junction after creation
   * @return The ID of the created requirement set
   * @throws AuraHandledException if requirementSet is null
   */
  public static Id createOnboardingRequirementSet(
    Onboarding_Requirement_Set__c requirementSet,
    List<Id> vendorProgramIds
  ) {
    ValidationHelper.requireRecord(requirementSet, 'Requirement Set');

    // Apply default values
    DefaultValueHelper.applyRequirementSetDefaults(requirementSet);

    Id requirementSetId = VendorOnboardingWizardRepository.insertOnboardingRequirementSet(
      requirementSet
    );

    // Link requirement set to vendor programs via junction (new approach)
    if (vendorProgramIds != null && !vendorProgramIds.isEmpty()) {
      VendorProgramRequirementSetService.linkRequirementSetsToVendorProgram(
        new List<Id>{ requirementSetId },
        vendorProgramIds[0]
      );

      // Link to additional vendor programs if provided
      if (vendorProgramIds.size() > 1) {
        for (Integer vendorProgramIndex = 1; vendorProgramIndex < vendorProgramIds.size(); vendorProgramIndex++) {
          VendorProgramRequirementSetService.linkVendorProgramToRequirementSet(
            vendorProgramIds[vendorProgramIndex],
            requirementSetId
          );
        }
      }
    }

    return requirementSetId;
  }

  // Overloaded method for backward compatibility (no vendor programs)
  public static Id createOnboardingRequirementSet(
    Onboarding_Requirement_Set__c requirementSet
  ) {
    return createOnboardingRequirementSet(requirementSet, new List<Id>());
  }

  /**
   * Gets all requirement sets
   * @return List of all requirement sets
   */
  public static List<Onboarding_Requirement_Set__c> getOnboardingRequirementSets() {
    return VendorOnboardingWizardRepository.fetchOnboardingRequirementSets();
  }

  /**
   * Searches for requirement sets
   * @param searchText The search text
   * @param vendorProgramId Optional vendor program ID to filter by
   * @return List of matching requirement sets
   */
  public static List<Onboarding_Requirement_Set__c> searchOnboardingRequirementSets(
    String searchText,
    Id vendorProgramId
  ) {
    if (String.isBlank(searchText)) {
      return new List<Onboarding_Requirement_Set__c>();
    }
    return VendorOnboardingWizardRepository.searchOnboardingRequirementSets(
      searchText.trim(),
      vendorProgramId
    );
  }

  /**
   * Gets all Requirement Sets with their associated Templates for hierarchical display
   * @return List of requirement sets with templates
   */
  public static List<Onboarding_Requirement_Set__c> getRequirementSetsWithTemplates() {
    return VendorOnboardingWizardRepository.getRequirementSetsWithTemplates();
  }

  /**
   * Gets Requirement Sets with Templates filtered by search text
   * @param searchText The search text
   * @return List of matching requirement sets with templates
   */
  public static List<Onboarding_Requirement_Set__c> searchRequirementSetsWithTemplates(
    String searchText
  ) {
    if (String.isBlank(searchText)) {
      return getRequirementSetsWithTemplates();
    }
    return VendorOnboardingWizardRepository.searchRequirementSetsWithTemplates(
      searchText.trim()
    );
  }

  /**
   * Links a requirement set to a vendor program
   * @param requirementSetId The requirement set ID
   * @param vendorProgramId The vendor program ID
   * @throws AuraHandledException if either ID is null
   */
  /**
   * Links a requirement set to a vendor program via junction object (new approach).
   * Legacy: Also maintains backward compatibility with Vendor_Program__c field if needed.
   */
  public static void linkRequirementSetToVendorProgram(
    Id requirementSetId,
    Id vendorProgramId
  ) {
    ValidationHelper.requireId(requirementSetId, 'Requirement Set ID');
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');

    // Use new junction approach
    VendorProgramRequirementSetService.linkVendorProgramToRequirementSet(
      vendorProgramId,
      requirementSetId
    );

    // Note: Legacy Vendor_Program__c field on Onboarding_Requirement_Set__c is no longer updated
    // Use Vendor_Program_Requirement_Set__c junction records instead
  }

  /**
   * Creates a new requirement set from an existing one, copying templates
   * @param existingRequirementSetId The existing requirement set ID
   * @param vendorProgramId The vendor program ID for the new set
   * @return The ID of the newly created requirement set
   * @throws AuraHandledException if either ID is null
   */
  public static Id createRequirementSetFromExisting(
    Id existingRequirementSetId,
    Id vendorProgramId
  ) {
    ValidationHelper.requireId(
      existingRequirementSetId,
      'Existing Requirement Set ID'
    );
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');

    // Get vendor program label for naming convention
    String vendorProgramLabel = VendorOnboardingWizardRepository.getVendorProgramLabel(
      vendorProgramId
    );

    // Get existing requirement set
    Onboarding_Requirement_Set__c existingSet = VendorOnboardingWizardRepository.getRequirementSetWithTemplates(
      existingRequirementSetId
    );

    // Get templates for existing set
    List<Vendor_Program_Onboarding_Req_Template__c> existingTemplates = VendorOnboardingWizardRepository.getTemplatesForRequirementSet(
      existingRequirementSetId
    );

    // Create new requirement set
    Onboarding_Requirement_Set__c newSet = new Onboarding_Requirement_Set__c(
      Status__c = 'Draft'
    );
    Id newSetId = VendorOnboardingWizardRepository.insertOnboardingRequirementSet(
      newSet
    );

    // Link new requirement set to vendor program via junction
    VendorProgramRequirementSetService.linkVendorProgramToRequirementSet(
      vendorProgramId,
      newSetId
    );

    // Copy templates from existing set to new set
    if (existingTemplates != null && !existingTemplates.isEmpty()) {
      List<Vendor_Program_Onboarding_Req_Template__c> newTemplates = new List<Vendor_Program_Onboarding_Req_Template__c>();
      for (
        Vendor_Program_Onboarding_Req_Template__c existingTemplate : existingTemplates
      ) {
        Vendor_Program_Onboarding_Req_Template__c newTemplate = new Vendor_Program_Onboarding_Req_Template__c(
          Requirement_Label__c = existingTemplate.Requirement_Label__c,
          Requirement_Type__c = existingTemplate.Requirement_Type__c,
          Status__c = existingTemplate.Status__c,
          Is_Current_Version__c = existingTemplate.Is_Current_Version__c,
          Category_Group__c = existingTemplate.Category_Group__c
        );
        newTemplates.add(newTemplate);
      }
      if (!newTemplates.isEmpty()) {
        VendorOnboardingWizardRepository.insertRequirementTemplates(
          newTemplates
        );
        // Link new templates to new requirement set via junction
        List<Id> newTemplateIds = new List<Id>();
        for (
          Vendor_Program_Onboarding_Req_Template__c newTemplate : newTemplates
        ) {
          newTemplateIds.add(newTemplate.Id);
        }
        RequirementSetTemplateService.linkTemplatesToRequirementSet(
          newTemplateIds,
          newSetId
        );
      }
    }

    return newSetId;
  }

  /**
   * Gets templates for a requirement set
   * @param requirementSetId The requirement set ID
   * @return List of templates in the requirement set
   * @throws AuraHandledException if requirementSetId is null
   */
  public static List<Vendor_Program_Onboarding_Req_Template__c> getTemplatesForRequirementSet(
    Id requirementSetId
  ) {
    ValidationHelper.requireId(requirementSetId, 'Requirement Set ID');
    return VendorOnboardingWizardRepository.fetchOnboardingRequirementTemplates(
      requirementSetId
    );
  }

  /**
   * Gets a requirement set by ID
   * @param requirementSetId The requirement set ID
   * @return The requirement set record
   * @throws AuraHandledException if requirementSetId is null
   */
  public static Onboarding_Requirement_Set__c getRequirementSetById(
    Id requirementSetId
  ) {
    ValidationHelper.requireId(requirementSetId, 'Requirement Set ID');
    return VendorOnboardingWizardRepository.getRequirementSetById(
      requirementSetId
    );
  }

  /**
   * Gets templates by group ID
   * @param requirementGroupId The requirement group ID
   * @return List of templates in the group
   * @throws AuraHandledException if requirementGroupId is null
   */
  public static List<Vendor_Program_Onboarding_Req_Template__c> getTemplatesByGroup(
    Id requirementGroupId
  ) {
    ValidationHelper.requireId(requirementGroupId, 'Requirement Group ID');
    return VendorOnboardingWizardRepository.getTemplatesByGroup(
      requirementGroupId
    );
  }

  /**
   * Creates a requirement from a template
   * @param templateId The template ID
   * @param vendorProgramId The vendor program ID
   * @return The ID of the created requirement
   * @throws AuraHandledException if either ID is null
   */
  public static Id createRequirementFromTemplate(
    Id templateId,
    Id vendorProgramId
  ) {
    ValidationHelper.requireId(templateId, 'Template ID');
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');

    Vendor_Program_Onboarding_Req_Template__c requirementTemplate = VendorOnboardingWizardRepository.getRequirementTemplate(
      templateId
    );

    Vendor_Program_Requirement__c requirement = new Vendor_Program_Requirement__c(
      Vendor_Program__c = vendorProgramId,
      Requirement_Template__c = templateId
    );

    return VendorOnboardingWizardRepository.insertVendorProgramRequirement(
      requirement
    );
  }

  /**
   * Creates a new requirement template
   * @param template The template record to create
   * @return The ID of the created template
   * @throws AuraHandledException if template is null or required fields are blank
   */
  /**
   * Creates a new requirement template.
   * Note: Onboarding_Requirement_Set__c field is kept for backward compatibility with Master-Detail relationship,
   * but templates should primarily be linked to requirement sets via Requirement_Set_Template__c junction records.
   * @param template The template record to create (Onboarding_Requirement_Set__c is optional for many-to-many support)
   * @param requirementSetIds Optional list of requirement set IDs to link via junction after creation
   * @return The ID of the created template
   * @throws AuraHandledException if template is null or required fields are blank
   */
  public static Id createOnboardingRequirementTemplate(
    Vendor_Program_Onboarding_Req_Template__c template,
    List<Id> requirementSetIds
  ) {
    ValidationHelper.requireRecord(template, 'Requirement Template');
    ValidationHelper.requireField(
      template.Requirement_Label__c,
      'Requirement Label'
    );
    // Note: Onboarding_Requirement_Set__c is no longer required for many-to-many support
    // However, MD field may still exist for backward compatibility

    // Security: Only admins can set field mapping fields
    Boolean isAdmin = VendorProgramStatusMapper.isCurrentUserAdmin();
    if (!isAdmin) {
      // Clear mapping fields for non-admin users (security measure)
      template.Onboarding_Status_Field_API_Name__c = null;
      template.Onboarding_Status_Value_When_Complete__c = null;
      template.Onboarding_Status_Value_When_Denied__c = null;
    }

    // Set default values for required fields if not provided
    if (String.isBlank(template.Requirement_Type__c)) {
      template.Requirement_Type__c = 'Document'; // Default requirement type
    }
    if (String.isBlank(template.Status__c)) {
      template.Status__c = 'Active'; // Default status
    }
    if (template.Is_Current_Version__c == null) {
      template.Is_Current_Version__c = true; // Default to current version
    }

    // DRY Pattern: Sync Status__c with Active__c
    // When Status = 'Active', set Active__c = true
    if (
      template.Status__c == 'Active' &&
      (template.Active__c == null ||
      template.Active__c == false)
    ) {
      template.Active__c = true;
    } else if (template.Status__c != 'Active' && template.Active__c == null) {
      template.Active__c = false;
    }

    Id templateId = VendorOnboardingWizardRepository.insertOnboardingRequirementTemplate(
      template
    );

    // Link template to requirement sets via junction (new approach)
    if (requirementSetIds != null && !requirementSetIds.isEmpty()) {
      RequirementSetTemplateService.linkTemplatesToRequirementSet(
        new List<Id>{ templateId },
        requirementSetIds[0]
      );

      // Link to additional requirement sets if provided
      if (requirementSetIds.size() > 1) {
        for (Integer requirementSetIndex = 1; requirementSetIndex < requirementSetIds.size(); requirementSetIndex++) {
          RequirementSetTemplateService.linkTemplateToRequirementSet(
            templateId,
            requirementSetIds[requirementSetIndex]
          );
        }
      }
    }

    return templateId;
  }

  // Overloaded method for backward compatibility (no requirement sets)
  public static Id createOnboardingRequirementTemplate(
    Vendor_Program_Onboarding_Req_Template__c template
  ) {
    return createOnboardingRequirementTemplate(template, new List<Id>());
  }

  /**
   * Updates an existing requirement template
   * @param template The template record to update (must have Id)
   * @throws AuraHandledException if template or Id is null
   */
  public static void updateOnboardingRequirementTemplate(
    Vendor_Program_Onboarding_Req_Template__c template
  ) {
    ValidationHelper.requireRecord(template, 'Requirement Template');
    ValidationHelper.requireId(template.Id, 'Requirement Template ID');

    // Security: Only admins can update field mapping fields
    Boolean isAdmin = VendorProgramStatusMapper.isCurrentUserAdmin();
    if (!isAdmin) {
      // For non-admin users, preserve existing mapping values (don't allow changes)
      Vendor_Program_Onboarding_Req_Template__c existing = [
        SELECT
          Onboarding_Status_Field_API_Name__c,
          Onboarding_Status_Value_When_Complete__c,
          Onboarding_Status_Value_When_Denied__c
        FROM Vendor_Program_Onboarding_Req_Template__c
        WHERE Id = :template.Id
        LIMIT 1
      ];
      if (existing != null) {
        template.Onboarding_Status_Field_API_Name__c = existing.Onboarding_Status_Field_API_Name__c;
        template.Onboarding_Status_Value_When_Complete__c = existing.Onboarding_Status_Value_When_Complete__c;
        template.Onboarding_Status_Value_When_Denied__c = existing.Onboarding_Status_Value_When_Denied__c;
      }
    }

    // DRY Pattern: Sync Status__c with Active__c
    // When Status = 'Active', set Active__c = true
    if (template.Status__c == 'Active') {
      template.Active__c = true;
    } else {
      // When Status is not 'Active' (e.g., 'Draft', 'Inactive'), set Active__c = false
      template.Active__c = false;
    }

    VendorOnboardingWizardRepository.updateOnboardingRequirementTemplate(
      template
    );
  }

  /**
   * Gets requirement templates for a requirement set
   * @param requirementSetId The requirement set ID
   * @return List of templates in the requirement set
   * @throws AuraHandledException if requirementSetId is null
   */
  public static List<Vendor_Program_Onboarding_Req_Template__c> getRequirementTemplatesForSet(
    Id requirementSetId
  ) {
    ValidationHelper.requireId(requirementSetId, 'Requirement Set ID');
    return VendorOnboardingWizardRepository.fetchOnboardingRequirementTemplates(
      requirementSetId
    );
  }

  /**
   * Updates requirement template group links
   * @param requirementGroupId The requirement group ID
   * @param templateIdsToLink List of template IDs to link
   * @param templateIdsToUnlink List of template IDs to unlink
   * @throws AuraHandledException if requirementGroupId is null
   */
  public static void updateRequirementTemplateGroupLinks(
    Id requirementGroupId,
    List<Id> templateIdsToLink,
    List<Id> templateIdsToUnlink
  ) {
    ValidationHelper.requireId(requirementGroupId, 'Requirement Group ID');

    if (templateIdsToLink == null) {
      templateIdsToLink = new List<Id>();
    }
    if (templateIdsToUnlink == null) {
      templateIdsToUnlink = new List<Id>();
    }

    VendorOnboardingWizardRepository.updateRequirementTemplateGroupLinks(
      requirementGroupId,
      templateIdsToLink,
      templateIdsToUnlink
    );
  }

  /**
   * Assigns templates to a requirement group
   * @param requirementGroupId The requirement group ID
   * @param templateIds List of template IDs to assign
   * @throws AuraHandledException if requirementGroupId is null or templateIds is empty
   */
  public static void assignTemplatesToRequirementGroup(
    Id requirementGroupId,
    List<Id> templateIds
  ) {
    ValidationHelper.requireId(requirementGroupId, 'Requirement Group ID');
    ValidationHelper.requireNotEmpty(templateIds, 'Template IDs list');

    VendorOnboardingWizardRepository.assignRequirementTemplatesToRequirementGroup(
      requirementGroupId,
      templateIds
    );
  }

  /**
   * Gets historical group members for a requirement set
   * @param requirementSetId The requirement set ID
   * @return List of historical group members
   * @throws AuraHandledException if requirementSetId is null
   */
  public static List<Vendor_Program_Group_Member__c> getHistoricalGroupMembers(
    Id requirementSetId
  ) {
    ValidationHelper.requireId(requirementSetId, 'Requirement Set ID');
    return VendorOnboardingWizardRepository.getHistoricalGroupMembers(
      requirementSetId
    );
  }

  /**
   * Gets historical status rules engines for a requirement set
   * @param requirementSetId The requirement set ID
   * @return List of historical status rules engines
   * @throws AuraHandledException if requirementSetId is null
   */
  public static List<Onboarding_Status_Rules_Engine__c> getHistoricalStatusRulesEngines(
    Id requirementSetId
  ) {
    ValidationHelper.requireId(requirementSetId, 'Requirement Set ID');
    return VendorOnboardingWizardRepository.getHistoricalStatusRulesEngines(
      requirementSetId
    );
  }

  /**
   * Creates requirement group components (groups and members) for a vendor program
   * @param vendorProgramId The vendor program ID
   * @param requirementSetId Optional requirement set ID for historical data
   * @param useHistorical Whether to use historical data from requirement set
   * @return The ID of the created group member
   * @throws AuraHandledException if vendorProgramId is null
   */
  public static Id createRequirementGroupComponents(
    Id vendorProgramId,
    Id requirementSetId,
    Boolean useHistorical
  ) {
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');

    String vendorProgramLabel = VendorOnboardingWizardRepository.getVendorProgramLabel(
      vendorProgramId
    );

    Id vendorProgramGroupId;
    Id vendorProgramRequirementGroupId;
    Id groupMemberId;

    if (useHistorical && requirementSetId != null) {
      // Link from historical values
      List<Vendor_Program_Group_Member__c> historicalMembers = getHistoricalGroupMembers(
        requirementSetId
      );
      if (historicalMembers != null && !historicalMembers.isEmpty()) {
        Vendor_Program_Group_Member__c historical = historicalMembers[0];
        vendorProgramGroupId = historical.Vendor_Program_Group__c;
        vendorProgramRequirementGroupId = historical.Inherited_Program_Requirement_Group__c;

        // Create new member linking to current vendor program
        Vendor_Program_Group_Member__c newMember = new Vendor_Program_Group_Member__c(
          Vendor_Program_Group__c = vendorProgramGroupId,
          Required_Program__c = vendorProgramId,
          Inherited_Program_Requirement_Group__c = vendorProgramRequirementGroupId,
          Is_Target__c = true,
          Active__c = true
        );
        groupMemberId = VendorOnboardingWizardRepository.insertVendorProgramGroupMember(
          newMember
        );
      }
    }

    if (!useHistorical || groupMemberId == null) {
      // Create new with naming convention
      // Create Vendor_Program_Group__c
      Vendor_Program_Group__c newGroup = new Vendor_Program_Group__c(
        Label__c = vendorProgramLabel + ' - Vendor Program Group',
        Logic_Type__c = 'ALL',
        Active__c = true
      );
      vendorProgramGroupId = VendorOnboardingWizardRepository.insertVendorProgramGroup(
        newGroup
      );

      // Create Vendor_Program_Requirement_Group__c
      Vendor_Program_Requirement_Group__c newReqGroup = new Vendor_Program_Requirement_Group__c(
        Name = vendorProgramLabel + ' - Requirement Group',
        Status__c = 'Active',
        Active__c = true
      );
      vendorProgramRequirementGroupId = VendorOnboardingWizardRepository.insertVendorProgramRequirementGroup(
        newReqGroup
      );

      // Create Vendor_Program_Group_Member__c to link them
      Vendor_Program_Group_Member__c newMember = new Vendor_Program_Group_Member__c(
        Vendor_Program_Group__c = vendorProgramGroupId,
        Required_Program__c = vendorProgramId,
        Inherited_Program_Requirement_Group__c = vendorProgramRequirementGroupId,
        Is_Target__c = true,
        Active__c = true
      );
      groupMemberId = VendorOnboardingWizardRepository.insertVendorProgramGroupMember(
        newMember
      );
    }

    return groupMemberId;
  }

  /**
   * Gets onboarding context data for resuming the onboarding flow
   * @param vendorProgramId The vendor program ID
   * @return Map containing requirementSetId and requirementTemplateId
   * @throws AuraHandledException if vendorProgramId is null
   */
  public static Map<String, Object> getOnboardingContext(Id vendorProgramId) {
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');

    Map<String, Object> context = new Map<String, Object>();

    try {
      // Get requirement set linked to vendor program via junction
      List<Id> requirementSetIds = VendorProgramRequirementSetService.getRequirementSetsForVendorProgram(
        vendorProgramId
      );

      if (!requirementSetIds.isEmpty()) {
        // Get most recent requirement set
        List<Onboarding_Requirement_Set__c> requirementSets = [
          SELECT Id
          FROM Onboarding_Requirement_Set__c
          WHERE Id IN :requirementSetIds
          ORDER BY CreatedDate DESC
          LIMIT 1
        ];

        if (!requirementSets.isEmpty()) {
          Id reqSetId = requirementSets[0].Id;
          context.put('requirementSetId', reqSetId);

          // Get most recent requirement template for this requirement set via junction
          List<Id> templateIds = RequirementSetTemplateService.getTemplatesForRequirementSet(
            reqSetId
          );
          if (!templateIds.isEmpty()) {
            List<Vendor_Program_Onboarding_Req_Template__c> requirementTemplates = [
              SELECT Id
              FROM Vendor_Program_Onboarding_Req_Template__c
              WHERE Id IN :templateIds
              ORDER BY CreatedDate DESC
              LIMIT 1
            ];

            if (!requirementTemplates.isEmpty()) {
              context.put('requirementTemplateId', requirementTemplates[0].Id);
            }
          }
        }
      }
    } catch (Exception ex) {
      System.debug('Error getting onboarding context: ' + ex.getMessage());
    }

    return context;
  }

  /**
   * Gets available Onboarding__c status fields that are picklist fields
   * Returns fields that are not already mapped to other templates
   * @param excludeTemplateId Optional template ID to exclude from the exclusion list (for editing)
   * @return List of maps with 'label', 'apiName', and 'dataType' keys
   */
  public static List<Map<String, Object>> getAvailableOnboardingStatusFields(
    Id excludeTemplateId
  ) {
    List<Map<String, Object>> availableFields = new List<Map<String, Object>>();

    try {
      // Get all already-mapped field API names to exclude them
      Set<String> mappedFields = new Set<String>();
      List<Vendor_Program_Onboarding_Req_Template__c> existingTemplates;

      // Exclude the current template if editing (so its mapped field is available)
      if (excludeTemplateId != null) {
        existingTemplates = [
          SELECT Onboarding_Status_Field_API_Name__c
          FROM Vendor_Program_Onboarding_Req_Template__c
          WHERE
            Onboarding_Status_Field_API_Name__c != NULL
            AND Onboarding_Status_Field_API_Name__c != ''
            AND Id != :excludeTemplateId
        ];
      } else {
        existingTemplates = [
          SELECT Onboarding_Status_Field_API_Name__c
          FROM Vendor_Program_Onboarding_Req_Template__c
          WHERE
            Onboarding_Status_Field_API_Name__c != NULL
            AND Onboarding_Status_Field_API_Name__c != ''
        ];
      }

      for (
        Vendor_Program_Onboarding_Req_Template__c existingTemplate : existingTemplates
      ) {
        mappedFields.add(existingTemplate.Onboarding_Status_Field_API_Name__c);
      }

      // Get all picklist fields on Onboarding__c
      Schema.SObjectType onboardingType = Schema.getGlobalDescribe()
        .get('Onboarding__c');
      if (onboardingType == null) {
        return availableFields;
      }

      Schema.DescribeSObjectResult objectDescribe = onboardingType.getDescribe();
      Map<String, Schema.SObjectField> fieldsMap = objectDescribe.fields.getMap();

      // Filter for picklist fields that end with __c (custom fields) and contain "Status" in the name
      Integer totalPicklistFields = 0;
      for (String fieldApiName : fieldsMap.keySet()) {
        Schema.SObjectField field = fieldsMap.get(fieldApiName);
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

        // Count all picklist fields for debugging
        if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST) {
          totalPicklistFields++;
        }

        // Only include picklist fields with "Status" in the name
        Boolean isPicklist =
          fieldDescribe.getType() == Schema.DisplayType.PICKLIST;
        Boolean hasStatusInName = fieldApiName.contains('Status');
        Boolean isCustomField = fieldApiName.endsWith('__c');
        Boolean notMapped = !mappedFields.contains(fieldApiName);

        if (isPicklist && hasStatusInName && isCustomField && notMapped) {
          availableFields.add(
            new Map<String, Object>{
              'label' => fieldDescribe.getLabel(),
              'apiName' => fieldApiName,
              'dataType' => 'PICKLIST'
            }
          );
        }
      }

      System.debug(
        'Total picklist fields on Onboarding__c: ' + totalPicklistFields
      );
      System.debug(
        'Found ' +
          availableFields.size() +
          ' picklist fields with "Status" in name'
      );

      // If no "Status" fields found, try broader search - all custom picklist fields
      if (availableFields.isEmpty()) {
        System.debug(
          'No fields with "Status" found. Searching all custom picklist fields...'
        );
        for (String fieldApiName : fieldsMap.keySet()) {
          Schema.SObjectField field = fieldsMap.get(fieldApiName);
          Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

          Boolean isPicklist =
            fieldDescribe.getType() == Schema.DisplayType.PICKLIST;
          Boolean isCustomField = fieldApiName.endsWith('__c');
          Boolean notMapped = !mappedFields.contains(fieldApiName);

          // Skip standard fields like Onboarding_Status__c if it exists
          if (
            isPicklist &&
            isCustomField &&
            notMapped &&
            fieldApiName != 'Onboarding_Status__c'
          ) {
            availableFields.add(
              new Map<String, Object>{
                'label' => fieldDescribe.getLabel(),
                'apiName' => fieldApiName,
                'dataType' => 'PICKLIST'
              }
            );
          }
        }
        System.debug(
          'Found ' +
            availableFields.size() +
            ' custom picklist fields (fallback)'
        );
      }

      // Sort by label for better UX
      // Apex doesn't have Comparator interface, so we'll sort manually
      List<Map<String, Object>> sortedFields = new List<Map<String, Object>>();
      Map<String, Map<String, Object>> labelToFieldMap = new Map<String, Map<String, Object>>();
      List<String> labels = new List<String>();

      for (Map<String, Object> field : availableFields) {
        String label = (String) field.get('label');
        if (label != null) {
          labelToFieldMap.put(label, field);
          labels.add(label);
        }
      }

      labels.sort();
      for (String label : labels) {
        sortedFields.add(labelToFieldMap.get(label));
      }

      availableFields = sortedFields;
    } catch (Exception ex) {
      System.debug(
        'Error getting available Onboarding status fields: ' + ex.getMessage()
      );
    }

    return availableFields;
  }

  /**
   * Gets available Onboarding__c status fields that are picklist fields (no exclusion)
   * @return List of maps with 'label', 'apiName', and 'dataType' keys
   */
  public static List<Map<String, Object>> getAvailableOnboardingStatusFields() {
    return getAvailableOnboardingStatusFields(null);
  }

  /**
   * Gets picklist values for a specific Onboarding__c field
   * @param fieldApiName The API name of the field (e.g., 'Labor_Form_Status__c')
   * @return List of maps with 'label' and 'value' keys
   */
  public static List<Map<String, String>> getPicklistValuesForOnboardingField(
    String fieldApiName
  ) {
    if (String.isBlank(fieldApiName)) {
      return new List<Map<String, String>>();
    }

    return PicklistHelper.getPicklistValues('Onboarding__c', fieldApiName);
  }
}
