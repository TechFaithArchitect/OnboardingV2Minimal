public class OnlyOneTargetProgramInGroupRule implements OnboardingAppValidationRule {
  public void validate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
    List<Vendor_Program_Group_Member__c> newList = (List<Vendor_Program_Group_Member__c>) newRecords;

    Set<Id> groupIds = new Set<Id>();
    Set<Id> newIds = new Set<Id>();

    for (Vendor_Program_Group_Member__c member : newList) {
      if (member.Id != null) {
        newIds.add(member.Id);
      }
      if (member.Vendor_Program_Group__c != null) {
        groupIds.add(member.Vendor_Program_Group__c);
      }
    }

    Map<Id, Integer> existingTargetCountByGroup = new Map<Id, Integer>();
    if (!groupIds.isEmpty()) {
      List<Vendor_Program_Group_Member__c> existingTargets;
      if (newIds.isEmpty()) {
        existingTargets = [
          SELECT Id, Vendor_Program_Group__c
          FROM Vendor_Program_Group_Member__c
          WHERE
            Vendor_Program_Group__c IN :groupIds
            AND Is_Target__c = TRUE
            AND Active__c = TRUE
        ];
      } else {
        existingTargets = [
          SELECT Id, Vendor_Program_Group__c
          FROM Vendor_Program_Group_Member__c
          WHERE
            Vendor_Program_Group__c IN :groupIds
            AND Is_Target__c = TRUE
            AND Active__c = TRUE
            AND Id NOT IN :newIds
        ];
      }

      for (Vendor_Program_Group_Member__c existingMember : existingTargets) {
        Integer count = existingTargetCountByGroup.containsKey(
            existingMember.Vendor_Program_Group__c
          )
          ? existingTargetCountByGroup.get(
              existingMember.Vendor_Program_Group__c
            )
          : 0;
        existingTargetCountByGroup.put(
          existingMember.Vendor_Program_Group__c,
          count + 1
        );
      }
    }

    Map<Id, Integer> seenTargetsByGroup = new Map<Id, Integer>();
    for (Vendor_Program_Group_Member__c member : newList) {
      if (member.Vendor_Program_Group__c == null) {
        continue;
      }

      if (member.Is_Target__c != true || member.Active__c != true) {
        continue;
      }

      Id groupId = member.Vendor_Program_Group__c;
      Integer existingCount = existingTargetCountByGroup.containsKey(groupId)
        ? existingTargetCountByGroup.get(groupId)
        : 0;
      Integer seenCount = seenTargetsByGroup.containsKey(groupId)
        ? seenTargetsByGroup.get(groupId)
        : 0;

      if (existingCount + seenCount >= 1) {
        member.addError(Label.Vendor_Program_Group_Target_Message);
      }

      seenTargetsByGroup.put(groupId, seenCount + 1);
    }
  }
}
