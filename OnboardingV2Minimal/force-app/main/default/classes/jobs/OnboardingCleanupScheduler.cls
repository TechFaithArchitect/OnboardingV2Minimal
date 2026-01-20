/**
 * Scheduled batch job to clean up abandoned onboarding records
 * Archives records that have been in Draft/Partially_Completed status for 30+ days
 */
global class OnboardingCleanupScheduler implements Database.Batchable<SObject>, Schedulable {

    private static final Integer DEFAULT_THRESHOLD_DAYS = 30;

    /**
     * Schedulable execute method - called by scheduled job
     */
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new OnboardingCleanupScheduler(), 200);
    }

    /**
     * Batch start method - query abandoned records
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Integer thresholdDays = getAbandonmentThreshold();
        DateTime cutoffDateTime = DateTime.now().addDays(-thresholdDays);

        // Query abandoned requirements
        // Note: Status values 'Draft' and 'Partially_Completed' need to be added to picklist
        // Note: Is_Archived__c field needs to be added to Onboarding_Requirement__c
        String query = 'SELECT Id, Status__c, LastModifiedDate, Account__c, Onboarding__c ' +
                      'FROM Onboarding_Requirement__c ' +
                      'WHERE LastModifiedDate < :cutoffDateTime ';
        
        // Add status filter if status values exist
        // TODO: Uncomment when status values are added
        // query += 'AND Status__c IN (\'Draft\', \'Partially_Completed\') ';
        
        // Add archived filter when field exists
        // TODO: Uncomment when Is_Archived__c is added
        // query += 'AND Is_Archived__c = false ';

        query += 'LIMIT 10000';

        return Database.getQueryLocator(query);
    }

    /**
     * Batch execute method - archive abandoned records
     */
    global void execute(Database.BatchableContext bc, List<Onboarding_Requirement__c> scope) {
        List<Onboarding_Requirement__c> toArchive = new List<Onboarding_Requirement__c>();
        List<Task> followUpTasks = new List<Task>();

        for (Onboarding_Requirement__c onboardingRequirement : scope) {
            // Check if status indicates abandonment
            // TODO: Update when status values are added
            Boolean isAbandoned = onboardingRequirement.Status__c == 'Draft' || 
                                 onboardingRequirement.Status__c == 'Partially_Completed' ||
                                 (onboardingRequirement.Status__c != 'Complete' && onboardingRequirement.Status__c != 'Approved');

            if (!isAbandoned) {
                continue;
            }

            // Soft delete: Mark as archived
            // TODO: Uncomment when Is_Archived__c field is created
            // onboardingRequirement.Is_Archived__c = true;
            // onboardingRequirement.Status__c = 'Abandoned';
            toArchive.add(onboardingRequirement);

            // Create follow-up task for Onboarding Rep
            Task followUpTask = new Task(
                WhatId = onboardingRequirement.Id,
                Subject = 'Abandoned Onboarding - Follow Up Required',
                Priority = 'Normal',
                Status = 'Not Started',
                Description = 'This onboarding requirement has been inactive for ' + 
                             getAbandonmentThreshold() + ' days. Please follow up with the dealer.'
            );
            followUpTasks.add(followUpTask);
        }

        if (!toArchive.isEmpty()) {
            update toArchive;
        }

        if (!followUpTasks.isEmpty()) {
            insert followUpTasks;
        }
    }

    /**
     * Batch finish method - send summary
     */
    global void finish(Database.BatchableContext bc) {
        // TODO: Send summary email to admins
        // sendCleanupSummary();
    }

    /**
     * Get abandonment threshold from custom setting or use default
     */
    private static Integer getAbandonmentThreshold() {
        // TODO: Query custom setting for threshold
        // For now, use default
        return DEFAULT_THRESHOLD_DAYS;
    }
}