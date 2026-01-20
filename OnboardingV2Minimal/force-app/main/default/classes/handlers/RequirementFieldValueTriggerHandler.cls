/**
 * Handler for Requirement_Field_Value__c trigger
 * Automatically enqueues async validation for Cross-Field and External validation types
 */
public with sharing class RequirementFieldValueTriggerHandler {

    /**
     * Handle after insert and after update
     * Enqueues async validation for fields that require Cross-Field or External validation
     */
    public static void handleAfterSave(List<Requirement_Field_Value__c> newRecords, Map<Id, Requirement_Field_Value__c> oldMap) {
        Set<Id> fieldValueIdsToEnqueue = new Set<Id>();
        Set<Id> requirementFieldIds = new Set<Id>();

        // Collect field value IDs that need async validation
        for (Requirement_Field_Value__c newRecord : newRecords) {
            Requirement_Field_Value__c oldRecord = oldMap != null ? oldMap.get(newRecord.Id) : null;

            // Only process if:
            // 1. Field value was just created, OR
            // 2. Value changed (Value__c or Encrypted_Value__c), OR
            // 3. Validation status is Pending (needs async validation)
            Boolean shouldProcess = false;

            if (oldRecord == null) {
                // New record - check if it needs async validation
                shouldProcess = true;
            } else {
                // Existing record - check if value changed or status is Pending
                Boolean valueChanged = (newRecord.Value__c != oldRecord.Value__c) ||
                                      (newRecord.Encrypted_Value__c != oldRecord.Encrypted_Value__c);
                Boolean isPending = newRecord.Validation_Status__c == 'Pending';
                shouldProcess = valueChanged || isPending;
            }

            if (shouldProcess && newRecord.Requirement_Field__c != null) {
                requirementFieldIds.add(newRecord.Requirement_Field__c);
                fieldValueIdsToEnqueue.add(newRecord.Id);
            }
        }

        // If no records to process, exit early
        if (requirementFieldIds.isEmpty() || fieldValueIdsToEnqueue.isEmpty()) {
            return;
        }

        // Query requirement fields to determine validation types
        Map<Id, Requirement_Field__c> requirementFields = new Map<Id, Requirement_Field__c>([
            SELECT Id, Validation_Type__c
            FROM Requirement_Field__c
            WHERE Id IN :requirementFieldIds
        ]);

        // Filter to only Cross-Field and External types
        Set<Id> asyncFieldValueIds = new Set<Id>();
        for (Requirement_Field_Value__c fieldValueRecord : newRecords) {
            if (fieldValueIdsToEnqueue.contains(fieldValueRecord.Id)) {
                Requirement_Field__c reqField = requirementFields.get(fieldValueRecord.Requirement_Field__c);
                if (reqField != null && 
                    (reqField.Validation_Type__c == 'Cross-Field' || isExternalValidation(reqField.Validation_Type__c))) {
                    asyncFieldValueIds.add(fieldValueRecord.Id);
                }
            }
        }

        // Enqueue async validation for eligible field values
        if (!asyncFieldValueIds.isEmpty()) {
            // Use future method to avoid mixed DML issues
            enqueueAsyncValidation(asyncFieldValueIds);
        }
    }

    /**
     * Future method to enqueue async validation
     * Prevents mixed DML issues when called from trigger context
     */
    @future
    private static void enqueueAsyncValidation(Set<Id> fieldValueIds) {
        try {
            RequirementFieldAsyncValidator.enqueue(fieldValueIds);
        } catch (Exception ex) {
            // Log error but don't throw - async validation failure shouldn't block saves
            System.debug('Error enqueueing async validation: ' + ex.getMessage());
            System.debug('Stack trace: ' + ex.getStackTraceString());
        }
    }

    private static Boolean isExternalValidation(String validationType) {
        return String.isNotBlank(validationType) && validationType.toLowerCase().startsWith('external');
    }
}