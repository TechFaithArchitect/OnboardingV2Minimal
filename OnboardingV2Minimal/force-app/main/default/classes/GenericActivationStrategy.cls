/**
 * Generic activation strategy for objects that don't require special handling
 * Uses the generic OnboardingAppActivationService
 */
public with sharing class GenericActivationStrategy implements ActivationStrategy {
    
    private String objectApiName;
    
    public GenericActivationStrategy(String objectApiName) {
        this.objectApiName = objectApiName;
    }
    
    public void activate(Id recordId) {
        OnboardingAppActivationService.activateRecord(objectApiName, recordId);
    }
}