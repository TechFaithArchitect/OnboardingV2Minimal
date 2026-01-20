/**
 * Handler for Onboarding_Requirement__c trigger
 * Evaluates follow-up rules when requirement status changes
 */
public with sharing class OnboardingRequirementTriggerHandler {
  /**
   * Handle after insert and after update
   * Evaluates follow-up rules for requirements that need follow-ups
   */
  public static void handleAfterSave(
    List<Onboarding_Requirement__c> newRecords,
    Map<Id, Onboarding_Requirement__c> oldMap
  ) {
    Set<Id> requirementIdsToEvaluate = new Set<Id>();

    // Collect requirement IDs that need evaluation
    for (Onboarding_Requirement__c newRecord : newRecords) {
      Onboarding_Requirement__c oldRecord = oldMap != null
        ? oldMap.get(newRecord.Id)
        : null;

      // Evaluate if:
      // 1. New record (insert)
      // 2. Status changed (update)
      // 3. Status is not Complete/Approved (still needs follow-up)
      Boolean shouldEvaluate = false;

      if (oldRecord == null) {
        // New record - evaluate if status warrants follow-up
        shouldEvaluate = shouldEvaluateForStatus(newRecord.Status__c);
      } else {
        // Existing record - evaluate if status changed to a follow-up-worthy status
        Boolean statusChanged = newRecord.Status__c != oldRecord.Status__c;
        shouldEvaluate =
          statusChanged && shouldEvaluateForStatus(newRecord.Status__c);
      }

      if (shouldEvaluate) {
        requirementIdsToEvaluate.add(newRecord.Id);
      }
    }

    // Evaluate follow-up rules for eligible requirements
    if (!requirementIdsToEvaluate.isEmpty()) {
      // Use future method to avoid mixed DML issues
      evaluateFollowUps(requirementIdsToEvaluate);
    }
  }

  /**
   * Check if status warrants follow-up evaluation
   */
  private static Boolean shouldEvaluateForStatus(String status) {
    if (String.isBlank(status)) {
      return false;
    }

    // Evaluate for statuses that might need follow-up
    // Exclude: Complete, Approved, Denied (no follow-up needed)
    Set<String> followUpStatuses = new Set<String>{
      'Not Started',
      'In Process',
      'Incomplete',
      'Draft',
      'Partially_Completed',
      'Pending',
      'Abandoned'
    };

    return followUpStatuses.contains(status);
  }

  /**
   * Future method to evaluate follow-ups
   * Prevents mixed DML issues when called from trigger context
   */
  @future
  private static void evaluateFollowUps(Set<Id> requirementIds) {
    try {
      FollowUpDetectionService.evaluateAndCreateFollowUpsBulk(requirementIds);
    } catch (Exception ex) {
      // Log error but don't throw - follow-up failure shouldn't block requirement updates
      System.debug('Error evaluating follow-ups: ' + ex.getMessage());
      System.debug('Stack trace: ' + ex.getStackTraceString());
    }
  }
}
