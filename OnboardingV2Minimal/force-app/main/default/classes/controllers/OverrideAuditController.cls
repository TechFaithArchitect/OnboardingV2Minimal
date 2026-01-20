/**
 * Controller to fetch override audit logs for admin dashboard.
 */
public with sharing class OverrideAuditController {
    @AuraEnabled(cacheable=true)
    public static List<OverrideLogDTO> getOverrideLogs(String dateRange) {
        List<OverrideLogDTO> logs = new List<OverrideLogDTO>();
        DateTime startDate = getStartDate(dateRange);

        List<Onboarding_External_Override_Log__c> overrideLogRecords = [
            SELECT Id, Name, Onboarding__c, Onboarding__r.Name,
                   Override_Action__c, Source_System__c, Request_ID__c,
                   Reason__c, Allowed_Programs__c, Previous_Status__c, New_Status__c,
                   Requested_By__c, Processed_By__c, Processed_By__r.Name, Processed_Date__c
            FROM Onboarding_External_Override_Log__c
            WHERE CreatedDate >= :startDate
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];

        for (Onboarding_External_Override_Log__c overrideLogRecord : overrideLogRecords) {
            OverrideLogDTO overrideLogDTO = new OverrideLogDTO();
            overrideLogDTO.id = overrideLogRecord.Id;
            overrideLogDTO.name = overrideLogRecord.Name;
            overrideLogDTO.onboardingName = overrideLogRecord.Onboarding__r != null ? overrideLogRecord.Onboarding__r.Name : null;
            overrideLogDTO.action = overrideLogRecord.Override_Action__c;
            overrideLogDTO.source = overrideLogRecord.Source_System__c;
            overrideLogDTO.requestId = overrideLogRecord.Request_ID__c;
            overrideLogDTO.reason = overrideLogRecord.Reason__c;
            overrideLogDTO.allowedPrograms = overrideLogRecord.Allowed_Programs__c;
            overrideLogDTO.previousStatus = overrideLogRecord.Previous_Status__c;
            overrideLogDTO.newStatus = overrideLogRecord.New_Status__c;
            overrideLogDTO.requestedBy = overrideLogRecord.Requested_By__c;
            overrideLogDTO.processedBy = overrideLogRecord.Processed_By__r != null ? overrideLogRecord.Processed_By__r.Name : null;
            overrideLogDTO.processedDate = overrideLogRecord.Processed_Date__c;
            logs.add(overrideLogDTO);
        }
        return logs;
    }

    private static DateTime getStartDate(String range) {
        if (range == 'LAST_7_DAYS') return DateTime.now().addDays(-7);
        if (range == 'LAST_30_DAYS') return DateTime.now().addDays(-30);
        if (range == 'LAST_90_DAYS') return DateTime.now().addDays(-90);
        return DateTime.now().addYears(-10);
    }

    public class OverrideLogDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String onboardingName;
        @AuraEnabled public String action;
        @AuraEnabled public String source;
        @AuraEnabled public String requestId;
        @AuraEnabled public String reason;
        @AuraEnabled public String allowedPrograms;
        @AuraEnabled public String previousStatus;
        @AuraEnabled public String newStatus;
        @AuraEnabled public String requestedBy;
        @AuraEnabled public String processedBy;
        @AuraEnabled public DateTime processedDate;
    }
}