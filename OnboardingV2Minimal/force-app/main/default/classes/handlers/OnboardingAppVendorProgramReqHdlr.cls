public with sharing class OnboardingAppVendorProgramReqHdlr {
  public static List<Required_Credential__c> loadRequiredCredentials(
    Id vendorProgramId
  ) {
    return OnboardingAppVendorProgramReqRepo.fetchRequiredCredentials(
      vendorProgramId
    );
  }

  public static List<Training_Requirement__c> loadTrainingRequirements(
    Id vendorProgramId
  ) {
    return OnboardingAppVendorProgramReqRepo.fetchTrainingRequirements(
      vendorProgramId
    );
  }

  public static Id insertRequiredCredential(
    Required_Credential__c requiredCredential
  ) {
    insert requiredCredential;
    return requiredCredential.Id;
  }

  public static Id insertTrainingRequirement(
    Training_Requirement__c trainingRequirement
  ) {
    insert trainingRequirement;
    return trainingRequirement.Id;
  }
}
