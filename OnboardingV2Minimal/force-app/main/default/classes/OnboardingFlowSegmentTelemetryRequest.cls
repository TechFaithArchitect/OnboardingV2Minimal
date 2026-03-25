public class OnboardingFlowSegmentTelemetryRequest {
    @InvocableVariable(label='Segment Key')
    public String segmentKey;

    @InvocableVariable(label='Interview GUID')
    public String interviewGuid;

    @InvocableVariable(label='Context Record Id')
    public String contextRecordId;
}