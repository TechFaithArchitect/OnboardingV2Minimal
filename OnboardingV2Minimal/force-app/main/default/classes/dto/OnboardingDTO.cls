/**
 * Data Transfer Object for Onboarding__c records (Dealer Onboarding)
 * Used for passing onboarding data to LWC components
 * 
 * ⚠️ IMPORTANT: The Status field contains Onboarding__c.Onboarding_Status__c (Dealer Onboarding).
 * This status is displayed AS-IS without simplification. 
 * 
 * For Vendor Program status simplification, use VendorProgramStatusMapper.
 */
public virtual class OnboardingDTO {
    @AuraEnabled public Id Id;
    @AuraEnabled public String Name;
    /** Dealer Onboarding status - displayed as-is, NOT simplified */
    @AuraEnabled public String Status;
    @AuraEnabled public Id AccountId;
    @AuraEnabled public String AccountName;
    @AuraEnabled public Id VendorProgramId;
    @AuraEnabled public String VendorProgramName;
    @AuraEnabled public DateTime CreatedDate;
    @AuraEnabled public DateTime LastModifiedDate;
    @AuraEnabled public Id CreatedById;
    @AuraEnabled public String CreatedByName;
    @AuraEnabled public String RecordUrl;

    public OnboardingDTO() {}

    public OnboardingDTO(Onboarding__c ob) {
        this.Id = ob.Id;
        this.Name = ob.Name;
        this.Status = ob.Onboarding_Status__c;
        this.AccountId = ob.Account__c;
        this.AccountName = ob.Account__r != null ? ob.Account__r.Name : null;
        this.VendorProgramId = ob.Vendor_Customization__c;
        this.VendorProgramName = ob.Vendor_Customization__r != null ? ob.Vendor_Customization__r.Name : null;
        this.CreatedDate = ob.CreatedDate;
        this.LastModifiedDate = ob.LastModifiedDate;
        this.CreatedById = ob.CreatedById;
        this.CreatedByName = ob.CreatedBy != null ? ob.CreatedBy.Name : null;
        this.RecordUrl = '/' + ob.Id;
    }
}