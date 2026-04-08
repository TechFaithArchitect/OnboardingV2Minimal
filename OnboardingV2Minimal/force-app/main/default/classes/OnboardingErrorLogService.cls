/**
 * Persists categorized rows to Error_Log__c for onboarding automation diagnostics.
 */
public without sharing class OnboardingErrorLogService {
    public static final String PROVIDER_ONBOARDING_V2 = 'OnboardingV2';

    private static final Integer MAX_ERROR_CHARS = 131072;
    private static final Integer MAX_REQUEST_CHARS = 32768;

    public class FaultInput {
        public String technicalDetail;
        public String userMessageBase;
        public String onboardingIdText;
        public String opportunityIdText;
        public String sourceFlowApiName;
        public String sourceElementApiName;
        public String contextKey;
        public String interviewGuid;
        public String errorLogType;
        public String providerSubtypeOverrideText;
        public String tabContext;
    }

    public class FaultOutcome {
        public Id errorLogId;
        public String userFacingMessage;
        public Boolean insertSucceeded;
    }

    public static FaultOutcome persistFault(FaultInput input) {
        FaultOutcome outcome = new FaultOutcome();
        outcome.insertSucceeded = false;

        if (input == null) {
            input = new FaultInput();
        }

        String userBase = String.isBlank(input.userMessageBase)
            ? 'The communication request could not be completed.'
            : input.userMessageBase;

        String typeValue = resolveType(input.errorLogType, input.sourceFlowApiName);
        String subtype = resolveProviderSubtype(input.providerSubtypeOverrideText, input.sourceFlowApiName);

        Error_Log__c row = new Error_Log__c();
        row.Type__c = typeValue;
        row.Provider_Subtype__c = subtype;
        row.Provider__c = PROVIDER_ONBOARDING_V2;
        row.Component__c = truncate(trimmedOrNull(input.sourceFlowApiName), 255);
        row.Endpoint__c = truncate(trimmedOrNull(input.sourceElementApiName), 255);
        row.Tab__c = truncate(trimmedOrNull(input.tabContext), 255);
        row.Error__c = truncate(LoggingUtil.redactPii(coalesce(input.technicalDetail, '')), MAX_ERROR_CHARS);

        Id onboardingId = tryParseId(input.onboardingIdText);
        if (onboardingId != null) {
            row.Onboarding__c = onboardingId;
        }

        Id opportunityId = tryParseId(input.opportunityIdText);
        if (opportunityId != null) {
            row.Opportunity__c = opportunityId;
        }

        Database.SaveResult sr;
        try {
            // Fault logging must remain durable even when caller CRUD/FLS is narrower than
            // platform operations support staff; use explicit SYSTEM_MODE for log persistence.
            sr = Database.insert(row, false, AccessLevel.SYSTEM_MODE);
        } catch (Exception ex) {
            outcome.userFacingMessage = userBase + ' Reference: logging unavailable.';
            LoggingUtil.error('OnboardingErrorLogService.persistFault insert threw: ' + ex.getMessage());
            return outcome;
        }

        if (sr == null || !sr.isSuccess()) {
            String err = sr == null ? 'unknown' : summarizeErrors(sr.getErrors());
            outcome.userFacingMessage = userBase + ' Reference: logging unavailable.';
            LoggingUtil.error('OnboardingErrorLogService.persistFault DML failed: ' + err);
            return outcome;
        }

        outcome.errorLogId = sr.getId();
        outcome.insertSucceeded = true;

        String requestBody =
            userBase +
            '\nErrorLogId=' +
            outcome.errorLogId +
            '\nInterviewGuid=' +
            coalesce(trimmedOrNull(input.interviewGuid), 'NO_INTERVIEW_GUID') +
            '\nContext=' +
            coalesce(trimmedOrNull(input.contextKey), 'NO_CONTEXT');

        Error_Log__c requestPatch = new Error_Log__c(
            Id = outcome.errorLogId,
            Request__c = truncate(LoggingUtil.redactPii(requestBody), MAX_REQUEST_CHARS)
        );
        try {
            // Keep follow-up patch in SYSTEM_MODE for the same durability reason as insert.
            Database.update(requestPatch, false, AccessLevel.SYSTEM_MODE);
        } catch (Exception ex) {
            LoggingUtil.warn('OnboardingErrorLogService.persistFault request update failed: ' + ex.getMessage());
        }

        outcome.userFacingMessage =
            userBase + ' Error Log Id: ' + String.valueOf(outcome.errorLogId);
        return outcome;
    }

    private static String resolveType(String explicit, String flowApi) {
        if (!String.isBlank(explicit)) {
            return explicit.trim();
        }
        if (!String.isBlank(flowApi) && flowApi.containsIgnoreCase('_SCR_')) {
            return 'Screen Flow';
        }
        return 'Flow';
    }

    private static String resolveProviderSubtype(String subtypeOverride, String flowApi) {
        if (!String.isBlank(subtypeOverride)) {
            return subtypeOverride.trim();
        }
        if (String.isBlank(flowApi)) {
            return 'Onboarding Automation';
        }
        String f = flowApi.toLowerCase();
        if (f.contains('communication') || f.contains('dispatch') || f.contains('send_email') || f.contains('email_communication')) {
            return 'Communication Dispatch';
        }
        if (f.contains('requirement_subject')) {
            return 'Requirement Subjects';
        }
        if (f.contains('requirement')) {
            return 'Onboarding Requirements';
        }
        if (f.contains('_bre_') || f.contains('business_rule')) {
            return 'BRE';
        }
        if (f.contains('training')) {
            return 'Training Sync';
        }
        if (f.contains('agreement')) {
            return 'Agreement';
        }
        if (f.contains('exp_opportunity') || f.contains('_scr_')) {
            return 'Experience Create Record';
        }
        return 'Onboarding Automation';
    }

    private static Id tryParseId(String text) {
        if (String.isBlank(text)) {
            return null;
        }
        try {
            return Id.valueOf(text.trim());
        } catch (Exception ex) {
            return null;
        }
    }

    private static String trimmedOrNull(String value) {
        if (value == null) {
            return null;
        }
        String t = value.trim();
        return t.length() == 0 ? null : t;
    }

    private static String coalesce(String a, String b) {
        return String.isBlank(a) ? b : a;
    }

    private static String truncate(String value, Integer maxLen) {
        if (value == null || maxLen == null || maxLen <= 0) {
            return value;
        }
        if (value.length() <= maxLen) {
            return value;
        }
        return value.substring(0, maxLen);
    }

    private static String summarizeErrors(List<Database.Error> errors) {
        if (errors == null || errors.isEmpty()) {
            return 'unknown';
        }
        List<String> parts = new List<String>();
        for (Database.Error err : errors) {
            parts.add(err.getStatusCode() + ':' + err.getMessage());
        }
        return String.join(parts, '; ');
    }
}
