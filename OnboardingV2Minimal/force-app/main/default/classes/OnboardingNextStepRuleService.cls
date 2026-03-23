/**
 * Evaluates active Onboarding_Next_Step_Rule__mdt when onboarding reaches Setup Complete.
 * Auto Create: inserts a sibling Onboarding__c for Scope_Key__c (target Vendor_Customization__c) when the
 * field path (from the triggering onboarding row) matches Expected_Value__c with Operator__c Equals.
 * Each auto-created onboarding gets a new Draft Contract on the same Account and Opportunity as the source.
 */
public with sharing class OnboardingNextStepRuleService {
  /** Test and production use: in-memory view of a CMDT rule row. */
  public class RuleSnapshot {
    public String developerName;
    public String action;
    public String scopeKey;
    public String fieldApiName;
    public String expectedValue;
    public String operator;
  }

  @TestVisible
  private class ForcedTestException extends Exception {
  }

  private static final String STATUS_SETUP_COMPLETE = 'Setup Complete';
  private static final String ACTION_AUTO_CREATE = 'Auto Create';
  private static final String OP_EQUALS = 'Equals';
  private static final Pattern SAFE_FIELD_PATH = Pattern.compile('^[a-zA-Z0-9_]+(\\.[a-zA-Z0-9_]+)*$');

  @TestVisible
  static Boolean forceThrowForTest = false;

  /** Same as applyAfterSetupComplete but never throws; returns an error message for Flow/debug or blank on success. */
  public static String applyAfterSetupCompleteSwallowingFaults(Id onboardingId) {
    try {
      applyAfterSetupComplete(onboardingId);
      return '';
    } catch (Exception ex) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.applyAfterSetupCompleteSwallowingFaults failed for Onboarding=' +
          String.valueOf(onboardingId) +
          ': ' +
          ex.getMessage()
      );
      return ex.getMessage();
    }
  }

  public static void applyAfterSetupComplete(Id onboardingId) {
    if (onboardingId == null) {
      return;
    }
    if (forceThrowForTest) {
      throw new ForcedTestException('OnboardingNextStepRuleService: forced test throw');
    }
    List<RuleSnapshot> rules = loadActiveRulesFromCmdt();
    if (rules.isEmpty()) {
      return;
    }
    applyRuleSnapshots(onboardingId, rules);
  }

  @TestVisible
  static void applyRuleSnapshotsForTest(Id onboardingId, List<RuleSnapshot> rules) {
    if (onboardingId == null || rules == null || rules.isEmpty()) {
      return;
    }
    applyRuleSnapshots(onboardingId, rules);
  }

  private static List<RuleSnapshot> loadActiveRulesFromCmdt() {
    List<RuleSnapshot> out = new List<RuleSnapshot>();
    for (Onboarding_Next_Step_Rule__mdt r : [
      SELECT
        DeveloperName,
        Action__c,
        Scope_Key__c,
        Field_API_Name__c,
        Expected_Value__c,
        Operator__c,
        Sequence__c
      FROM Onboarding_Next_Step_Rule__mdt
      WHERE Active__c = TRUE
      ORDER BY Sequence__c NULLS LAST, DeveloperName
    ]) {
      RuleSnapshot s = new RuleSnapshot();
      s.developerName = r.DeveloperName;
      s.action = r.Action__c;
      s.scopeKey = r.Scope_Key__c;
      s.fieldApiName = r.Field_API_Name__c;
      s.expectedValue = r.Expected_Value__c;
      s.operator = r.Operator__c;
      out.add(s);
    }
    return out;
  }

  private static void applyRuleSnapshots(Id onboardingId, List<RuleSnapshot> rules) {
    Set<String> selectFields = new Set<String>{
      'Id',
      'Account__c',
      'Vendor_Customization__c',
      'Opportunity__c',
      'Contract__c',
      'Onboarding_Status__c'
    };
    for (RuleSnapshot rule : rules) {
      String path = rule == null ? null : rule.fieldApiName;
      if (String.isNotBlank(path) && SAFE_FIELD_PATH.matcher(path.trim()).matches()) {
        selectFields.add(path.trim());
      }
    }

    String soql =
      'SELECT ' +
      String.join(new List<String>(selectFields), ', ') +
      ' FROM Onboarding__c WHERE Id = :onboardingId LIMIT 1';
    List<Onboarding__c> rows = Database.query(soql);
    if (rows.isEmpty()) {
      return;
    }
    Onboarding__c onboarding = rows[0];
    if (onboarding.Onboarding_Status__c != STATUS_SETUP_COMPLETE) {
      return;
    }
    if (onboarding.Account__c == null) {
      return;
    }

    for (RuleSnapshot rule : rules) {
      if (rule == null || String.isBlank(rule.action)) {
        continue;
      }
      if (!ACTION_AUTO_CREATE.equalsIgnoreCase(rule.action.trim())) {
        continue;
      }
      if (String.isBlank(rule.fieldApiName) || String.isBlank(rule.expectedValue)) {
        continue;
      }
      if (String.isNotBlank(rule.operator) && !OP_EQUALS.equalsIgnoreCase(rule.operator.trim())) {
        continue;
      }
      String path = rule.fieldApiName.trim();
      if (!SAFE_FIELD_PATH.matcher(path).matches()) {
        continue;
      }

      String actual = readPathAsString(onboarding, path);
      String expected = rule.expectedValue.trim();
      String actualTrimmed = actual == null ? null : actual.trim();
      if (actualTrimmed == null || !expected.equals(actualTrimmed)) {
        continue;
      }

      Id targetVendorProgramId = tryParseId(rule.scopeKey);
      if (targetVendorProgramId == null) {
        LoggingUtil.warn(
          'OnboardingNextStepRuleService: rule ' +
            String.valueOf(rule.developerName) +
            ' has invalid Scope_Key__c; skipped.'
        );
        continue;
      }

      List<Vendor_Customization__c> targetVp = [
        SELECT Id
        FROM Vendor_Customization__c
        WHERE Id = :targetVendorProgramId
        LIMIT 1
      ];
      if (targetVp.isEmpty()) {
        LoggingUtil.warn(
          'OnboardingNextStepRuleService: rule ' +
            String.valueOf(rule.developerName) +
            ' Scope_Key__c is not a Vendor_Customization__c Id in this org; skipped.'
        );
        continue;
      }

      createLinkedOnboardingIfNeeded(onboarding, targetVendorProgramId);
    }
  }

  @TestVisible
  static String readPathAsStringForTest(SObject root, String path) {
    return readPathAsString(root, path);
  }

  private static String readPathAsString(SObject root, String path) {
    if (root == null || String.isBlank(path)) {
      return null;
    }
    List<String> parts = path.trim().split('\\.');
    SObject current = root;
    for (Integer i = 0; i < parts.size(); i++) {
      String segment = parts[i];
      if (i == parts.size() - 1) {
        Object v = current.get(segment);
        return v == null ? null : String.valueOf(v);
      }
      current = current.getSObject(segment);
      if (current == null) {
        return null;
      }
    }
    return null;
  }

  private static void createLinkedOnboardingIfNeeded(Onboarding__c source, Id targetVendorProgramId) {
    if (targetVendorProgramId == null || source.Vendor_Customization__c == targetVendorProgramId) {
      return;
    }

    List<Onboarding__c> existing = [
      SELECT Id
      FROM Onboarding__c
      WHERE
        Account__c = :source.Account__c
        AND Vendor_Customization__c = :targetVendorProgramId
        AND Opportunity__c = :source.Opportunity__c
      LIMIT 1
    ];
    if (!existing.isEmpty()) {
      return;
    }

    Id newContractId = insertSiblingContract(source);
    if (newContractId == null) {
      return;
    }

    Onboarding__c linkedOnb = new Onboarding__c(
      Account__c = source.Account__c,
      Vendor_Customization__c = targetVendorProgramId,
      Opportunity__c = source.Opportunity__c,
      Contract__c = newContractId
    );
    insert as user linkedOnb;
  }

  /**
   * New Draft contract, same Account and Opportunity as the source onboarding (contract-centric sibling).
   * Reuses RecordType, ContractTerm, and Principal Owner from the source contract when present; otherwise
   * resolves Principal_Owner__c from Contacts on the Account.
   */
  private static Id insertSiblingContract(Onboarding__c source) {
    if (source.Account__c == null) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.insertSiblingContract: source onboarding has no Account__c; skipped.'
      );
      return null;
    }

    Id principalOwnerId;
    Integer contractTermMonths = 12;
    Id recordTypeId;

    if (source.Contract__c != null) {
      List<Contract> templates = [
        SELECT Principal_Owner__c, ContractTerm, RecordTypeId
        FROM Contract
        WHERE Id = :source.Contract__c
        LIMIT 1
      ];
      if (!templates.isEmpty()) {
        Contract t = templates[0];
        principalOwnerId = t.Principal_Owner__c;
        if (t.ContractTerm != null) {
          contractTermMonths = t.ContractTerm;
        }
        recordTypeId = t.RecordTypeId;
      }
    }

    if (principalOwnerId == null) {
      List<Contact> principals = [
        SELECT Id
        FROM Contact
        WHERE AccountId = :source.Account__c AND Principal_Owner__c = TRUE
        LIMIT 1
      ];
      if (principals.isEmpty()) {
        principals = [
          SELECT Id
          FROM Contact
          WHERE AccountId = :source.Account__c
          ORDER BY CreatedDate ASC
          LIMIT 1
        ];
      }
      if (principals.isEmpty()) {
        LoggingUtil.warn(
          'OnboardingNextStepRuleService.insertSiblingContract: no Contact on Account ' +
            String.valueOf(source.Account__c) +
            '; Principal_Owner__c is required on Contract. Skipped auto-onboarding.'
        );
        return null;
      }
      principalOwnerId = principals[0].Id;
    }

    Contract sibling = new Contract(
      AccountId = source.Account__c,
      Status = 'Draft',
      StartDate = Date.today(),
      ContractTerm = contractTermMonths,
      Principal_Owner__c = principalOwnerId,
      Opportunity_to_Contract__c = source.Opportunity__c
    );
    if (recordTypeId != null) {
      sibling.RecordTypeId = recordTypeId;
    }
    insert as user sibling;
    return sibling.Id;
  }

  private static Id tryParseId(String raw) {
    if (String.isBlank(raw)) {
      return null;
    }
    try {
      return (Id) raw.trim();
    } catch (Exception ignored) {
      return null;
    }
  }
}
