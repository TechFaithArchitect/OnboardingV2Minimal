OnboardingStatusEvaluatorService.EvaluationResult r = OnboardingStatusEvaluatorService.evaluate(
  Id.valueOf('aD1RL000001Od7h0AC')
);
System.debug(
  LoggingLevel.ERROR,
  'OnboardingStatusEvaluator DEBUG target=' +
    r.targetOnboardingStatus +
    ' shouldUpdate=' +
    r.shouldUpdate +
    ' matchedRule=' +
    r.matchedRuleDeveloperName +
    ' order=' +
    r.matchedRuleOrder
);
