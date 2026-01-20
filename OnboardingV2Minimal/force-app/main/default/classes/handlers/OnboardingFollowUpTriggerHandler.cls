public with sharing class OnboardingFollowUpTriggerHandler {

    private static final Set<String> TARGET_STATUSES = new Set<String>{
        'Incomplete', 'Not Started', 'In Progress', 'Partially_Completed', 'Needs_Correction'
    };

    public static void handleAfter(List<Onboarding__c> newRecords, Map<Id, Onboarding__c> oldMap) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Set<Id> onboardingIds = new Set<Id>();

        for (Onboarding__c onboardingRecord : newRecords) {
            // Only enqueue if status is in target list
            if (onboardingRecord.Onboarding_Status__c != null && TARGET_STATUSES.contains(onboardingRecord.Onboarding_Status__c)) {
                if (Trigger.isInsert) {
                    onboardingIds.add(onboardingRecord.Id);
                } else {
                    Onboarding__c oldOnboardingRecord = oldMap != null ? oldMap.get(onboardingRecord.Id) : null;
                    if (oldOnboardingRecord == null || onboardingRecord.Onboarding_Status__c != oldOnboardingRecord.Onboarding_Status__c) {
                        onboardingIds.add(onboardingRecord.Id);
                    }
                }
            }
        }

        if (!onboardingIds.isEmpty()) {
            FollowUpDetectionService.enqueueFollowUps(onboardingIds);
        }
    }
}