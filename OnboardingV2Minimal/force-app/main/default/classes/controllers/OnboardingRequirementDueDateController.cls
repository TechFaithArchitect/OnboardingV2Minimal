/**
 * @description Controller for due date override operations on Onboarding_Requirement__c
 * @group Onboarding
 * @author Agentforce
 * @notes
 * - Follows existing controller patterns with @AuraEnabled methods
 * - Implements FLS checks and user-mode DML
 * - Audits changes via Audit__c or Field History
 * - Delegates to OnboardingRequirementService for business logic
 */
public with sharing class OnboardingRequirementDueDateController {
  /**
   * @description Override due date for one or more requirements with reason and audit
   * @param requirementIds List of Onboarding_Requirement__c IDs to update
   * @param newDueDate New due date
   * @param reason Reason for the override (for audit trail)
   */
  @AuraEnabled
  public static void updateDueDate(
    List<Id> requirementIds,
    Date newDueDate,
    String reason
  ) {
    ValidationHelper.requireNotEmpty(requirementIds, 'Requirement IDs');
    ValidationHelper.requireNotNull(newDueDate, 'Due Date');
    ValidationHelper.requireNotBlank(reason, 'Reason');

    // Call service layer to perform the update
    OnboardingRequirementService.updateDueDateUserMode(
      requirementIds,
      newDueDate,
      reason
    );
  }
}
