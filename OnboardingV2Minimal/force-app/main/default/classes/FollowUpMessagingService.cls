/**
 * Service for sending SMS messages via multiple providers
 * Supports Salesforce Messaging API and Twilio using strategy pattern
 * 
 * NOTE: Salesforce Messaging API requires Digital Engagement setup.
 * Twilio requires Named Credential configuration.
 */
public with sharing class FollowUpMessagingService {

    /**
     * Send SMS message using specified provider
     * @param contactId Contact to send message to
     * @param messageContent Message text
     * @param providerType SMS provider type ('SalesforceMessaging' or 'Twilio')
     * @param providerConfig Provider-specific configuration map:
     *   - For SalesforceMessaging: messagingChannelId (Id), templateId (Id, optional)
     *   - For Twilio: fromPhoneNumber (String), accountSid (String, optional), authToken (String, optional)
     * @return String identifier for tracking (provider-specific message ID)
     */
    public static String sendSMS(
        Id contactId,
        String messageContent,
        String providerType,
        Map<String, Object> providerConfig
    ) {
        if (contactId == null || String.isBlank(messageContent)) {
            throw new IllegalArgumentException('Contact ID and message content are required');
        }

        // Get SMS provider strategy
        SMSProviderStrategy provider;
        try {
            provider = SMSProviderStrategyFactory.getStrategy(providerType);
        } catch (IllegalArgumentException ex) {
            throw new FollowUpMessagingException('Invalid SMS provider type: ' + providerType);
        }

        // Validate configuration
        String validationError = provider.validateConfig(providerConfig);
        if (validationError != null) {
            throw new FollowUpMessagingException('Provider configuration error: ' + validationError);
        }

        // Send SMS using provider strategy
        return provider.sendSMS(contactId, messageContent, providerConfig);
    }

    /**
     * Send SMS message (backward compatibility - uses Salesforce Messaging as default)
     * @param contactId Contact to send message to
     * @param messageContent Message text
     * @param messagingChannelId SMS channel ID (for Salesforce Messaging)
     * @param templateId Optional template ID (for Salesforce Messaging)
     * @return String identifier for tracking
     */
    public static String sendSMS(
        Id contactId,
        String messageContent,
        Id messagingChannelId,
        Id templateId
    ) {
        // Build provider config for Salesforce Messaging
        Map<String, Object> providerConfig = new Map<String, Object>();
        providerConfig.put('messagingChannelId', messagingChannelId);
        if (templateId != null) {
            providerConfig.put('templateId', templateId);
        }

        return sendSMS(contactId, messageContent, 'SalesforceMessaging', providerConfig);
    }

    /**
     * Check if Contact has active messaging endpoint for specified provider
     * @param contactId Contact ID
     * @param providerType SMS provider type ('SalesforceMessaging' or 'Twilio')
     * @param providerConfig Provider-specific configuration
     * @return Boolean indicating if messaging is available
     */
    public static Boolean hasActiveMessagingEndpoint(
        Id contactId,
        String providerType,
        Map<String, Object> providerConfig
    ) {
        if (contactId == null) {
            return false;
        }

        // Get SMS provider strategy
        SMSProviderStrategy provider;
        try {
            provider = SMSProviderStrategyFactory.getStrategy(providerType);
        } catch (IllegalArgumentException ex) {
            System.debug('Invalid provider type, defaulting to phone check: ' + ex.getMessage());
            // Fallback to phone check
            return hasPhoneNumber(contactId);
        }

        return provider.hasActiveMessagingEndpoint(contactId, providerConfig);
    }

    /**
     * Check if Contact has active messaging endpoint (backward compatibility)
     * Uses Salesforce Messaging as default
     * @param contactId Contact ID
     * @param channelId Messaging Channel ID (optional)
     * @return Boolean indicating if messaging is available
     */
    public static Boolean hasActiveMessagingEndpoint(Id contactId, Id channelId) {
        Map<String, Object> providerConfig = new Map<String, Object>();
        if (channelId != null) {
            providerConfig.put('messagingChannelId', channelId);
        }
        return hasActiveMessagingEndpoint(contactId, 'SalesforceMessaging', providerConfig);
    }

    /**
     * Helper method to check if Contact has phone number
     */
    private static Boolean hasPhoneNumber(Id contactId) {
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
     * Get primary Contact for an Account
     * @param accountId Account ID
     * @return Contact record or null
     */
    public static Contact getPrimaryContact(Id accountId) {
        if (accountId == null) {
            return null;
        }

        // Query Contact - use standard fields only
        List<Contact> contacts = [
            SELECT Id, Name, Phone, MobilePhone, Email
            FROM Contact
            WHERE AccountId = :accountId
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        return contacts.isEmpty() ? null : contacts[0];
    }

    /**
     * Custom exception for messaging errors
     */
    public class FollowUpMessagingException extends Exception {}
}