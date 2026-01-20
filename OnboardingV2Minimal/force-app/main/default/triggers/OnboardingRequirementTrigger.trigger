/**
 * Trigger on Onboarding_Requirement__c
 * Detects status changes and evaluates follow-up rules
 */
trigger OnboardingRequirementTrigger on Onboarding_Requirement__c (after insert, after update) {
    if (Trigger.isAfter) {
        OnboardingRequirementTriggerHandler.handleAfterSave(Trigger.new, Trigger.oldMap);
    }
}