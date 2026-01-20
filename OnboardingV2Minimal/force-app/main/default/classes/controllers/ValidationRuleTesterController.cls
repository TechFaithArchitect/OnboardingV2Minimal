/**
 * Controller for Validation Rule Tester UI.
 */
public with sharing class ValidationRuleTesterController {
    @AuraEnabled
    public static RequirementFieldValidationService.ValidationResult testValue(String requirementFieldApiName, String value) {
        return RequirementFieldValidationService.evaluateSingle(requirementFieldApiName, value);
    }
}