public class RecipientAndProgramMustBeActiveRule implements OnboardingAppValidationRule {
    public void validate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Vendor_Program_Recipient_Group__c> newList = (List<Vendor_Program_Recipient_Group__c>) newRecords;

        Set<Id> groupIds = new Set<Id>();
        Set<Id> programIds = new Set<Id>();

        for (Vendor_Program_Recipient_Group__c recipientGroupAssignment : newList) {
            if (recipientGroupAssignment.Is_Active__c) {
                if (recipientGroupAssignment.Recipient_Group__c != null) groupIds.add(recipientGroupAssignment.Recipient_Group__c);
                if (recipientGroupAssignment.Vendor_Program__c != null) programIds.add(recipientGroupAssignment.Vendor_Program__c);
            }
        }

        Map<Id, Recipient_Group__c> recipientGroups = new Map<Id, Recipient_Group__c>(
            [SELECT Id, Is_Active__c FROM Recipient_Group__c WHERE Id IN :groupIds]
        );
        Map<Id, Vendor_Customization__c> programs = new Map<Id, Vendor_Customization__c>(
            [SELECT Id, Active__c FROM Vendor_Customization__c WHERE Id IN :programIds]
        );

        for (Vendor_Program_Recipient_Group__c recipientGroupAssignment : newList) {
            if (!recipientGroupAssignment.Is_Active__c) continue;

            if (recipientGroupAssignment.Recipient_Group__c != null) {
                Recipient_Group__c recipientGroup = recipientGroups.get(recipientGroupAssignment.Recipient_Group__c);
                if (recipientGroup == null || !recipientGroup.Is_Active__c) {
                    recipientGroupAssignment.addError('Recipient Group must be active before this record can be activated.');
                }
            }
            if (recipientGroupAssignment.Vendor_Program__c != null) {
                Vendor_Customization__c vendorProgram = programs.get(recipientGroupAssignment.Vendor_Program__c);
                if (vendorProgram == null || !vendorProgram.Active__c) {
                    recipientGroupAssignment.addError('Vendor Program must be active before this record can be activated.');
                }
            }
        }
    }
}