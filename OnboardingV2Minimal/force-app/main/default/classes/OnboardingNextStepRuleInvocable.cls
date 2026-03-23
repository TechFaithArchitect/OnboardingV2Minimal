/**
 * Invoked from BLL_Onboarding_RCD_Logical_Process after the Setup Complete BRE gate (dispatch allowed or blocked)
 * to apply Onboarding_Next_Step_Rule__mdt (e.g. Auto Create sibling onboarding for another vendor program).
 */
public with sharing class OnboardingNextStepRuleInvocable {
  public class Request {
    @InvocableVariable(label='Onboarding Id' description='Onboarding__c record that reached Setup Complete')
    public Id onboardingId;
  }

  public class Result {
    @InvocableVariable(label='Error Message' description='Blank when processing finished without throwing.')
    public String errorMessage;
    @InvocableVariable(
      label='Warning Message'
      description='When rules matched but a linked onboarding/contract was skipped (e.g. no primary Opportunity Contact Role or Account Principal Owner).'
    )
    public String warningMessage;
  }

  @InvocableMethod(
    label='Apply Onboarding Next Step Rules (after Setup Complete)'
    description='Runs Onboarding_Next_Step_Rule__mdt for this onboarding. Swallows faults so the RCD flow can finish.'
  )
  public static List<Result> applyAfterSetupComplete(List<Request> requests) {
    List<Result> out = new List<Result>();
    if (requests == null || requests.isEmpty()) {
      return out;
    }
    for (Request req : requests) {
      Result r = new Result();
      if (req == null || req.onboardingId == null) {
        r.errorMessage = '';
        r.warningMessage = '';
        out.add(r);
        continue;
      }
      OnboardingNextStepRuleService.ApplyOutcome outcome = OnboardingNextStepRuleService.applyAfterSetupCompleteSwallowingFaultsWithOutcome(
        req.onboardingId
      );
      r.errorMessage = outcome.errorMessage == null ? '' : outcome.errorMessage;
      r.warningMessage = outcome.warningMessage == null ? '' : outcome.warningMessage;
      out.add(r);
    }
    return out;
  }
}
