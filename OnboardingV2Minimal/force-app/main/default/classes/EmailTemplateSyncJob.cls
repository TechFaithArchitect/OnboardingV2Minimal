public with sharing class EmailTemplateSyncJob implements Schedulable {

    public void execute(SchedulableContext ctx) {
        Datetime start = Datetime.now();
        LoggingUtil.info('Email Template Sync started at ' + start.format());

        try {
            EmailTemplateSyncService service = new EmailTemplateSyncService();
            EmailTemplateSyncService.EmailSyncSummaryDTO summary = service.syncAllTemplates(null);
            LoggingUtil.info('Sync completed successfully: ' + summary.toString());
        } catch (Exception ex) {
            LoggingUtil.error('Email Template Sync Job failed: ' + ex.getMessage());
        }

        LoggingUtil.info('Email Template Sync finished at ' + Datetime.now().format());
    }
}
