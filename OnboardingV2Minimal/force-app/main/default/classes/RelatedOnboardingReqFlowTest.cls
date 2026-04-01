@IsTest
private class RelatedOnboardingReqFlowTest {
  private static final String FLOW_API_NAME = 'DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records';

  @IsTest
  static void testReturnsErrorWhenNeitherInputRecordProvided() {
    Test.startTest();
    Flow.Interview interview = runFlow(new Map<String, Object>());
    Test.stopTest();

    System.assertEquals(
      'Error: Neither the Onboarding Record Nor the Onboarding Requirement Record Were Passed',
      toStringValue(interview.getVariableValue('errorMessage')),
      'Flow should return explicit error for missing invocation context.'
    );
  }

  @IsTest
  static void testReturnsErrorWhenOnlyOnboardingRecordProvided() {
    Account accountRecord = new Account(Name = 'Onboarding-only');
    insert accountRecord;
    Onboarding__c onboardingRecord = new Onboarding__c(Account__c = accountRecord.Id);
    insert onboardingRecord;

    Map<String, Object> inputs = new Map<String, Object>{
      'OnboardingRecord' => onboardingRecord
    };

    Test.startTest();
    Flow.Interview interview = runFlow(inputs);
    Test.stopTest();

    System.assertEquals(
      null,
      toStringValue(interview.getVariableValue('errorMessage')),
      'Flow should no-op when invoked with onboarding only.'
    );
  }

  @IsTest
  static void testPropagatesAgreementSubflowErrorWhenContractMissing() {
    Account accountRecord = new Account(Name = 'Agreement Missing Contract');
    insert accountRecord;
    Onboarding__c onboardingRecord = new Onboarding__c(Account__c = accountRecord.Id);
    insert onboardingRecord;

    Map<String, Object> inputs = new Map<String, Object>{
      'OnboardingRecord' => onboardingRecord,
      'OnboardingRequirementRecord' => new Onboarding_Requirement__c(
        Requirement_Type__c = getRequirementTypeValue('Agreement')
      )
    };

    try {
      Test.startTest();
      Flow.Interview interview = runFlow(inputs);
      Test.stopTest();

      String errorMessage = toStringValue(interview.getVariableValue('errorMessage'));
      System.assert(String.isNotBlank(errorMessage), 'Flow should return an explicit agreement-path error.');
      System.assert(
        errorMessage.contains('Contract'),
        'Flow should preserve a contract-related agreement error. Actual: ' + errorMessage
      );
    } catch (System.FlowException flowException) {
      System.assert(
        flowException.getMessage().contains('OnboardingRecord.Contract__c'),
        'Agreement path should fail with a contract-related flow error. Actual: ' + flowException.getMessage()
      );
    }
  }

  @IsTest
  static void testNoErrorWhenRequirementTypeNeedsNoRelatedRecord() {
    Map<String, Object> inputs = new Map<String, Object>{
      'OnboardingRequirementRecord' => new Onboarding_Requirement__c(
        Requirement_Type__c = getNoRelatedRecordTypeValue()
      )
    };

    Test.startTest();
    Flow.Interview interview = runFlow(inputs);
    Test.stopTest();

    System.assertEquals(
      null,
      toStringValue(interview.getVariableValue('errorMessage')),
      'Flow should not set an error when no related-record branch is required.'
    );
  }

  private static Flow.Interview runFlow(Map<String, Object> inputs) {
    Flow.Interview interview = Flow.Interview.createInterview(FLOW_API_NAME, inputs);
    interview.start();
    return interview;
  }

  private static String toStringValue(Object value) {
    return value == null ? null : String.valueOf(value);
  }

  private static String getRequirementTypeValue(String preferredValue) {
    List<String> validValues = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Requirement__c.SObjectType,
      'Requirement_Type__c'
    );
    if (validValues.contains(preferredValue)) {
      return preferredValue;
    }
    return validValues.isEmpty() ? preferredValue : validValues[0];
  }

  private static String getNoRelatedRecordTypeValue() {
    List<String> validValues = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Requirement__c.SObjectType,
      'Requirement_Type__c'
    );
    for (String value : validValues) {
      if (value != 'Agreement' && value != 'Contract') {
        return value;
      }
    }
    return '__NON_RELATED_TYPE__';
  }
}
