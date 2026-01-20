trigger OnboardingFollowUpTrigger on Onboarding__c (after insert, after update) {
    OnboardingFollowUpTriggerHandler.handleAfter(Trigger.new, Trigger.oldMap);
}