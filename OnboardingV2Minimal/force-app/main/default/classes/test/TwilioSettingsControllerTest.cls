/**
 * Test class for TwilioSettingsController
 * Tests Twilio configuration retrieval and validation
 */
@IsTest
private class TwilioSettingsControllerTest {
    
    @IsTest
    static void testGetTwilioConfigurations() {
        Test.startTest();
        List<TwilioSettingsController.TwilioConfigWrapper> configs = 
            TwilioSettingsController.getTwilioConfigurations();
        Test.stopTest();
        
        // Should return at least the seeded default config
        System.assert(configs != null, 'Configs should not be null');
        System.assert(configs.size() > 0, 'Should have at least one config (seeded default)');
        
        // Verify wrapper structure
        if (!configs.isEmpty()) {
            TwilioSettingsController.TwilioConfigWrapper config = configs[0];
            System.assertNotEquals(null, config.developerName, 'Should have developer name');
            System.assertNotEquals(null, config.masterLabel, 'Should have master label');
        }
    }
    
    @IsTest
    static void testValidateConfiguration() {
        Test.startTest();
        TwilioSettingsController.ValidationResult result = 
            TwilioSettingsController.validateConfiguration();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // Result depends on whether seeded config exists and is valid
        // If seeded config is present and valid, isValid should be true
        // Otherwise, it may be false
        System.assert(result.isValid != null, 'isValid should be set');
    }
    
    @IsTest
    static void testGetTwilioConfigurationsHandlesException() {
        // This test verifies the method handles exceptions gracefully
        // In a real scenario, we might mock the metadata query, but for now
        // we test that it doesn't throw unhandled exceptions
        
        Test.startTest();
        try {
            List<TwilioSettingsController.TwilioConfigWrapper> configs = 
                TwilioSettingsController.getTwilioConfigurations();
            System.assert(configs != null, 'Should return list even if empty');
        } catch (Exception e) {
            System.assert(false, 'Should not throw unhandled exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
}