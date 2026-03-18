public with sharing class EmailTemplateSyncOrchestrator {

    public static void run(Boolean isManual) {
        Datetime start = Datetime.now();
        System.debug('Email Template Sync started at ' + start.format());

        try {
            EmailTemplateSyncService service = new EmailTemplateSyncService();
            EmailSyncSummaryDTO summary = service.syncAllTemplates(null);
            System.debug('Sync completed successfully: ' + summary.toString());

        } catch (Exception ex) {
            System.debug('Sync failed: ' + ex.getMessage());
        }

        System.debug('Email Template Sync finished at ' + Datetime.now().format());
    }
}