trigger VendorProgramRequirementGroupTrigger on Vendor_Program_Requirement_Group__c (before insert) {
    if (Trigger.isBefore) {
        VendorProgramReqGroupTriggerHandler.handleVersioning(Trigger.new, Trigger.oldMap);
    }
}