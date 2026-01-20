/**
 * Controller for Requirement Field Value operations
 * Handles saving field values with auto-save and status updates
 */
public with sharing class RequirementFieldValueController {
  /**
   * Save a field value (create or update)
   * Updates Onboarding_Requirement__c status to Draft or Partially_Completed
   * @param requirementFieldValueId Existing Requirement_Field_Value__c ID (optional, for updates)
   * @param requirementFieldId Requirement_Field__c ID
   * @param onboardingRequirementId Onboarding_Requirement__c ID
   * @param fieldApiName API name of the field
   * @param value Field value to save
   * @param isEncrypted Whether to use Encrypted_Value__c field
   * @return SaveResult with record ID and status
   */
  @AuraEnabled
  public static SaveResult saveFieldValue(
    String requirementFieldValueId,
    String requirementFieldId,
    String onboardingRequirementId,
    String fieldApiName,
    String value,
    Boolean isEncrypted
  ) {
    SaveResult saveResult = new SaveResult();

    try {
      // Upsert Requirement_Field_Value__c
      Requirement_Field_Value__c fieldValue;

      if (String.isNotBlank(requirementFieldValueId)) {
        // Update existing
        fieldValue = [
          SELECT Id, Value__c, Encrypted_Value__c, Requirement_Field__c
          FROM Requirement_Field_Value__c
          WHERE Id = :requirementFieldValueId
          LIMIT 1
        ];
      } else {
        // Create new
        fieldValue = new Requirement_Field_Value__c();
        fieldValue.Requirement_Field__c = requirementFieldId;
        fieldValue.Onboarding_Requirement__c = onboardingRequirementId;
      }

      // Set value (encrypted or regular)
      if (isEncrypted) {
        fieldValue.Encrypted_Value__c = value;
        fieldValue.Value__c = null;
      } else {
        fieldValue.Value__c = value;
        fieldValue.Encrypted_Value__c = null;
      }

      upsert fieldValue;

      // Run synchronous validation for this field value
      try {
        RequirementFieldValidationService.validateAndUpdate(
          new Set<Id>{ fieldValue.Id }
        );
      } catch (Exception validationEx) {
        // Surface validation error in the response but do not block persistence
        saveResult.message =
          'Field saved, but validation failed: ' + validationEx.getMessage();
      }

      // For Cross-Field or External types, enqueue async validation for further checks
      try {
        if (String.isNotBlank(requirementFieldId)) {
          Requirement_Field__c reqField = [
            SELECT Validation_Type__c
            FROM Requirement_Field__c
            WHERE Id = :requirementFieldId
            LIMIT 1
          ];
          if (
            reqField.Validation_Type__c == 'Cross-Field' ||
            isExternalValidation(reqField.Validation_Type__c)
          ) {
            RequirementFieldAsyncValidator.enqueue(
              new Set<Id>{ fieldValue.Id }
            );
          }
        }
      } catch (Exception asyncEx) {
        // Do not block save if async enqueue fails
        System.debug(
          'Async validation enqueue failed: ' + asyncEx.getMessage()
        );
      }

      // Update Onboarding_Requirement__c status
      updateRequirementStatus(onboardingRequirementId);

      saveResult.id = fieldValue.Id;
      saveResult.success = true;
      saveResult.message = 'Field value saved successfully';
    } catch (Exception ex) {
      saveResult.success = false;
      saveResult.message = 'Error saving field value: ' + ex.getMessage();
      throw new AuraHandledException(saveResult.message);
    }

    return saveResult;
  }

  private static Boolean isExternalValidation(String validationType) {
    return String.isNotBlank(validationType) &&
      validationType.toLowerCase().startsWith('external');
  }

  /**
   * Update Onboarding_Requirement__c status based on completion
   * Status flow: New → Draft → Partially_Completed → In_Progress → Complete
   */
  private static void updateRequirementStatus(Id onboardingRequirementId) {
    if (onboardingRequirementId == null) {
      return;
    }

    try {
      // Query requirement and related field values separately
      // (Relationship name may vary - using separate query for reliability)
      Onboarding_Requirement__c requirement = [
        SELECT Id, Status__c
        FROM Onboarding_Requirement__c
        WHERE Id = :onboardingRequirementId
        LIMIT 1
      ];

      List<Requirement_Field_Value__c> fieldValues = [
        SELECT Id, Value__c, Encrypted_Value__c, Validation_Status__c
        FROM Requirement_Field_Value__c
        WHERE
          Onboarding_Requirement__c = :onboardingRequirementId
          AND Is_Archived__c = FALSE
      ];

      // Count completed fields
      Integer totalFields = fieldValues.size();
      Integer completedFields = 0;
      Integer validatedFields = 0;

      for (Requirement_Field_Value__c fieldValue : fieldValues) {
        if (
          String.isNotBlank(fieldValue.Value__c) ||
          String.isNotBlank(fieldValue.Encrypted_Value__c)
        ) {
          completedFields++;
        }
        if (fieldValue.Validation_Status__c == 'Valid') {
          validatedFields++;
        }
      }

      // Determine status
      String newStatus = requirement.Status__c;

      if (totalFields == 0) {
        // No fields yet - keep current status
        return;
      } else if (completedFields == 0) {
        // No fields completed - set to Draft
        newStatus = 'Draft';
      } else if (completedFields < totalFields) {
        // Some fields completed - set to Partially_Completed
        newStatus = 'Partially_Completed';
      } else if (validatedFields == totalFields) {
        // All fields completed and validated - set to Complete
        newStatus = 'Complete';
      } else {
        // All fields completed but not all validated - set to In_Progress
        newStatus = 'In_Progress';
      }

      // Only update if status changed
      if (newStatus != requirement.Status__c) {
        requirement.Status__c = newStatus;
        update requirement;
      }
    } catch (Exception ex) {
      System.debug('Error updating requirement status: ' + ex.getMessage());
      // Don't throw - status update is not critical for save operation
    }
  }

  /**
   * Result wrapper for save operations
   */
  public class SaveResult {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String message;
  }
}
