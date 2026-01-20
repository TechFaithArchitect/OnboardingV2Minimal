@isTest
private class OnboardingHealthServiceTest {

    @isTest
    static void reportsMissingWhenEmpty() {
        Test.startTest();
        List<OnboardingHealthService.HealthItem> items = OnboardingHealthService.runHealthCheck();
        Test.stopTest();

        System.assert(items.size() > 0, 'Should report issues when nothing configured');
    }

    @isTest
    static void passesWhenAligned() {
        // Insert all expected components
        Map<String, Id> libMap = new Map<String, Id>();
        for (String apiName : new List<String>{
            'vendorProgramOnboardingVendor',
            'vendorProgramOnboardingVendorProgramSearchOrCreate',
            'vendorProgramOnboardingRequirementSetOrCreate',
            'vendorProgramOnboardingRequirementGroupLinking',
            'vendorProgramOnboardingRequiredCredentials',
            'vendorProgramOnboardingTrainingRequirements',
            'vendorProgramOnboardingStatusRulesEngine',
            'vendorProgramOnboardingRecipientGroup',
            'vendorProgramOnboardingCommunicationTemplate',
            'vendorProgramOnboardingFinalize'
        }) {
            Onboarding_Component_Library__c comp = new Onboarding_Component_Library__c(
                Name = apiName,
                Component_API_Name__c = apiName,
                Component_Type__c = 'LWC',
                Active__c = true
            );
            insert comp;
            libMap.put(apiName, comp.Id);
        }

        Onboarding_Application_Process__c proc = new Onboarding_Application_Process__c(
            Name = 'Vendor Program Onboarding',
            Active__c = true
        );
        insert proc;

        Integer order = 1;
        List<Onboarding_Application_Stage__c> stages = new List<Onboarding_Application_Stage__c>();
        for (String apiName : libMap.keySet()) {
            Onboarding_Application_Stage__c st = new Onboarding_Application_Stage__c(
                Name = 'Stage ' + order,
                Label__c = 'Stage ' + order,
                Display_Order__c = order,
                Onboarding_Application_Process__c = proc.Id,
                Onboarding_Component_Library__c = libMap.get(apiName),
                Required__c = true
            );
            stages.add(st);
            order++;
        }
        insert stages;

        Test.startTest();
        List<OnboardingHealthService.HealthItem> items = OnboardingHealthService.runHealthCheck();
        Test.stopTest();

        System.assertEquals(1, items.size(), 'Should return single OK item when aligned');
        System.assertEquals('ok', items[0].type, 'Type should be ok');
    }
}