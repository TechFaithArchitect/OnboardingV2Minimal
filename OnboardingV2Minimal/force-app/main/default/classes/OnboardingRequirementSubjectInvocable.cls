public with sharing class OnboardingRequirementSubjectInvocable {

  public class CreateSubjectsRequest {
    @InvocableVariable(required=true label='Subject Records')
    public List<SObject> subjectRecords;
  }

  public class CreateSubjectsResult {
    @InvocableVariable(label='Error Message')
    public String errorMessage;
  }

  @InvocableMethod(
    label='Create Onboarding Requirement Subjects (Idempotent)'
    description='Inserts subject records, skipping those whose Unique_Key__c already exists. Handles duplicate-key conflicts for retries.'
  )
  public static List<CreateSubjectsResult> createSubjectsIdempotent(
    List<CreateSubjectsRequest> requests
  ) {
    List<CreateSubjectsResult> results = new List<CreateSubjectsResult>();
    if (requests == null || requests.isEmpty()) {
      return results;
    }

    List<List<Onboarding_Requirement_Subject__c>> subjectsByRequestIndex =
      new List<List<Onboarding_Requirement_Subject__c>>();
    Set<String> keys = new Set<String>();

    for (Integer requestIndex = 0; requestIndex < requests.size(); requestIndex++) {
      CreateSubjectsResult resultItem = new CreateSubjectsResult();
      results.add(resultItem);
      subjectsByRequestIndex.add(new List<Onboarding_Requirement_Subject__c>());

      CreateSubjectsRequest requestItem = requests[requestIndex];
      if (requestItem == null || requestItem.subjectRecords == null || requestItem.subjectRecords.isEmpty()) {
        continue;
      }

      try {
        List<Onboarding_Requirement_Subject__c> typedSubjects =
          (List<Onboarding_Requirement_Subject__c>) requestItem.subjectRecords;
        subjectsByRequestIndex[requestIndex] = typedSubjects;
        for (Onboarding_Requirement_Subject__c subjectItem : typedSubjects) {
          if (subjectItem != null && String.isNotBlank(subjectItem.Unique_Key__c)) {
            keys.add(subjectItem.Unique_Key__c);
          }
        }
      } catch (Exception ex) {
        logAndSetError(resultItem, ex);
      }
    }

    Set<String> existingKeys = new Set<String>();
    if (!keys.isEmpty()) {
      for (Onboarding_Requirement_Subject__c existingSubject : [
        SELECT Unique_Key__c
        FROM Onboarding_Requirement_Subject__c
        WHERE Unique_Key__c IN :keys
        WITH SECURITY_ENFORCED
      ]) {
        if (String.isNotBlank(existingSubject.Unique_Key__c)) {
          existingKeys.add(existingSubject.Unique_Key__c);
        }
      }
    }

    List<Onboarding_Requirement_Subject__c> subjectsToInsert = new List<Onboarding_Requirement_Subject__c>();
    List<Integer> requestIndexByInsertIndex = new List<Integer>();
    for (Integer requestIndex = 0; requestIndex < subjectsByRequestIndex.size(); requestIndex++) {
      if (String.isNotBlank(results[requestIndex].errorMessage)) {
        continue;
      }

      for (Onboarding_Requirement_Subject__c subjectItem : subjectsByRequestIndex[requestIndex]) {
        if (subjectItem == null) {
          continue;
        }
        if (String.isBlank(subjectItem.Unique_Key__c) || !existingKeys.contains(subjectItem.Unique_Key__c)) {
          subjectsToInsert.add(subjectItem);
          requestIndexByInsertIndex.add(requestIndex);
        }
      }
    }

    if (!subjectsToInsert.isEmpty()) {
      List<SObject> sanitizedForCreate = Security.stripInaccessible(
        AccessType.CREATABLE,
        subjectsToInsert
      ).getRecords();
      if (!sanitizedForCreate.isEmpty()) {
        List<Onboarding_Requirement_Subject__c> typedForCreate =
          (List<Onboarding_Requirement_Subject__c>) sanitizedForCreate;
        Database.SaveResult[] saveResults = Database.insert(
          typedForCreate,
          false,
          AccessLevel.USER_MODE
        );

        for (Integer i = 0; i < saveResults.size(); i++) {
          if (saveResults[i].isSuccess()) {
            continue;
          }
          Integer requestIndex = requestIndexByInsertIndex[i];
          if (String.isNotBlank(results[requestIndex].errorMessage)) {
            continue;
          }
          Database.Error firstError =
            saveResults[i].getErrors().isEmpty() ? null : saveResults[i].getErrors()[0];
          String errorMessage = firstError == null ? 'Failed to create onboarding requirement subject.' : firstError.getMessage();
          results[requestIndex].errorMessage = errorMessage;
          LoggingUtil.error('OnboardingRequirementSubjectInvocable.createSubjectsIdempotent: ' + errorMessage);
        }
      }
    }
    return results;
  }

  private static void logAndSetError(CreateSubjectsResult resultItem, Exception ex) {
    if (resultItem == null || ex == null) {
      return;
    }
    LoggingUtil.error('OnboardingRequirementSubjectInvocable.createSubjectsIdempotent: ' + ex.getMessage());
    resultItem.errorMessage = ex.getMessage();
  }
}
