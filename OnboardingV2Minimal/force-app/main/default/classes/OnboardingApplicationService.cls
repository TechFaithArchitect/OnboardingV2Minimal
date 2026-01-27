public with sharing class OnboardingApplicationService {
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

    OnboardingRulesRepository.updateRequirements(reqsToUpdate);

    Set<Id> onboardingIds = OnboardingRulesRepository.getOnboardingIdsFromRequirementIds(
      requirementIds
    );

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

  /**
   * Gets the user-facing stage for a Vendor Program technical status.
   * Maps Vendor Program technical statuses (e.g., "Draft", "In Process") to user-friendly stages
   * (e.g., "In Progress", "Review Pending", "Completed").
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
   */
  @AuraEnabled(cacheable=true)
  public static Boolean isCurrentUserAdmin() {
    return VendorProgramStatusMapper.isCurrentUserAdmin();
  }

  /**
   * Get resume context for an onboarding record
   * Finds last completed requirement and next incomplete requirement
   */
  @AuraEnabled(cacheable=true)
  public static ResumeContext getResumeContext(Id onboardingId) {
    if (onboardingId == null) {
      throw new AuraHandledException('Onboarding ID is required');
    }

    ResumeContext context = new ResumeContext();
    context.onboardingId = onboardingId;

    try {
      List<Onboarding_Requirement__c> requirements = [
        SELECT Id, Name, Status__c, Sequence__c, Completed__c
        FROM Onboarding_Requirement__c
        WHERE Onboarding__c = :onboardingId
        ORDER BY Sequence__c ASC NULLS LAST, CreatedDate ASC
      ];

      if (requirements.isEmpty()) {
        context.completionPercentage = 0;
        return context;
      }

      Integer totalRequirements = requirements.size();
      Integer completedRequirements = 0;
      Onboarding_Requirement__c lastCompleted = null;
      Onboarding_Requirement__c nextIncomplete = null;

      for (Onboarding_Requirement__c onboardingRequirement : requirements) {
        Boolean isComplete = isRequirementCompleteForResume(
          onboardingRequirement
        );

        if (isComplete) {
          completedRequirements++;
          lastCompleted = onboardingRequirement;
        } else if (nextIncomplete == null) {
          nextIncomplete = onboardingRequirement;
        }
      }

      context.completionPercentage = totalRequirements > 0
        ? Math.round(
            (completedRequirements / (Decimal) totalRequirements) * 100
          )
        : 0;

      if (lastCompleted != null) {
        context.lastCompletedRequirement = new RequirementInfo();
        context.lastCompletedRequirement.id = lastCompleted.Id;
        context.lastCompletedRequirement.name = lastCompleted.Name;
      }

      if (nextIncomplete != null) {
        context.nextIncompleteRequirement = new RequirementInfo();
        context.nextIncompleteRequirement.id = nextIncomplete.Id;
        context.nextIncompleteRequirement.name = nextIncomplete.Name;
      }
    } catch (Exception ex) {
      System.debug('Error getting resume context: ' + ex.getMessage());
      throw new AuraHandledException(
        'Error loading resume context: ' + ex.getMessage()
      );
    }

    return context;
  }

  private static Boolean isRequirementCompleteForResume(
    Onboarding_Requirement__c requirement
  ) {
    if (requirement == null) {
      return false;
    }

    if (requirement.Completed__c == true) {
      return true;
    }
    String status = requirement.Status__c;
    return status == 'Complete' ||
      status == 'Approved' ||
      status == 'Setup Complete' ||
      status == 'Completed';
  }

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

  public class RequirementInfo {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String name;
  }
}
