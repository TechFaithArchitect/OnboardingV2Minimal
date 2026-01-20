public with sharing class UtilitiesSyncLogHelper {

    //------------------------------------------------------------------------------------------
    // Creates a new Sync_Log__c record and returns it.
    //------------------------------------------------------------------------------------------
    public static Sync_Log__c createLogRecord(String jobName, Boolean isManual) {
        Sync_Log__c logRec = new Sync_Log__c(
            Job_Name__c = jobName,
            Run_Timestamp__c = Datetime.now(),
            Status__c = 'Running',
            Manual_Run__c = isManual,
            Triggered_By__c = UserInfo.getName()
        );
        insert logRec;
        System.debug('🧾 Created Sync Log: ' + logRec.Id);
        return logRec;
    }

    //------------------------------------------------------------------------------------------
    // Updates the log record on successful completion.
    //------------------------------------------------------------------------------------------
    public static void updateLogRecord(Id logId, EmailSyncSummaryDTO summary) {
        if (logId == null || summary == null) return;

        Sync_Log__c logRec = new Sync_Log__c(
            Id = logId,
            Status__c = 'Success',
            Duration_Seconds__c = summary.durationSeconds,
            Async_Operation_ID__c = summary.asyncOperationIdStr,
            Inserted_Count__c = summary.insertedCount,
            Updated_Count__c = summary.updatedCount,
            New_CMDTs__c = summary.newCMDTCount
        );
        update logRec;
        System.debug('✅ Updated Sync Log with summary for Job: ' + logId);
    }

    //------------------------------------------------------------------------------------------
    // Marks the Sync Log as failed and stores error message.
    //------------------------------------------------------------------------------------------
    public static void markFailed(Id logId, Exception ex) {
        if (logId == null) return;

        Sync_Log__c logRec = new Sync_Log__c(
            Id = logId,
            Status__c = 'Failed',
            Error_Message__c = ex != null ? ex.getMessage() : 'Unknown error'
        );
        update logRec;
        System.debug('❌ Marked Sync Log as failed: ' + logId);
    }
}