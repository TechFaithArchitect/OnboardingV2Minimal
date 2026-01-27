@isTest
private class OnboardingRuleEvaluatorTest {

    private static String getRequirementStatus(String preferredStatus) {
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Status__c'
        );
        if (validStatuses.contains(preferredStatus)) {
            return preferredStatus;
        }
        return validStatuses.isEmpty() ? null : validStatuses[0];
    }

    private static String getDifferentRequirementStatus(String statusToAvoid) {
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Status__c'
        );
        for (String status : validStatuses) {
            if (status != statusToAvoid) {
                return status;
            }
        }
        return null;
    }

    private static String getOnboardingStatus(String preferredStatus) {
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Onboarding_Status__c'
        );
        if (validStatuses.contains(preferredStatus)) {
            return preferredStatus;
        }
        return validStatuses.isEmpty() ? null : validStatuses[0];
    }

    private static String getEvaluationLogic(String preferredLogic) {
        List<String> validLogics = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Status_Rules_Engine__c.SObjectType,
            'Evaluation_Logic__c'
        );
        if (validLogics.contains(preferredLogic)) {
            return preferredLogic;
        }
        return validLogics.isEmpty() ? null : validLogics[0];
    }

    private static String getExpectedStatus(String preferredStatus) {
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Status_Rule__c.SObjectType,
            'Expected_Status__c'
        );
        if (validStatuses.contains(preferredStatus)) {
            return preferredStatus;
        }
        return validStatuses.isEmpty() ? null : validStatuses[0];
    }

    private static Onboarding_Status_Rules_Engine__c queryRuleEngine(Id ruleId) {
        return [
            SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (
                    SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c
                    FROM Onboarding_Status_Rules__r
                )
            FROM Onboarding_Status_Rules_Engine__c
            WHERE Id = :ruleId
        ];
    }

    @isTest
    static void testEvaluateRule_ALL_True() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(
            TestDataFactory.createAccount('Test Account', true),
            vendorProgram,
            true
        );

        Vendor_Program_Requirement__c requirementOne = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            true
        );
        Vendor_Program_Requirement__c requirementTwo = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            true
        );

        String completeStatus = getRequirementStatus('Complete');
        String inProcessStatus = getOnboardingStatus('In Process');
        String expectedCompleteStatus = getExpectedStatus(completeStatus);

        Onboarding_Requirement__c reqOne = TestOnboardingRequirementFactory.create(
            true,
            onboarding,
            requirementOne
        );
        reqOne.Status__c = completeStatus;
        update reqOne;

        Onboarding_Requirement__c reqTwo = TestOnboardingRequirementFactory.create(
            true,
            onboarding,
            requirementTwo
        );
        reqTwo.Status__c = completeStatus;
        update reqTwo;

        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(
            true,
            vendorProgramGroup,
            getEvaluationLogic('ALL'),
            null,
            inProcessStatus
        );
        TestOnboardingRulesFactory.create(true, rule, requirementOne, expectedCompleteStatus, 1);
        TestOnboardingRulesFactory.create(true, rule, requirementTwo, expectedCompleteStatus, 2);

        rule = queryRuleEngine(rule.Id);

        Map<Id, Onboarding_Requirement__c> reqByVpr = new Map<Id, Onboarding_Requirement__c>{
            requirementOne.Id => reqOne,
            requirementTwo.Id => reqTwo
        };

        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVpr);
        Test.stopTest();

        System.assertEquals(true, result, 'ALL logic should return true when all conditions match');
    }

    @isTest
    static void testEvaluateRule_ALL_False() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(
            TestDataFactory.createAccount('Test Account', true),
            vendorProgram,
            true
        );

        Vendor_Program_Requirement__c requirementOne = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            true
        );
        Vendor_Program_Requirement__c requirementTwo = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            true
        );

        String completeStatus = getRequirementStatus('Complete');
        String nonMatchingStatus = getDifferentRequirementStatus(completeStatus);
        String inProcessStatus = getOnboardingStatus('In Process');
        String expectedCompleteStatus = getExpectedStatus(completeStatus);

        Onboarding_Requirement__c reqOne = TestOnboardingRequirementFactory.create(
            true,
            onboarding,
            requirementOne
        );
        reqOne.Status__c = completeStatus;
        update reqOne;

        Onboarding_Requirement__c reqTwo = TestOnboardingRequirementFactory.create(
            true,
            onboarding,
            requirementTwo
        );
        reqTwo.Status__c = nonMatchingStatus;
        update reqTwo;

        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(
            true,
            vendorProgramGroup,
            getEvaluationLogic('ALL'),
            null,
            inProcessStatus
        );
        TestOnboardingRulesFactory.create(true, rule, requirementOne, expectedCompleteStatus, 1);
        TestOnboardingRulesFactory.create(true, rule, requirementTwo, expectedCompleteStatus, 2);

        rule = queryRuleEngine(rule.Id);

        Map<Id, Onboarding_Requirement__c> reqByVpr = new Map<Id, Onboarding_Requirement__c>{
            requirementOne.Id => reqOne,
            requirementTwo.Id => reqTwo
        };

        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVpr);
        Test.stopTest();

        System.assertEquals(false, result, 'ALL logic should return false when any condition fails');
    }

    @isTest
    static void testEvaluateRule_ANY_True() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(
            TestDataFactory.createAccount('Test Account', true),
            vendorProgram,
            true
        );

        Vendor_Program_Requirement__c requirementOne = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            true
        );
        Vendor_Program_Requirement__c requirementTwo = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            true
        );

        String completeStatus = getRequirementStatus('Complete');
        String nonMatchingStatus = getDifferentRequirementStatus(completeStatus);
        String inProcessStatus = getOnboardingStatus('In Process');
        String expectedCompleteStatus = getExpectedStatus(completeStatus);

        Onboarding_Requirement__c reqOne = TestOnboardingRequirementFactory.create(
            true,
            onboarding,
            requirementOne
        );
        reqOne.Status__c = completeStatus;
        update reqOne;

        Onboarding_Requirement__c reqTwo = TestOnboardingRequirementFactory.create(
            true,
            onboarding,
            requirementTwo
        );
        reqTwo.Status__c = nonMatchingStatus;
        update reqTwo;

        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(
            true,
            vendorProgramGroup,
            getEvaluationLogic('ANY'),
            null,
            inProcessStatus
        );
        TestOnboardingRulesFactory.create(true, rule, requirementOne, expectedCompleteStatus, 1);
        TestOnboardingRulesFactory.create(true, rule, requirementTwo, expectedCompleteStatus, 2);

        rule = queryRuleEngine(rule.Id);

        Map<Id, Onboarding_Requirement__c> reqByVpr = new Map<Id, Onboarding_Requirement__c>{
            requirementOne.Id => reqOne,
            requirementTwo.Id => reqTwo
        };

        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVpr);
        Test.stopTest();

        System.assertEquals(true, result, 'ANY logic should return true when one condition matches');
    }

    @isTest
    static void testEvaluateRule_ANY_False() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(
            TestDataFactory.createAccount('Test Account', true),
            vendorProgram,
            true
        );

        Vendor_Program_Requirement__c requirementOne = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            true
        );
        Vendor_Program_Requirement__c requirementTwo = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            true
        );

        String completeStatus = getRequirementStatus('Complete');
        String nonMatchingStatus = getDifferentRequirementStatus(completeStatus);
        String inProcessStatus = getOnboardingStatus('In Process');
        String expectedCompleteStatus = getExpectedStatus(completeStatus);

        Onboarding_Requirement__c reqOne = TestOnboardingRequirementFactory.create(
            true,
            onboarding,
            requirementOne
        );
        reqOne.Status__c = nonMatchingStatus;
        update reqOne;

        Onboarding_Requirement__c reqTwo = TestOnboardingRequirementFactory.create(
            true,
            onboarding,
            requirementTwo
        );
        reqTwo.Status__c = nonMatchingStatus;
        update reqTwo;

        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(
            true,
            vendorProgramGroup,
            getEvaluationLogic('ANY'),
            null,
            inProcessStatus
        );
        TestOnboardingRulesFactory.create(true, rule, requirementOne, expectedCompleteStatus, 1);
        TestOnboardingRulesFactory.create(true, rule, requirementTwo, expectedCompleteStatus, 2);

        rule = queryRuleEngine(rule.Id);

        Map<Id, Onboarding_Requirement__c> reqByVpr = new Map<Id, Onboarding_Requirement__c>{
            requirementOne.Id => reqOne,
            requirementTwo.Id => reqTwo
        };

        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVpr);
        Test.stopTest();

        System.assertEquals(false, result, 'ANY logic should return false when no condition matches');
    }

    @isTest
    static void testEvaluateRule_CUSTOM() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(
            TestDataFactory.createAccount('Test Account', true),
            vendorProgram,
            true
        );

        Vendor_Program_Requirement__c requirementOne = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            true
        );
        Vendor_Program_Requirement__c requirementTwo = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            true
        );

        String completeStatus = getRequirementStatus('Complete');
        String nonMatchingStatus = getDifferentRequirementStatus(completeStatus);
        String inProcessStatus = getOnboardingStatus('In Process');
        String expectedCompleteStatus = getExpectedStatus(completeStatus);

        Onboarding_Requirement__c reqOne = TestOnboardingRequirementFactory.create(
            true,
            onboarding,
            requirementOne
        );
        reqOne.Status__c = completeStatus;
        update reqOne;

        Onboarding_Requirement__c reqTwo = TestOnboardingRequirementFactory.create(
            true,
            onboarding,
            requirementTwo
        );
        reqTwo.Status__c = nonMatchingStatus;
        update reqTwo;

        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        String customLogic = getEvaluationLogic('CUSTOM');
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(
            false,
            vendorProgramGroup,
            customLogic,
            null,
            inProcessStatus
        );
        if (customLogic == 'CUSTOM') {
            rule.Custom_Evaluation_Logic__c = '1';
        }
        insert rule;

        TestOnboardingRulesFactory.create(true, rule, requirementOne, expectedCompleteStatus, 1);
        TestOnboardingRulesFactory.create(true, rule, requirementTwo, expectedCompleteStatus, 2);

        rule = queryRuleEngine(rule.Id);

        Map<Id, Onboarding_Requirement__c> reqByVpr = new Map<Id, Onboarding_Requirement__c>{
            requirementOne.Id => reqOne,
            requirementTwo.Id => reqTwo
        };

        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVpr);
        Test.stopTest();

        Boolean expected = customLogic == 'CUSTOM' ? true : false;
        System.assertEquals(expected, result, 'CUSTOM logic should evaluate expression correctly');
    }

    @isTest
    static void testEvaluate_SimpleExpression() {
        Test.startTest();
        Boolean resultTrue = OnboardingRuleEvaluator.evaluate('true');
        Boolean resultFalse = OnboardingRuleEvaluator.evaluate('false');
        Test.stopTest();

        System.assertEquals(true, resultTrue, 'Should evaluate true expression');
        System.assertEquals(false, resultFalse, 'Should evaluate false expression');
    }

    @isTest
    static void testEvaluate_WithContext() {
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluate('true', new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(true, result, 'Should evaluate expression with context');
    }

    @isTest
    static void testEvaluateRule_MissingRequirement() {
        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        String inProcessStatus = getOnboardingStatus('In Process');
        String expectedCompleteStatus = getExpectedStatus(getRequirementStatus('Complete'));

        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(
            true,
            vendorProgramGroup,
            getEvaluationLogic('ALL'),
            null,
            inProcessStatus
        );
        Vendor_Program_Requirement__c requirement = TestVendorProgramRequirementFactory.create(
            true
        );
        TestOnboardingRulesFactory.create(true, rule, requirement, expectedCompleteStatus, 1);

        rule = queryRuleEngine(rule.Id);

        Map<Id, Onboarding_Requirement__c> reqByVpr = new Map<Id, Onboarding_Requirement__c>();

        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVpr);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false when requirement is missing');
    }

    @isTest
    static void testEvaluateRule_InvalidLogic() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Onboarding__c onboarding = TestOnboardingFactory.create(
            TestDataFactory.createAccount('Test Account', true),
            vendorProgram,
            true
        );

        Vendor_Program_Requirement__c requirement = TestVendorProgramRequirementFactory.create(
            vendorProgram,
            true,
            true
        );
        String completeStatus = getRequirementStatus('Complete');
        String expectedCompleteStatus = getExpectedStatus(completeStatus);
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(
            true,
            onboarding,
            requirement
        );
        req.Status__c = completeStatus;
        update req;

        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(true);
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(
            true,
            vendorProgramGroup,
            getEvaluationLogic('ALL'),
            null,
            getOnboardingStatus('In Process')
        );
        TestOnboardingRulesFactory.create(true, rule, requirement, expectedCompleteStatus, 1);
        rule = queryRuleEngine(rule.Id);
        rule.Evaluation_Logic__c = 'INVALID';

        Map<Id, Onboarding_Requirement__c> reqByVpr = new Map<Id, Onboarding_Requirement__c>{
            requirement.Id => req
        };

        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVpr);
        Test.stopTest();

        System.assertEquals(false, result, 'Invalid logic should return false');
    }
}
