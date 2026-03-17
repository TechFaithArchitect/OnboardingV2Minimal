List<String> requirementStatuses = new List<String>();
for (Schema.PicklistEntry entry : Onboarding_Requirement__c.Status__c.getDescribe().getPicklistValues()) {
    requirementStatuses.add(entry.getValue());
}
System.debug('REQ=' + String.join(requirementStatuses, ','));
