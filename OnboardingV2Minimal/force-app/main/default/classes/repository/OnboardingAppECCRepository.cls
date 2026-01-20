public with sharing class OnboardingAppECCRepository {
  public static List<Required_Credential__c> fetchRequiredCredentials(
    Id vendorProgramId
  ) {
    return [
      SELECT
        Id,
        Name,
        External_Contact_Credential_Type__c,
        External_Contact_Credential_Type__r.Name
      FROM Required_Credential__c
      WHERE Vendor_Customization__c = :vendorProgramId
    ];
  }

  public static List<External_Contact_Credential_Type__c> fetchCredentialTypes() {
    return [
      SELECT Id, Name, Vendor_Customization__c
      FROM External_Contact_Credential_Type__c
      ORDER BY Name ASC
    ];
  }

  public static External_Contact_Credential_Type__c insertCredentialType(
    String name,
    Integer sortOrder,
    Id vendorCustomizationId,
    Boolean active
  ) {
    External_Contact_Credential_Type__c newType = new External_Contact_Credential_Type__c(
      Name = name,
      Sort_Order__c = sortOrder,
      Vendor_Customization__c = vendorCustomizationId,
      Active__c = active != null ? active : true // Default to true if not provided
    );
    insert newType;
    return newType;
  }

  public static External_Contact_Credential_Type__c insertCredentialType(
    External_Contact_Credential_Type__c credentialType
  ) {
    insert credentialType;
    return credentialType;
  }

  public static void updateRequiredCredential(
    Id requiredCredentialId,
    Id credentialTypeId
  ) {
    Required_Credential__c rc = [
      SELECT Id
      FROM Required_Credential__c
      WHERE Id = :requiredCredentialId
      LIMIT 1
    ];
    rc.External_Contact_Credential_Type__c = credentialTypeId;
    update rc;
  }
}
