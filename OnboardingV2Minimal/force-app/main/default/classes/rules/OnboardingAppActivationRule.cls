public interface OnboardingAppActivationRule {
    /**
     * Executes the activation rule logic for a single record.
     *
     * @param recordId      The ID of the parent record being activated
     * @param objectApiName The API name of the object being activated
     * @throws AuraHandledException if the rule fails and activation should be blocked
     */
    void apply(Id recordId, String objectApiName);

    /**
     * Executes the activation rule logic for multiple records in bulk.
     * This method should be more efficient than calling apply() multiple times.
     *
     * @param recordIds    The set of record IDs being activated
     * @param objectApiName The API name of the object being activated
     * @throws AuraHandledException if any rule fails and activation should be blocked
     */
    void applyBulk(Set<Id> recordIds, String objectApiName);
}