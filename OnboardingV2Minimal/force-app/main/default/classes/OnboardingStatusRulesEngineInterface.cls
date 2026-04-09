/**
 * Pluggable rule engine for onboarding status evaluation (first matching CMDT row wins).
 * Default implementation: OnboardingStatusCmdtRuleEngine (JSON Predicate_Config__c).
 */
public interface OnboardingStatusRulesEngineInterface {
  Boolean ruleApplies(
    Onboarding_Status_Evaluation_Rule__mdt rule,
    OnboardingStatusEvaluatorService.EvaluationContext context
  );
}
