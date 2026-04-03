/**
 * Loads and applies Onboarding_Status_Normalization__mdt. Single source for status normalization in the evaluator path.
 */
public with sharing class OnboardingStatusNormalizationService {
  public static Map<String, String> loadActiveNormalizationMap() {
    Map<String, String> m = new Map<String, String>();
    if (!Schema.sObjectType.Onboarding_Status_Normalization__mdt.isAccessible()) {
      return m;
    }
    for (
      Onboarding_Status_Normalization__mdt n : [
        SELECT Requirement_Type__c, Status__c, Normalized_Status__c
        FROM Onboarding_Status_Normalization__mdt
        WHERE Active__c = true
      ]
    ) {
      m.put(keyFor(n.Requirement_Type__c, n.Status__c), n.Normalized_Status__c);
    }
    return m;
  }

  public static String normalize(
    String requirementType,
    String rawStatus,
    Map<String, String> normalizationMap
  ) {
    if (normalizationMap == null) {
      return rawStatus;
    }
    String k = keyFor(requirementType, rawStatus);
    String n = normalizationMap.get(k);
    if (n != null) {
      return n;
    }
    return rawStatus == null ? null : rawStatus.trim();
  }

  public static String keyFor(String reqType, String status) {
    String rt = reqType == null ? '' : reqType.trim();
    String st = status == null ? '' : status.trim();
    return rt + '|' + st;
  }
}
