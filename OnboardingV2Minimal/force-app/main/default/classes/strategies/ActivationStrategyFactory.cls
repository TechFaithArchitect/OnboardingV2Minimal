/**
 * Factory for creating activation strategies
 * Centralizes strategy selection logic
 */
public with sharing class ActivationStrategyFactory {
    
    private static final Map<String, ActivationStrategy> STRATEGY_CACHE = new Map<String, ActivationStrategy>();
    
    /**
     * Gets the appropriate activation strategy for an object type
     * @param objectApiName The API name of the object
     * @return The activation strategy for the object type
     */
    public static ActivationStrategy getStrategy(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            throw new IllegalArgumentException('Object API name cannot be blank');
        }
        
        // Check cache first
        if (STRATEGY_CACHE.containsKey(objectApiName)) {
            return STRATEGY_CACHE.get(objectApiName);
        }
        
        // Create strategy based on object type
        ActivationStrategy strategy;
        switch on objectApiName {
            when 'Vendor_Customization__c' {
                strategy = new VendorCustomizationActivationStrategy();
            }
            when else {
                // Use generic strategy for all other object types
                strategy = new GenericActivationStrategy(objectApiName);
            }
        }
        
        // Cache the strategy
        STRATEGY_CACHE.put(objectApiName, strategy);
        return strategy;
    }
    
    /**
     * Clears the strategy cache (useful for testing)
     */
    @TestVisible
    private static void clearCache() {
        STRATEGY_CACHE.clear();
    }
}