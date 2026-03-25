/**
 * Documents the synchronous boundary for EXP_Opportunity_SCR_Create_Record and related DOMAIN automation.
 *
 * SYNC_BEFORE_MAIN_SCREEN — Account load (DOMAIN GET Account), onboarding presence lookups, Program Opportunity
 * record type, BRE (Evaluate_OnboardingOrchestrator), Vendor JSON Apex (VendorOnboardingJsonAdapter), main screen displayed.
 *
 * SYNC_MAIN_SCREEN — Single interview screen (Create_Opportunity_Screenflow): verification, addresses, program paths,
 * dependent picklists, vendor selector LWCs.
 *
 * SYNC_AFTER_MAIN_SCREEN — Program/branch assignments, optional default vendor program Apex, Get Vendor Program subflow,
 * Account update DML, EXP contact subflow (PerformDmlAsynchronously=false today builds JSON / relationships),
 * Create Opportunity (DOMAIN), opportunity contacts + OCR roles, primary OCR resolution, Contract create (DOMAIN).
 *
 * SYNC_ONBOARDING_TAIL — DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record (training/LearnUpon/agreements as designed).
 * This phase may be deferred to Queueable when Onboarding_Performance_Config__mdt.Defer_Onboarding_Tail__c is true.
 *
 * DEFERRABLE_BY_PRODUCT — Anything that does not change the user's ability to land on Account/Opportunity/Contract with
 * a consistent core graph: bulk requirement rows, external enrollments, non-blocking junctions, follow-up queue rows,
 * subject copies, provided ordering / idempotency are preserved in async implementations.
 *
 * Segment keys below align with OnboardingFlowSegmentTelemetryInvocable checkpoints wired into the screen flow.
 */
public with sharing class OnboardingOpportunityCreateSyncBoundary {
    /** Matches EXP_Opportunity_SCR_Create_Record checkpoint after VendorOnboardingJsonAdapter */
    public static final String TELEMETRY_AFTER_VENDOR_APEX = 'AfterVendorApex';
    /** After Create_Opportunity_Screenflow */
    public static final String TELEMETRY_AFTER_MAIN_SCREEN = 'AfterMainScreen';
    /** After EXP_Contact_SCR_Create_Contact, before DOMAIN opportunity create */
    public static final String TELEMETRY_BEFORE_CREATE_OPPORTUNITY = 'BeforeCreateOpportunity';
    /** After DOMAIN opportunity create + validation decision */
    public static final String TELEMETRY_AFTER_CREATE_OPPORTUNITY = 'AfterCreateOpportunity';
    /** Before DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record (inline path) */
    public static final String TELEMETRY_BEFORE_CREATE_ONBOARDING = 'BeforeCreateOnboarding';
}