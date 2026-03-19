public with sharing class EmailTemplateSyncOrchestrator {

    public static void run(Boolean isManual) {
        Datetime start = Datetime.now();
        LoggingUtil.info('Email Template Sync started at ' + start.format());

        try {
            EmailTemplateSyncService service = new EmailTemplateSyncService();
            EmailSyncSummaryDTO summary = service.syncAllTemplates(null);
            LoggingUtil.info('Sync completed successfully: ' + summary.toString());

        } catch (Exception ex) {
            LoggingUtil.error('Sync failed: ' + ex.getMessage());
        }

        LoggingUtil.info('Email Template Sync finished at ' + Datetime.now().format());
    }
}
