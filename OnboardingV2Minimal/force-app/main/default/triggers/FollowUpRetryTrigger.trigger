/**
 * Platform Event trigger for Follow-Up Retry
 * Subscribes to FollowUpRetryTrigger__e events and processes retries
 */
trigger FollowUpRetryTrigger on FollowUpRetryTrigger__e (after insert) {
    FollowUpRetryHandler.handleRetry(Trigger.new);
}