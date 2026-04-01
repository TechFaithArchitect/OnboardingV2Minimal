@IsTest
private class OnbReqParentBulkEvalInvocableTest {
  private static String getOpportunityStageName() {
    List<Schema.PicklistEntry> entries = Opportunity.StageName.getDescribe().getPicklistValues();
    return entries.isEmpty() ? 'Prospecting' : entries[0].getValue();
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

  @TestSetup
  static void setupData() {
    Account acc = new Account(Name = 'Bulk Eval Account');
    insert acc;

    Opportunity opp = new Opportunity(
      Name = 'Bulk Eval Opp',
      AccountId = acc.Id,
      StageName = getOpportunityStageName(),
      CloseDate = Date.today().addDays(30)
    );
    insert opp;

    TestDataFactoryWrapper.VendorCustomizationWrapper vpWrap = TestVendorProgramFactory.createVendorWithCustomization(
      true
    );

    Onboarding__c onb = new Onboarding__c(
      Account__c = acc.Id,
      Opportunity__c = opp.Id,
      Vendor_Customization__c = vpWrap.customization.Id,
      Onboarding_Status__c = 'Setup Complete',
      Assigned_Team__c = 'Onboarding'
    );
    insert onb;

    String requirementType = discoverInsertableRequirementType(onb.Id);
    System.assertNotEquals(
      null,
      requirementType,
      'Expected at least one insertable onboarding requirement type for this org context.'
    );

    Onboarding_Requirement__c reqSetupComplete = new Onboarding_Requirement__c(
      Onboarding__c = onb.Id,
      Requirement_Type__c = requirementType,
      Completed__c = false
    );
    Onboarding_Requirement__c reqPendingSales = new Onboarding_Requirement__c(
      Onboarding__c = onb.Id,
      Requirement_Type__c = requirementType,
      Completed__c = false
    );
    Onboarding_Requirement__c reqDenied = new Onboarding_Requirement__c(
      Onboarding__c = onb.Id,
      Requirement_Type__c = requirementType,
      Completed__c = false
    );
    insert new List<Onboarding_Requirement__c>{ reqSetupComplete, reqPendingSales, reqDenied };

    insert new List<Onboarding_Requirement_Subject__c>{
      new Onboarding_Requirement_Subject__c(
        Onboarding_Requirement__c = reqSetupComplete.Id,
        Account__c = acc.Id,
        Status__c = 'Setup Complete',
        Unique_Key__c = reqSetupComplete.Id + '|1'
      ),
      new Onboarding_Requirement_Subject__c(
        Onboarding_Requirement__c = reqSetupComplete.Id,
        Account__c = acc.Id,
        Status__c = 'Setup Complete',
        Unique_Key__c = reqSetupComplete.Id + '|2'
      ),
      new Onboarding_Requirement_Subject__c(
        Onboarding_Requirement__c = reqPendingSales.Id,
        Account__c = acc.Id,
        Status__c = 'Pending Sales',
        Unique_Key__c = reqPendingSales.Id + '|1'
      ),
      new Onboarding_Requirement_Subject__c(
        Onboarding_Requirement__c = reqDenied.Id,
        Account__c = acc.Id,
        Status__c = 'Denied',
        Unique_Key__c = reqDenied.Id + '|1'
      )
    };
  }

  @IsTest
  static void evaluate_updatesStatusesInBulk() {
    List<Onboarding_Requirement__c> requirements = [
      SELECT Id
      FROM Onboarding_Requirement__c
      ORDER BY CreatedDate ASC
    ];

    OnbReqParentBulkEvalInvocable.EvaluateRequest req =
      new OnbReqParentBulkEvalInvocable.EvaluateRequest();
    req.onboardingRequirementIds = new List<String>{
      String.valueOf(requirements[0].Id),
      String.valueOf(requirements[1].Id),
      String.valueOf(requirements[2].Id)
    };

    Test.startTest();
    List<OnbReqParentBulkEvalInvocable.EvaluateResult> results =
      OnbReqParentBulkEvalInvocable.evaluate(
        new List<OnbReqParentBulkEvalInvocable.EvaluateRequest>{ req }
      );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Expected one result row');
    System.assertEquals('', results[0].errorMessage, 'Expected no error');
    System.assertEquals(3, results[0].processedCount, 'Expected 3 processed');
    System.assert(results[0].updatedCount > 0, 'Expected at least one update');
    System.assertEquals(0, results[0].failedCount, 'Expected no failures');

    Map<Id, Onboarding_Requirement__c> updatedById = new Map<Id, Onboarding_Requirement__c>([
      SELECT Id, Status__c, Completed__c
      FROM Onboarding_Requirement__c
      WHERE Id IN :new Map<Id, Onboarding_Requirement__c>(requirements).keySet()
    ]);

    System.assertEquals(true, updatedById.get(requirements[0].Id).Completed__c);
    System.assertEquals(false, updatedById.get(requirements[1].Id).Completed__c);
    System.assertEquals(false, updatedById.get(requirements[2].Id).Completed__c);
  }

  @IsTest
  static void evaluate_noChangeDoesNotUpdate() {
    Id onboardingId = [
      SELECT Onboarding__c
      FROM Onboarding_Requirement__c
      LIMIT 1
    ].Onboarding__c;
    Onboarding__c onboardingRecord = [
      SELECT Id, Account__c
      FROM Onboarding__c
      WHERE Id = :onboardingId
      LIMIT 1
    ];
    String requirementType = discoverInsertableRequirementType(onboardingRecord.Id);
    System.assertNotEquals(
      null,
      requirementType,
      'Expected at least one insertable onboarding requirement type for this org context.'
    );

    Onboarding_Requirement__c reqNoChange = new Onboarding_Requirement__c(
      Onboarding__c = onboardingRecord.Id,
      Requirement_Type__c = requirementType,
      Completed__c = false
    );
    insert reqNoChange;
    insert new Onboarding_Requirement_Subject__c(
      Onboarding_Requirement__c = reqNoChange.Id,
      Account__c = onboardingRecord.Account__c,
      Status__c = 'Setup Complete',
      Unique_Key__c = reqNoChange.Id + '|nochange'
    );

    OnbReqParentBulkEvalInvocable.EvaluateRequest req =
      new OnbReqParentBulkEvalInvocable.EvaluateRequest();
    req.onboardingRequirementIds = new List<String>{ String.valueOf(reqNoChange.Id) };

    List<OnbReqParentBulkEvalInvocable.EvaluateResult> firstResults =
      OnbReqParentBulkEvalInvocable.evaluate(
        new List<OnbReqParentBulkEvalInvocable.EvaluateRequest>{ req }
      );
    System.assert(firstResults[0].updatedCount > 0, 'Expected first pass to update');

    List<OnbReqParentBulkEvalInvocable.EvaluateResult> results =
      OnbReqParentBulkEvalInvocable.evaluate(
        new List<OnbReqParentBulkEvalInvocable.EvaluateRequest>{ req }
      );

    System.assertEquals(1, results.size(), 'Expected one result');
    System.assertEquals('', results[0].errorMessage, 'Expected no error');
    System.assertEquals(1, results[0].processedCount, 'Expected one processed');
    System.assertEquals(0, results[0].updatedCount, 'Expected no update needed');
    System.assertEquals(0, results[0].failedCount, 'Expected no failures');
  }

  @IsTest
  static void evaluate_invalidOrMissingIdsReturnsError() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    OnbReqParentBulkEvalInvocable.EvaluateRequest req =
      new OnbReqParentBulkEvalInvocable.EvaluateRequest();
    req.onboardingRequirementIds = new List<String>{ 'not-an-id', String.valueOf(acc.Id) };

    List<OnbReqParentBulkEvalInvocable.EvaluateResult> results =
      OnbReqParentBulkEvalInvocable.evaluate(
        new List<OnbReqParentBulkEvalInvocable.EvaluateRequest>{ req }
      );

    System.assertEquals(1, results.size(), 'Expected one result');
    System.assert(results[0].errorMessage.contains('not found'), 'Expected not-found error detail');
    System.assertEquals(0, results[0].processedCount, 'No requirements should be processed');
    System.assertEquals(0, results[0].updatedCount, 'No updates expected');
    System.assertEquals(1, results[0].failedCount, 'Expected one missing id');
  }

  @IsTest
  static void evaluate_emptyRequestListReturnsSingleDefaultResult() {
    List<OnbReqParentBulkEvalInvocable.EvaluateResult> results =
      OnbReqParentBulkEvalInvocable.evaluate(null);

    System.assertEquals(1, results.size(), 'Expected one default result');
    System.assertEquals('', results[0].errorMessage, 'Expected empty error');
    System.assertEquals(0, results[0].processedCount, 'Expected zero processed');
    System.assertEquals(0, results[0].updatedCount, 'Expected zero updated');
    System.assertEquals(0, results[0].failedCount, 'Expected zero failed');
  }

  @IsTest
  static void fallbackStatusesForTest_coversOutcomeBranches() {
    System.assert(
      OnbReqParentBulkEvalInvocable.fallbackStatusesForTest('Setup Complete', 'Legacy').contains('Complete'),
      'Setup Complete branch should include Complete fallback'
    );
    System.assert(
      OnbReqParentBulkEvalInvocable.fallbackStatusesForTest('Pending Sales', 'Legacy').contains('In Progress'),
      'Pending Sales branch should include In Progress fallback'
    );
    System.assert(
      OnbReqParentBulkEvalInvocable.fallbackStatusesForTest('Denied', 'Legacy').contains('Incomplete'),
      'Denied branch should include Incomplete fallback'
    );
    System.assert(
      OnbReqParentBulkEvalInvocable.fallbackStatusesForTest('Canceled', 'Legacy').contains('Denied'),
      'Canceled branch should include Denied fallback'
    );
    System.assert(
      OnbReqParentBulkEvalInvocable.fallbackStatusesForTest('Expired', 'Legacy').contains('Draft'),
      'Expired branch should include Draft fallback'
    );
    System.assert(
      OnbReqParentBulkEvalInvocable.fallbackStatusesForTest('In Process', 'Legacy').contains('Pending Initial Review'),
      'In Process branch should include Pending Initial Review fallback'
    );
    System.assert(
      OnbReqParentBulkEvalInvocable.fallbackStatusesForTest('Pending Initial Review', 'Legacy').contains('Paperwork Sent'),
      'Pending Initial Review branch should include Paperwork Sent fallback'
    );
    System.assert(
      OnbReqParentBulkEvalInvocable.fallbackStatusesForTest('Paperwork Sent', 'Legacy').contains('In Process'),
      'Paperwork Sent branch should include In Process fallback'
    );

    List<String> defaultBranch = OnbReqParentBulkEvalInvocable.fallbackStatusesForTest('Unmapped', 'Legacy');
    System.assert(defaultBranch.contains('New'), 'Default branch should include New');
    System.assert(defaultBranch.contains('Legacy'), 'Current status should be included when provided');
  }
}
