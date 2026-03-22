/**
 * Runs BLL_BRE_Evaluate_Business_Rules in a try/catch so failures do not roll back
 * the parent Onboarding save (record-triggered flow cannot attach fault paths to subflows).
 */
public with sharing class OnboardingRecordBREGateInvocable {
  public class Request {
    @InvocableVariable(label='Event Key' description='e.g. SetupComplete, LearnUponTriggered')
    public String eventKey;

    @InvocableVariable(
      label='Vendor Program Id'
      description='Vendor_Customization__c Id from the Onboarding record (may be null).'
    )
    public Id vendorProgramId;
  }

  public class Result {
    @InvocableVariable(label='Dispatch Allowed')
    public Boolean dispatchAllowed;

    @InvocableVariable(
      label='Diagnostic Message'
      description='Populated when the nested BRE flow throws; evaluation treats dispatch as not allowed.'
    )
    public String diagnosticMessage;
  }

  @InvocableMethod(
    label='Onboarding Record — Evaluate BRE Communication Gate (safe)'
    description='Invokes BLL_BRE_Evaluate_Business_Rules with CommunicationDispatch context; swallows faults so Onboarding DML can commit.'
  )
  public static List<Result> evaluate(List<Request> requests) {
    List<Result> results = new List<Result>();
    if (requests == null || requests.isEmpty()) {
      return results;
    }

    for (Request req : requests) {
      Result res = new Result();
      res.dispatchAllowed = false;
      if (req == null || String.isBlank(req.eventKey)) {
        res.diagnosticMessage = 'eventKey is required.';
        results.add(res);
        continue;
      }

      Vendor_Customization__c vendorProgram = OnboardingRecordFlowSupport.loadVendorProgramForFlow(
        req.vendorProgramId
      );
      Map<String, Object> inputs = new Map<String, Object>{
        'EventKey' => req.eventKey.trim(),
        'RuleContext' => 'CommunicationDispatch',
        'VendorProgramRecord' => vendorProgram
      };
      OnboardingRecordFlowSupport.InterviewRunResult run = OnboardingRecordFlowSupport.runAutolaunchedFlow(
        'BLL_BRE_Evaluate_Business_Rules',
        inputs
      );
      if (run.succeeded) {
        Object allowed = run.getVariableValue('DispatchAllowed');
        res.dispatchAllowed = allowed == true;
      } else {
        res.diagnosticMessage = run.errorMessage;
        LoggingUtil.warn(
          'OnboardingRecordBREGateInvocable.evaluate failed for EventKey=' +
            String.valueOf(req.eventKey) +
            ': ' +
            String.valueOf(run.errorMessage)
        );
      }
      results.add(res);
    }

    return results;
  }
}
