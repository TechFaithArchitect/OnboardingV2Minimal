/**
 * Test for OnboardingDefaultVendorProgramInvocable.
 * Resolves active scenario config from Onboarding_Default_Vendor_Program__mdt at runtime.
 */
@isTest
private class OnboardingDefaultVendorProgramInvocTest {
  @isTest
  static void testGetDefaultVendorProgramReturnsProgramWhenConfigured() {
    ScenarioConfig config = getScenarioConfig(true);

    Vendor__c vendor = new Vendor__c(Name = config.vendorName, Active__c = true);
    insert vendor;

    Vendor_Customization__c vc = buildActiveVendorProgram(
      vendor.Id,
      'Primary ' + config.containsToken + ' Program'
    );
    insert vc;

    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = config.scenarioKey;

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    OnboardingDefaultVendorProgramInvocable.VendorProgramResult r = results[0];
    System.assertNotEquals(null, r.vendorProgramRecord, 'Expected configured vendor program match');
    System.assertEquals(vc.Id, r.vendorProgramRecord.Id, 'Should return the configured vendor program');
    System.assertEquals(
      null,
      r.vendorProgramRecord.Contract_Record_Type__c,
      'Invocable must hydrate Contract_Record_Type__c (null in test data is expected, missing-query exception is not).'
    );
    System.assert(String.isBlank(r.errorMessage), 'No error when program found');
  }

  @isTest
  static void testEmptyScenarioKeyReturnsError() {
    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = '';

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assert(String.isNotBlank(results[0].errorMessage), 'Should return error for blank scenario');
    System.assertEquals(null, results[0].vendorProgramRecord);
  }

  @isTest
  static void testNullRequestReturnsEmptyResult() {
    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      null
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Returns one empty result for null input');
  }

  @isTest
  static void testScenarioWithoutConfigReturnsError() {
    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = 'DOES_NOT_EXIST';

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertEquals(
      true,
      String.isNotBlank(results[0].errorMessage),
      'Missing scenario config should return explicit error'
    );
    System.assertEquals(
      null,
      results[0].vendorProgramRecord,
      'Missing scenario config should not return a program'
    );
  }

  @isTest
  static void testAmbiguousMatchReturnsAnyActiveProgramWithoutError() {
    ScenarioConfig config = getScenarioConfig(true);

    Vendor__c vendor = new Vendor__c(Name = config.vendorName, Active__c = true);
    insert vendor;

    Vendor_Customization__c vcA = buildActiveVendorProgram(
      vendor.Id,
      config.containsToken + ' Program A'
    );
    Vendor_Customization__c vcB = buildActiveVendorProgram(
      vendor.Id,
      config.containsToken + ' Program B'
    );
    insert new List<Vendor_Customization__c>{ vcA, vcB };

    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = config.scenarioKey;

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertNotEquals(null, results[0].vendorProgramRecord, 'Expected one matched vendor program');
    System.assertEquals(
      true,
      results[0].vendorProgramRecord.Id == vcA.Id ||
      results[0].vendorProgramRecord.Id == vcB.Id,
      'Returned program should be one of the active matches'
    );
    System.assertEquals(
      true,
      String.isBlank(results[0].errorMessage),
      'Ambiguous active matches should still return without error'
    );
  }

  @isTest
  static void testNameContainsScenarioUsesContainsFilter() {
    ScenarioConfig config = getScenarioConfig(true);

    Vendor__c vendor = new Vendor__c(Name = config.vendorName, Active__c = true);
    insert vendor;

    Vendor_Customization__c nonMatching = buildActiveVendorProgram(vendor.Id, 'Standard NDA Program');
    Vendor_Customization__c matching = buildActiveVendorProgram(
      vendor.Id,
      config.containsToken + ' Program'
    );
    insert new List<Vendor_Customization__c>{ nonMatching, matching };

    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = config.scenarioKey;

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertNotEquals(null, results[0].vendorProgramRecord, 'Expected matching vendor program');
    System.assertEquals(
      matching.Id,
      results[0].vendorProgramRecord.Id,
      'Name contains scenario should return the program matching configured contains token'
    );
    System.assertEquals(
      true,
      String.isBlank(results[0].errorMessage),
      'No error expected when contains filter finds a record'
    );
  }

  @isTest
  static void testContainsTokenFallbackUsesSingleProgramWhenOnlyOneActive() {
    ScenarioConfig config = getScenarioConfig(true);

    Vendor__c vendor = new Vendor__c(Name = config.vendorName, Active__c = true);
    insert vendor;

    Vendor_Customization__c onlyProgram = buildActiveVendorProgram(vendor.Id, 'NDA Program');
    insert onlyProgram;

    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = config.scenarioKey;

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertNotEquals(null, results[0].vendorProgramRecord, 'Single active program should be used as fallback');
    System.assertEquals(
      onlyProgram.Id,
      results[0].vendorProgramRecord.Id,
      'Fallback should return the sole active program for the vendor'
    );
    System.assertEquals(
      true,
      String.isBlank(results[0].errorMessage),
      'Fallback should not return an error when exactly one active program exists'
    );
  }

  @isTest
  static void testContainsTokenNoMatchWithMultipleProgramsReturnsError() {
    ScenarioConfig config = getScenarioConfig(true);

    Vendor__c vendor = new Vendor__c(Name = config.vendorName, Active__c = true);
    insert vendor;

    Vendor_Customization__c programA = buildActiveVendorProgram(vendor.Id, 'Program Alpha');
    Vendor_Customization__c programB = buildActiveVendorProgram(vendor.Id, 'Program Beta');
    insert new List<Vendor_Customization__c>{ programA, programB };

    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = config.scenarioKey;

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertEquals(
      null,
      results[0].vendorProgramRecord,
      'No contains match across multiple active programs should return no selected program'
    );
    System.assertEquals(
      true,
      String.isNotBlank(results[0].errorMessage),
      'Expected explicit error when token does not match and there are multiple active choices'
    );
  }

  @isTest
  static void testScenarioHintFallbackUsesExactHintMatch() {
    ScenarioConfig config = getScenarioConfig(true);
    String scenarioHint = extractScenarioHintForTest(config.scenarioKey);
    System.assertEquals(
      true,
      String.isNotBlank(scenarioHint),
      'Scenario key should provide a hint segment for fallback test'
    );

    Vendor__c vendor = new Vendor__c(Name = config.vendorName, Active__c = true);
    insert vendor;

    Vendor_Customization__c hinted = buildActiveVendorProgram(vendor.Id, scenarioHint);
    Vendor_Customization__c other = buildActiveVendorProgram(vendor.Id, 'Program Base');
    insert new List<Vendor_Customization__c>{ other, hinted };

    OnboardingDefaultVendorProgramInvocable.ScenarioRequest req = new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
    req.scenarioKey = config.scenarioKey;

    Test.startTest();
    List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> results = OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
      new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertNotEquals(
      null,
      results[0].vendorProgramRecord,
      'Scenario-hint fallback should return a program when contains token misses'
    );
    System.assertEquals(
      hinted.Id,
      results[0].vendorProgramRecord.Id,
      'Scenario-hint fallback should prefer exact scenario-hint name match'
    );
    System.assertEquals(
      true,
      String.isBlank(results[0].errorMessage),
      'No error expected when scenario-hint fallback resolves a single program'
    );
  }

  private static Vendor_Customization__c buildActiveVendorProgram(Id vendorId, String programName) {
    Vendor_Customization__c program = new Vendor_Customization__c(
      Name = programName,
      Vendor__c = vendorId,
      Active__c = true
    );

    String retailOption = firstActivePicklistValue(
      Vendor_Customization__c.Retail_Option__c
    );
    if (String.isNotBlank(retailOption)) {
      program.Retail_Option__c = retailOption;
    }

    String businessVertical = firstActivePicklistValue(
      Vendor_Customization__c.Business_Vertical__c
    );
    if (String.isNotBlank(businessVertical)) {
      program.Business_Vertical__c = businessVertical;
    }

    return program;
  }

  private static String firstActivePicklistValue(Schema.SObjectField fieldRef) {
    for (Schema.PicklistEntry entry : fieldRef.getDescribe().getPicklistValues()) {
      if (entry.isActive()) {
        return entry.getValue();
      }
    }
    return null;
  }

  private class ScenarioConfig {
    private String scenarioKey;
    private String vendorName;
    private String containsToken;
  }

  private static ScenarioConfig getScenarioConfig(Boolean requireContainsToken) {
    List<Onboarding_Default_Vendor_Program__mdt> configs;
    if (requireContainsToken) {
      configs = [
        SELECT Scenario_Key__c, Vendor_Name__c, Vendor_Program_Name_Contains__c
        FROM Onboarding_Default_Vendor_Program__mdt
        WHERE Active__c = true
        AND Vendor_Program_Name_Contains__c != null
        AND Vendor_Program_Name_Contains__c != ''
        LIMIT 1
      ];
    } else {
      configs = [
        SELECT Scenario_Key__c, Vendor_Name__c, Vendor_Program_Name_Contains__c
        FROM Onboarding_Default_Vendor_Program__mdt
        WHERE Active__c = true
        LIMIT 1
      ];
    }

    System.assertEquals(
      true,
      !configs.isEmpty(),
      requireContainsToken
        ? 'Expected one active default-vendor-program config with a name-contains token'
        : 'Expected at least one active default-vendor-program config'
    );

    ScenarioConfig config = new ScenarioConfig();
    config.scenarioKey = configs[0].Scenario_Key__c;
    config.vendorName = configs[0].Vendor_Name__c;
    config.containsToken = configs[0].Vendor_Program_Name_Contains__c;

    System.assertEquals(true, String.isNotBlank(config.scenarioKey), 'Scenario key is required in test metadata');
    System.assertEquals(true, String.isNotBlank(config.vendorName), 'Vendor name is required in test metadata');
    if (requireContainsToken) {
      System.assertEquals(
        true,
        String.isNotBlank(config.containsToken),
        'Contains token is required in test metadata for contains-token scenarios'
      );
    }

    return config;
  }

  private static String extractScenarioHintForTest(String scenarioKey) {
    if (String.isBlank(scenarioKey)) {
      return null;
    }
    List<String> parts = scenarioKey.split('_');
    for (Integer i = parts.size() - 1; i >= 0; i--) {
      String part = parts[i] == null ? null : parts[i].trim();
      if (String.isBlank(part)) {
        continue;
      }
      String upper = part.toUpperCase();
      if (
        upper == 'REQUIRE' ||
        upper == 'ONLY' ||
        upper == 'DEFAULT' ||
        upper == 'STATUS' ||
        upper == 'FLOW'
      ) {
        continue;
      }
      return part;
    }
    return null;
  }
}
