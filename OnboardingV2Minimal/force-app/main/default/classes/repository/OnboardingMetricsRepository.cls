/**
 * Repository for onboarding admin metrics and counts.
 * Centralizes data access for dashboard controllers.
 */
public with sharing class OnboardingMetricsRepository {
  public static Integer getValidationFailureCount(DateTime since) {
    // Placeholder until Validation_Failure__c is available
    // SELECT COUNT() FROM Validation_Failure__c WHERE CreatedDate >= :since AND Status__c = 'Failed'
    return 0;
  }

  public static Integer getMessageFailureCount(DateTime since) {
    try {
      return [
        SELECT COUNT()
        FROM Follow_Up_Queue__c
        WHERE Status__c = 'Failed' AND CreatedDate >= :since
        LIMIT 10000
      ];
    } catch (Exception ex) {
      System.debug('Error counting message failures: ' + ex.getMessage());
      return 0;
    }
  }

  public static Integer getWebhookFailureCount(DateTime since) {
    // Placeholder until AdobeSyncFailure__c exists
    return 0;
  }

  public static Integer getPlatformEventVolume(DateTime since) {
    // Placeholder for Event Monitoring
    return 0;
  }

  public static Integer getActiveFollowUpQueueCount() {
    try {
      return [
        SELECT COUNT()
        FROM Follow_Up_Queue__c
        WHERE
          Status__c IN ('Pending', 'Pending Retry')
          AND Is_Archived__c = FALSE
        LIMIT 10000
      ];
    } catch (Exception ex) {
      System.debug(
        'Error counting active follow-up queues: ' + ex.getMessage()
      );
      return 0;
    }
  }

  public static Integer getOverrideOperationCount(DateTime since) {
    // Placeholder until Onboarding_External_Override_Log__c exists
    return 0;
  }

  public static List<Validation_Failure__c> getValidationFailures(
    DateTime startDate,
    Map<String, Object> filters
  ) {
    // Guard in case object is not yet deployed
    try {
      String validationType = filters != null
        ? (String) filters.get('validationType')
        : null;
      String query =
        'SELECT Id, Name, Rule_Name__c, Requirement_Field__c, Validation_Result__c, ' +
        'Message__c, Validated_On__c, CreatedDate, CreatedBy.Name ' +
        'FROM Validation_Failure__c ' +
        'WHERE CreatedDate >= :startDate ';

      if (String.isNotBlank(validationType)) {
        query += 'AND Validation_Type__c = :validationType ';
      }

      query += 'ORDER BY CreatedDate DESC LIMIT 1000';
      return Database.query(query);
    } catch (Exception ex) {
      System.debug('Error querying validation failures: ' + ex.getMessage());
      return new List<Validation_Failure__c>();
    }
  }
}
