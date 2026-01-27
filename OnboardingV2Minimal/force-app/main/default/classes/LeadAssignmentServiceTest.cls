@IsTest
private class LeadAssignmentServiceTest {

    @IsTest
    static void assignsOwnerForLeadWhenMissing() {
        Lead ld = new Lead(LastName = 'Test', Company = 'Acme');
        LeadAssignmentService.assignOwners(new List<Lead>{ ld });
        System.assertEquals(UserInfo.getUserId(), ld.OwnerId, 'Lead owner should default to current user');
    }

    @IsTest
    static void doesNotOverrideExistingLeadOwner() {
        User ownerUser = TestDataFactory.createStandardUser(true);
        Lead ld = new Lead(LastName = 'Existing', Company = 'Acme', OwnerId = ownerUser.Id);
        LeadAssignmentService.assignOwners(new List<Lead>{ ld });
        System.assertEquals(ownerUser.Id, ld.OwnerId, 'Lead owner should not be overridden');
    }

    @IsTest
    static void assignsOwnerForContactWhenMissing() {
        Contact con = new Contact(LastName = 'Contact');
        LeadAssignmentService.assignOwnersForContacts(new List<Contact>{ con });
        System.assertEquals(UserInfo.getUserId(), con.OwnerId, 'Contact owner should default to current user');
    }

    @IsTest
    static void assignsOwnerForAccountWhenMissing() {
        Account acc = new Account(Name = 'Account');
        LeadAssignmentService.assignOwnersForAccounts(new List<Account>{ acc });
        System.assertEquals(UserInfo.getUserId(), acc.OwnerId, 'Account owner should default to current user');
    }

    @IsTest
    static void handlesNullAndEmptyInputs() {
        LeadAssignmentService.assignOwners(null);
        LeadAssignmentService.assignOwners(new List<Lead>());
        LeadAssignmentService.assignOwnersForContacts(null);
        LeadAssignmentService.assignOwnersForContacts(new List<Contact>());
        LeadAssignmentService.assignOwnersForAccounts(null);
        LeadAssignmentService.assignOwnersForAccounts(new List<Account>());
    }
}
