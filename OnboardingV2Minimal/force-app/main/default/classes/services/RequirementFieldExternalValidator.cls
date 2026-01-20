/**
 * Service for external validation of Requirement_Field_Value__c records
 * Integrates with external systems (e.g., credit checks, license verification, etc.)
 *
 * NOTE: This is a framework for external validation. Implement actual integrations as needed.
 */
public with sharing class RequirementFieldExternalValidator {
  /**
   * Validate field values externally
   * This method should be called from RequirementFieldAsyncValidator for External validation types
   *
   * @param fieldValueIds Set of Requirement_Field_Value__c IDs to validate externally
   */
  public static void validateExternally(Set<Id> fieldValueIds) {
    if (fieldValueIds == null || fieldValueIds.isEmpty()) {
      return;
    }

    // Get field values with their validation rules
    List<Requirement_Field_Value__c> fieldValues = RequirementFieldValueRepository.getFieldValuesByIds(
      fieldValueIds
    );

    // Group by validation rule to batch similar validations
    Map<String, List<Requirement_Field_Value__c>> valuesByRule = new Map<String, List<Requirement_Field_Value__c>>();
    Set<String> fieldApiNames = new Set<String>();

    for (Requirement_Field_Value__c fieldValue : fieldValues) {
      if (
        fieldValue.Requirement_Field__r != null &&
        String.isNotBlank(fieldValue.Requirement_Field__r.Field_API_Name__c)
      ) {
        fieldApiNames.add(fieldValue.Requirement_Field__r.Field_API_Name__c);
      }
    }

    // Load validation rules
    Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi = RequirementFieldValidationService.loadRulesByFieldApi(
      fieldApiNames
    );

    // Group field values by their validation rule
    for (Requirement_Field_Value__c fieldValue : fieldValues) {
      if (
        fieldValue.Requirement_Field__r == null ||
        String.isBlank(fieldValue.Requirement_Field__r.Field_API_Name__c)
      ) {
        continue;
      }

      Requirement_Field_Validation_Rule__mdt validationRule = rulesByApi.get(
        fieldValue.Requirement_Field__r.Field_API_Name__c
      );
      Boolean isExternal = validationRule != null
        ? isExternalValidation(validationRule.Validation_Type__c)
        : isExternalValidation(
            fieldValue.Requirement_Field__r.Validation_Type__c
          );
      if (!isExternal) {
        continue;
      }

      String ruleKey = (validationRule != null &&
        validationRule.DeveloperName != null)
        ? validationRule.DeveloperName
        : 'default';
      if (!valuesByRule.containsKey(ruleKey)) {
        valuesByRule.put(ruleKey, new List<Requirement_Field_Value__c>());
      }
      valuesByRule.get(ruleKey).add(fieldValue);
    }

    // Process each rule group
    List<Requirement_Field_Value__c> valuesToUpdate = new List<Requirement_Field_Value__c>();
    List<RequirementValidationLogger.LogEntry> logs = new List<RequirementValidationLogger.LogEntry>();

    for (String ruleKey : valuesByRule.keySet()) {
      List<Requirement_Field_Value__c> ruleValues = valuesByRule.get(ruleKey);

      // Call appropriate external validation based on rule configuration
      for (Requirement_Field_Value__c fieldValue : ruleValues) {
        // Get the rule for this specific field
        Requirement_Field_Validation_Rule__mdt validationRule = null;
        if (
          fieldValue.Requirement_Field__r != null &&
          String.isNotBlank(fieldValue.Requirement_Field__r.Field_API_Name__c)
        ) {
          validationRule = rulesByApi.get(
            fieldValue.Requirement_Field__r.Field_API_Name__c
          );
        }

        ExternalValidationResult externalValidationResult = performExternalValidation(
          fieldValue,
          validationRule
        );

        // Update field value based on result
        fieldValue.Validation_Status__c = externalValidationResult.isValid
          ? 'Valid'
          : 'Invalid';
        fieldValue.Validation_Error_Message__c = externalValidationResult.errorMessage;
        fieldValue.Last_Validated_Date__c = DateTime.now();
        valuesToUpdate.add(fieldValue);

        // Log the validation
        RequirementValidationLogger.LogEntry validationLog = new RequirementValidationLogger.LogEntry();
        validationLog.fieldValueId = fieldValue.Id;
        validationLog.fieldApiName = fieldValue.Requirement_Field__r != null
          ? fieldValue.Requirement_Field__r.Field_API_Name__c
          : null;
        validationLog.validationResult = fieldValue.Validation_Status__c;
        validationLog.validationType = 'External';
        validationLog.message = externalValidationResult.errorMessage;
        validationLog.correlationId = externalValidationResult.correlationId;
        validationLog.validatedOn = fieldValue.Last_Validated_Date__c;
        logs.add(validationLog);
      }
    }

    // Update field values
    if (!valuesToUpdate.isEmpty()) {
      update valuesToUpdate;
    }

    // Log validation results
    if (!logs.isEmpty()) {
      RequirementValidationLogger.log(logs);
    }
  }

  private static Boolean isExternalValidation(String validationType) {
    return String.isNotBlank(validationType) &&
      validationType.toLowerCase().startsWith('external');
  }

  /**
   * Perform external validation for a single field value
   * This method should be extended to integrate with actual external systems
   *
   * @param fieldValue Requirement_Field_Value__c to validate
   * @param rule Validation rule metadata
   * @return ExternalValidationResult
   */
  @TestVisible
  private static ExternalValidationResult performExternalValidation(
    Requirement_Field_Value__c fieldValue,
    Requirement_Field_Validation_Rule__mdt rule
  ) {
    ExternalValidationResult externalValidationResult = new ExternalValidationResult();
    externalValidationResult.correlationId = String.valueOf(
      Crypto.getRandomLong()
    );

    // TODO: Implement actual external validation based on rule configuration
    // Examples:
    // - Credit check API
    // - License verification service
    // - Tax ID validation
    // - Business registration lookup
    // - Address verification

    // For now, implement placeholder logic based on rule metadata
    String fieldApiName = fieldValue.Requirement_Field__r != null
      ? fieldValue.Requirement_Field__r.Field_API_Name__c
      : null;

    String fieldValueString = String.isNotBlank(fieldValue.Encrypted_Value__c)
      ? String.valueOf(fieldValue.Encrypted_Value__c)
      : fieldValue.Value__c;

    // Placeholder: Check if value is not blank (basic validation)
    if (String.isBlank(fieldValueString)) {
      externalValidationResult.isValid = false;
      externalValidationResult.errorMessage = 'External validation requires a value.';
      return externalValidationResult;
    }

    String externalService = (rule != null &&
      String.isNotBlank(rule.External_Service__c))
      ? rule.External_Service__c
      : 'ExternalValidationAPI';
    String endpoint = 'callout:' + externalService + '/validate';

    HttpRequest httpRequest = new HttpRequest();
    httpRequest.setEndpoint(endpoint);
    httpRequest.setMethod('POST');
    httpRequest.setHeader('Content-Type', 'application/json');
    httpRequest.setBody(
      JSON.serialize(
        new Map<String, Object>{
          'fieldApiName' => fieldApiName,
          'value' => fieldValueString,
          'ruleId' => rule != null ? rule.DeveloperName : null,
          'correlationId' => externalValidationResult.correlationId
        }
      )
    );

    try {
      HttpResponse httpResponse = new Http().send(httpRequest);
      Integer statusCode = httpResponse.getStatusCode();
      if (statusCode >= 200 && statusCode < 300) {
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(
          httpResponse.getBody()
        );
        Boolean isValidValue = response != null &&
          response.get('isValid') != null
          ? (Boolean) response.get('isValid')
          : false;
        externalValidationResult.isValid = isValidValue;
        externalValidationResult.errorMessage = response != null
          ? (String) response.get('errorMessage')
          : 'External validation failed.';
      } else {
        externalValidationResult.isValid = false;
        externalValidationResult.errorMessage = 'External validation service unavailable.';
      }
    } catch (Exception ex) {
      externalValidationResult.isValid = false;
      externalValidationResult.errorMessage =
        'External validation error: ' + ex.getMessage();
    }

    return externalValidationResult;
  }

  /**
   * Result class for external validation
   */
  public class ExternalValidationResult {
    public Boolean isValid;
    public String errorMessage;
    public String correlationId;
  }
}
