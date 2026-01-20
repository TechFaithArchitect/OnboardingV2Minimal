/**
 * Validates Requirement_Field_Value__c records using metadata-driven rules.
 * - Required check uses Requirement_Field__c.Required__c.
 * - Format check uses Requirement_Field_Validation_Rule__mdt matched by Field_API_Name__c.
 * - Updates validation status, error message, and last validated timestamp when asked to persist.
 */
public with sharing class RequirementFieldValidationService {
  public class ValidationResult {
    @AuraEnabled
    public Id fieldValueId;
    @AuraEnabled
    public String fieldApiName;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String message;
  }

  /**
   * Validate and persist Requirement_Field_Value__c records by Id.
   * Useful for synchronous validation flows.
   */
  public static List<ValidationResult> validateAndUpdate(
    Set<Id> fieldValueIds
  ) {
    if (fieldValueIds == null || fieldValueIds.isEmpty()) {
      return new List<ValidationResult>();
    }

    // Use repository for data access
    List<Requirement_Field_Value__c> fieldValues = RequirementFieldValueRepository.getFieldValuesByIds(
      fieldValueIds
    );

    Map<Id, Requirement_Field__c> requirementFieldsById = new Map<Id, Requirement_Field__c>();
    Set<String> fieldApiNames = new Set<String>();
    for (Requirement_Field_Value__c fieldValue : fieldValues) {
      if (
        fieldValue.Requirement_Field__c != null &&
        fieldValue.Requirement_Field__r != null
      ) {
        requirementFieldsById.put(
          fieldValue.Requirement_Field__c,
          fieldValue.Requirement_Field__r
        );
        if (
          String.isNotBlank(fieldValue.Requirement_Field__r.Field_API_Name__c)
        ) {
          fieldApiNames.add(fieldValue.Requirement_Field__r.Field_API_Name__c);
        }
      }
    }

    Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi = loadRulesByFieldApi(
      fieldApiNames
    );

    List<ValidationResult> validationResults = new List<ValidationResult>();
    List<RequirementValidationLogger.LogEntry> validationLogs = new List<RequirementValidationLogger.LogEntry>();
    for (Requirement_Field_Value__c fieldValue : fieldValues) {
      Requirement_Field__c requirementField = requirementFieldsById.get(
        fieldValue.Requirement_Field__c
      );
      ValidationResult validationResult = evaluateFieldValue(
        fieldValue,
        requirementField,
        rulesByApi
      );
      fieldValue.Validation_Status__c = validationResult.status;
      fieldValue.Validation_Error_Message__c = validationResult.message;
      fieldValue.Last_Validated_Date__c = DateTime.now();
      validationResults.add(validationResult);

      // Log non-Valid outcomes
      if (
        validationResult.status != null &&
        validationResult.status != 'Valid'
      ) {
        RequirementValidationLogger.LogEntry validationLog = new RequirementValidationLogger.LogEntry();
        validationLog.fieldValueId = fieldValue.Id;
        validationLog.fieldApiName = requirementField != null
          ? requirementField.Field_API_Name__c
          : null;
        validationLog.validationResult = validationResult.status;
        validationLog.validationType = requirementField != null
          ? requirementField.Validation_Type__c
          : null;
        validationLog.message = validationResult.message;
        validationLog.ruleName = (rulesByApi != null &&
          requirementField != null)
          ? rulesByApi.get(requirementField.Field_API_Name__c) != null
              ? rulesByApi.get(requirementField.Field_API_Name__c).DeveloperName
              : null
          : null;
        validationLog.correlationId = String.valueOf(Crypto.getRandomLong());
        validationLog.validatedOn = fieldValue.Last_Validated_Date__c;
        validationLogs.add(validationLog);
      }
    }

    if (!fieldValues.isEmpty()) {
      update fieldValues;
    }

    if (!validationLogs.isEmpty()) {
      RequirementValidationLogger.log(validationLogs);
    }

    return validationResults;
  }

  /**
   * Pure evaluation helper: no DML. Useful for LWC/Flow preview or tests.
   */
  public static ValidationResult evaluateFieldValue(
    Requirement_Field_Value__c fieldValue,
    Requirement_Field__c requirementField,
    Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi
  ) {
    ValidationResult validationResult = new ValidationResult();
    validationResult.fieldValueId = fieldValue != null ? fieldValue.Id : null;
    validationResult.status = 'Valid';
    validationResult.message = '';

    if (requirementField == null) {
      validationResult.status = 'Invalid';
      validationResult.message = 'Missing requirement field definition.';
      return validationResult;
    }

    String fieldApi = requirementField.Field_API_Name__c;
    validationResult.fieldApiName = fieldApi;
    String fieldValueString = getValue(fieldValue);
    Boolean isBlank = String.isBlank(fieldValueString);

    if (requirementField.Required__c && isBlank) {
      validationResult.status = 'Needs Correction';
      validationResult.message = 'This field is required.';
      return validationResult;
    }

    Requirement_Field_Validation_Rule__mdt validationRule = rulesByApi != null
      ? rulesByApi.get(fieldApi)
      : null;
    String validationType = requirementField.Validation_Type__c;

    if (
      validationRule != null &&
      validationRule.Is_Active__c &&
      validationRule.Validation_Type__c == 'Format' &&
      !String.isBlank(validationRule.Validation_Expression__c) &&
      !isBlank
    ) {
      try {
        if (
          !Pattern.compile(validationRule.Validation_Expression__c)
            .matcher(fieldValueString)
            .matches()
        ) {
          validationResult.status = 'Invalid';
          validationResult.message = String.isBlank(
              validationRule.Error_Message__c
            )
            ? 'Value does not match required format.'
            : validationRule.Error_Message__c;
          return validationResult;
        }
      } catch (Exception ex) {
        validationResult.status = 'Invalid';
        validationResult.message =
          'Invalid validation expression: ' + ex.getMessage();
        return validationResult;
      }
    }

    // If the field calls for cross-field or external validation, leave as Pending for downstream async validation.
    if (
      validationType == 'Cross-Field' || isExternalValidation(validationType)
    ) {
      validationResult.status = 'Pending';
      return validationResult;
    }

    validationResult.status = 'Valid';
    return validationResult;
  }

  /**
   * Convenience evaluation by Requirement Field API name and value (no DML).
   */
  @AuraEnabled(cacheable=false)
  public static ValidationResult evaluateSingle(
    String requirementFieldApiName,
    String value
  ) {
    ValidationResult validationResult = new ValidationResult();
    if (String.isBlank(requirementFieldApiName)) {
      validationResult.status = 'Invalid';
      validationResult.message = 'Requirement field API name is required.';
      return validationResult;
    }

    List<Requirement_Field__c> fields = [
      SELECT Id, Field_API_Name__c, Required__c, Validation_Type__c
      FROM Requirement_Field__c
      WHERE Field_API_Name__c = :requirementFieldApiName
      LIMIT 1
    ];
    if (fields.isEmpty()) {
      validationResult.status = 'Invalid';
      validationResult.message =
        'Requirement field not found for API name ' + requirementFieldApiName;
      return validationResult;
    }

    Requirement_Field__c requirementField = fields[0];
    Requirement_Field_Value__c fieldValue = new Requirement_Field_Value__c();
    fieldValue.Requirement_Field__c = requirementField.Id;
    fieldValue.Value__c = value;

    Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi = loadRulesByFieldApi(
      new Set<String>{ requirementFieldApiName }
    );

    return evaluateFieldValue(fieldValue, requirementField, rulesByApi);
  }

  public static Map<String, Requirement_Field_Validation_Rule__mdt> loadRulesByFieldApi(
    Set<String> fieldApiNames
  ) {
    Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi = new Map<String, Requirement_Field_Validation_Rule__mdt>();
    if (fieldApiNames == null || fieldApiNames.isEmpty()) {
      return rulesByApi;
    }

    for (Requirement_Field_Validation_Rule__mdt validationRule : [
      SELECT
        DeveloperName,
        Requirement_Field__c,
        Validation_Type__c,
        Validation_Expression__c,
        Error_Message__c,
        Is_Active__c
      FROM Requirement_Field_Validation_Rule__mdt
      WHERE Requirement_Field__c IN :fieldApiNames AND Is_Active__c = TRUE
    ]) {
      rulesByApi.put(validationRule.Requirement_Field__c, validationRule);
    }
    return rulesByApi;
  }

  private static String getValue(Requirement_Field_Value__c fieldValue) {
    if (fieldValue == null) {
      return null;
    }
    if (fieldValue.Encrypted_Value__c != null) {
      return String.valueOf(fieldValue.Encrypted_Value__c);
    }
    return fieldValue.Value__c;
  }

  private static Boolean isExternalValidation(String validationType) {
    return String.isNotBlank(validationType) &&
      validationType.toLowerCase().startsWith('external');
  }
}
