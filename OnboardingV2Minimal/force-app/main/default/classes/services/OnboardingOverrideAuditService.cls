/**
 * Audit logger for external override operations on Onboarding__c.
 */
public with sharing class OnboardingOverrideAuditService {
    public class AuditEntry {
        public Id onboardingId;
        public String action; // Applied, Removed, Modified
        public String sourceSystem;
        public String requestId;
        public String reason;
        public String allowedPrograms;
        public String previousStatus;
        public String newStatus;
        public String requestedBy;
        public Id processedBy;
        public Datetime processedDate;
    }

    public static void log(AuditEntry entry) {
        if (entry == null || entry.onboardingId == null) {
            return;
        }
        Onboarding_External_Override_Log__c log = new Onboarding_External_Override_Log__c();
        log.Onboarding__c = entry.onboardingId;
        log.Override_Action__c = entry.action;
        log.Source_System__c = entry.sourceSystem;
        log.Request_ID__c = entry.requestId;
        log.Reason__c = entry.reason;
        log.Allowed_Programs__c = entry.allowedPrograms;
        log.Previous_Status__c = entry.previousStatus;
        log.New_Status__c = entry.newStatus;
        log.Requested_By__c = entry.requestedBy;
        log.Processed_By__c = entry.processedBy;
        log.Processed_Date__c = entry.processedDate != null ? entry.processedDate : Datetime.now();
        insert log;
    }
}