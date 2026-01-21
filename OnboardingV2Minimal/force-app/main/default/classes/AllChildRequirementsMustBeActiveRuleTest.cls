@isTest
private class AllChildRequirementsMustBeActiveRuleTest {

    @isTest
    static void testApply_WithAllActiveRequirements_ShouldPass() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        // Create active requirements
        Vendor_Program_Requirement__c req1 = TestDataFactory.createVendorProgramRequirement(
            vendorProgram, true, true
        );
        Vendor_Program_Requirement__c req2 = TestDataFactory.createVendorProgramRequirement(
            vendorProgram, true, true
        );

        AllChildRequirementsMustBeActiveRule rule = new AllChildRequirementsMustBeActiveRule();

        Test.startTest();
        // Should not throw exception
        rule.apply(vendorProgram.Id, 'Vendor_Customization__c');
        Test.stopTest();

        System.assert(true, 'Should pass when all requirements are active');
    }

    @isTest
    static void testApply_WithInactiveRequirement_ShouldThrow() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        // Create mixed active/inactive requirements
        Vendor_Program_Requirement__c activeReq = TestDataFactory.createVendorProgramRequirement(
            vendorProgram, true, true
        );
        Vendor_Program_Requirement__c inactiveReq = TestDataFactory.createVendorProgramRequirement(
            vendorProgram, false, true
        );

        AllChildRequirementsMustBeActiveRule rule = new AllChildRequirementsMustBeActiveRule();

        // Verify the inactive requirement exists and is linked correctly
        List<Vendor_Program_Requirement__c> verifyReqs = [
            SELECT Id, Active__c, Vendor_Program__c
            FROM Vendor_Program_Requirement__c
            WHERE Vendor_Program__c = :vendorProgram.Id
        ];
        System.assert(!verifyReqs.isEmpty(), 'Should have requirements linked to vendor program');
        Boolean hasInactive = false;
        for (Vendor_Program_Requirement__c req : verifyReqs) {
            if (!req.Active__c) {
                hasInactive = true;
                break;
            }
        }
        System.assert(hasInactive, 'Should have at least one inactive requirement');

        Test.startTest();
        try {
            rule.apply(vendorProgram.Id, 'Vendor_Customization__c');
            System.assert(false, 'Should throw exception for inactive requirement');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for inactive requirements');
        }
        Test.stopTest();
    }

    @isTest
    static void testApply_WithNoRequirements_ShouldPass() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        AllChildRequirementsMustBeActiveRule rule = new AllChildRequirementsMustBeActiveRule();

        Test.startTest();
        // Should not throw exception when no requirements exist
        rule.apply(vendorProgram.Id, 'Vendor_Customization__c');
        Test.stopTest();

        System.assert(true, 'Should pass when no requirements exist');
    }

    @isTest
    static void testApplyBulk_WithMixedActiveInactive_ShouldThrow() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c program1 = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );
        Vendor_Customization__c program2 = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        // Program 1: all active
        Vendor_Program_Requirement__c req1 = TestDataFactory.createVendorProgramRequirement(
            program1, true, true
        );

        // Program 2: has inactive requirement
        Vendor_Program_Requirement__c req2 = TestDataFactory.createVendorProgramRequirement(
            program2, false, true
        );

        // Verify the inactive requirement exists and is linked correctly
        List<Vendor_Program_Requirement__c> verifyReqs = [
            SELECT Id, Active__c, Vendor_Program__c
            FROM Vendor_Program_Requirement__c
            WHERE Vendor_Program__c = :program2.Id
        ];
        System.assert(!verifyReqs.isEmpty(), 'Program 2 should have requirements linked');
        Boolean hasInactive = false;
        for (Vendor_Program_Requirement__c req : verifyReqs) {
            if (!req.Active__c) {
                hasInactive = true;
                break;
            }
        }
        System.assert(hasInactive, 'Program 2 should have at least one inactive requirement');

        AllChildRequirementsMustBeActiveRule rule = new AllChildRequirementsMustBeActiveRule();

        Test.startTest();
        try {
            rule.applyBulk(new Set<Id>{ program1.Id, program2.Id }, 'Vendor_Customization__c');
            System.assert(false, 'Should throw exception for inactive requirement');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'AuraHandledException should be thrown for inactive requirements');
        }
        Test.stopTest();
    }

    @isTest
    static void testApplyBulk_WithEmptySet_ShouldNotThrow() {
        AllChildRequirementsMustBeActiveRule rule = new AllChildRequirementsMustBeActiveRule();

        Test.startTest();
        rule.applyBulk(new Set<Id>(), 'Vendor_Customization__c');
        rule.applyBulk(null, 'Vendor_Customization__c');
        Test.stopTest();

        System.assert(true, 'Should handle empty set gracefully');
    }
}