@isTest
private class AllLinkedEngineMustBeActiveRuleTest {

    @isTest
    static void testApply_WithActiveParentEngine_ShouldPass() {
        // Create active rules engine
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(true);
        engine.Active__c = true;
        update engine;

        // Create active vendor program requirement
        Vendor_Program_Requirement__c requirement = TestVendorProgramRequirementFactory.create(true);
        requirement.Active__c = true;
        update requirement;

        // Create status rule with active parent
        Onboarding_Status_Rule__c statusRule = TestOnboardingRulesFactory.create(
            false, engine, requirement, 'New', 1
        );
        statusRule.Active__c = false;
        insert statusRule;

        AllLinkedEngineMustBeActiveRule rule = new AllLinkedEngineMustBeActiveRule();

        Test.startTest();
        // Should not throw exception
        rule.apply(statusRule.Id, 'Onboarding_Status_Rule__c');
        Test.stopTest();

        // If we get here, the test passed
        System.assert(true, 'Should pass when parent engine and requirement are active');
    }

    @isTest
    static void testApply_WithInactiveParentEngine_ShouldThrow() {
        // Create inactive rules engine
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(true);
        engine.Active__c = false;
        update engine;

        // Create active vendor program requirement
        Vendor_Program_Requirement__c requirement = TestVendorProgramRequirementFactory.create(true);
        requirement.Active__c = true;
        update requirement;

        // Create status rule with inactive parent
        Onboarding_Status_Rule__c statusRule = TestOnboardingRulesFactory.create(
            false, engine, requirement, 'New', 1
        );
        statusRule.Active__c = false;
        insert statusRule;

        AllLinkedEngineMustBeActiveRule rule = new AllLinkedEngineMustBeActiveRule();

        Test.startTest();
        try {
            rule.apply(statusRule.Id, 'Onboarding_Status_Rule__c');
            System.assert(false, 'Should throw exception for inactive parent engine');
        } catch (AuraHandledException e) {
             System.assert(e != null, 'AuraHandledException should be thrown for inactive parent engine');
        }
        Test.stopTest();
    }

    @isTest
    static void testApply_WithInactiveRequirement_ShouldThrow() {
        // Create active rules engine
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(true);
        engine.Active__c = true;
        update engine;

        // Create inactive vendor program requirement
        Vendor_Program_Requirement__c requirement = TestVendorProgramRequirementFactory.create(true);
        requirement.Active__c = false;
        update requirement;

        // Create status rule with inactive requirement
        Onboarding_Status_Rule__c statusRule = TestOnboardingRulesFactory.create(
            false, engine, requirement, 'New', 1
        );
        statusRule.Active__c = false;
        insert statusRule;

        AllLinkedEngineMustBeActiveRule rule = new AllLinkedEngineMustBeActiveRule();

        Test.startTest();
        try {
            rule.apply(statusRule.Id, 'Onboarding_Status_Rule__c');
            System.assert(false, 'Should throw exception for inactive requirement');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for inactive requirement');
        }
        Test.stopTest();
    }

    @isTest
    static void testApplyBulk_WithMixedActiveInactive_ShouldThrow() {
        // Create active and inactive engines
        Onboarding_Status_Rules_Engine__c activeEngine = TestOnboardingRulesEngineFactory.create(true);
        activeEngine.Active__c = true;
        update activeEngine;

        Onboarding_Status_Rules_Engine__c inactiveEngine = TestOnboardingRulesEngineFactory.create(true);
        inactiveEngine.Active__c = false;
        update inactiveEngine;

        Vendor_Program_Requirement__c requirement = TestVendorProgramRequirementFactory.create(true);
        requirement.Active__c = true;
        update requirement;

        Onboarding_Status_Rule__c activeRule = TestOnboardingRulesFactory.create(
            false, activeEngine, requirement, 'New', 1
        );
        activeRule.Active__c = false;
        insert activeRule;

        Onboarding_Status_Rule__c inactiveRule = TestOnboardingRulesFactory.create(
            false, inactiveEngine, requirement, 'New', 2
        );
        inactiveRule.Active__c = false;
        insert inactiveRule;

        AllLinkedEngineMustBeActiveRule rule = new AllLinkedEngineMustBeActiveRule();

        Test.startTest();
        try {
            rule.applyBulk(new Set<Id>{ activeRule.Id, inactiveRule.Id }, 'Onboarding_Status_Rule__c');
            System.assert(false, 'Should throw exception for inactive parent engine');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for inactive parent engine');
        }
        Test.stopTest();
    }

    @isTest
    static void testApplyBulk_WithEmptySet_ShouldNotThrow() {
        AllLinkedEngineMustBeActiveRule rule = new AllLinkedEngineMustBeActiveRule();

        Test.startTest();
        // Should not throw exception
        rule.applyBulk(new Set<Id>(), 'Onboarding_Status_Rule__c');
        rule.applyBulk(null, 'Onboarding_Status_Rule__c');
        Test.stopTest();

        System.assert(true, 'Should handle empty set gracefully');
    }
}