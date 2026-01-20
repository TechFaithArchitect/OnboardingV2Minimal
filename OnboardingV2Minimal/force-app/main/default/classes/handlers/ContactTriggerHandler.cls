public with sharing class ContactTriggerHandler {
    public static void beforeInsert(List<Contact> newList) {
        LeadAssignmentService.assignOwnersForContacts(newList);
    }

    public static void beforeUpdate(List<Contact> newList, Map<Id, Contact> oldMap) {
        if (newList == null || newList.isEmpty() || oldMap == null) {
            return;
        }

        List<Contact> toProcess = new List<Contact>();
        for (Contact con : newList) {
            Contact oldRecord = oldMap.get(con.Id);
            if (oldRecord == null) {
                continue;
            }
            if (postalChanged(con.MailingPostalCode, oldRecord.MailingPostalCode)) {
                toProcess.add(con);
            }
        }

        if (!toProcess.isEmpty()) {
            LeadAssignmentService.assignOwnersForContacts(toProcess);
        }
    }

    private static Boolean postalChanged(String currentPostal, String oldPostal) {
        return (currentPostal == null && oldPostal != null)
            || (currentPostal != null && oldPostal == null)
            || (currentPostal != oldPostal);
    }
}