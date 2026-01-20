/**
 * Repository for Onboarding Application activation operations.
 * Handles data access for activation workflows across multiple object types
 * within the Onboarding Application domain (vendor onboarding, dealer onboarding, etc.).
 */
public with sharing class OnboardingAppActivationRepository {
  /**
   * Queries an SObject by ID with dynamic fields.
   * Used for activation services that work with multiple object types in the Onboarding Application.
   *
   * @param objectApiName The API name of the object
   * @param recordId The record ID
   * @param selectFields List of field API names to select
   * @return The SObject record
   */
  public static SObject getById(
    String objectApiName,
    Id recordId,
    List<String> selectFields
  ) {
    String query =
      'SELECT ' +
      String.join(selectFields, ', ') +
      ' FROM ' +
      objectApiName +
      ' WHERE Id = :recordId LIMIT 1';
    return Database.query(query);
  }

  /**
   * Queries sibling records for versioning within the Onboarding Application.
   *
   * @param objectApiName The API name of the object
   * @param parentVersionId The Previous_Version__c ID
   * @param recordId The record ID to exclude
   * @param activeFieldName The active field name (Active__c or Is_Active__c)
   * @return List of sibling SObject records
   */
  public static List<SObject> getActiveSiblingsByParentVersion(
    String objectApiName,
    Id parentVersionId,
    Id recordId,
    String activeFieldName
  ) {
    String query =
      'SELECT Id FROM ' +
      objectApiName +
      ' WHERE Previous_Version__c = :parentVersionId ' +
      'AND Id != :recordId ' +
      'AND ' +
      activeFieldName +
      ' = true';
    return Database.query(query);
  }

  /**
   * Updates SObject records for Onboarding Application activation.
   *
   * @param records List of SObject records to update
   */
  public static void updateRecords(List<SObject> sObjectRecords) {
    if (sObjectRecords != null && !sObjectRecords.isEmpty()) {
      update sObjectRecords;
    }
  }

  /**
   * Updates a single SObject record for Onboarding Application activation.
   *
   * @param sObjectRecord The SObject record to update
   */
  public static void updateRecord(SObject sObjectRecord) {
    if (sObjectRecord != null) {
      update sObjectRecord;
    }
  }
}
