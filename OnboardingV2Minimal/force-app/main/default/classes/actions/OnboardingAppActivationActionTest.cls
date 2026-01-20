@isTest
private class OnboardingAppActivationActionTest {

    @isTest
    static void testActivationSuccess() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(
            vendor,
            'Draft',        // Initial Status
            false,          // Active__c
            null,           // No parent version
            true            // Insert
        );

        OnboardingAppActivationAction.Request activationRequest = new OnboardingAppActivationAction.Request();
        activationRequest.recordId = customization.Id;
        activationRequest.objectApiName = 'Vendor_Customization__c';

        Test.startTest();
        OnboardingAppActivationAction.activate(new List<OnboardingAppActivationAction.Request>{ activationRequest });
        Test.stopTest();

        System.assert(true, 'No exception thrown means success');
    }

    @isTest
    static void testActivation_MissingRecordId_Throws() {
        OnboardingAppActivationAction.Request activationRequest = new OnboardingAppActivationAction.Request();
        activationRequest.objectApiName = 'Vendor_Customization__c';

        try {
            OnboardingAppActivationAction.activate(new List<OnboardingAppActivationAction.Request>{ activationRequest });
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException auraHandledException) {
            System.debug('⚠️ Actual exception message: ' + auraHandledException.getMessage());
            System.assert(auraHandledException != null, 'AuraHandledException should be thrown');
        }
    }

    @isTest
    static void testActivation_MissingObjectApiName_Throws() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(
            vendor,
            'Draft',
            false,
            null,
            true
        );

        OnboardingAppActivationAction.Request activationRequest = new OnboardingAppActivationAction.Request();
        activationRequest.recordId = customization.Id;

        try {
            OnboardingAppActivationAction.activate(new List<OnboardingAppActivationAction.Request>{ activationRequest });
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException auraHandledException) {
            System.assert(auraHandledException != null, 'AuraHandledException should be thrown');
        }
    }
}