public with sharing class EmailTemplateSyncOrchestrator {

    public static void run(Boolean isManual) {
        Datetime start = Datetime.now();
        System.debug('Email Template Sync started at ' + start.format());

        Sync_Log__c logRec = UtilitiesSyncLogHelper.createLogRecord('Full Email Sync', isManual);

        try {
            EmailTemplateSyncService service = new EmailTemplateSyncService();
            EmailSyncSummaryDTO summary = service.syncAllTemplates(logRec.Id);

            UtilitiesSyncLogHelper.updateLogRecord(logRec.Id, summary);
            System.debug('Sync completed successfully: ' + summary.toString());

        } catch (Exception ex) {
            UtilitiesSyncLogHelper.markFailed(logRec.Id, ex);
            System.debug('Sync failed: ' + ex.getMessage());
        }

        System.debug('Email Template Sync finished at ' + Datetime.now().format());
    }
}