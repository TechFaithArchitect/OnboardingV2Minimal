@isTest
private class OnboardingAppActivationControllerTest {

    @isTest
    static void testActivate_Success() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(
            vendor,
            'Draft',
            false,
            null,
            true
        );

        // Act
        Test.startTest();
        OnboardingAppActivationService.activate(customization.Id, 'Vendor_Customization__c');
        Test.stopTest();

        // Assert
        System.assert(true, 'No exception was thrown');
    }

    @isTest
    static void testActivate_MissingParams_Throws() {
        // Act + Assert
        try {
            Test.startTest();
            OnboardingAppActivationController.activate(null, null);
            Test.stopTest();
            System.assert(false, 'Expected exception was not thrown');
        } catch (Exception e) {
            System.debug('Caught exception: ' + e.getMessage());
            System.assert(e != null, 'Exception should be thrown');
        }
    }
}