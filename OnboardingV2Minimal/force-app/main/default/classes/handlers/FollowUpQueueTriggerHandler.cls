/**
 * Handler for Follow_Up_Queue__c trigger
 * Implements retry logic with exponential backoff
 */
public with sharing class FollowUpQueueTriggerHandler {

    /**
     * Handle after update trigger
     * Processes failed follow-ups and schedules retries
     */
    public static void handleAfterUpdate(List<Follow_Up_Queue__c> newRecords, Map<Id, Follow_Up_Queue__c> oldMap) {
        List<FollowUpRetryTrigger__e> retryEvents = new List<FollowUpRetryTrigger__e>();
        List<Follow_Up_Queue__c> followUpsToUpdate = new List<Follow_Up_Queue__c>();

        for (Follow_Up_Queue__c newRecord : newRecords) {
            Follow_Up_Queue__c oldRecord = oldMap.get(newRecord.Id);

            // Only process if status changed to 'Failed'
            if (newRecord.Status__c == 'Failed' && 
                (oldRecord == null || oldRecord.Status__c != 'Failed')) {
                
                // Check if retry is eligible
                if (isRetryEligible(newRecord)) {
                    DateTime nextRetryDate = calculateNextRetryDate(newRecord);
                    
                    // Update follow-up record
                    Follow_Up_Queue__c followUpUpdate = new Follow_Up_Queue__c(
                        Id = newRecord.Id,
                        Status__c = 'Pending Retry',
                        Next_Attempt_Date__c = nextRetryDate
                    );
                    followUpsToUpdate.add(followUpUpdate);

                    // Create Platform Event for async retry processing
                    FollowUpRetryTrigger__e retryEvent = new FollowUpRetryTrigger__e(
                        Follow_Up_Queue_Id__c = newRecord.Id,
                        Retry_Attempt_Number__c = (newRecord.Attempt_Count__c == null ? 0 : newRecord.Attempt_Count__c.intValue()) + 1,
                        Next_Retry_Date__c = nextRetryDate
                    );
                    retryEvents.add(retryEvent);
                }
            }
        }

        // Update follow-up records
        if (!followUpsToUpdate.isEmpty()) {
            update followUpsToUpdate;
        }

        // Publish Platform Events for async retry processing
        if (!retryEvents.isEmpty()) {
            List<Database.SaveResult> publishResults = EventBus.publish(retryEvents);
            
            // Log any publish failures
            for (Integer resultIndex = 0; resultIndex < publishResults.size(); resultIndex++) {
                if (!publishResults[resultIndex].isSuccess()) {
                    System.debug('Failed to publish retry event for Follow_Up_Queue__c: ' + retryEvents[resultIndex].Follow_Up_Queue_Id__c);
                    for (Database.Error publishError : publishResults[resultIndex].getErrors()) {
                        System.debug('Error: ' + publishError.getMessage());
                    }
                }
            }
        }
    }

    /**
     * Check if a follow-up is eligible for retry
     * @param followUp Follow_Up_Queue__c record
     * @return Boolean indicating if retry is eligible
     */
    private static Boolean isRetryEligible(Follow_Up_Queue__c followUp) {
        // Check attempt count limit (max 3 retries)
        Integer attemptCount = followUp.Attempt_Count__c == null ? 0 : followUp.Attempt_Count__c.intValue();
        if (attemptCount >= 3) {
            return false;
        }

        // Check if enough time has passed since last attempt (minimum 1 hour)
        if (followUp.Last_Attempt_Date__c != null) {
            DateTime oneHourAgo = DateTime.now().addHours(-1);
            if (followUp.Last_Attempt_Date__c > oneHourAgo) {
                return false;
            }
        }

        return true;
    }

    /**
     * Calculate next retry date using exponential backoff
     * @param followUp Follow_Up_Queue__c record
     * @return DateTime for next retry
     */
    private static DateTime calculateNextRetryDate(Follow_Up_Queue__c followUp) {
        Integer attemptCount = followUp.Attempt_Count__c == null ? 0 : followUp.Attempt_Count__c.intValue();
        DateTime now = DateTime.now();
        
        // Exponential backoff:
        // 1st retry: 1 hour after failure
        // 2nd retry: 4 hours after first retry
        // 3rd retry: 12 hours after second retry
        Integer delayHours;
        if (attemptCount == 0) {
            delayHours = 1;
        } else if (attemptCount == 1) {
            delayHours = 4;
        } else {
            delayHours = 12;
        }

        return now.addHours(delayHours);
    }
}