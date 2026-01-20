@isTest
private class RequirementFieldValidationServiceTest {

    @isTest
    static void requiredFieldBlankSetsNeedsCorrection() {
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);
        
        Requirement_Field__c reqField = TestDataFactory.createRequirementField(
            'Test_Field__c',
            'None',
            true,
            true
        );
        Requirement_Field_Value__c fieldValue = TestDataFactory.createRequirementFieldValue(
            reqField,
            ctx.requirement,
            false
        );

        RequirementFieldValidationService.ValidationResult result =
            RequirementFieldValidationService.evaluateFieldValue(fieldValue, reqField, new Map<String, Requirement_Field_Validation_Rule__mdt>());

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Requirement_Field_Value__c.SObjectType,
            'Validation_Status__c'
        );
        String needsCorrectionStatus = validStatuses.contains('Needs Correction') ? 'Needs Correction' : validStatuses[0];
        System.assertEquals(needsCorrectionStatus, result.status, 'Required blank field should request correction');
        System.assertEquals('This field is required.', result.message, 'Should return required message');
    }

    @isTest
    static void formatValidationPassesAndFails() {
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);
        
        Requirement_Field__c reqField = TestDataFactory.createRequirementField(
            'Number_Field__c',
            'Format',
            false,
            true
        );

        Requirement_Field_Validation_Rule__mdt rule = new Requirement_Field_Validation_Rule__mdt(
            DeveloperName = 'Number_Field_Format',
            MasterLabel = 'Number Field Format',
            Requirement_Field__c = 'Number_Field__c',
            Validation_Type__c = 'Format',
            Validation_Expression__c = '^\\d+$',
            Error_Message__c = 'Numbers only',
            Is_Active__c = true
        );
        Map<String, Requirement_Field_Validation_Rule__mdt> rulesByApi = new Map<String, Requirement_Field_Validation_Rule__mdt>{
            'Number_Field__c' => rule
        };

        Requirement_Field_Value__c validValue = TestDataFactory.createRequirementFieldValue(
            reqField,
            ctx.requirement,
            '12345',
            false
        );
        Requirement_Field_Value__c invalidValue = TestDataFactory.createRequirementFieldValue(
            reqField,
            ctx.requirement,
            '12AB',
            false
        );

        RequirementFieldValidationService.ValidationResult validResult =
            RequirementFieldValidationService.evaluateFieldValue(validValue, reqField, rulesByApi);
        RequirementFieldValidationService.ValidationResult invalidResult =
            RequirementFieldValidationService.evaluateFieldValue(invalidValue, reqField, rulesByApi);

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Requirement_Field_Value__c.SObjectType,
            'Validation_Status__c'
        );
        String validStatus = validStatuses.contains('Valid') ? 'Valid' : validStatuses[0];
        String invalidStatus = validStatuses.contains('Invalid') ? 'Invalid' : validStatuses[0];
        System.assertEquals(validStatus, validResult.status, 'Digits should pass format validation');
        System.assertEquals(invalidStatus, invalidResult.status, 'Non-digits should fail format validation');
        System.assertEquals('Numbers only', invalidResult.message, 'Should surface rule error message');
    }

    @isTest
    static void crossFieldRemainsPending() {
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);
        
        Requirement_Field__c reqField = TestDataFactory.createRequirementField(
            'CrossField__c',
            'Cross-Field',
            false,
            true
        );
        Requirement_Field_Value__c fieldValue = TestDataFactory.createRequirementFieldValue(
            reqField,
            ctx.requirement,
            'anything',
            false
        );

        RequirementFieldValidationService.ValidationResult result =
            RequirementFieldValidationService.evaluateFieldValue(fieldValue, reqField, new Map<String, Requirement_Field_Validation_Rule__mdt>());

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Requirement_Field_Value__c.SObjectType,
            'Validation_Status__c'
        );
        String pendingStatus = validStatuses.contains('Pending') ? 'Pending' : validStatuses[0];
        System.assertEquals(pendingStatus, result.status, 'Cross-field validations should remain pending for async handling');
    }
}