/**
 * Data Transfer Object for Vendor Program health metrics
 * Used for displaying vendor program overview in dashboard
 */
public class VendorProgramMetricsDTO {
    @AuraEnabled public Id Id;
    @AuraEnabled public String Name;
    @AuraEnabled public String Label;
    @AuraEnabled public Id VendorId;
    @AuraEnabled public String VendorName;
    @AuraEnabled public String Status;
    @AuraEnabled public Boolean Active;
    @AuraEnabled public Integer DealersOnboarded;
    @AuraEnabled public Integer InProgressCount;
    @AuraEnabled public Integer BlockedCount;
    @AuraEnabled public Integer TotalRequirements;
    @AuraEnabled public Integer CompleteRequirements;
    @AuraEnabled public Boolean RulesEngineValid;
    @AuraEnabled public Boolean DependenciesValid;
    @AuraEnabled public String RecordUrl;
    @AuraEnabled public List<String> GroupNames;

    public VendorProgramMetricsDTO() {
        this.DealersOnboarded = 0;
        this.InProgressCount = 0;
        this.BlockedCount = 0;
        this.TotalRequirements = 0;
        this.CompleteRequirements = 0;
        this.RulesEngineValid = true;
        this.DependenciesValid = true;
        this.GroupNames = new List<String>();
    }
}