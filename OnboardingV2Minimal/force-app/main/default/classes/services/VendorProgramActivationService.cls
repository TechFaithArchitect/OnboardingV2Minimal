public with sharing class VendorProgramActivationService {
  @AuraEnabled
  public static void activate(Id recordId) {
    ValidationHelper.requireId(recordId, 'Record ID');

    // Apply activation rules before activation
    List<OnboardingAppActivationRule> activationRules = OnboardingAppRuleRegistry.getActivationRulesForObject(
      'Vendor_Customization__c'
    );
    for (OnboardingAppActivationRule activationRule : activationRules) {
      activationRule.apply(recordId, 'Vendor_Customization__c');
    }

    Vendor_Customization__c vendorProgramRecord = VendorCustomizationRepository.getById(
      recordId
    );

    if (vendorProgramRecord.Status__c == 'Active') {
      // Program is already active - throw exception without debug log
      throw new AuraHandledException('Program is already active.');
    }

    // Deactivate siblings, enforce Vendor-specific constraints, do vendor-specific post-processing
    deactivateSiblings(vendorProgramRecord);
    vendorProgramRecord.Status__c = PicklistHelper.getValidPicklistValue(
      'Vendor_Customization__c',
      'Status__c',
      'Active'
    );
    vendorProgramRecord.Active__c = true;
    VendorCustomizationRepository.updateRecord(vendorProgramRecord);

    postActivate(vendorProgramRecord);
  }

  /**
   * Activates multiple vendor programs in bulk for better performance.
   *
   * @param recordIds Set of Vendor_Customization__c record IDs to activate
   */
  public static void activateBulk(Set<Id> recordIds) {
    if (recordIds == null || recordIds.isEmpty()) {
      return;
    }

    // Apply activation rules in bulk
    List<OnboardingAppActivationRule> activationRules = OnboardingAppRuleRegistry.getActivationRulesForObject(
      'Vendor_Customization__c'
    );
    for (OnboardingAppActivationRule activationRule : activationRules) {
      activationRule.applyBulk(recordIds, 'Vendor_Customization__c');
    }

    // Query all records in one query
    List<Vendor_Customization__c> vendorProgramRecords = VendorCustomizationRepository.getByIds(
      recordIds
    );

    // Collect all parent version IDs for sibling deactivation
    Set<Id> parentVersionIds = new Set<Id>();
    for (Vendor_Customization__c vendorProgramRecord : vendorProgramRecords) {
      if (vendorProgramRecord.Status__c == 'Active') {
        throw new AuraHandledException(
          'Program ' + vendorProgramRecord.Id + ' is already active.'
        );
      }
      if (vendorProgramRecord.Previous_Version__c != null) {
        parentVersionIds.add(vendorProgramRecord.Previous_Version__c);
      }
    }

    // Deactivate all siblings in bulk
    String inactiveStatus = PicklistHelper.getValidPicklistValue(
      'Vendor_Customization__c',
      'Status__c',
      'Draft'
    );
    if (!parentVersionIds.isEmpty()) {
      List<Vendor_Customization__c> siblingsToDeactivate = new List<Vendor_Customization__c>();
      for (Id parentVersionId : parentVersionIds) {
        List<Vendor_Customization__c> siblings = VendorCustomizationRepository.getActiveSiblingsByParentVersion(
          parentVersionId,
          recordIds
        );

        // Filter out the records being activated
        for (Vendor_Customization__c siblingRecord : siblings) {
          if (!recordIds.contains(siblingRecord.Id)) {
            if (String.isNotBlank(inactiveStatus)) {
              siblingRecord.Status__c = inactiveStatus;
            }
            siblingRecord.Active__c = false;
            siblingsToDeactivate.add(siblingRecord);
          }
        }
      }

      if (!siblingsToDeactivate.isEmpty()) {
        VendorCustomizationRepository.updateRecords(siblingsToDeactivate);
      }
    }

    // Activate all records
    String activeStatus = PicklistHelper.getValidPicklistValue(
      'Vendor_Customization__c',
      'Status__c',
      'Active'
    );
    for (Vendor_Customization__c vendorProgramRecord : vendorProgramRecords) {
      vendorProgramRecord.Status__c = activeStatus;
      vendorProgramRecord.Active__c = true;
    }
    VendorCustomizationRepository.updateRecords(vendorProgramRecords);

    // Post-activation processing
    for (Vendor_Customization__c vendorProgramRecord : vendorProgramRecords) {
      postActivate(vendorProgramRecord);
    }
  }

  private static void deactivateSiblings(
    Vendor_Customization__c vendorProgramRecord
  ) {
    if (vendorProgramRecord.Previous_Version__c == null)
      return;

    Set<Id> excludeIds = new Set<Id>{ vendorProgramRecord.Id };
    List<Vendor_Customization__c> siblings = VendorCustomizationRepository.getActiveSiblingsByParentVersion(
      vendorProgramRecord.Previous_Version__c,
      excludeIds
    );

    String inactiveStatus = PicklistHelper.getValidPicklistValue(
      'Vendor_Customization__c',
      'Status__c',
      'Draft'
    );
    for (Vendor_Customization__c siblingRecord : siblings) {
      if (String.isNotBlank(inactiveStatus)) {
        siblingRecord.Status__c = inactiveStatus;
      }
      siblingRecord.Active__c = false;
    }
    if (!siblings.isEmpty()) {
      VendorCustomizationRepository.updateRecords(siblings);
    }
  }

  private static void postActivate(
    Vendor_Customization__c vendorProgramRecord
  ) {
    // Vendor-specific business rules after activation.
    if (vendorProgramRecord == null) {
      return;
    }

    // Update activation metadata if fields exist.
    Map<String, Schema.SObjectField> fields = Vendor_Customization__c.SObjectType.getDescribe()
      .fields.getMap();
    Boolean shouldUpdate = false;

    if (
      fields.containsKey('Activation_Date__c') &&
      vendorProgramRecord.get('Activation_Date__c') == null
    ) {
      vendorProgramRecord.put('Activation_Date__c', Date.today());
      shouldUpdate = true;
    }

    if (
      fields.containsKey('Activated_By__c') &&
      vendorProgramRecord.get('Activated_By__c') == null
    ) {
      vendorProgramRecord.put('Activated_By__c', UserInfo.getUserId());
      shouldUpdate = true;
    }

    if (fields.containsKey('Activation_Status__c')) {
      vendorProgramRecord.put('Activation_Status__c', 'Activated');
      shouldUpdate = true;
    }

    if (shouldUpdate) {
      VendorCustomizationRepository.updateRecord(vendorProgramRecord);
    }
  }
}
