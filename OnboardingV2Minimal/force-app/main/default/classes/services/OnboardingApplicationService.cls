public with sharing class OnboardingApplicationService {
  // Note: OnboardingStageDependencyService is used for dependency validation

  @AuraEnabled(cacheable=true)
  public static List<Onboarding_Application_Stage__c> getStagesForProcess(
    Id processId
  ) {
    ValidationHelper.requireId(processId, 'Process ID');
    return OnboardingApplicationRepository.fetchStagesForProcess(processId);
  }

  @AuraEnabled(cacheable=true)
  public static Onboarding_Application_Process__c getProcessDetails(
    Id processId
  ) {
    ValidationHelper.requireId(processId, 'Process ID');
    return OnboardingApplicationRepository.fetchProcessDetails(processId);
  }

  /**
   * Gets requirements for an onboarding record (for requirements panel)
   * @param onboardingId Onboarding ID
   * @return List of RequirementDTO objects
   */
  @AuraEnabled(cacheable=true)
  public static List<RequirementDTO> getRequirements(Id onboardingId) {
    ValidationHelper.requireId(onboardingId, 'Onboarding ID');
    List<RequirementDTO> requirementDTOList = new List<RequirementDTO>();
    List<Onboarding_Requirement__c> requirements = OnboardingRulesRepository.fetchRequirementsByOnboardingId(
      onboardingId
    );
    for (Onboarding_Requirement__c onboardingRequirement : requirements) {
      requirementDTOList.add(new RequirementDTO(onboardingRequirement));
    }
    return requirementDTOList;
  }

  /**
   * Updates requirement statuses and triggers status evaluation
   * @param updates List of RequirementDTO objects with updated statuses
   */
  @AuraEnabled
  public static void updateRequirementStatuses(List<RequirementDTO> updates) {
    if (updates == null || updates.isEmpty()) {
      return;
    }

    // Build list of requirements to update
    List<Onboarding_Requirement__c> reqsToUpdate = new List<Onboarding_Requirement__c>();
    Set<Id> requirementIds = new Set<Id>();
    for (RequirementDTO requirementDTO : updates) {
      reqsToUpdate.add(
        new Onboarding_Requirement__c(
          Id = requirementDTO.Id,
          Status__c = requirementDTO.Status
        )
      );
      requirementIds.add(requirementDTO.Id);
    }

    // Update requirements via repository
    OnboardingRulesRepository.updateRequirements(reqsToUpdate);

    // Get onboarding IDs from updated requirement records
    Set<Id> onboardingIds = OnboardingRulesRepository.getOnboardingIdsFromRequirementIds(
      requirementIds
    );

    // Query all affected onboardings and run status evaluation
    if (!onboardingIds.isEmpty()) {
      List<Onboarding__c> onboardings = OnboardingRepository.fetchOnboardingsByIds(
        onboardingIds
      );
      OnboardingStatusEvaluator.evaluateAndApplyStatus(onboardings);
    }
  }

  /**
   * Runs rule evaluation for a single onboarding record
   * @param onboardingId Onboarding ID
   */
  @AuraEnabled
  public static void runRuleEvaluation(Id onboardingId) {
    ValidationHelper.requireId(onboardingId, 'Onboarding ID');

    Onboarding__c onboardingRecord = OnboardingRepository.fetchOnboardingById(
      onboardingId
    );
    if (onboardingRecord != null) {
      OnboardingStatusEvaluator.evaluateAndApplyStatus(
        new List<Onboarding__c>{ onboardingRecord }
      );
    }
  }

  /**
   * Data Transfer Object for requirements panel
   */
  public class RequirementDTO {
    @AuraEnabled
    public Id Id;
    @AuraEnabled
    public String Name;
    @AuraEnabled
    public String Status;
    @AuraEnabled
    public Date dueDate;

    public RequirementDTO(Onboarding_Requirement__c onboardingRequirement) {
      if (onboardingRequirement == null) {
        return;
      }
      Id = onboardingRequirement.Id;
      if (onboardingRequirement.isSet('Name')) {
        Name = (String) onboardingRequirement.get('Name');
      }
      if (onboardingRequirement.isSet('Status__c')) {
        Status = (String) onboardingRequirement.get('Status__c');
      }
      if (onboardingRequirement.isSet('Due_Date__c')) {
        dueDate = (Date) onboardingRequirement.get('Due_Date__c');
      }
    }
  }

  @AuraEnabled
  public static Id saveProgress(Id processId, Id vendorProgramId, Id stageId) {
    ValidationHelper.requireId(processId, 'Process ID');
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
    ValidationHelper.requireId(stageId, 'Stage ID');
    // Validate dependencies before allowing stage progression
    OnboardingStageDependencyService.StageDependencyValidationDTO validation = OnboardingStageDependencyService.canStartStage(
      stageId,
      vendorProgramId,
      processId
    );

    if (!validation.canStart && !validation.blockingDependencies.isEmpty()) {
      // Build error message with blocking dependencies
      String errorMessage = 'Cannot start this stage. The following dependencies must be completed first:\n';
      for (
        OnboardingStageDependencyService.DependencyInfo blocking : validation.blockingDependencies
      ) {
        errorMessage += '\n• ' + blocking.dependencyName;
        if (blocking.logicType == 'ALL') {
          errorMessage += ' (All required stages must be completed)';
        } else if (blocking.logicType == 'ANY') {
          errorMessage += ' (At least one required stage must be completed)';
        }
      }
      throw new AuraHandledException(errorMessage);
    }

    // Fetch existing progress
    Onboarding_Application_Progress__c progress = OnboardingApplicationRepository.fetchProgress(
      vendorProgramId,
      processId
    );

    // Create or update progress
    if (progress == null) {
      progress = new Onboarding_Application_Progress__c(
        Onboarding_Application_Process__c = processId,
        Vendor_Program__c = vendorProgramId,
        Current_Stage__c = stageId
      );
    } else {
      progress.Current_Stage__c = stageId;
    }

    // Upsert progress via repository
    Id progressId = OnboardingApplicationRepository.upsertProgress(progress);

    // Create related stage completion record
    Onboarding_Application_Stage_Completion__c completion = new Onboarding_Application_Stage_Completion__c(
      Vendor_Program__c = vendorProgramId,
      Onboarding_Application_Process__c = processId,
      Onboarding_Application_Stage__c = stageId,
      Completed_Date__c = System.now(),
      Completed_By__c = UserInfo.getUserId()
    );

    // Insert completion via repository
    OnboardingApplicationRepository.insertStageCompletion(completion);

    return progressId;
  }

  @AuraEnabled(cacheable=true)
  public static Onboarding_Application_Progress__c getProgress(
    Id vendorProgramId,
    Id processId
  ) {
    return OnboardingApplicationRepository.fetchProgress(
      vendorProgramId,
      processId
    );
  }

  /**
   * Gets the user-facing stage for a Vendor Program technical status.
   * Maps Vendor Program technical statuses (e.g., "Draft", "In Process") to user-friendly stages
   * (e.g., "In Progress", "Review Pending", "Completed").
   *
   * ⚠️ IMPORTANT: This method is ONLY for Vendor_Customization__c.Status__c.
   * It does NOT apply to Dealer Onboarding statuses (Onboarding__c.Onboarding_Status__c).
   * Dealer Onboarding statuses should be displayed as-is without simplification.
   *
   * @param technicalStatus The Vendor Program technical status from Salesforce
   * @return User-friendly stage label for display
   */
  @AuraEnabled(cacheable=true)
  public static String getUserFacingStage(String technicalStatus) {
    return VendorProgramStatusMapper.getUserFacingStageForCurrentUser(
      technicalStatus
    );
  }

  /**
   * Checks if the current user is an admin.
   * Used to determine whether to show technical or simplified statuses.
   *
   * @return True if user is an admin
   */
  @AuraEnabled(cacheable=true)
  public static Boolean isCurrentUserAdmin() {
    return VendorProgramStatusMapper.isCurrentUserAdmin();
  }

  @AuraEnabled(cacheable=true)
  public static List<Onboarding_Application_Stage_Completion__c> getStageCompletions(
    Id vendorProgramId,
    Id processId
  ) {
    if (vendorProgramId == null || processId == null) {
      return new List<Onboarding_Application_Stage_Completion__c>();
    }
    try {
      return [
        SELECT Id, Onboarding_Application_Stage__c, Completed_Date__c
        FROM Onboarding_Application_Stage_Completion__c
        WHERE
          Vendor_Program__c = :vendorProgramId
          AND Onboarding_Application_Process__c = :processId
      ];
    } catch (Exception ex) {
      System.debug('Error fetching stage completions: ' + ex.getMessage());
      return new List<Onboarding_Application_Stage_Completion__c>();
    }
  }

  /**
   * Auto-completes stages that are implicitly done based on vendor program state.
   * For example, if vendor program has a vendor, "Select Vendor" is already done.
   * Returns the stage ID that progress should be advanced to.
   */
  @AuraEnabled
  public static Id autoCompleteStagesAndAdvanceProgress(
    Id vendorProgramId,
    Id processId
  ) {
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
    ValidationHelper.requireId(processId, 'Process ID');

    // Get vendor program data via repository
    Vendor_Customization__c vendorProgram = VendorCustomizationRepository.getBasicById(
      vendorProgramId
    );
    if (vendorProgram == null) {
      return null;
    }

    Boolean hasVendor = vendorProgram.Vendor__c != null;

    // Get all stages
    List<Onboarding_Application_Stage__c> stages = OnboardingApplicationRepository.fetchStagesForProcess(
      processId
    );

    // Get existing completions via repository
    List<Onboarding_Application_Stage_Completion__c> existingCompletions = OnboardingApplicationRepository.fetchStageCompletions(
      vendorProgramId,
      processId
    );
    Set<Id> completedStageIds = new Set<Id>();
    for (
      Onboarding_Application_Stage_Completion__c stageCompletion : existingCompletions
    ) {
      completedStageIds.add(stageCompletion.Onboarding_Application_Stage__c);
    }

    // Determine stages to auto-complete
    List<Onboarding_Application_Stage_Completion__c> toInsert = new List<Onboarding_Application_Stage_Completion__c>();
    Id targetStageId = null;

    if (hasVendor) {
      // Find vendor-related stages and mark them as complete if not already
      for (Onboarding_Application_Stage__c onboardingStage : stages) {
        String componentName = onboardingStage.Onboarding_Component_Library__r
          ?.Component_API_Name__c;

        // These stages are done if vendor program has a vendor
        // Uses configuration class to check component type (OCP compliant)
        if (
          StageCompletionConfig.isVendorSelectionComponent(componentName) &&
          !completedStageIds.contains(onboardingStage.Id)
        ) {
          // Create completion record
          Onboarding_Application_Stage_Completion__c stageCompletion = new Onboarding_Application_Stage_Completion__c(
            Vendor_Program__c = vendorProgramId,
            Onboarding_Application_Process__c = processId,
            Onboarding_Application_Stage__c = onboardingStage.Id,
            Completed_Date__c = System.now(),
            Completed_By__c = UserInfo.getUserId()
          );
          toInsert.add(stageCompletion);
          completedStageIds.add(onboardingStage.Id);
        }

        // Find the first stage after vendor selection to set as current
        // Uses configuration class to check component type (OCP compliant)
        if (
          targetStageId == null &&
          !StageCompletionConfig.isVendorSelectionComponent(componentName)
        ) {
          targetStageId = onboardingStage.Id;
        }
      }
    }

    // Insert completion records
    if (!toInsert.isEmpty()) {
      OnboardingApplicationRepository.insertStageCompletions(toInsert);
    }

    // Update progress to target stage if we found one
    if (targetStageId != null) {
      Onboarding_Application_Progress__c progress = OnboardingApplicationRepository.fetchProgress(
        vendorProgramId,
        processId
      );
      if (progress != null) {
        progress.Current_Stage__c = targetStageId;
        OnboardingApplicationRepository.upsertProgress(progress);
      }
    }

    return targetStageId;
  }

  @AuraEnabled(cacheable=true)
  public static Id getProcessIdForVendorProgram(Id vendorProgramId) {
    Onboarding_Application_Progress__c progress = OnboardingApplicationRepository.fetchProgressByVendorProgram(
      vendorProgramId
    );
    return progress != null ? progress.Onboarding_Application_Process__c : null;
  }

  /**
   * Gets basic vendor program data to determine which stages to skip.
   * Returns null if vendor program doesn't exist.
   */
  @AuraEnabled(cacheable=true)
  public static Vendor_Customization__c getVendorProgramData(
    Id vendorProgramId
  ) {
    if (vendorProgramId == null) {
      return null;
    }
    try {
      return VendorCustomizationRepository.getBasicById(vendorProgramId);
    } catch (Exception ex) {
      System.debug('Error fetching vendor program data: ' + ex.getMessage());
      return null;
    }
  }

  /**
   * Gets vendor program metadata including ownership and change tracking information.
   * Used for displaying collaboration features in the wizard.
   *
   * @param vendorProgramId The vendor program ID
   * @return Vendor program data with CreatedBy, LastModifiedBy, and timestamps
   */
  @AuraEnabled(cacheable=true)
  public static VendorProgramMetadataDTO getVendorProgramMetadata(
    Id vendorProgramId
  ) {
    if (vendorProgramId == null) {
      return null;
    }
    try {
      Vendor_Customization__c program = VendorCustomizationRepository.getMetadataById(
        vendorProgramId
      );

      if (program == null) {
        return null;
      }
      VendorProgramMetadataDTO metadata = new VendorProgramMetadataDTO();
      metadata.vendorProgramId = program.Id;
      metadata.vendorProgramName = program.Name;
      metadata.createdById = program.CreatedById;
      metadata.createdByName = program.CreatedBy?.Name;
      metadata.createdDate = program.CreatedDate;
      metadata.lastModifiedById = program.LastModifiedById;
      metadata.lastModifiedByName = program.LastModifiedBy?.Name;
      metadata.lastModifiedDate = program.LastModifiedDate;

      return metadata;
    } catch (Exception ex) {
      System.debug(
        'Error fetching vendor program metadata: ' + ex.getMessage()
      );
      return null;
    }
  }

  /**
   * DTO for vendor program metadata including ownership and change tracking
   */
  public class VendorProgramMetadataDTO {
    @AuraEnabled
    public Id vendorProgramId;
    @AuraEnabled
    public String vendorProgramName;
    @AuraEnabled
    public Id createdById;
    @AuraEnabled
    public String createdByName;
    @AuraEnabled
    public DateTime createdDate;
    @AuraEnabled
    public Id lastModifiedById;
    @AuraEnabled
    public String lastModifiedByName;
    @AuraEnabled
    public DateTime lastModifiedDate;
  }

  /**
   * Get the default vendor program onboarding process ID.
   * Returns the first active process, prioritizing one named "Vendor Program Onboarding".
   * This is used to start the vendor program onboarding wizard.
   */
  @AuraEnabled(cacheable=true)
  public static Id getDefaultVendorProgramOnboardingProcessId() {
    // First try to find a process named "Vendor Program Onboarding"
    List<Onboarding_Application_Process__c> processes = OnboardingApplicationRepository.fetchActiveProcessesByName(
      'Vendor Program Onboarding'
    );
    if (processes != null && !processes.isEmpty()) {
      return processes[0].Id;
    }
    // Fallback: get first active process if no specific match
    List<Onboarding_Application_Process__c> allActive = OnboardingApplicationRepository.fetchActiveProcesses();
    return (allActive != null && !allActive.isEmpty()) ? allActive[0].Id : null;
  }

  /**
   * Checks if a stage can be started based on its dependencies.
   * Used by the flow engine to validate stage navigation.
   *
   * @param targetStageId The stage the user wants to start
   * @param vendorProgramId The vendor program ID
   * @param processId The onboarding process ID
   * @return StageDependencyValidationDTO with canStart flag and blocking dependencies
   */
  @AuraEnabled
  public static OnboardingStageDependencyService.StageDependencyValidationDTO canStartStage(
    Id targetStageId,
    Id vendorProgramId,
    Id processId
  ) {
    return OnboardingStageDependencyService.canStartStage(
      targetStageId,
      vendorProgramId,
      processId
    );
  }

  /**
   * Gets dependency information for a target stage (for display purposes).
   * Returns all dependencies regardless of whether they're met.
   *
   * @param targetStageId The stage to get dependencies for
   * @param vendorProgramId The vendor program ID
   * @param processId The onboarding process ID
   * @return List of dependency information
   */
  @AuraEnabled(cacheable=true)
  public static List<OnboardingStageDependencyService.DependencyInfo> getStageDependencies(
    Id targetStageId,
    Id vendorProgramId,
    Id processId
  ) {
    return OnboardingStageDependencyService.getDependencyInfo(
      targetStageId,
      vendorProgramId,
      processId
    );
  }

  /**
   * Get resume context for an onboarding record
   * Finds last completed requirement and next incomplete requirement
   * Added in Phase 0.4: Partial Save & Resume Strategy
   * @param onboardingId The Onboarding__c record ID
   * @return ResumeContext with progress and navigation info
   */
  @AuraEnabled(cacheable=true)
  public static ResumeContext getResumeContext(Id onboardingId) {
    if (onboardingId == null) {
      throw new AuraHandledException('Onboarding ID is required');
    }

    ResumeContext context = new ResumeContext();
    context.onboardingId = onboardingId;

    try {
      // Get all requirements for this onboarding
      List<Onboarding_Requirement__c> requirements = [
        SELECT Id, Name, Status__c, Sequence__c
        FROM Onboarding_Requirement__c
        WHERE Onboarding__c = :onboardingId
        // TODO: Add AND Is_Archived__c = false when field is created
        ORDER BY Sequence__c ASC NULLS LAST, CreatedDate ASC
      ];

      // Get field values for all requirements
      Set<Id> requirementIds = new Set<Id>();
      for (Onboarding_Requirement__c onboardingRequirement : requirements) {
        requirementIds.add(onboardingRequirement.Id);
      }

      Map<Id, List<Requirement_Field_Value__c>> fieldValuesByRequirement = new Map<Id, List<Requirement_Field_Value__c>>();
      if (!requirementIds.isEmpty()) {
        List<Requirement_Field_Value__c> allFieldValues = [
          SELECT
            Id,
            Value__c,
            Encrypted_Value__c,
            Requirement_Field__c,
            Onboarding_Requirement__c
          FROM Requirement_Field_Value__c
          WHERE Onboarding_Requirement__c IN :requirementIds
          // TODO: Add AND Is_Archived__c = false when field is created
        ];

        for (Requirement_Field_Value__c fieldValue : allFieldValues) {
          if (
            !fieldValuesByRequirement.containsKey(
              fieldValue.Onboarding_Requirement__c
            )
          ) {
            fieldValuesByRequirement.put(
              fieldValue.Onboarding_Requirement__c,
              new List<Requirement_Field_Value__c>()
            );
          }
          fieldValuesByRequirement.get(fieldValue.Onboarding_Requirement__c)
            .add(fieldValue);
        }
      }

      if (requirements.isEmpty()) {
        context.completionPercentage = 0;
        return context;
      }

      // Calculate completion
      Integer totalRequirements = requirements.size();
      Integer completedRequirements = 0;
      Onboarding_Requirement__c lastCompleted = null;
      Onboarding_Requirement__c nextIncomplete = null;

      for (Onboarding_Requirement__c onboardingRequirement : requirements) {
        // Get field values for this requirement
        List<Requirement_Field_Value__c> fieldValues = fieldValuesByRequirement.get(
          onboardingRequirement.Id
        );
        if (fieldValues == null) {
          fieldValues = new List<Requirement_Field_Value__c>();
        }

        // Check if requirement is complete
        Boolean isComplete = isRequirementCompleteForResume(
          onboardingRequirement,
          fieldValues
        );

        if (isComplete) {
          completedRequirements++;
          lastCompleted = onboardingRequirement;
        } else if (nextIncomplete == null) {
          // First incomplete requirement
          nextIncomplete = onboardingRequirement;
        }
      }

      context.completionPercentage = totalRequirements > 0
        ? Math.round(
            (completedRequirements / (Decimal) totalRequirements) * 100
          )
        : 0;

      // Set last completed requirement
      if (lastCompleted != null) {
        context.lastCompletedRequirement = new RequirementInfo();
        context.lastCompletedRequirement.id = lastCompleted.Id;
        context.lastCompletedRequirement.name = lastCompleted.Name;
      }

      // Set next incomplete requirement
      if (nextIncomplete != null) {
        context.nextIncompleteRequirement = new RequirementInfo();
        context.nextIncompleteRequirement.id = nextIncomplete.Id;
        context.nextIncompleteRequirement.name = nextIncomplete.Name;

        // Find first incomplete field
        Requirement_Field_Value__c firstIncompleteField = findFirstIncompleteField(
          nextIncomplete.Id
        );
        if (firstIncompleteField != null) {
          context.nextIncompleteRequirement.firstIncompleteField = new FieldInfo();
          context.nextIncompleteRequirement.firstIncompleteField.id = firstIncompleteField.Id;
          context.nextIncompleteRequirement.firstIncompleteField.name = firstIncompleteField.Requirement_Field__r
            ?.Name;
        }
      }
    } catch (Exception ex) {
      System.debug('Error getting resume context: ' + ex.getMessage());
      throw new AuraHandledException(
        'Error loading resume context: ' + ex.getMessage()
      );
    }

    return context;
  }

  /**
   * Check if a requirement is complete for resume context
   * A requirement is complete if all its fields have values and are validated
   */
  private static Boolean isRequirementCompleteForResume(
    Onboarding_Requirement__c requirement,
    List<Requirement_Field_Value__c> fieldValues
  ) {
    // Check status
    if (
      requirement.Status__c == 'Complete' ||
      requirement.Status__c == 'Approved'
    ) {
      return true;
    }

    // Check if all fields have values
    // TODO: Query Requirement_Field__c records to get total field count
    // For now, check if all existing field values are populated
    if (fieldValues != null && !fieldValues.isEmpty()) {
      for (Requirement_Field_Value__c fieldValue : fieldValues) {
        if (
          String.isBlank(fieldValue.Value__c) &&
          String.isBlank(fieldValue.Encrypted_Value__c)
        ) {
          return false; // Found incomplete field
        }
      }
      // All existing fields have values
      return true;
    }

    return false;
  }

  /**
   * Find first incomplete field for a requirement
   */
  private static Requirement_Field_Value__c findFirstIncompleteField(
    Id requirementId
  ) {
    // Query requirement fields and their values
    // Find first field without a value
    List<Requirement_Field_Value__c> fieldValues = [
      SELECT
        Id,
        Value__c,
        Encrypted_Value__c,
        Requirement_Field__c,
        Requirement_Field__r.Name
      FROM Requirement_Field_Value__c
      WHERE Onboarding_Requirement__c = :requirementId
      // TODO: Add AND Is_Archived__c = false when field is created
      ORDER BY Requirement_Field__r.Sequence__c ASC NULLS LAST, CreatedDate ASC
    ];

    for (Requirement_Field_Value__c fieldValue : fieldValues) {
      if (
        String.isBlank(fieldValue.Value__c) &&
        String.isBlank(fieldValue.Encrypted_Value__c)
      ) {
        return fieldValue;
      }
    }

    return null;
  }

  /**
   * Resume context wrapper
   * Added in Phase 0.4: Partial Save & Resume Strategy
   */
  public class ResumeContext {
    @AuraEnabled
    public String onboardingId;
    @AuraEnabled
    public Integer completionPercentage = 0;
    @AuraEnabled
    public RequirementInfo lastCompletedRequirement;
    @AuraEnabled
    public RequirementInfo nextIncompleteRequirement;
  }

  /**
   * Requirement info wrapper for resume context
   * Added in Phase 0.4: Partial Save & Resume Strategy
   */
  public class RequirementInfo {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public FieldInfo firstIncompleteField;
  }

  /**
   * Field info wrapper for resume context
   * Added in Phase 0.4: Partial Save & Resume Strategy
   */
  public class FieldInfo {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String name;
  }
}
