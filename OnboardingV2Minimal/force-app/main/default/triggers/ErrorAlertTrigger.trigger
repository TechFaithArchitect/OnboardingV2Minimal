trigger ErrorAlertTrigger on Error_Alert__e (after insert) {
    //After Insert
    if (Trigger.isAfter && Trigger.isInsert) {
        ErrorAlertTriggerHelper.afterInsert(Trigger.new);
    }
}