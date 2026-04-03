/**
 * Cached access to Onboarding_Performance_Config__mdt (Default record).
 */
public with sharing class OnboardingPerformanceSettings {
    private static final String DEFAULT_ROW = 'Default';

    /** Primitive: `if (loaded)` on null Boolean throws NPE in Apex. */
    private static boolean loaded = false;
    private static Boolean deferOnboardingTail;
    private static Boolean publishChainProgressEvents;

    /**
     * Primitive boolean so callers can safely use ! without NPE ( ! on null Boolean throws ).
     */
    public static boolean isDeferOnboardingTailEnabled() {
        ensureLoaded();
        return deferOnboardingTail == true;
    }

    public static boolean isPublishChainProgressEventsEnabled() {
        ensureLoaded();
        return publishChainProgressEvents == true;
    }

    @TestVisible
    static void resetCacheForTest() {
        loaded = false;
        deferOnboardingTail = false;
        publishChainProgressEvents = true;
    }

    @TestVisible
    static void setTestValues(
        Boolean deferTail,
        Boolean publishEvents
    ) {
        loaded = true;
        deferOnboardingTail = deferTail == null ? false : deferTail;
        publishChainProgressEvents = publishEvents == null ? true : publishEvents;
    }

    private static void ensureLoaded() {
        if (loaded) {
            return;
        }
        deferOnboardingTail = false;
        publishChainProgressEvents = true;
        try {
            if (!Schema.sObjectType.Onboarding_Performance_Config__mdt.isAccessible()) {
                loaded = true;
                return;
            }
            List<Onboarding_Performance_Config__mdt> rows = [
                SELECT
                    Defer_Onboarding_Tail__c,
                    Publish_Chain_Progress_Events__c
                FROM Onboarding_Performance_Config__mdt
                WHERE DeveloperName = :DEFAULT_ROW
                LIMIT 1
            ];
            if (!rows.isEmpty()) {
                Onboarding_Performance_Config__mdt row = rows[0];
                if (row.Defer_Onboarding_Tail__c != null) {
                    deferOnboardingTail = row.Defer_Onboarding_Tail__c;
                }
                if (row.Publish_Chain_Progress_Events__c != null) {
                    publishChainProgressEvents = row.Publish_Chain_Progress_Events__c;
                }
            }
        } catch (Exception ex) {
            System.debug(
                LoggingLevel.WARN,
                '[Onboarding] OnboardingPerformanceSettings: ' + ex.getMessage()
            );
        }
        loaded = true;
    }
}
