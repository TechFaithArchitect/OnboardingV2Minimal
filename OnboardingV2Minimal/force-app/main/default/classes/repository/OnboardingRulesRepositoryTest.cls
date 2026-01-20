@isTest
private class OnboardingRulesRepositoryTest {

    @isTest
    static void testFetchRulesEngineRecords() {
        TestDataFactoryWrapper.OnboardingRulesSetupWrapper wrapper =
            TestDataFactory.createAllOnboardingRule(null, 1, 'New', false, true);
        Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine = wrapper.ruleEngine;

        Test.startTest();
        List<Onboarding_Status_Rule__c> onboardingStatusRule = OnboardingRulesRepository.fetchRulesEngineRecords(onboardingStatusRulesEngine.Id);
        Test.stopTest();

        System.assertNotEquals(null, onboardingStatusRule, 'Rules list should not be null');
        System.assertEquals(1, onboardingStatusRule.size(), 'Expected one rule');
    }

    @isTest
    static void testUpsertRule() {
        // Create rules engine first (Parent_Rule__c is required)
        Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine = TestOnboardingRulesEngineFactory.create(true);
        
        Onboarding_Status_Rule__c onboardingStatusRule = new Onboarding_Status_Rule__c(
            Parent_Rule__c = onboardingStatusRulesEngine.Id,
            Rule_Number__c = 1,
            Expected_Status__c = TestDataFactoryUtil.getFirstPicklistValue(
                Onboarding_Status_Rule__c.SObjectType,
                'Expected_Status__c'
            )
        );

        Test.startTest();
        Onboarding_Status_Rule__c upsertOnboardingStatusRule = OnboardingRulesRepository.upsertRule(onboardingStatusRule);
        Test.stopTest();

        System.assertNotEquals(null, upsertOnboardingStatusRule.Id, 'Upserted rule should have an Id');
    }

    @isTest
    static void testDeleteRule() {
        Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine = TestOnboardingRulesEngineFactory.create(true);

        Onboarding_Status_Rule__c onboardingStatusRule = new Onboarding_Status_Rule__c(
            Parent_Rule__c = onboardingStatusRulesEngine.Id,
            Rule_Number__c = 2,
            Expected_Status__c = TestDataFactoryUtil.getFirstPicklistValue(
                Onboarding_Status_Rule__c.SObjectType,
                'Expected_Status__c'
            )
        );
        insert onboardingStatusRule;

        Test.startTest();
        OnboardingRulesRepository.deleteRule(onboardingStatusRule.Id);
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM Onboarding_Status_Rule__c WHERE Id = :onboardingStatusRule.Id],
            'Rule should be deleted');
    }

    @isTest
    static void testFetchOnboardingWithRequirements() {
        TestDataFactoryWrapper.AccountContactWrapper acctWrapper = TestDataFactory.createAccountContact(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        Onboarding__c onboarding = TestDataFactory.createOnboarding(acctWrapper.account, vendorProgram, true);

        TestDataFactoryWrapper.OnboardingRulesSetupWrapper rulesWrapper =
            TestDataFactory.createAllOnboardingRule(onboarding, 1, 'New', true, true);

        Test.startTest();
        Onboarding__c result = OnboardingRulesRepository.fetchOnboardingWithRequirements(onboarding.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Onboarding should be returned');
        System.assert(result.Onboarding_Requirements__r.size() > 0, 'Should have requirements');
    }

    @isTest
    static void testFetchRulesForGroups() {
        TestDataFactoryWrapper.OnboardingRulesSetupWrapper wrapper =
            TestDataFactoryWrapper.createRulesVersionChain(true);
        Id groupId = wrapper.ruleEngine.Vendor_Program_Group__c;

        Test.startTest();
        List<Onboarding_Status_Rules_Engine__c> result =
            OnboardingRulesRepository.fetchRulesForGroups(new List<Id>{ groupId });
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testFetchRequirementsByOnboardingIds() {
        TestDataFactoryWrapper.AccountContactWrapper acctWrapper = TestDataFactory.createAccountContact(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Onboarding__c onboarding = TestDataFactory.createOnboarding(acctWrapper.account, vendorProgram, true);

        TestDataFactoryWrapper.OnboardingRulesSetupWrapper wrapper =
            TestDataFactory.createAllOnboardingRule(onboarding, 1, 'New', true, true);

        Set<Id> onboardingIds = new Set<Id>{ onboarding.Id };

        Test.startTest();
        List<Onboarding_Requirement__c> result =
            OnboardingRulesRepository.fetchRequirementsByOnboardingIds(onboardingIds);
        Test.stopTest();

        System.assert(result.size() > 0, 'Should fetch onboarding requirements');
    }

    @isTest
    static void testFetchOnboardingsByIds() {
        TestDataFactoryWrapper.AccountContactWrapper acctWrapper = TestDataFactory.createAccountContact(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Onboarding__c onboarding = TestDataFactory.createOnboarding(acctWrapper.account, vendorProgram, true);

        Test.startTest();
        List<Onboarding__c> result = OnboardingRulesRepository.fetchOnboardingsByIds(new Set<Id>{ onboarding.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should fetch one onboarding');
    }

    @isTest
    static void testFetchGroupMembersByVendorProgramIds() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        Vendor_Program_Group_Member__c vendorProgramGroupMember = new Vendor_Program_Group_Member__c(
            Required_Program__c = vendorProgram.Id
        );
        insert vendorProgramGroupMember;

        Test.startTest();
        List<Vendor_Program_Group_Member__c> result =
            OnboardingRulesRepository.fetchGroupMembersByVendorProgramIds(new Set<Id>{ vendorProgram.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should fetch one group member');
    }

    @isTest
    static void testFetchGroupMembersByVendorProgramId() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram =
            TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);

        Vendor_Program_Group_Member__c member = new Vendor_Program_Group_Member__c(
            Required_Program__c = vendorProgram.Id
        );
        insert member;

        Test.startTest();
        List<Vendor_Program_Group_Member__c> result =
            OnboardingRulesRepository.fetchGroupMembersByVendorProgramId(vendorProgram.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one group member');
    }
}