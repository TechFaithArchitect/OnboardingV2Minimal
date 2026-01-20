public with sharing class VersioningTriggerHandler {
    public static void run(
        List<SObject> newList,
        Map<Id, SObject> oldMap,
        String objectApiName
    ) {
        if (!supportsVersioning(objectApiName)) {
            return;
        }
        autoCorrectInvalidActiveDrafts(newList);
        enforceOneActivePerParent(newList, objectApiName);
    }

    public static void afterInsert(List<SObject> newList, String objectApiName) {
        // No post-insert logic currently required — left here for potential future use
    }

    private static void autoCorrectInvalidActiveDrafts(List<SObject> newList) {
        for (SObject sObjectRecord : newList) {
            String status = (String) sObjectRecord.get('Status__c');
            Boolean isActive = (Boolean) sObjectRecord.get('Active__c');
            
            // DRY Pattern: Sync Status__c with Active__c
            // When Status = 'Active', set Active__c = true
            if (status == 'Active' && (isActive == null || isActive == false)) {
                sObjectRecord.put('Active__c', true);
            }
            // When Status = 'Draft', set Active__c = false
            if (status == 'Draft' && isActive == true) {
                sObjectRecord.put('Active__c', false);
            }
        }
    }

    private static void enforceOneActivePerParent(List<SObject> newList, String objectApiName) {
        Set<Id> parentIds = new Set<Id>();
        for (SObject sObjectRecord : newList) {
            Id parentVersionId = (Id) sObjectRecord.get('Previous_Version__c');
            if (parentVersionId != null) parentIds.add(parentVersionId);
        }
        if (parentIds.isEmpty()) return;

        Map<Id, Integer> activeCountByParent = new Map<Id, Integer>();
        String soqlQuery = 'SELECT Previous_Version__c parentId, COUNT(Id) cnt ' +
                   'FROM ' + objectApiName +
                   ' WHERE Active__c = true AND Previous_Version__c IN :parentIds ' +
                   'GROUP BY Previous_Version__c';
        for (AggregateResult aggregateResult : Database.query(soqlQuery)) {
            activeCountByParent.put((Id) aggregateResult.get('parentId'), (Integer) aggregateResult.get('cnt'));
        }

        for (SObject sObjectRecord : newList) {
            if ((Boolean) sObjectRecord.get('Active__c') == true && sObjectRecord.get('Previous_Version__c') != null) {
                Id parentVersionId = (Id) sObjectRecord.get('Previous_Version__c');
                Integer currentCount = activeCountByParent.containsKey(parentVersionId) ? activeCountByParent.get(parentVersionId) : 0;
                activeCountByParent.put(parentVersionId, currentCount + 1);
            }
        }

        for (SObject sObjectRecord : newList) {
            Id parentVersionId = (Id) sObjectRecord.get('Previous_Version__c');
            Boolean willBeActive = (Boolean) sObjectRecord.get('Active__c') == true;
            if (willBeActive && parentVersionId != null) {
                Integer count = activeCountByParent.containsKey(parentVersionId) ? activeCountByParent.get(parentVersionId) : 0;
                if (count > 1) {
                    sObjectRecord.addError('Only one active version is allowed per record lineage.');
                }
            }
        }
    }

    private static Boolean supportsVersioning(String objectApiName) {
        Schema.SObjectType typeInfo = Schema.getGlobalDescribe().get(objectApiName);
        if (typeInfo == null) {
            return false;
        }
        Map<String, Schema.SObjectField> fields = typeInfo.getDescribe().fields.getMap();

        return fields.containsKey('Status__c') &&
            fields.containsKey('Previous_Version__c') &&
            fields.containsKey('Active__c');
    }
}