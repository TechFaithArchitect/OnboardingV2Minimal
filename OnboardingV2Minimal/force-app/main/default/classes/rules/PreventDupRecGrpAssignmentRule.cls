public class PreventDupRecGrpAssignmentRule implements OnboardingAppValidationRule {
    public void validate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Vendor_Program_Recipient_Group__c> newRecords = 
            (List<Vendor_Program_Recipient_Group__c>) newList;

        Set<Id> programIds = new Set<Id>();
        Set<Id> groupIds = new Set<Id>();
        Map<String, Id> keyToExisting = new Map<String, Id>();
        Set<String> keysSeenThisBatch = new Set<String>();
        List<Vendor_Program_Recipient_Group__c> recordsToCheck = new List<Vendor_Program_Recipient_Group__c>();

        // Extract keys
        for (Vendor_Program_Recipient_Group__c recipientGroupAssignment : newRecords) {
            if (recipientGroupAssignment.Vendor_Program__c != null && recipientGroupAssignment.Recipient_Group__c != null) {
                if (recipientGroupAssignment.Parent_Version__c != null || recipientGroupAssignment.Status__c == 'Draft') {
                    continue;
                }
                programIds.add(recipientGroupAssignment.Vendor_Program__c);
                groupIds.add(recipientGroupAssignment.Recipient_Group__c);
                recordsToCheck.add(recipientGroupAssignment);
            }
        }

        if (recordsToCheck.isEmpty()) {
            return;
        }

        // Fetch existing assignments
        List<Vendor_Program_Recipient_Group__c> existing = [
            SELECT Id, Vendor_Program__c, Recipient_Group__c
            FROM Vendor_Program_Recipient_Group__c
            WHERE Vendor_Program__c IN :programIds
            AND Recipient_Group__c IN :groupIds
            AND (Is_Active__c = true OR Status__c = 'Active')
        ];

        for (Vendor_Program_Recipient_Group__c existingAssignment : existing) {
            String assignmentKey = existingAssignment.Vendor_Program__c + ':' + existingAssignment.Recipient_Group__c;
            keyToExisting.put(assignmentKey, existingAssignment.Id);
        }

        for (Vendor_Program_Recipient_Group__c recipientGroupAssignment : recordsToCheck) {
            if (recipientGroupAssignment.Vendor_Program__c != null && recipientGroupAssignment.Recipient_Group__c != null) {
                String assignmentKey = recipientGroupAssignment.Vendor_Program__c + ':' + recipientGroupAssignment.Recipient_Group__c;
                Id existingId = keyToExisting.get(assignmentKey);

                Boolean isChanged = oldMap == null || 
                    oldMap.get(recipientGroupAssignment.Id) == null || 
                    oldMap.get(recipientGroupAssignment.Id).get('Vendor_Program__c') != recipientGroupAssignment.Vendor_Program__c ||
                    oldMap.get(recipientGroupAssignment.Id).get('Recipient_Group__c') != recipientGroupAssignment.Recipient_Group__c;

                if (keysSeenThisBatch.contains(assignmentKey)) {
                    recipientGroupAssignment.addError('This Vendor Program already has this Recipient Group assigned in this transaction.');
                } else if (existingId != null && (recipientGroupAssignment.Id == null || recipientGroupAssignment.Id != existingId) && isChanged) {
                    recipientGroupAssignment.addError('This Vendor Program already has this Recipient Group assigned.');
                }

                keysSeenThisBatch.add(assignmentKey);
            }
        }
    }
}