/**
 * Exposes Onboarding_Performance_Config__mdt flags to Flow (decisions and branching).
 */
public with sharing class OnboardingPerformanceRoutingInvocable {
    @InvocableMethod(label='Onboarding - get performance routing')
    public static List<OnboardingPerformanceRoutingResponse> getRouting(
        List<OnboardingPerformanceRoutingRequest> requests
    ) {
        OnboardingPerformanceRoutingResponse row = new OnboardingPerformanceRoutingResponse();
        row.deferOnboardingTail = OnboardingPerformanceSettings.isDeferOnboardingTailEnabled();
        return new List<OnboardingPerformanceRoutingResponse>{ row };
    }
}