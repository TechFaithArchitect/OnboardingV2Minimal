/**
 * Scheduled batch job to process pending follow-ups
 * Runs periodically to send follow-ups that are due
 * 
 * NOTE: This is a Batchable version. There's also a Schedulable version in schedulers/ folder
 * that uses FollowUpProcessor Queueable. This batchable version processes follow-ups directly.
 */
public with sharing class FollowUpProcessorBatchScheduler implements Database.Batchable<SObject>, Schedulable {

    /**
     * Schedulable execute method - called by scheduled job
     */
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new FollowUpProcessorBatchScheduler(), 50);
    }

    /**
     * Batchable start method - query pending follow-ups
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime now = DateTime.now();
        
        // Query follow-ups that are due for processing
        // Status = Pending and Next_Attempt_Date__c <= now
        return Database.getQueryLocator([
            SELECT Id, Onboarding__c, Onboarding_Requirement__c,
                   Follow_Up_Type__c, Status__c, Follow_Up_Rule__c,
                   Next_Attempt_Date__c, Attempt_Count__c,
                   Fatigue_Suppressed__c, Consecutive_Failures__c
            FROM Follow_Up_Queue__c
            WHERE Status__c = 'Pending'
              AND Next_Attempt_Date__c <= :now
              AND Is_Archived__c = false
            ORDER BY Next_Attempt_Date__c ASC
            LIMIT 200
        ]);
    }

    /**
     * Batchable execute method - process each follow-up
     */
    public void execute(Database.BatchableContext bc, List<Follow_Up_Queue__c> followUps) {
        if (followUps == null || followUps.isEmpty()) {
            return;
        }

        List<Follow_Up_Queue__c> toUpdate = new List<Follow_Up_Queue__c>();
        
        for (Follow_Up_Queue__c followUp : followUps) {
            try {
                // Check if suppressed due to fatigue
                if (followUp.Fatigue_Suppressed__c == true) {
                    // Skip suppressed follow-ups, but update next attempt date
                    followUp.Next_Attempt_Date__c = calculateNextRetryDate(followUp);
                    toUpdate.add(followUp);
                    continue;
                }

                // Process based on follow-up type
                if (followUp.Follow_Up_Type__c == 'SMS') {
                    FollowUpExecutionService.sendSMSFollowUp(followUp.Id);
                } else if (followUp.Follow_Up_Type__c == 'Email') {
                    FollowUpExecutionService.sendEmailFollowUp(followUp.Id);
                } else {
                    // Unknown type - mark as failed
                    FollowUpExecutionService.markFollowUpFailed(
                        followUp.Id,
                        'Unknown follow-up type: ' + followUp.Follow_Up_Type__c
                    );
                }
            } catch (Exception ex) {
                // Log error and mark as failed
                System.debug('Error processing follow-up ' + followUp.Id + ': ' + ex.getMessage());
                System.debug('Stack trace: ' + ex.getStackTraceString());
                
                try {
                    FollowUpExecutionService.markFollowUpFailed(
                        followUp.Id,
                        'Processing error: ' + ex.getMessage()
                    );
                } catch (Exception updateEx) {
                    System.debug('Error marking follow-up as failed: ' + updateEx.getMessage());
                }
            }
        }

        // Update any follow-ups that were modified (e.g., suppressed ones)
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    /**
     * Batchable finish method - log completion
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('FollowUpProcessorScheduler batch completed');
    }

    /**
     * Calculate next retry date with exponential backoff
     */
    private static DateTime calculateNextRetryDate(Follow_Up_Queue__c followUp) {
        Integer attemptCount = followUp.Attempt_Count__c != null ? followUp.Attempt_Count__c.intValue() : 0;
        Integer backoffHours = (Integer)Math.pow(2, attemptCount); // Exponential: 1, 2, 4, 8, 16 hours
        backoffHours = Math.min(backoffHours, 24); // Cap at 24 hours
        
        return DateTime.now().addHours(backoffHours);
    }

    /**
     * Schedule the job to run hourly
     * Call this method to set up the scheduled job:
     * String jobId = FollowUpProcessorScheduler.scheduleHourly();
     */
    public static String scheduleHourly() {
        FollowUpProcessorBatchScheduler scheduler = new FollowUpProcessorBatchScheduler();
        // Run every hour
        return System.schedule('Follow-Up Processor Batch Hourly', '0 0 * * * ?', scheduler);
    }

    /**
     * Schedule the job to run every 15 minutes
     * Call this method to set up the scheduled job:
     * String jobId = FollowUpProcessorBatchScheduler.scheduleEvery15Minutes();
     */
    public static String scheduleEvery15Minutes() {
        FollowUpProcessorBatchScheduler scheduler = new FollowUpProcessorBatchScheduler();
        // Run every 15 minutes
        return System.schedule('Follow-Up Processor Batch 15min', '0 */15 * * * ?', scheduler);
    }
}

