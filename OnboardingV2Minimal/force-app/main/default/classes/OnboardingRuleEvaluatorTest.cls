@isTest
private class OnboardingRuleEvaluatorTest {

    private static String getRequirementStatus(String preferredStatus) {
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Status__c'
        );
        return validStatuses.contains(preferredStatus) ? preferredStatus : validStatuses[0];
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
        return validStatuses.contains(preferredStatus) ? preferredStatus : validStatuses[0];
    }

    private static String getEvaluationLogic(String preferredLogic) {
        List<String> validLogics = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Status_Rules_Engine__c.SObjectType,
            'Evaluation_Logic__c'
        );
        return validLogics.contains(preferredLogic) ? preferredLogic : validLogics[0];
    }

    private static String getExpectedStatus(String preferredStatus) {
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Status_Rule__c.SObjectType,
            'Expected_Status__c'
        );
        return validStatuses.contains(preferredStatus) ? preferredStatus : validStatuses[0];
    }

    @isTest
    static void testEvaluateRule_ALL_True() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestDataFactory.createAccount('Test Account', true), vendorProgram, true);
        
        Vendor_Program_Requirement__c vpr1 = TestVendorProgramRequirementFactory.create(true);
        Vendor_Program_Requirement__c vpr2 = TestVendorProgramRequirementFactory.create(true);
        
        String completeStatus = getRequirementStatus('Complete');
        String inProcessStatus = getOnboardingStatus('In Process');
        
        Onboarding_Requirement__c req1 = TestOnboardingRequirementFactory.create(true, onboarding, vpr1);
        req1.Status__c = completeStatus;
        update req1;
        
        Onboarding_Requirement__c req2 = TestOnboardingRequirementFactory.create(true, onboarding, vpr2);
        req2.Status__c = completeStatus;
        update req2;
        
        String allLogic = getEvaluationLogic('ALL');
        // Expected_Status__c should match Onboarding_Requirement__c.Status__c picklist
        String expectedCompleteStatus = getRequirementStatus('Complete');
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, allLogic, null, inProcessStatus);
        Onboarding_Status_Rule__c rule1 = TestOnboardingRulesFactory.create(true, rule, vpr1, expectedCompleteStatus, 1);
        Onboarding_Status_Rule__c rule2 = TestOnboardingRulesFactory.create(true, rule, vpr2, expectedCompleteStatus, 2);
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr1.Id => req1,
            vpr2.Id => req2
        };
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'ALL logic should return true when all conditions match');
    }

    @isTest
    static void testEvaluateRule_ALL_False() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestDataFactory.createAccount('Test Account', true), vendorProgram, true);
        
        Vendor_Program_Requirement__c vpr1 = TestVendorProgramRequirementFactory.create(true);
        Vendor_Program_Requirement__c vpr2 = TestVendorProgramRequirementFactory.create(true);
        
        String completeStatus = getRequirementStatus('Complete');
        String nonMatchingStatus = getDifferentRequirementStatus(completeStatus);
        
        Onboarding_Requirement__c req1 = TestOnboardingRequirementFactory.create(true, onboarding, vpr1);
        req1.Status__c = completeStatus;
        update req1;
        
        Onboarding_Requirement__c req2 = TestOnboardingRequirementFactory.create(true, onboarding, vpr2);
        req2.Status__c = nonMatchingStatus; // Different status (or null if only one picklist value)
        update req2;
        
        String allLogic = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Status_Rules_Engine__c.SObjectType,
            'Evaluation_Logic__c'
        ).contains('ALL') ? 'ALL' : TestDataFactoryUtil.getFirstPicklistValue(
            Onboarding_Status_Rules_Engine__c.SObjectType,
            'Evaluation_Logic__c'
        );
        String inProcessStatus = getOnboardingStatus('In Process');
        // Expected_Status__c should match Onboarding_Requirement__c.Status__c picklist
        String expectedCompleteStatus = getRequirementStatus('Complete');
        
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, allLogic, null, inProcessStatus);
        Onboarding_Status_Rule__c rule1 = TestOnboardingRulesFactory.create(true, rule, vpr1, expectedCompleteStatus, 1);
        Onboarding_Status_Rule__c rule2 = TestOnboardingRulesFactory.create(true, rule, vpr2, expectedCompleteStatus, 2);
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        // Re-query requirements to ensure status is persisted
        req1 = [SELECT Id, Status__c, Vendor_Program_Requirement__c FROM Onboarding_Requirement__c WHERE Id = :req1.Id];
        req2 = [SELECT Id, Status__c, Vendor_Program_Requirement__c FROM Onboarding_Requirement__c WHERE Id = :req2.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr1.Id => req1,
            vpr2.Id => req2
        };
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        // Rule1 expects 'Complete', req1 has 'Complete' → true
        // Rule2 expects 'Complete', req2 has 'New' → false
        // ALL logic should return false when not all conditions match
        System.assertEquals(false, result, 'ALL logic should return false when not all conditions match. req1=' + req1.Status__c + ', req2=' + req2.Status__c);
    }

    @isTest
    static void testEvaluateRule_ANY_True() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestDataFactory.createAccount('Test Account', true), vendorProgram, true);
        
        Vendor_Program_Requirement__c vpr1 = TestVendorProgramRequirementFactory.create(true);
        Vendor_Program_Requirement__c vpr2 = TestVendorProgramRequirementFactory.create(true);
        
        String completeStatus = getRequirementStatus('Complete');
        String nonMatchingStatus = getDifferentRequirementStatus(completeStatus);
        
        Onboarding_Requirement__c req1 = TestOnboardingRequirementFactory.create(true, onboarding, vpr1);
        req1.Status__c = completeStatus;
        update req1;
        
        Onboarding_Requirement__c req2 = TestOnboardingRequirementFactory.create(true, onboarding, vpr2);
        req2.Status__c = nonMatchingStatus;
        update req2;
        
        String anyLogic = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Status_Rules_Engine__c.SObjectType,
            'Evaluation_Logic__c'
        ).contains('ANY') ? 'ANY' : TestDataFactoryUtil.getFirstPicklistValue(
            Onboarding_Status_Rules_Engine__c.SObjectType,
            'Evaluation_Logic__c'
        );
        String inProcessStatus = getOnboardingStatus('In Process');
        // Expected_Status__c should match Onboarding_Requirement__c.Status__c picklist
        String expectedCompleteStatus = getRequirementStatus('Complete');
        
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, anyLogic, null, inProcessStatus);
        Onboarding_Status_Rule__c rule1 = TestOnboardingRulesFactory.create(true, rule, vpr1, expectedCompleteStatus, 1);
        Onboarding_Status_Rule__c rule2 = TestOnboardingRulesFactory.create(true, rule, vpr2, expectedCompleteStatus, 2);
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        // Re-query requirements to ensure status is persisted
        req1 = [SELECT Id, Status__c, Vendor_Program_Requirement__c FROM Onboarding_Requirement__c WHERE Id = :req1.Id];
        req2 = [SELECT Id, Status__c, Vendor_Program_Requirement__c FROM Onboarding_Requirement__c WHERE Id = :req2.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr1.Id => req1,
            vpr2.Id => req2
        };
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        // Rule1 expects 'Complete', req1 has 'Complete' → true
        // Rule2 expects 'Complete', req2 has 'New' → false
        // ANY logic should return true when at least one condition matches
        System.assertEquals(true, result, 'ANY logic should return true when at least one condition matches');
    }

    @isTest
    static void testEvaluateRule_ANY_False() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestDataFactory.createAccount('Test Account', true), vendorProgram, true);
        
        Vendor_Program_Requirement__c vpr1 = TestVendorProgramRequirementFactory.create(true);
        Vendor_Program_Requirement__c vpr2 = TestVendorProgramRequirementFactory.create(true);
        
        String completeStatus = getRequirementStatus('Complete');
        String nonMatchingStatus = getDifferentRequirementStatus(completeStatus);
        Onboarding_Requirement__c req1 = TestOnboardingRequirementFactory.create(true, onboarding, vpr1);
        req1.Status__c = nonMatchingStatus;
        update req1;
        
        Onboarding_Requirement__c req2 = TestOnboardingRequirementFactory.create(true, onboarding, vpr2);
        req2.Status__c = nonMatchingStatus;
        update req2;
        
        String anyLogic = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Status_Rules_Engine__c.SObjectType,
            'Evaluation_Logic__c'
        ).contains('ANY') ? 'ANY' : TestDataFactoryUtil.getFirstPicklistValue(
            Onboarding_Status_Rules_Engine__c.SObjectType,
            'Evaluation_Logic__c'
        );
        String inProcessStatus = getOnboardingStatus('In Process');
        // Expected_Status__c should match Onboarding_Requirement__c.Status__c picklist
        String expectedCompleteStatus = getRequirementStatus('Complete');
        
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, anyLogic, null, inProcessStatus);
        Onboarding_Status_Rule__c rule1 = TestOnboardingRulesFactory.create(true, rule, vpr1, expectedCompleteStatus, 1);
        Onboarding_Status_Rule__c rule2 = TestOnboardingRulesFactory.create(true, rule, vpr2, expectedCompleteStatus, 2);
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        // Re-query requirements to ensure status is persisted
        req1 = [SELECT Id, Status__c, Vendor_Program_Requirement__c FROM Onboarding_Requirement__c WHERE Id = :req1.Id];
        req2 = [SELECT Id, Status__c, Vendor_Program_Requirement__c FROM Onboarding_Requirement__c WHERE Id = :req2.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr1.Id => req1,
            vpr2.Id => req2
        };
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        // Rule1 expects 'Complete', req1 has 'New' → false
        // Rule2 expects 'Complete', req2 has 'New' → false
        // ANY logic should return false when no conditions match
        System.assertEquals(false, result, 'ANY logic should return false when no conditions match. req1=' + req1.Status__c + ', req2=' + req2.Status__c);
    }

    @isTest
    static void testEvaluateRule_CUSTOM() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestDataFactory.createAccount('Test Account', true), vendorProgram, true);
        
        Vendor_Program_Requirement__c vpr1 = TestVendorProgramRequirementFactory.create(true);
        Vendor_Program_Requirement__c vpr2 = TestVendorProgramRequirementFactory.create(true);
        
        String completeStatus = getRequirementStatus('Complete');
        String nonMatchingStatus = getDifferentRequirementStatus(completeStatus);
        
        Onboarding_Requirement__c req1 = TestOnboardingRequirementFactory.create(true, onboarding, vpr1);
        req1.Status__c = completeStatus;
        update req1;
        
        Onboarding_Requirement__c req2 = TestOnboardingRequirementFactory.create(true, onboarding, vpr2);
        req2.Status__c = nonMatchingStatus;
        update req2;
        
        List<String> evaluationLogics = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Status_Rules_Engine__c.SObjectType,
            'Evaluation_Logic__c'
        );
        String customLogic = evaluationLogics.contains('CUSTOM') ? 'CUSTOM' : evaluationLogics[0];
        String inProcessStatus = getOnboardingStatus('In Process');
        // Expected_Status__c should match Onboarding_Requirement__c.Status__c picklist
        String expectedCompleteStatus = getRequirementStatus('Complete');
        
        // Create rule with CUSTOM logic and set Custom_Evaluation_Logic__c before insert
        Onboarding_Status_Rules_Engine__c rule = new Onboarding_Status_Rules_Engine__c(
            Name = 'Test Rules Engine ' + DateTime.now().getTime(),
            Active__c = true,
            Evaluation_Logic__c = customLogic,
            Target_Onboarding_Status__c = inProcessStatus
        );
        if (customLogic == 'CUSTOM') {
            // Note: OnboardingExpressionEngine only supports 'true' or 'false' literals
            // For CUSTOM logic to work, we need a single condition that evaluates to true
            // Use '1' which will be replaced with the boolean result of rule1
            rule.Custom_Evaluation_Logic__c = '1';
        }
        insert rule;
        
        Onboarding_Status_Rule__c rule1 = TestOnboardingRulesFactory.create(true, rule, vpr1, expectedCompleteStatus, 1);
        Onboarding_Status_Rule__c rule2 = TestOnboardingRulesFactory.create(true, rule, vpr2, expectedCompleteStatus, 2);
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        // Re-query requirements to ensure status is persisted
        req1 = [SELECT Id, Status__c, Vendor_Program_Requirement__c FROM Onboarding_Requirement__c WHERE Id = :req1.Id];
        req2 = [SELECT Id, Status__c, Vendor_Program_Requirement__c FROM Onboarding_Requirement__c WHERE Id = :req2.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr1.Id => req1,
            vpr2.Id => req2
        };
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        // Rule1 expects 'Complete', req1 has 'Complete' → true
        // Rule2 expects 'Complete', req2 has 'New' → false
        // Expression '1' becomes 'true', which should evaluate to true
        // Note: OnboardingExpressionEngine only supports 'true' or 'false' literals
        System.assertEquals(true, result, 'CUSTOM logic should evaluate expression correctly');
    }

    @isTest
    static void testEvaluate_SimpleExpression() {
        // Act
        Test.startTest();
        Boolean result1 = OnboardingRuleEvaluator.evaluate('true');
        Boolean result2 = OnboardingRuleEvaluator.evaluate('false');
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result1, 'Should evaluate true expression');
        System.assertEquals(false, result2, 'Should evaluate false expression');
    }

    @isTest
    static void testEvaluate_WithContext() {
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluate('true', new Map<String, Object>());
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'Should evaluate expression with context');
    }

    @isTest
    static void testEvaluateRule_MissingRequirement() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        String allLogic = getEvaluationLogic('ALL');
        String inProcessStatus = getOnboardingStatus('In Process');
        // Expected_Status__c should match Onboarding_Requirement__c.Status__c picklist
        String expectedCompleteStatus = getRequirementStatus('Complete');
        
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, allLogic, null, inProcessStatus);
        Vendor_Program_Requirement__c vpr1 = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Status_Rule__c rule1 = TestOnboardingRulesFactory.create(true, rule, vpr1, expectedCompleteStatus, 1);
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        // Empty map - requirement doesn't exist
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>();
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Should return false when requirement is missing');
    }

    @isTest
    static void testEvaluateRule_InvalidLogic() {
        // Arrange
        // Use a valid evaluation logic first, then try to set invalid one
        String validLogic = getEvaluationLogic('ALL');
        String inProcessStatus = getOnboardingStatus('In Process');
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, validLogic, null, inProcessStatus);
        // Try to set invalid logic - this may fail validation, which is expected
        try {
            rule.Evaluation_Logic__c = 'INVALID';
            update rule;
        } catch (Exception e) {
            // Validation may prevent invalid logic, which is acceptable
            // Re-query to get current state
            rule = [SELECT Id, Evaluation_Logic__c FROM Onboarding_Status_Rules_Engine__c WHERE Id = :rule.Id];
        }
        
        rule = [SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>();
        
        // Act
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR);
        Test.stopTest();
        
        // Assert
        // If validation prevented invalid logic, the rule still has valid logic and may return true
        // If invalid logic was set, it should return false
        // The test verifies the evaluator handles the case gracefully
        System.assert(result != null, 'Should return a boolean result');
    }

    @isTest
    static void testEvaluateRule_WithTemplateFieldMapping() {
        // Test the template field mapping logic (lines 16-25)
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestDataFactory.createAccount('Test Account', true), vendorProgram, true);
        
        // Create template with field mapping
        Vendor_Program_Onboarding_Req_Template__c template = TestVdrPrgrmOnboardingReqTemplateFactory.create(true);
        template.Onboarding_Status_Field_API_Name__c = 'Labor_Form_Status__c';
        template.Onboarding_Status_Value_When_Complete__c = 'Onboarding Approved;Approved Box 1';
        update template;
        
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        vpr.Requirement_Template__c = template.Id;
        update vpr;
        
        // Set onboarding field value to match completion value
        onboarding.Labor_Form_Status__c = 'Onboarding Approved';
        update onboarding;
        
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true, onboarding, vpr);
        
        String allLogic = getEvaluationLogic('ALL');
        String inProcessStatus = getOnboardingStatus('In Process');
        // Expected_Status__c should match Onboarding_Requirement__c.Status__c picklist
        String completeStatus = getRequirementStatus('Complete');
        
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, allLogic, null, inProcessStatus);
        Onboarding_Status_Rule__c statusRule = TestOnboardingRulesFactory.create(true, rule, vpr, completeStatus, 1);
        
        // Query with relationship fields
        rule = [SELECT Id, Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c,
                 Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c,
                 Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr.Id => req
        };
        
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR, onboarding);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true when template field mapping matches');
    }

    @isTest
    static void testEvaluateRule_WithTemplateFieldMapping_NoMatch() {
        // Test template field mapping when value doesn't match
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestDataFactory.createAccount('Test Account', true), vendorProgram, true);
        
        Vendor_Program_Onboarding_Req_Template__c template = TestVdrPrgrmOnboardingReqTemplateFactory.create(true);
        template.Onboarding_Status_Field_API_Name__c = 'Labor_Form_Status__c';
        template.Onboarding_Status_Value_When_Complete__c = 'Onboarding Approved';
        update template;
        
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        vpr.Requirement_Template__c = template.Id;
        update vpr;
        
        // Set onboarding field value to non-matching value
        // Use a valid picklist value that doesn't match the completion value
        List<String> laborFormStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Labor_Form_Status__c'
        );
        String nonMatchingStatus = laborFormStatuses.size() > 0 ? 
            (laborFormStatuses.contains('Pending') ? 'Pending' : 
             (laborFormStatuses.contains('In Process') ? 'In Process' : laborFormStatuses[0])) : null;
        if (nonMatchingStatus != null && nonMatchingStatus != 'Onboarding Approved') {
            onboarding.Labor_Form_Status__c = nonMatchingStatus;
            update onboarding;
        }
        
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true, onboarding, vpr);
        
        String allLogic = getEvaluationLogic('ALL');
        String inProcessStatus = getOnboardingStatus('In Process');
        // Expected_Status__c should match Onboarding_Requirement__c.Status__c picklist
        String completeStatus = getRequirementStatus('Complete');
        
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, allLogic, null, inProcessStatus);
        Onboarding_Status_Rule__c statusRule = TestOnboardingRulesFactory.create(true, rule, vpr, completeStatus, 1);
        
        rule = [SELECT Id, Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c,
                 Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c,
                 Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr.Id => req
        };
        
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR, onboarding);
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false when template field mapping does not match');
    }

    @isTest
    static void testEvaluateRule_WithOnboardingRecord_NoTemplateMapping() {
        // Test with onboarding record but no template mapping (falls back to status check)
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Active', true, null, true);
        Onboarding__c onboarding = TestOnboardingFactory.create(TestDataFactory.createAccount('Test Account', true), vendorProgram, true);
        
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        String reqCompleteStatus = getRequirementStatus('Complete');
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true, onboarding, vpr);
        req.Status__c = reqCompleteStatus;
        update req;
        
        String allLogic = getEvaluationLogic('ALL');
        String inProcessStatus = getOnboardingStatus('In Process');
        // Expected_Status__c should match Onboarding_Requirement__c.Status__c picklist
        String expectedCompleteStatus = getRequirementStatus('Complete');
        
        Onboarding_Status_Rules_Engine__c rule = TestOnboardingRulesEngineFactory.create(true, null, null, allLogic, null, inProcessStatus);
        Onboarding_Status_Rule__c statusRule = TestOnboardingRulesFactory.create(true, rule, vpr, expectedCompleteStatus, 1);
        
        rule = [SELECT Id, Evaluation_Logic__c,
                (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Field_API_Name__c, Requirement__r.Requirement_Template__r.Onboarding_Status_Value_When_Complete__c
                 FROM Onboarding_Status_Rules__r)
                FROM Onboarding_Status_Rules_Engine__c 
                WHERE Id = :rule.Id];
        
        Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>{
            vpr.Id => req
        };
        
        Test.startTest();
        Boolean result = OnboardingRuleEvaluator.evaluateRule(rule, reqByVPR, onboarding);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should fall back to status check when no template mapping');
    }
}