public with sharing class AVOTriggerHandler {
    private static final Set<String> COMPLETE_STATUSES = new Set<String>{ 'Complete', 'Completed' };

    public static void handleBeforeUpdate(
        Map<Id, Account_Vendor_Program_Onboarding__c> oldMap,
        List<Account_Vendor_Program_Onboarding__c> newRecords
    ) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Set<Id> onboardingIdsNeedingCheck = new Set<Id>();
        Map<Id, Account_Vendor_Program_Onboarding__c> toValidate = new Map<Id, Account_Vendor_Program_Onboarding__c>();

        for (Account_Vendor_Program_Onboarding__c avo : newRecords) {
            Account_Vendor_Program_Onboarding__c oldAvo = oldMap == null ? null : oldMap.get(avo.Id);
            Boolean statusChanged = oldAvo == null ? false : oldAvo.Status__c != avo.Status__c;
            if (!statusChanged) {
                continue;
            }

            if (isCompleteStatus(avo.Status__c) && avo.Onboarding__c != null) {
                onboardingIdsNeedingCheck.add(avo.Onboarding__c);
                toValidate.put(avo.Id, avo);
            }

            if (isClosedLostStatus(avo.Status__c) && String.isBlank(avo.Reason_for_Return__c)) {
                avo.addError('Reason for Return is required when setting Status to Closed Lost.');
            }
        }

        if (onboardingIdsNeedingCheck.isEmpty()) {
            return;
        }

        Map<Id, Integer> openRequirementCountByOnboarding = new Map<Id, Integer>();
        for (AggregateResult aggregateResult : [
            SELECT Onboarding__c onboardingId, COUNT(Id) openCount
            FROM Onboarding_Requirement__c
            WHERE Onboarding__c IN :onboardingIdsNeedingCheck
              AND (Status__c = null OR Status__c NOT IN :COMPLETE_STATUSES)
            GROUP BY Onboarding__c
        ]) {
            Integer openCount = Integer.valueOf(String.valueOf(aggregateResult.get('openCount')));
            openRequirementCountByOnboarding.put(
                (Id) aggregateResult.get('onboardingId'),
                openCount
            );
        }

        for (Account_Vendor_Program_Onboarding__c avo : toValidate.values()) {
            Integer openCount = openRequirementCountByOnboarding.get(avo.Onboarding__c);
            if (openCount != null && openCount > 0) {
                avo.addError('Cannot mark Complete while there are open requirements (' + openCount + ').');
            }
        }
    }

    private static Boolean isCompleteStatus(String statusValue) {
        return !String.isBlank(statusValue) && COMPLETE_STATUSES.contains(statusValue);
    }

    private static Boolean isClosedLostStatus(String statusValue) {
        return !String.isBlank(statusValue) && statusValue.trim().toLowerCase() == 'closed lost';
    }
}
