/**
 * Transaction-scoped timing between Flow checkpoints (same interview GUID).
 * Emits INFO logs when segment telemetry is enabled; pair with Onboarding_Logging_Config__mdt Minimum_Level INFO or DEBUG.
 */
public with sharing class OnboardingFlowPerformanceTracer {
    private static final Map<String, Long> LAST_MS_BY_INTERVIEW = new Map<String, Long>();

    public static void log(String interviewGuid, String segmentKey, String contextRecordId) {
        if (!OnboardingPerformanceSettings.isFlowSegmentTelemetryEnabled()) {
            return;
        }
        String interview = String.isBlank(interviewGuid) ? 'UNKNOWN' : interviewGuid;
        String segment = String.isBlank(segmentKey) ? 'UNNAMED' : segmentKey;
        long now = System.currentTimeMillis();
        Long prev = LAST_MS_BY_INTERVIEW.get(interview);
        Long delta = prev == null ? null : (now - prev);
        LAST_MS_BY_INTERVIEW.put(interview, now);

        String ctx = contextRecordId == null ? '' : contextRecordId;
        String deltaStr = delta == null ? 'n/a' : String.valueOf(delta);
        LoggingUtil.info(
            'FLOW_PERF segment=' +
                segment +
                ' interview=' +
                interview +
                ' wallMs=' +
                now +
                ' deltaSincePrevMs=' +
                deltaStr +
                ' contextId=' +
                ctx
        );
    }

    @TestVisible
    static void clearForTest() {
        LAST_MS_BY_INTERVIEW.clear();
    }
}