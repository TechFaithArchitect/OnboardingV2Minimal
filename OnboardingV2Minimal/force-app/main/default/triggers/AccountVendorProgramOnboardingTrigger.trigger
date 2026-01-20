trigger AccountVendorProgramOnboardingTrigger on Account_Vendor_Program_Onboarding__c (before update) {
    AVOTriggerHandler.handleBeforeUpdate(Trigger.oldMap, Trigger.new);
}