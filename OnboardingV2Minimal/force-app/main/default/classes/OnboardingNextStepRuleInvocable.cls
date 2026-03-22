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
        out.add(r);
        continue;
      }
      r.errorMessage = OnboardingNextStepRuleService.applyAfterSetupCompleteSwallowingFaults(req.onboardingId);
      out.add(r);
    }
    return out;
  }
}
