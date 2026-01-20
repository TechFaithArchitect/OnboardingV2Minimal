@isTest
private class RequirementFieldValidationActionTest {

    @isTest
    static void validatesAndReturnsStatuses() {
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);
        
        Requirement_Field__c reqField = TestDataFactory.createRequirementField(
            'Action_Field__c',
            'None',
            true,
            true
        );

        Requirement_Field_Value__c fv = TestDataFactory.createRequirementFieldValue(
            reqField,
            ctx.requirement,
            true
        );

        RequirementFieldValidationAction.Request req = new RequirementFieldValidationAction.Request();
        req.requirementFieldValueId = fv.Id;

        Test.startTest();
        List<RequirementFieldValidationAction.Response> responses =
            RequirementFieldValidationAction.validate(new List<RequirementFieldValidationAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(fv.Id, responses[0].requirementFieldValueId);
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Requirement_Field_Value__c.SObjectType,
            'Validation_Status__c'
        );
        String needsCorrectionStatus = validStatuses.contains('Needs Correction') ? 'Needs Correction' : validStatuses[0];
        System.assertEquals(needsCorrectionStatus, responses[0].status, 'Required blank should need correction');
        System.assertNotEquals(null, responses[0].message, 'Should have a validation message');
    }
}