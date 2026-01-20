@isTest
private class OnboardingExpressionEngineTest {

    @isTest
    static void testEvaluate_True() {
        // Act
        Test.startTest();
        Boolean result = OnboardingExpressionEngine.evaluate('true');
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'Should evaluate true expression');
    }

    @isTest
    static void testEvaluate_False() {
        // Act
        Test.startTest();
        Boolean result = OnboardingExpressionEngine.evaluate('false');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Should evaluate false expression');
    }

    @isTest
    static void testEvaluate_Blank_ReturnsFalse() {
        // Act
        Test.startTest();
        Boolean result1 = OnboardingExpressionEngine.evaluate('');
        Boolean result2 = OnboardingExpressionEngine.evaluate(null);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result1, 'Blank expression should return false');
        System.assertEquals(false, result2, 'Null expression should return false');
    }

    @isTest
    static void testEvaluate_WithContext() {
        // Arrange
        Map<String, Object> context = new Map<String, Object>{ 'key' => 'value' };
        
        // Act
        Test.startTest();
        Boolean result = OnboardingExpressionEngine.evaluate('true', context);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'Should evaluate expression with context');
    }

    @isTest
    static void testEvaluate_InvalidExpression_Throws() {
        // Act + Assert
        try {
            Test.startTest();
            OnboardingExpressionEngine.evaluate('invalid');
            Test.stopTest();
            System.assert(false, 'Expected exception was not thrown');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Invalid expression'), 'Should throw exception for invalid expression');
        }
    }

    @isTest
    static void testEvaluate_Caching() {
        // Act
        Test.startTest();
        Boolean result1 = OnboardingExpressionEngine.evaluate('true');
        Boolean result2 = OnboardingExpressionEngine.evaluate('true'); // Should use cache
        Boolean result3 = OnboardingExpressionEngine.evaluate('false');
        Boolean result4 = OnboardingExpressionEngine.evaluate('false'); // Should use cache
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result1, 'First true should work');
        System.assertEquals(true, result2, 'Cached true should work');
        System.assertEquals(false, result3, 'First false should work');
        System.assertEquals(false, result4, 'Cached false should work');
    }

    @isTest
    static void testClearCache() {
        // Arrange - Evaluate to populate cache
        OnboardingExpressionEngine.evaluate('true');
        
        // Act
        Test.startTest();
        OnboardingExpressionEngine.clearCache();
        Boolean result = OnboardingExpressionEngine.evaluate('true'); // Should re-parse after clear
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'Should still evaluate correctly after clearing cache');
    }
}