public with sharing class EnforceTargetProgramPerGroupHandler {
  public static void beforeInsertOrUpdate(
    List<Vendor_Program_Group__c> newRecords,
    Map<Id, Vendor_Program_Group__c> oldMap
  ) {
    // Placeholder: no-op while target-program enforcement is handled elsewhere.
    if (newRecords == null || newRecords.isEmpty()) {
      return;
    }
  }
}
