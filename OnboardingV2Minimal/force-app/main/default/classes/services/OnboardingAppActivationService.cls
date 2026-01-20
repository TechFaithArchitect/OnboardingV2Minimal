public with sharing class OnboardingAppActivationService {
  /**
   * @AuraEnabled method for LWC components - uses strategy pattern to support different object types
   * Consolidates OnboardingAppActivationOrchestrator logic
   * Note: Can be called from both LWC (@AuraEnabled) and test classes
   */
  @AuraEnabled
  public static void activate(Id recordId, String objectApiName) {
    activateRecord(objectApiName, recordId);
  }

  public static void activateRecord(String objectApiName, Id recordId) {
    ValidationHelper.requireNotBlank(objectApiName, 'Object API Name');
    ValidationHelper.requireId(recordId, 'Record Id');

    // === ✅ Apply Activation Guard Rules
    List<OnboardingAppActivationRule> activationRules = OnboardingAppRuleRegistry.getActivationRulesForObject(
      objectApiName
    );

    for (OnboardingAppActivationRule activationRule : activationRules) {
      activationRule.apply(recordId, objectApiName);
    }

    // Activate the record
    activateRecordInternal(objectApiName, recordId);
  }

  /**
   * Activates multiple records in bulk for better performance.
   * Groups records by object type and applies rules in bulk.
   *
   * @param recordIdsByObject Map of object API name to set of record IDs to activate
   */
  public static void activateRecordsBulk(
    Map<String, Set<Id>> recordIdsByObject
  ) {
    if (recordIdsByObject == null || recordIdsByObject.isEmpty()) {
      return;
    }

    // Process each object type
    for (String objectApiName : recordIdsByObject.keySet()) {
      Set<Id> recordIds = recordIdsByObject.get(objectApiName);
      if (recordIds == null || recordIds.isEmpty()) {
        continue;
      }

      // Apply activation rules in bulk
      List<OnboardingAppActivationRule> activationRules = OnboardingAppRuleRegistry.getActivationRulesForObject(
        objectApiName
      );

      for (OnboardingAppActivationRule activationRule : activationRules) {
        activationRule.applyBulk(recordIds, objectApiName);
      }

      // Activate each record individually (versioning logic is per-record)
      for (Id recordId : recordIds) {
        activateRecordInternal(objectApiName, recordId);
      }
    }
  }

  /**
   * Internal method to activate a single record (without rule validation).
   * Used by both single and bulk activation methods.
   */
  private static void activateRecordInternal(
    String objectApiName,
    Id recordId
  ) {
    // === ✅ Load record metadata
    Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe()
      .get(objectApiName)
      .getDescribe()
      .fields.getMap();

    List<String> selectFields = new List<String>{ 'Id' };
    Boolean hasActiveField = fieldMap.containsKey('Active__c');
    Boolean hasLegacyActiveField = fieldMap.containsKey('Is_Active__c');

    if (fieldMap.containsKey('Status__c'))
      selectFields.add('Status__c');
    if (hasLegacyActiveField)
      selectFields.add('Is_Active__c');
    if (hasActiveField)
      selectFields.add('Active__c');
    if (fieldMap.containsKey('Previous_Version__c'))
      selectFields.add('Previous_Version__c');

    SObject onboardingRecord = OnboardingAppActivationRepository.getById(
      objectApiName,
      recordId,
      selectFields
    );

    // === ✅ Skip if already active
    if (fieldMap.containsKey('Status__c')) {
      String status = (String) onboardingRecord.get('Status__c');
      if (status == 'Active') {
        throw new AuraHandledException('Record is already active.');
      }
    }

    // === ✅ Versioning logic (if supported)
    Id parentVersionId = fieldMap.containsKey('Previous_Version__c')
      ? (Id) onboardingRecord.get('Previous_Version__c')
      : null;

    if (parentVersionId != null && (hasActiveField || hasLegacyActiveField)) {
      String activeFieldName = hasActiveField ? 'Active__c' : 'Is_Active__c';
      List<SObject> siblings = OnboardingAppActivationRepository.getActiveSiblingsByParentVersion(
        objectApiName,
        parentVersionId,
        recordId,
        activeFieldName
      );

      for (SObject siblingRecord : siblings) {
        siblingRecord.put(activeFieldName, false);
      }
      if (!siblings.isEmpty()) {
        OnboardingAppActivationRepository.updateRecords(siblings);
      }
    }

    // === ✅ Final Activation
    if (fieldMap.containsKey('Status__c')) {
      onboardingRecord.put('Status__c', 'Active');
    }

    if (hasActiveField) {
      onboardingRecord.put('Active__c', true);
    } else if (hasLegacyActiveField) {
      onboardingRecord.put('Is_Active__c', true);
    }

    OnboardingAppActivationRepository.updateRecord(onboardingRecord);
  }
}
