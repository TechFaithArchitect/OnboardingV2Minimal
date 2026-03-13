public with sharing class OnboardingFollowUpInvocables {
  @TestVisible
  private static Boolean forceFailureForTests = false;

  public class FollowUpEvaluationRequest {
    @InvocableVariable(required=true label='Onboarding Requirement Id')
    public Id onboardingRequirementId;
  }

  public class FollowUpEvaluationResult {
    @InvocableVariable(label='Onboarding Requirement Id')
    public Id onboardingRequirementId;

    @InvocableVariable(label='Requested')
    public Boolean requested;

    @InvocableVariable(label='Error Message')
    public String errorMessage;
  }

  @InvocableMethod(
    label='Evaluate Follow-Ups (Typed)'
    description='Evaluates follow-up rules for onboarding requirements.'
  )
  public static List<FollowUpEvaluationResult> evaluateFollowUps(
    List<FollowUpEvaluationRequest> requests
  ) {
    List<FollowUpEvaluationResult> results = new List<FollowUpEvaluationResult>();
    if (requests == null || requests.isEmpty()) {
      return results;
    }

    Set<Id> requirementIds = new Set<Id>();
    for (FollowUpEvaluationRequest requestItem : requests) {
      FollowUpEvaluationResult resultItem = new FollowUpEvaluationResult();
      resultItem.onboardingRequirementId = requestItem == null
        ? null
        : requestItem.onboardingRequirementId;
      resultItem.requested = false;

      if (requestItem == null || requestItem.onboardingRequirementId == null) {
        resultItem.errorMessage = 'Onboarding Requirement Id is required.';
        results.add(resultItem);
        continue;
      }

      requirementIds.add(requestItem.onboardingRequirementId);
      resultItem.requested = true;
      results.add(resultItem);
    }

    if (requirementIds.isEmpty()) {
      return results;
    }

    try {
      if (Test.isRunningTest() && forceFailureForTests) {
        throw new IllegalArgumentException('Forced test failure');
      }

      FollowUpDetectionService.evaluateAndCreateFollowUpsBulk(requirementIds);
    } catch (Exception ex) {
      LoggingUtil.error(
        'OnboardingFollowUpInvocables.evaluateFollowUps failed: ' +
        ex.getMessage()
      );
      for (FollowUpEvaluationResult resultItem : results) {
        if (resultItem.requested == true) {
          resultItem.requested = false;
          resultItem.errorMessage = 'Unable to evaluate follow-ups.';
        }
      }
    }

    return results;
  }
}
