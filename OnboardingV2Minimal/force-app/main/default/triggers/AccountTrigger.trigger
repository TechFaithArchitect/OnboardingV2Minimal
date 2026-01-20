trigger AccountTrigger on Account (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            AccountTriggerHandler.beforeInsert((List<Account>) Trigger.new);
        } else if (Trigger.isUpdate) {
            AccountTriggerHandler.beforeUpdate((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
        }
    }
}