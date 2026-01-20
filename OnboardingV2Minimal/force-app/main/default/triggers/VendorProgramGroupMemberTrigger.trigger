trigger VendorProgramGroupMemberTrigger on Vendor_Program_Group_Member__c (
    before insert, before update
) {
    if (Trigger.isBefore) {
        OnboardingAppRuleEngineHandler.apply(
            'Vendor_Program_Group_Member__c',
            (List<SObject>) Trigger.new,
            (Map<Id, SObject>) Trigger.oldMap
        );
    }
}