/**
 * Flow entry: inserts Error_Log__c with Type/Provider_Subtype categorization and returns user-facing text + log Id.
 */
public with sharing class OnboardingErrorLogInvocable {
    public class LogRequest {
        @InvocableVariable(label='Technical Detail' description='Full admin diagnostic payload.')
        public String technicalDetail;

        @InvocableVariable(label='User Message Base' description='Resolved friendly text before log Id suffix.')
        public String userMessageBase;

        @InvocableVariable(label='Onboarding Id' description='15-18 char Onboarding__c Id when known.')
        public String onboardingId;

        @InvocableVariable(label='Opportunity Id' description='Opportunity Id when known.')
        public String opportunityId;

        @InvocableVariable(label='Source Flow API Name')
        public String sourceFlowApiName;

        @InvocableVariable(label='Source Element API Name')
        public String sourceElementApiName;

        @InvocableVariable(label='Context Key')
        public String contextKey;

        @InvocableVariable(label='Interview Guid')
        public String interviewGuid;

        @InvocableVariable(
            label='Error Log Type'
            description='Flow, Screen Flow, Apex, Integration, or Internal Error; blank derives Flow vs Screen Flow from API name.'
        )
        public String errorLogType;

        @InvocableVariable(label='Provider Subtype Override' description='When blank, derived from flow API name.')
        public String providerSubtypeOverrideText;

        @InvocableVariable(label='Tab Context' description='Optional execution hint (e.g. Async, Sync).')
        public String tabContext;
    }

    public class LogResult {
        @InvocableVariable(label='Error Log Id')
        public String errorLogId;

        @InvocableVariable(label='User Facing Message')
        public String userFacingMessage;

        @InvocableVariable(label='Insert Succeeded')
        public Boolean insertSucceeded;
    }

    @InvocableMethod(
        label='Log Onboarding Automation Fault'
        description='Inserts a categorized Chuzo Error Log row and returns support-friendly user text with the log Id.'
    )
    public static List<LogResult> logFault(List<LogRequest> requests) {
        List<LogResult> results = new List<LogResult>();
        if (requests == null) {
            return results;
        }

        for (LogRequest req : requests) {
            LogResult res = new LogResult();
            res.insertSucceeded = false;
            if (req == null) {
                res.userFacingMessage = 'The communication request could not be completed.';
                results.add(res);
                continue;
            }

            OnboardingErrorLogService.FaultInput input = new OnboardingErrorLogService.FaultInput();
            input.technicalDetail = req.technicalDetail;
            input.userMessageBase = req.userMessageBase;
            input.onboardingIdText = req.onboardingId;
            input.opportunityIdText = req.opportunityId;
            input.sourceFlowApiName = req.sourceFlowApiName;
            input.sourceElementApiName = req.sourceElementApiName;
            input.contextKey = req.contextKey;
            input.interviewGuid = req.interviewGuid;
            input.errorLogType = req.errorLogType;
            input.providerSubtypeOverrideText = req.providerSubtypeOverrideText;
            input.tabContext = req.tabContext;

            OnboardingErrorLogService.FaultOutcome outcome = OnboardingErrorLogService.persistFault(input);
            res.errorLogId = outcome.errorLogId == null ? null : String.valueOf(outcome.errorLogId);
            res.userFacingMessage = outcome.userFacingMessage;
            res.insertSucceeded = outcome.insertSucceeded == true;
            results.add(res);
        }
        return results;
    }
}
