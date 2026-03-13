public with sharing class EmailTemplateSyncJob implements Schedulable {

    public void execute(SchedulableContext ctx) {
        try {
            EmailTemplateSyncOrchestrator.run(false);
        } catch (Exception ex) {
            LoggingUtil.error('EmailTemplateSyncJob failure: ' + ex.getMessage());
        }
    }
}
