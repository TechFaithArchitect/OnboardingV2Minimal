public class EmailTemplateDTO {
    public Id id;
    public String developerName;
    public String name;
    public String folder;
    public String subject;
    public Boolean isActive;
    public String commType;

    public EmailTemplateDTO() {}

    public EmailTemplateDTO(EmailTemplate emailTemplate) {
        this.id = emailTemplate.Id;
        this.developerName = emailTemplate.DeveloperName;
        this.name = emailTemplate.Name;
        this.folder = emailTemplate.FolderName;
        this.subject = String.isNotBlank(emailTemplate.Subject) ? emailTemplate.Subject : 'Unfiled';
        this.isActive = emailTemplate.IsActive;
        this.commType = deriveCommType(emailTemplate.Name);
    }

    private String deriveCommType(String templateName) {
        if (templateName.containsIgnoreCase('Welcome')) return 'Welcome';
        if (templateName.containsIgnoreCase('Reminder')) return 'Reminder';
        if (templateName.containsIgnoreCase('Completion')) return 'Completion';
        return 'Custom';
    }

    public Communication_Template__c toSObject() {
        return new Communication_Template__c(
            Name = name,
            DeveloperName__c = developerName,
            Folder_Name__c = folder,
            Email_Subject__c = subject,
            Communication_Type__c = commType,
            Active__c = isActive,
            Email_Template_Id__c = id
        );
    }

    public Communication_Template__c toSObject(Communication_Template__c existing) {
        existing.Folder_Name__c = folder;
        existing.Email_Subject__c = subject;
        existing.Communication_Type__c = commType;
        existing.Active__c = isActive;
        existing.Email_Template_Id__c = id;
        return existing;
    }

    public Boolean hasChanges(Communication_Template__c existing) {
        return (
            existing.Folder_Name__c != folder ||
            existing.Email_Subject__c != subject ||
            existing.Communication_Type__c != commType ||
            existing.Active__c != isActive ||
            existing.Email_Template_Id__c != id
        );
    }
}