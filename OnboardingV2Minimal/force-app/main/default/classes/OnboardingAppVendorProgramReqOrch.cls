public with sharing class OnboardingAppVendorProgramReqOrch {
  // Fetch all required credentials for a given vendor program
  public static List<Required_Credential__c> orchestrateCredentialLoad(
    Id vendorProgramId
  ) {
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
    return OnboardingAppVendorProgramReqRepo.fetchRequiredCredentials(
      vendorProgramId
    );
  }

  // Fetch all training requirements for a given vendor program
  public static List<Training_Requirement__c> orchestrateTrainingLoad(
    Id vendorProgramId
  ) {
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
    return OnboardingAppVendorProgramReqRepo.fetchTrainingRequirements(
      vendorProgramId
    );
  }

  // Create a single required credential record
  public static Id orchestrateCreateCredential(
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

  // Create a single training requirement record
  public static Id orchestrateCreateTraining(
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
}