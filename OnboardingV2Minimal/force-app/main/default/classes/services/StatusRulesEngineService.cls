/**
 * Service for Status Rules Engine domain operations
 * Handles all business logic related to Onboarding_Status_Rules_Engine__c and Onboarding_Status_Rule__c records
 */
public with sharing class StatusRulesEngineService {
  /**
   * Searches for status rules engines
   * Consolidates VendorOnboardingWizardService - removed facade layer
   * @param onboardingStatusRulesEngine The search text
   * @return List of matching status rules engines
   */
  @AuraEnabled(cacheable=true)
  public static List<Onboarding_Status_Rules_Engine__c> searchStatusRulesEngines(
    String onboardingStatusRulesEngine
  ) {
    return VendorOnboardingWizardRepository.searchStatusRulesEngines(
      onboardingStatusRulesEngine
    );
  }

  /**
   * Gets a status rules engine by ID
   * Consolidates VendorOnboardingWizardService - removed facade layer
   * @param engineId The engine ID
   * @return The status rules engine record, or null if not found
   */
  @AuraEnabled(cacheable=true)
  public static Onboarding_Status_Rules_Engine__c getStatusRulesEngineById(
    Id engineId
  ) {
    if (engineId == null) {
      return null;
    }
    return VendorOnboardingWizardRepository.getStatusRulesEngineById(engineId);
  }

  /**
   * Creates a new status rules engine
   * Consolidates VendorOnboardingWizardService - removed facade layer
   * @param onboardingStatusRulesEngine The rules engine record to create
   * @return The ID of the created rules engine
   * @throws AuraHandledException if rules engine is null or name is blank
   */
  @AuraEnabled
  public static Id createOnboardingStatusRulesEngine(
    Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine
  ) {
    ValidationHelper.requireRecord(
      onboardingStatusRulesEngine,
      'Onboarding Status Rules Engine'
    );
    ValidationHelper.requireField(onboardingStatusRulesEngine.Name, 'Name');

    // Apply default values
    DefaultValueHelper.applyStatusRulesEngineDefaults(
      onboardingStatusRulesEngine
    );

    // Set additional defaults if not provided
    if (String.isBlank(onboardingStatusRulesEngine.Evaluation_Logic__c)) {
      onboardingStatusRulesEngine.Evaluation_Logic__c = 'ALL'; // Default evaluation logic
    }
    if (String.isBlank(onboardingStatusRulesEngine.Required_Status__c)) {
      onboardingStatusRulesEngine.Required_Status__c = PicklistHelper.getValidPicklistValue(
        'Onboarding_Status_Rules_Engine__c',
        'Required_Status__c',
        'New'
      );
    }
    if (
      String.isBlank(onboardingStatusRulesEngine.Target_Onboarding_Status__c)
    ) {
      onboardingStatusRulesEngine.Target_Onboarding_Status__c = PicklistHelper.getValidPicklistValue(
        'Onboarding_Status_Rules_Engine__c',
        'Target_Onboarding_Status__c',
        'In Process'
      );
    }

    return VendorOnboardingWizardRepository.insertOnboardingStatusRulesEngine(
      onboardingStatusRulesEngine
    );
  }

  /**
   * Creates a new status rule
   * Consolidates VendorOnboardingWizardService - removed facade layer
   * @param rule The status rule record to create
   * @return The ID of the created rule
   * @throws AuraHandledException if rule is null or name is blank
   */
  @AuraEnabled
  public static Id createStatusRule(
    Onboarding_Status_Rule__c statusRuleRecord
  ) {
    ValidationHelper.requireRecord(statusRuleRecord, 'Status Rule');
    Schema.DescribeFieldResult nameDescribe = Onboarding_Status_Rule__c.Name.getDescribe();
    if (!nameDescribe.isAutoNumber()) {
      ValidationHelper.requireField(statusRuleRecord.Name, 'Name');
    }

    // Set default values for required fields if not provided
    if (String.isBlank(statusRuleRecord.Expected_Status__c)) {
      statusRuleRecord.Expected_Status__c = PicklistHelper.getValidPicklistValue(
        'Onboarding_Status_Rule__c',
        'Expected_Status__c',
        'New'
      );
    }
    if (
      statusRuleRecord.Rule_Number__c == null ||
      statusRuleRecord.Rule_Number__c == 0
    ) {
      statusRuleRecord.Rule_Number__c = 1; // Default rule number
    }

    return VendorOnboardingWizardRepository.insertStatusRule(statusRuleRecord);
  }

  /**
   * Searches for status rules
   * Consolidates VendorOnboardingWizardService - removed facade layer
   * @param nameSearchText The search text
   * @return List of matching status rules
   */
  @AuraEnabled(cacheable=true)
  public static List<Onboarding_Status_Rule__c> searchStatusRules(
    String nameSearchText
  ) {
    return VendorOnboardingWizardRepository.searchStatusRules(nameSearchText);
  }
}
