public with sharing class OnboardingAppVendorProgramReqSvc {
  /**
   * Consolidates OnboardingAppVendorProgramReqCtlr and OnboardingAppVendorProgramReqOrch - removed controller and orchestrator layers
   */
  @AuraEnabled(cacheable=true)
  public static List<Required_Credential__c> getRequiredCredentials(
    Id vendorProgramId
  ) {
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
    return OnboardingAppVendorProgramReqRepo.fetchRequiredCredentials(
      vendorProgramId
    );
  }

  @AuraEnabled(cacheable=true)
  public static List<Training_Requirement__c> getTrainingRequirements(
    Id vendorProgramId
  ) {
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
    return OnboardingAppVendorProgramReqRepo.fetchTrainingRequirements(
      vendorProgramId
    );
  }

  @AuraEnabled
  public static Id createRequiredCredential(
    Required_Credential__c requiredCredential
  ) {
    ValidationHelper.requireRecord(requiredCredential, 'Required Credential');
    ValidationHelper.requireId(
      requiredCredential.Vendor_Customization__c,
      'Vendor Program reference'
    );
    return OnboardingAppVendorProgramReqRepo.insertRequiredCredential(
      requiredCredential
    );
  }

  @AuraEnabled
  public static Id createTrainingRequirement(
    Training_Requirement__c trainingRequirement
  ) {
    ValidationHelper.requireRecord(trainingRequirement, 'Training Requirement');
    ValidationHelper.requireId(
      trainingRequirement.Vendor_Customization__c,
      'Vendor Program'
    );
    ValidationHelper.requireId(
      trainingRequirement.Training_System__c,
      'Training System'
    );
    return OnboardingAppVendorProgramReqRepo.insertTrainingRequirement(
      trainingRequirement
    );
  }

  @AuraEnabled
  public static void updateRequiredCredentials(
    List<Required_Credential__c> records
  ) {
    OnboardingAppVendorProgramReqRepo.updateRequiredCredentials(records);
  }

  @AuraEnabled(cacheable=true)
  public static List<External_Contact_Credential_Type__c> getCredentialTypes() {
    return OnboardingAppECCService.getAvailableCredentialTypes();
  }

  @AuraEnabled
  public static External_Contact_Credential_Type__c createCredentialType(
    External_Contact_Credential_Type__c credentialTypeInput
  ) {
    return OnboardingAppECCService.createCredentialType(credentialTypeInput);
  }

  @AuraEnabled(cacheable=true)
  public static List<Training_System__c> getTrainingSystems() {
    return OnboardingAppVendorProgramReqRepo.fetchActiveTrainingSystems();
  }

  @AuraEnabled
  public static Id createTrainingSystem(
    Training_System__c trainingSystemInput
  ) {
    ValidationHelper.requireField(trainingSystemInput.Name, 'Name');

    // Create a new record to ensure clean state
    Training_System__c newTrainingSystem = new Training_System__c();
    newTrainingSystem.Name = trainingSystemInput.Name.trim();

    // Apply default values
    DefaultValueHelper.applyTrainingSystemDefaults(newTrainingSystem);

    // Override Active__c if explicitly provided
    if (trainingSystemInput.Active__c != null) {
      newTrainingSystem.Active__c = trainingSystemInput.Active__c;
    }

    // Set System_Type__c if provided, otherwise use default
    if (String.isNotBlank(trainingSystemInput.System_Type__c)) {
      newTrainingSystem.System_Type__c = trainingSystemInput.System_Type__c;
    } else {
      newTrainingSystem.System_Type__c = 'External';
    }

    // Copy any other fields if needed
    if (String.isNotBlank(trainingSystemInput.Notes__c)) {
      newTrainingSystem.Notes__c = trainingSystemInput.Notes__c;
    }

    return OnboardingAppVendorProgramReqRepo.insertTrainingSystem(
      newTrainingSystem
    );
  }

  @AuraEnabled
  public static void updateTrainingRequirementRequiredStatus(
    List<Id> trainingRequirementIds,
    Boolean isRequired
  ) {
    if (trainingRequirementIds == null || trainingRequirementIds.isEmpty()) {
      return;
    }
    OnboardingAppVendorProgramReqRepo.updateTrainingRequirementRequiredStatus(
      trainingRequirementIds,
      isRequired
    );
  }
}
