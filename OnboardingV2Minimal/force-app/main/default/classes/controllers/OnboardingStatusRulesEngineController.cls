public with sharing class OnboardingStatusRulesEngineController {
  @AuraEnabled(cacheable=true)
  public static List<Onboarding_Status_Rules_Engine__c> getRules(
    Id vendorProgramGroupId,
    Id requirementGroupId
  ) {
    return OnboardingRulesService.getRulesEngines(
      vendorProgramGroupId,
      requirementGroupId
    );
  }

  @AuraEnabled
  public static void saveRules(
    List<Onboarding_Status_Rules_Engine__c> statusRulesEngineRecords
  ) {
    OnboardingRulesService.saveRulesEngines(statusRulesEngineRecords);
  }

  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> getVendorProgramGroups() {
    List<Map<String, String>> options = new List<Map<String, String>>();
    for (Vendor_Program_Group__c vendorProgramGroup : [
      SELECT Id, Name
      FROM Vendor_Program_Group__c
      ORDER BY Name
      LIMIT 1000
    ]) {
      options.add(
        new Map<String, String>{
          'value' => vendorProgramGroup.Id,
          'label' => vendorProgramGroup.Name
        }
      );
    }
    return options;
  }

  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> getRequirementGroups() {
    List<Map<String, String>> options = new List<Map<String, String>>();
    for (Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup : [
      SELECT Id, Name
      FROM Vendor_Program_Requirement_Group__c
      ORDER BY Name
      LIMIT 1000
    ]) {
      options.add(
        new Map<String, String>{
          'value' => vendorProgramRequirementGroup.Id,
          'label' => vendorProgramRequirementGroup.Name
        }
      );
    }
    return options;
  }

  /**
   * Get list of onboarding records for preview evaluation selection
   * Returns recent active onboarding records with their account and vendor program names
   *
   * @param limitCount Maximum number of records to return (defaults to 50)
   * @return List of maps with Id, label (Account - Vendor Program), and Name
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> getOnboardingOptions(
    Integer limitCount
  ) {
    if (limitCount == null || limitCount <= 0) {
      limitCount = 50;
    }

    List<Map<String, String>> options = new List<Map<String, String>>();
    for (Onboarding__c onboardingRecord : [
      SELECT Id, Name, Account__r.Name, Vendor_Customization__r.Name
      FROM Onboarding__c
      WHERE
        Onboarding_Status__c != 'Complete'
        AND Onboarding_Status__c != 'Expired'
      ORDER BY LastModifiedDate DESC
      LIMIT :limitCount
    ]) {
      String label = onboardingRecord.Name;
      if (
        String.isNotBlank(onboardingRecord.Account__r.Name) &&
        String.isNotBlank(onboardingRecord.Vendor_Customization__r.Name)
      ) {
        label =
          onboardingRecord.Account__r.Name +
          ' - ' +
          onboardingRecord.Vendor_Customization__r.Name;
      }

      options.add(
        new Map<String, String>{
          'value' => onboardingRecord.Id,
          'label' => label
        }
      );
    }
    return options;
  }

  /**
   * Preview status evaluation for an onboarding record without applying changes.
   * Returns trace information showing which rules were evaluated and their results.
   *
   * @param onboardingId Onboarding__c ID to evaluate
   * @param asOfDateTime Optional datetime to simulate effective-dated rules (future use)
   * @param rulesEngineIds Optional list of specific rules engine IDs to evaluate (if null, evaluates all applicable)
   * @return List of StatusEvaluationTraceDTO showing evaluation trace
   */
  @AuraEnabled(cacheable=true)
  public static List<StatusEvaluationTraceDTO> previewStatusEvaluation(
    Id onboardingId,
    Datetime asOfDateTime,
    List<Id> rulesEngineIds
  ) {
    ValidationHelper.requireId(onboardingId, 'Onboarding ID');

    List<StatusEvaluationTraceDTO> traceList = new List<StatusEvaluationTraceDTO>();

    // Get onboarding with requirements
    Onboarding__c onboardingRecord = OnboardingRulesRepository.fetchOnboardingWithRequirements(
      onboardingId
    );
    if (onboardingRecord == null) {
      return traceList;
    }

    Id vendorProgramId = onboardingRecord.Vendor_Customization__c;
    if (vendorProgramId == null) {
      StatusEvaluationTraceDTO trace = new StatusEvaluationTraceDTO();
      trace.shortCircuitReason = 'No Vendor Program associated';
      traceList.add(trace);
      return traceList;
    }

    // Get group IDs for this vendor program
    List<Id> groupIds = OnboardingRulesService.getVendorProgramGroupIds(
      vendorProgramId
    );
    if (groupIds.isEmpty()) {
      StatusEvaluationTraceDTO trace = new StatusEvaluationTraceDTO();
      trace.shortCircuitReason = 'No Vendor Program Groups found';
      traceList.add(trace);
      return traceList;
    }

    // Get rules engines
    List<Onboarding_Status_Rules_Engine__c> allRulesEngines = OnboardingRulesService.getRulesForGroups(
      groupIds
    );

    // Filter by rulesEngineIds if provided
    if (rulesEngineIds != null && !rulesEngineIds.isEmpty()) {
      Set<Id> engineIdSet = new Set<Id>(rulesEngineIds);
      List<Onboarding_Status_Rules_Engine__c> filteredRulesEngines = new List<Onboarding_Status_Rules_Engine__c>();
      for (
        Onboarding_Status_Rules_Engine__c statusRulesEngineRecord : allRulesEngines
      ) {
        if (engineIdSet.contains(statusRulesEngineRecord.Id)) {
          filteredRulesEngines.add(statusRulesEngineRecord);
        }
      }
      allRulesEngines = filteredRulesEngines;
    }

    if (allRulesEngines.isEmpty()) {
      StatusEvaluationTraceDTO trace = new StatusEvaluationTraceDTO();
      trace.shortCircuitReason = 'No rules engines found for applicable groups';
      traceList.add(trace);
      return traceList;
    }

    Set<String> mappedFieldApiNames = collectMappedFieldApiNames(
      allRulesEngines
    );
    List<Onboarding__c> fullOnboardingRecords = OnboardingRulesRepository.fetchOnboardingsByIdsWithFields(
      new Set<Id>{ onboardingId },
      mappedFieldApiNames
    );
    Onboarding__c fullOnboardingRecord = fullOnboardingRecords.isEmpty()
      ? onboardingRecord
      : fullOnboardingRecords[0];

    // Check for external override
    if (
      Boolean.valueOf(fullOnboardingRecord.get('External_Override_Enabled__c'))
    ) {
      StatusEvaluationTraceDTO trace = new StatusEvaluationTraceDTO();
      trace.shortCircuitReason = 'External Override Enabled - evaluation skipped';
      traceList.add(trace);
      return traceList;
    }

    // Build requirements map
    Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>();
    for (
      Onboarding_Requirement__c onboardingRequirement : onboardingRecord.Onboarding_Requirements__r
    ) {
      if (onboardingRequirement.Vendor_Program_Requirement__c != null) {
        reqByVPR.put(
          onboardingRequirement.Vendor_Program_Requirement__c,
          onboardingRequirement
        );
      }
    }

    // Get group names for display
    Map<Id, String> groupNamesById = new Map<Id, String>();
    for (Vendor_Program_Group__c vendorProgramGroup : [
      SELECT Id, Name
      FROM Vendor_Program_Group__c
      WHERE Id IN :groupIds
    ]) {
      groupNamesById.put(vendorProgramGroup.Id, vendorProgramGroup.Name);
    }

    // Evaluate each rules engine
    String finalStatus = null;
    Integer ruleOrder = 0;

    for (Id groupId : groupIds) {
      List<Onboarding_Status_Rules_Engine__c> groupRulesEngines = new List<Onboarding_Status_Rules_Engine__c>();
      for (
        Onboarding_Status_Rules_Engine__c statusRulesEngineRecord : allRulesEngines
      ) {
        if (statusRulesEngineRecord.Vendor_Program_Group__c == groupId) {
          groupRulesEngines.add(statusRulesEngineRecord);
        }
      }

      if (groupRulesEngines.isEmpty()) {
        continue;
      }

      String groupName = groupNamesById.get(groupId);

      // Check for override rules first
      for (
        Onboarding_Status_Rules_Engine__c statusRulesEngineRecord : groupRulesEngines
      ) {
        if (
          statusRulesEngineRecord.Override_Status__c == true &&
          String.isNotBlank(statusRulesEngineRecord.Target_Onboarding_Status__c)
        ) {
          StatusEvaluationTraceDTO trace = new StatusEvaluationTraceDTO();
          trace.engineId = statusRulesEngineRecord.Id;
          trace.engineName = statusRulesEngineRecord.Name;
          trace.groupId = groupId;
          trace.groupName = groupName;
          trace.passed = true;
          trace.resultingStatus = statusRulesEngineRecord.Target_Onboarding_Status__c;
          trace.shortCircuitReason = 'Override rule - status forced';
          trace.evaluationLogic = 'OVERRIDE';
          trace.ruleOrder = ++ruleOrder;
          traceList.add(trace);
          finalStatus = statusRulesEngineRecord.Target_Onboarding_Status__c;
          break;
        }
      }
      if (finalStatus != null) {
        break;
      }

      // Evaluate non-override rules
      for (
        Onboarding_Status_Rules_Engine__c statusRulesEngineRecord : groupRulesEngines
      ) {
        if (statusRulesEngineRecord.Override_Status__c == true) {
          continue;
        }

        ruleOrder++;
        Boolean rulePassed = OnboardingRuleEvaluator.evaluateRule(
          statusRulesEngineRecord,
          reqByVPR,
          fullOnboardingRecord
        );

        StatusEvaluationTraceDTO trace = new StatusEvaluationTraceDTO();
        trace.engineId = statusRulesEngineRecord.Id;
        trace.engineName = statusRulesEngineRecord.Name;
        trace.groupId = groupId;
        trace.groupName = groupName;
        trace.passed = rulePassed;
        trace.evaluationLogic = statusRulesEngineRecord.Evaluation_Logic__c;
        trace.ruleOrder = ruleOrder;

        if (
          rulePassed &&
          String.isNotBlank(statusRulesEngineRecord.Target_Onboarding_Status__c)
        ) {
          trace.resultingStatus = statusRulesEngineRecord.Target_Onboarding_Status__c;
          finalStatus = statusRulesEngineRecord.Target_Onboarding_Status__c;
        } else if (!rulePassed) {
          trace.shortCircuitReason = 'Rule evaluation failed';
        }

        // Add details about individual rule conditions
        if (
          statusRulesEngineRecord.Onboarding_Status_Rules__r != null &&
          !statusRulesEngineRecord.Onboarding_Status_Rules__r.isEmpty()
        ) {
          for (
            Onboarding_Status_Rule__c onboardingStatusRule : statusRulesEngineRecord.Onboarding_Status_Rules__r
          ) {
            StatusEvaluationTraceDTO conditionTrace = new StatusEvaluationTraceDTO();
            conditionTrace.engineId = trace.engineId;
            conditionTrace.engineName = trace.engineName;
            conditionTrace.groupId = trace.groupId;
            conditionTrace.groupName = trace.groupName;
            conditionTrace.passed = trace.passed;
            conditionTrace.evaluationLogic = trace.evaluationLogic;
            conditionTrace.ruleOrder = trace.ruleOrder;
            conditionTrace.ruleNumber = Integer.valueOf(
              onboardingStatusRule.Rule_Number__c
            );
            conditionTrace.ruleName = onboardingStatusRule.Name;
            conditionTrace.requirementName = onboardingStatusRule.Requirement__r !=
              null
              ? onboardingStatusRule.Requirement__r.Name
              : null;
            conditionTrace.expectedStatus = onboardingStatusRule.Expected_Status__c;

            // Check if this condition passed
            Onboarding_Requirement__c matchedOnboardingRequirement = reqByVPR.get(
              onboardingStatusRule.Requirement__c
            );
            if (matchedOnboardingRequirement != null) {
              conditionTrace.passed = (matchedOnboardingRequirement.Status__c ==
              onboardingStatusRule.Expected_Status__c);
            } else {
              conditionTrace.passed = false;
              conditionTrace.shortCircuitReason = 'Requirement not found';
            }

            traceList.add(conditionTrace);
          }
        } else {
          traceList.add(trace);
        }

        if (finalStatus != null) {
          break;
        }
      }

      if (finalStatus != null) {
        break;
      }
    }

    // Add final status summary
    if (finalStatus != null) {
      StatusEvaluationTraceDTO summary = new StatusEvaluationTraceDTO();
      summary.shortCircuitReason = 'Evaluation complete';
      summary.resultingStatus = finalStatus;
      summary.ruleOrder = 9999; // Show at end
      traceList.add(summary);
    }

    return traceList;
  }

  private static Set<String> collectMappedFieldApiNames(
    List<Onboarding_Status_Rules_Engine__c> rulesEngines
  ) {
    Set<String> fieldApiNames = new Set<String>();
    if (rulesEngines == null || rulesEngines.isEmpty()) {
      return fieldApiNames;
    }
    for (Onboarding_Status_Rules_Engine__c engine : rulesEngines) {
      if (engine.Onboarding_Status_Rules__r == null) {
        continue;
      }
      for (Onboarding_Status_Rule__c rule : engine.Onboarding_Status_Rules__r) {
        String fieldApiName = rule.Requirement__r
          ?.Requirement_Template__r
          ?.Onboarding_Status_Field_API_Name__c;
        if (String.isNotBlank(fieldApiName)) {
          fieldApiNames.add(fieldApiName);
        }
      }
    }
    return fieldApiNames;
  }
}
