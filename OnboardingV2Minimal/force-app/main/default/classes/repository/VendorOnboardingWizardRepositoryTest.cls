@isTest
private class VendorOnboardingWizardRepositoryTest {

    @isTest
    static void testInsertAndSearchVendor() {
        Vendor__c vendor = TestDataFactory.createVendor(true);

        Test.startTest();
        Id vendorId = VendorOnboardingWizardRepository.insertVendor(vendor);
        List<Vendor__c> result = VendorOnboardingWizardRepository.searchVendors(vendor.Name);
        Test.stopTest();

        System.assertNotEquals(null, vendorId, 'Vendor ID should not be null');
        System.assert(!result.isEmpty(), 'Vendor search should return results');
    }

    @isTest
    static void testInsertAndSearchVendorProgram() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);

        Test.startTest();
        Id programId = VendorOnboardingWizardRepository.insertVendorProgram(vendorProgram);
        // Query the record to get the auto-numbered Name field (since it's read-only)
        Vendor_Customization__c programWithName = [SELECT Name FROM Vendor_Customization__c WHERE Id = :programId LIMIT 1];
        List<Vendor_Customization__c> result = VendorOnboardingWizardRepository.searchVendorPrograms(programWithName.Name);
        Test.stopTest();

        System.assertNotEquals(null, programId, 'Program ID should not be null');
        System.assert(!result.isEmpty(), 'Vendor Program search should return results');
    }

    @isTest
    static void testInsertAndSearchVendorProgramGroup() {
        Vendor_Program_Group__c vendorProgramGroup = TestDataFactory.createVendorProgramGroup(true);

        Test.startTest();
        Id groupId = VendorOnboardingWizardRepository.insertVendorProgramGroup(vendorProgramGroup);
        // Search by the actual Name of the created group (factory creates it with "Program Group" prefix)
        List<Vendor_Program_Group__c> result = VendorOnboardingWizardRepository.searchVendorProgramGroups('Program Group');
        Test.stopTest();

        System.assertNotEquals(null, groupId, 'Group ID should not be null');
        System.assert(!result.isEmpty(), 'Group search should return results');
    }

    @isTest
    static void testLinkVendorProgramToGroups() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);
        Vendor_Program_Group__c vendorProgramGroup = TestDataFactory.createVendorProgramGroup(true);
        Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup = TestDataFactory.createVendorProgramRequirementGroup('Req Group', true);

        Test.startTest();
        VendorOnboardingWizardRepository.linkVendorProgramToGroups(
            vendorProgram.Id, vendor.Id, vendorProgramGroup.Id, vendorProgramRequirementGroup.Id
        );
        Test.stopTest();

        Vendor_Customization__c updatedVendorProgram = [
            SELECT Vendor__c, Vendor_Program_Group__c, Vendor_Program_Requirement_Group__c
            FROM Vendor_Customization__c
            WHERE Id = :vendorProgram.Id
        ];

        System.assertEquals(vendor.Id, updatedVendorProgram.Vendor__c);
        System.assertEquals(vendorProgramGroup.Id, updatedVendorProgram.Vendor_Program_Group__c);
        System.assertEquals(vendorProgramRequirementGroup.Id, updatedVendorProgram.Vendor_Program_Requirement_Group__c);
    }

    @isTest
    static void testInsertAndFetchRequirementSet() {
        Onboarding_Requirement_Set__c onboardingRequirementSet = new Onboarding_Requirement_Set__c(
            Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Onboarding_Requirement_Set__c.SObjectType,
                'Status__c'
            )
        );

        Test.startTest();
        Id setId = VendorOnboardingWizardRepository.insertOnboardingRequirementSet(onboardingRequirementSet);
        List<Onboarding_Requirement_Set__c> result = VendorOnboardingWizardRepository.fetchOnboardingRequirementSets();
        Test.stopTest();

        System.assertNotEquals(null, setId, 'Set ID should not be null');
        System.assert(!result.isEmpty(), 'Should return at least one requirement set');
    }

    @isTest
    static void testInsertAndFetchRequirementTemplate() {
        Onboarding_Requirement_Set__c onboardingRequirementSet = new Onboarding_Requirement_Set__c(
            Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Onboarding_Requirement_Set__c.SObjectType,
                'Status__c'
            )
        );
        insert onboardingRequirementSet;

        Vendor_Program_Onboarding_Req_Template__c vendorProgramOnboardingRequirementTemplate = TestDataFactory.createOnboardingRequirementTemplate(onboardingRequirementSet.Id, true);

        Test.startTest();
        List<Vendor_Program_Onboarding_Req_Template__c> result =
            VendorOnboardingWizardRepository.fetchOnboardingRequirementTemplates(onboardingRequirementSet.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one requirement template');
        System.assertEquals(vendorProgramOnboardingRequirementTemplate.Id, result[0].Id, 'Template IDs should match');
    }

    @isTest
    static void testAssignRequirementTemplatesToGroup() {
        Onboarding_Requirement_Set__c onboardingRequirementSet = new Onboarding_Requirement_Set__c(
            Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Onboarding_Requirement_Set__c.SObjectType,
                'Status__c'
            )
        );
        insert onboardingRequirementSet;

        Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup = TestDataFactory.createVendorProgramRequirementGroup('Req Group', true);
        Vendor_Program_Onboarding_Req_Template__c vendorProgramOnboardingRequirementTemplate = TestDataFactory.createOnboardingRequirementTemplate(onboardingRequirementSet.Id, true);

        Test.startTest();
        VendorOnboardingWizardRepository.assignRequirementTemplatesToRequirementGroup(vendorProgramRequirementGroup.Id, new List<Id>{ vendorProgramOnboardingRequirementTemplate.Id });
        Test.stopTest();

        Vendor_Program_Onboarding_Req_Template__c updated =
            [SELECT Category_Group__c FROM Vendor_Program_Onboarding_Req_Template__c WHERE Id = :vendorProgramOnboardingRequirementTemplate.Id];
        System.assertEquals(vendorProgramRequirementGroup.Id, updated.Category_Group__c, 'Template should be assigned to group');
    }

    @isTest
    static void testInsertAndSearchStatusRule() {
        Onboarding_Status_Rule__c onboardingStatusRule = TestDataFactory.createOnboardingStatusRule(true);

        Test.startTest();
        Id ruleId = VendorOnboardingWizardRepository.insertStatusRule(onboardingStatusRule);
        Onboarding_Status_Rule__c ruleWithName = [
            SELECT Name
            FROM Onboarding_Status_Rule__c
            WHERE Id = :ruleId
        ];
        List<Onboarding_Status_Rule__c> result = VendorOnboardingWizardRepository.searchStatusRules(ruleWithName.Name);
        Test.stopTest();

        System.assertNotEquals(null, ruleId, 'Rule ID should not be null');
        System.assert(result.size() > 0, 'Should return rule(s)');
    }

    @isTest
    static void testInsertAndSearchRecipientGroup() {
        Recipient_Group__c recipientGroup = new Recipient_Group__c(Name = 'Test Recipients');
        Id groupId = VendorOnboardingWizardRepository.insertRecipientGroup(recipientGroup);

        Test.startTest();
        List<Recipient_Group__c> result = VendorOnboardingWizardRepository.searchRecipientGroups('Test Recipients');
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return recipient group');
        System.assertEquals(groupId, result[0].Id);
    }

    @isTest
    static void testInsertAndSearchVendorProgramRecipientGroup() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(vendor, 'Draft', true, null, true);
        Recipient_Group__c recipientGroup = new Recipient_Group__c(Name = 'RecipientGroupTest');
        insert recipientGroup;

        Id linkId = VendorOnboardingWizardRepository.insertVendorProgramRecipientGroupLink(vendorProgram.Id, recipientGroup.Id);

        Test.startTest();
        List<Vendor_Program_Recipient_Group__c> result =
            VendorOnboardingWizardRepository.searchVendorProgramRecipientGroups('RecipientGroupTest');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return VPRG records');
        System.assertEquals(linkId, result[0].Id);
    }

    @isTest
    static void testUpsertOnboardingComponents() {
        List<String> componentApiNames = new List<String>{ 'vendorProgramOnboardingStepOne' };

        Test.startTest();
        VendorOnboardingWizardRepository.upsertOnboardingComponents(componentApiNames);
        Test.stopTest();

        List<Onboarding_Component_Library__c> records = [
            SELECT Component_API_Name__c
            FROM Onboarding_Component_Library__c
            WHERE Component_API_Name__c IN :componentApiNames
        ];

        System.assertEquals(1, records.size(), 'Should upsert 1 component');
    }
}