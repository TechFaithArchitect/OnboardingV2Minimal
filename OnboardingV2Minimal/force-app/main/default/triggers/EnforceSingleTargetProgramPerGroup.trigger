trigger EnforceSingleTargetProgramPerGroup on Vendor_Program_Group__c(
  before insert,
  before update
) {
  // Thin trigger delegating to handler for bulkified logic
  EnforceSingleTargetProgramPerGroupTriggerHandler.beforeInsertOrUpdate(
    Trigger.new,
    Trigger.oldMap
  );
}
