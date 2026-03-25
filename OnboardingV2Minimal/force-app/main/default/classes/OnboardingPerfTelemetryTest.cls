@IsTest
private class OnboardingPerfTelemetryTest {
    @IsTest
    static void routing_invocable_returns_defer_when_config_test_override() {
        OnboardingPerformanceSettings.resetCacheForTest();
        OnboardingPerformanceSettings.setTestValues(true, true, false);
        List<OnboardingPerformanceRoutingResponse> rows = OnboardingPerformanceRoutingInvocable.getRouting(
            new List<OnboardingPerformanceRoutingRequest>{ new OnboardingPerformanceRoutingRequest() }
        );
        System.assertEquals(1, rows.size(), 'one routing row');
        System.assertEquals(true, rows[0].deferOnboardingTail, 'defer tail');
        OnboardingPerformanceSettings.resetCacheForTest();
    }

    @IsTest
    static void telemetry_first_segment_no_null_pointer_on_delta() {
        OnboardingPerformanceSettings.resetCacheForTest();
        OnboardingPerformanceSettings.setTestValues(false, true, false);
        OnboardingFlowPerformanceTracer.clearForTest();
        OnboardingFlowSegmentTelemetryRequest req = new OnboardingFlowSegmentTelemetryRequest();
        req.segmentKey = 'AfterVendorApex';
        req.interviewGuid = 'interview-1';
        req.contextRecordId = '001xxxxxxxxxxxxxxx';
        List<OnboardingFlowSegmentTelemetryResponse> res = OnboardingFlowSegmentTelemetryInvocable.logSegment(
            new List<OnboardingFlowSegmentTelemetryRequest>{ req }
        );
        System.assertEquals(true, res[0].logged, 'first checkpoint should log without NPE');
        OnboardingPerformanceSettings.resetCacheForTest();
    }

    @IsTest
    static void telemetry_skips_when_disabled() {
        OnboardingPerformanceSettings.resetCacheForTest();
        OnboardingPerformanceSettings.setTestValues(false, false, false);
        OnboardingFlowPerformanceTracer.clearForTest();
        OnboardingFlowSegmentTelemetryRequest req = new OnboardingFlowSegmentTelemetryRequest();
        req.segmentKey = OnboardingOpportunityCreateSyncBoundary.TELEMETRY_AFTER_VENDOR_APEX;
        req.interviewGuid = 'test-guid';
        req.contextRecordId = null;
        List<OnboardingFlowSegmentTelemetryResponse> res = OnboardingFlowSegmentTelemetryInvocable.logSegment(
            new List<OnboardingFlowSegmentTelemetryRequest>{ req }
        );
        System.assertEquals(false, res[0].logged, 'no log when disabled');
        OnboardingPerformanceSettings.resetCacheForTest();
    }

    @IsTest
    static void enqueue_invocable_errors_on_blank_required_ids() {
        OnboardingEnqueueOnboardingTailRequest bad = new OnboardingEnqueueOnboardingTailRequest();
        bad.contractId = '';
        bad.opportunityId = '';
        bad.accountId = '';
        List<OnboardingEnqueueOnboardingTailResponse> out = OnboardingEnqueueOnboardingTailInvocable.enqueue(
            new List<OnboardingEnqueueOnboardingTailRequest>{ bad }
        );
        System.assertEquals(false, out[0].jobEnqueued);
        System.assert(!String.isBlank(out[0].errorMessage), 'error message');
    }
}