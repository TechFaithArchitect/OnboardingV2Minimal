/**
 * CMDT-driven rule engine: Predicate_Config__c JSON via OnboardingStatusPredicateInterpreter.
 */
public with sharing class OnboardingStatusCmdtRuleEngine implements IOnboardingStatusRuleEngine {
  public Boolean ruleApplies(
    Onboarding_Status_Evaluation_Rule__mdt rule,
    OnboardingStatusEvaluatorService.EvaluationContext context
  ) {
    return OnboardingStatusPredicateInterpreter.ruleMatchesRule(rule, context);
  }
}
