@isTest
private class RecipientGroupResolverTest {

    @isTest
    static void testResolveUsersFromRecipientGroupMemberships() {
        // Create three test users
        User user1 = TestDataFactory.createStandardUser(true);
        User user2 = TestDataFactory.createStandardUser(true);
        User roleUser = TestDataFactory.createStandardUser(true);

        // Create an active Vendor and Vendor Program
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        // Create one recipient group (only one active group per vendor program)
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);

        // Link group to the vendor program
        TestDataFactory.createVendorProgramRecipientGroup(vendorProgram, recipientGroup, true);

        // Add users as members
        TestDataFactory.createRecipientGroupMember(true, recipientGroup, user1, 'User', 'To');
        TestDataFactory.createRecipientGroupMember(true, recipientGroup, user2, 'User', 'To');

        Territory_Assignments__c territoryAssignment = new Territory_Assignments__c(
            Division__c = 'DIV',
            Region__c = 'REG',
            Territory__c = 'TERR'
        );
        insert territoryAssignment;

        Territory_Role_Assignment__c roleAssignment = new Territory_Role_Assignment__c(
            Name = 'Role Assignment',
            Territory_Assignments__c = territoryAssignment.Id,
            User__c = roleUser.Id,
            Active__c = true
        );
        insert roleAssignment;

        Recipient_Group_Member__c roleMember = TestDataFactory.createRecipientGroupMember(
            false,
            recipientGroup,
            null,
            'Territory Role Assignment',
            'To'
        );
        roleMember.Role_Assignment__c = roleAssignment.Id;
        insert roleMember;

        // Act
        Test.startTest();
        List<User> result = RecipientGroupResolver.resolveUsersForVendorProgram(vendorProgram.Id);
        Test.stopTest();

        // Assert
        Set<Id> resultUserIds = new Map<Id, User>(result).keySet();

        System.assertEquals(3, resultUserIds.size(), 'Should return expected unique users');
        System.assert(resultUserIds.contains(user1.Id), 'Should include user1');
        System.assert(resultUserIds.contains(user2.Id), 'Should include user2');
        System.assert(resultUserIds.contains(roleUser.Id), 'Should include user from role assignment');
    }

}