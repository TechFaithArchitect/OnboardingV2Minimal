@isTest
private class OnboardingEccEmailDispatchInvocableTest {
  private class ScenarioData {
    Onboarding__c onboarding;
    Contact contact;
    Vendor_Customization__c vendorProgram;
  }

  @isTest
  static void buildTokenMap_prefersProgramMatchedCredentialAndCountsMissing() {
    ScenarioData scenario = buildScenario();
    String validProgramValue = firstActiveProgramValue();
    External_Contact_Credential_Type__c ssoType = TestCredentialFactory.createCredentialType(
      'SSO ID',
      1,
      scenario.vendorProgram,
      true,
      true
    );
    External_Contact_Credential_Type__c pinType = TestCredentialFactory.createCredentialType(
      'PIN',
      2,
      scenario.vendorProgram,
      true,
      true
    );

    TestCredentialFactory.createRequiredCredential(ssoType, scenario.vendorProgram, true, true);
    TestCredentialFactory.createRequiredCredential(pinType, scenario.vendorProgram, true, true);

    TestECCFactory.createExternalContactCredential(
      scenario.contact,
      'preferred-user',
      validProgramValue,
      'Complete',
      ssoType,
      scenario.vendorProgram,
      true
    );

    Test.startTest();
    Map<String, String> tokenMap = OnboardingEccEmailDispatchInvocable.buildTokenMapForTest(
      scenario.onboarding.Id,
      scenario.contact.Id
    );
    Test.stopTest();

    System.assertEquals('2', tokenMap.get('{{ECC_REQUIRED_TOTAL}}'));
    System.assertEquals('1', tokenMap.get('{{ECC_COMPLETE_TOTAL}}'));
    System.assertEquals('1', tokenMap.get('{{ECC_MISSING_TOTAL}}'));
    System.assert(tokenMap.get('{{ECC_SUMMARY}}').contains('Required credentials: 2'));
    System.assert(tokenMap.get('{{ECC_TABLE}}').contains('preferred-user'));
    System.assert(tokenMap.get('{{ECC_TABLE}}').contains('<th>N#</th>'));
    System.assert(tokenMap.get('{{ECC_ROWS}}').contains('PIN: Missing'));
    System.assert(tokenMap.get('{{ECC_TYPE_VALUE_ROWS}}').contains('SSO ID: preferred-user'));
    System.assert(tokenMap.get('{{ECC_TYPE_VALUE_TABLE}}').contains('<th>Value</th>'));
  }

  @isTest
  static void renderTemplateForTest_supportsDynamicTypeTokens() {
    ScenarioData scenario = buildScenario();
    String validProgramValue = firstActiveProgramValue();

    External_Contact_Credential_Type__c ssoType = TestCredentialFactory.createCredentialType(
      'SSO ID',
      1,
      scenario.vendorProgram,
      true,
      true
    );
    External_Contact_Credential_Type__c pinType = TestCredentialFactory.createCredentialType(
      'PIN',
      2,
      scenario.vendorProgram,
      true,
      true
    );
    TestCredentialFactory.createRequiredCredential(ssoType, scenario.vendorProgram, true, true);
    TestCredentialFactory.createRequiredCredential(pinType, scenario.vendorProgram, true, true);

    TestECCFactory.createExternalContactCredential(
      scenario.contact,
      'user-dynamic',
      validProgramValue,
      'Complete',
      ssoType,
      scenario.vendorProgram,
      true
    );

    String template =
      'U={{ECC_VALUE:SSO ID}}|P={{ECC_VALUE:PIN}}|PAIR={{ECC_TYPE_VALUE:SSO ID}}';
    String rendered = OnboardingEccEmailDispatchInvocable.renderTemplateForTest(
      template,
      scenario.onboarding.Id,
      scenario.contact.Id,
      false
    );

    System.assert(rendered.contains('U=user-dynamic'));
    System.assert(rendered.contains('P=Missing'));
    System.assert(rendered.contains('PAIR=SSO ID: user-dynamic'));
  }

  @isTest
  static void renderTemplateForTest_supportsTypeUniqueKeyAndFieldApiTokens() {
    ScenarioData scenario = buildScenario();
    String validProgramValue = firstActiveProgramValue();

    External_Contact_Credential_Type__c ssoType = TestCredentialFactory.createCredentialType(
      'SSO ID',
      1,
      scenario.vendorProgram,
      true,
      true
    );
    String ssoTypeKey = [
      SELECT Unique_Key__c
      FROM External_Contact_Credential_Type__c
      WHERE Id = :ssoType.Id
      LIMIT 1
    ].Unique_Key__c;

    TestCredentialFactory.createRequiredCredential(ssoType, scenario.vendorProgram, true, true);

    TestECCFactory.createExternalContactCredential(
      scenario.contact,
      'user-abc',
      validProgramValue,
      'Complete',
      ssoType,
      scenario.vendorProgram,
      true
    );

    POE_External_Contact_Credential__c insertedRow = [
      SELECT Id
      FROM POE_External_Contact_Credential__c
      WHERE POE_Contact__c = :scenario.contact.Id
        AND Vendor_Program__c = :scenario.vendorProgram.Id
        AND External_Contact_Credential_Type__c = :ssoType.Id
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    insertedRow.POE_N_Number__c = 'N-9988';
    insertedRow.POE_Code__c = 'PIN-XYZ';
    update insertedRow;

    String template =
      'Default={{ECC_VALUE:' + ssoTypeKey + '}}|' +
      'N={{ECC_VALUE:' + ssoTypeKey + '|POE_N_Number__c}}|' +
      'Code={{ECC_VALUE:' + ssoTypeKey + '|POE_Code__c}}|' +
      'Pair={{ECC_TYPE_VALUE:' + ssoTypeKey + '|POE_N_Number__c}}|' +
      'Bad={{ECC_VALUE:' + ssoTypeKey + '|Not_A_Field__c}}';
    String rendered = OnboardingEccEmailDispatchInvocable.renderTemplateForTest(
      template,
      scenario.onboarding.Id,
      scenario.contact.Id,
      false
    );

    System.assert(rendered.contains('Default=user-abc'));
    System.assert(rendered.contains('N=N-9988'));
    System.assert(rendered.contains('Code=PIN-XYZ'));
    System.assert(rendered.contains('Pair=SSO ID: N-9988'));
    System.assert(rendered.contains('Bad=Missing'));
  }

  @isTest
  static void dispatch_failsWhenCommunicationTemplateMissingEmailTemplateId() {
    ScenarioData scenario = buildScenario();
    Communication_Template__c communicationTemplate = TestDataFactory.createCommunicationTemplate(true, true);

    OnboardingEccEmailDispatchInvocable.DispatchRequest request =
      new OnboardingEccEmailDispatchInvocable.DispatchRequest();
    request.vendorProgramId = scenario.vendorProgram.Id;
    request.recipientContactId = scenario.contact.Id;
    request.communicationTemplateId = communicationTemplate.Id;

    Test.startTest();
    List<OnboardingEccEmailDispatchInvocable.DispatchResult> results =
      OnboardingEccEmailDispatchInvocable.dispatch(
        new List<OnboardingEccEmailDispatchInvocable.DispatchRequest>{ request }
      );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals(false, results[0].ranSuccessfully);
    System.assertEquals(0, results[0].sentCount);
    System.assertEquals(1, results[0].failedCount);
    System.assert(
      results[0].diagnosticMessage != null &&
      results[0].diagnosticMessage.contains('Email_Template_Id__c')
    );
  }

  @isTest
  static void dispatch_failsWhenRequiredInputsAreMissing() {
    OnboardingEccEmailDispatchInvocable.DispatchRequest missingRecipientRequest =
      new OnboardingEccEmailDispatchInvocable.DispatchRequest();

    List<OnboardingEccEmailDispatchInvocable.DispatchResult> results =
      OnboardingEccEmailDispatchInvocable.dispatch(
        new List<OnboardingEccEmailDispatchInvocable.DispatchRequest>{ missingRecipientRequest }
      );

    System.assertEquals(1, results.size());
    System.assertEquals(false, results[0].ranSuccessfully);
    System.assertEquals(1, results[0].failedCount);
    System.assert(
      results[0].diagnosticMessage != null &&
      results[0].diagnosticMessage.contains('recipientContactId is required')
    );

    OnboardingEccEmailDispatchInvocable.DispatchRequest missingContextRequest =
      new OnboardingEccEmailDispatchInvocable.DispatchRequest();
    missingContextRequest.recipientContactId = UserInfo.getUserId();
    missingContextRequest.communicationTemplateId = UserInfo.getUserId();

    results = OnboardingEccEmailDispatchInvocable.dispatch(
      new List<OnboardingEccEmailDispatchInvocable.DispatchRequest>{ missingContextRequest }
    );

    System.assertEquals(1, results.size());
    System.assertEquals(false, results[0].ranSuccessfully);
    System.assertEquals(1, results[0].failedCount);
    System.assert(
      results[0].diagnosticMessage != null &&
      results[0].diagnosticMessage.contains('Either onboardingId or vendorProgramId is required')
    );
  }

  private static ScenarioData buildScenario() {
    ScenarioData data = new ScenarioData();

    Account account = TestDataFactory.createAccount('ECC Email Account', true);
    data.contact = TestDataFactory.createContact('ECC', 'Recipient', true, account);

    Vendor__c vendor = TestDataFactory.createVendor(true);
    data.vendorProgram = TestDataFactory.createVendorCustomization(
      vendor,
      'Active',
      true,
      null,
      true
    );
    data.vendorProgram = [
      SELECT Id, Name, Label__c
      FROM Vendor_Customization__c
      WHERE Id = :data.vendorProgram.Id
      LIMIT 1
    ];

    data.onboarding = TestDataFactory.createOnboarding(account, data.vendorProgram, true);
    return data;
  }

  private static String firstActiveProgramValue() {
    for (Schema.PicklistEntry entry :
      POE_External_Contact_Credential__c.POE_Program__c.getDescribe().getPicklistValues()
    ) {
      if (entry.isActive()) {
        return entry.getValue();
      }
    }
    return 'Verizon Fios D2D';
  }
}
