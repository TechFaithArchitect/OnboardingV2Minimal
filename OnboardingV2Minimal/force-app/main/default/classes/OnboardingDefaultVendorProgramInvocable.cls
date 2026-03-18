/**
 * Invocable action to resolve the default Vendor Program for a flow scenario (e.g., REQUIRE_NDA).
 * Used when the BRE returns REQUIRE_NDA and no vendor selection was made (no onboarding records).
 * Configuration is driven by Onboarding_Default_Vendor_Program__mdt.
 */
public with sharing class OnboardingDefaultVendorProgramInvocable {
  public class ScenarioRequest {
    @InvocableVariable(required=true label='Scenario Key' description='e.g., REQUIRE_NDA from FinalNextAction')
    public String scenarioKey;
  }

  public class VendorProgramResult {
    @InvocableVariable(label='Vendor Program Record' description='The default Vendor_Customization__c for the scenario')
    public Vendor_Customization__c vendorProgramRecord;

    @InvocableVariable(label='Error Message')
    public String errorMessage;
  }

  @InvocableMethod(
    label='Get Default Vendor Program for Scenario'
    description='Returns the default Vendor Program (Vendor_Customization__c) for a flow scenario from Onboarding_Default_Vendor_Program__mdt. Used when REQUIRE_NDA and no vendor was selected.'
  )
  public static List<VendorProgramResult> getDefaultVendorProgram(
    List<ScenarioRequest> requests
  ) {
    List<VendorProgramResult> results = new List<VendorProgramResult>();
    if (requests == null || requests.isEmpty()) {
      results.add(new VendorProgramResult());
      return results;
    }

    String scenarioKey = requests[0].scenarioKey;
    VendorProgramResult result = new VendorProgramResult();

    if (String.isBlank(scenarioKey)) {
      result.errorMessage = 'Scenario Key is required.';
      results.add(result);
      return results;
    }

    try {
      List<Onboarding_Default_Vendor_Program__mdt> configs = [
        SELECT Vendor_Name__c, Vendor_Program_Name_Contains__c
        FROM Onboarding_Default_Vendor_Program__mdt
        WHERE Scenario_Key__c = :scenarioKey
        AND Active__c = true
        LIMIT 1
      ];

      if (configs.isEmpty()) {
        result.errorMessage =
          'No active Onboarding Default Vendor Program found for scenario: ' +
          scenarioKey;
        results.add(result);
        return results;
      }

      String vendorName = configs[0].Vendor_Name__c;
      if (String.isBlank(vendorName)) {
        result.errorMessage =
          'Vendor Name is blank for scenario: ' + scenarioKey;
        results.add(result);
        return results;
      }

      String nameContains = configs[0].Vendor_Program_Name_Contains__c;
      List<Vendor_Customization__c> programs;

      if (String.isNotBlank(nameContains)) {
        String namePattern =
          '%' + String.escapeSingleQuotes(nameContains.trim()) + '%';
        programs = [
          SELECT Id, Vendor__c, Business_Vertical__c, Retail_Option__c
          FROM Vendor_Customization__c
          WHERE Vendor__r.Name = :vendorName
          AND Name LIKE :namePattern
          AND Active__c = true
          WITH SECURITY_ENFORCED
          LIMIT 1
        ];
      } else {
        programs = [
          SELECT Id, Vendor__c, Business_Vertical__c, Retail_Option__c
          FROM Vendor_Customization__c
          WHERE Vendor__r.Name = :vendorName
          AND Active__c = true
          WITH SECURITY_ENFORCED
          LIMIT 1
        ];
      }

      if (!programs.isEmpty()) {
        result.vendorProgramRecord = programs[0];
      } else {
        result.errorMessage =
          String.isNotBlank(nameContains)
            ? 'No active Vendor Program found for Vendor: ' +
              vendorName +
              ' with Name containing "' +
              nameContains +
              '"'
            : 'No active Vendor Program found for Vendor: ' + vendorName;
      }
    } catch (Exception ex) {
      result.errorMessage = 'Unable to resolve default Vendor Program: ' + ex.getMessage();
      LoggingUtil.error(
        'OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram failed: ' +
        ex.getStackTraceString()
      );
    }

    results.add(result);
    return results;
  }
}