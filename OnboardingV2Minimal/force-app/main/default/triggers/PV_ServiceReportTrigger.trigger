trigger PV_ServiceReportTrigger on ServiceReport (after insert) {
    if (trigger.isAfter && trigger.isInsert) {
        PV_ServiceReportTriggerHandler.handleAfterInsert(Trigger.new);
    }
}