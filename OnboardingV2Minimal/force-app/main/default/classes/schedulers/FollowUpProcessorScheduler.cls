global with sharing class FollowUpProcessorScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        FollowUpProcessor.enqueue();
    }
}