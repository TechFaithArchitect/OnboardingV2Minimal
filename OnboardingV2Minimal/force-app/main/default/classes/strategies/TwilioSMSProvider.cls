/**
 * SMS provider strategy for Twilio
 * Uses Twilio REST API via Named Credential
 */
public with sharing class TwilioSMSProvider implements SMSProviderStrategy {
    
    private static final String TWILIO_API_VERSION = '2010-04-01';
    private static final String DEFAULT_NAMED_CREDENTIAL = 'Twilio_API'; // Default Named Credential name
    
    /**
     * Get Named Credential name from configuration or use default
     */
    private String getNamedCredential(Map<String, Object> providerConfig) {
        String namedCredential = (String)providerConfig.get('namedCredential');
        if (String.isNotBlank(namedCredential)) {
            return namedCredential;
        }
        
        // Try to get from Twilio_Configuration__mdt
        try {
            List<Twilio_Configuration__mdt> configs = [
                SELECT Named_Credential__c
                FROM Twilio_Configuration__mdt
                WHERE Active__c = true
                LIMIT 1
            ];
            if (!configs.isEmpty() && String.isNotBlank(configs[0].Named_Credential__c)) {
                return configs[0].Named_Credential__c;
            }
        } catch (Exception ex) {
            // Twilio_Configuration__mdt may not exist - use default
            System.debug('Could not get Named Credential from Twilio_Configuration__mdt: ' + ex.getMessage());
        }
        
        return DEFAULT_NAMED_CREDENTIAL;
    }
    
    /**
     * Get Account SID from configuration or Named Credential
     * NOTE: Named Credential username should be the Account SID
     * For now, returns null if not in config (will cause error - this is expected)
     * TODO: Extract Account SID from Named Credential username if possible
     */
    private String getAccountSidFromConfig(Map<String, Object> providerConfig) {
        // Account SID should be provided in providerConfig or stored in Named Credential username
        // Since we can't easily extract from Named Credential in Apex, require it in config
        // Alternatively, can be stored in Twilio_Configuration__mdt if needed
        return null;
    }
    
    /**
     * Send SMS via Twilio API
     * @param contactId Contact to send message to
     * @param messageContent Message text
     * @param providerConfig Map containing:
     *   - fromPhoneNumber (String) - Twilio phone number to send from
     *   - accountSid (String, optional) - Twilio Account SID (if not in Named Credential)
     *   - authToken (String, optional) - Twilio Auth Token (if not in Named Credential)
     * @return String identifier for tracking (Twilio Message SID)
     */
    public String sendSMS(Id contactId, String messageContent, Map<String, Object> providerConfig) {
        if (contactId == null || String.isBlank(messageContent)) {
            throw new IllegalArgumentException('Contact ID and message content are required');
        }
        
        // Get Contact phone number
        Contact contact = getContactWithPhone(contactId);
        if (contact == null) {
            throw new FollowUpMessagingService.FollowUpMessagingException('Contact not found or has no phone number');
        }
        
        String toPhoneNumber = contact.MobilePhone != null ? contact.MobilePhone : contact.Phone;
        if (String.isBlank(toPhoneNumber)) {
            throw new FollowUpMessagingService.FollowUpMessagingException('Contact has no phone number');
        }
        
        // Normalize phone number (remove non-digits, ensure +1 prefix for US)
        toPhoneNumber = normalizePhoneNumber(toPhoneNumber);
        
        // Get from phone number from config
        String fromPhoneNumber = (String)providerConfig.get('fromPhoneNumber');
        if (String.isBlank(fromPhoneNumber)) {
            throw new IllegalArgumentException('From phone number is required for Twilio');
        }
        fromPhoneNumber = normalizePhoneNumber(fromPhoneNumber);
        
        // Make Twilio API callout
        try {
            // Get Account SID from config if provided
            String accountSid = (String)providerConfig.get('accountSid');
            String response = makeTwilioCallout(toPhoneNumber, fromPhoneNumber, messageContent, accountSid, providerConfig);
            
            // Parse response to get Message SID
            String messageSid = extractMessageSid(response);
            
            return messageSid != null ? messageSid : 'TWILIO-' + String.valueOf(DateTime.now().getTime());
        } catch (Exception ex) {
            throw new FollowUpMessagingService.FollowUpMessagingException(
                'Error sending SMS via Twilio: ' + ex.getMessage()
            );
        }
    }
    
    /**
     * Make HTTP callout to Twilio API
     * Twilio API format: https://api.twilio.com/2010-04-01/Accounts/{AccountSid}/Messages.json
     * Named Credential should be configured with:
     *   - URL: https://api.twilio.com
     *   - Identity Type: Named Principal
     *   - Authentication: Username/Password (Account SID / Auth Token)
     * 
     * NOTE: If Account SID is provided in providerConfig, it will be used in the URL path.
     * Otherwise, the Named Credential username (which should be the Account SID) will be used.
     */
    private String makeTwilioCallout(String toPhoneNumber, String fromPhoneNumber, String messageContent, String accountSid, Map<String, Object> providerConfig) {
        HttpRequest httpRequest = new HttpRequest();
        
        // Get Named Credential name (from config or default)
        String namedCredential = getNamedCredential(providerConfig);
        
        // Build endpoint
        // Twilio API: https://api.twilio.com/2010-04-01/Accounts/{AccountSid}/Messages.json
        // Named Credential should be configured with URL: https://api.twilio.com
        // Named Credential username should be Account SID, password should be Auth Token
        
        // Build endpoint path
        // Twilio requires Account SID in the URL path
        // If accountSid is provided in config, use it; otherwise we need to get it from Named Credential
        // Note: Salesforce Named Credentials don't support merge fields in URL path, so accountSid should be provided
        if (String.isBlank(accountSid)) {
            throw new IllegalArgumentException('Account SID must be provided in providerConfig.accountSid for Twilio API calls. Named Credential username should be the Account SID.');
        }
        
        String endpoint = 'callout:' + namedCredential + '/' + TWILIO_API_VERSION + '/Accounts/' + accountSid + '/Messages.json';
        
        httpRequest.setEndpoint(endpoint);
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        // Build form data
        String body = 'To=' + EncodingUtil.urlEncode(toPhoneNumber, 'UTF-8') +
                     '&From=' + EncodingUtil.urlEncode(fromPhoneNumber, 'UTF-8') +
                     '&Body=' + EncodingUtil.urlEncode(messageContent, 'UTF-8');
        httpRequest.setBody(body);
        
        Http http = new Http();
        HttpResponse httpResponse = http.send(httpRequest);
        
        if (httpResponse.getStatusCode() != 200 && httpResponse.getStatusCode() != 201) {
            throw new CalloutException('Twilio API error: ' + httpResponse.getStatusCode() + ' - ' + httpResponse.getBody());
        }
        
        return httpResponse.getBody();
    }
    
    /**
     * Extract Message SID from Twilio API response
     */
    private String extractMessageSid(String response) {
        // Parse JSON response: {"sid": "SM...", ...}
        try {
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response);
            return (String)responseMap.get('sid');
        } catch (Exception ex) {
            System.debug('Error parsing Twilio response: ' + ex.getMessage());
            return null;
        }
    }
    
    /**
     * Normalize phone number format
     * Ensures +1 prefix for US numbers
     */
    private String normalizePhoneNumber(String phoneNumber) {
        if (String.isBlank(phoneNumber)) {
            return phoneNumber;
        }
        
        // Remove all non-digit characters
        String digits = phoneNumber.replaceAll('[^0-9]', '');
        
        // If 10 digits, assume US and add +1
        if (digits.length() == 10) {
            return '+1' + digits;
        }
        
        // If 11 digits and starts with 1, add +
        if (digits.length() == 11 && digits.startsWith('1')) {
            return '+' + digits;
        }
        
        // If already has +, return as is
        if (phoneNumber.startsWith('+')) {
            return phoneNumber;
        }
        
        // Otherwise, add + prefix
        return '+' + digits;
    }
    
    /**
     * Get Contact with phone number
     */
    private Contact getContactWithPhone(Id contactId) {
        List<Contact> contacts = [
            SELECT Id, Phone, MobilePhone
            FROM Contact
            WHERE Id = :contactId
              AND (Phone != null OR MobilePhone != null)
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }
    
    /**
     * Check if Contact has active messaging endpoint (phone number) for Twilio
     * @param contactId Contact ID
     * @param providerConfig Map (not used for Twilio, but required by interface)
     * @return Boolean indicating if messaging is available
     */
    public Boolean hasActiveMessagingEndpoint(Id contactId, Map<String, Object> providerConfig) {
        if (contactId == null) {
            return false;
        }
        
        // Twilio requires a phone number
        List<Contact> contacts = [
            SELECT Id, Phone, MobilePhone
            FROM Contact
            WHERE Id = :contactId
              AND (Phone != null OR MobilePhone != null)
            LIMIT 1
        ];
        
        return !contacts.isEmpty();
    }
    
    /**
     * Validates Twilio configuration
     * @param providerConfig Map containing provider configuration
     * @return Error message if validation fails, null if valid
     */
    public String validateConfig(Map<String, Object> providerConfig) {
        if (providerConfig == null) {
            return 'Provider configuration is required';
        }
        
        String fromPhoneNumber = (String)providerConfig.get('fromPhoneNumber');
        if (String.isBlank(fromPhoneNumber)) {
            return 'From phone number is required for Twilio';
        }
        
        // Check if Named Credential exists (optional - will fail at callout if not configured)
        // Note: We can't check Named Credential existence in Apex, so we'll validate at callout time
        
        return null; // Valid
    }
}
