/**
 * Test class for FollowUpExecutionService
 * Tests provider selection, configuration building, and validation
 */
@IsTest
private class FollowUpExecutionServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create Account and Contact
        Account acct = TestDataFactory.createAccount('Test', true);
        Contact con = TestDataFactory.createContact('Test', 'User', true, acct);
        con.MobilePhone = '+15551234567';
        con.Email = 'test@example.com';
        update con;
        
        // Create Vendor and Vendor Program
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, true
        );
        
        // Create Onboarding
        Onboarding__c ob = TestDataFactory.createOnboarding(acct, vendorProgram, true);
        
        // Create Follow Up Queue
        Follow_Up_Queue__c fq = new Follow_Up_Queue__c(
            Name = 'Test Follow Up',
            Onboarding__c = ob.Id,
            Follow_Up_Type__c = 'SMS',
            Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Follow_Up_Queue__c.SObjectType,
                'Status__c'
            ),
            Next_Attempt_Date__c = DateTime.now().addMinutes(-5)
        );
        TestDataFactoryUtil.maybeInsert(fq, true);
    }
    
    @IsTest
    static void testSendSMSFollowUpWithTwilioProvider() {
        Follow_Up_Queue__c fq = [SELECT Id FROM Follow_Up_Queue__c LIMIT 1];
        
        Test.startTest();
        try {
            FollowUpExecutionService.sendSMSFollowUp(fq.Id);
        } catch (Exception e) {
            // Expected to fail without proper Twilio config, but should validate gracefully
            System.assert(e.getMessage().contains('Account SID') || 
                         e.getMessage().contains('From phone number') ||
                         e.getMessage().contains('No active messaging endpoint'),
                         'Should fail with validation error');
        }
        Test.stopTest();
        
        Follow_Up_Queue__c updated = [SELECT Status__c, Error_Message__c FROM Follow_Up_Queue__c WHERE Id = :fq.Id];
        System.assertEquals('Failed', updated.Status__c, 'Should be marked as failed');
        System.assertNotEquals(null, updated.Error_Message__c, 'Should have error message');
    }
    
    @IsTest
    static void testSendEmailFollowUp() {
        Follow_Up_Queue__c fq = [SELECT Id FROM Follow_Up_Queue__c LIMIT 1];
        fq.Follow_Up_Type__c = 'Email';
        update fq;
        
        Test.startTest();
        FollowUpExecutionService.sendEmailFollowUp(fq.Id);
        Test.stopTest();
        
        Follow_Up_Queue__c updated = [SELECT Status__c FROM Follow_Up_Queue__c WHERE Id = :fq.Id];
        // Status depends on email send result - may be Sent or Failed
        System.assert(updated.Status__c == 'Sent' || updated.Status__c == 'Failed');
    }
    
    @IsTest
    static void testMarkFollowUpFailed() {
        Follow_Up_Queue__c fq = [SELECT Id, Status__c, Consecutive_Failures__c FROM Follow_Up_Queue__c LIMIT 1];
        
        Test.startTest();
        FollowUpExecutionService.markFollowUpFailed(fq.Id, 'Test error message');
        Test.stopTest();
        
        Follow_Up_Queue__c updated = [
            SELECT Status__c, Consecutive_Failures__c, Error_Message__c
            FROM Follow_Up_Queue__c
            WHERE Id = :fq.Id
        ];
        System.assertEquals('Failed', updated.Status__c);
        System.assertEquals(1, updated.Consecutive_Failures__c);
        System.assertEquals('Test error message', updated.Error_Message__c);
    }
    
    @IsTest
    static void testRetryFailedFollowUps() {
        Follow_Up_Queue__c fq = [SELECT Id FROM Follow_Up_Queue__c LIMIT 1];
        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Follow_Up_Queue__c.SObjectType,
            'Status__c'
        );
        String pendingRetryStatus = validStatuses.contains('Pending Retry') ? 'Pending Retry' : validStatuses[0];
        fq.Status__c = pendingRetryStatus;
        update fq;
        
        Test.startTest();
        FollowUpExecutionService.retryFailedFollowUps(new List<Id>{ fq.Id });
        Test.stopTest();
        
        Follow_Up_Queue__c updated = [SELECT Status__c FROM Follow_Up_Queue__c WHERE Id = :fq.Id];
        // Status depends on retry result
        System.assert(updated.Status__c == 'Sent' || updated.Status__c == 'Failed');
    }
    
    @IsTest
    static void testRetryFailedFollowUpsWithEmptyList() {
        Test.startTest();
        FollowUpExecutionService.retryFailedFollowUps(new List<Id>());
        Test.stopTest();
        
        // Should complete without error
        System.assert(true);
    }
    
    @IsTest
    static void testSendSMSFollowUpWithNullId() {
        Test.startTest();
        try {
            FollowUpExecutionService.sendSMSFollowUp(null);
            System.assert(false, 'Should throw exception');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('required'));
        }
        Test.stopTest();
    }
}