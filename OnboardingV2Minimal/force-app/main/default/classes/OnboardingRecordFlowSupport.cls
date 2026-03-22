/**
 * Shared helpers for Onboarding RCD: broad SOQL for records passed into nested autolaunched flows,
 * safe Flow.Interview execution, and (via @InvocableMethod) fault-isolated dispatch so requirement /
 * status DML is not rolled back when communication subflows fault.
 */
public with sharing class OnboardingRecordFlowSupport {
  private static final String FLOW_DISPATCH_COMMUNICATION_BY_EVENT = 'BLL_Onboarding_SFL_Dispatch_Communication_By_Event';

  public class DispatchByEventRequest {
    @InvocableVariable(label='Event Key' description='e.g. SetupComplete, LearnUponTriggered')
    public String eventKey;

    @InvocableVariable(label='Onboarding Id')
    public Id onboardingId;

    @InvocableVariable(
      label='Vendor Program Id'
      description='Vendor_Customization__c Id from the Onboarding record (may be null).'
    )
    public Id vendorProgramId;
  }

  public class DispatchByEventResult {
    @InvocableVariable(label='Ran Successfully')
    public Boolean ranSuccessfully;

    @InvocableVariable(label='Diagnostic Message')
    public String diagnosticMessage;
  }
  /** Result of runAutolaunchedFlow; read outputs via getVariableValue only when succeeded is true. */
  public class InterviewRunResult {
    public Boolean succeeded { get; private set; }
    public String errorMessage { get; private set; }
    private Flow.Interview interview;

    private InterviewRunResult(Boolean ok, String err, Flow.Interview iv) {
      succeeded = ok;
      errorMessage = err;
      interview = iv;
    }

    public Object getVariableValue(String variableName) {
      if (!succeeded || interview == null || String.isBlank(variableName)) {
        return null;
      }
      return interview.getVariableValue(variableName);
    }
  }

  public static Onboarding__c loadOnboardingForFlow(Id onboardingId) {
    if (onboardingId == null) {
      return null;
    }
    String cols = commaSeparatedQueryableFields(Onboarding__c.SObjectType);
    return (Onboarding__c) Database.query(
      'SELECT ' + cols + ' FROM Onboarding__c WHERE Id = :onboardingId LIMIT 1'
    );
  }

  public static Vendor_Customization__c loadVendorProgramForFlow(Id vendorProgramId) {
    if (vendorProgramId == null) {
      return null;
    }
    String cols = commaSeparatedQueryableFields(Vendor_Customization__c.SObjectType);
    return (Vendor_Customization__c) Database.query(
      'SELECT ' +
        cols +
        ' FROM Vendor_Customization__c WHERE Id = :vendorProgramId LIMIT 1'
    );
  }

  /** Starts an autolaunched flow by API name; never throws (failures set InterviewRunResult.succeeded to false). */
  public static InterviewRunResult runAutolaunchedFlow(
    String flowApiName,
    Map<String, Object> inputVariables
  ) {
    if (String.isBlank(flowApiName)) {
      return new InterviewRunResult(false, 'flowApiName is required.', null);
    }
    Map<String, Object> inputs = inputVariables == null ? new Map<String, Object>() : inputVariables;
    try {
      Flow.Interview iv = Flow.Interview.createInterview(flowApiName.trim(), inputs);
      iv.start();
      return new InterviewRunResult(true, null, iv);
    } catch (Exception ex) {
      return new InterviewRunResult(false, ex.getMessage(), null);
    }
  }

  @InvocableMethod(
    label='Onboarding RCD — Dispatch Communication By Event (safe)'
    description='Runs BLL_Onboarding_SFL_Dispatch_Communication_By_Event inside a non-throwing wrapper so Onboarding saves still commit.'
  )
  public static List<DispatchByEventResult> dispatchCommunicationByEvent(
    List<DispatchByEventRequest> requests
  ) {
    List<DispatchByEventResult> results = new List<DispatchByEventResult>();
    if (requests == null || requests.isEmpty()) {
      return results;
    }
    for (DispatchByEventRequest req : requests) {
      results.add(dispatchCommunicationByEventOne(req));
    }
    return results;
  }

  private static DispatchByEventResult dispatchCommunicationByEventOne(DispatchByEventRequest req) {
    DispatchByEventResult res = new DispatchByEventResult();
    res.ranSuccessfully = false;
    if (req == null || String.isBlank(req.eventKey) || req.onboardingId == null) {
      res.diagnosticMessage = 'eventKey and onboardingId are required.';
      return res;
    }

    Onboarding__c onboarding = loadOnboardingForFlow(req.onboardingId);
    Vendor_Customization__c vendorProgram = loadVendorProgramForFlow(req.vendorProgramId);
    Map<String, Object> inputs = new Map<String, Object>{
      'EventKey' => req.eventKey.trim(),
      'OnboardingRecord' => onboarding,
      'VendorProgramRecord' => vendorProgram
    };

    InterviewRunResult run = runAutolaunchedFlow(FLOW_DISPATCH_COMMUNICATION_BY_EVENT, inputs);
    if (run.succeeded) {
      res.ranSuccessfully = true;
    } else {
      res.diagnosticMessage = run.errorMessage;
      LoggingUtil.warn(
        'OnboardingRecordFlowSupport.dispatchCommunicationByEvent failed for EventKey=' +
          String.valueOf(req.eventKey) +
          ' Onboarding=' +
          String.valueOf(req.onboardingId) +
          ': ' +
          String.valueOf(run.errorMessage)
      );
    }
    return res;
  }

  private static String commaSeparatedQueryableFields(Schema.SObjectType typeToken) {
    List<String> parts = new List<String>();
    for (Schema.SObjectField f : typeToken.getDescribe().fields.getMap().values()) {
      Schema.DescribeFieldResult fr = f.getDescribe();
      if (!fr.isAccessible()) {
        continue;
      }
      parts.add(fr.getName());
    }
    return String.join(parts, ',');
  }
}
