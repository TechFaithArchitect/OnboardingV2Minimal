public with sharing class OnbReqContractEvidenceInvocable {
  public class EvaluateRequest {
    @InvocableVariable(required=true)
    public Id contractId;

    @InvocableVariable(required=true)
    public String requirementType;

    @InvocableVariable(required=true)
    public String evidenceStatus;

    @InvocableVariable
    public Id agreementId;

    @InvocableVariable
    public Boolean applyOnboardingStatus;
  }

  public class EvaluateResult {
    @InvocableVariable
    public String errorMessage;

    @InvocableVariable
    public Integer matchedOnboardingCount;

    @InvocableVariable
    public Integer matchedRequirementCount;

    @InvocableVariable
    public Integer updatedSubjectCount;

    @InvocableVariable
    public Integer updatedOnboardingCount;
  }

  private class RequestContext {
    Integer index;
    EvaluateRequest request;
    String mappedSubjectStatus;
    Set<Id> requirementIds = new Set<Id>();
    Set<Id> onboardingIds = new Set<Id>();
    Integer updatedSubjectCount = 0;
    Integer updatedOnboardingCount = 0;
    List<String> errors = new List<String>();
  }

  private class SubjectTarget {
    Id subjectId;
    Id requirementId;
    String targetStatus;
    Integer priority;
    Set<Integer> requestIndexes = new Set<Integer>();
  }

  @InvocableMethod(
    label='Evaluate Requirement Subjects by Contract Evidence'
    description='Contract-scoped evidence evaluator: updates matching requirement subjects, rolls up parent requirement status, and applies onboarding BRE evaluation.'
  )
  public static List<EvaluateResult> evaluate(List<EvaluateRequest> requests) {
    List<EvaluateResult> results = initializeResults(requests);
    if (requests == null || requests.isEmpty()) {
      return results;
    }

    Map<Integer, RequestContext> contextsByIndex = new Map<Integer, RequestContext>();
    Set<Id> contractIds = new Set<Id>();
    Map<Id, Set<String>> requirementTypesByContract = new Map<Id, Set<String>>();

    for (Integer i = 0; i < requests.size(); i++) {
      EvaluateRequest req = requests[i];
      RequestContext ctx = new RequestContext();
      ctx.index = i;
      ctx.request = req;
      contextsByIndex.put(i, ctx);

      if (req == null) {
        ctx.errors.add('Request row is null.');
        continue;
      }
      if (req.contractId == null) {
        ctx.errors.add('Contract Id is required.');
        continue;
      }
      if (String.isBlank(req.requirementType)) {
        ctx.errors.add('Requirement Type is required.');
        continue;
      }
      if (String.isBlank(req.evidenceStatus)) {
        ctx.errors.add('Evidence Status is required.');
        continue;
      }

      String mappedStatus = mapEvidenceStatus(req.evidenceStatus);
      if (String.isBlank(mappedStatus)) {
        ctx.errors.add('Unsupported evidence status: ' + req.evidenceStatus);
        continue;
      }

      ctx.mappedSubjectStatus = mappedStatus;
      contractIds.add(req.contractId);
      if (!requirementTypesByContract.containsKey(req.contractId)) {
        requirementTypesByContract.put(req.contractId, new Set<String>());
      }
      requirementTypesByContract.get(req.contractId).add(req.requirementType);
    }

    if (!contractIds.isEmpty()) {
      Map<String, List<Onboarding_Requirement__c>> requirementsByContractAndType = loadRequirementsByContractAndType(
        contractIds,
        requirementTypesByContract
      );
      Set<Id> allRequirementIds = collectRequirementIds(requirementsByContractAndType);
      Map<Id, List<Onboarding_Requirement_Subject__c>> subjectsByRequirementId = loadSubjectsByRequirementId(
        allRequirementIds
      );

      Map<Id, SubjectTarget> targetsBySubjectId = new Map<Id, SubjectTarget>();

      for (Integer i = 0; i < requests.size(); i++) {
        RequestContext ctx = contextsByIndex.get(i);
        if (ctx == null || !ctx.errors.isEmpty() || ctx.request == null) {
          continue;
        }

        String key = keyFor(ctx.request.contractId, ctx.request.requirementType);
        List<Onboarding_Requirement__c> scopedRequirements = requirementsByContractAndType.get(key);
        if (scopedRequirements == null || scopedRequirements.isEmpty()) {
          ctx.errors.add(
            'No onboarding requirements found for contract ' +
            String.valueOf(ctx.request.contractId) +
            ' and type ' +
            ctx.request.requirementType +
            '.'
          );
          continue;
        }

        for (Onboarding_Requirement__c requirement : scopedRequirements) {
          ctx.requirementIds.add(requirement.Id);
          if (requirement.Onboarding__c != null) {
            ctx.onboardingIds.add(requirement.Onboarding__c);
          }

          List<Onboarding_Requirement_Subject__c> subjects = subjectsByRequirementId.get(requirement.Id);
          if (subjects == null) {
            continue;
          }

          for (Onboarding_Requirement_Subject__c subject : subjects) {
            if (subject.Status__c == ctx.mappedSubjectStatus) {
              continue;
            }
            upsertTarget(targetsBySubjectId, subject, ctx.mappedSubjectStatus, ctx.index);
          }
        }
      }

      Set<Id> successfulChangedRequirementIds = applySubjectUpdates(
        targetsBySubjectId,
        contextsByIndex
      );

      applyParentRequirementRollup(successfulChangedRequirementIds, contextsByIndex);

      Map<Id, Id> desiredAgreementByOnboardingId = buildDesiredAgreementByOnboardingId(
        contextsByIndex,
        requirementsByContractAndType
      );
      applyAgreementPointers(desiredAgreementByOnboardingId, contextsByIndex);

      Set<Id> onboardingIdsForStatusEval = collectOnboardingIdsForStatusEval(contextsByIndex);
      applyOnboardingStatusEvaluation(onboardingIdsForStatusEval, contextsByIndex);
    }

    finalizeResults(results, contextsByIndex);
    return results;
  }

  private static List<EvaluateResult> initializeResults(List<EvaluateRequest> requests) {
    List<EvaluateResult> results = new List<EvaluateResult>();
    if (requests == null || requests.isEmpty()) {
      results.add(emptyResult());
      return results;
    }

    for (Integer i = 0; i < requests.size(); i++) {
      results.add(emptyResult());
    }
    return results;
  }

  private static EvaluateResult emptyResult() {
    EvaluateResult result = new EvaluateResult();
    result.errorMessage = null;
    result.matchedOnboardingCount = 0;
    result.matchedRequirementCount = 0;
    result.updatedSubjectCount = 0;
    result.updatedOnboardingCount = 0;
    return result;
  }

  private static Map<String, List<Onboarding_Requirement__c>> loadRequirementsByContractAndType(
    Set<Id> contractIds,
    Map<Id, Set<String>> requirementTypesByContract
  ) {
    Map<String, List<Onboarding_Requirement__c>> grouped = new Map<String, List<Onboarding_Requirement__c>>();
    if (contractIds == null || contractIds.isEmpty()) {
      return grouped;
    }

    for (Onboarding_Requirement__c requirement : [
      SELECT Id, Onboarding__c, Requirement_Type__c, Onboarding__r.Contract__c
      FROM Onboarding_Requirement__c
      WHERE Onboarding__r.Contract__c IN :contractIds
      WITH SECURITY_ENFORCED
    ]) {
      Id contractId = requirement.Onboarding__r.Contract__c;
      Set<String> acceptedTypes = requirementTypesByContract.get(contractId);
      if (acceptedTypes == null || !acceptedTypes.contains(requirement.Requirement_Type__c)) {
        continue;
      }

      String key = keyFor(contractId, requirement.Requirement_Type__c);
      if (!grouped.containsKey(key)) {
        grouped.put(key, new List<Onboarding_Requirement__c>());
      }
      grouped.get(key).add(requirement);
    }

    return grouped;
  }

  private static Set<Id> collectRequirementIds(
    Map<String, List<Onboarding_Requirement__c>> requirementsByContractAndType
  ) {
    Set<Id> ids = new Set<Id>();
    for (List<Onboarding_Requirement__c> requirements : requirementsByContractAndType.values()) {
      for (Onboarding_Requirement__c requirement : requirements) {
        ids.add(requirement.Id);
      }
    }
    return ids;
  }

  private static Map<Id, List<Onboarding_Requirement_Subject__c>> loadSubjectsByRequirementId(
    Set<Id> requirementIds
  ) {
    Map<Id, List<Onboarding_Requirement_Subject__c>> grouped = new Map<Id, List<Onboarding_Requirement_Subject__c>>();
    if (requirementIds == null || requirementIds.isEmpty()) {
      return grouped;
    }

    for (Onboarding_Requirement_Subject__c subject : [
      SELECT Id, Onboarding_Requirement__c, Status__c
      FROM Onboarding_Requirement_Subject__c
      WHERE Onboarding_Requirement__c IN :requirementIds
      WITH SECURITY_ENFORCED
    ]) {
      if (!grouped.containsKey(subject.Onboarding_Requirement__c)) {
        grouped.put(subject.Onboarding_Requirement__c, new List<Onboarding_Requirement_Subject__c>());
      }
      grouped.get(subject.Onboarding_Requirement__c).add(subject);
    }

    return grouped;
  }

  private static void upsertTarget(
    Map<Id, SubjectTarget> targetsBySubjectId,
    Onboarding_Requirement_Subject__c subject,
    String mappedStatus,
    Integer requestIndex
  ) {
    SubjectTarget existing = targetsBySubjectId.get(subject.Id);
    Integer mappedPriority = statusPriority(mappedStatus);
    if (existing == null) {
      SubjectTarget target = new SubjectTarget();
      target.subjectId = subject.Id;
      target.requirementId = subject.Onboarding_Requirement__c;
      target.targetStatus = mappedStatus;
      target.priority = mappedPriority;
      target.requestIndexes.add(requestIndex);
      targetsBySubjectId.put(subject.Id, target);
      return;
    }

    existing.requestIndexes.add(requestIndex);
    if (mappedPriority > existing.priority) {
      existing.targetStatus = mappedStatus;
      existing.priority = mappedPriority;
    }
  }

  private static Set<Id> applySubjectUpdates(
    Map<Id, SubjectTarget> targetsBySubjectId,
    Map<Integer, RequestContext> contextsByIndex
  ) {
    Set<Id> changedRequirementIds = new Set<Id>();
    if (targetsBySubjectId == null || targetsBySubjectId.isEmpty()) {
      return changedRequirementIds;
    }

    List<Onboarding_Requirement_Subject__c> updates = new List<Onboarding_Requirement_Subject__c>();
    List<SubjectTarget> orderedTargets = new List<SubjectTarget>();
    for (SubjectTarget target : targetsBySubjectId.values()) {
      updates.add(new Onboarding_Requirement_Subject__c(
        Id = target.subjectId,
        Status__c = target.targetStatus
      ));
      orderedTargets.add(target);
    }

    List<SObject> sanitizedForUpdate = Security.stripInaccessible(
      AccessType.UPDATABLE,
      updates
    ).getRecords();
    Database.SaveResult[] saveResults = Database.update(
      (List<Onboarding_Requirement_Subject__c>) sanitizedForUpdate,
      false,
      AccessLevel.USER_MODE
    );
    for (Integer i = 0; i < saveResults.size(); i++) {
      Database.SaveResult saveResult = saveResults[i];
      SubjectTarget target = orderedTargets[i];
      if (saveResult.isSuccess()) {
        changedRequirementIds.add(target.requirementId);
        for (Integer requestIndex : target.requestIndexes) {
          RequestContext ctx = contextsByIndex.get(requestIndex);
          if (ctx != null) {
            ctx.updatedSubjectCount++;
          }
        }
      } else {
        String error = firstErrorMessage(saveResult);
        for (Integer requestIndex : target.requestIndexes) {
          RequestContext ctx = contextsByIndex.get(requestIndex);
          if (ctx != null) {
            ctx.errors.add(
              'Failed updating requirement subject ' +
              String.valueOf(target.subjectId) +
              ': ' +
              error
            );
          }
        }
      }
    }

    return changedRequirementIds;
  }

  private static void applyParentRequirementRollup(
    Set<Id> changedRequirementIds,
    Map<Integer, RequestContext> contextsByIndex
  ) {
    if (changedRequirementIds == null || changedRequirementIds.isEmpty()) {
      return;
    }

    OnbReqParentBulkEvalInvocable.EvaluateRequest evalReq = new OnbReqParentBulkEvalInvocable.EvaluateRequest();
    evalReq.onboardingRequirementIds = new List<String>();
    for (Id idValue : changedRequirementIds) {
      evalReq.onboardingRequirementIds.add(String.valueOf(idValue));
    }

    List<OnbReqParentBulkEvalInvocable.EvaluateResult> evalResults =
      OnbReqParentBulkEvalInvocable.evaluate(
        new List<OnbReqParentBulkEvalInvocable.EvaluateRequest>{ evalReq }
      );
    if (evalResults.isEmpty()) {
      return;
    }

    String parentError = evalResults[0].errorMessage;
    if (String.isBlank(parentError)) {
      return;
    }

    for (RequestContext ctx : contextsByIndex.values()) {
      if (ctx == null || ctx.requirementIds.isEmpty()) {
        continue;
      }
      if (!intersects(ctx.requirementIds, changedRequirementIds)) {
        continue;
      }
      ctx.errors.add('Parent requirement rollup: ' + parentError);
    }
  }

  private static Map<Id, Id> buildDesiredAgreementByOnboardingId(
    Map<Integer, RequestContext> contextsByIndex,
    Map<String, List<Onboarding_Requirement__c>> requirementsByContractAndType
  ) {
    Map<Id, Id> desiredAgreementByOnboardingId = new Map<Id, Id>();
    if (contextsByIndex == null || contextsByIndex.isEmpty()) {
      return desiredAgreementByOnboardingId;
    }

    for (RequestContext ctx : contextsByIndex.values()) {
      if (
        ctx == null ||
        ctx.request == null ||
        ctx.request.agreementId == null ||
        String.isBlank(ctx.request.requirementType)
      ) {
        continue;
      }
      String key = keyFor(ctx.request.contractId, ctx.request.requirementType);
      List<Onboarding_Requirement__c> requirements = requirementsByContractAndType.get(key);
      if (requirements == null) {
        continue;
      }
      for (Onboarding_Requirement__c requirement : requirements) {
        if (requirement.Onboarding__c != null) {
          desiredAgreementByOnboardingId.put(requirement.Onboarding__c, ctx.request.agreementId);
        }
      }
    }

    return desiredAgreementByOnboardingId;
  }

  private static void applyAgreementPointers(
    Map<Id, Id> desiredAgreementByOnboardingId,
    Map<Integer, RequestContext> contextsByIndex
  ) {
    if (desiredAgreementByOnboardingId == null || desiredAgreementByOnboardingId.isEmpty()) {
      return;
    }

    List<Onboarding__c> updates = new List<Onboarding__c>();
    for (Onboarding__c onboarding : [
      SELECT Id, Agreement__c
      FROM Onboarding__c
      WHERE Id IN :desiredAgreementByOnboardingId.keySet()
      WITH SECURITY_ENFORCED
    ]) {
      Id desiredAgreementId = desiredAgreementByOnboardingId.get(onboarding.Id);
      if (desiredAgreementId == null || onboarding.Agreement__c == desiredAgreementId) {
        continue;
      }
      updates.add(new Onboarding__c(
        Id = onboarding.Id,
        Agreement__c = desiredAgreementId
      ));
    }

    if (updates.isEmpty()) {
      return;
    }

    List<SObject> sanitizedForUpdate = Security.stripInaccessible(
      AccessType.UPDATABLE,
      updates
    ).getRecords();
    Database.SaveResult[] saveResults = Database.update(
      (List<Onboarding__c>) sanitizedForUpdate,
      false,
      AccessLevel.USER_MODE
    );
    for (Integer i = 0; i < saveResults.size(); i++) {
      Database.SaveResult saveResult = saveResults[i];
      Onboarding__c attempted = updates[i];
      if (saveResult.isSuccess()) {
        for (RequestContext ctx : contextsByIndex.values()) {
          if (ctx != null && ctx.onboardingIds.contains(attempted.Id)) {
            ctx.updatedOnboardingCount++;
          }
        }
        continue;
      }

      String error = firstErrorMessage(saveResult);
      for (RequestContext ctx : contextsByIndex.values()) {
        if (ctx != null && ctx.onboardingIds.contains(attempted.Id)) {
          ctx.errors.add(
            'Failed updating onboarding agreement pointer for onboarding ' +
            String.valueOf(attempted.Id) +
            ': ' +
            error
          );
        }
      }
    }
  }

  private static Set<Id> collectOnboardingIdsForStatusEval(
    Map<Integer, RequestContext> contextsByIndex
  ) {
    Set<Id> ids = new Set<Id>();
    for (RequestContext ctx : contextsByIndex.values()) {
      if (ctx == null || ctx.request == null) {
        continue;
      }
      if (ctx.request.applyOnboardingStatus == false) {
        continue;
      }
      ids.addAll(ctx.onboardingIds);
    }
    return ids;
  }

  private static void applyOnboardingStatusEvaluation(
    Set<Id> onboardingIdsForStatusEval,
    Map<Integer, RequestContext> contextsByIndex
  ) {
    if (onboardingIdsForStatusEval == null || onboardingIdsForStatusEval.isEmpty()) {
      return;
    }

    try {
      OnboardingStatusEvaluatorService.evaluateAndApplyBulk(onboardingIdsForStatusEval);
    } catch (Exception ex) {
      for (RequestContext ctx : contextsByIndex.values()) {
        if (ctx == null || ctx.onboardingIds.isEmpty()) {
          continue;
        }
        if (!intersects(ctx.onboardingIds, onboardingIdsForStatusEval)) {
          continue;
        }
        ctx.errors.add('Onboarding status evaluation failed: ' + ex.getMessage());
      }
    }
  }

  private static Boolean intersects(Set<Id> leftValues, Set<Id> rightValues) {
    if (leftValues == null || rightValues == null || leftValues.isEmpty() || rightValues.isEmpty()) {
      return false;
    }
    for (Id idValue : leftValues) {
      if (rightValues.contains(idValue)) {
        return true;
      }
    }
    return false;
  }

  private static String firstErrorMessage(Database.SaveResult saveResult) {
    if (saveResult == null || saveResult.getErrors().isEmpty() || saveResult.getErrors()[0] == null) {
      return 'Unknown update error.';
    }
    return saveResult.getErrors()[0].getMessage();
  }

  private static void finalizeResults(
    List<EvaluateResult> results,
    Map<Integer, RequestContext> contextsByIndex
  ) {
    for (Integer i = 0; i < results.size(); i++) {
      EvaluateResult result = results[i];
      RequestContext ctx = contextsByIndex.get(i);
      if (ctx == null) {
        continue;
      }

      result.matchedOnboardingCount = ctx.onboardingIds.size();
      result.matchedRequirementCount = ctx.requirementIds.size();
      result.updatedSubjectCount = ctx.updatedSubjectCount;
      result.updatedOnboardingCount = ctx.updatedOnboardingCount;
      result.errorMessage = ctx.errors.isEmpty() ? null : String.join(ctx.errors, ' | ');
    }
  }

  @TestVisible
  private static String mapEvidenceStatus(String evidenceStatus) {
    if (String.isBlank(evidenceStatus)) {
      return null;
    }

    Set<String> completeStatuses = new Set<String>{
      'Complete',
      'Waived',
      'Completed',
      'Passed',
      'Exempt',
      'Signed'
    };
    if (completeStatuses.contains(evidenceStatus)) {
      return 'Setup Complete';
    }

    Set<String> deniedStatuses = new Set<String>{
      'Denied',
      'Denied by PV',
      'Denied by Partner'
    };
    if (deniedStatuses.contains(evidenceStatus)) {
      return 'Denied';
    }

    if (new Set<String>{ 'Cancelled', 'Canceled' }.contains(evidenceStatus)) {
      return 'Canceled';
    }

    if (evidenceStatus == 'Expired') {
      return 'Expired';
    }

    if (
      new Set<String>{
        'Requested',
        'Incomplete',
        'In Progress',
        'Enrolled',
        'Failed'
      }.contains(evidenceStatus)
    ) {
      return 'In Process';
    }

    if (
      new Set<String>{
        'Out for Signature',
        'Training Sent',
        'Paperwork Sent'
      }.contains(evidenceStatus)
    ) {
      return 'Paperwork Sent';
    }

    if (
      new Set<String>{
        'New',
        'Not Started',
        'Assigned'
      }.contains(evidenceStatus)
    ) {
      return 'New';
    }

    return null;
  }

  private static Integer statusPriority(String statusValue) {
    if (statusValue == 'Denied') {
      return 900;
    }
    if (statusValue == 'Canceled') {
      return 850;
    }
    if (statusValue == 'Expired') {
      return 800;
    }
    if (statusValue == 'Setup Complete') {
      return 700;
    }
    if (statusValue == 'Pending Sales') {
      return 600;
    }
    if (statusValue == 'In Process') {
      return 500;
    }
    if (statusValue == 'Pending Initial Review') {
      return 450;
    }
    if (statusValue == 'Paperwork Sent') {
      return 400;
    }
    if (statusValue == 'New') {
      return 100;
    }
    return 0;
  }

  private static String keyFor(Id contractId, String requirementType) {
    return String.valueOf(contractId) + '|' + String.valueOf(requirementType);
  }
}
