@isTest
private class EmailCommTerritoryRoleHelperTest {

    @isTest
    static void testSyncRoles_createsAssignmentsCorrectly() {
        // Arrange
        TestDataFactoryWrapper.TerritoryAssignmentWrapper wrapper =
            TestDataFactoryWrapper.createTerritoryAssignmentWithUser(true);

        // Act
        Test.startTest();
        EmailCommTerritoryRoleHelper.syncRoles(new List<Territory_Assignments__c>{ wrapper.assignment });
        Test.stopTest();

        // Assert
        List<Territory_Role_Assignment__c> roleAssignments = [
            SELECT Id, User__c, Role__c, Territory_Assignments__c
            FROM Territory_Role_Assignment__c
            WHERE Territory_Assignments__c = :wrapper.assignment.Id
        ];

        System.assertEquals(1, roleAssignments.size(), 'Should insert 1 role assignment');
        System.assertEquals(wrapper.user.Id, roleAssignments[0].User__c);
        System.assertEquals('Recruiter', roleAssignments[0].Role__c);
    }
}