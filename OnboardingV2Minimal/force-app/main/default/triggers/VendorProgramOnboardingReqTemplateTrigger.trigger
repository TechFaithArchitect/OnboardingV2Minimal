trigger VendorProgramOnboardingReqTemplateTrigger on Vendor_Program_Onboarding_Req_Template__c (
    before insert, before update, after insert
) {
    if (Trigger.isBefore) {
        VersioningTriggerHandler.run(Trigger.new, Trigger.oldMap, 'Vendor_Program_Onboarding_Req_Template__c');
        RequirementTemplateTriggerHandler.run(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        VersioningTriggerHandler.afterInsert(Trigger.new, 'Vendor_Program_Onboarding_Req_Template__c');
        RequirementTemplateTriggerHandler.afterInsert(Trigger.new);
    }
}