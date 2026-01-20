@isTest
private class AllStatusRuleGroupMustBeActiveRuleTest {

    @isTest
    static void testApply_WithAllActiveGroups_ShouldPass() {
        // Create active requirement group
        Vendor_Program_Requirement_Group__c reqGroup = TestDataFactory.createVendorProgramRequirementGroup('Test Req Group', true);
        reqGroup.Active__c = true;
        update reqGroup;

        // Create active vendor program group
        Vendor_Program_Group__c vendorGroup = TestDataFactory.createVendorProgramGroup(true);
        vendorGroup.Active__c = true;
        update vendorGroup;

        // Create rules engine with active groups
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(
            false, reqGroup, vendorGroup, 'ALL', 'New', 'In Process'
        );
        engine.Active__c = false;
        insert engine;

        AllStatusRuleGroupMustBeActiveRule rule = new AllStatusRuleGroupMustBeActiveRule();

        Test.startTest();
        // Should not throw exception
        rule.apply(engine.Id, 'Onboarding_Status_Rules_Engine__c');
        Test.stopTest();

        System.assert(true, 'Should pass when all groups are active');
    }

    @isTest
    static void testApply_WithInactiveRequirementGroup_ShouldThrow() {
        // Create inactive requirement group
        Vendor_Program_Requirement_Group__c reqGroup = TestDataFactory.createVendorProgramRequirementGroup('Test Req Group', true);
        reqGroup.Active__c = false;
        update reqGroup;

        // Create active vendor program group
        Vendor_Program_Group__c vendorGroup = TestDataFactory.createVendorProgramGroup(true);
        vendorGroup.Active__c = true;
        update vendorGroup;

        // Create rules engine with inactive requirement group
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(
            false, reqGroup, vendorGroup, 'ALL', 'New', 'In Process'
        );
        engine.Active__c = false;
        insert engine;

        AllStatusRuleGroupMustBeActiveRule rule = new AllStatusRuleGroupMustBeActiveRule();

        Test.startTest();
        try {
            rule.apply(engine.Id, 'Onboarding_Status_Rules_Engine__c');
            System.assert(false, 'Should throw exception for inactive requirement group');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for inactive requirement group');
        }
        Test.stopTest();
    }

    @isTest
    static void testApply_WithInactiveVendorProgramGroup_ShouldThrow() {
        // Create active requirement group
        Vendor_Program_Requirement_Group__c reqGroup = TestDataFactory.createVendorProgramRequirementGroup('Test Req Group', true);
        reqGroup.Active__c = true;
        update reqGroup;

        // Create inactive vendor program group
        Vendor_Program_Group__c vendorGroup = TestDataFactory.createVendorProgramGroup(true);
        vendorGroup.Active__c = false;
        update vendorGroup;

        // Create rules engine with inactive vendor program group
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(
            false, reqGroup, vendorGroup, 'ALL', 'New', 'In Process'
        );
        engine.Active__c = false;
        insert engine;

        AllStatusRuleGroupMustBeActiveRule rule = new AllStatusRuleGroupMustBeActiveRule();

        Test.startTest();
        try {
            rule.apply(engine.Id, 'Onboarding_Status_Rules_Engine__c');
            System.assert(false, 'Should throw exception for inactive vendor program group');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for inactive vendor program group');
        }
        Test.stopTest();
    }

    @isTest
    static void testApply_WithNullGroups_ShouldThrow() {
        // Create rules engine with null groups
        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(
            false, null, null, 'ALL', 'New', 'In Process'
        );
        engine.Active__c = false;
        insert engine;

        AllStatusRuleGroupMustBeActiveRule rule = new AllStatusRuleGroupMustBeActiveRule();

        Test.startTest();
        try {
            rule.apply(engine.Id, 'Onboarding_Status_Rules_Engine__c');
            System.assert(false, 'Should throw exception for null groups');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for null groups');
        }
        Test.stopTest();
    }

    @isTest
    static void testApplyBulk_WithMixedActiveInactive_ShouldThrow() {
        // Active groups
        Vendor_Program_Requirement_Group__c activeReqGroup = TestDataFactory.createVendorProgramRequirementGroup('Active Req Group', true);
        activeReqGroup.Active__c = true;
        update activeReqGroup;
        Vendor_Program_Group__c activeVendorGroup = TestDataFactory.createVendorProgramGroup(true);
        activeVendorGroup.Active__c = true;
        update activeVendorGroup;
        Onboarding_Status_Rules_Engine__c activeEngine = TestOnboardingRulesEngineFactory.create(
            false, activeReqGroup, activeVendorGroup, 'ALL', 'New', 'In Process'
        );
        activeEngine.Active__c = false;
        insert activeEngine;

        // Inactive groups
        Vendor_Program_Requirement_Group__c inactiveReqGroup = TestDataFactory.createVendorProgramRequirementGroup('Inactive Req Group', true);
        inactiveReqGroup.Active__c = false;
        update inactiveReqGroup;
        Vendor_Program_Group__c inactiveVendorGroup = TestDataFactory.createVendorProgramGroup(true);
        inactiveVendorGroup.Active__c = true;
        update inactiveVendorGroup;
        Onboarding_Status_Rules_Engine__c inactiveEngine = TestOnboardingRulesEngineFactory.create(
            false, inactiveReqGroup, inactiveVendorGroup, 'ALL', 'New', 'In Process'
        );
        inactiveEngine.Active__c = false;
        insert inactiveEngine;

        AllStatusRuleGroupMustBeActiveRule rule = new AllStatusRuleGroupMustBeActiveRule();

        Test.startTest();
        try {
            rule.applyBulk(new Set<Id>{ activeEngine.Id, inactiveEngine.Id }, 'Onboarding_Status_Rules_Engine__c');
            System.assert(false, 'Should throw exception for inactive groups');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for inactive groups');
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