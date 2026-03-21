/**
 * Service for evaluating Onboarding Status based on requirement statuses and CMDT rules.
 * Uses Onboarding_Status_Normalization__mdt for per-requirement status and
 * Onboarding_Status_Evaluation_Rule__mdt for evaluation rules.
 */
public with sharing class OnboardingStatusEvaluatorService {
  private static final String IGNORE = 'Ignore';
  private static final String DENIED = 'Denied';
  private static final String CANCELED = 'Canceled';
  private static final String CANCELLED = 'Cancelled';
  private static final String EXPIRED = 'Expired';
  private static final String SETUP_COMPLETE = 'Setup Complete';
  private static final String OUT_FOR_SIGNATURE = 'Out for signature';
  private static final String SIGNED = 'Signed';
  private static final String COMPLETE = 'Complete';
  private static final String AGREEMENT = 'Agreement';
  private static final String CONTRACT = 'Contract';
  private static final String SALES = 'Sales';

  public class EvaluationContext {
    public Onboarding__c onboarding;
    public Opportunity opportunity;
    public List<RequirementInfo> requirements;
    public Map<String, String> normalizedByReqType;
  }

  public class RequirementInfo {
    public Id id;
    public String requirementType;
    public String status;
    public String normalizedStatus;
    public Boolean isOverridden;
  }

  public class EvaluationResult {
    public String targetOnboardingStatus;
    public String targetOpportunityStage;
    public Boolean shouldUpdate;
  }

  /**
   * Evaluate onboarding status and return target status/stage.
   * Rules are evaluated in Rule_Order__c; first match wins.
   */
  public static EvaluationResult evaluate(Id onboardingId) {
    if (onboardingId == null) {
      return emptyResult();
    }
    Map<Id, EvaluationResult> resultsById = evaluateBulk(new Set<Id>{ onboardingId });
    if (!resultsById.containsKey(onboardingId)) {
      return emptyResult();
    }
    return resultsById.get(onboardingId);
  }

  /**
   * Bulk evaluate onboarding status for a set of onboarding ids.
   */
  public static Map<Id, EvaluationResult> evaluateBulk(Set<Id> onboardingIds) {
    Map<Id, EvaluationResult> resultsById = new Map<Id, EvaluationResult>();
    if (onboardingIds == null || onboardingIds.isEmpty()) {
      return resultsById;
    }

    Map<Id, EvaluationContext> contextByOnboardingId = loadContexts(onboardingIds);
    List<Onboarding_Status_Evaluation_Rule__mdt> rules = [
      SELECT Condition_Type__c, Target_Onboarding_Status__c, Target_Opportunity_Stage__c
      FROM Onboarding_Status_Evaluation_Rule__mdt
      WHERE Is_Active__c = true
      ORDER BY Rule_Order__c ASC
    ];

    for (Id onboardingId : onboardingIds) {
      EvaluationContext ctx = contextByOnboardingId.get(onboardingId);
      if (ctx == null) {
        resultsById.put(onboardingId, emptyResult());
        continue;
      }

      EvaluationResult matched = null;
      for (Onboarding_Status_Evaluation_Rule__mdt rule : rules) {
        if (evaluateCondition(rule.Condition_Type__c, ctx)) {
          matched = new EvaluationResult();
          matched.targetOnboardingStatus = rule.Target_Onboarding_Status__c;
          matched.targetOpportunityStage = rule.Target_Opportunity_Stage__c;
          matched.shouldUpdate = true;
          break;
        }
      }

      resultsById.put(onboardingId, matched == null ? emptyResult() : matched);
    }

    return resultsById;
  }

  /**
   * Evaluate and apply: update Onboarding and Opportunity if needed.
   */
  public static EvaluationResult evaluateAndApply(Id onboardingId) {
    if (onboardingId == null) {
      return emptyResult();
    }

    Map<Id, EvaluationResult> resultsById = evaluateAndApplyBulk(new Set<Id>{ onboardingId });
    if (!resultsById.containsKey(onboardingId)) {
      return emptyResult();
    }
    return resultsById.get(onboardingId);
  }

  /**
   * Bulk evaluate and apply: update Onboarding and Opportunity where needed.
   */
  public static Map<Id, EvaluationResult> evaluateAndApplyBulk(Set<Id> onboardingIds) {
    Map<Id, EvaluationResult> resultsById = evaluateBulk(onboardingIds);
    if (resultsById.isEmpty()) {
      return resultsById;
    }

    Set<Id> evaluableOnboardingIds = new Set<Id>();
    for (Id onboardingId : resultsById.keySet()) {
      EvaluationResult result = resultsById.get(onboardingId);
      if (
        result != null &&
        result.shouldUpdate == true &&
        String.isNotBlank(result.targetOnboardingStatus)
      ) {
        evaluableOnboardingIds.add(onboardingId);
      }
    }

    if (evaluableOnboardingIds.isEmpty()) {
      return resultsById;
    }

    Map<Id, Onboarding__c> onboardingById = new Map<Id, Onboarding__c>([
      SELECT Id, Onboarding_Status__c, Opportunity__c
      FROM Onboarding__c
      WHERE Id IN :evaluableOnboardingIds
      WITH SECURITY_ENFORCED
    ]);

    Map<Id, String> targetStageByOpportunityId = new Map<Id, String>();
    Map<Id, Onboarding__c> onboardingUpdatesById = new Map<Id, Onboarding__c>();

    for (Id onboardingId : evaluableOnboardingIds) {
      EvaluationResult result = resultsById.get(onboardingId);
      Onboarding__c existingOnboarding = onboardingById.get(onboardingId);
      if (existingOnboarding == null) {
        continue;
      }

      if (existingOnboarding.Onboarding_Status__c != result.targetOnboardingStatus) {
        onboardingUpdatesById.put(
          onboardingId,
          new Onboarding__c(
            Id = onboardingId,
            Onboarding_Status__c = result.targetOnboardingStatus
          )
        );
      }

      if (
        String.isNotBlank(result.targetOpportunityStage) &&
        existingOnboarding.Opportunity__c != null &&
        !targetStageByOpportunityId.containsKey(existingOnboarding.Opportunity__c)
      ) {
        targetStageByOpportunityId.put(
          existingOnboarding.Opportunity__c,
          result.targetOpportunityStage
        );
      }
    }

    Map<Id, Opportunity> opportunityUpdatesById = new Map<Id, Opportunity>();
    if (!targetStageByOpportunityId.isEmpty()) {
      for (Opportunity existingOpportunity : [
        SELECT Id, StageName
        FROM Opportunity
        WHERE Id IN :targetStageByOpportunityId.keySet()
        WITH SECURITY_ENFORCED
      ]) {
        String targetStage = targetStageByOpportunityId.get(existingOpportunity.Id);
        if (
          String.isNotBlank(targetStage) &&
          existingOpportunity.StageName != targetStage
        ) {
          opportunityUpdatesById.put(
            existingOpportunity.Id,
            new Opportunity(
              Id = existingOpportunity.Id,
              StageName = targetStage
            )
          );
        }
      }
    }

    List<SObject> toUpdate = new List<SObject>();
    toUpdate.addAll(onboardingUpdatesById.values());
    toUpdate.addAll(opportunityUpdatesById.values());

    if (!toUpdate.isEmpty()) {
      update as user toUpdate;
    }

    return resultsById;
  }

  private static EvaluationContext loadContext(Id onboardingId) {
    if (onboardingId == null) {
      return null;
    }
    Map<Id, EvaluationContext> contexts = loadContexts(new Set<Id>{ onboardingId });
    return contexts.get(onboardingId);
  }

  private static Map<Id, EvaluationContext> loadContexts(Set<Id> onboardingIds) {
    Map<Id, EvaluationContext> contextByOnboardingId = new Map<Id, EvaluationContext>();
    if (onboardingIds == null || onboardingIds.isEmpty()) {
      return contextByOnboardingId;
    }

    Map<Id, Onboarding__c> onboardingById = new Map<Id, Onboarding__c>([
      SELECT Id, Onboarding_Status__c, Assigned_Team__c, Opportunity__c
      FROM Onboarding__c
      WHERE Id IN :onboardingIds
      WITH SECURITY_ENFORCED
    ]);
    if (onboardingById.isEmpty()) {
      return contextByOnboardingId;
    }

    Set<Id> opportunityIds = new Set<Id>();
    for (Onboarding__c onboarding : onboardingById.values()) {
      if (onboarding.Opportunity__c != null) {
        opportunityIds.add(onboarding.Opportunity__c);
      }
    }

    Map<Id, Opportunity> opportunityById = new Map<Id, Opportunity>();
    if (!opportunityIds.isEmpty()) {
      opportunityById = new Map<Id, Opportunity>([
        SELECT Id, StageName, IsClosed, IsWon
        FROM Opportunity
        WHERE Id IN :opportunityIds
        WITH SECURITY_ENFORCED
      ]);
    }

    Map<String, String> normMap = loadNormalizationMap();

    for (Onboarding__c onboarding : onboardingById.values()) {
      EvaluationContext ctx = new EvaluationContext();
      ctx.onboarding = onboarding;
      ctx.opportunity = onboarding.Opportunity__c == null
        ? null
        : opportunityById.get(onboarding.Opportunity__c);
      ctx.requirements = new List<RequirementInfo>();
      ctx.normalizedByReqType = new Map<String, String>();
      contextByOnboardingId.put(onboarding.Id, ctx);
    }

    for (Onboarding_Requirement__c r : [
      SELECT Id, Onboarding__c, Requirement_Type__c, Status__c, Is_Overridden__c
      FROM Onboarding_Requirement__c
      WHERE Onboarding__c IN :contextByOnboardingId.keySet()
      WITH SECURITY_ENFORCED
    ]) {
      EvaluationContext ctx = contextByOnboardingId.get(r.Onboarding__c);
      if (ctx == null) {
        continue;
      }

      RequirementInfo ri = new RequirementInfo();
      ri.id = r.Id;
      ri.requirementType = r.Requirement_Type__c;
      ri.status = r.Status__c;
      ri.isOverridden = r.Is_Overridden__c == true;
      String key = keyFor(r.Requirement_Type__c, r.Status__c);
      ri.normalizedStatus = normMap.get(key);
      if (ri.normalizedStatus == null) {
        ri.normalizedStatus = r.Status__c;
      }
      ctx.requirements.add(ri);
      ctx.normalizedByReqType.put(r.Requirement_Type__c, ri.normalizedStatus);
    }

    return contextByOnboardingId;
  }

  private static Map<String, String> loadNormalizationMap() {
    Map<String, String> m = new Map<String, String>();
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

  private static String keyFor(String reqType, String status) {
    return (reqType == null ? '' : reqType) +
      '|' +
      (status == null ? '' : status);
  }

  private static Boolean evaluateCondition(String conditionType, EvaluationContext ctx) {
    if (String.isBlank(conditionType)) {
      return false;
    }

    switch on conditionType {
      when 'ANY_DENIED' {
        return hasAnyNormalized(ctx, DENIED);
      }
      when 'ALL_SETUP_COMPLETE' {
        return allRequirementsSetupComplete(ctx);
      }
      when 'ANY_CANCELED' {
        return hasAnyCanceled(ctx);
      }
      when 'ANY_EXPIRED' {
        return hasAnyNormalized(ctx, EXPIRED);
      }
      when 'ONLY_AGREEMENT_OUT_FOR_SIGNATURE' {
        return onlyAgreementHasStatus(ctx, OUT_FOR_SIGNATURE);
      }
      when 'ONLY_AGREEMENT_SIGNED' {
        return onlyAgreementHasStatus(ctx, SIGNED) ||
          onlyAgreementHasStatus(ctx, SETUP_COMPLETE);
      }
      when 'AGREEMENT_SIGNED_AND_CONTRACT_COMPLETE' {
        return agreementSignedAndContractComplete(ctx);
      }
      when 'PENDING_SALES' {
        return !hasAnyNormalized(ctx, DENIED) &&
          !allRequirementsSetupComplete(ctx) &&
          SALES.equals(ctx.onboarding.Assigned_Team__c);
      }
      when 'IN_PROCESS_DEFAULT' {
        return !hasAnyNormalized(ctx, DENIED) && !allRequirementsSetupComplete(ctx);
      }
      when 'OPPORTUNITY_CANCELED' {
        return ctx.opportunity != null &&
          isCanceledStage(ctx.opportunity.StageName);
      }
      when else {
        return false;
      }
    }
  }

  @TestVisible
  private static Boolean evaluateConditionForTest(
    String conditionType,
    EvaluationContext ctx
  ) {
    return evaluateCondition(conditionType, ctx);
  }

  private static Boolean hasAnyNormalized(EvaluationContext ctx, String status) {
    for (RequirementInfo r : ctx.requirements) {
      if (status.equalsIgnoreCase(r.normalizedStatus)) {
        return true;
      }
    }
    return false;
  }

  private static Boolean hasAnyCanceled(EvaluationContext ctx) {
    if (
      !hasAnyNormalized(ctx, CANCELED) &&
      !hasAnyNormalized(ctx, CANCELLED)
    ) {
      return false;
    }

    // Cancellation can be cleared by reopening/changing Opportunity stage.
    return ctx.opportunity == null || isCanceledStage(ctx.opportunity.StageName);
  }

  private static Boolean allRequirementsSetupComplete(EvaluationContext ctx) {
    if (ctx.requirements.isEmpty()) {
      return false;
    }
    for (RequirementInfo r : ctx.requirements) {
      String n = r.normalizedStatus;
      if (n == null || n == '') {
        return false;
      }
      if (
        !SETUP_COMPLETE.equalsIgnoreCase(n) &&
        !IGNORE.equalsIgnoreCase(n) &&
        !SIGNED.equalsIgnoreCase(n) &&
        !COMPLETE.equalsIgnoreCase(n)
      ) {
        return false;
      }
    }
    return true;
  }

  private static Boolean onlyAgreementHasStatus(EvaluationContext ctx, String status) {
    Boolean agreementHas = false;
    for (RequirementInfo r : ctx.requirements) {
      if (AGREEMENT.equalsIgnoreCase(r.requirementType)) {
        if (status.equalsIgnoreCase(r.normalizedStatus)) {
          agreementHas = true;
        } else {
          return false;
        }
      } else {
        String n = r.normalizedStatus;
        if (n != null && n != '' && !IGNORE.equalsIgnoreCase(n)) {
          return false;
        }
      }
    }
    return agreementHas;
  }

  private static Boolean agreementSignedAndContractComplete(EvaluationContext ctx) {
    String agreementNorm = ctx.normalizedByReqType.get(AGREEMENT);
    String contractNorm = ctx.normalizedByReqType.get(CONTRACT);
    if (
      agreementNorm == null ||
      (!SIGNED.equalsIgnoreCase(agreementNorm) &&
        !SETUP_COMPLETE.equalsIgnoreCase(agreementNorm))
    ) {
      return false;
    }
    if (
      contractNorm == null ||
      (!COMPLETE.equalsIgnoreCase(contractNorm) &&
        !SETUP_COMPLETE.equalsIgnoreCase(contractNorm))
    ) {
      return false;
    }
    for (RequirementInfo r : ctx.requirements) {
      if (AGREEMENT.equalsIgnoreCase(r.requirementType) ||
        CONTRACT.equalsIgnoreCase(r.requirementType)) {
        continue;
      }
      String n = r.normalizedStatus;
      if (n != null && n != '' && !IGNORE.equalsIgnoreCase(n)) {
        return false;
      }
    }
    return true;
  }

  private static Boolean isCanceledStage(String stage) {
    return stage != null &&
      (
        stage.equalsIgnoreCase('Canceled') ||
        stage.equalsIgnoreCase('Cancelled') ||
        stage.equalsIgnoreCase('Closed Lost')
      );
  }

  private static EvaluationResult emptyResult() {
    EvaluationResult result = new EvaluationResult();
    result.shouldUpdate = false;
    return result;
  }
}
