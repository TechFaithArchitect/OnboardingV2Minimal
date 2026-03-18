public with sharing class EmailTemplateSyncJob implements Schedulable {

    public void execute(SchedulableContext ctx) {
        try {
            EmailTemplateSyncOrchestrator.run(false);
        } catch (Exception ex) {
            System.debug('❌ Email Template Sync Job failed: ' + ex.getMessage());
        }
    }
}