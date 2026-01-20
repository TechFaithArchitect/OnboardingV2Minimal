public with sharing class OnboardingRulesRepository {
  public static List<Onboarding_Status_Rule__c> fetchRulesEngineRecords(
    Id engineId
  ) {
    if (engineId == null) {
      return new List<Onboarding_Status_Rule__c>();
    }
    return [
      SELECT
        Id,
        Name,
        Rule_Number__c,
        Requirement__c,
        Expected_Status__c,
        Parent_Rule__c,
        Requirement__r.Name,
        Requirement__r.Requirement_Template__r.Requirement_Label__c
      FROM Onboarding_Status_Rule__c
      WHERE Parent_Rule__c = :engineId
      ORDER BY Rule_Number__c ASC NULLS LAST, CreatedDate DESC
    ];
  }

  public static Onboarding_Status_Rule__c upsertRule(
    Onboarding_Status_Rule__c statusRuleRecord
  ) {
    upsert statusRuleRecord;
    return statusRuleRecord;
  }

  public static void deleteRule(Id ruleId) {
    if (ruleId == null) {
      return;
    }
    List<Onboarding_Status_Rule__c> rulesToDelete = [
      SELECT Id
      FROM Onboarding_Status_Rule__c
      WHERE Id = :ruleId
      LIMIT 1
    ];
    if (!rulesToDelete.isEmpty()) {
      delete rulesToDelete;
    }
  }

  /**
   * Bulk delete rules by IDs
   * @param ruleIds List of rule IDs to delete
   */
  public static void deleteRules(List<Id> ruleIds) {
    if (ruleIds == null || ruleIds.isEmpty()) {
      return;
    }
    List<Onboarding_Status_Rule__c> rulesToDelete = [
      SELECT Id
      FROM Onboarding_Status_Rule__c
      WHERE Id IN :ruleIds
    ];
    if (!rulesToDelete.isEmpty()) {
      delete rulesToDelete;
    }
  }

  public static Onboarding__c fetchOnboardingWithRequirements(Id onboardingId) {
    if (onboardingId == null) {
      return null;
    }
    List<Onboarding__c> onboardings = [
      SELECT
        Id,
        Vendor_Customization__c,
        (
          SELECT
            Id,
            Status__c,
            Vendor_Program_Requirement__c,
            Vendor_Program_Requirement__r.Requirement_Template__c,
            Vendor_Program_Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c,
            Vendor_Program_Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
          FROM Onboarding_Requirements__r
          WHERE Vendor_Program_Requirement__c != NULL
        )
      FROM Onboarding__c
      WHERE Id = :onboardingId
      LIMIT 1
    ];
    return onboardings.isEmpty() ? null : onboardings[0];
  }

  public static List<Onboarding_Status_Rules_Engine__c> fetchRulesForGroups(
    List<Id> groupIds
  ) {
    if (groupIds == null || groupIds.isEmpty()) {
      return new List<Onboarding_Status_Rules_Engine__c>();
    }
    return [
      SELECT
        Id,
        Name,
        LastModifiedDate,
        Evaluation_Logic__c,
        Custom_Evaluation_Logic__c,
        Override_Status__c,
        Target_Onboarding_Status__c,
        Vendor_Program_Group__c,
        Sequence__c,
        (
          SELECT
            Id,
            Name,
            Rule_Number__c,
            Requirement__c,
            Expected_Status__c,
            Requirement__r.Name,
            Requirement__r.Requirement_Template__c,
            Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c,
            Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
          FROM Onboarding_Status_Rules__r
        )
      FROM Onboarding_Status_Rules_Engine__c
      WHERE Vendor_Program_Group__c IN :groupIds
      ORDER BY Sequence__c ASC NULLS LAST, CreatedDate ASC
    ];
  }

  public static List<Onboarding_Requirement__c> fetchRequirementsByOnboardingIds(
    Set<Id> onboardingIds
  ) {
    if (onboardingIds == null || onboardingIds.isEmpty()) {
      return new List<Onboarding_Requirement__c>();
    }
    return [
      SELECT
        Id,
        Status__c,
        Completed__c,
        Vendor_Program_Requirement__c,
        Onboarding__c,
        Vendor_Program_Requirement__r.Requirement_Template__c,
        Vendor_Program_Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c,
        Vendor_Program_Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
      FROM Onboarding_Requirement__c
      WHERE Onboarding__c IN :onboardingIds
    ];
  }

  /**
   * Fetches requirements by onboarding ID with Name field for panel display
   * @param onboardingId Onboarding ID
   * @return List of requirements
   */
  public static List<Onboarding_Requirement__c> fetchRequirementsByOnboardingId(
    Id onboardingId
  ) {
    if (onboardingId == null) {
      return new List<Onboarding_Requirement__c>();
    }
    return [
      SELECT Id, Name, Status__c, Due_Date__c
      FROM Onboarding_Requirement__c
      WHERE Onboarding__c = :onboardingId
    ];
  }

  /**
   * Updates requirements in bulk
   * @param requirements List of requirements to update
   */
  public static void updateRequirements(
    List<Onboarding_Requirement__c> requirements
  ) {
    if (requirements == null || requirements.isEmpty()) {
      return;
    }
    update requirements;
  }

  /**
   * Gets onboarding IDs from requirement IDs
   * @param requirementIds Set of requirement IDs
   * @return Set of onboarding IDs
   */
  public static Set<Id> getOnboardingIdsFromRequirementIds(
    Set<Id> requirementIds
  ) {
    Set<Id> onboardingIds = new Set<Id>();
    if (requirementIds == null || requirementIds.isEmpty()) {
      return onboardingIds;
    }
    for (AggregateResult aggregateResult : [
      SELECT Onboarding__c
      FROM Onboarding_Requirement__c
      WHERE Id IN :requirementIds
      GROUP BY Onboarding__c
    ]) {
      onboardingIds.add((Id) aggregateResult.get('Onboarding__c'));
    }
    return onboardingIds;
  }

  public static List<Onboarding__c> fetchOnboardingsByIds(
    Set<Id> onboardingIds
  ) {
    if (onboardingIds == null || onboardingIds.isEmpty()) {
      return new List<Onboarding__c>();
    }
    return [
      SELECT Id, Vendor_Customization__c
      FROM Onboarding__c
      WHERE Id IN :onboardingIds
    ];
  }

  /**
   * Fetches Onboarding__c records for dynamic field access
   * Used when we need to check custom status fields dynamically
   * @param onboardingIds Set of Onboarding IDs
   * @return List of Onboarding__c records
   */
  public static List<Onboarding__c> fetchOnboardingsByIdsWithAllFields(
    Set<Id> onboardingIds
  ) {
    return fetchOnboardingsByIdsWithFields(onboardingIds, null);
  }

  /**
   * Fetches Onboarding__c records with optional dynamic fields included.
   * @param onboardingIds Set of Onboarding IDs
   * @param extraFieldApiNames Additional Onboarding__c field API names to include
   * @return List of Onboarding__c records
   */
  public static List<Onboarding__c> fetchOnboardingsByIdsWithFields(
    Set<Id> onboardingIds,
    Set<String> extraFieldApiNames
  ) {
    if (onboardingIds == null || onboardingIds.isEmpty()) {
      return new List<Onboarding__c>();
    }

    Set<String> fields = new Set<String>{
      'Id',
      'Vendor_Customization__c',
      'Onboarding_Status__c',
      'External_Override_Enabled__c',
      'External_Override_Programs__c',
      'External_Override_Source__c',
      'External_Override_Request_ID__c',
      'External_Override_Date__c',
      'Previous_Status_Before_Override__c'
    };

    if (extraFieldApiNames != null && !extraFieldApiNames.isEmpty()) {
      Map<String, Schema.SObjectField> fieldMap = Onboarding__c.SObjectType.getDescribe()
        .fields.getMap();
      for (String fieldName : extraFieldApiNames) {
        if (fieldMap.containsKey(fieldName)) {
          fields.add(fieldName);
        }
      }
    }

    List<String> fieldList = new List<String>();
    fieldList.addAll(fields);
    fieldList.sort();

    String soql =
      'SELECT ' +
      String.join(fieldList, ', ') +
      ' FROM Onboarding__c WHERE Id IN :onboardingIds';
    return Database.query(soql);
  }

  public static List<Vendor_Program_Group_Member__c> fetchGroupMembersByVendorProgramIds(
    Set<Id> vendorProgramIds
  ) {
    if (vendorProgramIds == null || vendorProgramIds.isEmpty()) {
      return new List<Vendor_Program_Group_Member__c>();
    }
    return [
      SELECT Vendor_Program_Group__c, Required_Program__c
      FROM Vendor_Program_Group_Member__c
      WHERE Required_Program__c IN :vendorProgramIds
    ];
  }

  public static List<Vendor_Program_Group_Member__c> fetchGroupMembersByVendorProgramId(
    Id vendorProgramId
  ) {
    if (vendorProgramId == null) {
      return new List<Vendor_Program_Group_Member__c>();
    }
    return [
      SELECT Vendor_Program_Group__c
      FROM Vendor_Program_Group_Member__c
      WHERE Required_Program__c = :vendorProgramId
    ];
  }

  /**
   * Fetches rules engines by vendor program group and requirement group
   * @param vendorProgramGroupId Vendor Program Group ID
   * @param requirementGroupId Requirement Group ID
   * @return List of rules engines
   */
  public static List<Onboarding_Status_Rules_Engine__c> fetchRulesEnginesByGroups(
    Id vendorProgramGroupId,
    Id requirementGroupId
  ) {
    if (vendorProgramGroupId == null || requirementGroupId == null) {
      return new List<Onboarding_Status_Rules_Engine__c>();
    }
    return [
      SELECT
        Id,
        Name,
        Required_Status__c,
        Target_Onboarding_Status__c,
        Evaluation_Logic__c,
        Custom_Evaluation_Logic__c
      FROM Onboarding_Status_Rules_Engine__c
      WHERE
        Vendor_Program_Group__c = :vendorProgramGroupId
        AND Requirement_Group__c = :requirementGroupId
      ORDER BY Name
    ];
  }

  /**
   * Fetches rules engines by vendor program group only
   * @param vendorProgramGroupId Vendor Program Group ID
   * @return List of rules engines
   */
  public static List<Onboarding_Status_Rules_Engine__c> fetchRulesEnginesByVendorProgramGroup(
    Id vendorProgramGroupId
  ) {
    if (vendorProgramGroupId == null) {
      return new List<Onboarding_Status_Rules_Engine__c>();
    }
    return [
      SELECT
        Id,
        Name,
        Evaluation_Logic__c,
        Override_Status__c,
        Vendor_Program_Group__c
      FROM Onboarding_Status_Rules_Engine__c
      WHERE Vendor_Program_Group__c = :vendorProgramGroupId
      ORDER BY Name
    ];
  }

  /**
   * Fetches a single rules engine by ID
   * @param ruleId Rules engine ID
   * @return Rules engine or null if not found
   */
  public static Onboarding_Status_Rules_Engine__c fetchRulesEngineById(
    Id ruleId
  ) {
    if (ruleId == null) {
      return null;
    }
    List<Onboarding_Status_Rules_Engine__c> engines = [
      SELECT
        Id,
        Name,
        Evaluation_Logic__c,
        Custom_Evaluation_Logic__c,
        Override_Status__c,
        Vendor_Program_Group__c
      FROM Onboarding_Status_Rules_Engine__c
      WHERE Id = :ruleId
      LIMIT 1
    ];
    return engines.isEmpty() ? null : engines[0];
  }

  /**
   * Fetches conditions (rules) for a rules engine
   * @param ruleId Rules engine ID
   * @return List of status rules
   */
  public static List<Onboarding_Status_Rule__c> fetchConditionsByRuleId(
    Id ruleId
  ) {
    if (ruleId == null) {
      return new List<Onboarding_Status_Rule__c>();
    }
    return [
      SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c
      FROM Onboarding_Status_Rule__c
      WHERE Parent_Rule__c = :ruleId
      ORDER BY Rule_Number__c ASC
    ];
  }

  /**
   * Updates rules engines in bulk
   * @param rulesEngines List of rules engines to update
   */
  public static void updateRulesEngines(
    List<Onboarding_Status_Rules_Engine__c> rulesEngines
  ) {
    if (rulesEngines == null || rulesEngines.isEmpty()) {
      return;
    }
    update rulesEngines;
  }

  /**
   * Upserts a single rules engine
   * @param rulesEngine Rules engine to upsert
   * @return Upserted rules engine
   */
  public static Onboarding_Status_Rules_Engine__c upsertRulesEngine(
    Onboarding_Status_Rules_Engine__c rulesEngine
  ) {
    if (rulesEngine == null) {
      return null;
    }
    upsert rulesEngine;
    return rulesEngine;
  }

  /**
   * Upserts status rules (conditions) in bulk
   * @param conditions List of status rules to upsert
   */
  public static void upsertConditions(
    List<Onboarding_Status_Rule__c> conditions
  ) {
    if (conditions == null || conditions.isEmpty()) {
      return;
    }
    upsert conditions;
  }
}
