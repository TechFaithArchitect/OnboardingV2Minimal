trigger VendorProgramRecipientGroupTrigger on Vendor_Program_Recipient_Group__c (
    before insert, before update
) {
    if (Trigger.isBefore) {
        OnboardingAppRuleEngineHandler.apply(
            'Vendor_Program_Recipient_Group__c',
            (List<SObject>) Trigger.new,
            (Map<Id, SObject>) Trigger.oldMap
        );
    }
}