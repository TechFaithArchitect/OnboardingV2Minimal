@isTest
private class EmailCommTerritoryRoleSyncJobTest {

    @isTest
    static void testExecute_createsAssignmentsViaJob() {
        // SETUP DATA FROM TEST DATA FACTORY
        User user = TestDataFactory.createStandardUser(true);
        Territory_Assignments__c territoryAssignment = TestDataFactory.createTerritoryAssignmentWithUser(user, 'Recruiter__c', true);

        // SCHEDULE THE JOB
        String cronExpression = '0 0 0 1 1 ? 2099';
        Test.startTest();
        System.schedule('Test Role Sync Job', cronExpression, new EmailCommTerritoryRoleSyncJob());
        Test.stopTest();

        // VERIFY THE RESULTS
        // Query all fields including required fields to avoid SObjectException
        List<Territory_Role_Assignment__c> roleAssignments = [
            SELECT Id, User__c, Role__c, Territory_Assignments__c, Name, CreatedDate, LastModifiedDate
            FROM Territory_Role_Assignment__c
            WHERE Territory_Assignments__c = :territoryAssignment.Id
        ];
        System.assertEquals(1, roleAssignments.size(), 'Expected one role assignment');
        System.assertEquals(user.Id, roleAssignments[0].User__c);
        System.assertEquals('Recruiter', roleAssignments[0].Role__c);
    }
}