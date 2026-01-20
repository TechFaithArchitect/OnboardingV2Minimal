public with sharing class OnboardingAppVendorProgramReqRepo {
  public static List<Required_Credential__c> fetchRequiredCredentials(
    Id vendorProgramId
  ) {
    return [
      SELECT
        Id,
        Name,
        Notes__c,
        Vendor_Customization__c,
        Is_Required__c,
        Sequence__c,
        External_Contact_Credential_Type__c,
        External_Contact_Credential_Type__r.Name
      FROM Required_Credential__c
      WHERE Vendor_Customization__c = :vendorProgramId
    ];
  }

  public static List<Training_Requirement__c> fetchTrainingRequirements(
    Id vendorProgramId
  ) {
    return [
      SELECT
        Id,
        Name,
        Training_System__c,
        Training_System__r.Name,
        Sequence__c,
        Vendor_Customization__c,
        Is_Required__c,
        Training_Code__c,
        External_Course_Code__c,
        External_Course_Name__c
      FROM Training_Requirement__c
      WHERE Vendor_Customization__c = :vendorProgramId
      ORDER BY Sequence__c NULLS LAST, Name
    ];
  }

  /**
   * Inserts a new Required Credential record.
   * @param requiredCredential The Required_Credential__c record to insert
   * @return The Id of the inserted record
   */
  public static Id insertRequiredCredential(
    Required_Credential__c requiredCredential
  ) {
    insert requiredCredential;
    return requiredCredential.Id;
  }

  public static void updateRequiredCredentials(
    List<Required_Credential__c> requiredCredentials
  ) {
    if (requiredCredentials == null || requiredCredentials.isEmpty()) {
      return;
    }
    update requiredCredentials;
  }

  /**
   * Inserts a new Training Requirement record.
   * @param trainingRequirement The Training_Requirement__c record to insert
   * @return The Id of the inserted record
   */
  public static Id insertTrainingRequirement(
    Training_Requirement__c trainingRequirement
  ) {
    insert trainingRequirement;
    return trainingRequirement.Id;
  }

  /**
   * Fetches all active Training Systems for use in picklists.
   * @return List of active Training_System__c records
   */
  public static List<Training_System__c> fetchActiveTrainingSystems() {
    return [
      SELECT Id, Name, System_Type__c
      FROM Training_System__c
      WHERE Active__c = TRUE
      ORDER BY Name
    ];
  }

  /**
   * Inserts a new Training System record.
   * @param trainingSystem The Training_System__c record to insert
   * @return The Id of the inserted record
   */
  public static Id insertTrainingSystem(Training_System__c trainingSystem) {
    insert trainingSystem;
    return trainingSystem.Id;
  }

  /**
   * Updates Training Requirements to mark them as required or not required.
   * @param trainingRequirementIds List of Training Requirement IDs to update
   * @param isRequired Whether the training requirements should be marked as required
   */
  public static void updateTrainingRequirementRequiredStatus(
    List<Id> trainingRequirementIds,
    Boolean isRequired
  ) {
    List<Training_Requirement__c> trainingRequirements = new List<Training_Requirement__c>();
    for (Id trainingRequirementId : trainingRequirementIds) {
      trainingRequirements.add(
        new Training_Requirement__c(
          Id = trainingRequirementId,
          Is_Required__c = isRequired
        )
      );
    }
    if (!trainingRequirements.isEmpty()) {
      update trainingRequirements;
    }
  }
}
