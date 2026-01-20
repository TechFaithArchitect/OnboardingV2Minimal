/**
 * Test class for TwilioSMSProvider
 * Tests Twilio SMS sending with HttpCalloutMock
 */
@IsTest
private class TwilioSMSProviderTest {
    
    @TestSetup
    static void setupTestData() {
        Account acct = TestDataFactory.createAccount('Test', true);
        Contact con = TestDataFactory.createContact('Test', 'User', true, acct);
        con.MobilePhone = '+15551234567';
        update con;
    }
    
    @IsTest
    static void testSendSMSWithValidConfig() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        TwilioSMSProvider provider = new TwilioSMSProvider();
        
        Map<String, Object> providerConfig = new Map<String, Object>{
            'fromPhoneNumber' => '+15559876543',
            'accountSid' => 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
            'namedCredential' => 'Twilio_API'
        };
        
        Test.setMock(HttpCalloutMock.class, new TwilioHttpCalloutMock(true));
        
        Test.startTest();
        String messageSid = provider.sendSMS(con.Id, 'Test message', providerConfig);
        Test.stopTest();
        
        System.assertNotEquals(null, messageSid, 'Should return message SID');
        System.assert(messageSid.startsWith('SM') || messageSid.startsWith('TWILIO-'), 
                     'Should return valid message identifier');
    }
    
    @IsTest
    static void testSendSMSWithMissingFromPhone() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        TwilioSMSProvider provider = new TwilioSMSProvider();
        
        Map<String, Object> providerConfig = new Map<String, Object>{
            'accountSid' => 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
        };
        
        Test.startTest();
        try {
            provider.sendSMS(con.Id, 'Test message', providerConfig);
            System.assert(false, 'Should throw exception');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('From phone number'), 
                         'Should fail with from phone validation');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSendSMSWithMissingContact() {
        TwilioSMSProvider provider = new TwilioSMSProvider();
        
        Map<String, Object> providerConfig = new Map<String, Object>{
            'fromPhoneNumber' => '+15559876543',
            'accountSid' => 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
        };
        
        Test.startTest();
        try {
            provider.sendSMS(null, 'Test message', providerConfig);
            System.assert(false, 'Should throw exception');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('required'));
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testHasActiveMessagingEndpoint() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        TwilioSMSProvider provider = new TwilioSMSProvider();
        
        Map<String, Object> providerConfig = new Map<String, Object>();
        
        Test.startTest();
        Boolean hasEndpoint = provider.hasActiveMessagingEndpoint(con.Id, providerConfig);
        Test.stopTest();
        
        System.assertEquals(true, hasEndpoint, 'Contact with phone should have endpoint');
    }
    
    @IsTest
    static void testValidateConfig() {
        TwilioSMSProvider provider = new TwilioSMSProvider();
        
        Map<String, Object> validConfig = new Map<String, Object>{
            'fromPhoneNumber' => '+15559876543'
        };
        
        Test.startTest();
        String error = provider.validateConfig(validConfig);
        Test.stopTest();
        
        System.assertEquals(null, error, 'Valid config should return null error');
    }
    
    @IsTest
    static void testValidateConfigWithMissingFromPhone() {
        TwilioSMSProvider provider = new TwilioSMSProvider();
        
        Map<String, Object> invalidConfig = new Map<String, Object>();
        
        Test.startTest();
        String error = provider.validateConfig(invalidConfig);
        Test.stopTest();
        
        System.assertNotEquals(null, error, 'Invalid config should return error');
        System.assert(error.contains('From phone number'), 'Error should mention from phone');
    }
    
    /**
     * Mock class for Twilio HTTP callouts
     */
    private class TwilioHttpCalloutMock implements HttpCalloutMock {
        private Boolean success;
        
        public TwilioHttpCalloutMock(Boolean success) {
            this.success = success;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (success) {
                res.setStatusCode(201);
                res.setBody('{"sid": "SM1234567890abcdef", "status": "queued", "to": "+15551234567", "from": "+15559876543"}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"code": 21211, "message": "Invalid \'To\' Phone Number"}');
            }
            
            return res;
        }
    }
}