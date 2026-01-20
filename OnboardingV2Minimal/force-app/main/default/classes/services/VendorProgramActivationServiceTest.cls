@isTest
private class VendorProgramActivationServiceTest {
    @isTest 
    static void testFlowAction() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        
        Vendor_Customization__c rootCustomization = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, null, true
        );

        Vendor_Customization__c draft = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, rootCustomization.Id, true
        );

        OnboardingAppActivationAction.Request activationRequest = new OnboardingAppActivationAction.Request();
        activationRequest.recordId = draft.Id;
        activationRequest.objectApiName = 'Vendor_Customization__c';

        Test.startTest();
        OnboardingAppActivationAction.activate(new List<OnboardingAppActivationAction.Request>{ activationRequest });
        Test.stopTest();

        Vendor_Customization__c result = [
            SELECT Status__c, Active__c 
            FROM Vendor_Customization__c 
            WHERE Id = :draft.Id
        ];
        String expectedActiveStatus = PicklistHelper.getValidPicklistValue(
            'Vendor_Customization__c',
            'Status__c',
            'Active'
        );
        if (String.isNotBlank(expectedActiveStatus)) {
            System.assertEquals(expectedActiveStatus, result.Status__c);
        }
        System.assertEquals(true, result.Active__c);
    }

    @isTest 
    static void testAlreadyActive() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c rootCustomization = TestDataFactory.createVendorCustomization(vendor, 'Draft', false, null, true);

        Vendor_Customization__c active = TestDataFactory.createVendorCustomization(vendor, 'Active', true, rootCustomization.Id, true);

        active = [
            SELECT Id, Status__c, Active__c 
            FROM Vendor_Customization__c 
            WHERE Id = :active.Id
        ];

        String expectedActiveStatus = PicklistHelper.getValidPicklistValue(
            'Vendor_Customization__c',
            'Status__c',
            'Active'
        );
        if (String.isNotBlank(expectedActiveStatus)) {
            System.assertEquals(expectedActiveStatus, active.Status__c);
        }
        System.assertEquals(true, active.Active__c);

        OnboardingAppActivationAction.Request activationRequest = new OnboardingAppActivationAction.Request();
        activationRequest.recordId = active.Id;
        activationRequest.objectApiName = 'Vendor_Customization__c';

        Boolean caught = false;

        Test.startTest();
        try {
            OnboardingAppActivationAction.activate(new List<OnboardingAppActivationAction.Request>{ activationRequest });
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException auraHandledException) {
            caught = true;
            System.assert(auraHandledException != null, 'AuraHandledException should be thrown');
        }
        Test.stopTest();

        System.assert(caught, 'AuraHandledException should have been thrown.');
    }

    @isTest 
    static void testSiblingDeactivation() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c rootCustomization = TestDataFactory.createVendorCustomization(vendor, 'Draft', false, null, true);

        // Active sibling (committed without startTest)
        Vendor_Customization__c sibling1 = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, rootCustomization.Id, true
        );

        // Draft sibling to activate
        Vendor_Customization__c sibling2 = TestDataFactory.createVendorCustomization(
            vendor, 'Draft', false, rootCustomization.Id, true
        );

        OnboardingAppActivationAction.Request activationRequest = new OnboardingAppActivationAction.Request();
        activationRequest.recordId = sibling2.Id;
        activationRequest.objectApiName = 'Vendor_Customization__c';

        Test.startTest();
        OnboardingAppActivationAction.activate(new List<OnboardingAppActivationAction.Request>{ activationRequest });
        Test.stopTest();

        Vendor_Customization__c updatedSibling1 = [
            SELECT Id, Active__c FROM Vendor_Customization__c WHERE Id = :sibling1.Id
        ];
        Vendor_Customization__c updatedSibling2 = [
            SELECT Id, Active__c FROM Vendor_Customization__c WHERE Id = :sibling2.Id
        ];

        System.assertEquals(false, updatedSibling1.Active__c);
        System.assertEquals(true, updatedSibling2.Active__c);
    }

    @isTest 
    static void testNullIdThrows() {
        OnboardingAppActivationAction.Request activationRequest = new OnboardingAppActivationAction.Request();
        activationRequest.recordId = null;
        activationRequest.objectApiName = 'Vendor_Customization__c';

        Boolean exceptionThrown = false;

        try {
            OnboardingAppActivationAction.activate(new List<OnboardingAppActivationAction.Request>{ activationRequest });
        } catch (AuraHandledException auraHandledException) {
            System.assert(auraHandledException.getMessage().contains('Script-thrown exception'));
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Expected AuraHandledException not thrown');
    }

    @isTest
    static void testRootActiveVersionWithoutChildren_isAllowed() {
        Vendor__c vendor = TestDataFactory.createVendor(true);

        Vendor_Customization__c rootActive = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, false
        );

        Test.startTest();
        insert rootActive;
        Test.stopTest();

        Vendor_Customization__c inserted = [
            SELECT Id, Status__c, Active__c, Previous_Version__c 
            FROM Vendor_Customization__c 
            WHERE Id = :rootActive.Id
        ];

        System.assertEquals(true, inserted.Active__c, 'Root active version should be allowed');
        System.assertEquals(null, inserted.Previous_Version__c, 'Root should not have a parent');
    }

    @isTest
    static void testMultipleActiveChildrenInSameLineage_shouldFail() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c parent = TestDataFactory.createVendorCustomization(vendor, 'Draft', false, null, true);

        Vendor_Customization__c activeVendorCustomization1 = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, parent.Id, false
        );

        Vendor_Customization__c activeVendorCustomization2 = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, parent.Id, false
        );

        Test.startTest();
        try {
            insert new List<Vendor_Customization__c>{ activeVendorCustomization1, activeVendorCustomization2 };
            System.assert(false, 'Expected DMLException due to multiple active siblings');
        } catch (DmlException dmlException) {
            System.assert(dmlException.getDmlMessage(0).contains('Only one active version is allowed per record lineage.'));
        }
        Test.stopTest();
    }

    @isTest
    static void testNonDraftWithNoParentOrChildren_shouldStayNull() {
        Vendor__c vendor = TestDataFactory.createVendor(true);

        Vendor_Customization__c orphan = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, false
        );

        Test.startTest();
        insert orphan;
        Test.stopTest();

        orphan = [
            SELECT Id, Previous_Version__c
            FROM Vendor_Customization__c
            WHERE Id = :orphan.Id
        ];

        System.assertEquals(null, orphan.Previous_Version__c, 'Root orphan should not link to itself');
    }
}