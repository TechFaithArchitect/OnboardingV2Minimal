public class RequireParentVersionOnActivationRule implements OnboardingAppValidationRule {
    public void validate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Vendor_Program_Recipient_Group__c> newList = (List<Vendor_Program_Recipient_Group__c>) newRecords;

        Set<Id> programIds = new Set<Id>();
        for (Vendor_Program_Recipient_Group__c recipientGroupAssignment : newList) {
            if (recipientGroupAssignment.Vendor_Program__c != null) {
                programIds.add(recipientGroupAssignment.Vendor_Program__c);
            }
        }

        Map<Id, Integer> existingCounts = new Map<Id, Integer>();
        for (AggregateResult aggregateResult : [
            SELECT Vendor_Program__c programId, COUNT(Id) cnt
            FROM Vendor_Program_Recipient_Group__c
            WHERE Vendor_Program__c IN :programIds
            GROUP BY Vendor_Program__c
        ]) {
            existingCounts.put((Id) aggregateResult.get('programId'), (Integer) aggregateResult.get('cnt'));
        }

        for (Vendor_Program_Recipient_Group__c recipientGroupAssignment : newList) {
            Boolean needsLink = recipientGroupAssignment.Status__c != 'Draft' && recipientGroupAssignment.Parent_Version__c == null;
            Integer existingCount = existingCounts.get(recipientGroupAssignment.Vendor_Program__c);

            if (needsLink && existingCount != null && existingCount > 0) {
                recipientGroupAssignment.addError('Non-draft versions must reference a parent version.');
            }
        }
    }
}