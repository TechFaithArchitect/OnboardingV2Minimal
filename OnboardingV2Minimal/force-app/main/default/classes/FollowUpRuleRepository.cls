/**
 * Repository for follow-up metadata and related data access.
 * Centralizes SOQL used by fatigue suppression services.
 */
public with sharing class FollowUpRuleRepository {

    public static Follow_Up_Rule__mdt getRuleByDeveloperName(String developerName) {
        if (String.isBlank(developerName)) {
            return null;
        }
        List<Follow_Up_Rule__mdt> followUpRules = [
            SELECT Max_Attempts_Per_Window__c, Fatigue_Window_Days__c, Fatigue_Suppression_Enabled__c
            FROM Follow_Up_Rule__mdt
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];
        return followUpRules.isEmpty() ? null : followUpRules[0];
    }

    public static List<Follow_Up_Suppression__mdt> getActiveSuppressions() {
        return [
            SELECT Start_Date__c, End_Date__c, Reason__c, Suppression_Type__c, Timezone_Aware__c
            FROM Follow_Up_Suppression__mdt
            WHERE Active__c = true
        ];
    }

    public static Id getAccountIdForRequirement(Id onboardingRequirementId) {
        if (onboardingRequirementId == null) {
            return null;
        }
        try {
            Onboarding_Requirement__c onboardingRequirement = [
                SELECT Onboarding__r.Account__c
                FROM Onboarding_Requirement__c
                WHERE Id = :onboardingRequirementId
                LIMIT 1
            ];
            return onboardingRequirement.Onboarding__r.Account__c;
        } catch (Exception ex) {
            return null;
        }
    }

    public static List<Follow_Up_Queue__c> getRecentFollowUps(Id onboardingRequirementId, DateTime thresholdDateTime) {
        if (onboardingRequirementId == null || thresholdDateTime == null) {
            return new List<Follow_Up_Queue__c>();
        }
        return [
            SELECT Id, Attempt_Count__c, Last_Attempt_Date__c, Consecutive_Failures__c
            FROM Follow_Up_Queue__c
            WHERE Onboarding_Requirement__c = :onboardingRequirementId
              AND Last_Attempt_Date__c >= :thresholdDateTime
              AND Is_Archived__c = false
            ORDER BY Last_Attempt_Date__c DESC
            LIMIT 100
        ];
    }

    public static Follow_Up_Queue__c getFollowUpQueue(Id followUpQueueId) {
        if (followUpQueueId == null) {
            return null;
        }
        List<Follow_Up_Queue__c> queues = [
            SELECT Id, Fatigue_Suppressed__c, Suppression_Reason__c, Status__c
            FROM Follow_Up_Queue__c
            WHERE Id = :followUpQueueId
            LIMIT 1
        ];
        return queues.isEmpty() ? null : queues[0];
    }

    public static Follow_Up_Queue__c getFollowUpQueueForTracking(Id followUpQueueId) {
        if (followUpQueueId == null) {
            return null;
        }
        List<Follow_Up_Queue__c> queues = [
            SELECT Id, Attempt_Count__c, Last_Attempt_Date__c, Consecutive_Failures__c,
                   Fatigue_Suppressed__c, Suppression_Reason__c, Status__c
            FROM Follow_Up_Queue__c
            WHERE Id = :followUpQueueId
            LIMIT 1
        ];
        return queues.isEmpty() ? null : queues[0];
    }
}