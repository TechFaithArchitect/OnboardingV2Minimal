/**
 * Data Transfer Object for Account records with onboarding context
 * Used for passing account data with eligible vendor information to LWC components
 */
public class AccountDTO {
    @AuraEnabled public Id Id;
    @AuraEnabled public String Name;
    @AuraEnabled public String Territory;
    @AuraEnabled public String Region;
    @AuraEnabled public Integer EligibleVendorCount;
    @AuraEnabled public String RecordUrl;

    public AccountDTO() {
        this.EligibleVendorCount = 0;
    }
}