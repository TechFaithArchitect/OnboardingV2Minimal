@IsTest
private class OnbReqSubjectInvocableTest {

  @IsTest
  static void createSubjectsIdempotent_insertsNewRecords() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;
    Onboarding__c onb = new Onboarding__c(Account__c = acc.Id);
    insert onb;
    Onboarding_Requirement__c req = new Onboarding_Requirement__c(
      Onboarding__c = onb.Id,
      Requirement_Type__c = 'Training'
    );
    insert req;

    Onboarding_Requirement_Subject__c sub = new Onboarding_Requirement_Subject__c(
      Onboarding_Requirement__c = req.Id,
      Account__c = acc.Id,
      Status__c = 'New',
      Requirement_Type__c = 'Training',
      Unique_Key__c = req.Id + '|' + acc.Id
    );

    OnboardingRequirementSubjectInvocable.CreateSubjectsRequest reqItem =
      new OnboardingRequirementSubjectInvocable.CreateSubjectsRequest();
    reqItem.subjectRecords = new List<SObject>{ sub };

    Test.startTest();
    List<OnboardingRequirementSubjectInvocable.CreateSubjectsResult> results =
      OnboardingRequirementSubjectInvocable.createSubjectsIdempotent(
        new List<OnboardingRequirementSubjectInvocable.CreateSubjectsRequest>{ reqItem }
      );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Expected one result');
    System.assert(results[0].errorMessage == null || results[0].errorMessage == '', 'Expected no error');
    System.assertEquals(1, [SELECT COUNT() FROM Onboarding_Requirement_Subject__c WHERE Unique_Key__c = :sub.Unique_Key__c], 'Expected one subject created');
  }

  @IsTest
  static void createSubjectsIdempotent_skipsExistingUniqueKey() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;
    Onboarding__c onb = new Onboarding__c(Account__c = acc.Id);
    insert onb;
    Onboarding_Requirement__c req = new Onboarding_Requirement__c(
      Onboarding__c = onb.Id,
      Requirement_Type__c = 'Training'
    );
    insert req;

    String uniqueKey = req.Id + '|' + acc.Id;
    Onboarding_Requirement_Subject__c existing = new Onboarding_Requirement_Subject__c(
      Onboarding_Requirement__c = req.Id,
      Account__c = acc.Id,
      Status__c = 'New',
      Requirement_Type__c = 'Training',
      Unique_Key__c = uniqueKey
    );
    insert existing;

    Onboarding_Requirement_Subject__c duplicate = new Onboarding_Requirement_Subject__c(
      Onboarding_Requirement__c = req.Id,
      Account__c = acc.Id,
      Status__c = 'New',
      Requirement_Type__c = 'Training',
      Unique_Key__c = uniqueKey
    );

    OnboardingRequirementSubjectInvocable.CreateSubjectsRequest reqItem =
      new OnboardingRequirementSubjectInvocable.CreateSubjectsRequest();
    reqItem.subjectRecords = new List<SObject>{ duplicate };

    Test.startTest();
    List<OnboardingRequirementSubjectInvocable.CreateSubjectsResult> results =
      OnboardingRequirementSubjectInvocable.createSubjectsIdempotent(
        new List<OnboardingRequirementSubjectInvocable.CreateSubjectsRequest>{ reqItem }
      );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Expected one result');
    System.assert(results[0].errorMessage == null || results[0].errorMessage == '', 'Expected no error');
    System.assertEquals(1, [SELECT COUNT() FROM Onboarding_Requirement_Subject__c WHERE Unique_Key__c = :uniqueKey], 'Expected no duplicate created');
  }

  @IsTest
  static void createSubjectsIdempotent_emptyRequest() {
    OnboardingRequirementSubjectInvocable.CreateSubjectsRequest reqItem =
      new OnboardingRequirementSubjectInvocable.CreateSubjectsRequest();
    reqItem.subjectRecords = new List<SObject>();

    List<OnboardingRequirementSubjectInvocable.CreateSubjectsResult> results =
      OnboardingRequirementSubjectInvocable.createSubjectsIdempotent(
        new List<OnboardingRequirementSubjectInvocable.CreateSubjectsRequest>{ reqItem }
      );

    System.assertEquals(1, results.size(), 'Expected one result');
    System.assert(results[0].errorMessage == null || results[0].errorMessage == '', 'Expected no error');
  }
}
