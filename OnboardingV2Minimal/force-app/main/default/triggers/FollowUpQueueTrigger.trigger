/**
 * Trigger for Follow_Up_Queue__c
 * Handles retry logic for failed follow-ups
 */
trigger FollowUpQueueTrigger on Follow_Up_Queue__c (after update) {
    FollowUpQueueTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}