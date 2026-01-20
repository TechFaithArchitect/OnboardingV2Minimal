public class VendorPrerequisiteEvaluator {
  public class PrereqMap {
    public Map<Id, Map<Id, List<Id>>> customizationToGroupToRequired;
    public Map<Id, String> groupLogicType;

    public PrereqMap() {
      customizationToGroupToRequired = new Map<Id, Map<Id, List<Id>>>();
      groupLogicType = new Map<Id, String>();
    }
  }

  public static PrereqMap getActivePrerequisites() {
    PrereqMap prereqMap = new PrereqMap();

    // Step 1: Load all active group members with group & customization data
    List<Vendor_Program_Group_Member__c> members = [
      SELECT
        Vendor_Program_Group__c,
        Required_Program__c,
        Is_Target__c,
        Vendor_Program_Group__r.Logic_Type__c,
        Vendor_Program_Group__r.Active__c
      FROM Vendor_Program_Group_Member__c
      WHERE Active__c = TRUE
    ];

    // Step 2: Build a map of group to logic type, and identify target customizations
    Map<Id, String> groupLogicType = new Map<Id, String>();
    Map<Id, Id> groupToTarget = new Map<Id, Id>();
    Map<Id, List<Id>> groupToRequired = new Map<Id, List<Id>>();

    for (Vendor_Program_Group_Member__c m : members) {
      Id groupId = m.Vendor_Program_Group__c;

      // Capture logic type once per group
      if (!groupLogicType.containsKey(groupId)) {
        groupLogicType.put(groupId, m.Vendor_Program_Group__r.Logic_Type__c);
      }

      // If it's a target customization
      if (m.Is_Target__c) {
        groupToTarget.put(groupId, m.Required_Program__c);
        continue;
      }

      // Otherwise it's a prerequisite
      if (m.Required_Program__c == null)
        continue;

      if (!groupToRequired.containsKey(groupId)) {
        groupToRequired.put(groupId, new List<Id>());
      }
      groupToRequired.get(groupId).add(m.Required_Program__c);
    }

    // Step 3: Organize data into the PrereqMap format
    for (Id groupId : groupToTarget.keySet()) {
      Id customizationId = groupToTarget.get(groupId);

      if (!groupToRequired.containsKey(groupId))
        continue;

      if (
        !prereqMap.customizationToGroupToRequired.containsKey(customizationId)
      ) {
        prereqMap.customizationToGroupToRequired.put(
          customizationId,
          new Map<Id, List<Id>>()
        );
      }

      prereqMap.customizationToGroupToRequired
        .get(customizationId)
        .put(groupId, groupToRequired.get(groupId));

      prereqMap.groupLogicType.put(groupId, groupLogicType.get(groupId));
    }

    return prereqMap;
  }

  public static Boolean isCustomizationEligible(
    Id customizationId,
    Set<Id> onboardedCustomizationIds,
    PrereqMap prereqMap
  ) {
    if (onboardedCustomizationIds.contains(customizationId)) {
      return false; // Already onboarded
    }

    if (
      !prereqMap.customizationToGroupToRequired.containsKey(customizationId)
    ) {
      return true; // No prerequisites
    }

    Map<Id, List<Id>> groupToRequired = prereqMap.customizationToGroupToRequired.get(
      customizationId
    );

    for (Id groupId : groupToRequired.keySet()) {
      List<Id> required = groupToRequired.get(groupId);
      String logic = prereqMap.groupLogicType.get(groupId);

      if (logic == 'OR') {
        Boolean oneMet = false;
        for (Id req : required) {
          if (onboardedCustomizationIds.contains(req)) {
            oneMet = true;
            break;
          }
        }
        if (!oneMet)
          return false;
      } else {
        // Default to AND
        for (Id req : required) {
          if (!onboardedCustomizationIds.contains(req)) {
            return false;
          }
        }
      }
    }

    return true;
  }
}
