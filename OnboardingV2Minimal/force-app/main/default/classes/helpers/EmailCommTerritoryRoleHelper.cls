public with sharing class EmailCommTerritoryRoleHelper {
  public static void syncRoles(List<Territory_Assignments__c> assignments) {
    Map<Id, List<Territory_Role_Assignment__c>> toInsert = new Map<Id, List<Territory_Role_Assignment__c>>();
    Map<Id, List<Territory_Role_Assignment__c>> toUpdate = new Map<Id, List<Territory_Role_Assignment__c>>();

    // Describe the object once
    Map<String, Schema.SObjectField> fields = Territory_Assignments__c.SObjectType.getDescribe()
      .fields.getMap();

    for (Territory_Assignments__c ta : assignments) {
      List<Territory_Role_Assignment__c> roleAssignments = new List<Territory_Role_Assignment__c>();

      for (String fieldName : fields.keySet()) {
        Schema.DescribeFieldResult fieldDescribe = fields.get(fieldName)
          .getDescribe();

        if (!fieldDescribe.isCustom()) {
          continue;
        }

        if (
          fieldDescribe.getType() == Schema.DisplayType.REFERENCE &&
          fieldDescribe.getReferenceTo().size() > 0 &&
          fieldDescribe.getReferenceTo()[0].getDescribe().getName() == 'User'
        ) {
          if (!ta.isSet(fieldName)) {
            continue;
          }

          Id userId = (Id) ta.get(fieldName);
          if (userId != null) {
            // Label will be used as the Role Name
            String roleName = fieldDescribe.getLabel();

            Territory_Role_Assignment__c roleRecord = new Territory_Role_Assignment__c(
              Territory_Assignments__c = ta.Id,
              User__c = userId,
              Role__c = roleName
            );

            roleAssignments.add(roleRecord);
          }
        }
      }

      if (!roleAssignments.isEmpty()) {
        toInsert.put(ta.Id, roleAssignments);
      }
    }

    // Delete existing role assignments to avoid duplicates
    List<Territory_Role_Assignment__c> toDelete = [
      SELECT Id, Territory_Assignments__c
      FROM Territory_Role_Assignment__c
      WHERE Territory_Assignments__c IN :toInsert.keySet()
    ];
    delete toDelete;

    // Insert new ones
    List<Territory_Role_Assignment__c> allNewRoles = new List<Territory_Role_Assignment__c>();
    for (
      List<Territory_Role_Assignment__c> roleAssignmentList : toInsert.values()
    ) {
      allNewRoles.addAll(roleAssignmentList);
    }

    insert allNewRoles;
  }
}
