public with sharing class EmailCommTerritoryRoleHelper {
  @TestVisible
  private static Set<String> processedAssignmentOperationKeys = new Set<String>();
  @TestVisible
  private static List<String> cachedUserLookupFieldNames;
  @TestVisible
  private static Map<String, String> cachedUserLookupLabelsByField;

  public static void syncRoles(List<Territory_Assignments__c> assignments) {
    syncRoles(assignments, null, 'UNKNOWN');
  }

  public static void syncRoles(
    List<Territory_Assignments__c> assignments,
    String operationKey
  ) {
    syncRoles(assignments, null, operationKey);
  }

  public static void syncRoles(
    List<Territory_Assignments__c> assignments,
    Map<Id, Territory_Assignments__c> oldAssignmentsById,
    String operationKey
  ) {
    if (assignments == null || assignments.isEmpty()) {
      return;
    }
    String safeOperationKey = String.isBlank(operationKey)
      ? 'UNKNOWN'
      : operationKey;
    List<String> userLookupFieldNames = getUserLookupFieldNames();
    Map<String, String> userLookupLabelsByField = getUserLookupLabelsByField();

    Map<Id, List<Territory_Role_Assignment__c>> toInsert = new Map<Id, List<Territory_Role_Assignment__c>>();
    Set<Id> assignmentIdsToRefresh = new Set<Id>();

    for (Territory_Assignments__c ta : assignments) {
      if (ta == null || ta.Id == null) {
        continue;
      }
      String idempotencyKey = safeOperationKey + ':' + String.valueOf(ta.Id);
      if (processedAssignmentOperationKeys.contains(idempotencyKey)) {
        continue;
      }

      Territory_Assignments__c oldAssignment = oldAssignmentsById == null
        ? null
        : oldAssignmentsById.get(ta.Id);
      if (!shouldRefreshRoles(ta, oldAssignment, userLookupFieldNames)) {
        continue;
      }

      List<Territory_Role_Assignment__c> roleAssignments = buildRoleAssignments(
        ta,
        userLookupFieldNames,
        userLookupLabelsByField
      );
      assignmentIdsToRefresh.add(ta.Id);

      if (!roleAssignments.isEmpty()) {
        toInsert.put(ta.Id, roleAssignments);
      }
      processedAssignmentOperationKeys.add(idempotencyKey);
    }

    if (assignmentIdsToRefresh.isEmpty()) {
      return;
    }

    // Delete existing role assignments to avoid duplicates
    List<Territory_Role_Assignment__c> toDelete = [
      SELECT Id, Territory_Assignments__c
      FROM Territory_Role_Assignment__c
      WHERE Territory_Assignments__c IN :assignmentIdsToRefresh
      WITH SECURITY_ENFORCED
    ];
    if (!toDelete.isEmpty()) {
      delete toDelete;
    }

    // Insert new ones
    List<Territory_Role_Assignment__c> allNewRoles = new List<Territory_Role_Assignment__c>();
    for (
      List<Territory_Role_Assignment__c> roleAssignmentList : toInsert.values()
    ) {
      allNewRoles.addAll(roleAssignmentList);
    }

    if (!allNewRoles.isEmpty()) {
      insert allNewRoles;
    }
  }

  private static Boolean shouldRefreshRoles(
    Territory_Assignments__c assignment,
    Territory_Assignments__c oldAssignment,
    List<String> userLookupFieldNames
  ) {
    if (assignment == null) {
      return false;
    }
    if (oldAssignment == null) {
      return hasAnyAssignedUsers(assignment, userLookupFieldNames);
    }

    return hasUserLookupChanges(
      assignment,
      oldAssignment,
      userLookupFieldNames
    );
  }

  private static Boolean hasAnyAssignedUsers(
    Territory_Assignments__c assignment,
    List<String> userLookupFieldNames
  ) {
    for (String fieldName : userLookupFieldNames) {
      if ((Id) assignment.get(fieldName) != null) {
        return true;
      }
    }

    return false;
  }

  private static Boolean hasUserLookupChanges(
    Territory_Assignments__c assignment,
    Territory_Assignments__c oldAssignment,
    List<String> userLookupFieldNames
  ) {
    for (String fieldName : userLookupFieldNames) {
      if ((Id) assignment.get(fieldName) != (Id) oldAssignment.get(fieldName)) {
        return true;
      }
    }

    return false;
  }

  private static List<Territory_Role_Assignment__c> buildRoleAssignments(
    Territory_Assignments__c assignment,
    List<String> userLookupFieldNames,
    Map<String, String> userLookupLabelsByField
  ) {
    List<Territory_Role_Assignment__c> roleAssignments = new List<Territory_Role_Assignment__c>();

    for (String fieldName : userLookupFieldNames) {
      if (!assignment.isSet(fieldName)) {
        continue;
      }

      Id userId = (Id) assignment.get(fieldName);
      if (userId == null) {
        continue;
      }

      roleAssignments.add(
        new Territory_Role_Assignment__c(
          Territory_Assignments__c = assignment.Id,
          User__c = userId,
          Role__c = userLookupLabelsByField.get(fieldName)
        )
      );
    }

    return roleAssignments;
  }

  private static List<String> getUserLookupFieldNames() {
    if (cachedUserLookupFieldNames != null) {
      return cachedUserLookupFieldNames;
    }

    cachedUserLookupFieldNames = new List<String>();
    cachedUserLookupLabelsByField = new Map<String, String>();
    Map<String, Schema.SObjectField> fields = Territory_Assignments__c.SObjectType.getDescribe()
      .fields.getMap();

    for (String fieldName : fields.keySet()) {
      Schema.DescribeFieldResult fieldDescribe = fields.get(fieldName)
        .getDescribe();
      if (
        fieldDescribe.isCustom() &&
        fieldDescribe.getType() == Schema.DisplayType.REFERENCE &&
        fieldDescribe.getReferenceTo().size() > 0 &&
        fieldDescribe.getReferenceTo()[0].getDescribe().getName() == 'User'
      ) {
        cachedUserLookupFieldNames.add(fieldName);
        cachedUserLookupLabelsByField.put(fieldName, fieldDescribe.getLabel());
      }
    }

    cachedUserLookupFieldNames.sort();
    return cachedUserLookupFieldNames;
  }

  private static Map<String, String> getUserLookupLabelsByField() {
    if (cachedUserLookupLabelsByField == null) {
      getUserLookupFieldNames();
    }

    return cachedUserLookupLabelsByField;
  }
}
