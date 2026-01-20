public class OrgWideEmailDTO {
    public Id orgWideEmailAddressId;
    public String emailAddress;
    public String developerName;
    public String masterLabel;
    public Boolean isActive;

    public OrgWideEmailDTO() {}

    public OrgWideEmailDTO(OrgWideEmailAddress owa) {
        this.orgWideEmailAddressId = owa.Id;
        this.emailAddress = owa.Address;
        this.developerName = generateDeveloperName(owa.Address);
        this.masterLabel = owa.DisplayName;
        this.isActive = owa.IsAllowAllProfiles;
    }

    @testVisible
    private String generateDeveloperName(String email) {
        return email != null ? email.replaceAll('[^a-zA-Z0-9]', '_') : null;
    }

    public OrgWideEmail__c toSObject() {
        return new OrgWideEmail__c(
            Name = masterLabel,
            Developer_Name__c = developerName,
            Email_Address__c = emailAddress,
            OrgWideEmailAddressId__c = orgWideEmailAddressId,
            MasterLabel__c = masterLabel,
            Active__c = isActive
        );
    }

    public Boolean hasChanges(OrgWideEmail__c existing) {
        return existing.Email_Address__c != emailAddress ||
               existing.MasterLabel__c != masterLabel ||
               existing.Active__c != isActive;
    }
}