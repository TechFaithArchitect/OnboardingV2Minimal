public with sharing class LeadTriggerHandler {
    public static void beforeInsert(List<Lead> newList) {
        LeadAssignmentService.assignOwners(newList);
    }

    public static void beforeUpdate(List<Lead> newList, Map<Id, Lead> oldMap) {
        if (newList == null || newList.isEmpty() || oldMap == null) {
            return;
        }

        List<Lead> toProcess = new List<Lead>();
        for (Lead ld : newList) {
            Lead oldRecord = oldMap.get(ld.Id);
            if (oldRecord == null) {
                continue;
            }
            if (postalChanged(ld.PostalCode, oldRecord.PostalCode)) {
                toProcess.add(ld);
            }
        }

        if (!toProcess.isEmpty()) {
            LeadAssignmentService.assignOwners(toProcess);
        }
    }

    private static Boolean postalChanged(String currentPostal, String oldPostal) {
        return (currentPostal == null && oldPostal != null)
            || (currentPostal != null && oldPostal == null)
            || (currentPostal != oldPostal);
    }
}