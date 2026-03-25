/**
 * Flow-callable checkpoints for EXP_Opportunity_SCR_Create_Record performance profiling.
 */
public with sharing class OnboardingFlowSegmentTelemetryInvocable {
    @InvocableMethod(label='Onboarding - log flow segment')
    public static List<OnboardingFlowSegmentTelemetryResponse> logSegment(
        List<OnboardingFlowSegmentTelemetryRequest> requests
    ) {
        List<OnboardingFlowSegmentTelemetryResponse> out = new List<OnboardingFlowSegmentTelemetryResponse>();
        OnboardingFlowSegmentTelemetryResponse summary = new OnboardingFlowSegmentTelemetryResponse();
        summary.logged = false;
        if (requests == null || requests.isEmpty()) {
            out.add(summary);
            return out;
        }
        OnboardingFlowSegmentTelemetryRequest row = requests[0];
        if (row == null) {
            out.add(summary);
            return out;
        }
        if (!OnboardingPerformanceSettings.isFlowSegmentTelemetryEnabled()) {
            out.add(summary);
            return out;
        }
        try {
            OnboardingFlowPerformanceTracer.log(row.interviewGuid, row.segmentKey, row.contextRecordId);
            summary.logged = true;
        } catch (Exception ex) {
            System.debug(
                LoggingLevel.WARN,
                'OnboardingFlowSegmentTelemetryInvocable: telemetry skipped. ' + ex.getMessage()
            );
            summary.logged = false;
        }
        out.add(summary);
        return out;
    }
}