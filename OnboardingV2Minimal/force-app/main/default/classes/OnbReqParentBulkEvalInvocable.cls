public with sharing class OnbReqParentBulkEvalInvocable {
  public class EvaluateRequest {
    @InvocableVariable(required=true)
    public List<String> onboardingRequirementIds;
  }

  public class EvaluateResult {
    @InvocableVariable
    public String errorMessage;

    @InvocableVariable
    public Integer processedCount;

    @InvocableVariable
    public Integer updatedCount;

    @InvocableVariable
    public Integer failedCount;
  }

  private class SaveSummary {
    Integer updatedCount = 0;
    Integer failedCount = 0;
    List<String> errors = new List<String>();
  }

  @InvocableMethod(
    label='Evaluate Changed Onboarding Requirements (Bulk)'
    description='Rolls up parent onboarding requirement status/completed values in bulk from subject status.'
  )
  public static List<EvaluateResult> evaluate(List<EvaluateRequest> requests) {
    List<EvaluateResult> results = new List<EvaluateResult>();
    if (requests == null || requests.isEmpty()) {
      results.add(emptyResult());
      return results;
    }

    List<Set<Id>> requirementIdsByRequestIndex = new List<Set<Id>>();
    Set<Id> allRequirementIds = new Set<Id>();
    for (EvaluateRequest requestItem : requests) {
      Set<Id> requirementIds = parseRequirementIds(requestItem);
      requirementIdsByRequestIndex.add(requirementIds);
      allRequirementIds.addAll(requirementIds);
      results.add(new EvaluateResult());
    }

    Map<Id, Onboarding_Requirement__c> allRequirementsById = new Map<Id, Onboarding_Requirement__c>();
    if (!allRequirementIds.isEmpty()) {
      allRequirementsById = new Map<Id, Onboarding_Requirement__c>([
        SELECT Id, Status__c, Completed__c
        FROM Onboarding_Requirement__c
        WHERE Id IN :allRequirementIds
        WITH SECURITY_ENFORCED
      ]);
    }

    Map<Id, StatusCounts> countsByRequirementId = new Map<Id, StatusCounts>();
    if (!allRequirementsById.isEmpty()) {
      for (Onboarding_Requirement_Subject__c subject : [
        SELECT Id, Onboarding_Requirement__c, Status__c
        FROM Onboarding_Requirement_Subject__c
        WHERE Onboarding_Requirement__c IN :allRequirementsById.keySet()
        WITH SECURITY_ENFORCED
      ]) {
        StatusCounts counts = countsByRequirementId.get(subject.Onboarding_Requirement__c);
        if (counts == null) {
          counts = new StatusCounts();
          countsByRequirementId.put(subject.Onboarding_Requirement__c, counts);
        }
        counts.add(subject.Status__c);
      }
    }

    for (Integer requestIndex = 0; requestIndex < requests.size(); requestIndex++) {
      EvaluateResult result = results[requestIndex];
      try {
        Set<Id> requirementIds = requirementIdsByRequestIndex[requestIndex];
        if (requirementIds.isEmpty()) {
          result.errorMessage = 'No onboarding requirement ids were passed.';
          result.processedCount = 0;
          result.updatedCount = 0;
          result.failedCount = 0;
          continue;
        }

        Map<Id, Onboarding_Requirement__c> requirementsById = new Map<Id, Onboarding_Requirement__c>();
        for (Id requirementId : requirementIds) {
          Onboarding_Requirement__c requirementRecord = allRequirementsById.get(requirementId);
          if (requirementRecord != null) {
            requirementsById.put(requirementId, requirementRecord);
          }
        }

        Map<Id, StatusOutcome> outcomesById = new Map<Id, StatusOutcome>();
        List<Onboarding_Requirement__c> updates = new List<Onboarding_Requirement__c>();
        for (Onboarding_Requirement__c existing : requirementsById.values()) {
          StatusOutcome outcome = determineOutcome(countsByRequirementId.get(existing.Id));
          outcomesById.put(existing.Id, outcome);
          if (existing.Status__c != outcome.status || existing.Completed__c != outcome.completed) {
            updates.add(new Onboarding_Requirement__c(
              Id = existing.Id,
              Status__c = outcome.status,
              Completed__c = outcome.completed
            ));
          }
        }

        SaveSummary saveSummary = applyUpdatesWithStatusFallback(
          updates,
          outcomesById,
          requirementsById
        );

        Integer missingCount = requirementIds.size() - requirementsById.size();
        if (missingCount > 0) {
          saveSummary.errors.add('Some onboarding requirement ids were not found: ' + missingCount);
        }

        result.processedCount = requirementsById.size();
        result.updatedCount = saveSummary.updatedCount;
        result.failedCount = saveSummary.failedCount + missingCount;
        result.errorMessage = saveSummary.errors.isEmpty() ? '' : String.join(saveSummary.errors, ' | ');
      } catch (Exception ex) {
        result.errorMessage = ex.getMessage();
        result.processedCount = 0;
        result.updatedCount = 0;
        result.failedCount = 0;
      }
    }
    return results;
  }

  @SuppressWarnings('PMD.OperationWithLimitsInLoop')
  private static SaveSummary applyUpdatesWithStatusFallback(
    List<Onboarding_Requirement__c> updates,
    Map<Id, StatusOutcome> outcomesById,
    Map<Id, Onboarding_Requirement__c> existingById
  ) {
    SaveSummary summary = new SaveSummary();
    if (updates == null || updates.isEmpty()) {
      return summary;
    }

    Map<Id, Onboarding_Requirement__c> pendingStatusFallbackById = new Map<Id, Onboarding_Requirement__c>();
    List<SObject> sanitizedFirstPassUpdates = Security.stripInaccessible(
      AccessType.UPDATABLE,
      updates
    ).getRecords();
    Database.SaveResult[] firstPassResults = Database.update(
      (List<Onboarding_Requirement__c>) sanitizedFirstPassUpdates,
      false,
      AccessLevel.USER_MODE
    );

    for (Integer i = 0; i < firstPassResults.size(); i++) {
      Database.SaveResult saveResult = firstPassResults[i];
      Onboarding_Requirement__c attemptedUpdate = updates[i];
      if (saveResult.isSuccess()) {
        summary.updatedCount++;
        continue;
      }

      Database.Error firstError = saveResult.getErrors().isEmpty() ? null : saveResult.getErrors()[0];
      if (isStatusRestrictedPicklistError(firstError)) {
        pendingStatusFallbackById.put(attemptedUpdate.Id, attemptedUpdate);
      } else {
        summary.failedCount++;
        summary.errors.add(formatUpdateError(attemptedUpdate.Id, saveResult));
      }
    }

    if (pendingStatusFallbackById.isEmpty()) {
      return summary;
    }

    Set<Id> unresolvedIds = new Set<Id>(pendingStatusFallbackById.keySet());
    Map<Id, List<String>> candidatesById = new Map<Id, List<String>>();
    Map<Id, Integer> nextCandidateIndexById = new Map<Id, Integer>();

    for (Id requirementId : unresolvedIds) {
      StatusOutcome outcome = outcomesById.get(requirementId);
      Onboarding_Requirement__c existing = existingById.get(requirementId);
      String currentStatus = existing == null ? null : existing.Status__c;
      candidatesById.put(requirementId, fallbackStatusesForOutcome(outcome == null ? null : outcome.status, currentStatus));
      nextCandidateIndexById.put(requirementId, 0);
    }

    while (!unresolvedIds.isEmpty()) {
      List<Onboarding_Requirement__c> retryUpdates = new List<Onboarding_Requirement__c>();
      List<Id> retryIds = new List<Id>();
      Boolean attemptedAny = false;

      for (Id requirementId : new List<Id>(unresolvedIds)) {
        List<String> candidates = candidatesById.get(requirementId);
        Integer nextIndex = nextCandidateIndexById.get(requirementId);
        if (candidates == null || nextIndex == null || nextIndex >= candidates.size()) {
          continue;
        }

        attemptedAny = true;
        String candidateStatus = candidates[nextIndex];
        nextCandidateIndexById.put(requirementId, nextIndex + 1);

        StatusOutcome outcome = outcomesById.get(requirementId);
        Onboarding_Requirement__c existing = existingById.get(requirementId);
        Boolean desiredCompleted = outcome == null ? false : outcome.completed;
        if (
          existing != null &&
          existing.Status__c == candidateStatus &&
          existing.Completed__c == desiredCompleted
        ) {
          unresolvedIds.remove(requirementId);
          continue;
        }

        retryUpdates.add(new Onboarding_Requirement__c(
          Id = requirementId,
          Status__c = candidateStatus,
          Completed__c = desiredCompleted
        ));
        retryIds.add(requirementId);
      }

      if (!attemptedAny || retryUpdates.isEmpty()) {
        break;
      }

      List<SObject> sanitizedRetryUpdates = Security.stripInaccessible(
        AccessType.UPDATABLE,
        retryUpdates
      ).getRecords();
      Database.SaveResult[] retryResults = Database.update(
        (List<Onboarding_Requirement__c>) sanitizedRetryUpdates,
        false,
        AccessLevel.USER_MODE
      );
      for (Integer i = 0; i < retryResults.size(); i++) {
        Database.SaveResult retryResult = retryResults[i];
        Id requirementId = retryIds[i];

        if (retryResult.isSuccess()) {
          summary.updatedCount++;
          unresolvedIds.remove(requirementId);
          continue;
        }

        Database.Error firstError = retryResult.getErrors().isEmpty() ? null : retryResult.getErrors()[0];
        if (!isStatusRestrictedPicklistError(firstError)) {
          summary.failedCount++;
          summary.errors.add(formatUpdateError(requirementId, retryResult));
          unresolvedIds.remove(requirementId);
        }
      }
    }

    if (unresolvedIds.isEmpty()) {
      return summary;
    }

    List<Onboarding_Requirement__c> completedOnlyUpdates = new List<Onboarding_Requirement__c>();
    List<Id> completedOnlyIds = new List<Id>();

    for (Id requirementId : new List<Id>(unresolvedIds)) {
      Onboarding_Requirement__c existing = existingById.get(requirementId);
      StatusOutcome outcome = outcomesById.get(requirementId);

      if (existing == null || outcome == null) {
        summary.failedCount++;
        summary.errors.add('Onboarding Requirement ' + requirementId + ': Missing context for fallback update.');
        unresolvedIds.remove(requirementId);
        continue;
      }

      if (existing.Completed__c != outcome.completed) {
        completedOnlyUpdates.add(new Onboarding_Requirement__c(
          Id = requirementId,
          Completed__c = outcome.completed
        ));
        completedOnlyIds.add(requirementId);
      } else {
        unresolvedIds.remove(requirementId);
      }
    }

    if (!completedOnlyUpdates.isEmpty()) {
      List<SObject> sanitizedCompletedOnlyUpdates = Security.stripInaccessible(
        AccessType.UPDATABLE,
        completedOnlyUpdates
      ).getRecords();
      Database.SaveResult[] completedOnlyResults = Database.update(
        (List<Onboarding_Requirement__c>) sanitizedCompletedOnlyUpdates,
        false,
        AccessLevel.USER_MODE
      );
      for (Integer i = 0; i < completedOnlyResults.size(); i++) {
        Database.SaveResult completedOnlyResult = completedOnlyResults[i];
        Id requirementId = completedOnlyIds[i];
        unresolvedIds.remove(requirementId);

        if (completedOnlyResult.isSuccess()) {
          summary.updatedCount++;
        } else {
          summary.failedCount++;
          summary.errors.add(formatUpdateError(requirementId, completedOnlyResult));
        }
      }
    }

    return summary;
  }

  private static List<String> fallbackStatusesForOutcome(String desiredStatus, String currentStatus) {
    List<String> candidates = new List<String>();

    if (desiredStatus == 'Setup Complete') {
      addUnique(candidates, 'Setup Complete');
      addUnique(candidates, 'Complete');
      addUnique(candidates, 'Completed');
      addUnique(candidates, 'Approved');
      addUnique(candidates, 'Passed');
      addUnique(candidates, 'Onboarding Approved');
    } else if (desiredStatus == 'Pending Sales') {
      addUnique(candidates, 'Pending Sales');
      addUnique(candidates, 'In Process');
      addUnique(candidates, 'In Progress');
      addUnique(candidates, 'Pending Initial Review');
      addUnique(candidates, 'Paperwork Sent');
      addUnique(candidates, 'Incomplete');
      addUnique(candidates, 'Not Started');
      addUnique(candidates, 'Draft');
    } else if (desiredStatus == 'Denied') {
      addUnique(candidates, 'Denied');
      addUnique(candidates, 'Canceled');
      addUnique(candidates, 'Expired');
      addUnique(candidates, 'Incomplete');
      addUnique(candidates, 'Not Started');
      addUnique(candidates, 'Draft');
    } else if (desiredStatus == 'Canceled') {
      addUnique(candidates, 'Canceled');
      addUnique(candidates, 'Denied');
      addUnique(candidates, 'Expired');
      addUnique(candidates, 'Incomplete');
      addUnique(candidates, 'Not Started');
      addUnique(candidates, 'Draft');
    } else if (desiredStatus == 'Expired') {
      addUnique(candidates, 'Expired');
      addUnique(candidates, 'Denied');
      addUnique(candidates, 'Canceled');
      addUnique(candidates, 'Incomplete');
      addUnique(candidates, 'Not Started');
      addUnique(candidates, 'Draft');
    } else if (desiredStatus == 'In Process') {
      addUnique(candidates, 'In Process');
      addUnique(candidates, 'In Progress');
      addUnique(candidates, 'Pending Initial Review');
      addUnique(candidates, 'Paperwork Sent');
      addUnique(candidates, 'Incomplete');
      addUnique(candidates, 'Not Started');
      addUnique(candidates, 'Draft');
    } else if (desiredStatus == 'Pending Initial Review') {
      addUnique(candidates, 'Pending Initial Review');
      addUnique(candidates, 'In Process');
      addUnique(candidates, 'In Progress');
      addUnique(candidates, 'Paperwork Sent');
      addUnique(candidates, 'Incomplete');
      addUnique(candidates, 'Not Started');
      addUnique(candidates, 'Draft');
    } else if (desiredStatus == 'Paperwork Sent') {
      addUnique(candidates, 'Paperwork Sent');
      addUnique(candidates, 'Pending Initial Review');
      addUnique(candidates, 'In Process');
      addUnique(candidates, 'In Progress');
      addUnique(candidates, 'Incomplete');
      addUnique(candidates, 'Not Started');
      addUnique(candidates, 'Draft');
    } else {
      addUnique(candidates, desiredStatus);
      addUnique(candidates, 'New');
      addUnique(candidates, 'Not Started');
      addUnique(candidates, 'Draft');
      addUnique(candidates, 'Incomplete');
    }

    addUnique(candidates, currentStatus);
    return candidates;
  }

  @TestVisible
  private static List<String> fallbackStatusesForTest(String desiredStatus, String currentStatus) {
    return fallbackStatusesForOutcome(desiredStatus, currentStatus);
  }

  private static void addUnique(List<String> candidates, String value) {
    if (String.isBlank(value) || candidates.contains(value)) {
      return;
    }
    candidates.add(value);
  }

  private static Boolean isStatusRestrictedPicklistError(Database.Error error) {
    if (error == null || error.getStatusCode() != StatusCode.INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST) {
      return false;
    }

    List<String> fields = error.getFields();
    return fields == null || fields.isEmpty() || fields.contains('Status__c');
  }

  private static String formatUpdateError(Id requirementId, Database.SaveResult saveResult) {
    String message = firstErrorMessage(saveResult);
    return 'Onboarding Requirement ' + requirementId + ': ' + message;
  }

  private static String firstErrorMessage(Database.SaveResult saveResult) {
    if (saveResult == null || saveResult.getErrors().isEmpty() || saveResult.getErrors()[0] == null) {
      return 'Unknown update error.';
    }
    return saveResult.getErrors()[0].getMessage();
  }

  private static EvaluateResult emptyResult() {
    EvaluateResult result = new EvaluateResult();
    result.errorMessage = '';
    result.processedCount = 0;
    result.updatedCount = 0;
    result.failedCount = 0;
    return result;
  }

  private static Set<Id> parseRequirementIds(EvaluateRequest req) {
    Set<Id> ids = new Set<Id>();
    if (req == null || req.onboardingRequirementIds == null) {
      return ids;
    }
    for (String rawValue : req.onboardingRequirementIds) {
      if (String.isBlank(rawValue)) {
        continue;
      }
      String trimmed = rawValue.trim();
      try {
        ids.add((Id)trimmed);
      } catch (Exception ignored) {
        // Ignore malformed ids and continue processing valid ids.
      }
    }
    return ids;
  }

  private class StatusCounts {
    Integer totalCount = 0;
    Integer deniedCount = 0;
    Integer canceledCount = 0;
    Integer expiredCount = 0;
    Integer setupCompleteCount = 0;
    Integer pendingSalesCount = 0;
    Integer inProcessCount = 0;
    Integer pendingInitialReviewCount = 0;
    Integer paperworkSentCount = 0;

    void add(String statusValue) {
      totalCount++;
      if (statusValue == 'Denied') {
        deniedCount++;
      } else if (statusValue == 'Canceled') {
        canceledCount++;
      } else if (statusValue == 'Expired') {
        expiredCount++;
      } else if (statusValue == 'Setup Complete') {
        setupCompleteCount++;
      } else if (statusValue == 'Pending Sales') {
        pendingSalesCount++;
      } else if (statusValue == 'In Process') {
        inProcessCount++;
      } else if (statusValue == 'Pending Initial Review') {
        pendingInitialReviewCount++;
      } else if (statusValue == 'Paperwork Sent') {
        paperworkSentCount++;
      }
    }
  }

  private class StatusOutcome {
    String status;
    Boolean completed;

    StatusOutcome(String status, Boolean completed) {
      this.status = status;
      this.completed = completed;
    }
  }

  private static StatusOutcome determineOutcome(StatusCounts counts) {
    if (counts == null) {
      return new StatusOutcome('New', false);
    }

    if (counts.deniedCount > 0) {
      return new StatusOutcome('Denied', false);
    }
    if (counts.canceledCount > 0) {
      return new StatusOutcome('Canceled', false);
    }
    if (counts.expiredCount > 0) {
      return new StatusOutcome('Expired', false);
    }
    if (counts.totalCount > 0 && counts.totalCount == counts.setupCompleteCount) {
      return new StatusOutcome('Setup Complete', true);
    }
    if (counts.pendingSalesCount > 0) {
      return new StatusOutcome('Pending Sales', false);
    }
    if (counts.inProcessCount > 0) {
      return new StatusOutcome('In Process', false);
    }
    if (counts.pendingInitialReviewCount > 0) {
      return new StatusOutcome('Pending Initial Review', false);
    }
    if (counts.paperworkSentCount > 0) {
      return new StatusOutcome('Paperwork Sent', false);
    }
    if (counts.setupCompleteCount > 0) {
      return new StatusOutcome('In Process', false);
    }
    return new StatusOutcome('New', false);
  }
}
