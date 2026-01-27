@isTest
private class AllStatusRuleGroupMustBeActiveRuleTest {

    @isTest
    static void testApply_WithActiveGroup_ShouldPass() {
        Vendor_Program_Group__c vendorGroup = TestVendorProgramGroupFactory.create(true);
        vendorGroup.Active__c = true;
        update vendorGroup;

        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(
            false,
            vendorGroup,
            null,
            null,
            null
        );
        engine.Active__c = false;
        insert engine;

        AllStatusRuleGroupMustBeActiveRule rule = new AllStatusRuleGroupMustBeActiveRule();

        Test.startTest();
        rule.apply(engine.Id, 'Onboarding_Status_Rules_Engine__c');
        Test.stopTest();

        System.assert(true, 'Should pass when vendor program group is active');
    }

    @isTest
    static void testApply_WithInactiveGroup_ShouldThrow() {
        Vendor_Program_Group__c vendorGroup = TestVendorProgramGroupFactory.create(true);
        vendorGroup.Active__c = false;
        update vendorGroup;

        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(
            false,
            vendorGroup,
            null,
            null,
            null
        );
        engine.Active__c = false;
        insert engine;

        AllStatusRuleGroupMustBeActiveRule rule = new AllStatusRuleGroupMustBeActiveRule();

        Test.startTest();
        try {
            rule.apply(engine.Id, 'Onboarding_Status_Rules_Engine__c');
            System.assert(false, 'Should throw exception for inactive vendor program group');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for inactive group');
        }
        Test.stopTest();
    }

    @isTest
    static void testApply_WithNullGroup_ShouldThrow() {
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(
            false,
            null,
            null,
            null,
            null
        );
        engine.Active__c = false;
        insert engine;

        AllStatusRuleGroupMustBeActiveRule rule = new AllStatusRuleGroupMustBeActiveRule();

        Test.startTest();
        try {
            rule.apply(engine.Id, 'Onboarding_Status_Rules_Engine__c');
            System.assert(false, 'Should throw exception for null group');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for null group');
        }
        Test.stopTest();
    }

    @isTest
    static void testApplyBulk_WithMixedActiveInactive_ShouldThrow() {
        Vendor_Program_Group__c activeGroup = TestVendorProgramGroupFactory.create(true);
        activeGroup.Active__c = true;
        update activeGroup;
        Onboarding_Status_Rules_Engine__c activeEngine = TestOnboardingRulesEngineFactory.create(
            false,
            activeGroup,
            null,
            null,
            null
        );
        activeEngine.Active__c = false;
        insert activeEngine;

        Vendor_Program_Group__c inactiveGroup = TestVendorProgramGroupFactory.create(true);
        inactiveGroup.Active__c = false;
        update inactiveGroup;
        Onboarding_Status_Rules_Engine__c inactiveEngine = TestOnboardingRulesEngineFactory.create(
            false,
            inactiveGroup,
            null,
            null,
            null
        );
        inactiveEngine.Active__c = false;
        insert inactiveEngine;

        AllStatusRuleGroupMustBeActiveRule rule = new AllStatusRuleGroupMustBeActiveRule();

        Test.startTest();
        try {
            rule.applyBulk(
                new Set<Id>{ activeEngine.Id, inactiveEngine.Id },
                'Onboarding_Status_Rules_Engine__c'
            );
            System.assert(false, 'Should throw exception for inactive groups');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for inactive group');
        }
        Test.stopTest();
    }

    @isTest
    static void testApplyBulk_WithEmptySet_ShouldNotThrow() {
        AllStatusRuleGroupMustBeActiveRule rule = new AllStatusRuleGroupMustBeActiveRule();

        Test.startTest();
        rule.applyBulk(new Set<Id>(), 'Onboarding_Status_Rules_Engine__c');
        rule.applyBulk(null, 'Onboarding_Status_Rules_Engine__c');
        Test.stopTest();

        System.assert(true, 'Should handle empty set gracefully');
    }
}
