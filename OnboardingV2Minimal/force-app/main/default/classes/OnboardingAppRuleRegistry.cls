public with sharing class OnboardingAppRuleRegistry {
  // Validation Rules Registry (for other objects)
  public static Map<String, List<OnboardingAppValidationRule>> getValidationRules() {
    return new Map<String, List<OnboardingAppValidationRule>>{
      'Vendor_Program_Group_Member__c' => new List<OnboardingAppValidationRule>{
        new OnlyOneTargetProgramInGroupRule()
      }

      // Add additional validation rule groups here...
    };
  }

  // ✅ Activation Rules Registry
  public static List<OnboardingAppActivationRule> getActivationRulesForObject(
    String objectApiName
  ) {
    List<OnboardingAppActivationRule> activationRules = new List<OnboardingAppActivationRule>();

    if (objectApiName == 'Vendor_Program__c') {
      activationRules.add(new AllChildRequirementsMustBeActiveRule());
    }

    if (objectApiName == 'Vendor_Customization__c') {
    }

    if (objectApiName == 'Onboarding_Status_Rule__c') {
      activationRules.add(new AllLinkedEngineMustBeActiveRule());
    }

    if (objectApiName == 'Onboarding_Status_Rules_Engine__c') {
      activationRules.add(new AllStatusRulesMustBeActiveRule());
    }

    return activationRules;
  }
}
