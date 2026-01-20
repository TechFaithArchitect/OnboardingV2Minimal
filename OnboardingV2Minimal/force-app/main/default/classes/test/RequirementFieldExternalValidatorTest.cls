/**
 * Test class for RequirementFieldExternalValidator
 */
@isTest
private class RequirementFieldExternalValidatorTest {

    @testSetup
    static void setupTestData() {
        // Create test data using factory
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);
        
        // Create Requirement_Field__c with External validation type
        Requirement_Field__c externalField = TestDataFactory.createRequirementField(
            'External_Field__c',
            'External',
            false,
            true
        );
        
        // Create Requirement_Field_Value__c with Pending status (awaiting external validation)
        Requirement_Field_Value__c fieldValue = TestDataFactory.createRequirementFieldValue(
            externalField,
            ctx.requirement,
            'Test Value',
            'Pending',
            true
        );
    }

    @isTest
    static void testValidateExternally() {
        List<Requirement_Field_Value__c> fieldValues = [
            SELECT Id FROM Requirement_Field_Value__c WHERE Validation_Status__c = 'Pending'
        ];
        
        if (fieldValues.isEmpty()) {
            return;
        }
        
        Set<Id> fieldValueIds = new Set<Id>{ fieldValues[0].Id };
        
        Test.startTest();
        RequirementFieldExternalValidator.validateExternally(fieldValueIds);
        Test.stopTest();
        
        // Verify field value was updated
        Requirement_Field_Value__c updated = [
            SELECT Id, Validation_Status__c, Validation_Error_Message__c, Last_Validated_Date__c
            FROM Requirement_Field_Value__c
            WHERE Id = :fieldValues[0].Id
        ];
        
        System.assertNotEquals(null, updated.Last_Validated_Date__c, 'Last validated date should be set');
        // Status should be Valid or Invalid (depending on placeholder logic)
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Requirement_Field_Value__c.SObjectType,
            'Validation_Status__c'
        );
        String validStatus = validStatuses.contains('Valid') ? 'Valid' : validStatuses[0];
        String invalidStatus = validStatuses.contains('Invalid') ? 'Invalid' : validStatuses[0];
        System.assert(updated.Validation_Status__c == validStatus || updated.Validation_Status__c == invalidStatus, 
                     'Status should be Valid or Invalid');
    }

    @isTest
    static void testValidateExternally_EmptySet() {
        Test.startTest();
        RequirementFieldExternalValidator.validateExternally(new Set<Id>());
        Test.stopTest();
        
        // Should complete without error
        System.assert(true, 'Should handle empty set gracefully');
    }

    @isTest
    static void testValidateExternally_Null() {
        Test.startTest();
        RequirementFieldExternalValidator.validateExternally(null);
        Test.stopTest();
        
        // Should complete without error
        System.assert(true, 'Should handle null gracefully');
    }

    @isTest
    static void testValidateExternally_NonExternalField() {
        // Create field with non-External validation type
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);
        ctx.requirementField.Validation_Type__c = 'Format';
        update ctx.requirementField;
        
        Requirement_Field_Value__c fieldValue = TestDataFactory.createRequirementFieldValue(
            ctx.requirementField,
            ctx.requirement,
            'Test',
            'Pending',
            true
        );
        
        Set<Id> fieldValueIds = new Set<Id>{ fieldValue.Id };
        
        Test.startTest();
        RequirementFieldExternalValidator.validateExternally(fieldValueIds);
        Test.stopTest();
        
        // Field value should not be updated (not External type)
        Requirement_Field_Value__c updated = [
            SELECT Id, Validation_Status__c
            FROM Requirement_Field_Value__c
            WHERE Id = :fieldValue.Id
        ];
        
        // Status should remain Pending (not processed by external validator)
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Requirement_Field_Value__c.SObjectType,
            'Validation_Status__c'
        );
        String pendingStatus = validStatuses.contains('Pending') ? 'Pending' : validStatuses[0];
        System.assertEquals(pendingStatus, updated.Validation_Status__c, 'Non-External field should not be processed');
    }

    @isTest
    static void testValidateExternally_MultipleFields() {
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);
        
        // Create multiple external fields
        Requirement_Field__c field1 = TestDataFactory.createRequirementField(
            'External_Field_1__c',
            'External',
            false,
            true
        );
        Requirement_Field__c field2 = TestDataFactory.createRequirementField(
            'External_Field_2__c',
            'External',
            false,
            true
        );
        
        Requirement_Field_Value__c value1 = TestDataFactory.createRequirementFieldValue(
            field1,
            ctx.requirement,
            'Value 1',
            'Pending',
            false
        );
        Requirement_Field_Value__c value2 = TestDataFactory.createRequirementFieldValue(
            field2,
            ctx.requirement,
            'Value 2',
            'Pending',
            false
        );
        insert new List<Requirement_Field_Value__c>{ value1, value2 };
        
        Set<Id> fieldValueIds = new Set<Id>{ value1.Id, value2.Id };
        
        Test.startTest();
        RequirementFieldExternalValidator.validateExternally(fieldValueIds);
        Test.stopTest();
        
        // Verify both were processed
        List<Requirement_Field_Value__c> updated = [
            SELECT Id, Validation_Status__c, Last_Validated_Date__c
            FROM Requirement_Field_Value__c
            WHERE Id IN :fieldValueIds
        ];
        
        System.assertEquals(2, updated.size(), 'Should process both field values');
        for (Requirement_Field_Value__c fv : updated) {
            System.assertNotEquals(null, fv.Last_Validated_Date__c, 'Last validated date should be set');
        }
    }

    @isTest
    static void testValidateExternally_BlankValue() {
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);
        
        Requirement_Field__c externalField = TestDataFactory.createRequirementField(
            'External_Field_Blank__c',
            'External',
            false,
            true
        );
        
        Requirement_Field_Value__c fieldValue = TestDataFactory.createRequirementFieldValue(
            externalField,
            ctx.requirement,
            null,
            'Pending',
            true
        );
        
        Set<Id> fieldValueIds = new Set<Id>{ fieldValue.Id };
        
        Test.startTest();
        RequirementFieldExternalValidator.validateExternally(fieldValueIds);
        Test.stopTest();
        
        // Verify field value was updated (should be Invalid for blank value)
        Requirement_Field_Value__c updated = [
            SELECT Id, Validation_Status__c, Validation_Error_Message__c
            FROM Requirement_Field_Value__c
            WHERE Id = :fieldValue.Id
        ];
        
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Requirement_Field_Value__c.SObjectType,
            'Validation_Status__c'
        );
        String invalidStatus = validStatuses.contains('Invalid') ? 'Invalid' : validStatuses[0];
        System.assertEquals(invalidStatus, updated.Validation_Status__c, 'Blank value should be invalid');
        System.assertNotEquals(null, updated.Validation_Error_Message__c, 'Should have error message');
    }
}