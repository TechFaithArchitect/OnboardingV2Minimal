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

    for (CreateSubjectsRequest req : requests) {
      CreateSubjectsResult res = new CreateSubjectsResult();
      if (req == null || req.subjectRecords == null || req.subjectRecords.isEmpty()) {
        results.add(res);
        continue;
      }

      try {
        List<Onboarding_Requirement_Subject__c> subjects =
          (List<Onboarding_Requirement_Subject__c>) req.subjectRecords;
        Set<String> keys = new Set<String>();
        for (Onboarding_Requirement_Subject__c s : subjects) {
          if (String.isNotBlank(s.Unique_Key__c)) {
            keys.add(s.Unique_Key__c);
          }
        }

        Set<String> existingKeys = new Set<String>();
        if (!keys.isEmpty()) {
          for (Onboarding_Requirement_Subject__c existing : [
            SELECT Unique_Key__c
            FROM Onboarding_Requirement_Subject__c
            WHERE Unique_Key__c IN :keys
            WITH SECURITY_ENFORCED
          ]) {
            existingKeys.add(existing.Unique_Key__c);
          }
        }

        List<Onboarding_Requirement_Subject__c> toInsert = new List<Onboarding_Requirement_Subject__c>();
        for (Onboarding_Requirement_Subject__c s : subjects) {
          if (String.isBlank(s.Unique_Key__c) || !existingKeys.contains(s.Unique_Key__c)) {
            toInsert.add(s);
          }
        }

        if (!toInsert.isEmpty()) {
          insert toInsert;
        }
      } catch (Exception ex) {
        LoggingUtil.error(
          'OnboardingRequirementSubjectInvocable.createSubjectsIdempotent: ' + ex.getMessage()
        );
        res.errorMessage = ex.getMessage();
      }
      results.add(res);
    }
    return results;
  }
}
