/**
 * Repository for onboarding admin metrics and counts.
 * Centralizes data access for dashboard controllers.
 */
public with sharing class OnboardingMetricsRepository {
  public static Integer getValidationFailureCount(DateTime since) {
    // MVP does not persist validation failure logs.
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
    // MVP does not persist webhook failure logs.
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

}
