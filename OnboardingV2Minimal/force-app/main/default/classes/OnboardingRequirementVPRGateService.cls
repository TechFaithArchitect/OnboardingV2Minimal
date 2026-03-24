/**
 * Filters Vendor_Program_Requirement__c rows for onboarding requirement creation: idempotent skip of
 * existing Onboarding_Requirement__c rows, ordered by Sequence__c. When a row matches an active
 * Vendor_Program_Approval_Policy__mdt with Block_Action__c = true, that row is not created until
 * Onboarding__c.Onboarding_Status__c is Approved (post-approval resume); before approval, creation stops
 * before that row. After approval, that row is included and the batch still stops after it (later types
 * wait for the next run, same as before).
 * Matching uses VPR.Approval_Policy_Key__c + Requirement_Type__c when the key is set; when the key is
 * blank, the active CMDT row for that requirement type with the highest Priority__c is used.
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

  /** When set in tests, used instead of querying Onboarding__c for status (e.g. Approved). */
  @TestVisible
  static String testOnboardingStatusOverride;

  private static final String ONBOARDING_STATUS_APPROVED = 'Approved';

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

    List<Vendor_Program_Approval_Policy__mdt> activePolicies = loadPoliciesForGate();
    Map<String, Vendor_Program_Approval_Policy__mdt> policyByKeyAndType = buildPolicyMap(activePolicies);
    Map<String, Vendor_Program_Approval_Policy__mdt> policyBestByType = buildPolicyMapByType(activePolicies);

    Boolean onboardingApproved = isOnboardingApprovedForGate(onboardingId);

    for (Vendor_Program_Requirement__c vpr : allVpr) {
      if (existingVprIds.contains(vpr.Id)) {
        continue;
      }
      Vendor_Program_Approval_Policy__mdt pol = matchPolicy(vpr, policyByKeyAndType, policyBestByType);
      if (pol != null && pol.Block_Action__c == true && !onboardingApproved) {
        out.gateStoppedThisBatch = true;
        break;
      }
      out.vendorProgramRequirementsToCreate.add(vpr);
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
    testOnboardingStatusOverride = null;
  }

  private static Boolean isOnboardingApprovedForGate(Id onboardingId) {
    if (Test.isRunningTest() && testOnboardingStatusOverride != null) {
      return ONBOARDING_STATUS_APPROVED.equals(testOnboardingStatusOverride);
    }
    if (onboardingId == null) {
      return false;
    }
    List<Onboarding__c> obRows = [
      SELECT Onboarding_Status__c
      FROM Onboarding__c
      WHERE Id = :onboardingId
      LIMIT 1
    ];
    if (obRows.isEmpty()) {
      return false;
    }
    return ONBOARDING_STATUS_APPROVED.equals(obRows[0].Onboarding_Status__c);
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

  /**
   * When VPR.Approval_Policy_Key__c is blank, match CMDT by requirement type only (highest Priority__c wins).
   */
  private static Map<String, Vendor_Program_Approval_Policy__mdt> buildPolicyMapByType(
    List<Vendor_Program_Approval_Policy__mdt> rows
  ) {
    Map<String, Vendor_Program_Approval_Policy__mdt> best = new Map<String, Vendor_Program_Approval_Policy__mdt>();
    if (rows == null) {
      return best;
    }
    for (Vendor_Program_Approval_Policy__mdt row : rows) {
      if (row == null || String.isBlank(row.Type__c)) {
        continue;
      }
      String t = row.Type__c.trim();
      if (!best.containsKey(t)) {
        best.put(t, row);
        continue;
      }
      Decimal prevP = best.get(t).Priority__c == null ? -1 : best.get(t).Priority__c;
      Decimal newP = row.Priority__c == null ? -1 : row.Priority__c;
      if (newP > prevP) {
        best.put(t, row);
      }
    }
    return best;
  }

  private static String mapKey(String policyKey, String typeValue) {
    return policyKey.trim() + '|' + typeValue.trim();
  }

  private static Vendor_Program_Approval_Policy__mdt matchPolicy(
    Vendor_Program_Requirement__c vpr,
    Map<String, Vendor_Program_Approval_Policy__mdt> policyByKeyAndType,
    Map<String, Vendor_Program_Approval_Policy__mdt> policyBestByType
  ) {
    if (vpr == null) {
      return null;
    }
    String reqType = vpr.Requirement_Type__c == null ? null : String.valueOf(vpr.Requirement_Type__c);
    if (String.isBlank(reqType)) {
      return null;
    }
    String reqTypeTrim = reqType.trim();
    if (!String.isBlank(vpr.Approval_Policy_Key__c)) {
      return policyByKeyAndType.get(mapKey(vpr.Approval_Policy_Key__c, reqTypeTrim));
    }
    return policyBestByType != null ? policyBestByType.get(reqTypeTrim) : null;
  }
}
