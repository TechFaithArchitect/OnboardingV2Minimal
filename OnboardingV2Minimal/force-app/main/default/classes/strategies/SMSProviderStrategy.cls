/**
 * Strategy interface for SMS provider types
 * Follows Open/Closed Principle - new SMS providers can be added without modifying existing code
 */
public interface SMSProviderStrategy {
    /**
     * Send SMS message using the provider's API
     * @param contactId Contact to send message to
     * @param messageContent Message text
     * @param providerConfig Provider-specific configuration (e.g., channel ID, template ID)
     * @return String identifier for tracking (provider-specific message ID)
     * @throws FollowUpMessagingService.FollowUpMessagingException if sending fails
     */
    String sendSMS(Id contactId, String messageContent, Map<String, Object> providerConfig);
    
    /**
     * Check if Contact has active messaging endpoint for this provider
     * @param contactId Contact ID
     * @param providerConfig Provider-specific configuration
     * @return Boolean indicating if messaging is available
     */
    Boolean hasActiveMessagingEndpoint(Id contactId, Map<String, Object> providerConfig);
    
    /**
     * Validates that the provider configuration has all required fields
     * @param providerConfig Provider-specific configuration
     * @return Error message if validation fails, null if valid
     */
    String validateConfig(Map<String, Object> providerConfig);
}