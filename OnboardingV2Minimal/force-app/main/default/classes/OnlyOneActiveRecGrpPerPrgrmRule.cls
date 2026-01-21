public class OnlyOneActiveRecGrpPerPrgrmRule implements OnboardingAppValidationRule {
    public void validate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Vendor_Program_Recipient_Group__c> newList = (List<Vendor_Program_Recipient_Group__c>) newRecords;

        Set<Id> programIds = new Set<Id>();
        Set<Id> newIds = new Set<Id>();

        for (Vendor_Program_Recipient_Group__c recipientGroupAssignment : newList) {
            if (recipientGroupAssignment.Id != null) {
                newIds.add(recipientGroupAssignment.Id);
            }
            if (recipientGroupAssignment.Vendor_Program__c != null) {
                programIds.add(recipientGroupAssignment.Vendor_Program__c);
            }
        }

        Map<Id, Integer> activeCountByProgram = new Map<Id, Integer>();
        if (!programIds.isEmpty()) {
            List<Vendor_Program_Recipient_Group__c> existingActive;
            if (newIds.isEmpty()) {
                existingActive = [
                    SELECT Id, Vendor_Program__c
                    FROM Vendor_Program_Recipient_Group__c
                    WHERE (Is_Active__c = true OR Status__c = 'Active')
                    AND Vendor_Program__c IN :programIds
                ];
            } else {
                existingActive = [
                    SELECT Id, Vendor_Program__c
                    FROM Vendor_Program_Recipient_Group__c
                    WHERE (Is_Active__c = true OR Status__c = 'Active')
                    AND Vendor_Program__c IN :programIds
                    AND Id NOT IN :newIds
                ];
            }

            for (Vendor_Program_Recipient_Group__c existingAssignment : existingActive) {
                Integer count = activeCountByProgram.containsKey(existingAssignment.Vendor_Program__c)
                    ? activeCountByProgram.get(existingAssignment.Vendor_Program__c)
                    : 0;
                activeCountByProgram.put(existingAssignment.Vendor_Program__c, count + 1);
            }
        }

        Map<Id, Integer> seenActiveByProgram = new Map<Id, Integer>();
        for (Vendor_Program_Recipient_Group__c recipientGroupAssignment : newList) {
            if (recipientGroupAssignment.Vendor_Program__c == null) {
                continue;
            }

            Boolean willBeActive = recipientGroupAssignment.Is_Active__c == true || recipientGroupAssignment.Status__c == 'Active';
            if (!willBeActive) {
                continue;
            }

            Id programId = recipientGroupAssignment.Vendor_Program__c;
            Integer existingCount = activeCountByProgram.containsKey(programId)
                ? activeCountByProgram.get(programId)
                : 0;
            Integer seenCount = seenActiveByProgram.containsKey(programId)
                ? seenActiveByProgram.get(programId)
                : 0;

            if (existingCount + seenCount >= 1) {
                recipientGroupAssignment.addError('Only one active Recipient Group is allowed per Vendor Program.');
            }

            seenActiveByProgram.put(programId, seenCount + 1);
        }
    }
}