trigger OnboardingRequirementSetTrigger on Onboarding_Requirement_Set__c (
    before insert, before update, after insert, after update
) {
    if (Trigger.isBefore) {
        RequirementSetTriggerHandler.run(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter) {
        RequirementSetTriggerHandler.afterInsert(Trigger.new);
        RequirementSetTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}