@isTest
public class TestTrainingRequirementFactory {
    public static Training_Requirement__c create(Boolean doInsert, Vendor_Customization__c vendorProgram, Training_System__c trainingSystem) {
        // Get Training_Type__c picklist values
        List<String> trainingTypes = TestDataFactoryUtil.getPicklistValues(
            Training_Requirement__c.SObjectType,
            'Training_Type__c'
        );
        String trainingType = trainingTypes.contains('Internal') ? 'Internal' : trainingTypes[0];
        
        Training_Requirement__c trainingRequirement = new Training_Requirement__c(
            External_Course_Code__c = 'TR-001',
            External_Course_Name__c = 'Test Course',
            Training_Code__c = 'INT-001',
            Is_Required__c = true,
            Sequence__c = 1,
            Training_System__c = trainingSystem.Id,
            Vendor_Customization__c = vendorProgram.Id,
            Training_Type__c = trainingType
        );
        
        // If Training_Type__c is not "Internal", we need Required_Credential__c
        // For test purposes, set to Internal to avoid validation error
        // If external is needed, create Required_Credential__c separately
        if (doInsert) insert trainingRequirement;
        return trainingRequirement;
    }
}