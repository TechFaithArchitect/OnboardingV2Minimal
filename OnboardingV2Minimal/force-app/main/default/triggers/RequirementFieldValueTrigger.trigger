/**
 * Trigger on Requirement_Field_Value__c
 * Automatically enqueues async validation for Cross-Field and External validation types
 */
trigger RequirementFieldValueTrigger on Requirement_Field_Value__c (after insert, after update) {
    if (Trigger.isAfter) {
        RequirementFieldValueTriggerHandler.handleAfterSave(Trigger.new, Trigger.oldMap);
    }
}