/**
 * Assigns owners for Lead, Contact, and Account.
 * Falls back to the creating user when no owner is set.
 */
public with sharing class LeadAssignmentService {

    /**
     * Bulk-safe assignment for Leads.
     */
    public static void assignOwners(List<Lead> leads) {
        assignOwnersInternal((List<SObject>) leads, 'PostalCode');
    }

    /**
     * Bulk-safe assignment for Contacts.
     */
    public static void assignOwnersForContacts(List<Contact> contacts) {
        assignOwnersInternal((List<SObject>) contacts, 'MailingPostalCode');
    }

    /**
     * Bulk-safe assignment for Accounts.
     */
    public static void assignOwnersForAccounts(List<Account> accounts) {
        assignOwnersInternal((List<SObject>) accounts, 'BillingPostalCode');
    }

    /**
     * Core assignment logic shared across Lead/Contact/Account.
     * @param records SObjects to assign
     * @param postalField API name of the postal code field to read
     */
    private static void assignOwnersInternal(List<SObject> sObjectRecords, String postalField) {
        if (sObjectRecords == null || sObjectRecords.isEmpty()) {
            return;
        }
        for (SObject sObjectRecord : sObjectRecords) {
            if ((Id) sObjectRecord.get('OwnerId') == null) {
                // Default assignment: Created By user (same as current user in before insert)
                sObjectRecord.put('OwnerId', UserInfo.getUserId());
            }
        }
    }
}
