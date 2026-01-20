trigger LeadTrigger on Lead (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            LeadTriggerHandler.beforeInsert((List<Lead>) Trigger.new);
        } else if (Trigger.isUpdate) {
            LeadTriggerHandler.beforeUpdate((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }

}