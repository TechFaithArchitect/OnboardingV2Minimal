public with sharing class RecipientGroupResolver {
    public static List<User> resolveUsersForVendorProgram(Id vendorProgramId) {
        if (vendorProgramId == null) {
            return new List<User>();
        }

        Set<Id> userIds = new Set<Id>();

        // Step 1: Get all active group IDs linked to this Vendor Program
        Set<Id> groupIds = new Set<Id>();
        for (Vendor_Program_Recipient_Group__c link : [
            SELECT Recipient_Group__c
            FROM Vendor_Program_Recipient_Group__c
            WHERE Vendor_Program__c = :vendorProgramId
            AND Is_Active__c = true
        ]) {
            groupIds.add(link.Recipient_Group__c);
        }

        if (groupIds.isEmpty()) {
            return new List<User>();
        }

        // Step 2: Get users from the linked recipient groups
        Set<Id> relatedGroupIds = new Set<Id>();
        Set<Id> territoryRoleAssignmentIds = new Set<Id>();

        // Build dynamic field list to stay compatible if optional lookups are absent.
        Map<String, Schema.SObjectField> memberFields = Recipient_Group_Member__c.SObjectType.getDescribe().fields.getMap();
        List<String> memberSelectFields = new List<String>{ 'Recipient_User__c', 'OwnerId' };
        Boolean hasTerritoryRoleLookup = memberFields.containsKey('Role_Assignment__c');
        if (hasTerritoryRoleLookup) {
            memberSelectFields.add('Role_Assignment__c');
        }

        String memberQuery = 'SELECT ' + String.join(memberSelectFields, ', ') +
            ' FROM Recipient_Group_Member__c WHERE Recipient_Group__c IN :groupIds';

        for (Recipient_Group_Member__c recipientGroupMember : Database.query(memberQuery)) {
            if (recipientGroupMember.Recipient_User__c != null) {
                userIds.add(recipientGroupMember.Recipient_User__c);
            }
            // OwnerId can be a User or Group. Collect Groups to resolve nested members.
            if (recipientGroupMember.OwnerId != null && String.valueOf(recipientGroupMember.OwnerId).startsWith('00G')) {
                relatedGroupIds.add(recipientGroupMember.OwnerId);
            }
            if (hasTerritoryRoleLookup && recipientGroupMember.get('Role_Assignment__c') != null) {
                Id territoryRoleId = (Id) recipientGroupMember.get('Role_Assignment__c');
                territoryRoleAssignmentIds.add(territoryRoleId);
            }
        }

        // Resolve public groups/queues to users
        if (!relatedGroupIds.isEmpty()) {
            for (GroupMember gm : [
                SELECT UserOrGroupId, Group.Type
                FROM GroupMember
                WHERE GroupId IN :relatedGroupIds
            ]) {
                if (gm.UserOrGroupId != null && String.valueOf(gm.UserOrGroupId).startsWith('005')) {
                    userIds.add(gm.UserOrGroupId);
                }
            }
        }

        // Resolve territory role assignments to users (active only)
        if (!territoryRoleAssignmentIds.isEmpty()) {
            for (Territory_Role_Assignment__c roleAssignment : [
                SELECT User__c, Active__c
                FROM Territory_Role_Assignment__c
                WHERE Id IN :territoryRoleAssignmentIds
            ]) {
                if (roleAssignment.Active__c == true && roleAssignment.User__c != null) {
                    userIds.add(roleAssignment.User__c);
                }
            }
        }

        if (userIds.isEmpty()) {
            return new List<User>();
        }

        // Step 3: Return fully hydrated User records with LIMIT for safety
        return [
            SELECT Id, Email
            FROM User
            WHERE Id IN :userIds
            AND Email != null
            LIMIT 1000
        ];
    }
}