/**
 * Evaluates Onboarding_Status_Evaluation_Rule__mdt.Predicate_Config__c (JSON) against EvaluationContext.
 * Composable: { "all": [...] }, { "any": [...] }, or { "op": "...", ... }.
 * Blank or invalid JSON does not match (rules must ship Predicate_Config__c).
 */
public with sharing class OnboardingStatusPredicateInterpreter {
  private static final String IGNORE = 'Ignore';
  private static final String DENIED = 'Denied';
  private static final String CANCELED = 'Canceled';
  private static final String CANCELLED = 'Cancelled';
  private static final String EXPIRED = 'Expired';
  private static final String SETUP_COMPLETE = 'Setup Complete';
  private static final String SIGNED = 'Signed';
  private static final String COMPLETE = 'Complete';
  private static final String AGREEMENT = 'Agreement';
  private static final String CONTRACT = 'Contract';

  public static Boolean ruleMatchesRule(
    Onboarding_Status_Evaluation_Rule__mdt rule,
    OnboardingStatusEvaluatorService.EvaluationContext ctx
  ) {
    if (ctx == null) {
      return false;
    }
    if (String.isBlank(rule.Predicate_Config__c)) {
      LoggingUtil.warn(
        'OnboardingStatusPredicateInterpreter: Predicate_Config__c is blank for rule ' +
        rule.DeveloperName +
        '; rule will not match.'
      );
      return false;
    }
    try {
      Object root = JSON.deserializeUntyped(rule.Predicate_Config__c.trim());
      return evaluateNode(root, ctx);
    } catch (Exception ex) {
      LoggingUtil.error(
        'OnboardingStatusPredicateInterpreter invalid Predicate_Config__c: ' +
        ex.getMessage()
      );
      return false;
    }
  }

  public static Boolean evaluateNode(Object node, OnboardingStatusEvaluatorService.EvaluationContext ctx) {
    if (node == null) {
      return false;
    }
    if (!(node instanceof Map<String, Object>)) {
      return false;
    }
    Map<String, Object> m = (Map<String, Object>) node;

    if (m.containsKey('all')) {
      Object arrObj = m.get('all');
      if (!(arrObj instanceof List<Object>)) {
        return false;
      }
      for (Object child : (List<Object>) arrObj) {
        if (!evaluateNode(child, ctx)) {
          return false;
        }
      }
      return true;
    }

    if (m.containsKey('any')) {
      Object arrObj = m.get('any');
      if (!(arrObj instanceof List<Object>)) {
        return false;
      }
      for (Object child : (List<Object>) arrObj) {
        if (evaluateNode(child, ctx)) {
          return true;
        }
      }
      return false;
    }

    return evaluateOp(m, ctx);
  }

  private static Boolean evaluateOp(
    Map<String, Object> m,
    OnboardingStatusEvaluatorService.EvaluationContext ctx
  ) {
    String op = stringVal(m.get('op'));
    if (String.isBlank(op)) {
      return false;
    }

    switch on op.trim().toLowerCase() {
      when 'reqanynormalizedequals' {
        return hasAnyNormalized(ctx, stringVal(m.get('normalized')));
      }
      when 'notreqanynormalizedequals' {
        return !hasAnyNormalized(ctx, stringVal(m.get('normalized')));
      }
      when 'allrequirementsterminal' {
        return allRequirementsSetupComplete(ctx);
      }
      when 'notallrequirementsterminal' {
        return !allRequirementsSetupComplete(ctx);
      }
      when 'anyrequirementcanceledwithstagegate' {
        return hasAnyCanceled(ctx);
      }
      when 'onlyrequirementtypenormalizedinset' {
        return onlyRequirementTypeNormalizedInSet(
          ctx,
          stringVal(m.get('requirementType')),
          stringList(m.get('allowedNormalized'))
        );
      }
      when 'agreementandcontractcompleteothersignored' {
        return agreementSignedAndContractComplete(ctx);
      }
      when 'assignedteamequals' {
        String team = stringVal(m.get('team'));
        return ctx.onboarding != null &&
          String.isNotBlank(team) &&
          team.equalsIgnoreCase(ctx.onboarding.Assigned_Team__c);
      }
      when 'opportunitystagecanceled' {
        return ctx.opportunity != null &&
          isCanceledStage(ctx.opportunity.StageName);
      }
      when else {
        return false;
      }
    }
  }

  private static String stringVal(Object o) {
    return o == null ? null : String.valueOf(o).trim();
  }

  private static List<String> stringList(Object o) {
    List<String> out = new List<String>();
    if (o instanceof List<Object>) {
      for (Object x : (List<Object>) o) {
        String s = stringVal(x);
        if (String.isNotBlank(s)) {
          out.add(s);
        }
      }
    }
    return out;
  }

  private static Boolean onlyRequirementTypeNormalizedInSet(
    OnboardingStatusEvaluatorService.EvaluationContext ctx,
    String requirementType,
    List<String> allowedNormalized
  ) {
    if (String.isBlank(requirementType) || allowedNormalized == null || allowedNormalized.isEmpty()) {
      return false;
    }
    List<String> typeNorms = new List<String>();
    for (OnboardingStatusEvaluatorService.RequirementInfo r : ctx.requirements) {
      if (requirementType.equalsIgnoreCase(r.requirementType)) {
        typeNorms.add(r.normalizedStatus);
      } else {
        String n = r.normalizedStatus;
        if (n != null && n != '' && !IGNORE.equalsIgnoreCase(n)) {
          return false;
        }
      }
    }
    if (typeNorms.isEmpty()) {
      return false;
    }
    String first = typeNorms[0];
    if (String.isBlank(first)) {
      return false;
    }
    Boolean inSet = false;
    for (String allowed : allowedNormalized) {
      if (first.equalsIgnoreCase(allowed)) {
        inSet = true;
        break;
      }
    }
    if (!inSet) {
      return false;
    }
    for (String n : typeNorms) {
      if (n == null || !n.equalsIgnoreCase(first)) {
        return false;
      }
    }
    return true;
  }

  private static Boolean hasAnyNormalized(
    OnboardingStatusEvaluatorService.EvaluationContext ctx,
    String status
  ) {
    if (String.isBlank(status)) {
      return false;
    }
    for (OnboardingStatusEvaluatorService.RequirementInfo r : ctx.requirements) {
      if (status.equalsIgnoreCase(r.normalizedStatus)) {
        return true;
      }
    }
    return false;
  }

  private static Boolean hasAnyCanceled(OnboardingStatusEvaluatorService.EvaluationContext ctx) {
    if (
      !hasAnyNormalized(ctx, CANCELED) &&
      !hasAnyNormalized(ctx, CANCELLED)
    ) {
      return false;
    }
    return ctx.opportunity == null || isCanceledStage(ctx.opportunity.StageName);
  }

  private static Boolean allRequirementsSetupComplete(
    OnboardingStatusEvaluatorService.EvaluationContext ctx
  ) {
    if (ctx.requirements.isEmpty()) {
      return false;
    }
    for (OnboardingStatusEvaluatorService.RequirementInfo r : ctx.requirements) {
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

  private static Boolean agreementSignedAndContractComplete(
    OnboardingStatusEvaluatorService.EvaluationContext ctx
  ) {
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
    for (OnboardingStatusEvaluatorService.RequirementInfo r : ctx.requirements) {
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
}
