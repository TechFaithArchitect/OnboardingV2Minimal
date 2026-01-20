public with sharing class ContactECCController {
  @AuraEnabled(cacheable=true)
  public static ContactECCDependencyWrapper getECCRecordsForContact(
    Id contactId
  ) {
    // Step 1: Query ECCs for the Contact
    List<POE_External_Contact_Credential__c> eccRecords = [
      SELECT
        Id,
        POE_Process_Status__c,
        Training_Sent_Date__c,
        Activation_Date__c,
        POE_Username__c,
        POE_Program__c,
        External_Contact_Credential_Type__c,
        External_Contact_Credential_Type__r.Name,
        External_Contact_Credential_Type__r.Vendor_Customization__c
      FROM POE_External_Contact_Credential__c
      WHERE POE_Contact__c = :contactId
      ORDER BY POE_Program__c, CreatedDate DESC
    ];

    // Step 2: Build picklist values
    List<String> picklistValues = new List<String>();
    for (
      Schema.PicklistEntry entry : POE_External_Contact_Credential__c.POE_Process_Status__c.getDescribe()
        .getPicklistValues()
    ) {
      if (entry.isActive())
        picklistValues.add(entry.getValue());
    }

    // Step 3: Collect vendorCustomizationIds
    Set<Id> vendorCustomizationIds = new Set<Id>();
    for (POE_External_Contact_Credential__c ecc : eccRecords) {
      Id vcId = ecc.External_Contact_Credential_Type__r
        ?.Vendor_Customization__c;
      if (vcId != null) {
        vendorCustomizationIds.add(vcId);
        System.debug('VC ID: ' + vcId);
      }
    }

    // Step 4: Get field configurations
    Map<Id, List<ContactECCFieldConfigurationWrapper.FieldDisplayConfig>> fieldConfigurations = ContactECCFieldConfigurationWrapper.getFieldConfigurationsByVendorAndType(
      eccRecords
    );

    // Step 5: Wrap ECCs with picklist and field configs
    List<ContactECCWithOptionsWrapper> wrappedRecords = new List<ContactECCWithOptionsWrapper>();
    for (POE_External_Contact_Credential__c ecc : eccRecords) {
      Id eccId = ecc.Id;

      List<ContactECCFieldConfigurationWrapper.FieldDisplayConfig> configs = fieldConfigurations.containsKey(
          eccId
        )
        ? fieldConfigurations.get(eccId)
        : new List<ContactECCFieldConfigurationWrapper.FieldDisplayConfig>();

      System.debug('ECC ID: ' + eccId);
      System.debug('Field Configs: ' + configs);

      wrappedRecords.add(
        new ContactECCWithOptionsWrapper(ecc, picklistValues, configs)
      );
    }

    // Step 6: Get dependencies
    Map<String, Set<String>> rawDependencies = vendorCustomizationIds.isEmpty()
      ? new Map<String, Set<String>>()
      : getCredentialDependencies(vendorCustomizationIds);

    List<CredentialDependencyWrapper> dependencies = new List<CredentialDependencyWrapper>();
    for (String key : rawDependencies.keySet()) {
      dependencies.add(
        new CredentialDependencyWrapper(
          key,
          new List<String>(rawDependencies.get(key))
        )
      );
    }

    // Step 7: Return wrapper
    return new ContactECCDependencyWrapper(
      wrappedRecords,
      dependencies,
      fieldConfigurations
    );
  }

  @AuraEnabled(cacheable=true)
  public static Boolean shouldShowECC(Id contactId) {
    Contact c = [
      SELECT POE_Commercial_Programs__c
      FROM Contact
      WHERE Id = :contactId
      LIMIT 1
    ];

    return c.POE_Commercial_Programs__c != null &&
      c.POE_Commercial_Programs__c.contains('Verizon Fios D2D');
  }

  @TestVisible
  private static Map<String, Set<String>> getCredentialDependencies(
    Set<Id> vendorCustomizationIds
  ) {
    Map<String, Set<String>> dependencyMap = new Map<String, Set<String>>();

    List<External_Credential_Type_Dependency__c> dependencies = [
      SELECT Credential_Type__r.Name, Depends_On__r.Name
      FROM External_Credential_Type_Dependency__c
      WHERE Vendor_Program__c IN :vendorCustomizationIds
    ];

    for (External_Credential_Type_Dependency__c dep : dependencies) {
      String typeName = dep.Credential_Type__r?.Name;
      String dependsOnName = dep.Depends_On__r?.Name;

      if (String.isNotBlank(typeName) && String.isNotBlank(dependsOnName)) {
        if (!dependencyMap.containsKey(typeName)) {
          dependencyMap.put(typeName, new Set<String>());
        }
        dependencyMap.get(typeName).add(dependsOnName);
      }
    }

    return dependencyMap;
  }

  @AuraEnabled
  public static void updateECCRecord(
    POE_External_Contact_Credential__c updatedRecord
  ) {
    try {
      update updatedRecord;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Failed to update ECC record: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<POE_External_Contact_Credential__c> getECCRecordsForOnboarding(
    Id onboardingId
  ) {
    Onboarding__c onboarding = [
      SELECT Account__c, Vendor_Customization__c
      FROM Onboarding__c
      WHERE Id = :onboardingId
      LIMIT 1
    ];

    List<Contact> principalContacts = [
      SELECT Id
      FROM Contact
      WHERE AccountId = :onboarding.Account__c AND Principal_Owner__c = TRUE
      LIMIT 1
    ];

    if (principalContacts.isEmpty()) {
      return new List<POE_External_Contact_Credential__c>();
    }

    Id principalContactId = principalContacts[0].Id;

    Set<Id> requiredECCTypes = new Set<Id>();
    for (Required_Credential__c rc : [
      SELECT External_Contact_Credential_Type__c
      FROM Required_Credential__c
      WHERE
        Vendor_Customization__c = :onboarding.Vendor_Customization__c
        AND External_Contact_Credential_Type__c != NULL
    ]) {
      requiredECCTypes.add(rc.External_Contact_Credential_Type__c);
    }

    if (requiredECCTypes.isEmpty()) {
      return new List<POE_External_Contact_Credential__c>();
    }

    return [
      SELECT
        Id,
        POE_Process_Status__c,
        Training_Sent_Date__c,
        Activation_Date__c,
        POE_Username__c,
        POE_Program__c,
        External_Contact_Credential_Type__r.Name
      FROM POE_External_Contact_Credential__c
      WHERE
        POE_Contact__c = :principalContactId
        AND External_Contact_Credential_Type__c IN :requiredECCTypes
      ORDER BY POE_Program__c, CreatedDate DESC
    ];
  }
}
