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
  private static final String NOT_STARTED = 'Not Started';
  private static final String IN_APPROVAL_PROCESS = 'In Approval Process';
  private static final String DRAFT = 'Draft';
  private static final String NEW_STATUS = 'New';

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
        return hasAnyCanceledWithStageGate(ctx);
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
      when 'agreementsignedcontractnotstartedothersignored' {
        return agreementSignedContractNotStartedOthersIgnored(ctx);
      }
      when 'assignedteamequals' {
        String team = stringVal(m.get('team'));
        return ctx.onboarding != null &&
          String.isNotBlank(team) &&
          team.equalsIgnoreCase(ctx.onboarding.Assigned_Team__c);
      }
      when 'opportunitystagecanceled' {
        return ctx.opportunity != null &&
          isCanceledOpportunityStage(ctx.opportunity.StageName);
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

  /**
   * Canceled requirement rows only drive onboarding Canceled when the linked Opportunity is absent
   * or already in a canceled/lost stage — avoids treating in-flight deals as hard-canceled from a stray row.
   */
  private static Boolean hasAnyCanceledWithStageGate(OnboardingStatusEvaluatorService.EvaluationContext ctx) {
    if (
      !hasAnyNormalized(ctx, CANCELED) &&
      !hasAnyNormalized(ctx, CANCELLED)
    ) {
      return false;
    }
    return ctx.opportunity == null ||
      isCanceledOpportunityStage(ctx.opportunity.StageName);
  }

  private static Boolean allRequirementsSetupComplete(
    OnboardingStatusEvaluatorService.EvaluationContext ctx
  ) {
    if (ctx.requirements.isEmpty()) {
      return false;
    }
    Set<String> applicable = ctx.applicableProgramRequirementTypesLowercase;
    if (applicable == null || applicable.isEmpty()) {
      return everyOnboardingRequirementRowTerminal(ctx.requirements);
    }
    // Template types with no onboarding row yet are skipped (do not block). Otherwise a program that
    // lists e.g. Training on Vendor_Program_Requirement__c but never creates that row prevents
    // Setup Complete forever when Agreement+Contract are done. At least one template type must have
    // ≥1 row, and every row for every template type that *does* have rows must be terminal.
    Boolean sawAtLeastOneTemplateRow = false;
    for (String typeKey : applicable) {
      List<OnboardingStatusEvaluatorService.RequirementInfo> rows = requirementsMatchingTypeKey(
        ctx.requirements,
        typeKey
      );
      if (rows.isEmpty()) {
        continue;
      }
      sawAtLeastOneTemplateRow = true;
      for (OnboardingStatusEvaluatorService.RequirementInfo r : rows) {
        if (!isTerminalNormalizedStatus(r.normalizedStatus)) {
          return false;
        }
      }
    }
    if (sawAtLeastOneTemplateRow) {
      return true;
    }
    // Program template Requirement_Type__c values did not match any onboarding row (picklist drift,
    // typos, or org-specific labels). Do not block Setup Complete forever — fall back to "all rows terminal".
    return everyOnboardingRequirementRowTerminal(ctx.requirements);
  }

  private static List<OnboardingStatusEvaluatorService.RequirementInfo> requirementsMatchingTypeKey(
    List<OnboardingStatusEvaluatorService.RequirementInfo> reqs,
    String typeKeyLower
  ) {
    List<OnboardingStatusEvaluatorService.RequirementInfo> out = new List<OnboardingStatusEvaluatorService.RequirementInfo>();
    if (reqs == null || String.isBlank(typeKeyLower)) {
      return out;
    }
    for (OnboardingStatusEvaluatorService.RequirementInfo r : reqs) {
      if (r.requirementType != null && typeKeyLower.equals(r.requirementType.trim().toLowerCase())) {
        out.add(r);
      }
    }
    return out;
  }

  private static Boolean everyOnboardingRequirementRowTerminal(
    List<OnboardingStatusEvaluatorService.RequirementInfo> reqs
  ) {
    if (reqs == null || reqs.isEmpty()) {
      return false;
    }
    for (OnboardingStatusEvaluatorService.RequirementInfo r : reqs) {
      if (!isTerminalNormalizedStatus(r.normalizedStatus)) {
        return false;
      }
    }
    return true;
  }

  private static Boolean isTerminalNormalizedStatus(String n) {
    if (n == null || n == '') {
      return false;
    }
    return SETUP_COMPLETE.equalsIgnoreCase(n) ||
      IGNORE.equalsIgnoreCase(n) ||
      SIGNED.equalsIgnoreCase(n) ||
      COMPLETE.equalsIgnoreCase(n);
  }

  /**
   * Every Agreement row Signed or Setup Complete; every Contract requirement row normalized
   * to an early contract milestone (Not Started or In Approval Process after CMDT + sync).
   * Other types ignored. Evaluator reads only Onboarding_Requirement__c — keep Contract rows in
   * sync with linked Contract via flows/automation; do not mirror Contract.Status here.
   */
  private static Boolean agreementSignedContractNotStartedOthersIgnored(
    OnboardingStatusEvaluatorService.EvaluationContext ctx
  ) {
    if (ctx.requirements == null || ctx.requirements.isEmpty()) {
      return false;
    }
    Boolean sawAgreement = false;
    Boolean agreementOk = true;
    Boolean sawContract = false;
    Boolean contractOk = true;
    for (OnboardingStatusEvaluatorService.RequirementInfo r : ctx.requirements) {
      if (AGREEMENT.equalsIgnoreCase(r.requirementType)) {
        sawAgreement = true;
        String n = r.normalizedStatus;
        if (
          String.isBlank(n) ||
          (!SIGNED.equalsIgnoreCase(n) && !SETUP_COMPLETE.equalsIgnoreCase(n))
        ) {
          agreementOk = false;
        }
      } else if (CONTRACT.equalsIgnoreCase(r.requirementType)) {
        sawContract = true;
        String n = r.normalizedStatus;
        if (String.isBlank(n) || !contractRequirementNormalizedAllowsPendingInitialReview(n)) {
          contractOk = false;
        }
      }
    }
    return sawAgreement && agreementOk && sawContract && contractOk;
  }

  /**
   * Pre-PIR contract requirement shapes. Includes Draft/New: Contract requirements often default to
   * Draft or New before flows sync to Not Started; excluding them forced a fall-through to In Process.
   */
  private static Boolean contractRequirementNormalizedAllowsPendingInitialReview(String normalized) {
    if (String.isBlank(normalized)) {
      return false;
    }
    return NOT_STARTED.equalsIgnoreCase(normalized) ||
      IN_APPROVAL_PROCESS.equalsIgnoreCase(normalized) ||
      DRAFT.equalsIgnoreCase(normalized) ||
      NEW_STATUS.equalsIgnoreCase(normalized);
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
    Set<String> applicable = ctx.applicableProgramRequirementTypesLowercase;
    for (OnboardingStatusEvaluatorService.RequirementInfo r : ctx.requirements) {
      if (AGREEMENT.equalsIgnoreCase(r.requirementType) ||
        CONTRACT.equalsIgnoreCase(r.requirementType)) {
        continue;
      }
      if (
        applicable != null &&
        !applicable.isEmpty() &&
        (r.requirementType == null ||
          !applicable.contains(r.requirementType.trim().toLowerCase()))
      ) {
        continue;
      }
      String n = r.normalizedStatus;
      if (n != null && n != '' && !IGNORE.equalsIgnoreCase(n)) {
        return false;
      }
    }
    return true;
  }

  private static Boolean isCanceledOpportunityStage(String stage) {
    return stage != null &&
      (
        stage.equalsIgnoreCase('Canceled') ||
        stage.equalsIgnoreCase('Cancelled') ||
        stage.equalsIgnoreCase('Closed Lost')
      );
  }
}
