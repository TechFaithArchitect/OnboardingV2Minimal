public class NoDuplicateRecipientGroupAssignmentRule implements OnboardingAppValidationRule {

    public void validate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Vendor_Program_Recipient_Group__c> recipientGroupAssignmentRecords = (List<Vendor_Program_Recipient_Group__c>) newList;
        Map<Id, Vendor_Program_Recipient_Group__c> oldRecipientGroupAssignments = (Map<Id, Vendor_Program_Recipient_Group__c>) oldMap;

        Set<Id> programIds = new Set<Id>();
        Set<Id> groupIds = new Set<Id>();
        Map<String, Id> keyToExisting = new Map<String, Id>();
        Set<String> seenKeys = new Set<String>();

        for (Vendor_Program_Recipient_Group__c recipientGroupAssignment : recipientGroupAssignmentRecords) {
            if (recipientGroupAssignment.Vendor_Program__c != null && recipientGroupAssignment.Recipient_Group__c != null) {
                programIds.add(recipientGroupAssignment.Vendor_Program__c);
                groupIds.add(recipientGroupAssignment.Recipient_Group__c);
            }
        }

        if (!programIds.isEmpty() && !groupIds.isEmpty()) {
            for (Vendor_Program_Recipient_Group__c existingAssignment : [
                SELECT Id, Vendor_Program__c, Recipient_Group__c
                FROM Vendor_Program_Recipient_Group__c
                WHERE Vendor_Program__c IN :programIds
                AND Recipient_Group__c IN :groupIds
                AND (Is_Active__c = true OR Status__c = 'Active')
            ]) {
                String assignmentKey = existingAssignment.Vendor_Program__c + ':' + existingAssignment.Recipient_Group__c;
                keyToExisting.put(assignmentKey, existingAssignment.Id);
            }
        }

        for (Vendor_Program_Recipient_Group__c recipientGroupAssignment : recipientGroupAssignmentRecords) {
            if (recipientGroupAssignment.Vendor_Program__c == null || recipientGroupAssignment.Recipient_Group__c == null) continue;

            String assignmentKey = recipientGroupAssignment.Vendor_Program__c + ':' + recipientGroupAssignment.Recipient_Group__c;
            Id existingId = keyToExisting.get(assignmentKey);

            Boolean isChanged = oldRecipientGroupAssignments == null || 
                oldRecipientGroupAssignments.get(recipientGroupAssignment.Id) == null || 
                oldRecipientGroupAssignments.get(recipientGroupAssignment.Id).Vendor_Program__c != recipientGroupAssignment.Vendor_Program__c || 
                oldRecipientGroupAssignments.get(recipientGroupAssignment.Id).Recipient_Group__c != recipientGroupAssignment.Recipient_Group__c;

            if (seenKeys.contains(assignmentKey)) {
                recipientGroupAssignment.addError('This Vendor Program already has this Recipient Group assigned (same transaction).');
            } else if (existingId != null && (recipientGroupAssignment.Id == null || recipientGroupAssignment.Id != existingId) && isChanged) {
                recipientGroupAssignment.addError('This Vendor Program already has this Recipient Group assigned.');
            }

            seenKeys.add(assignmentKey);
        }
    }
}