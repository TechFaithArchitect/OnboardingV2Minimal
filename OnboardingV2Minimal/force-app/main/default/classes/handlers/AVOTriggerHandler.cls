/**
 * Lifecycle guardrails for Account_Vendor_Program_Onboarding__c.
 */
public with sharing class AVOTriggerHandler {

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
            Account_Vendor_Program_Onboarding__c oldAvo = oldMap.get(avo.Id);
            Boolean statusChanged = oldAvo == null ? false : oldAvo.Status__c != avo.Status__c;
            if (!statusChanged) {
                continue;
            }
            if (avo.Status__c == 'Complete') {
                if (avo.Onboarding__c != null) {
                    onboardingIdsNeedingCheck.add(avo.Onboarding__c);
                    toValidate.put(avo.Id, avo);
                }
            }
            if (avo.Status__c == 'Closed Lost' && String.isBlank(avo.Reason_for_Return__c)) {
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
              AND (Status__c != 'Complete' OR Status__c = null)
            GROUP BY Onboarding__c
        ]) {
            openRequirementCountByOnboarding.put((Id)aggregateResult.get('onboardingId'), (Integer)aggregateResult.get('openCount'));
        }

        for (Account_Vendor_Program_Onboarding__c avo : toValidate.values()) {
            Integer openCount = openRequirementCountByOnboarding.get(avo.Onboarding__c);
            if (openCount != null && openCount > 0) {
                avo.addError('Cannot mark Complete while there are open requirements (' + openCount + ').');
            }
        }
    }
}