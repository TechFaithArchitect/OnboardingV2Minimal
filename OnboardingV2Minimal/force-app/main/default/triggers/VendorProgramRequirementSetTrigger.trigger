trigger VendorProgramRequirementSetTrigger on Vendor_Program_Requirement_Set__c (
    after insert, after update, after delete, after undelete
) {
    if (Trigger.isAfter) {
        List<Vendor_Program_Requirement_Set__c> junctions = Trigger.isDelete 
            ? Trigger.old 
            : Trigger.new;
        RequirementSetTriggerHandler.updateDisplayLabelsFromJunction(junctions, Trigger.oldMap);
    }
}