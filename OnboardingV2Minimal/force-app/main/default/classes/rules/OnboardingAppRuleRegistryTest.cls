@isTest
private class OnboardingAppRuleRegistryTest {

    @isTest
    static void testGetValidationRules() {
        // Act
        Test.startTest();
        Map<String, List<OnboardingAppValidationRule>> rules = OnboardingAppRuleRegistry.getValidationRules();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, rules, 'Rules should not be null');
        System.assert(rules.containsKey('Vendor_Program_Recipient_Group__c'), 
            'Should contain Vendor_Program_Recipient_Group__c rules');
        List<OnboardingAppValidationRule> recipientGroupRules = rules.get('Vendor_Program_Recipient_Group__c');
        System.assertNotEquals(null, recipientGroupRules, 'Recipient group rules should not be null');
        System.assert(recipientGroupRules.size() > 0, 'Should have validation rules');
    }

    @isTest
    static void testGetActivationRulesForObject_VendorProgram() {
        // Act
        Test.startTest();
        List<OnboardingAppActivationRule> rules = OnboardingAppRuleRegistry.getActivationRulesForObject('Vendor_Program__c');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, rules, 'Rules should not be null');
        System.assert(rules.size() > 0, 'Should have activation rules for Vendor_Program__c');
    }

    @isTest
    static void testGetActivationRulesForObject_VendorCustomization() {
        // Act
        Test.startTest();
        List<OnboardingAppActivationRule> rules = OnboardingAppRuleRegistry.getActivationRulesForObject('Vendor_Customization__c');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, rules, 'Rules should not be null');
        System.assert(rules.size() > 0, 'Should have activation rules for Vendor_Customization__c');
    }

    @isTest
    static void testGetActivationRulesForObject_OnboardingStatusRule() {
        // Act
        Test.startTest();
        List<OnboardingAppActivationRule> rules = OnboardingAppRuleRegistry.getActivationRulesForObject('Onboarding_Status_Rule__c');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, rules, 'Rules should not be null');
        System.assert(rules.size() > 0, 'Should have activation rules for Onboarding_Status_Rule__c');
    }

    @isTest
    static void testGetActivationRulesForObject_OnboardingStatusRulesEngine() {
        // Act
        Test.startTest();
        List<OnboardingAppActivationRule> rules = OnboardingAppRuleRegistry.getActivationRulesForObject('Onboarding_Status_Rules_Engine__c');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, rules, 'Rules should not be null');
        System.assert(rules.size() > 0, 'Should have activation rules for Onboarding_Status_Rules_Engine__c');
    }

    @isTest
    static void testGetActivationRulesForObject_UnknownObject_ReturnsEmpty() {
        // Act
        Test.startTest();
        List<OnboardingAppActivationRule> rules = OnboardingAppRuleRegistry.getActivationRulesForObject('Unknown_Object__c');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, rules, 'Rules should not be null');
        System.assertEquals(0, rules.size(), 'Should return empty list for unknown object');
    }
}