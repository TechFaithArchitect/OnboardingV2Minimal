/**
 * Filters Vendor_Program_Requirement__c rows for onboarding requirement creation: idempotent skip of
 * existing Onboarding_Requirement__c rows, ordered by Sequence__c. When a row matches an active
 * Vendor_Program_Approval_Policy__mdt with Block_Action__c = true, that row is not created until
 * Onboarding__c.Onboarding_Status__c is Approved (post-approval resume); before approval, creation stops
 * before that row. After approval, that row is included and the batch still stops after it (later types
 * wait for the next run, same as before).
 * CMDT lookup uses Vendor_Customization__c.Approval_Policy_Key__c + Vendor_Program_Requirement__c.Requirement_Type__c.
 * Programs with no approval policy key on the vendor program record do not match CMDT.
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

  /** When true in tests, {@link #testVendorProgramApprovalPolicyKeyStubValue} replaces the program SOQL. */
  @TestVisible
  static Boolean testVendorProgramApprovalPolicyKeyStubActive;

  /** Program Approval_Policy_Key__c substitute when {@link #testVendorProgramApprovalPolicyKeyStubActive} is true. */
  @TestVisible
  static String testVendorProgramApprovalPolicyKeyStubValue;

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
        SELECT Id, Sequence__c, Requirement_Type__c, Vendor_Program__c
        FROM Vendor_Program_Requirement__c
        WHERE Vendor_Program__c = :vendorProgramId
        WITH SECURITY_ENFORCED
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
        WITH SECURITY_ENFORCED
      ]) {
        existingVprIds.add(orow.Vendor_Program_Requirement__c);
      }
    }

    List<Vendor_Program_Approval_Policy__mdt> activePolicies = loadPoliciesForGate();
    Map<String, Vendor_Program_Approval_Policy__mdt> policyByKeyAndType = buildPolicyMap(activePolicies);

    String vendorProgramPolicyKey = resolveVendorProgramApprovalPolicyKey(vendorProgramId);
    Boolean onboardingApproved = isOnboardingApprovedForGate(onboardingId);

    for (Vendor_Program_Requirement__c vpr : allVpr) {
      if (existingVprIds.contains(vpr.Id)) {
        continue;
      }
      Vendor_Program_Approval_Policy__mdt pol = matchPolicy(vpr, vendorProgramPolicyKey, policyByKeyAndType);
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
    testVendorProgramApprovalPolicyKeyStubActive = false;
    testVendorProgramApprovalPolicyKeyStubValue = null;
  }

  private static String resolveVendorProgramApprovalPolicyKey(Id vendorProgramId) {
    if (Test.isRunningTest() && testVendorProgramApprovalPolicyKeyStubActive == true) {
      return String.isBlank(testVendorProgramApprovalPolicyKeyStubValue)
        ? null
        : testVendorProgramApprovalPolicyKeyStubValue.trim();
    }
    List<Vendor_Customization__c> rows = [
      SELECT Approval_Policy_Key__c
      FROM Vendor_Customization__c
      WHERE Id = :vendorProgramId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    if (rows.isEmpty() || String.isBlank(rows[0].Approval_Policy_Key__c)) {
      return null;
    }
    return rows[0].Approval_Policy_Key__c.trim();
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
      WITH SECURITY_ENFORCED
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
    if (!Schema.sObjectType.Vendor_Program_Approval_Policy__mdt.isAccessible()) {
      return new List<Vendor_Program_Approval_Policy__mdt>();
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
    String vendorProgramPolicyKey,
    Map<String, Vendor_Program_Approval_Policy__mdt> policyByKeyAndType
  ) {
    if (vpr == null || String.isBlank(vendorProgramPolicyKey)) {
      return null;
    }
    String reqType = vpr.Requirement_Type__c == null ? null : String.valueOf(vpr.Requirement_Type__c);
    if (String.isBlank(reqType)) {
      return null;
    }
    return policyByKeyAndType.get(mapKey(vendorProgramPolicyKey.trim(), reqType.trim()));
  }
}
