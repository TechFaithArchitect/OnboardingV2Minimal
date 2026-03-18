/**
 * Service for evaluating Onboarding Status based on requirement statuses and CMDT rules.
 * Uses Onboarding_Status_Normalization__mdt for per-requirement status and
 * Onboarding_Status_Evaluation_Rule__mdt for evaluation rules.
 */
public with sharing class OnboardingStatusEvaluatorService {
  private static final String IGNORE = 'Ignore';
  private static final String DENIED = 'Denied';
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
      return new EvaluationResult();
    }
    EvaluationContext ctx = loadContext(onboardingId);
    if (ctx == null) {
      return new EvaluationResult();
    }

    List<Onboarding_Status_Evaluation_Rule__mdt> rules = [
      SELECT Condition_Type__c, Target_Onboarding_Status__c, Target_Opportunity_Stage__c
      FROM Onboarding_Status_Evaluation_Rule__mdt
      WHERE Is_Active__c = true
      ORDER BY Rule_Order__c ASC
    ];

    for (Onboarding_Status_Evaluation_Rule__mdt rule : rules) {
      if (evaluateCondition(rule.Condition_Type__c, ctx)) {
        EvaluationResult r = new EvaluationResult();
        r.targetOnboardingStatus = rule.Target_Onboarding_Status__c;
        r.targetOpportunityStage = rule.Target_Opportunity_Stage__c;
        r.shouldUpdate = true;
        return r;
      }
    }

    return new EvaluationResult();
  }

  /**
   * Evaluate and apply: update Onboarding and Opportunity if needed.
   */
  public static EvaluationResult evaluateAndApply(Id onboardingId) {
    EvaluationResult result = evaluate(onboardingId);
    if (!result.shouldUpdate || String.isBlank(result.targetOnboardingStatus)) {
      return result;
    }

    Onboarding__c onb = [
      SELECT Id, Onboarding_Status__c, Opportunity__c
      FROM Onboarding__c
      WHERE Id = :onboardingId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];

    List<SObject> toUpdate = new List<SObject>();

    if (onb.Onboarding_Status__c != result.targetOnboardingStatus) {
      onb.Onboarding_Status__c = result.targetOnboardingStatus;
      toUpdate.add(onb);
    }

    if (
      String.isNotBlank(result.targetOpportunityStage) &&
      onb.Opportunity__c != null
    ) {
      Opportunity opp = [
        SELECT Id, StageName
        FROM Opportunity
        WHERE Id = :onb.Opportunity__c
        WITH SECURITY_ENFORCED
        LIMIT 1
      ];
      if (opp.StageName != result.targetOpportunityStage) {
        opp.StageName = result.targetOpportunityStage;
        toUpdate.add(opp);
      }
    }

    if (!toUpdate.isEmpty()) {
      update as user toUpdate;
    }

    return result;
  }

  private static EvaluationContext loadContext(Id onboardingId) {
    List<Onboarding__c> onbs = [
      SELECT Id, Onboarding_Status__c, Assigned_Team__c, Opportunity__c
      FROM Onboarding__c
      WHERE Id = :onboardingId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    if (onbs.isEmpty()) {
      return null;
    }

    Onboarding__c onb = onbs[0];
    EvaluationContext ctx = new EvaluationContext();
    ctx.onboarding = onb;

    if (onb.Opportunity__c != null) {
      List<Opportunity> opps = [
        SELECT Id, StageName, IsClosed, IsWon
        FROM Opportunity
        WHERE Id = :onb.Opportunity__c
        WITH SECURITY_ENFORCED
        LIMIT 1
      ];
      if (!opps.isEmpty()) {
        ctx.opportunity = opps[0];
      }
    }

    List<Onboarding_Requirement__c> reqs = [
      SELECT Id, Requirement_Type__c, Status__c, Is_Overridden__c
      FROM Onboarding_Requirement__c
      WHERE Onboarding__c = :onboardingId
      WITH SECURITY_ENFORCED
    ];

    Map<String, String> normMap = loadNormalizationMap();
    ctx.requirements = new List<RequirementInfo>();
    ctx.normalizedByReqType = new Map<String, String>();

    for (Onboarding_Requirement__c r : reqs) {
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

    return ctx;
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
      when 'HAS_REQUIREMENTS_NOT_ALL_SETUP_COMPLETE' {
        return hasRequirements(ctx) && !allRequirementsSetupComplete(ctx);
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
      when 'OPPORTUNITY_UNCANCELED' {
        return ctx.opportunity != null &&
          !isCanceledStage(ctx.opportunity.StageName) &&
          ctx.onboarding.Onboarding_Status__c == 'Canceled';
      }
      when else {
        return false;
      }
    }
  }

  private static Boolean hasAnyNormalized(EvaluationContext ctx, String status) {
    for (RequirementInfo r : ctx.requirements) {
      if (status.equalsIgnoreCase(r.normalizedStatus)) {
        return true;
      }
    }
    return false;
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

  private static Boolean hasRequirements(EvaluationContext ctx) {
    return !ctx.requirements.isEmpty();
  }

  private static Boolean isCanceledStage(String stage) {
    return stage != null &&
      (stage.equalsIgnoreCase('Canceled') || stage.equalsIgnoreCase('Closed Lost'));
  }
}
