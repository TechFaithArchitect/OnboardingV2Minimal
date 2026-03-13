@IsTest
private class EmailCommTerritoryRoleHelperTest {
  private static final Integer BULK_RECORD_COUNT = 210;

  @IsTest
  static void testTriggerCreatesRoleAssignments() {
    User recruiterUser = TestDataFactory.createStandardUser(true);
    Territory_Assignments__c assignment = TestDataFactory.createTerritoryAssignmentWithUser(
      recruiterUser,
      'Recruiter__c',
      true
    );

    List<Territory_Role_Assignment__c> roleAssignments = [
      SELECT Territory_Assignments__c, User__c, Role__c
      FROM Territory_Role_Assignment__c
      WHERE Territory_Assignments__c = :assignment.Id
    ];

    System.assertEquals(
      1,
      roleAssignments.size(),
      'Trigger should create one role assignment for the recruiter lookup.'
    );
    System.assertEquals(
      recruiterUser.Id,
      roleAssignments[0].User__c,
      'Role assignment should reference the recruiter user.'
    );
    System.assert(
      String.isNotBlank(roleAssignments[0].Role__c),
      'Role label should be populated from field metadata.'
    );
  }

  @IsTest
  static void testOperationGuardAndUpdatePath() {
    User firstRecruiter = TestDataFactory.createStandardUser(true);
    Territory_Assignments__c assignment = TestDataFactory.createTerritoryAssignmentWithUser(
      firstRecruiter,
      'Recruiter__c',
      true
    );

    Test.startTest();
    // Simulate duplicate invocation for the same operation within transaction.
    EmailCommTerritoryRoleHelper.syncRoles(
      new List<Territory_Assignments__c>{ assignment },
      'AFTER_INSERT'
    );
    Test.stopTest();

    Integer countAfterDuplicateInsert = [
      SELECT COUNT()
      FROM Territory_Role_Assignment__c
      WHERE Territory_Assignments__c = :assignment.Id
    ];
    System.assertEquals(
      1,
      countAfterDuplicateInsert,
      'Duplicate AFTER_INSERT processing should not create additional role rows.'
    );

    User updatedRecruiter = TestDataFactory.createStandardUser(true);
    assignment.Recruiter__c = updatedRecruiter.Id;
    update assignment;

    List<Territory_Role_Assignment__c> refreshedRoles = [
      SELECT Territory_Assignments__c, User__c
      FROM Territory_Role_Assignment__c
      WHERE Territory_Assignments__c = :assignment.Id
    ];

    System.assertEquals(
      1,
      refreshedRoles.size(),
      'Update path should keep exactly one role assignment row.'
    );
    System.assertEquals(
      updatedRecruiter.Id,
      refreshedRoles[0].User__c,
      'AFTER_UPDATE processing should refresh role assignment user.'
    );
  }

  @IsTest
  static void testClearingLookupDeletesRoleAssignments() {
    User recruiterUser = TestDataFactory.createStandardUser(true);
    Territory_Assignments__c assignment = TestDataFactory.createTerritoryAssignmentWithUser(
      recruiterUser,
      'Recruiter__c',
      true
    );

    assignment.Recruiter__c = null;
    update assignment;

    Integer remainingRoleAssignments = [
      SELECT COUNT()
      FROM Territory_Role_Assignment__c
      WHERE Territory_Assignments__c = :assignment.Id
    ];
    System.assertEquals(
      0,
      remainingRoleAssignments,
      'Clearing the last user lookup should delete stale territory role assignments.'
    );
  }

  @IsTest
  static void testBulkUpdateMixedStateOver200Records() {
    User initialRecruiter = TestDataFactory.createStandardUser(true);
    User updatedRecruiter = TestDataFactory.createStandardUser(true);
    List<Territory_Assignments__c> assignments = new List<Territory_Assignments__c>();

    for (Integer i = 0; i < BULK_RECORD_COUNT; i++) {
      assignments.add(
        new Territory_Assignments__c(
          Division__c = 'Infra',
          Region__c = 'PNW',
          Territory__c = 'T' + String.valueOf(i),
          Recruiter__c = initialRecruiter.Id
        )
      );
    }

    insert assignments;

    Integer insertedRoleCount = [
      SELECT COUNT()
      FROM Territory_Role_Assignment__c
      WHERE Territory_Assignments__c IN :assignments
    ];
    System.assertEquals(
      BULK_RECORD_COUNT,
      insertedRoleCount,
      'Each inserted territory assignment should create one role assignment.'
    );

    Integer unchangedCount = 70;
    Integer changedCount = 70;
    Integer clearedCount = BULK_RECORD_COUNT - unchangedCount - changedCount;
    List<Territory_Assignments__c> updates = new List<Territory_Assignments__c>();

    for (Integer i = 0; i < BULK_RECORD_COUNT; i++) {
      Territory_Assignments__c updateRecord = new Territory_Assignments__c(
        Id = assignments[i].Id
      );
      if (i < unchangedCount) {
        updateRecord.Territory__c = 'U' + String.valueOf(i);
      } else if (i < unchangedCount + changedCount) {
        updateRecord.Recruiter__c = updatedRecruiter.Id;
      } else {
        updateRecord.Recruiter__c = null;
      }
      updates.add(updateRecord);
    }

    update updates;

    List<Territory_Role_Assignment__c> refreshedRoles = [
      SELECT Territory_Assignments__c, User__c
      FROM Territory_Role_Assignment__c
      WHERE Territory_Assignments__c IN :assignments
    ];
    Map<Id, List<Territory_Role_Assignment__c>> rolesByAssignmentId = new Map<Id, List<Territory_Role_Assignment__c>>();

    for (Territory_Role_Assignment__c roleAssignment : refreshedRoles) {
      if (!rolesByAssignmentId.containsKey(roleAssignment.Territory_Assignments__c)) {
        rolesByAssignmentId.put(
          roleAssignment.Territory_Assignments__c,
          new List<Territory_Role_Assignment__c>()
        );
      }
      rolesByAssignmentId.get(roleAssignment.Territory_Assignments__c)
        .add(roleAssignment);
    }

    System.assertEquals(
      BULK_RECORD_COUNT - clearedCount,
      refreshedRoles.size(),
      'Only unchanged and reassigned records should retain one role assignment each.'
    );

    for (Integer i = 0; i < BULK_RECORD_COUNT; i++) {
      Id assignmentId = assignments[i].Id;
      if (i < unchangedCount) {
        System.assertEquals(
          1,
          rolesByAssignmentId.get(assignmentId).size(),
          'Unchanged recruiter rows should keep exactly one role assignment.'
        );
        System.assertEquals(
          initialRecruiter.Id,
          rolesByAssignmentId.get(assignmentId)[0].User__c,
          'Unrelated updates should preserve the original recruiter role assignment.'
        );
      } else if (i < unchangedCount + changedCount) {
        System.assertEquals(
          1,
          rolesByAssignmentId.get(assignmentId).size(),
          'Changed recruiter rows should keep exactly one role assignment.'
        );
        System.assertEquals(
          updatedRecruiter.Id,
          rolesByAssignmentId.get(assignmentId)[0].User__c,
          'Changed recruiter rows should point at the updated recruiter.'
        );
      } else {
        System.assertEquals(
          false,
          rolesByAssignmentId.containsKey(assignmentId),
          'Cleared recruiter rows should have no remaining role assignments.'
        );
      }
    }

    System.assertEquals(
      BULK_RECORD_COUNT + changedCount + clearedCount,
      EmailCommTerritoryRoleHelper.processedAssignmentOperationKeys.size(),
      'Only inserts plus recruiter-changing updates should be processed.'
    );
  }
}
