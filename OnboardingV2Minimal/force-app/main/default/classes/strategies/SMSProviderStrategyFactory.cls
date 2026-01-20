/**
 * Factory for creating SMS provider strategies
 * Centralizes strategy selection logic
 */
public with sharing class SMSProviderStrategyFactory {
    
    private static final Set<String> VALID_PROVIDER_TYPES = new Set<String>{ 'SalesforceMessaging', 'Twilio' };
    private static final Map<String, SMSProviderStrategy> STRATEGY_CACHE = new Map<String, SMSProviderStrategy>();
    
    /**
     * Gets the appropriate SMS provider strategy for a provider type
     * @param providerType The provider type (e.g., 'SalesforceMessaging', 'Twilio')
     * @return The SMS provider strategy
     * @throws IllegalArgumentException if provider type is invalid
     */
    public static SMSProviderStrategy getStrategy(String providerType) {
        if (String.isBlank(providerType)) {
            providerType = 'SalesforceMessaging'; // Default
        }
        
        // Validate provider type
        if (!VALID_PROVIDER_TYPES.contains(providerType)) {
            throw new IllegalArgumentException(
                'Invalid providerType "' + providerType + '". Valid values are: ' + 
                String.join(new List<String>(VALID_PROVIDER_TYPES), ', ')
            );
        }
        
        // Check cache first
        if (STRATEGY_CACHE.containsKey(providerType)) {
            return STRATEGY_CACHE.get(providerType);
        }
        
        // Create strategy based on provider type
        SMSProviderStrategy strategy;
        switch on providerType {
            when 'SalesforceMessaging' {
                strategy = new SalesforceMessagingProvider();
            }
            when 'Twilio' {
                strategy = new TwilioSMSProvider();
            }
        }
        
        // Cache the strategy
        STRATEGY_CACHE.put(providerType, strategy);
        return strategy;
    }
    
    /**
     * Gets the set of valid provider types
     * @return Set of valid provider type strings
     */
    public static Set<String> getValidProviderTypes() {
        return VALID_PROVIDER_TYPES.clone();
    }
    
    /**
     * Clears the strategy cache (useful for testing)
     */
    @TestVisible
    private static void clearCache() {
        STRATEGY_CACHE.clear();
    }
}