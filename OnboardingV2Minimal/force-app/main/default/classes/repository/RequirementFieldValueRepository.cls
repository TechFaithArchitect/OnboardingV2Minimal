/**
 * Repository for Requirement_Field_Value__c
 * Centralizes all SOQL queries for Requirement_Field_Value__c to follow repository pattern
 */
public with sharing class RequirementFieldValueRepository {

    /**
     * Get Requirement_Field_Value__c records by IDs with related field information
     * @param fieldValueIds Set of Requirement_Field_Value__c IDs
     * @return List of Requirement_Field_Value__c records with Requirement_Field__r relationship
     */
    public static List<Requirement_Field_Value__c> getFieldValuesByIds(Set<Id> fieldValueIds) {
        if (fieldValueIds == null || fieldValueIds.isEmpty()) {
            return new List<Requirement_Field_Value__c>();
        }

        return [
            SELECT Id, Value__c, Encrypted_Value__c, Validation_Status__c, 
                   Validation_Error_Message__c, Last_Validated_Date__c,
                   Requirement_Field__c, Requirement_Field__r.Field_API_Name__c,
                   Requirement_Field__r.Required__c, Requirement_Field__r.Validation_Type__c,
                   Requirement_Field__r.Requirement_Field_Group__c,
                   Onboarding_Requirement__c, Onboarding_Requirement__r.Onboarding__c
            FROM Requirement_Field_Value__c
            WHERE Id IN :fieldValueIds
        ];
    }

    /**
     * Get Requirement_Field_Value__c records for an onboarding requirement
     * @param requirementId Onboarding_Requirement__c ID
     * @return List of Requirement_Field_Value__c records
     */
    public static List<Requirement_Field_Value__c> getFieldValuesByRequirement(Id requirementId) {
        if (requirementId == null) {
            return new List<Requirement_Field_Value__c>();
        }

        return [
            SELECT Id, Value__c, Encrypted_Value__c, Validation_Status__c,
                   Validation_Error_Message__c, Last_Validated_Date__c,
                   Requirement_Field__c, Requirement_Field__r.Field_API_Name__c,
                   Requirement_Field__r.Required__c, Requirement_Field__r.Validation_Type__c,
                   Requirement_Field__r.Sequence__c,
                   Requirement_Field__r.Requirement_Field_Group__c,
                   Onboarding_Requirement__c
            FROM Requirement_Field_Value__c
            WHERE Onboarding_Requirement__c = :requirementId
            ORDER BY Requirement_Field__r.Requirement_Field_Group__r.Sequence__c,
                     Requirement_Field__r.Sequence__c
        ];
    }

    /**
     * Get Requirement_Field_Value__c records for an onboarding with invalid status
     * @param onboardingId Onboarding__c ID
     * @return List of Requirement_Field_Value__c records with Invalid or Needs Correction status
     */
    public static List<Requirement_Field_Value__c> getInvalidFieldValuesByOnboarding(Id onboardingId) {
        if (onboardingId == null) {
            return new List<Requirement_Field_Value__c>();
        }

        return [
            SELECT Id, Value__c, Encrypted_Value__c, Validation_Status__c,
                   Validation_Error_Message__c, Requirement_Field__c,
                   Requirement_Field__r.Field_API_Name__c,
                   Requirement_Field__r.Name,
                   Onboarding_Requirement__c, Onboarding_Requirement__r.Name
            FROM Requirement_Field_Value__c
            WHERE Onboarding_Requirement__r.Onboarding__c = :onboardingId
              AND Validation_Status__c IN ('Invalid', 'Needs Correction')
            ORDER BY Onboarding_Requirement__r.Name,
                     Requirement_Field__r.Name
        ];
    }

    /**
     * Get Requirement_Field_Value__c records for cross-field validation
     * Gets all field values for the same onboarding requirement (siblings)
     * @param fieldValueId Requirement_Field_Value__c ID to get siblings for
     * @return Map of Field_API_Name__c to Requirement_Field_Value__c
     */
    public static Map<String, Requirement_Field_Value__c> getSiblingFieldValues(Id fieldValueId) {
        if (fieldValueId == null) {
            return new Map<String, Requirement_Field_Value__c>();
        }

        // First get the requirement ID
        List<Requirement_Field_Value__c> sourceField = [
            SELECT Onboarding_Requirement__c
            FROM Requirement_Field_Value__c
            WHERE Id = :fieldValueId
            LIMIT 1
        ];

        if (sourceField.isEmpty()) {
            return new Map<String, Requirement_Field_Value__c>();
        }

        Id requirementId = sourceField[0].Onboarding_Requirement__c;

        // Get all sibling field values
        List<Requirement_Field_Value__c> siblings = [
            SELECT Id, Value__c, Encrypted_Value__c, Validation_Status__c,
                   Requirement_Field__c, Requirement_Field__r.Field_API_Name__c
            FROM Requirement_Field_Value__c
            WHERE Onboarding_Requirement__c = :requirementId
              AND Id != :fieldValueId
        ];

        // Build map by Field_API_Name__c
        Map<String, Requirement_Field_Value__c> siblingsByApi = new Map<String, Requirement_Field_Value__c>();
        for (Requirement_Field_Value__c sibling : siblings) {
            if (String.isNotBlank(sibling.Requirement_Field__r.Field_API_Name__c)) {
                siblingsByApi.put(sibling.Requirement_Field__r.Field_API_Name__c, sibling);
            }
        }

        return siblingsByApi;
    }

    /**
     * Get Requirement_Field_Value__c records pending validation
     * @param limitCount Maximum number of records to return
     * @return List of Requirement_Field_Value__c records with Pending status
     */
    public static List<Requirement_Field_Value__c> getPendingFieldValues(Integer limitCount) {
        if (limitCount == null || limitCount <= 0) {
            limitCount = 200;
        }

        return [
            SELECT Id, Value__c, Encrypted_Value__c, Validation_Status__c,
                   Requirement_Field__c, Requirement_Field__r.Field_API_Name__c,
                   Requirement_Field__r.Validation_Type__c,
                   Onboarding_Requirement__c
            FROM Requirement_Field_Value__c
            WHERE Validation_Status__c = 'Pending'
            ORDER BY Last_Validated_Date__c ASC NULLS FIRST
            LIMIT :limitCount
        ];
    }

    /**
     * Get count of invalid field values for an onboarding
     * @param onboardingId Onboarding__c ID
     * @return Count of invalid field values
     */
    public static Integer getInvalidFieldValueCount(Id onboardingId) {
        if (onboardingId == null) {
            return 0;
        }

        return [
            SELECT COUNT()
            FROM Requirement_Field_Value__c
            WHERE Onboarding_Requirement__r.Onboarding__c = :onboardingId
              AND Validation_Status__c IN ('Invalid', 'Needs Correction')
        ];
    }
}