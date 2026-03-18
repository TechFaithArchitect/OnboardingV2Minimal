public with sharing class VendorOnboardingEligibilityRuleEngine {
  public static final String BLOCK_MODE_SAME_PROGRAM = 'BLOCK_SAME_PROGRAM';
  public static final String BLOCK_MODE_VENDOR_ANY_COMPLETE =
    'BLOCK_VENDOR_ON_ANY_COMPLETE';

  public class Rule {
    public String blockMode;
    public Boolean usePrerequisites;

    public Rule(String blockMode, Boolean usePrerequisites) {
      this.blockMode = String.isBlank(blockMode)
        ? BLOCK_MODE_SAME_PROGRAM
        : blockMode;
      this.usePrerequisites = usePrerequisites == null
        ? true
        : usePrerequisites;
    }
  }

  @TestVisible
  private static Map<String, Rule> testRulesByVendorName;
  private static Map<String, Rule> cachedRulesByVendorName;

  public static Map<String, Rule> getRulesByVendorName() {
    if (Test.isRunningTest() && testRulesByVendorName != null) {
      return testRulesByVendorName;
    }

    if (cachedRulesByVendorName == null) {
      cachedRulesByVendorName = new Map<String, Rule>();
      for (Vendor_Onboarding_Eligibility_Rule__mdt metadataRule : [
        SELECT Vendor_Name__c, Block_Mode__c, Use_Prerequisites__c
        FROM Vendor_Onboarding_Eligibility_Rule__mdt
        WHERE Active__c = TRUE
      ]) {
        String normalizedVendorName = normalizeVendorName(
          metadataRule.Vendor_Name__c
        );
        if (normalizedVendorName == null) {
          continue;
        }

        cachedRulesByVendorName.put(
          normalizedVendorName,
          new Rule(
            normalizeBlockMode(metadataRule.Block_Mode__c),
            metadataRule.Use_Prerequisites__c
          )
        );
      }
    }

    return cachedRulesByVendorName;
  }

  public static Rule getRuleForVendorName(
    String vendorName,
    Map<String, Rule> rulesByVendorName
  ) {
    String normalizedVendorName = normalizeVendorName(vendorName);
    if (
      normalizedVendorName == null ||
      rulesByVendorName == null ||
      !rulesByVendorName.containsKey(normalizedVendorName)
    ) {
      return getDefaultRule();
    }

    return rulesByVendorName.get(normalizedVendorName);
  }

  public static Rule getDefaultRule() {
    return new Rule(BLOCK_MODE_SAME_PROGRAM, true);
  }

  @TestVisible
  static void setTestRulesByVendorName(Map<String, Rule> rulesByVendorName) {
    testRulesByVendorName = rulesByVendorName;
  }

  @TestVisible
  static void clearTestRulesByVendorName() {
    testRulesByVendorName = null;
    cachedRulesByVendorName = null;
  }

  public static String normalizeVendorName(String vendorName) {
    return String.isBlank(vendorName) ? null : vendorName.trim().toUpperCase();
  }

  private static String normalizeBlockMode(String blockMode) {
    String normalizedBlockMode = String.isBlank(blockMode)
      ? null
      : blockMode.trim().toUpperCase();

    if (
      normalizedBlockMode == 'BLOCK VENDOR ON ANY COMPLETE' ||
      normalizedBlockMode == 'BLOCK_VENDOR_ON_ANY_COMPLETE'
    ) {
      return BLOCK_MODE_VENDOR_ANY_COMPLETE;
    }

    return BLOCK_MODE_SAME_PROGRAM;
  }
}