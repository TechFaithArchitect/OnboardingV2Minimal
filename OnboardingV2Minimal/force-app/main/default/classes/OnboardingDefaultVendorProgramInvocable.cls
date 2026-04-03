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
      if (!Schema.sObjectType.Onboarding_Default_Vendor_Program__mdt.isAccessible()) {
        result.errorMessage = 'You do not have access to Onboarding Default Vendor Program configuration.';
        results.add(result);
        return results;
      }

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

      String containsToken = String.isBlank(configs[0].Vendor_Program_Name_Contains__c)
        ? null
        : configs[0].Vendor_Program_Name_Contains__c.trim();
      List<Vendor_Customization__c> activePrograms = [
        SELECT Id, Name, Vendor__c, Business_Vertical__c, Retail_Option__c, Contract_Record_Type__c,Associated_Agreement_Template__c
        FROM Vendor_Customization__c
        WHERE Vendor__r.Name = :vendorName
        AND Active__c = true
        WITH SECURITY_ENFORCED
        ORDER BY Name
        LIMIT 200
      ];

      if (activePrograms.isEmpty()) {
        result.errorMessage = 'No active Vendor Program found for Vendor: ' + vendorName;
        results.add(result);
        return results;
      }

      Vendor_Customization__c selectedProgram;
      if (String.isBlank(containsToken)) {
        selectedProgram = activePrograms[0];
      } else {
        List<Vendor_Customization__c> containsMatches = new List<Vendor_Customization__c>();
        for (Vendor_Customization__c program : activePrograms) {
          if (containsIgnoreCase(program.Name, containsToken)) {
            containsMatches.add(program);
          }
        }

        if (!containsMatches.isEmpty()) {
          selectedProgram = containsMatches[0];
        } else {
          List<Vendor_Customization__c> scenarioHintMatches = findScenarioHintMatches(
            activePrograms,
            scenarioKey
          );
          if (!scenarioHintMatches.isEmpty()) {
            selectedProgram = scenarioHintMatches[0];
            LoggingUtil.warn(
              'OnboardingDefaultVendorProgramInvocable scenario-key fallback: Scenario=' +
              scenarioKey +
              ', Vendor=' +
              vendorName +
              ', containsToken="' +
              containsToken +
              '" did not match. Using scenario-key hint match Vendor Program Id=' +
              selectedProgram.Id
            );
          } else if (activePrograms.size() == 1) {
            // Safe fallback: single active program for vendor even if token no longer matches name.
            selectedProgram = activePrograms[0];
            LoggingUtil.warn(
              'OnboardingDefaultVendorProgramInvocable fallback: Scenario=' +
              scenarioKey +
              ', Vendor=' +
              vendorName +
              ', containsToken="' +
              containsToken +
              '" did not match. Using sole active Vendor Program Id=' +
              selectedProgram.Id
            );
          } else {
            result.errorMessage =
              'Configured Vendor Program token "' +
              containsToken +
              '" did not match any active Vendor Program names for Vendor: ' +
              vendorName +
              '. Active program count: ' +
              String.valueOf(activePrograms.size());
            results.add(result);
            return results;
          }
        }
      }

      result.vendorProgramRecord = selectedProgram;
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

  private static Boolean containsIgnoreCase(String source, String token) {
    if (String.isBlank(source) || String.isBlank(token)) {
      return false;
    }
    return source.toLowerCase().contains(token.toLowerCase());
  }

  private static List<Vendor_Customization__c> findScenarioHintMatches(
    List<Vendor_Customization__c> activePrograms,
    String scenarioKey
  ) {
    List<Vendor_Customization__c> matches = new List<Vendor_Customization__c>();
    String scenarioToken = extractScenarioHint(scenarioKey);
    if (String.isBlank(scenarioToken)) {
      return matches;
    }

    for (Vendor_Customization__c program : activePrograms) {
      if (containsIgnoreCase(program.Name, scenarioToken)) {
        matches.add(program);
      }
    }

    if (matches.size() <= 1) {
      return matches;
    }

    for (Vendor_Customization__c program : matches) {
      if (program.Name != null && program.Name.trim().equalsIgnoreCase(scenarioToken)) {
        return new List<Vendor_Customization__c>{ program };
      }
    }

    return matches;
  }

  private static String extractScenarioHint(String scenarioKey) {
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
