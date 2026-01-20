trigger ContactTrigger on Contact (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ContactTriggerHandler.beforeInsert((List<Contact>) Trigger.new);
        } else if (Trigger.isUpdate) {
            ContactTriggerHandler.beforeUpdate((List<Contact>) Trigger.new, (Map<Id, Contact>) Trigger.oldMap);
        }
    }
}