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
        matchesExpected = (matchedReq.Status__c == cond.Expected_Status__c);
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
