trigger TerritoryAssignmentsTrigger on Territory_Assignments__c (after insert, after update) {
    if (Trigger.isAfter) {
        EmailCommTerritoryRoleHelper.syncRoles(Trigger.new);
    }
}