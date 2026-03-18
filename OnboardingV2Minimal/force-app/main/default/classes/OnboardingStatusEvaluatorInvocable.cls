/**
 * Invocable action to evaluate and optionally apply Onboarding Status based on CMDT rules.
 * Called from BLL_Onboarding_Requirement_RCD_Logical_Process when requirement status changes.
 */
public with sharing class OnboardingStatusEvaluatorInvocable {
  public class EvaluateRequest {
    @InvocableVariable(required=true label='Onboarding Record Id' description='Id of the Onboarding__c record to evaluate')
    public Id onboardingId;

    @InvocableVariable(label='Apply Updates' description='If true, updates Onboarding and Opportunity. If false, returns target status only.')
    public Boolean applyUpdates;
  }

  public class EvaluateResult {
    @InvocableVariable(label='Target Onboarding Status')
    public String targetOnboardingStatus;

    @InvocableVariable(label='Target Opportunity Stage')
    public String targetOpportunityStage;

    @InvocableVariable(label='Should Update')
    public Boolean shouldUpdate;

    @InvocableVariable(label='Error Message')
    public String errorMessage;
  }

  @InvocableMethod(
    label='Evaluate Onboarding Status'
    description='Evaluates Onboarding Status from requirement statuses using Onboarding_Status_Evaluation_Rule__mdt. Optionally applies updates to Onboarding and Opportunity.'
  )
  public static List<EvaluateResult> evaluate(List<EvaluateRequest> requests) {
    List<EvaluateResult> results = new List<EvaluateResult>();
    if (requests == null || requests.isEmpty()) {
      results.add(new EvaluateResult());
      return results;
    }

    EvaluateRequest req = requests[0];
    EvaluateResult res = new EvaluateResult();

    if (req.onboardingId == null) {
      res.errorMessage = 'Onboarding Record Id is required.';
      results.add(res);
      return results;
    }

    try {
      OnboardingStatusEvaluatorService.EvaluationResult eval;
      if (req.applyUpdates == true) {
        eval = OnboardingStatusEvaluatorService.evaluateAndApply(req.onboardingId);
      } else {
        eval = OnboardingStatusEvaluatorService.evaluate(req.onboardingId);
      }

      res.targetOnboardingStatus = eval.targetOnboardingStatus;
      res.targetOpportunityStage = eval.targetOpportunityStage;
      res.shouldUpdate = eval.shouldUpdate;
    } catch (Exception ex) {
      res.errorMessage = 'Evaluation failed: ' + ex.getMessage();
      LoggingUtil.error(
        'OnboardingStatusEvaluatorInvocable.evaluate failed: ' +
        ex.getStackTraceString()
      );
    }

    results.add(res);
    return results;
  }
}
