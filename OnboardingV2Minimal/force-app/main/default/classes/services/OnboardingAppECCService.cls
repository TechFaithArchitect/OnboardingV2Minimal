public with sharing class OnboardingAppECCService {
  /**
   * Consolidates OnboardingAppECCController - removed controller layer
   */
  @AuraEnabled(cacheable=true)
  public static List<Required_Credential__c> getRequiredCredentials(
    Id vendorProgramId
  ) {
    return OnboardingAppECCRepository.fetchRequiredCredentials(vendorProgramId);
  }

  @AuraEnabled(cacheable=true)
  public static List<External_Contact_Credential_Type__c> getAvailableCredentialTypes() {
    return OnboardingAppECCRepository.fetchCredentialTypes();
  }

  @AuraEnabled
  public static External_Contact_Credential_Type__c createCredentialType(
    External_Contact_Credential_Type__c credentialTypeInput
  ) {
    ValidationHelper.requireRecord(credentialTypeInput, 'Credential Type');
    ValidationHelper.requireField(credentialTypeInput.Name, 'Name');
    ValidationHelper.requireId(
      credentialTypeInput.Vendor_Customization__c,
      'Vendor Program'
    );

    External_Contact_Credential_Type__c newCredentialType = new External_Contact_Credential_Type__c();
    newCredentialType.Name = credentialTypeInput.Name.trim();
    newCredentialType.Vendor_Customization__c = credentialTypeInput.Vendor_Customization__c;
    newCredentialType.Active__c = credentialTypeInput.Active__c != null
      ? credentialTypeInput.Active__c
      : true;
    if (credentialTypeInput.Sort_Order__c != null) {
      newCredentialType.Sort_Order__c = credentialTypeInput.Sort_Order__c;
    }
    if (String.isNotBlank(credentialTypeInput.Description__c)) {
      newCredentialType.Description__c = credentialTypeInput.Description__c;
    }

    return OnboardingAppECCRepository.insertCredentialType(newCredentialType);
  }

  @AuraEnabled
  public static void linkCredentialTypeToRequiredCredential(
    Id requiredCredentialId,
    Id credentialTypeId
  ) {
    OnboardingAppECCRepository.updateRequiredCredential(
      requiredCredentialId,
      credentialTypeId
    );
  }
}
