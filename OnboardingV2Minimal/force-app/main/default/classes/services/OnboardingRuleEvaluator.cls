public with sharing class OnboardingRuleEvaluator {
  public static Boolean evaluateRule(
    Onboarding_Status_Rules_Engine__c rule,
    Map<Id, Onboarding_Requirement__c> reqByVPR
  ) {
    return evaluateRule(rule, reqByVPR, null);
  }

  public static Boolean evaluateRule(
    Onboarding_Status_Rules_Engine__c rule,
    Map<Id, Onboarding_Requirement__c> reqByVPR,
    Onboarding__c onboardingRecord
  ) {
    Map<String, Boolean> conditionsMap = new Map<String, Boolean>();

    for (Onboarding_Status_Rule__c cond : rule.Onboarding_Status_Rules__r) {
      Boolean matchesExpected = false;
      Onboarding_Requirement__c matchedReq = reqByVPR.get(cond.Requirement__c);

      if (matchedReq != null) {
        // Check if template has field mapping
        String templateFieldApiName = cond.Requirement__r
          ?.Requirement_Template__r
          ?.Onboarding_Status_Field_API_Name__c;
        String templateCompletionValues = cond.Requirement__r
          ?.Requirement_Template__r
          ?.Onboarding_Status_Value_When_Complete__c;

        if (
          String.isNotBlank(templateFieldApiName) &&
          String.isNotBlank(templateCompletionValues) &&
          onboardingRecord != null
        ) {
          // Use template mapping: check Onboarding__c field value against completion values
          matchesExpected = checkOnboardingFieldValue(
            onboardingRecord,
            templateFieldApiName,
            templateCompletionValues
          );
        } else {
          // Fall back to existing logic: check requirement Status__c
          matchesExpected = (matchedReq.Status__c == cond.Expected_Status__c);
        }
      }

      conditionsMap.put(String.valueOf(cond.Rule_Number__c), matchesExpected);
    }

    if (rule.Evaluation_Logic__c == 'ALL') {
      return !conditionsMap.values().contains(false);
    } else if (rule.Evaluation_Logic__c == 'ANY') {
      return conditionsMap.values().contains(true);
    } else if (rule.Evaluation_Logic__c == 'CUSTOM') {
      String logic = rule.Custom_Evaluation_Logic__c;
      for (String key : conditionsMap.keySet()) {
        logic = logic.replace(key, String.valueOf(conditionsMap.get(key)));
      }
      logic = logic.replaceAll('(?i)\\sAND\\s', ' && ')
        .replaceAll('(?i)\\sOR\\s', ' || ');
      return OnboardingExpressionEngine.evaluate(logic); // this calls the overload!
    }

    return false;
  }

  /**
   * Checks if the Onboarding__c record's field value matches any of the completion values
   * @param onboardingRecord The Onboarding__c record to check
   * @param fieldApiName The API name of the field to check (e.g., 'Labor_Form_Status__c')
   * @param completionValues Semicolon-separated list of values that indicate completion (e.g., 'Onboarding Approved;Approved Box 1')
   * @return true if the field value matches any completion value
   */
  private static Boolean checkOnboardingFieldValue(
    Onboarding__c onboardingRecord,
    String fieldApiName,
    String completionValues
  ) {
    if (
      onboardingRecord == null ||
      String.isBlank(fieldApiName) ||
      String.isBlank(completionValues)
    ) {
      return false;
    }

    try {
      // Get the field value from the record using dynamic field access
      Object fieldValue = onboardingRecord.get(fieldApiName);
      if (fieldValue == null) {
        return false;
      }

      String fieldValueStr = String.valueOf(fieldValue);

      // Parse semicolon-separated completion values
      List<String> completionValueList = completionValues.split(';');
      Set<String> completionValueSet = new Set<String>();

      for (String value : completionValueList) {
        String trimmedValue = value.trim();
        if (String.isNotBlank(trimmedValue)) {
          completionValueSet.add(trimmedValue);
        }
      }

      // Check if the field value matches any completion value
      return completionValueSet.contains(fieldValueStr);
    } catch (Exception ex) {
      System.debug(
        'Error checking Onboarding field value for ' +
          fieldApiName +
          ': ' +
          ex.getMessage()
      );
      return false;
    }
  }

  public static Boolean evaluate(String expression) {
    return OnboardingExpressionEngine.evaluate(expression);
  }

  public static Boolean evaluate(
    String expression,
    Map<String, Object> context
  ) {
    return OnboardingExpressionEngine.evaluate(expression, context);
  }
}
