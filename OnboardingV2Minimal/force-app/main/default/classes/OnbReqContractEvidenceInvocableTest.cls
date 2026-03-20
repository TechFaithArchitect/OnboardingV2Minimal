@IsTest
private class OnbReqContractEvidenceInvocableTest {
  private static String getOpportunityStageName() {
    List<Schema.PicklistEntry> entries = Opportunity.StageName.getDescribe().getPicklistValues();
    return entries.isEmpty() ? 'Prospecting' : entries[0].getValue();
  }

  private static Contract createContract(Account accountRecord, Contact primaryContact) {
    Opportunity opportunityRecord = new Opportunity(
      Name = 'Opp ' + String.valueOf(Crypto.getRandomInteger()),
      StageName = getOpportunityStageName(),
      CloseDate = Date.today().addDays(30),
      AccountId = accountRecord.Id
    );
    insert opportunityRecord;

    Contract contractRecord = new Contract(
      AccountId = accountRecord.Id,
      StartDate = Date.today(),
      ContractTerm = 12,
      Status = 'Draft',
      Principal_Owner__c = primaryContact.Id,
      Opportunity_to_Contract__c = opportunityRecord.Id
    );
    insert contractRecord;
    return contractRecord;
  }

  @IsTest
  static void evaluate_updatesOnlyMatchingContractAndType() {
    Account accountRecord = TestDataFactory.createAccount('OnbReq Contract Scope', true);
    Contact primaryContact = TestDataFactory.createContact('Primary', 'Owner', true, accountRecord);

    Contract contractA = createContract(accountRecord, primaryContact);
    Contract contractB = createContract(accountRecord, primaryContact);

    Onboarding__c onboardingA = new Onboarding__c(Account__c = accountRecord.Id, Contract__c = contractA.Id);
    Onboarding__c onboardingB = new Onboarding__c(Account__c = accountRecord.Id, Contract__c = contractB.Id);
    insert new List<Onboarding__c>{ onboardingA, onboardingB };

    Onboarding_Requirement__c reqA = new Onboarding_Requirement__c(
      Onboarding__c = onboardingA.Id,
      Status__c = 'Draft',
      Completed__c = false
    );
    Onboarding_Requirement__c reqB = new Onboarding_Requirement__c(
      Onboarding__c = onboardingB.Id,
      Status__c = 'Draft',
      Completed__c = false
    );
    insert new List<Onboarding_Requirement__c>{ reqA, reqB };
    Map<Id, Onboarding_Requirement__c> requirementsById = new Map<Id, Onboarding_Requirement__c>([
      SELECT Id, Requirement_Type__c
      FROM Onboarding_Requirement__c
      WHERE Id IN :new Set<Id>{ reqA.Id, reqB.Id }
    ]);
    String targetRequirementType = requirementsById.get(reqA.Id).Requirement_Type__c;

    Onboarding_Requirement_Subject__c reqASubject = new Onboarding_Requirement_Subject__c(
      Onboarding_Requirement__c = reqA.Id,
      Account__c = accountRecord.Id,
      Status__c = 'New',
      Unique_Key__c = reqA.Id + '|A'
    );
    Onboarding_Requirement_Subject__c reqASecondSubject = new Onboarding_Requirement_Subject__c(
      Onboarding_Requirement__c = reqA.Id,
      Account__c = accountRecord.Id,
      Status__c = 'New',
      Unique_Key__c = reqA.Id + '|A2'
    );
    Onboarding_Requirement_Subject__c reqBSubject = new Onboarding_Requirement_Subject__c(
      Onboarding_Requirement__c = reqB.Id,
      Account__c = accountRecord.Id,
      Status__c = 'New',
      Unique_Key__c = reqB.Id + '|B'
    );
    insert new List<Onboarding_Requirement_Subject__c>{
      reqASubject,
      reqASecondSubject,
      reqBSubject
    };

    OnbReqContractEvidenceInvocable.EvaluateRequest request =
      new OnbReqContractEvidenceInvocable.EvaluateRequest();
    request.contractId = contractA.Id;
    request.requirementType = targetRequirementType;
    request.evidenceStatus = 'Signed';
    request.applyOnboardingStatus = false;

    Test.startTest();
    List<OnbReqContractEvidenceInvocable.EvaluateResult> results =
      OnbReqContractEvidenceInvocable.evaluate(
        new List<OnbReqContractEvidenceInvocable.EvaluateRequest>{ request }
      );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Expected a single result row');
    System.assertEquals(null, results[0].errorMessage, 'Expected no row-level error');
    System.assertEquals(1, results[0].matchedOnboardingCount, 'Expected one onboarding in scope');
    System.assertEquals(1, results[0].matchedRequirementCount, 'Expected one requirement in scope');
    System.assertEquals(2, results[0].updatedSubjectCount, 'Expected two subject updates');

    Map<Id, Onboarding_Requirement_Subject__c> subjectsById = new Map<Id, Onboarding_Requirement_Subject__c>([
      SELECT Id, Status__c
      FROM Onboarding_Requirement_Subject__c
      WHERE Id IN :new Set<Id>{ reqASubject.Id, reqASecondSubject.Id, reqBSubject.Id }
    ]);

    System.assertEquals(
      'Setup Complete',
      subjectsById.get(reqASubject.Id).Status__c,
      'Matching contract + type should be updated (subject 1)'
    );
    System.assertEquals(
      'Setup Complete',
      subjectsById.get(reqASecondSubject.Id).Status__c,
      'Matching contract + type should be updated (subject 2)'
    );
    System.assertEquals(
      'New',
      subjectsById.get(reqBSubject.Id).Status__c,
      'Non-matching contract should remain unchanged'
    );
  }

  @IsTest
  static void evaluate_returnsErrorsForInvalidRequests() {
    Account accountRecord = TestDataFactory.createAccount('OnbReq Invalid', true);
    Contact primaryContact = TestDataFactory.createContact('Primary', 'Invalid', true, accountRecord);
    Contract contractRecord = createContract(accountRecord, primaryContact);

    OnbReqContractEvidenceInvocable.EvaluateRequest missingContract =
      new OnbReqContractEvidenceInvocable.EvaluateRequest();
    missingContract.requirementType = 'Agreement';
    missingContract.evidenceStatus = 'Signed';

    OnbReqContractEvidenceInvocable.EvaluateRequest unsupportedStatus =
      new OnbReqContractEvidenceInvocable.EvaluateRequest();
    unsupportedStatus.contractId = contractRecord.Id;
    unsupportedStatus.requirementType = 'Agreement';
    unsupportedStatus.evidenceStatus = 'Totally Unsupported';

    List<OnbReqContractEvidenceInvocable.EvaluateResult> results =
      OnbReqContractEvidenceInvocable.evaluate(
        new List<OnbReqContractEvidenceInvocable.EvaluateRequest>{ missingContract, unsupportedStatus }
      );

    System.assertEquals(2, results.size(), 'Expected two result rows');
    System.assert(
      results[0].errorMessage.contains('Contract Id is required'),
      'Missing contract should produce a clear validation error'
    );
    System.assert(
      results[1].errorMessage.contains('Unsupported evidence status'),
      'Unsupported evidence status should produce a clear validation error'
    );

    List<OnbReqContractEvidenceInvocable.EvaluateResult> nullRequestResults =
      OnbReqContractEvidenceInvocable.evaluate(null);
    System.assertEquals(1, nullRequestResults.size(), 'Null request list should return one default row');
  }

  @IsTest
  static void evaluate_coversAgreementPointerAndStatusApplyBranches() {
    Account accountRecord = TestDataFactory.createAccount('OnbReq Branch Coverage', true);
    Contact primaryContact = TestDataFactory.createContact('Primary', 'Branch', true, accountRecord);
    Contract contractRecord = createContract(accountRecord, primaryContact);

    Onboarding__c onboardingRecord = new Onboarding__c(
      Account__c = accountRecord.Id,
      Contract__c = contractRecord.Id
    );
    insert onboardingRecord;

    Onboarding_Requirement__c requirementRecord = new Onboarding_Requirement__c(
      Onboarding__c = onboardingRecord.Id,
      Status__c = 'Draft',
      Completed__c = false
    );
    insert requirementRecord;
    requirementRecord = [
      SELECT Id, Requirement_Type__c
      FROM Onboarding_Requirement__c
      WHERE Id = :requirementRecord.Id
      LIMIT 1
    ];

    Onboarding_Requirement_Subject__c subjectRecord = new Onboarding_Requirement_Subject__c(
      Onboarding_Requirement__c = requirementRecord.Id,
      Account__c = accountRecord.Id,
      Status__c = 'New',
      Unique_Key__c = requirementRecord.Id + '|coverage'
    );
    insert subjectRecord;

    String keyPrefix = echosign_dev1__SIGN_Agreement__c.SObjectType.getDescribe().getKeyPrefix();
    Id syntheticAgreementId = (Id)(keyPrefix + '000000000000');

    OnbReqContractEvidenceInvocable.EvaluateRequest request =
      new OnbReqContractEvidenceInvocable.EvaluateRequest();
    request.contractId = contractRecord.Id;
    request.requirementType = requirementRecord.Requirement_Type__c;
    request.evidenceStatus = 'Signed';
    request.agreementId = syntheticAgreementId;
    request.applyOnboardingStatus = true;

    Test.startTest();
    List<OnbReqContractEvidenceInvocable.EvaluateResult> results =
      OnbReqContractEvidenceInvocable.evaluate(
        new List<OnbReqContractEvidenceInvocable.EvaluateRequest>{ request }
      );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Expected one result row');
    System.assertEquals(1, results[0].matchedOnboardingCount, 'Expected one onboarding in scope');
    System.assertEquals(1, results[0].matchedRequirementCount, 'Expected one requirement in scope');
    System.assertEquals(1, results[0].updatedSubjectCount, 'Expected one subject update');
    System.assert(
      String.isNotBlank(results[0].errorMessage),
      'Expected an error for synthetic agreement pointer update'
    );

    Onboarding_Requirement_Subject__c updatedSubject = [
      SELECT Status__c
      FROM Onboarding_Requirement_Subject__c
      WHERE Id = :subjectRecord.Id
      LIMIT 1
    ];
    System.assertEquals(
      'Setup Complete',
      updatedSubject.Status__c,
      'Subject should still normalize despite agreement pointer failure'
    );
  }

  @IsTest
  static void mapEvidenceStatus_coversKeyMappings() {
    System.assertEquals('Setup Complete', OnbReqContractEvidenceInvocable.mapEvidenceStatus('Signed'));
    System.assertEquals('Denied', OnbReqContractEvidenceInvocable.mapEvidenceStatus('Denied by PV'));
    System.assertEquals('Canceled', OnbReqContractEvidenceInvocable.mapEvidenceStatus('Cancelled'));
    System.assertEquals('Expired', OnbReqContractEvidenceInvocable.mapEvidenceStatus('Expired'));
    System.assertEquals('In Process', OnbReqContractEvidenceInvocable.mapEvidenceStatus('Incomplete'));
    System.assertEquals('Paperwork Sent', OnbReqContractEvidenceInvocable.mapEvidenceStatus('Out for Signature'));
    System.assertEquals('New', OnbReqContractEvidenceInvocable.mapEvidenceStatus('Assigned'));
    System.assertEquals(null, OnbReqContractEvidenceInvocable.mapEvidenceStatus('Unknown'));
  }
}
