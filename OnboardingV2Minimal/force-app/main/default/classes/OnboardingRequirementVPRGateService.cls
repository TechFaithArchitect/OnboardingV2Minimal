/**
 * Filters Vendor_Program_Requirement__c rows for onboarding requirement creation: idempotent skip of
 * existing Onboarding_Requirement__c rows, ordered by Sequence__c, and stops after the first new row
 * that matches an active Vendor_Program_Approval_Policy__mdt with Block_Action__c = true.
 */
public with sharing class OnboardingRequirementVPRGateService {
  @TestVisible
  static List<Vendor_Program_Approval_Policy__mdt> testPoliciesOverride;

  /** In-memory VPR list for unit tests (avoids DML). */
  @TestVisible
  static List<Vendor_Program_Requirement__c> testAllVprOverride;

  /** VPR Ids that already have an Onboarding_Requirement__c in tests. */
  @TestVisible
  static Set<Id> testExistingVprIdsOverride;

  public class GateOutcome {
    public List<Vendor_Program_Requirement__c> vendorProgramRequirementsToCreate;
    public Boolean deferredRequirementsRemain;
    public Boolean gateStoppedThisBatch;
  }

  public static GateOutcome buildGateOutcome(Id onboardingId, Id vendorProgramId) {
    GateOutcome out = new GateOutcome();
    out.vendorProgramRequirementsToCreate = new List<Vendor_Program_Requirement__c>();
    out.deferredRequirementsRemain = false;
    out.gateStoppedThisBatch = false;

    if (onboardingId == null || vendorProgramId == null) {
      return out;
    }

    List<Vendor_Program_Requirement__c> allVpr;
    if (Test.isRunningTest() && testAllVprOverride != null) {
      allVpr = testAllVprOverride;
    } else {
      allVpr = [
        SELECT Id, Sequence__c, Requirement_Type__c, Approval_Policy_Key__c, Vendor_Program__c
        FROM Vendor_Program_Requirement__c
        WHERE Vendor_Program__c = :vendorProgramId
        ORDER BY Sequence__c ASC NULLS LAST, Id ASC
      ];
    }

    Set<Id> existingVprIds = new Set<Id>();
    if (Test.isRunningTest() && testExistingVprIdsOverride != null) {
      existingVprIds.addAll(testExistingVprIdsOverride);
    } else {
      for (Onboarding_Requirement__c orow : [
        SELECT Vendor_Program_Requirement__c
        FROM Onboarding_Requirement__c
        WHERE Onboarding__c = :onboardingId AND Vendor_Program_Requirement__c != NULL
      ]) {
        existingVprIds.add(orow.Vendor_Program_Requirement__c);
      }
    }

    Map<String, Vendor_Program_Approval_Policy__mdt> policyByKeyAndType = buildPolicyMap(loadPoliciesForGate());

    for (Vendor_Program_Requirement__c vpr : allVpr) {
      if (existingVprIds.contains(vpr.Id)) {
        continue;
      }
      out.vendorProgramRequirementsToCreate.add(vpr);
      Vendor_Program_Approval_Policy__mdt pol = matchPolicy(vpr, policyByKeyAndType);
      if (pol != null && pol.Block_Action__c == true) {
        out.gateStoppedThisBatch = true;
        break;
      }
    }

    Set<Id> queuedIds = new Set<Id>();
    for (Vendor_Program_Requirement__c q : out.vendorProgramRequirementsToCreate) {
      queuedIds.add(q.Id);
    }
    for (Vendor_Program_Requirement__c vpr : allVpr) {
      if (existingVprIds.contains(vpr.Id) || queuedIds.contains(vpr.Id)) {
        continue;
      }
      out.deferredRequirementsRemain = true;
      break;
    }

    return out;
  }

  @TestVisible
  static void clearTestStubs() {
    testPoliciesOverride = null;
    testAllVprOverride = null;
    testExistingVprIdsOverride = null;
  }

  private static List<Vendor_Program_Approval_Policy__mdt> loadPoliciesForGate() {
    if (Test.isRunningTest() && testPoliciesOverride != null) {
      return testPoliciesOverride;
    }
    return [
      SELECT Policy_Key__c, Type__c, Block_Action__c, Active__c, Priority__c
      FROM Vendor_Program_Approval_Policy__mdt
      WHERE Active__c = TRUE
    ];
  }

  private static Map<String, Vendor_Program_Approval_Policy__mdt> buildPolicyMap(
    List<Vendor_Program_Approval_Policy__mdt> rows
  ) {
    Map<String, Vendor_Program_Approval_Policy__mdt> best = new Map<String, Vendor_Program_Approval_Policy__mdt>();
    if (rows == null) {
      return best;
    }
    for (Vendor_Program_Approval_Policy__mdt row : rows) {
      if (row == null || String.isBlank(row.Policy_Key__c) || String.isBlank(row.Type__c)) {
        continue;
      }
      String k = mapKey(row.Policy_Key__c, row.Type__c);
      if (!best.containsKey(k)) {
        best.put(k, row);
        continue;
      }
      Decimal prevP = best.get(k).Priority__c == null ? -1 : best.get(k).Priority__c;
      Decimal newP = row.Priority__c == null ? -1 : row.Priority__c;
      if (newP > prevP) {
        best.put(k, row);
      }
    }
    return best;
  }

  private static String mapKey(String policyKey, String typeValue) {
    return policyKey.trim() + '|' + typeValue.trim();
  }

  private static Vendor_Program_Approval_Policy__mdt matchPolicy(
    Vendor_Program_Requirement__c vpr,
    Map<String, Vendor_Program_Approval_Policy__mdt> policyByKeyAndType
  ) {
    if (vpr == null || String.isBlank(vpr.Approval_Policy_Key__c)) {
      return null;
    }
    String reqType = vpr.Requirement_Type__c == null ? null : String.valueOf(vpr.Requirement_Type__c);
    if (String.isBlank(reqType)) {
      return null;
    }
    return policyByKeyAndType.get(mapKey(vpr.Approval_Policy_Key__c, reqType));
  }
}
