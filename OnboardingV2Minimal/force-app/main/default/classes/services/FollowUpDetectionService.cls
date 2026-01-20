/**
 * Service for detecting when follow-ups should be created
 * Evaluates Follow_Up_Rule__mdt conditions and creates Follow_Up_Queue__c records
 */
public with sharing class FollowUpDetectionService {
  /**
   * Evaluate follow-up rules for a requirement and create queue records if conditions are met
   * @param requirementId Onboarding_Requirement__c record ID
   */
  public static void evaluateAndCreateFollowUps(Id requirementId) {
    if (requirementId == null) {
      return;
    }

    // Get requirement with related data
    Onboarding_Requirement__c requirement = getRequirementWithContext(
      requirementId
    );
    if (requirement == null) {
      return;
    }

    // Get active follow-up rules
    List<Follow_Up_Rule__mdt> activeRules = getActiveFollowUpRules();
    if (activeRules.isEmpty()) {
      return;
    }

    // Evaluate each rule
    List<Follow_Up_Queue__c> followUpsToCreate = new List<Follow_Up_Queue__c>();

    for (Follow_Up_Rule__mdt followUpRule : activeRules) {
      if (evaluateRuleCondition(requirement, followUpRule)) {
        Follow_Up_Queue__c followUp = createFollowUpQueue(
          requirement,
          followUpRule
        );
        if (followUp != null) {
          followUpsToCreate.add(followUp);
        }
      }
    }

    // Insert follow-up queue records
    if (!followUpsToCreate.isEmpty()) {
      insert followUpsToCreate;
    }
  }

  /**
   * Enqueue follow-ups for onboarding records (called by existing trigger handler)
   * @param onboardingIds Set of Onboarding__c record IDs
   */
  public static void enqueueFollowUps(Set<Id> onboardingIds) {
    if (onboardingIds == null || onboardingIds.isEmpty()) {
      return;
    }

    // Get requirements for these onboardings
    Set<Id> requirementIds = new Set<Id>();
    try {
      List<Onboarding_Requirement__c> requirements = [
        SELECT Id
        FROM Onboarding_Requirement__c
        WHERE Onboarding__c IN :onboardingIds
      ];
      for (Onboarding_Requirement__c onboardingRequirement : requirements) {
        requirementIds.add(onboardingRequirement.Id);
      }
    } catch (Exception ex) {
      System.debug('Error querying requirements: ' + ex.getMessage());
      return;
    }

    if (!requirementIds.isEmpty()) {
      evaluateAndCreateFollowUpsBulk(requirementIds);
    }
  }

  /**
   * Evaluate follow-up rules for multiple requirements (bulk)
   * @param requirementIds Set of Onboarding_Requirement__c record IDs
   */
  public static void evaluateAndCreateFollowUpsBulk(Set<Id> requirementIds) {
    if (requirementIds == null || requirementIds.isEmpty()) {
      return;
    }

    // Get requirements with context
    Map<Id, Onboarding_Requirement__c> requirements = getRequirementsWithContext(
      requirementIds
    );
    if (requirements.isEmpty()) {
      return;
    }

    // Get active follow-up rules
    List<Follow_Up_Rule__mdt> activeRules = getActiveFollowUpRules();
    if (activeRules.isEmpty()) {
      return;
    }

    // Evaluate each rule for each requirement
    List<Follow_Up_Queue__c> followUpsToCreate = new List<Follow_Up_Queue__c>();

    for (
      Onboarding_Requirement__c onboardingRequirement : requirements.values()
    ) {
      for (Follow_Up_Rule__mdt followUpRule : activeRules) {
        if (evaluateRuleCondition(onboardingRequirement, followUpRule)) {
          // Check if follow-up already exists for this requirement and rule
          if (
            !followUpExists(
              onboardingRequirement.Id,
              followUpRule.DeveloperName
            )
          ) {
            Follow_Up_Queue__c followUp = createFollowUpQueue(
              onboardingRequirement,
              followUpRule
            );
            if (followUp != null) {
              followUpsToCreate.add(followUp);
            }
          }
        }
      }
    }

    // Insert follow-up queue records
    if (!followUpsToCreate.isEmpty()) {
      insert followUpsToCreate;
    }
  }

  /**
   * Get requirement with context data needed for rule evaluation
   */
  private static Onboarding_Requirement__c getRequirementWithContext(
    Id requirementId
  ) {
    try {
      List<Onboarding_Requirement__c> requirements = [
        SELECT
          Id,
          Name,
          Status__c,
          Onboarding__c,
          Onboarding__r.Account__c,
          Onboarding__r.Onboarding_Status__c,
          LastModifiedDate,
          CreatedDate,
          Vendor_Program_Requirement__c
        FROM Onboarding_Requirement__c
        WHERE Id = :requirementId
        LIMIT 1
      ];
      return requirements.isEmpty() ? null : requirements[0];
    } catch (Exception ex) {
      System.debug('Error querying requirement: ' + ex.getMessage());
      return null;
    }
  }

  /**
   * Get multiple requirements with context (bulk)
   */
  private static Map<Id, Onboarding_Requirement__c> getRequirementsWithContext(
    Set<Id> requirementIds
  ) {
    Map<Id, Onboarding_Requirement__c> requirements = new Map<Id, Onboarding_Requirement__c>();
    try {
      List<Onboarding_Requirement__c> onboardingRequirements = [
        SELECT
          Id,
          Name,
          Status__c,
          Onboarding__c,
          Onboarding__r.Account__c,
          Onboarding__r.Onboarding_Status__c,
          LastModifiedDate,
          CreatedDate,
          Vendor_Program_Requirement__c
        FROM Onboarding_Requirement__c
        WHERE Id IN :requirementIds
      ];
      for (
        Onboarding_Requirement__c onboardingRequirement : onboardingRequirements
      ) {
        requirements.put(onboardingRequirement.Id, onboardingRequirement);
      }
    } catch (Exception ex) {
      System.debug('Error querying requirements: ' + ex.getMessage());
    }
    return requirements;
  }

  /**
   * Get active follow-up rules from metadata
   */
  private static List<Follow_Up_Rule__mdt> getActiveFollowUpRules() {
    try {
      return [
        SELECT
          DeveloperName,
          Trigger_Condition__c,
          Follow_Up_Type__c,
          Initial_Delay_Days__c,
          Escalation_Schedule__c,
          Max_Attempts_Per_Window__c,
          Fatigue_Window_Days__c,
          Fatigue_Suppression_Enabled__c,
          Active__c
        FROM Follow_Up_Rule__mdt
        WHERE Active__c = TRUE
        ORDER BY Initial_Delay_Days__c ASC
      ];
    } catch (Exception ex) {
      System.debug('Error querying follow-up rules: ' + ex.getMessage());
      return new List<Follow_Up_Rule__mdt>();
    }
  }

  /**
   * Evaluate rule condition against requirement
   * Simple condition evaluation - can be enhanced for complex expressions
   */
  @TestVisible
  private static Boolean evaluateRuleCondition(
    Onboarding_Requirement__c requirement,
    Follow_Up_Rule__mdt followUpRule
  ) {
    if (
      followUpRule == null || String.isBlank(followUpRule.Trigger_Condition__c)
    ) {
      return false;
    }

    String condition = followUpRule.Trigger_Condition__c.trim();

    // Simple status check: "Status = 'In Process'"
    if (condition.contains('Status') && condition.contains('=')) {
      String statusValue = extractQuotedValue(condition);
      if (String.isNotBlank(statusValue)) {
        return requirement.Status__c == statusValue;
      }
    }

    // Days since last activity: "Days_Since_Last_Activity > 7"
    if (
      condition.contains('Days_Since_Last_Activity') && condition.contains('>')
    ) {
      Integer daysThreshold = extractNumber(condition);
      if (daysThreshold != null) {
        Integer daysSinceActivity = requirement.LastModifiedDate.date()
          .daysBetween(Date.today());
        return daysSinceActivity > daysThreshold;
      }
    }

    // Days since created: "Days_Since_Created > 3"
    if (condition.contains('Days_Since_Created') && condition.contains('>')) {
      Integer daysThreshold = extractNumber(condition);
      if (daysThreshold != null) {
        Integer daysSinceCreated = requirement.CreatedDate.date()
          .daysBetween(Date.today());
        return daysSinceCreated > daysThreshold;
      }
    }

    // Default: if condition contains requirement status, check it
    if (condition.contains(requirement.Status__c)) {
      return true;
    }

    return false;
  }

  /**
   * Extract quoted value from condition string
   */
  private static String extractQuotedValue(String condition) {
    Integer startQuote = condition.indexOf('\'');
    if (startQuote == -1) {
      startQuote = condition.indexOf('"');
    }
    if (startQuote == -1) {
      return null;
    }

    Integer endQuote = condition.indexOf('\'', startQuote + 1);
    if (endQuote == -1) {
      endQuote = condition.indexOf('"', startQuote + 1);
    }
    if (endQuote == -1) {
      return null;
    }

    return condition.substring(startQuote + 1, endQuote);
  }

  /**
   * Extract number from condition string
   */
  private static Integer extractNumber(String condition) {
    Pattern numberPattern = Pattern.compile('\\d+');
    Matcher matcher = numberPattern.matcher(condition);
    if (matcher.find()) {
      return Integer.valueOf(matcher.group());
    }
    return null;
  }

  /**
   * Create Follow_Up_Queue__c record from requirement and rule
   */
  private static Follow_Up_Queue__c createFollowUpQueue(
    Onboarding_Requirement__c requirement,
    Follow_Up_Rule__mdt rule
  ) {
    // Check fatigue suppression
    if (
      FollowUpFatigueService.shouldSuppressDueToFatigue(
        requirement.Id,
        rule.DeveloperName
      )
    ) {
      return null; // Suppressed due to fatigue
    }

    // Calculate next attempt date
    DateTime nextAttemptDate = calculateNextAttemptDate(requirement, rule);

    // Create follow-up queue record
    Follow_Up_Queue__c followUp = new Follow_Up_Queue__c();
    followUp.Onboarding_Requirement__c = requirement.Id;
    followUp.Onboarding__c = requirement.Onboarding__c;
    followUp.Follow_Up_Type__c = rule.Follow_Up_Type__c;
    followUp.Follow_Up_Rule__c = rule.DeveloperName;
    followUp.Status__c = 'Pending';
    followUp.Next_Attempt_Date__c = nextAttemptDate;
    followUp.Trigger_Reason__c = rule.Trigger_Condition__c;
    followUp.Priority__c = 'Medium'; // Default priority
    followUp.Attempt_Count__c = 0;
    followUp.Consecutive_Failures__c = 0;

    // Set timezone if available
    if (
      requirement.Onboarding__r != null &&
      requirement.Onboarding__r.Account__c != null
    ) {
      try {
        Account account = [
          SELECT Time_zone__pc
          FROM Account
          WHERE Id = :requirement.Onboarding__r.Account__c
          LIMIT 1
        ];
        // Timezone stored in custom field - adjust if field name differs
        // followUp.Timezone__c = account.Time_zone__pc;
      } catch (Exception ex) {
        // Timezone field may not exist or be accessible
        System.debug('Could not set timezone: ' + ex.getMessage());
      }
    }

    return followUp;
  }

  /**
   * Calculate next attempt date based on rule and requirement
   */
  private static DateTime calculateNextAttemptDate(
    Onboarding_Requirement__c requirement,
    Follow_Up_Rule__mdt rule
  ) {
    Integer delayDays = rule.Initial_Delay_Days__c != null
      ? rule.Initial_Delay_Days__c.intValue()
      : 0;

    // Use last modified date or created date
    Date baseDate = requirement.LastModifiedDate.date();
    if (delayDays == 0) {
      baseDate = Date.today();
    }

    Date nextDate = baseDate.addDays(delayDays);

    // Default to 9 AM in org timezone
    Time defaultTime = Time.newInstance(9, 0, 0, 0);
    return DateTime.newInstance(nextDate, defaultTime);
  }

  /**
   * Check if follow-up already exists for requirement and rule
   */
  private static Boolean followUpExists(
    Id requirementId,
    String ruleDeveloperName
  ) {
    try {
      Integer count = [
        SELECT COUNT()
        FROM Follow_Up_Queue__c
        WHERE
          Onboarding_Requirement__c = :requirementId
          AND Follow_Up_Rule__c = :ruleDeveloperName
          AND Status__c IN ('Pending', 'Pending Retry')
          AND Is_Archived__c = FALSE
        LIMIT 1
      ];
      return count > 0;
    } catch (Exception ex) {
      System.debug('Error checking existing follow-up: ' + ex.getMessage());
      return false;
    }
  }
}
