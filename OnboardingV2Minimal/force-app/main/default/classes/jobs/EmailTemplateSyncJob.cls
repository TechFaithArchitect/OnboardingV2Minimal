public with sharing class EmailTemplateSyncJob implements Schedulable {
  public void execute(SchedulableContext ctx) {
    try {
      EmailSyncDomainService.runEmailTemplateSync(false);
    } catch (Exception ex) {
      System.debug('❌ Email Template Sync Job failed: ' + ex.getMessage());
    }
  }
}
