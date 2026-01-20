public with sharing class VendorProgramGroupMemberTriggerHandler {
    public static void run(List<SObject> newList, Map<Id, SObject> oldMap) {
        VersioningTriggerHandler.run(newList, oldMap, 'Vendor_Program_Group_Member__c');
    }
}