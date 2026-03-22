/**
 * Evaluates active Onboarding_Next_Step_Rule__mdt when onboarding reaches Setup Complete.
 * Auto Create: inserts a sibling Onboarding__c for Scope_Key__c (target Vendor_Customization__c) when the
 * field path (from the triggering onboarding row) matches Expected_Value__c with Operator__c Equals.
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

    Onboarding__c linkedOnb = new Onboarding__c(
      Account__c = source.Account__c,
      Vendor_Customization__c = targetVendorProgramId,
      Opportunity__c = source.Opportunity__c,
      Contract__c = source.Contract__c
    );
    insert as user linkedOnb;
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
