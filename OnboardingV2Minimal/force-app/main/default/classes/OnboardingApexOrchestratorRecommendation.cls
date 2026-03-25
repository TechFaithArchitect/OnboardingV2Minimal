/**
 * Evaluation (implementation backlog): consolidating DOMAIN_OmniSObject_SFL_CREATE_* screen-flow subflows.
 *
 * Recommendation — Phased approach:
 * 1. Keep Flow for human screens and declarative branching; measure with OnboardingFlowSegmentTelemetryInvocable.
 * 2. Extract the post-screen DML chain into one bulk-safe Invocable (or two: core graph + async enrichment) when:
 *    (a) debug logs show Flow element overhead or small DML batches dominate, or
 *    (b) governor limits require single-transaction bulkification not expressible in Flow.
 * 3. Prefer a narrow Apex façade that calls existing service classes over re-implementing business rules; keep DOMAIN
 *    flows as reference until parity tests pass.
 * 4. Where ordering is fixed (Opportunity → OCR → Contract → Onboarding), a single orchestrator reduces round-trips;
 *    retain Platform Events / Queueable for tails that are explicitly eventual (see OnboardingChainTailQueueable).
 *
 * Anti-pattern — Rewriting the entire onboarding graph in Apex without tests: risk of subtle rule drift versus BRE output.
 */
public with sharing class OnboardingApexOrchestratorRecommendation {
}