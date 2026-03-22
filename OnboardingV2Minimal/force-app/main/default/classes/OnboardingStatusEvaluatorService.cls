/**
 * Orchestrates onboarding status evaluation: loads context, applies normalization (CMDT),
 * runs rules via IOnboardingStatusRuleEngine (default: JSON Predicate_Config__c on evaluation CMDT).
 */
public with sharing class OnboardingStatusEvaluatorService {
  @TestVisible
  private static IOnboardingStatusRuleEngine ruleEngine = new OnboardingStatusCmdtRuleEngine();

  @TestVisible
  static void setRuleEngineForTest(IOnboardingStatusRuleEngine engine) {
    ruleEngine = engine == null ? new OnboardingStatusCmdtRuleEngine() : engine;
  }

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

  public static Map<Id, EvaluationResult> evaluateBulk(Set<Id> onboardingIds) {
    Map<Id, EvaluationResult> resultsById = new Map<Id, EvaluationResult>();
    if (onboardingIds == null || onboardingIds.isEmpty()) {
      return resultsById;
    }

    Map<Id, EvaluationContext> contextByOnboardingId = loadContexts(onboardingIds);
    List<Onboarding_Status_Evaluation_Rule__mdt> rules = [
      SELECT
        DeveloperName,
        Predicate_Config__c,
        Target_Onboarding_Status__c,
        Target_Opportunity_Stage__c
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
        if (ruleEngine.ruleApplies(rule, ctx)) {
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

    Map<String, String> normMap = OnboardingStatusNormalizationService.loadActiveNormalizationMap();

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
      ri.normalizedStatus = OnboardingStatusNormalizationService.normalize(
        r.Requirement_Type__c,
        r.Status__c,
        normMap
      );
      ctx.requirements.add(ri);
      ctx.normalizedByReqType.put(r.Requirement_Type__c, ri.normalizedStatus);
    }

    return contextByOnboardingId;
  }

  private static EvaluationResult emptyResult() {
    EvaluationResult result = new EvaluationResult();
    result.shouldUpdate = false;
    return result;
  }
}
