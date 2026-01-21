/**
 * Utility class for common validation patterns
 * Eliminates code duplication and provides consistent error messages
 */
public with sharing class ValidationHelper {
    
    /**
     * Validates that an object is not null
     * @param obj The object to validate
     * @param fieldName The name of the field for error message
     * @throws AuraHandledException if object is null
     */
    public static void requireNotNull(Object objectToValidate, String fieldName) {
        if (objectToValidate == null) {
            throw new AuraHandledException(fieldName + ' is required.');
        }
    }
    
    /**
     * Validates that a string is not null or blank
     * @param str The string to validate
     * @param fieldName The name of the field for error message
     * @throws AuraHandledException if string is blank
     */
    public static void requireNotBlank(String str, String fieldName) {
        if (String.isBlank(str)) {
            throw new AuraHandledException(fieldName + ' is required.');
        }
    }
    
    /**
     * Validates that a list is not null or empty
     * @param valueList The list to validate
     * @param fieldName The name of the field for error message
     * @throws AuraHandledException if list is null or empty
     */
    public static void requireNotEmpty(List<Object> valueList, String fieldName) {
        if (valueList == null || valueList.isEmpty()) {
            throw new AuraHandledException(fieldName + ' is required.');
        }
    }
    
    /**
     * Validates that a list of IDs is not null or empty
     * @param idList The list of IDs to validate
     * @param fieldName The name of the field for error message
     * @throws AuraHandledException if list is null or empty
     */
    public static void requireNotEmpty(List<Id> idList, String fieldName) {
        if (idList == null || idList.isEmpty()) {
            throw new AuraHandledException(fieldName + ' is required.');
        }
    }
    
    /**
     * Validates that a list of SObjects is not null or empty
     * @param recordList The list of records to validate
     * @param fieldName The name of the field for error message
     * @throws AuraHandledException if list is null or empty
     */
    public static void requireNotEmpty(List<SObject> recordList, String fieldName) {
        if (recordList == null || recordList.isEmpty()) {
            throw new AuraHandledException(fieldName + ' is required.');
        }
    }
    
    /**
     * Validates that a list of Vendor Program Requirements is not null or empty
     * @param requirementList The list of requirements to validate
     * @param fieldName The name of the field for error message
     * @throws AuraHandledException if list is null or empty
     */
    public static void requireNotEmpty(List<Vendor_Program_Requirement__c> requirementList, String fieldName) {
        if (requirementList == null || requirementList.isEmpty()) {
            throw new AuraHandledException(fieldName + ' is required.');
        }
    }
    
    /**
     * Validates that a set is not null or empty
     * @param valueSet The set to validate
     * @param fieldName The name of the field for error message
     * @throws AuraHandledException if set is null or empty
     */
    public static void requireNotEmpty(Set<Object> valueSet, String fieldName) {
        if (valueSet == null || valueSet.isEmpty()) {
            throw new AuraHandledException(fieldName + ' is required.');
        }
    }
    
    /**
     * Validates that an ID is not null
     * @param idValue The ID to validate
     * @param fieldName The name of the field for error message
     * @throws AuraHandledException if ID is null
     */
    public static void requireId(Id idValue, String fieldName) {
        if (idValue == null) {
            throw new AuraHandledException(fieldName + ' is required.');
        }
    }
    
    /**
     * Validates a record is not null with a custom message
     * @param record The record to validate
     * @param recordTypeName The type name for error message (e.g., "Vendor Program")
     * @throws AuraHandledException if record is null
     */
    public static void requireRecord(SObject sObjectRecord, String recordTypeName) {
        if (sObjectRecord == null) {
            throw new AuraHandledException(recordTypeName + ' record is required.');
        }
    }
    
    /**
     * Validates a record field is not blank with a custom message
     * @param fieldValue The field value to validate
     * @param fieldLabel The field label for error message (e.g., "Vendor Name")
     * @throws AuraHandledException if field is blank
     */
    public static void requireField(String fieldValue, String fieldLabel) {
        if (String.isBlank(fieldValue)) {
            throw new AuraHandledException(fieldLabel + ' is required.');
        }
    }
    
    /**
     * Validates a record field with object type context
     * @param fieldValue The field value to validate
     * @param objectType The object type (e.g., "Vendor Program Group")
     * @param fieldName The field API name (e.g., "Label__c")
     * @throws AuraHandledException if field is blank
     */
    public static void requireFieldForObject(String fieldValue, String objectType, String fieldName) {
        if (String.isBlank(fieldValue)) {
            throw new AuraHandledException(fieldName + ' is required for ' + objectType + '. Please provide a ' + fieldName + '.');
        }
    }
}