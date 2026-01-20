/**
 * Data Transfer Object for Onboarding__c records with blocking information
 * Extends OnboardingDTO with blocking reasons and at-risk indicators
 */
public class OnboardingWithBlockingDTO extends OnboardingDTO {
    @AuraEnabled public Boolean IsBlocked;
    @AuraEnabled public Boolean IsAtRisk;
    @AuraEnabled public List<String> BlockingReasons;
    @AuraEnabled public Integer AgeInDays;

    public OnboardingWithBlockingDTO() {
        super();
        this.IsBlocked = false;
        this.IsAtRisk = false;
        this.BlockingReasons = new List<String>();
        this.AgeInDays = 0;
    }

    public OnboardingWithBlockingDTO(Onboarding__c ob) {
        super(ob);
        this.IsBlocked = false;
        this.IsAtRisk = false;
        this.BlockingReasons = new List<String>();
        if (ob.CreatedDate != null) {
            Date createdDate = Date.valueOf(ob.CreatedDate);
            this.AgeInDays = createdDate.daysBetween(Date.today());
            if (this.AgeInDays < 0) {
                this.AgeInDays = 0;
            }
        }
    }
}