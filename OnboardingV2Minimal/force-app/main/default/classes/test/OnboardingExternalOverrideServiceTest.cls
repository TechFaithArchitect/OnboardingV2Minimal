@isTest
private class OnboardingExternalOverrideServiceTest {
    @isTest
    static void applyOverrideCreatesAudit() {
        Account acc = TestDataFactory.createAccount('Test Account', true);
        
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );

        Onboarding__c ob = TestDataFactory.createOnboarding(acc, vendorProgram, true);
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Onboarding_Status__c'
        );
        String setupCompleteStatus = validStatuses.contains('Setup Complete') ? 'Setup Complete' : validStatuses[0];
        ob.Onboarding_Status__c = setupCompleteStatus;
        update ob;

        OnboardingExternalOverrideService.OverrideRequest req = new OnboardingExternalOverrideService.OverrideRequest();
        req.onboardingId = ob.Id;
        req.reason = 'Re-onboard';
        req.allowedPrograms = new List<String>{ 'ProgramA', 'ProgramB' };
        req.sourceSystem = 'Axapta';
        req.requestId = 'REQ-123';

        Test.startTest();
        OnboardingExternalOverrideService.OverrideResponse resp = OnboardingExternalOverrideService.applyOverride(req);
        Test.stopTest();

        System.assertEquals(true, resp.success, 'Override should succeed');

        Onboarding__c updated = [
            SELECT External_Override_Enabled__c, External_Override_Programs__c,
                   External_Override_Request_ID__c, Previous_Status_Before_Override__c
            FROM Onboarding__c
            WHERE Id = :ob.Id
        ];
        System.assertEquals(true, updated.External_Override_Enabled__c, 'Override flag should be set');
        System.assert(updated.External_Override_Programs__c.contains('ProgramA'), 'Programs should be stored');
        System.assertEquals('REQ-123', updated.External_Override_Request_ID__c, 'Request ID should be stored');
        // Previous status should match what we set
        System.assertNotEquals(null, updated.Previous_Status_Before_Override__c, 'Previous status should be stored');

        List<Onboarding_External_Override_Log__c> logs = [
            SELECT Override_Action__c, Allowed_Programs__c, Source_System__c
            FROM Onboarding_External_Override_Log__c
            WHERE Onboarding__c = :ob.Id
        ];
        System.assertEquals(1, logs.size(), 'One audit log expected');
        System.assertEquals('Applied', logs[0].Override_Action__c);
        System.assert(logs[0].Allowed_Programs__c.contains('ProgramA'));
    }

    @isTest
    static void removeOverrideResetsFlagAndLogs() {
        Account acc = TestDataFactory.createAccount('Test Account 2', true);
        
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Onboarding_Status__c'
        );
        String setupCompleteStatus = validStatuses.contains('Setup Complete') ? 'Setup Complete' : validStatuses[0];
        
        Onboarding__c ob = TestDataFactory.createOnboarding(acc, vendorProgram, true);
        ob.Onboarding_Status__c = setupCompleteStatus;
        ob.External_Override_Enabled__c = true;
        ob.Previous_Status_Before_Override__c = setupCompleteStatus;
        update ob;

        Test.startTest();
        OnboardingExternalOverrideService.OverrideResponse resp = OnboardingExternalOverrideService.removeOverride(ob.Id, 'Done');
        Test.stopTest();

        System.assertEquals(true, resp.success);
        Onboarding__c updated = [
            SELECT External_Override_Enabled__c, External_Override_Source__c, External_Override_Programs__c
            FROM Onboarding__c WHERE Id = :ob.Id
        ];
        System.assertEquals(false, updated.External_Override_Enabled__c, 'Override flag should be cleared');
        System.assertEquals(null, updated.External_Override_Source__c);
        System.assertEquals(null, updated.External_Override_Programs__c);

        List<Onboarding_External_Override_Log__c> logs = [
            SELECT Override_Action__c, Reason__c
            FROM Onboarding_External_Override_Log__c
            WHERE Onboarding__c = :ob.Id
            AND Override_Action__c = 'Removed'
        ];
        System.assertEquals(1, logs.size(), 'One removal audit log expected');
        System.assertEquals('Done', logs[0].Reason__c);
    }
}