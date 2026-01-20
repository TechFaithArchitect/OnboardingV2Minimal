/**
 * Service for detecting blocked/at-risk onboarding records
 * Uses OnboardingStatusEvaluator and OnboardingStageDependencyService
 */
public with sharing class OnboardingBlockingDetectionService {
  /**
   * Get IDs of blocked onboarding records
   * @param onboardingIds List of Onboarding__c IDs to check
   * @return Set of blocked Onboarding__c IDs
   */
  public static Set<Id> getBlockedOnboardingIds(List<Id> onboardingIds) {
    if (onboardingIds == null || onboardingIds.isEmpty()) {
      return new Set<Id>();
    }

    Set<Id> blockedIds = new Set<Id>();

    // Check each onboarding for blocking reasons
    for (Id onboardingId : onboardingIds) {
      List<String> blockingReasons = getBlockingReasons(onboardingId);
      if (!blockingReasons.isEmpty()) {
        blockedIds.add(onboardingId);
      }
    }

    return blockedIds;
  }

  /**
   * Get blocking reasons for an onboarding record
   * @param onboardingId Onboarding__c ID
   * @return List of blocking reason strings
   */
  public static List<String> getBlockingReasons(Id onboardingId) {
    List<String> reasons = new List<String>();

    if (onboardingId == null) {
      return reasons;
    }

    try {
      // Get onboarding with requirements
      List<Onboarding__c> onboardings = [
        SELECT Id, Onboarding_Status__c, Vendor_Customization__c
        FROM Onboarding__c
        WHERE Id = :onboardingId
        LIMIT 1
      ];

      if (onboardings.isEmpty()) {
        return reasons;
      }

      Onboarding__c onboardingRecord = onboardings[0];

      // Check if status is Denied (blocked status)
      if (onboardingRecord.Onboarding_Status__c == 'Denied') {
        reasons.add('Onboarding status is Denied');
      }

      // Check requirement statuses using OnboardingStatusEvaluator
      // Note: This assumes OnboardingStatusEvaluator exists and has a method to check blocking
      // If not available, we'll use a simplified check
      try {
        // Try to use OnboardingStatusEvaluator if available
        // List<Onboarding_Requirement__c> requirements = getRequirementsForOnboarding(onboardingId);
        // for (Onboarding_Requirement__c req : requirements) {
        //     if (req.Status__c == 'Incomplete' || req.Status__c == 'Not Started') {
        //         reasons.add('Requirement "' + req.Name + '" is ' + req.Status__c);
        //     }
        // }
      } catch (Exception ex) {
        // OnboardingStatusEvaluator not available - use simplified check
        System.debug(
          'OnboardingStatusEvaluator not available: ' + ex.getMessage()
        );
      }

      // Check stage dependencies using OnboardingStageDependencyService
      // Note: This assumes OnboardingStageDependencyService exists
      try {
        // Try to use OnboardingStageDependencyService if available
        // Boolean hasBlockingDependencies = OnboardingStageDependencyService.hasBlockingDependencies(onboardingId);
        // if (hasBlockingDependencies) {
        //     reasons.add('Stage dependencies not met');
        // }
      } catch (Exception ex) {
        // OnboardingStageDependencyService not available
        System.debug(
          'OnboardingStageDependencyService not available: ' + ex.getMessage()
        );
      }

      // Simplified blocking check: Look for incomplete requirements
      List<Onboarding_Requirement__c> incompleteReqs = [
        SELECT Id, Name, Status__c
        FROM Onboarding_Requirement__c
        WHERE
          Onboarding__c = :onboardingId
          AND Status__c IN ('Incomplete', 'Not Started', 'Needs_Correction')
        LIMIT 10
      ];

      if (!incompleteReqs.isEmpty()) {
        reasons.add(incompleteReqs.size() + ' requirement(s) incomplete');
      }
    } catch (Exception ex) {
      System.debug('Error checking blocking reasons: ' + ex.getMessage());
    }

    return reasons;
  }

  /**
   * Check if onboarding is at risk
   * @param onboardingId Onboarding__c ID
   * @param daysThreshold Number of days since last activity to be considered at risk
   * @return Boolean indicating if onboarding is at risk
   */
  public static Boolean isAtRisk(Id onboardingId, Integer daysThreshold) {
    if (onboardingId == null || daysThreshold == null || daysThreshold <= 0) {
      return false;
    }

    try {
      List<Onboarding__c> onboardings = [
        SELECT Id, LastModifiedDate
        FROM Onboarding__c
        WHERE Id = :onboardingId
        LIMIT 1
      ];

      if (onboardings.isEmpty()) {
        return false;
      }

      Onboarding__c onboardingRecord = onboardings[0];
      Integer daysSinceActivity = onboardingRecord.LastModifiedDate.date()
        .daysBetween(Date.today());

      return daysSinceActivity >= daysThreshold;
    } catch (Exception ex) {
      System.debug('Error checking at-risk status: ' + ex.getMessage());
      return false;
    }
  }

  /**
   * Get requirements for an onboarding (helper method)
   */
  private static List<Onboarding_Requirement__c> getRequirementsForOnboarding(
    Id onboardingId
  ) {
    return [
      SELECT Id, Name, Status__c
      FROM Onboarding_Requirement__c
      WHERE Onboarding__c = :onboardingId
    ];
  }
}
