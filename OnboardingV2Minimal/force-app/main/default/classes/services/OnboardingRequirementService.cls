public with sharing class OnboardingRequirementService {
  private static final String DUE_DATE_FIELD = 'Due_Date__c';
  private static final String DUE_DATE_REASON_FIELD = 'Due_Date_Override_Reason__c';

  public static void updateDueDateUserMode(
    List<Id> requirementIds,
    Date newDueDate,
    String reason
  ) {
    ValidationHelper.requireNotEmpty(requirementIds, 'Requirement IDs');
    ValidationHelper.requireNotNull(newDueDate, 'Due Date');
    ValidationHelper.requireNotBlank(reason, 'Reason');

    if (
      !FLSCheckUtil.isUpdateable(
        Onboarding_Requirement__c.SObjectType,
        DUE_DATE_FIELD
      )
    ) {
      throw new AuraHandledException(
        'You do not have permission to update requirement due dates.'
      );
    }
    if (
      !FLSCheckUtil.isUpdateable(
        Onboarding_Requirement__c.SObjectType,
        DUE_DATE_REASON_FIELD
      )
    ) {
      throw new AuraHandledException(
        'You do not have permission to update due date override reason.'
      );
    }

    List<Onboarding_Requirement__c> requirements = [
      SELECT Id, Due_Date__c, Due_Date_Override_Reason__c
      FROM Onboarding_Requirement__c
      WHERE Id IN :requirementIds
    ];

    if (requirements.isEmpty()) {
      return;
    }

    for (Onboarding_Requirement__c requirement : requirements) {
      requirement.Due_Date__c = newDueDate;
      requirement.Due_Date_Override_Reason__c = reason;
    }

    update requirements;
  }
}
