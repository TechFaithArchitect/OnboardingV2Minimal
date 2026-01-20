/**
 * Platform Event subscriber for Follow-Up Retry Trigger
 * Handles retry logic for failed follow-up messages
 */
public with sharing class FollowUpRetryHandler {

    /**
     * Handle retry events from Platform Event
     * @param events List of FollowUpRetryTrigger__e events
     */
    public static void handleRetry(List<FollowUpRetryTrigger__e> events) {
        if (events == null || events.isEmpty()) {
            return;
        }

        List<Id> followUpIds = new List<Id>();
        for (FollowUpRetryTrigger__e retryEvent : events) {
            if (String.isNotBlank(retryEvent.Follow_Up_Queue_Id__c)) {
                followUpIds.add(retryEvent.Follow_Up_Queue_Id__c);
            }
        }

        if (followUpIds.isEmpty()) {
            return;
        }

        // Process retries
        FollowUpExecutionService.retryFailedFollowUps(followUpIds);
    }
}