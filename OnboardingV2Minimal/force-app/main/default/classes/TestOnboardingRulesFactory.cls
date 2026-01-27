@isTest
public class TestOnboardingRulesFactory {

    public static Onboarding_Status_Rule__c create(
        Boolean doInsert,
        Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngineRule,
        Vendor_Program_Requirement__c vendorProgramRequirement,
        String expectedStatus,
        Integer ruleNumber
    ) {
        Onboarding_Status_Rule__c onboardingStatusRule = new Onboarding_Status_Rule__c(
            Parent_Rule__c = onboardingStatusRulesEngineRule != null ? onboardingStatusRulesEngineRule.Id : null,
            Requirement__c = vendorProgramRequirement != null ? vendorProgramRequirement.Id : null,
            Expected_Status__c = String.isNotBlank(expectedStatus) ? expectedStatus : 
                TestDataFactoryUtil.getFirstPicklistValue(
                    Onboarding_Status_Rule__c.SObjectType,
                    'Expected_Status__c'
                ),
            Rule_Number__c = ruleNumber != null ? ruleNumber : 1
        );

        TestDataFactoryUtil.maybeInsert(onboardingStatusRule, doInsert);
        return onboardingStatusRule;
    }

    public static Onboarding_Status_Rule__c create(Boolean doInsert) {
        Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngineRule = TestOnboardingRulesEngineFactory.create(doInsert);
        Vendor_Program_Requirement__c requivendorProgramRequirementement = TestVendorProgramRequirementFactory.create(doInsert);
        String defaultStatus = TestDataFactoryUtil.getFirstPicklistValue(
            Onboarding_Status_Rule__c.SObjectType,
            'Expected_Status__c'
        );
        return create(doInsert, onboardingStatusRulesEngineRule, requivendorProgramRequirementement, defaultStatus, 1);
    }

    // ===========================================
    // NEW: Version Chain Builder for Rules Engine
    // ===========================================
    public class VersionChainWrapper {
        public Onboarding_Status_Rules_Engine__c engine;
        public List<Vendor_Program_Requirement__c> requirements;
        public List<Onboarding_Status_Rule__c> rules;

        public VersionChainWrapper(
            Onboarding_Status_Rules_Engine__c engine,
            List<Vendor_Program_Requirement__c> requirements,
            List<Onboarding_Status_Rule__c> rules
        ) {
            this.engine = engine;
            this.requirements = requirements;
            this.rules = rules;
        }
    }

    public static VersionChainWrapper createVersionChain(Boolean doInsert) {

        Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(doInsert);

        List<Vendor_Program_Requirement__c> reqs = new List<Vendor_Program_Requirement__c>();
        for (Integer i = 0; i < 2; i++) {
            reqs.add(TestVendorProgramRequirementFactory.create(doInsert));
        }

        List<Onboarding_Status_Rule__c> rules = new List<Onboarding_Status_Rule__c>();
        
        Integer idx = 1;
        for (Vendor_Program_Requirement__c req : reqs) {
            rules.add(
                TestOnboardingRulesFactory.create(
                    doInsert,
                    engine,
                    req,
                    TestDataFactoryUtil.getFirstPicklistValue(
                        Onboarding_Status_Rule__c.SObjectType,
                        'Expected_Status__c'
                    ),
                    idx++
                )
            );
        }
        return new VersionChainWrapper(engine, reqs, rules);
    }
}