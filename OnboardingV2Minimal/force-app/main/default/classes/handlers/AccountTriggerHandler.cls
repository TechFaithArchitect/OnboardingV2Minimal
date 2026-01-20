public with sharing class AccountTriggerHandler {
    public static void beforeInsert(List<Account> newList) {
        LeadAssignmentService.assignOwnersForAccounts(newList);
    }

    public static void beforeUpdate(List<Account> newList, Map<Id, Account> oldMap) {
        if (newList == null || newList.isEmpty() || oldMap == null) {
            return;
        }

        List<Account> toProcess = new List<Account>();
        for (Account accountRecord : newList) {
            Account oldAccountRecord = oldMap.get(accountRecord.Id);
            if (oldAccountRecord == null) {
                continue;
            }
            if (postalChanged(accountRecord.BillingPostalCode, oldAccountRecord.BillingPostalCode)) {
                toProcess.add(accountRecord);
            }
        }

        if (!toProcess.isEmpty()) {
            LeadAssignmentService.assignOwnersForAccounts(toProcess);
        }
    }

    private static Boolean postalChanged(String currentPostal, String oldPostal) {
        return (currentPostal == null && oldPostal != null)
            || (currentPostal != null && oldPostal == null)
            || (currentPostal != oldPostal);
    }
}