@isTest
private class RequirementFieldValueControllerTest {

    @isTest
    static void saveFieldValue_insertsAndUpdatesStatus() {
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);

        Test.startTest();
        RequirementFieldValueController.SaveResult result = RequirementFieldValueController.saveFieldValue(
            null,
            ctx.requirementField.Id,
            ctx.requirement.Id,
            ctx.requirementField.Field_API_Name__c,
            'Test Value',
            false
        );
        Test.stopTest();

        System.assertEquals(true, result.success, 'Save should succeed');
        System.assertNotEquals(null, result.id, 'Field value Id should be returned');

        Requirement_Field_Value__c persisted = [
            SELECT Value__c, Encrypted_Value__c, Requirement_Field__c
            FROM Requirement_Field_Value__c
            WHERE Id = :result.id
        ];
        System.assertEquals('Test Value', persisted.Value__c, 'Plain value should be stored');
        System.assertEquals(null, persisted.Encrypted_Value__c, 'Encrypted field should remain empty');

        Onboarding_Requirement__c requirement = [
            SELECT Status__c
            FROM Onboarding_Requirement__c
            WHERE Id = :ctx.requirement.Id
        ];
        System.assertNotEquals(null, requirement.Status__c, 'Status should be set after save');
    }

    @isTest
    static void saveFieldValue_updatesExistingAndEncryptedPath() {
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);

        RequirementFieldValueController.SaveResult initial = RequirementFieldValueController.saveFieldValue(
            null,
            ctx.requirementField.Id,
            ctx.requirement.Id,
            ctx.requirementField.Field_API_Name__c,
            'Initial',
            false
        );

        Test.startTest();
        RequirementFieldValueController.SaveResult updated = RequirementFieldValueController.saveFieldValue(
            initial.id,
            ctx.requirementField.Id,
            ctx.requirement.Id,
            ctx.requirementField.Field_API_Name__c,
            'Encrypted',
            true
        );
        Test.stopTest();

        System.assertEquals(true, updated.success, 'Update should succeed');

        Requirement_Field_Value__c persisted = [
            SELECT Value__c, Encrypted_Value__c
            FROM Requirement_Field_Value__c
            WHERE Id = :updated.id
        ];
        System.assertEquals(null, persisted.Value__c, 'Plain value should be cleared when encrypted path used');
        System.assertEquals('Encrypted', persisted.Encrypted_Value__c, 'Encrypted value should be stored');
    }
}