trigger VersioningTrigger on Vendor_Customization__c (before insert, before update, after insert) {
    if (Trigger.isBefore) {
        VersioningTriggerHandler.run(Trigger.new, Trigger.oldMap, 'Vendor_Customization__c');
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        VersioningTriggerHandler.afterInsert(Trigger.new, 'Vendor_Customization__c');
    }
}