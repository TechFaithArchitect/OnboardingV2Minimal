/**
 * Service for applying/removing external overrides on Onboarding__c.
 */
public with sharing class OnboardingExternalOverrideService {

    public class OverrideRequest {
        @AuraEnabled public Id onboardingId;
        @AuraEnabled public String reason;
        @AuraEnabled public List<String> allowedPrograms;
        @AuraEnabled public String sourceSystem;
        @AuraEnabled public String requestId;
        @AuraEnabled public Boolean resetRequirements;
    }

    public class OverrideResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id onboardingId;
        @AuraEnabled public String previousStatus;
        @AuraEnabled public String newStatus;
    }

    public static OverrideResponse applyOverride(OverrideRequest request) {
        OverrideResponse resp = new OverrideResponse();
        if (request == null || request.onboardingId == null) {
            resp.success = false;
            resp.message = 'onboardingId is required';
            return resp;
        }

        Onboarding__c onboardingRecord = [
            SELECT Id, Onboarding_Status__c, External_Override_Enabled__c,
                   External_Override_Programs__c
            FROM Onboarding__c
            WHERE Id = :request.onboardingId
            LIMIT 1
        ];

        String prevStatus = onboardingRecord.Onboarding_Status__c;
        onboardingRecord.External_Override_Enabled__c = true;
        onboardingRecord.External_Override_Reason__c = request.reason;
        onboardingRecord.External_Override_Date__c = Datetime.now();
        onboardingRecord.External_Override_Source__c = request.sourceSystem;
        onboardingRecord.External_Override_Programs__c = request.allowedPrograms != null ? String.join(request.allowedPrograms, ',') : null;
        onboardingRecord.Previous_Status_Before_Override__c = prevStatus;
        onboardingRecord.External_Override_Request_ID__c = request.requestId;
        update onboardingRecord;

        // Audit log
        OnboardingOverrideAuditService.AuditEntry entry = new OnboardingOverrideAuditService.AuditEntry();
        entry.onboardingId = onboardingRecord.Id;
        entry.action = 'Applied';
        entry.sourceSystem = request.sourceSystem;
        entry.requestId = request.requestId;
        entry.reason = request.reason;
        entry.allowedPrograms = onboardingRecord.External_Override_Programs__c;
        entry.previousStatus = prevStatus;
        entry.newStatus = onboardingRecord.Onboarding_Status__c;
        entry.requestedBy = UserInfo.getName();
        entry.processedBy = UserInfo.getUserId();
        entry.processedDate = Datetime.now();
        OnboardingOverrideAuditService.log(entry);

        resp.success = true;
        resp.message = 'Override applied';
        resp.onboardingId = onboardingRecord.Id;
        resp.previousStatus = prevStatus;
        resp.newStatus = onboardingRecord.Onboarding_Status__c;
        return resp;
    }

    public static OverrideResponse removeOverride(Id onboardingId, String reason) {
        OverrideResponse resp = new OverrideResponse();
        if (onboardingId == null) {
            resp.success = false;
            resp.message = 'onboardingId is required';
            return resp;
        }
        Onboarding__c onboardingRecord = [
            SELECT Id, Onboarding_Status__c, External_Override_Enabled__c,
                   Previous_Status_Before_Override__c
            FROM Onboarding__c
            WHERE Id = :onboardingId
            LIMIT 1
        ];

        String prevStatus = onboardingRecord.Onboarding_Status__c;
        onboardingRecord.External_Override_Enabled__c = false;
        onboardingRecord.External_Override_Reason__c = reason;
        onboardingRecord.External_Override_Date__c = Datetime.now();
        onboardingRecord.External_Override_Source__c = null;
        onboardingRecord.External_Override_Programs__c = null;
        onboardingRecord.External_Override_Request_ID__c = null;
        onboardingRecord.Onboarding_Status__c = onboardingRecord.Previous_Status_Before_Override__c;
        update onboardingRecord;

        // Audit log
        OnboardingOverrideAuditService.AuditEntry entry = new OnboardingOverrideAuditService.AuditEntry();
        entry.onboardingId = onboardingRecord.Id;
        entry.action = 'Removed';
        entry.sourceSystem = null;
        entry.requestId = null;
        entry.reason = reason;
        entry.allowedPrograms = null;
        entry.previousStatus = prevStatus;
        entry.newStatus = onboardingRecord.Onboarding_Status__c;
        entry.requestedBy = UserInfo.getName();
        entry.processedBy = UserInfo.getUserId();
        entry.processedDate = Datetime.now();
        OnboardingOverrideAuditService.log(entry);

        resp.success = true;
        resp.message = 'Override removed';
        resp.onboardingId = onboardingRecord.Id;
        resp.previousStatus = prevStatus;
        resp.newStatus = onboardingRecord.Onboarding_Status__c;
        return resp;
    }

    public static Boolean isProgramAllowed(Id onboardingId, String programName) {
        if (onboardingId == null || String.isBlank(programName)) {
            return false;
        }
        List<Onboarding__c> onboardingRecords = [
            SELECT External_Override_Enabled__c, External_Override_Programs__c
            FROM Onboarding__c
            WHERE Id = :onboardingId
            LIMIT 1
        ];
        if (onboardingRecords.isEmpty()) {
            return false;
        }
        Onboarding__c onboardingRecord = onboardingRecords[0];
        if (onboardingRecord.External_Override_Enabled__c != true) {
            return true; // no override restriction
        }
        if (String.isBlank(onboardingRecord.External_Override_Programs__c)) {
            return true; // override enabled but no restriction specified
        }
        Set<String> allowed = new Set<String>();
        for (String programNameInList : onboardingRecord.External_Override_Programs__c.split(',')) {
            if (!String.isBlank(programNameInList)) {
                allowed.add(programNameInList.trim().toLowerCase());
            }
        }
        return allowed.isEmpty() ? true : allowed.contains(programName.toLowerCase());
    }
}