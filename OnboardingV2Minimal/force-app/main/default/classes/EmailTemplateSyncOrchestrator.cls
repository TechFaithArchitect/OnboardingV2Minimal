public with sharing class EmailTemplateSyncOrchestrator {

    public static void run(Boolean isManual) {
        Datetime start = Datetime.now();
        LoggingUtil.info('EmailTemplateSyncOrchestrator start. manualRun=' + String.valueOf(isManual) + ', at=' + start.format());

        try {
            EmailTemplateSyncService service = new EmailTemplateSyncService();
            EmailSyncSummaryDTO summary = service.syncAllTemplates(null);
            LoggingUtil.info('EmailTemplateSyncOrchestrator success: ' + summary.toString());

        } catch (Exception ex) {
            LoggingUtil.error('EmailTemplateSyncOrchestrator failure: ' + ex.getMessage());
        }

        LoggingUtil.info('EmailTemplateSyncOrchestrator finished at ' + Datetime.now().format());
    }
}
