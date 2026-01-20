/**
 * Evaluates next-step actions for onboarding workflows using overrides and metadata rules.
 *
 * Expected config:
 * - Custom Metadata: Onboarding_Next_Step_Rule__mdt
 *   Fields: Scope_Key__c, Field_API_Name__c, Operator__c, Expected_Value__c, Action__c, Sequence__c, Active__c
 * - Custom Object: Onboarding_Next_Step_Override__c
 *   Fields: Onboarding__c, Vendor_Program__c, Action__c, Active__c, Expires_On__c
 */
public with sharing class OnboardingNextStepService {
  public static final String ACTION_AUTO_CREATE = 'Auto_Create';
  public static final String ACTION_MANUAL_UNLOCK = 'Manual_Unlock';
  public static final String ACTION_NONE = 'None';

  private static final String ACTION_SOURCE_OVERRIDE = 'Override';
  private static final String ACTION_SOURCE_RULE = 'Rule';
  private static final String ACTION_SOURCE_DEFAULT = 'Default';

  private static final String OPERATOR_EQUALS = 'Equals';
  private static final String OPERATOR_NOT_EQUALS = 'NotEquals';
  private static final String OPERATOR_CONTAINS = 'Contains';
  private static final String OPERATOR_IS_BLANK = 'IsBlank';
  private static final String OPERATOR_IS_NOT_BLANK = 'IsNotBlank';
  private static final String OPERATOR_IN = 'In';

  private static final Map<String, Schema.SObjectField> ONBOARDING_FIELD_MAP = Onboarding__c.SObjectType.getDescribe()
    .fields.getMap();

  public class Request {
    @InvocableVariable(required=true)
    public Id onboardingId;
    @InvocableVariable(required=true)
    public Id targetVendorProgramId;
    @InvocableVariable
    public String vendorProgramGroupKey;
  }

  public class Response {
    @InvocableVariable
    public Id onboardingId;
    @InvocableVariable
    public Id targetVendorProgramId;
    @InvocableVariable
    public String action;
    @InvocableVariable
    public String actionSource;
    @InvocableVariable
    public String matchedRuleName;
  }

  private class OverrideDecision {
    public String action;
    public Id overrideId;
  }

  private class NextStepRuleConfig {
    public String developerName;
    public String scopeKey;
    public String fieldApiName;
    public String operatorValue;
    public String expectedValue;
    public String action;
    public Decimal sequence;
  }

  private class NextStepRuleComparator implements Comparator<NextStepRuleConfig> {
    public Integer compare(
      NextStepRuleConfig leftRule,
      NextStepRuleConfig rightRule
    ) {
      Decimal leftSequence = leftRule != null &&
        leftRule.sequence != null
        ? leftRule.sequence
        : Decimal.valueOf(999999);
      Decimal rightSequence = rightRule != null &&
        rightRule.sequence != null
        ? rightRule.sequence
        : Decimal.valueOf(999999);

      if (leftSequence == rightSequence) {
        String leftName = leftRule != null ? leftRule.developerName : null;
        String rightName = rightRule != null ? rightRule.developerName : null;
        return String.valueOf(leftName).compareTo(String.valueOf(rightName));
      }
      return leftSequence < rightSequence ? -1 : 1;
    }
  }

  @InvocableMethod(
    label='Evaluate Onboarding Next Step'
    description='Evaluates next-step actions using overrides and metadata rules.'
  )
  public static List<Response> evaluate(List<Request> evaluationRequests) {
    List<Response> evaluationResponses = new List<Response>();
    if (evaluationRequests == null || evaluationRequests.isEmpty()) {
      return evaluationResponses;
    }

    Set<Id> onboardingIds = new Set<Id>();
    Set<Id> targetVendorProgramIds = new Set<Id>();
    Set<String> vendorProgramGroupKeys = new Set<String>();

    for (Request nextStepRequest : evaluationRequests) {
      if (nextStepRequest == null) {
        continue;
      }
      if (nextStepRequest.onboardingId != null) {
        onboardingIds.add(nextStepRequest.onboardingId);
      }
      if (nextStepRequest.targetVendorProgramId != null) {
        targetVendorProgramIds.add(nextStepRequest.targetVendorProgramId);
      }
      if (String.isNotBlank(nextStepRequest.vendorProgramGroupKey)) {
        vendorProgramGroupKeys.add(
          nextStepRequest.vendorProgramGroupKey.trim()
        );
      }
    }

    Map<String, OverrideDecision> overrideDecisionByKey = fetchOverrideDecisions(
      onboardingIds,
      targetVendorProgramIds
    );

    Map<String, List<NextStepRuleConfig>> rulesByScopeKey = fetchRuleConfigsByScopeKey(
      vendorProgramGroupKeys
    );

    Set<String> requiredFieldApiNames = collectRequiredFieldApiNames(
      rulesByScopeKey
    );

    Map<Id, Onboarding__c> onboardingRecordById = fetchOnboardingRecords(
      onboardingIds,
      requiredFieldApiNames
    );

    for (Request nextStepRequest : evaluationRequests) {
      Response evaluationResponse = new Response();
      evaluationResponse.onboardingId = nextStepRequest != null
        ? nextStepRequest.onboardingId
        : null;
      evaluationResponse.targetVendorProgramId = nextStepRequest != null
        ? nextStepRequest.targetVendorProgramId
        : null;
      evaluationResponse.action = ACTION_NONE;
      evaluationResponse.actionSource = ACTION_SOURCE_DEFAULT;

      if (
        nextStepRequest == null ||
        nextStepRequest.onboardingId == null ||
        nextStepRequest.targetVendorProgramId == null
      ) {
        evaluationResponses.add(evaluationResponse);
        continue;
      }

      String requestKey = buildRequestKey(
        nextStepRequest.onboardingId,
        nextStepRequest.targetVendorProgramId
      );

      OverrideDecision overrideDecision = overrideDecisionByKey.get(requestKey);
      if (
        overrideDecision != null && String.isNotBlank(overrideDecision.action)
      ) {
        evaluationResponse.action = normalizeActionValue(
          overrideDecision.action
        );
        evaluationResponse.actionSource = ACTION_SOURCE_OVERRIDE;
        evaluationResponse.matchedRuleName = String.valueOf(
          overrideDecision.overrideId
        );
        evaluationResponses.add(evaluationResponse);
        continue;
      }

      if (String.isBlank(nextStepRequest.vendorProgramGroupKey)) {
        evaluationResponses.add(evaluationResponse);
        continue;
      }

      List<NextStepRuleConfig> ruleConfigs = rulesByScopeKey.get(
        nextStepRequest.vendorProgramGroupKey.trim()
      );
      if (ruleConfigs == null || ruleConfigs.isEmpty()) {
        evaluationResponses.add(evaluationResponse);
        continue;
      }

      Onboarding__c onboardingRecord = onboardingRecordById.get(
        nextStepRequest.onboardingId
      );
      if (onboardingRecord == null) {
        evaluationResponses.add(evaluationResponse);
        continue;
      }

      NextStepRuleConfig matchingRule = findMatchingRule(
        onboardingRecord,
        ruleConfigs
      );
      if (matchingRule != null && String.isNotBlank(matchingRule.action)) {
        evaluationResponse.action = normalizeActionValue(matchingRule.action);
        evaluationResponse.actionSource = ACTION_SOURCE_RULE;
        evaluationResponse.matchedRuleName = matchingRule.developerName;
      }

      evaluationResponses.add(evaluationResponse);
    }

    return evaluationResponses;
  }

  private static Map<String, OverrideDecision> fetchOverrideDecisions(
    Set<Id> onboardingIds,
    Set<Id> targetVendorProgramIds
  ) {
    Map<String, OverrideDecision> overrideDecisionByKey = new Map<String, OverrideDecision>();
    if (
      onboardingIds == null ||
      onboardingIds.isEmpty() ||
      targetVendorProgramIds == null ||
      targetVendorProgramIds.isEmpty()
    ) {
      return overrideDecisionByKey;
    }

    if (
      !Schema.getGlobalDescribe()
        .containsKey('Onboarding_Next_Step_Override__c')
    ) {
      return overrideDecisionByKey;
    }

    String overrideQuery =
      'SELECT Id, Onboarding__c, Vendor_Program__c, Action__c, Active__c, Expires_On__c ' +
      'FROM Onboarding_Next_Step_Override__c ' +
      'WHERE Active__c = true ' +
      'AND Onboarding__c IN :onboardingIds ' +
      'AND Vendor_Program__c IN :targetVendorProgramIds ' +
      'AND (Expires_On__c = null OR Expires_On__c >= TODAY) ' +
      'ORDER BY CreatedDate DESC';

    List<SObject> overrideRecords = Database.query(overrideQuery);
    for (SObject overrideRecord : overrideRecords) {
      Id onboardingId = (Id) overrideRecord.get('Onboarding__c');
      Id targetProgramId = (Id) overrideRecord.get('Vendor_Program__c');
      String actionValue = (String) overrideRecord.get('Action__c');
      if (onboardingId == null || targetProgramId == null) {
        continue;
      }
      String requestKey = buildRequestKey(onboardingId, targetProgramId);
      if (!overrideDecisionByKey.containsKey(requestKey)) {
        OverrideDecision overrideDecision = new OverrideDecision();
        overrideDecision.action = actionValue;
        overrideDecision.overrideId = (Id) overrideRecord.get('Id');
        overrideDecisionByKey.put(requestKey, overrideDecision);
      }
    }

    return overrideDecisionByKey;
  }

  private static Map<String, List<NextStepRuleConfig>> fetchRuleConfigsByScopeKey(
    Set<String> vendorProgramGroupKeys
  ) {
    Map<String, List<NextStepRuleConfig>> rulesByScopeKey = new Map<String, List<NextStepRuleConfig>>();
    if (vendorProgramGroupKeys == null || vendorProgramGroupKeys.isEmpty()) {
      return rulesByScopeKey;
    }

    if (
      !Schema.getGlobalDescribe().containsKey('Onboarding_Next_Step_Rule__mdt')
    ) {
      return rulesByScopeKey;
    }

    String ruleQuery =
      'SELECT DeveloperName, MasterLabel, Scope_Key__c, Field_API_Name__c, Operator__c, Expected_Value__c, Action__c, Sequence__c ' +
      'FROM Onboarding_Next_Step_Rule__mdt ' +
      'WHERE Active__c = true ' +
      'AND Scope_Key__c IN :vendorProgramGroupKeys';

    List<SObject> ruleRecords = Database.query(ruleQuery);
    for (SObject ruleRecord : ruleRecords) {
      String scopeKey = (String) ruleRecord.get('Scope_Key__c');
      if (String.isBlank(scopeKey)) {
        continue;
      }
      NextStepRuleConfig ruleConfig = new NextStepRuleConfig();
      ruleConfig.developerName = (String) ruleRecord.get('DeveloperName');
      ruleConfig.scopeKey = scopeKey;
      ruleConfig.fieldApiName = (String) ruleRecord.get('Field_API_Name__c');
      ruleConfig.operatorValue = (String) ruleRecord.get('Operator__c');
      ruleConfig.expectedValue = (String) ruleRecord.get('Expected_Value__c');
      ruleConfig.action = (String) ruleRecord.get('Action__c');
      ruleConfig.sequence = parseSequenceValue(ruleRecord.get('Sequence__c'));

      if (!rulesByScopeKey.containsKey(scopeKey)) {
        rulesByScopeKey.put(scopeKey, new List<NextStepRuleConfig>());
      }
      rulesByScopeKey.get(scopeKey).add(ruleConfig);
    }

    NextStepRuleComparator ruleComparator = new NextStepRuleComparator();
    for (String scopeKey : rulesByScopeKey.keySet()) {
      rulesByScopeKey.get(scopeKey).sort(ruleComparator);
    }

    return rulesByScopeKey;
  }

  private static Decimal parseSequenceValue(Object sequenceValue) {
    if (sequenceValue == null) {
      return null;
    }
    try {
      return Decimal.valueOf(String.valueOf(sequenceValue));
    } catch (Exception ex) {
      return null;
    }
  }

  private static Set<String> collectRequiredFieldApiNames(
    Map<String, List<NextStepRuleConfig>> rulesByScopeKey
  ) {
    Set<String> requiredFieldApiNames = new Set<String>();
    if (rulesByScopeKey == null || rulesByScopeKey.isEmpty()) {
      return requiredFieldApiNames;
    }

    for (List<NextStepRuleConfig> ruleConfigs : rulesByScopeKey.values()) {
      for (NextStepRuleConfig ruleConfig : ruleConfigs) {
        if (String.isNotBlank(ruleConfig.fieldApiName)) {
          requiredFieldApiNames.add(ruleConfig.fieldApiName);
        }
      }
    }
    return requiredFieldApiNames;
  }

  private static Map<Id, Onboarding__c> fetchOnboardingRecords(
    Set<Id> onboardingIds,
    Set<String> extraFieldApiNames
  ) {
    Map<Id, Onboarding__c> onboardingRecordById = new Map<Id, Onboarding__c>();
    if (onboardingIds == null || onboardingIds.isEmpty()) {
      return onboardingRecordById;
    }

    List<Onboarding__c> onboardingRecords = OnboardingRulesRepository.fetchOnboardingsByIdsWithFields(
      onboardingIds,
      extraFieldApiNames
    );
    for (Onboarding__c onboardingRecord : onboardingRecords) {
      onboardingRecordById.put(onboardingRecord.Id, onboardingRecord);
    }
    return onboardingRecordById;
  }

  private static NextStepRuleConfig findMatchingRule(
    Onboarding__c onboardingRecord,
    List<NextStepRuleConfig> ruleConfigs
  ) {
    if (
      onboardingRecord == null ||
      ruleConfigs == null ||
      ruleConfigs.isEmpty()
    ) {
      return null;
    }

    for (NextStepRuleConfig ruleConfig : ruleConfigs) {
      if (ruleMatchesOnboarding(onboardingRecord, ruleConfig)) {
        return ruleConfig;
      }
    }
    return null;
  }

  private static Boolean ruleMatchesOnboarding(
    Onboarding__c onboardingRecord,
    NextStepRuleConfig ruleConfig
  ) {
    if (
      onboardingRecord == null ||
      ruleConfig == null ||
      String.isBlank(ruleConfig.fieldApiName)
    ) {
      return false;
    }

    if (!ONBOARDING_FIELD_MAP.containsKey(ruleConfig.fieldApiName)) {
      return false;
    }

    Object fieldValue = onboardingRecord.get(ruleConfig.fieldApiName);
    return compareFieldValue(
      fieldValue,
      ruleConfig.operatorValue,
      ruleConfig.expectedValue
    );
  }

  private static Boolean compareFieldValue(
    Object fieldValue,
    String operatorValue,
    String expectedValueList
  ) {
    String normalizedOperator = normalizeOperator(operatorValue);

    if (OPERATOR_IS_BLANK == normalizedOperator) {
      return String.isBlank(normalizeFieldValue(fieldValue));
    }

    if (OPERATOR_IS_NOT_BLANK == normalizedOperator) {
      return String.isNotBlank(normalizeFieldValue(fieldValue));
    }

    String normalizedFieldValue = normalizeFieldValue(fieldValue);
    if (String.isBlank(normalizedFieldValue)) {
      return false;
    }

    Set<String> expectedValueSet = parseExpectedValues(expectedValueList);
    if (expectedValueSet.isEmpty()) {
      return false;
    }

    if (OPERATOR_CONTAINS == normalizedOperator) {
      for (String expectedValue : expectedValueSet) {
        if (normalizedFieldValue.contains(expectedValue)) {
          return true;
        }
      }
      return false;
    }

    if (OPERATOR_NOT_EQUALS == normalizedOperator) {
      return !expectedValueSet.contains(normalizedFieldValue);
    }

    return expectedValueSet.contains(normalizedFieldValue);
  }

  private static Set<String> parseExpectedValues(String expectedValueList) {
    Set<String> expectedValueSet = new Set<String>();
    if (String.isBlank(expectedValueList)) {
      return expectedValueSet;
    }

    for (String value : expectedValueList.split(';')) {
      String trimmedValue = value.trim();
      if (String.isNotBlank(trimmedValue)) {
        expectedValueSet.add(trimmedValue);
      }
    }
    return expectedValueSet;
  }

  private static String normalizeFieldValue(Object fieldValue) {
    if (fieldValue == null) {
      return null;
    }
    if (fieldValue instanceof Boolean) {
      return ((Boolean) fieldValue) ? 'true' : 'false';
    }
    String fieldStringValue = String.valueOf(fieldValue);
    if (String.isBlank(fieldStringValue)) {
      return null;
    }
    return fieldStringValue.trim();
  }

  private static String normalizeOperator(String operatorValue) {
    if (String.isBlank(operatorValue)) {
      return OPERATOR_EQUALS;
    }

    String normalizedOperator = operatorValue.trim().toLowerCase();
    if (normalizedOperator == 'equals' || normalizedOperator == '=') {
      return OPERATOR_EQUALS;
    }
    if (
      normalizedOperator == 'notequals' ||
      normalizedOperator == '!=' ||
      normalizedOperator == '<>'
    ) {
      return OPERATOR_NOT_EQUALS;
    }
    if (normalizedOperator == 'contains') {
      return OPERATOR_CONTAINS;
    }
    if (normalizedOperator == 'isblank') {
      return OPERATOR_IS_BLANK;
    }
    if (normalizedOperator == 'isnotblank') {
      return OPERATOR_IS_NOT_BLANK;
    }
    if (normalizedOperator == 'in') {
      return OPERATOR_IN;
    }
    return OPERATOR_EQUALS;
  }

  private static String normalizeActionValue(String actionValue) {
    if (String.isBlank(actionValue)) {
      return ACTION_NONE;
    }
    return actionValue.trim();
  }

  private static String buildRequestKey(Id onboardingId, Id targetProgramId) {
    return String.valueOf(onboardingId) + ':' + String.valueOf(targetProgramId);
  }
}
