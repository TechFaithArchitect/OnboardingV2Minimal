@IsTest
private class OnbReqSubjectInvocableTest {
  private static String getOpportunityStageName() {
    List<Schema.PicklistEntry> entries = Opportunity.StageName.getDescribe().getPicklistValues();
    return entries.isEmpty() ? 'Prospecting' : entries[0].getValue();
  }

  private static Onboarding__c createOnboardingWithContext(Account accountRecord) {
    Opportunity opportunityRecord = new Opportunity(
      Name = 'Subject Invocable Opp',
      AccountId = accountRecord.Id,
      StageName = getOpportunityStageName(),
      CloseDate = Date.today().addDays(30)
    );
    insert opportunityRecord;

    TestDataFactoryWrapper.VendorCustomizationWrapper vpWrap = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );

    Onboarding__c onboardingRecord = new Onboarding__c(
      Account__c = accountRecord.Id,
      Opportunity__c = opportunityRecord.Id,
      Vendor_Customization__c = vpWrap.customization.Id,
      Onboarding_Status__c = 'Setup Complete',
      Assigned_Team__c = 'Onboarding'
    );
    insert onboardingRecord;
    return onboardingRecord;
  }

  private static String discoverInsertableRequirementType(Id onboardingId) {
    List<String> values = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Requirement__c.SObjectType,
      'Requirement_Type__c'
    );
    List<String> ordered = new List<String>();
    for (String value : values) {
      if (
        value != null &&
        !value.equalsIgnoreCase('Agreement') &&
        !value.equalsIgnoreCase('Contract') &&
        !value.equalsIgnoreCase('Training')
      ) {
        ordered.add(value);
      }
    }
    for (String value : values) {
      if (value != null && !ordered.contains(value)) {
        ordered.add(value);
      }
    }

    for (String candidate : ordered) {
      Database.SaveResult probeResult = Database.insert(
        new Onboarding_Requirement__c(
          Onboarding__c = onboardingId,
          Requirement_Type__c = candidate,
          Status__c = 'Draft',
          Is_Overridden__c = false
        ),
        false
      );
      if (probeResult.isSuccess()) {
        delete new Onboarding_Requirement__c(Id = probeResult.getId());
        return candidate;
      }
    }
    return null;
  }

  @IsTest
  static void createSubjectsIdempotent_insertsNewRecords() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;
    Onboarding__c onb = createOnboardingWithContext(acc);
    String requirementType = discoverInsertableRequirementType(onb.Id);
    System.assertNotEquals(
      null,
      requirementType,
      'Expected at least one insertable onboarding requirement type for this org context.'
    );

    Onboarding_Requirement__c req = new Onboarding_Requirement__c(
      Onboarding__c = onb.Id,
      Requirement_Type__c = requirementType
    );
    insert req;
    req = [
      SELECT Id, Requirement_Type__c
      FROM Onboarding_Requirement__c
      WHERE Id = :req.Id
      LIMIT 1
    ];

    Onboarding_Requirement_Subject__c sub = new Onboarding_Requirement_Subject__c(
      Onboarding_Requirement__c = req.Id,
      Account__c = acc.Id,
      Status__c = 'New',
      Requirement_Type__c = requirementType,
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
    Onboarding__c onb = createOnboardingWithContext(acc);
    String requirementType = discoverInsertableRequirementType(onb.Id);
    System.assertNotEquals(
      null,
      requirementType,
      'Expected at least one insertable onboarding requirement type for this org context.'
    );

    Onboarding_Requirement__c req = new Onboarding_Requirement__c(
      Onboarding__c = onb.Id,
      Requirement_Type__c = requirementType
    );
    insert req;
    req = [
      SELECT Id, Requirement_Type__c
      FROM Onboarding_Requirement__c
      WHERE Id = :req.Id
      LIMIT 1
    ];

    String uniqueKey = req.Id + '|' + acc.Id;
    Onboarding_Requirement_Subject__c existing = new Onboarding_Requirement_Subject__c(
      Onboarding_Requirement__c = req.Id,
      Account__c = acc.Id,
      Status__c = 'New',
      Requirement_Type__c = requirementType,
      Unique_Key__c = uniqueKey
    );
    insert existing;

    Onboarding_Requirement_Subject__c duplicate = new Onboarding_Requirement_Subject__c(
      Onboarding_Requirement__c = req.Id,
      Account__c = acc.Id,
      Status__c = 'New',
      Requirement_Type__c = requirementType,
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
