@isTest
private class RequirementFieldAsyncValidatorTest {

    @isTest
    static void asyncValidatorMarksValidWhenNotRequired() {
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);
        
        Requirement_Field__c reqField = TestDataFactory.createRequirementField(
            'Async_Field__c',
            'External',
            false,
            true
        );

        Requirement_Field_Value__c fv = TestDataFactory.createRequirementFieldValue(
            reqField,
            ctx.requirement,
            'abc',
            true
        );

        Test.startTest();
        RequirementFieldAsyncValidator.enqueue(new Set<Id>{ fv.Id });
        Test.stopTest();

        Requirement_Field_Value__c updated = [
            SELECT Validation_Status__c, Validation_Error_Message__c, Last_Validated_Date__c
            FROM Requirement_Field_Value__c
            WHERE Id = :fv.Id
        ];

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Requirement_Field_Value__c.SObjectType,
            'Validation_Status__c'
        );
        String pendingStatus = validStatuses.contains('Pending') ? 'Pending' : validStatuses[0];
        System.assertEquals(pendingStatus, updated.Validation_Status__c, 'External validation should remain pending');
        System.assertEquals('Awaiting external validation.', updated.Validation_Error_Message__c, 'Pending should include message');
        System.assertNotEquals(null, updated.Last_Validated_Date__c, 'Should stamp validation time');
    }

    @isTest
    static void asyncValidatorFlagsRequiredBlank() {
        OnboardingTestDataFactory.RequirementContext ctx = OnboardingTestDataFactory.createRequirementContext(true);
        
        Requirement_Field__c reqField = TestDataFactory.createRequirementField(
            'Async_Required_Field__c',
            'Cross-Field',
            true,
            true
        );

        Requirement_Field_Value__c fv = TestDataFactory.createRequirementFieldValue(
            reqField,
            ctx.requirement,
            true
        );

        Test.startTest();
        RequirementFieldAsyncValidator.enqueue(new Set<Id>{ fv.Id });
        Test.stopTest();

        Requirement_Field_Value__c updated = [
            SELECT Validation_Status__c, Validation_Error_Message__c
            FROM Requirement_Field_Value__c
            WHERE Id = :fv.Id
        ];

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Requirement_Field_Value__c.SObjectType,
            'Validation_Status__c'
        );
        String needsCorrectionStatus = validStatuses.contains('Needs Correction') ? 'Needs Correction' : validStatuses[0];
        System.assertEquals(needsCorrectionStatus, updated.Validation_Status__c, 'Blank required field should need correction');
        System.assertEquals('This field is required.', updated.Validation_Error_Message__c);
    }

    @isTest
    static void crossFieldExpressionPassesEquality() {
        Requirement_Field__c left = TestDataFactory.createRequirementField(
            'Left__c',
            'Cross-Field',
            false,
            true
        );
        Requirement_Field__c right = TestDataFactory.createRequirementField(
            'Right__c',
            'None',
            false,
            true
        );

        // Directly test the cross-field evaluator helper
        Map<String, String> values = new Map<String, String>{
            'Left__c' => 'X',
            'Right__c' => 'X'
        };
        Boolean passed = RequirementFieldAsyncValidator.evaluateCrossField('Left__c==Right__c', values);
        System.assertEquals(true, passed, 'Cross-field equality should validate');
    }

    @isTest
    static void testAndExpression() {
        Map<String, String> values = new Map<String, String>{
            'Field1__c' => 'value1',
            'Field2__c' => 'value2',
            'Field3__c' => 'value3'
        };

        // Both conditions true
        Boolean result1 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c == "value1" AND Field2__c == "value2"', values);
        System.assertEquals(true, result1, 'AND expression should pass when both conditions are true');

        // One condition false
        Boolean result2 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c == "value1" AND Field2__c == "wrong"', values);
        System.assertEquals(false, result2, 'AND expression should fail when one condition is false');
    }

    @isTest
    static void testOrExpression() {
        Map<String, String> values = new Map<String, String>{
            'Field1__c' => 'value1',
            'Field2__c' => 'value2'
        };

        // One condition true
        Boolean result1 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c == "value1" OR Field2__c == "wrong"', values);
        System.assertEquals(true, result1, 'OR expression should pass when one condition is true');

        // Both conditions false
        Boolean result2 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c == "wrong" OR Field2__c == "wrong"', values);
        System.assertEquals(false, result2, 'OR expression should fail when both conditions are false');
    }

    @isTest
    static void testNestedParentheses() {
        Map<String, String> values = new Map<String, String>{
            'Field1__c' => 'value1',
            'Field2__c' => 'value2',
            'Field3__c' => 'value3'
        };

        // Nested parentheses: (Field1 == Field2) OR (Field3 == "value3")
        Boolean result1 = RequirementFieldAsyncValidator.evaluateCrossField('(Field1__c == Field2__c) OR (Field3__c == "value3")', values);
        System.assertEquals(true, result1, 'Nested parentheses should evaluate correctly');

        // Complex nested: ((Field1 == "value1") AND (Field2 == "value2")) OR (Field3 == "wrong")
        Boolean result2 = RequirementFieldAsyncValidator.evaluateCrossField('((Field1__c == "value1") AND (Field2__c == "value2")) OR (Field3__c == "wrong")', values);
        System.assertEquals(true, result2, 'Complex nested expressions should evaluate correctly');
    }

    @isTest
    static void testIsBlankFunctions() {
        Map<String, String> values = new Map<String, String>{
            'Field1__c' => '',
            'Field2__c' => 'value2',
            'Field3__c' => null
        };

        // ISBLANK with blank field
        Boolean result1 = RequirementFieldAsyncValidator.evaluateCrossField('ISBLANK(Field1__c)', values);
        System.assertEquals(true, result1, 'ISBLANK should return true for blank field');

        // ISNOTBLANK with non-blank field
        Boolean result2 = RequirementFieldAsyncValidator.evaluateCrossField('ISNOTBLANK(Field2__c)', values);
        System.assertEquals(true, result2, 'ISNOTBLANK should return true for non-blank field');

        // Combined with AND
        Boolean result3 = RequirementFieldAsyncValidator.evaluateCrossField('ISBLANK(Field1__c) AND ISNOTBLANK(Field2__c)', values);
        System.assertEquals(true, result3, 'ISBLANK/ISNOTBLANK should work with AND');
    }

    @isTest
    static void testInequalityOperator() {
        Map<String, String> values = new Map<String, String>{
            'Field1__c' => 'value1',
            'Field2__c' => 'value2'
        };

        // Inequality true
        Boolean result1 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c != Field2__c', values);
        System.assertEquals(true, result1, 'Inequality should return true when values differ');

        // Inequality false
        Boolean result2 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c != "value1"', values);
        System.assertEquals(false, result2, 'Inequality should return false when values are equal');
    }

    @isTest
    static void testComplexExpression() {
        Map<String, String> values = new Map<String, String>{
            'Email__c' => 'test@example.com',
            'ConfirmEmail__c' => 'test@example.com',
            'Phone__c' => '1234567890',
            'Country__c' => 'US'
        };

        // Complex: (Email == ConfirmEmail) AND (ISNOTBLANK(Phone) OR Country == "US")
        Boolean result = RequirementFieldAsyncValidator.evaluateCrossField(
            '(Email__c == ConfirmEmail__c) AND (ISNOTBLANK(Phone__c) OR Country__c == "US")',
            values
        );
        System.assertEquals(true, result, 'Complex expression should evaluate correctly');
    }

    @isTest
    static void testLiteralValues() {
        Map<String, String> values = new Map<String, String>{
            'Field1__c' => 'test'
        };

        // Literal comparison
        Boolean result1 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c == "test"', values);
        System.assertEquals(true, result1, 'Literal comparison should work');

        // Literal with single quotes
        Boolean result2 = RequirementFieldAsyncValidator.evaluateCrossField('Field1__c == \'test\'', values);
        System.assertEquals(true, result2, 'Single quote literals should work');
    }
}