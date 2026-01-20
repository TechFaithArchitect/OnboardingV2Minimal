/**
 * Controller for Onboarding Admin Dashboard
 * Provides system health metrics and monitoring data
 */
public with sharing class OnboardingAdminDashboardController {
  /**
   * Get system health metrics for the admin dashboard
   * @return SystemHealthMetrics wrapper with all metrics
   */
  @AuraEnabled(cacheable=true)
  public static SystemHealthMetrics getSystemHealthMetrics() {
    SystemHealthMetrics metrics = new SystemHealthMetrics();

    // Validation failures (last 24 hours)
    DateTime last24h = DateTime.now().addHours(-24);
    DateTime last48h = DateTime.now().addHours(-48);

    // Count validation failures in last 24h
    // Note: Validation_Failure__c object will be created in Phase 1
    // For now, return 0 or query from existing failure tracking
    metrics.validationFailures24h = OnboardingMetricsRepository.getValidationFailureCount(
      last24h
    );
    metrics.validationFailuresTrend =
      metrics.validationFailures24h -
      OnboardingMetricsRepository.getValidationFailureCount(last48h);

    // Message failures (last 24 hours)
    metrics.messageFailures24h = OnboardingMetricsRepository.getMessageFailureCount(
      last24h
    );
    metrics.messageFailuresTrend =
      metrics.messageFailures24h -
      OnboardingMetricsRepository.getMessageFailureCount(last48h);

    // Webhook failures (last 24 hours)
    // Note: AdobeSyncFailure__c will be created in Phase 3
    metrics.webhookFailures24h = OnboardingMetricsRepository.getWebhookFailureCount(
      last24h
    );
    metrics.webhookFailuresTrend =
      metrics.webhookFailures24h -
      OnboardingMetricsRepository.getWebhookFailureCount(last48h);

    // Platform Event volume (last hour)
    DateTime last1h = DateTime.now().addHours(-1);
    metrics.platformEventVolume1h = OnboardingMetricsRepository.getPlatformEventVolume(
      last1h
    );

    // Active follow-up queues
    metrics.activeFollowUpQueues = OnboardingMetricsRepository.getActiveFollowUpQueueCount();

    // Override operations (last 7 days)
    // Note: Onboarding_External_Override_Log__c will be created in Phase 4
    DateTime last7d = DateTime.now().addDays(-7);
    metrics.overrideOperations7d = OnboardingMetricsRepository.getOverrideOperationCount(
      last7d
    );

    return metrics;
  }

  /**
   * Get validation failures with filtering and grouping
   * Note: Validation_Failure__c object will be created in Phase 1
   * @param groupBy Grouping option: 'rule', 'user', or 'requirement'
   * @param filters Map of filter criteria
   * @return List of ValidationFailureDTO records
   */
  @AuraEnabled(cacheable=false)
  public static List<ValidationFailureDTO> getValidationFailures(
    String groupBy,
    Map<String, Object> filters
  ) {
    List<ValidationFailureDTO> failures = new List<ValidationFailureDTO>();

    DateTime startDate = getStartDateForFilter(
      (String) filters.get('dateRange')
    );

    List<Validation_Failure__c> validationFailures = OnboardingMetricsRepository.getValidationFailures(
      startDate,
      filters
    );
    for (Validation_Failure__c failure : validationFailures) {
      failures.add(new ValidationFailureDTO(failure));
    }

    return failures;
  }

  /**
   * Retry validation for a specific failure
   * @param failureId Validation_Failure__c record ID
   * @return Success message
   */
  @AuraEnabled
  public static String retryValidation(Id failureId) {
    // TODO: Implement retry logic when Validation_Failure__c is created
    // This will trigger re-validation of the field value
    return 'Retry initiated (to be implemented in Phase 1)';
  }

  /**
   * Get start date for filter
   */
  private static DateTime getStartDateForFilter(String filter) {
    if (filter == 'LAST_24_HOURS') {
      return DateTime.now().addHours(-24);
    } else if (filter == 'LAST_7_DAYS') {
      return DateTime.now().addDays(-7);
    } else if (filter == 'LAST_30_DAYS') {
      return DateTime.now().addDays(-30);
    }
    return DateTime.now().addYears(-10); // All time
  }

  /**
   * Wrapper class for system health metrics
   */
  public class SystemHealthMetrics {
    @AuraEnabled
    public Integer validationFailures24h = 0;
    @AuraEnabled
    public Integer validationFailuresTrend = 0;
    @AuraEnabled
    public Integer messageFailures24h = 0;
    @AuraEnabled
    public Integer messageFailuresTrend = 0;
    @AuraEnabled
    public Integer webhookFailures24h = 0;
    @AuraEnabled
    public Integer webhookFailuresTrend = 0;
    @AuraEnabled
    public Integer platformEventVolume1h = 0;
    @AuraEnabled
    public Integer activeFollowUpQueues = 0;
    @AuraEnabled
    public Integer overrideOperations7d = 0;
  }

  /**
   * DTO for validation failure records
   */
  public class ValidationFailureDTO {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String ruleName;
    @AuraEnabled
    public String requirementFieldApiName;
    @AuraEnabled
    public String validationResult;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String createdBy;
    @AuraEnabled
    public DateTime createdDate;
    @AuraEnabled
    public DateTime validatedOn;

    public ValidationFailureDTO() {
      // Default constructor for AuraEnabled
    }

    public ValidationFailureDTO(Validation_Failure__c failure) {
      this.id = failure.Id;
      this.name = failure.Name;
      this.ruleName = failure.Rule_Name__c;
      this.requirementFieldApiName = failure.Requirement_Field__c;
      this.validationResult = failure.Validation_Result__c;
      this.message = failure.Message__c;
      this.createdBy = failure.CreatedBy != null
        ? failure.CreatedBy.Name
        : null;
      this.createdDate = failure.CreatedDate;
      this.validatedOn = failure.Validated_On__c;
    }
  }

  /**
   * Get messaging issues from Follow_Up_Queue__c
   * @param groupBy Grouping option: 'type', 'status', or 'onboarding'
   * @param filters Map of filter criteria
   * @return List of MessagingIssueDTO records
   */
  @AuraEnabled(cacheable=false)
  public static List<MessagingIssueDTO> getMessagingIssues(
    String groupBy,
    Map<String, Object> filters
  ) {
    List<MessagingIssueDTO> issues = new List<MessagingIssueDTO>();

    DateTime startDate = getStartDateForFilter(
      (String) filters.get('dateRange')
    );
    String statusFilter = (String) filters.get('status');
    String typeFilter = (String) filters.get('type');

    String query =
      'SELECT Id, Name, Follow_Up_Type__c, Status__c, ' +
      'Onboarding__c, Onboarding__r.Name, ' +
      'Onboarding__r.Account__c, Onboarding__r.Account__r.Name, ' +
      'Trigger_Reason__c, Error_Message__c, CreatedDate, ' +
      'Attempt_Count__c, Last_Attempt_Date__c, ' +
      'Consecutive_Failures__c ' +
      'FROM Follow_Up_Queue__c ' +
      'WHERE CreatedDate >= :startDate ' +
      'AND Is_Archived__c = false ';

    if (statusFilter != null && statusFilter != '') {
      query += 'AND Status__c = :statusFilter ';
    } else {
      // Default to showing failed and pending retry
      query += 'AND Status__c IN (\'Failed\', \'Pending Retry\', \'Pending\') ';
    }

    if (typeFilter != null && typeFilter != '') {
      query += 'AND Follow_Up_Type__c = :typeFilter ';
    }

    query += 'ORDER BY CreatedDate DESC LIMIT 1000';

    List<Follow_Up_Queue__c> followUpQueueRecords = Database.query(query);
    for (Follow_Up_Queue__c issue : followUpQueueRecords) {
      issues.add(new MessagingIssueDTO(issue));
    }

    return issues;
  }

  /**
   * Retry messaging for a specific issue
   * @param issueId Follow_Up_Queue__c record ID
   * @return Success message
   */
  @AuraEnabled
  public static String retryMessaging(Id issueId) {
    try {
      Follow_Up_Queue__c issue = [
        SELECT Id, Status__c, Attempt_Count__c, Follow_Up_Type__c
        FROM Follow_Up_Queue__c
        WHERE Id = :issueId
        LIMIT 1
      ];

      // Mark as pending retry and attempt immediately
      issue.Status__c = 'Pending Retry';
      issue.Attempt_Count__c =
        (issue.Attempt_Count__c == null ? 0 : issue.Attempt_Count__c) + 1;
      update issue;

      // Execute based on type
      if (issue.Follow_Up_Type__c == 'SMS') {
        FollowUpExecutionService.sendSMSFollowUp(issue.Id);
      } else if (issue.Follow_Up_Type__c == 'Email') {
        FollowUpExecutionService.sendEmailFollowUp(issue.Id);
      } else {
        // Unknown type; leave in Pending Retry
      }

      return 'Retry initiated successfully';
    } catch (Exception ex) {
      throw new AuraHandledException(
        'Failed to retry messaging: ' + ex.getMessage()
      );
    }
  }

  /**
   * Dismiss a messaging issue
   * @param issueId Follow_Up_Queue__c record ID
   * @return Success message
   */
  @AuraEnabled
  public static String dismissMessagingIssue(Id issueId) {
    try {
      Follow_Up_Queue__c issue = [
        SELECT Id, Status__c
        FROM Follow_Up_Queue__c
        WHERE Id = :issueId
        LIMIT 1
      ];

      issue.Status__c = 'Resolved';
      issue.Is_Archived__c = true;
      update issue;

      return 'Issue dismissed successfully';
    } catch (Exception ex) {
      throw new AuraHandledException(
        'Failed to dismiss issue: ' + ex.getMessage()
      );
    }
  }

  /**
   * DTO for messaging issue records
   */
  public class MessagingIssueDTO {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String followUpType;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String onboardingId;
    @AuraEnabled
    public String onboardingName;
    @AuraEnabled
    public String accountName;
    @AuraEnabled
    public String errorMessage;
    @AuraEnabled
    public Integer attemptCount;
    @AuraEnabled
    public DateTime lastAttemptDate;
    @AuraEnabled
    public DateTime createdDate;

    public MessagingIssueDTO(Follow_Up_Queue__c issue) {
      this.id = issue.Id;
      this.followUpType = issue.Follow_Up_Type__c;
      this.status = issue.Status__c;
      this.onboardingId = issue.Onboarding__c;
      this.onboardingName = issue.Onboarding__r?.Name;
      this.accountName = issue.Onboarding__r?.Account__r?.Name;
      this.errorMessage = String.isNotBlank(issue.Error_Message__c)
        ? issue.Error_Message__c
        : issue.Trigger_Reason__c;
      this.attemptCount = issue.Attempt_Count__c != null
        ? issue.Attempt_Count__c.intValue()
        : 0;
      this.lastAttemptDate = issue.Last_Attempt_Date__c;
      this.createdDate = issue.CreatedDate;
    }
  }

  /**
   * Get Adobe sync failures
   * Note: AdobeSyncFailure__c object will be created in Phase 3
   * @param groupBy Grouping option: 'type', 'status', or 'onboarding'
   * @param filters Map of filter criteria
   * @return List of AdobeSyncFailureDTO records
   */
  @AuraEnabled(cacheable=false)
  public static List<AdobeSyncFailureDTO> getAdobeSyncFailures(
    String groupBy,
    Map<String, Object> filters
  ) {
    // TODO: Query AdobeSyncFailure__c when object is created in Phase 3
    // For now, return empty list
    List<AdobeSyncFailureDTO> failures = new List<AdobeSyncFailureDTO>();

    /*
        DateTime startDate = getStartDateForFilter((String)filters.get('dateRange'));
        String statusFilter = (String)filters.get('status');
        String typeFilter = (String)filters.get('type');
        
        String query = 'SELECT Id, Name, Failure_Type__c, Status__c, ' +
                      'Onboarding__c, Onboarding__r.Name, ' +
                      'Onboarding__r.Account__c, Onboarding__r.Account__r.Name, ' +
                      'Error_Message__c, CreatedDate, ' +
                      'Retry_Count__c, Last_Retry_Date__c ' +
                      'FROM AdobeSyncFailure__c ' +
                      'WHERE CreatedDate >= :startDate ' +
                      'AND Status__c != \'Resolved\' ';
        
        if (statusFilter != null && statusFilter != '') {
            query += 'AND Status__c = :statusFilter ';
        }
        
        if (typeFilter != null && typeFilter != '') {
            query += 'AND Failure_Type__c = :typeFilter ';
        }
        
        query += 'ORDER BY CreatedDate DESC LIMIT 1000';
        
        List<AdobeSyncFailure__c> adobeSyncFailures = Database.query(query);
        for (AdobeSyncFailure__c failure : adobeSyncFailures) {
            failures.add(new AdobeSyncFailureDTO(failure));
        }
        */

    return failures;
  }

  /**
   * Retry Adobe sync for a specific failure
   * @param failureId AdobeSyncFailure__c record ID
   * @return Success message
   */
  @AuraEnabled
  public static String retryAdobeSync(Id failureId) {
    // TODO: Implement retry logic when AdobeSyncFailure__c is created
    // This will trigger Platform Event to retry the webhook
    return 'Retry initiated (to be implemented in Phase 3)';
  }

  /**
   * Mark Adobe sync failure as resolved
   * @param failureId AdobeSyncFailure__c record ID
   * @return Success message
   */
  @AuraEnabled
  public static String resolveAdobeSyncFailure(Id failureId) {
    // TODO: Implement resolve logic when AdobeSyncFailure__c is created
    return 'Failure resolved (to be implemented in Phase 3)';
  }

  /**
   * DTO for Adobe sync failure records
   */
  public class AdobeSyncFailureDTO {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String failureType;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String onboardingId;
    @AuraEnabled
    public String onboardingName;
    @AuraEnabled
    public String accountName;
    @AuraEnabled
    public String errorMessage;
    @AuraEnabled
    public Integer retryCount;
    @AuraEnabled
    public DateTime lastRetryDate;
    @AuraEnabled
    public DateTime createdDate;

    public AdobeSyncFailureDTO() {
      // Default constructor for AuraEnabled
    }

    // TODO: Add constructor that takes AdobeSyncFailure__c when object is created
    /*
        public AdobeSyncFailureDTO(AdobeSyncFailure__c failure) {
            this.id = failure.Id;
            this.failureType = failure.Failure_Type__c;
            this.status = failure.Status__c;
            this.onboardingId = failure.Onboarding__c;
            this.onboardingName = failure.Onboarding__r?.Name;
            this.accountName = failure.Onboarding__r?.Account__r?.Name;
            this.errorMessage = failure.Error_Message__c;
            this.retryCount = failure.Retry_Count__c != null ? failure.Retry_Count__c.intValue() : 0;
            this.lastRetryDate = failure.Last_Retry_Date__c;
            this.createdDate = failure.CreatedDate;
        }
        */
  }
}
