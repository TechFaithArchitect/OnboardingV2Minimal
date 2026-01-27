@isTest
private class OnboardingStatusRulesEngineCtlrTest {

    @isTest
    static void testGetRules() {
        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        TestOnboardingRulesEngineFactory.create(
            true,
            vendorProgramGroup,
            'ALL',
            null,
            'In Process'
        );

        Test.startTest();
        List<Onboarding_Status_Rules_Engine__c> result =
            OnboardingStatusRulesEngineController.getRules(vendorProgramGroup.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return rules');
    }

    @isTest
    static void testSaveRules() {
        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(
            true,
            vendorProgramGroup,
            'ALL',
            null,
            'In Process'
        );
        List<String> validTargetStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Status_Rules_Engine__c.SObjectType,
            'Target_Onboarding_Status__c'
        );
        String targetStatus = validTargetStatuses.size() > 0 ? validTargetStatuses[0] : null;
        if (targetStatus != null) {
            rule.Target_Onboarding_Status__c = targetStatus;
        }
        List<Onboarding_Status_Rules_Engine__c> rules = new List<Onboarding_Status_Rules_Engine__c>{
            rule
        };

        Test.startTest();
        OnboardingStatusRulesEngineController.saveRules(rules);
        Test.stopTest();

        Onboarding_Status_Rules_Engine__c updated = [
            SELECT Id, Target_Onboarding_Status__c
            FROM Onboarding_Status_Rules_Engine__c
            WHERE Id = :rule.Id
        ];
        if (targetStatus != null) {
            System.assertEquals(
                targetStatus,
                updated.Target_Onboarding_Status__c,
                'Status should be updated'
            );
        }
    }

    @isTest
    static void testGetVendorProgramGroups() {
        TestVendorProgramGroupFactory.create(true);

        Test.startTest();
        List<Map<String, String>> result =
            OnboardingStatusRulesEngineController.getVendorProgramGroups();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return vendor program groups');
        System.assertEquals(
            'value',
            result[0].keySet().iterator().next(),
            'Should have value/label keys'
        );
    }
}
