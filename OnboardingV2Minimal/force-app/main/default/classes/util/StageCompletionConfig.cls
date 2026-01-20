/**
 * Configuration for stage completion logic
 * Centralizes component name checks to follow Open/Closed Principle
 * New component types can be added by extending this class or using Custom Metadata
 */
public with sharing class StageCompletionConfig {
    
    /**
     * Set of component API names that represent vendor selection stages
     * These stages are automatically completed if the vendor program has a vendor
     */
    private static final Set<String> VENDOR_SELECTION_COMPONENTS = new Set<String>{
        'vendorProgramOnboardingVendor',
        'vendorProgramOnboardingVendorProgramSearchOrCreate'
    };
    
    /**
     * Checks if a component represents a vendor selection stage
     * @param componentApiName The component API name to check
     * @return true if the component is a vendor selection stage
     */
    public static Boolean isVendorSelectionComponent(String componentApiName) {
        if (String.isBlank(componentApiName)) {
            return false;
        }
        return VENDOR_SELECTION_COMPONENTS.contains(componentApiName);
    }
    
    /**
     * Gets all vendor selection component names
     * @return Set of component API names
     */
    public static Set<String> getVendorSelectionComponents() {
        return VENDOR_SELECTION_COMPONENTS.clone();
    }
}