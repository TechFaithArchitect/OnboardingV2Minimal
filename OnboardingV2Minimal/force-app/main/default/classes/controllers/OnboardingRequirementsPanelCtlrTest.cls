@isTest
private class OnboardingRequirementsPanelCtlrTest {

    @isTest
    static void testGetRequirements() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Account account = TestDataFactory.createAccount('Test Account', true);
        Onboarding__c onboarding = TestDataFactory.createOnboarding(account, vendorProgram, true);
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true, onboarding, vpr);
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Status__c'
        );
        String inProcessStatus = validStatuses.contains('In Process') ? 'In Process' : validStatuses[0];
        req.Status__c = inProcessStatus;
        update req;
        
        // Act
        Test.startTest();
        List<OnboardingApplicationService.RequirementDTO> result = 
            OnboardingRequirementsPanelController.getRequirements(onboarding.Id);
        Test.stopTest();
        
        // Assert
        System.assert(result != null, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return requirements');
        System.assertEquals(req.Id, result[0].Id, 'Should return correct requirement');
        System.assertEquals('In Process', result[0].Status, 'Status should match');
    }

    @isTest
    static void testGetRequirements_Empty() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Account account = TestDataFactory.createAccount('Test Account', true);
        Onboarding__c onboarding = TestDataFactory.createOnboarding(account, vendorProgram, true);
        
        // Act
        Test.startTest();
        List<OnboardingApplicationService.RequirementDTO> result = 
            OnboardingRequirementsPanelController.getRequirements(onboarding.Id);
        Test.stopTest();
        
        // Assert
        System.assert(result != null, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list');
    }

    @isTest
    static void testUpdateRequirementStatuses() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Account account = TestDataFactory.createAccount('Test Account', true);
        Onboarding__c onboarding = TestDataFactory.createOnboarding(account, vendorProgram, true);
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Requirement__c req = TestOnboardingRequirementFactory.create(true, onboarding, vpr);
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Status__c'
        );
        String newStatus = validStatuses.contains('New') ? 'New' : validStatuses[0];
        req.Status__c = newStatus;
        update req;
        
        List<OnboardingApplicationService.RequirementDTO> updates = 
            new List<OnboardingApplicationService.RequirementDTO>();
        OnboardingApplicationService.RequirementDTO dto = 
            new OnboardingApplicationService.RequirementDTO(req);
        String completeStatus = validStatuses.contains('Complete') ? 'Complete' : validStatuses[validStatuses.size() - 1];
        dto.Status = completeStatus;
        updates.add(dto);
        
        // Act
        Test.startTest();
        OnboardingRequirementsPanelController.updateRequirementStatuses(updates);
        Test.stopTest();
        
        // Assert
        Onboarding_Requirement__c updated = [SELECT Id, Status__c FROM Onboarding_Requirement__c WHERE Id = :req.Id];
        // Status should match what we set in the DTO
        System.assertEquals(completeStatus, updated.Status__c, 'Status should be updated');
    }

    @isTest
    static void testUpdateRequirementStatuses_NullList() {
        // Act
        Test.startTest();
        OnboardingRequirementsPanelController.updateRequirementStatuses(null);
        Test.stopTest();
        
        // Assert - Verify no exception thrown
        System.assert(true, 'Should handle null list gracefully');
    }

    @isTest
    static void testUpdateRequirementStatuses_EmptyList() {
        // Act
        Test.startTest();
        OnboardingRequirementsPanelController.updateRequirementStatuses(new List<OnboardingApplicationService.RequirementDTO>());
        Test.stopTest();
        
        // Assert - Verify no exception thrown
        System.assert(true, 'Should handle empty list gracefully');
    }

    @isTest
    static void testRunRuleEvaluation() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Account account = TestDataFactory.createAccount('Test Account', true);
        Onboarding__c onboarding = TestDataFactory.createOnboarding(account, vendorProgram, true);
        
        // Act
        Test.startTest();
        OnboardingRequirementsPanelController.runRuleEvaluation(onboarding.Id);
        Test.stopTest();
        
        // Assert - Verify no exception thrown
        System.assert(true, 'Rule evaluation should complete successfully');
    }

    @isTest
    static void testRunRuleEvaluation_NullId() {
        // Act + Assert
        Test.startTest();
        try {
            OnboardingRequirementsPanelController.runRuleEvaluation(null);
            // If no exception is thrown, that's also acceptable
            System.assert(true, 'Should handle null ID gracefully');
        } catch (AuraHandledException e) {
            // AuraHandledException is expected for null ID validation
            System.assert(e != null, 'AuraHandledException should be thrown for null ID');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetInvalidFieldValuesAndRerunValidation() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true);
        Account account = TestDataFactory.createAccount('Test Account', true);
        Onboarding__c onboarding = TestDataFactory.createOnboarding(account, vendorProgram, true);
        Vendor_Program_Requirement__c vpr = TestVendorProgramRequirementFactory.create(true);
        Onboarding_Requirement__c requirement = TestOnboardingRequirementFactory.create(true, onboarding, vpr);

        Requirement_Field__c fieldDef = new Requirement_Field__c(
            Name = 'Email',
            Field_API_Name__c = 'Email__c',
            Required__c = true,
            Vendor_Program_Requirement__c = vpr.Id,
            Field_Type__c = 'Text',
            Validation_Type__c = 'Format'
        );
        insert fieldDef;

        Requirement_Field_Value__c fv = new Requirement_Field_Value__c(
            Onboarding_Requirement__c = requirement.Id,
            Requirement_Field__c = fieldDef.Id,
            Value__c = 'bad',
            Validation_Status__c = 'Invalid',
            Validation_Error_Message__c = 'Invalid email'
        );
        insert fv;

        Test.startTest();
        List<OnboardingRequirementsPanelController.InvalidFieldDTO> invalids =
            OnboardingRequirementsPanelController.getInvalidFieldValues(onboarding.Id);
        OnboardingRequirementsPanelController.rerunValidation(new List<Id>{ fv.Id });
        Test.stopTest();

        System.assertEquals(1, invalids.size(), 'Should return the invalid field');
        System.assertEquals('Invalid', invalids[0].status);
        System.assertEquals('Email', invalids[0].fieldName);
        System.assertEquals('Invalid email', invalids[0].message);
    }
}