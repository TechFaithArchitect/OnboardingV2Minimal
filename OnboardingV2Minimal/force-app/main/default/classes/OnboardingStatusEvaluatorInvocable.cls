/**
 * Invocable action to evaluate and optionally apply Onboarding Status based on CMDT rules.
 * Called from BLL_Onboarding_Requirement_RCD_Logical_Process when requirement status changes.
 */
public with sharing class OnboardingStatusEvaluatorInvocable {
  public class EvaluateRequest {
    @InvocableVariable(label='Onboarding Record Id' description='Id of the Onboarding__c record to evaluate')
    public Id onboardingId;

    @InvocableVariable(label='Onboarding Record Ids' description='Optional collection of Onboarding__c record ids to evaluate in one request.')
    public List<String> onboardingIds;

    @InvocableVariable(label='Apply Updates' description='If true, updates Onboarding and Opportunity. If false, returns target status only.')
    public Boolean applyUpdates;
  }

  public class EvaluateResult {
    @InvocableVariable(label='Target Onboarding Status')
    public String targetOnboardingStatus;

    @InvocableVariable(label='Target Opportunity Stage')
    public String targetOpportunityStage;

    @InvocableVariable(label='Should Update')
    public Boolean shouldUpdate;

    @InvocableVariable(
      label='Matched Rule Developer Name'
      description='Onboarding_Status_Evaluation_Rule__mdt.DeveloperName for the first rule whose predicate matched (blank if none).'
    )
    public String matchedRuleDeveloperName;

    @InvocableVariable(
      label='Matched Rule Order'
      description='Rule_Order__c of the matched rule (blank if none). Use with Developer Name to debug why a status was chosen.'
    )
    public String matchedRuleOrder;

    @InvocableVariable(label='Error Message')
    public String errorMessage;
  }

  @InvocableMethod(
    label='Evaluate Onboarding Status'
    description='Evaluates Onboarding Status from requirement statuses using Onboarding_Status_Evaluation_Rule__mdt. Optionally applies updates to Onboarding and Opportunity.'
  )
  public static List<EvaluateResult> evaluate(List<EvaluateRequest> requests) {
    List<EvaluateResult> results = new List<EvaluateResult>();
    if (requests == null || requests.isEmpty()) {
      results.add(new EvaluateResult());
      return results;
    }

    try {
      List<Set<Id>> requestIds = new List<Set<Id>>();
      List<Boolean> requestApplyFlags = new List<Boolean>();
      Set<Id> applyIds = new Set<Id>();
      Set<Id> evaluateOnlyIds = new Set<Id>();

      for (EvaluateRequest req : requests) {
        Set<Id> ids = parseOnboardingIds(req);
        requestIds.add(ids);

        Boolean shouldApplyUpdates = req != null && req.applyUpdates == true;
        requestApplyFlags.add(shouldApplyUpdates);
        if (shouldApplyUpdates) {
          applyIds.addAll(ids);
        } else {
          evaluateOnlyIds.addAll(ids);
        }
      }

      Map<Id, OnboardingStatusEvaluatorService.EvaluationResult> evaluateOnlyById = evaluateOnlyIds.isEmpty()
        ? new Map<Id, OnboardingStatusEvaluatorService.EvaluationResult>()
        : OnboardingStatusEvaluatorService.evaluateBulk(evaluateOnlyIds);
      Map<Id, OnboardingStatusEvaluatorService.EvaluationResult> applyById = applyIds.isEmpty()
        ? new Map<Id, OnboardingStatusEvaluatorService.EvaluationResult>()
        : OnboardingStatusEvaluatorService.evaluateAndApplyBulk(applyIds);

      for (Integer i = 0; i < requests.size(); i++) {
        EvaluateResult res = new EvaluateResult();
        Set<Id> ids = requestIds[i];
        if (ids.isEmpty()) {
          res.errorMessage = 'Onboarding Record Id is required.';
          results.add(res);
          continue;
        }

        Map<Id, OnboardingStatusEvaluatorService.EvaluationResult> sourceById = requestApplyFlags[i]
          ? applyById
          : evaluateOnlyById;

        if (ids.size() == 1) {
          Id onboardingId = ids.iterator().next();
          OnboardingStatusEvaluatorService.EvaluationResult eval = sourceById.get(onboardingId);
          if (eval == null) {
            res.errorMessage = 'Onboarding Record Id was not found: ' + onboardingId;
          } else {
            res.errorMessage = '';
            res.targetOnboardingStatus = eval.targetOnboardingStatus;
            res.targetOpportunityStage = eval.targetOpportunityStage;
            res.shouldUpdate = eval.shouldUpdate;
            res.matchedRuleDeveloperName = eval.matchedRuleDeveloperName;
            res.matchedRuleOrder = eval.matchedRuleOrder;
          }
          results.add(res);
          continue;
        }

        Boolean anyShouldUpdate = false;
        for (Id onboardingId : ids) {
          OnboardingStatusEvaluatorService.EvaluationResult eval = sourceById.get(onboardingId);
          if (eval == null) {
            continue;
          }
          anyShouldUpdate = anyShouldUpdate || eval.shouldUpdate == true;
        }

        res.errorMessage = '';
        res.shouldUpdate = anyShouldUpdate;
        results.add(res);
      }
    } catch (Exception ex) {
      LoggingUtil.error(
        'OnboardingStatusEvaluatorInvocable.evaluate failed: ' +
        ex.getStackTraceString()
      );
      for (Integer i = 0; i < requests.size(); i++) {
        EvaluateResult res = new EvaluateResult();
        res.errorMessage = 'Evaluation failed: ' + ex.getMessage();
        results.add(res);
      }
    }

    return results;
  }

  private static Set<Id> parseOnboardingIds(EvaluateRequest req) {
    Set<Id> ids = new Set<Id>();
    if (req == null) {
      return ids;
    }

    if (req.onboardingId != null) {
      ids.add(req.onboardingId);
    }

    if (req.onboardingIds == null) {
      return ids;
    }

    for (String rawId : req.onboardingIds) {
      Id parsedId = tryParseId(rawId);
      if (parsedId != null) {
        ids.add(parsedId);
      }
    }
    return ids;
  }

  private static Id tryParseId(String rawId) {
    if (String.isBlank(rawId)) {
      return null;
    }

    try {
      return (Id)rawId.trim();
    } catch (Exception ignored) {
      return null;
    }
  }
}
