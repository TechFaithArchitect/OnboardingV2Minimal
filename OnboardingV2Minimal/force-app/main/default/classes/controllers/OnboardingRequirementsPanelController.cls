public with sharing class OnboardingRequirementsPanelController {
  @AuraEnabled(cacheable=true)
  public static List<OnboardingApplicationService.RequirementDTO> getRequirements(
    Id onboardingId
  ) {
    return OnboardingApplicationService.getRequirements(onboardingId);
  }

  @AuraEnabled
  public static void updateRequirementStatuses(
    List<OnboardingApplicationService.RequirementDTO> updates
  ) {
    OnboardingApplicationService.updateRequirementStatuses(updates);
  }

  @AuraEnabled
  public static void runRuleEvaluation(Id onboardingId) {
    OnboardingApplicationService.runRuleEvaluation(onboardingId);
  }

  /**
   * Returns Requirement Field Values that are not Valid for the given onboarding record.
   * Used by the Requirements Panel to surface only the fields that need correction.
   */
  @AuraEnabled(cacheable=true)
  public static List<InvalidFieldDTO> getInvalidFieldValues(Id onboardingId) {
    ValidationHelper.requireId(onboardingId, 'Onboarding ID');

    // Use repository for data access
    List<Requirement_Field_Value__c> invalidValues = RequirementFieldValueRepository.getInvalidFieldValuesByOnboarding(
      onboardingId
    );

    List<InvalidFieldDTO> invalidFieldDTOList = new List<InvalidFieldDTO>();
    for (Requirement_Field_Value__c fieldValueRecord : invalidValues) {
      InvalidFieldDTO invalidFieldDTO = new InvalidFieldDTO();
      invalidFieldDTO.fieldValueId = fieldValueRecord.Id;
      invalidFieldDTO.requirementName = fieldValueRecord.Onboarding_Requirement__r.Name;
      invalidFieldDTO.fieldName = fieldValueRecord.Requirement_Field__r.Name;
      invalidFieldDTO.fieldApiName = fieldValueRecord.Requirement_Field__r.Field_API_Name__c;
      invalidFieldDTO.status = fieldValueRecord.Validation_Status__c;
      invalidFieldDTO.message = fieldValueRecord.Validation_Error_Message__c;
      invalidFieldDTOList.add(invalidFieldDTO);
    }
    return invalidFieldDTOList;
  }

  /**
   * Re-runs async validation for the specified field values.
   * The UI can call this after users correct individual fields.
   */
  @AuraEnabled
  public static void rerunValidation(List<Id> fieldValueIds) {
    if (fieldValueIds == null || fieldValueIds.isEmpty()) {
      return;
    }
    RequirementFieldAsyncValidator.enqueue(new Set<Id>(fieldValueIds));
  }

  /**
   * Get the last modified date of rules engines that apply to this onboarding.
   * Used to detect if rules have changed since the page was loaded.
   *
   * @param onboardingId Onboarding__c ID
   * @return RulesVersionInfo with lastModifiedDate and engineIds
   */
  @AuraEnabled(cacheable=true)
  public static RulesVersionInfo getActiveRulesVersion(Id onboardingId) {
    ValidationHelper.requireId(onboardingId, 'Onboarding ID');

    // Get the onboarding record to find its vendor program
    List<Onboarding__c> onboardingRecords = [
      SELECT Id, Vendor_Customization__c
      FROM Onboarding__c
      WHERE Id = :onboardingId
      LIMIT 1
    ];

    if (onboardingRecords.isEmpty()) {
      return new RulesVersionInfo();
    }

    Id vendorProgramId = onboardingRecords[0].Vendor_Customization__c;
    if (vendorProgramId == null) {
      return new RulesVersionInfo();
    }

    // Get group IDs for this vendor program
    List<Id> groupIds = OnboardingRulesService.getVendorProgramGroupIds(
      vendorProgramId
    );

    if (groupIds.isEmpty()) {
      return new RulesVersionInfo();
    }

    // Get the most recent LastModifiedDate from applicable rules engines
    List<Onboarding_Status_Rules_Engine__c> rulesEngines = OnboardingRulesService.getRulesForGroups(
      groupIds
    );

    if (rulesEngines.isEmpty()) {
      return new RulesVersionInfo();
    }

    // Find the most recent LastModifiedDate
    Datetime mostRecentModified = null;
    List<Id> engineIds = new List<Id>();
    for (Onboarding_Status_Rules_Engine__c statusRulesEngineRecord : rulesEngines) {
      engineIds.add(statusRulesEngineRecord.Id);
      if (
        mostRecentModified == null ||
        statusRulesEngineRecord.LastModifiedDate > mostRecentModified
      ) {
        mostRecentModified = statusRulesEngineRecord.LastModifiedDate;
      }
    }

    RulesVersionInfo versionInfo = new RulesVersionInfo();
    versionInfo.lastModifiedDate = mostRecentModified;
    versionInfo.engineIds = engineIds;
    return versionInfo;
  }

  /**
   * Refresh rules and re-evaluate the onboarding status.
   * Fetches the latest rules version and re-runs evaluation.
   *
   * @param onboardingId Onboarding__c ID
   * @return Updated status after re-evaluation
   */
  @AuraEnabled
  public static String refreshAndReevaluate(Id onboardingId) {
    ValidationHelper.requireId(onboardingId, 'Onboarding ID');

    // Re-run rule evaluation with latest rules
    OnboardingApplicationService.runRuleEvaluation(onboardingId);

    // Fetch the updated status
    List<Onboarding__c> onboardingRecords = [
      SELECT Id, Onboarding_Status__c
      FROM Onboarding__c
      WHERE Id = :onboardingId
      LIMIT 1
    ];

    if (onboardingRecords.isEmpty()) {
      return null;
    }

    return onboardingRecords[0].Onboarding_Status__c;
  }

  public class InvalidFieldDTO {
    @AuraEnabled
    public Id fieldValueId;
    @AuraEnabled
    public String requirementName;
    @AuraEnabled
    public String fieldName;
    @AuraEnabled
    public String fieldApiName;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String message;
  }

  public class RulesVersionInfo {
    @AuraEnabled
    public Datetime lastModifiedDate;
    @AuraEnabled
    public List<Id> engineIds;

    public RulesVersionInfo() {
      this.engineIds = new List<Id>();
    }
  }
}
