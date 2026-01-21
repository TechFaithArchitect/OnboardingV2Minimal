/**
 * Orchestrator for activation operations
 * Uses strategy pattern to support different object types without modification (OCP compliant)
 */
public with sharing class OnboardingAppActivationOrchestrator {

    public static void activate(Id recordId, String objectApiName) {
        ValidationHelper.requireNotBlank(objectApiName, 'Object API Name');
        ValidationHelper.requireId(recordId, 'Record Id');

        // Get the appropriate strategy for this object type
        ActivationStrategy strategy = ActivationStrategyFactory.getStrategy(objectApiName);
        strategy.activate(recordId);
    }
}