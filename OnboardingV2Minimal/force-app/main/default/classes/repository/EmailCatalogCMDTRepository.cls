public with sharing class EmailCatalogCMDTRepository {
    @TestVisible private static Map<String, Email_Template_Catalog__mdt> testMockCatalogs;

    public static void setMockCatalogs(Map<String, Email_Template_Catalog__mdt> mockCatalogs) {
        testMockCatalogs = mockCatalogs;
    }

    // 🔹 Get all existing CMDT records
    public static Map<String, Email_Template_Catalog__mdt> getAllEmailCatalogs() {
        if (Test.isRunningTest() && testMockCatalogs != null) {
            return testMockCatalogs;
        }

        Map<String, Email_Template_Catalog__mdt> catalogMap = new Map<String, Email_Template_Catalog__mdt>();
        for (Email_Template_Catalog__mdt emailCatalog : [
            SELECT DeveloperName__c, MasterLabel, Folder_Name__c,
                   Communication_Type__c, Active__c, Description__c
            FROM Email_Template_Catalog__mdt
        ]) {
            catalogMap.put(emailCatalog.DeveloperName__c, emailCatalog);
        }
        return catalogMap;
    }

    // 🔹 Build a Custom Metadata record
    public static Metadata.CustomMetadata buildCMDT(EmailTemplateDTO emailTemplateDTO, Id jobId) {
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = 'Email_Template_Catalog.' + emailTemplateDTO.developerName;
        customMetadata.label = emailTemplateDTO.name;
        customMetadata.values = new List<Metadata.CustomMetadataValue>();

        addValue(customMetadata, 'DeveloperName__c', emailTemplateDTO.developerName);
        addValue(customMetadata, 'Folder_Name__c', emailTemplateDTO.folder);
        addValue(customMetadata, 'Communication_Type__c', emailTemplateDTO.commType);
        addValue(customMetadata, 'Active__c', emailTemplateDTO.isActive);
        addValue(customMetadata, 'Description__c', emailTemplateDTO.subject);
        addValue(customMetadata, 'Sync_Job_Id__c', String.valueOf(jobId));

        return customMetadata;
    }

    private static void addValue(Metadata.CustomMetadata customMetadata, String fieldName, Object value) {
        Metadata.CustomMetadataValue customMetadataValue = new Metadata.CustomMetadataValue();
        customMetadataValue.field = fieldName;
        customMetadataValue.value = value;
        customMetadata.values.add(customMetadataValue);
    }

    // 🔹 Bulk deploy CMDTs
    public static Id deployMetadata(List<Metadata.Metadata> metadataRecords) {
        if (metadataRecords == null || metadataRecords.isEmpty()) return null;

        if (Test.isRunningTest()) {
            System.debug('⚠️ Skipping Metadata deployment during test context.');
            return [SELECT Id FROM User LIMIT 1].Id;  // You can sub this out with fakeAsyncId() if preferred
        }

        Metadata.DeployContainer container = new Metadata.DeployContainer();
        for (Metadata.Metadata metadataRecord : metadataRecords) {
            container.addMetadata(metadataRecord);
        }

        return Metadata.Operations.enqueueDeployment(container, null);
    }

    // 🔹 Upsert CMDTs with diff check
    public static EmailSyncSummaryDTO upsertCMDTs(List<EmailTemplateDTO> emailTemplateDTOList, Id jobId) {
        EmailSyncSummaryDTO summary = new EmailSyncSummaryDTO();
        if (emailTemplateDTOList == null || emailTemplateDTOList.isEmpty()) return summary;

        Map<String, Email_Template_Catalog__mdt> existing = getAllEmailCatalogs();
        Metadata.DeployContainer container = new Metadata.DeployContainer();
        Integer changedCount = 0;

        for (EmailTemplateDTO emailTemplateDTO : emailTemplateDTOList) {
            String developerNameKey = emailTemplateDTO.developerName;

            Boolean unchanged = existing.containsKey(developerNameKey) &&
                existing.get(developerNameKey).Folder_Name__c == emailTemplateDTO.folder &&
                existing.get(developerNameKey).Communication_Type__c == emailTemplateDTO.commType &&
                existing.get(developerNameKey).Active__c == emailTemplateDTO.isActive &&
                existing.get(developerNameKey).Description__c == emailTemplateDTO.subject;

            if (unchanged) continue;

            Metadata.CustomMetadata cmdtRecord = buildCMDT(emailTemplateDTO, jobId);
            container.addMetadata(cmdtRecord);
            changedCount++;
        }

        if (!container.getMetadata().isEmpty()) {
            Id asyncId = deployMetadata(container.getMetadata());
            summary.asyncOperationId = asyncId;
            summary.asyncOperationIdStr = String.valueOf(asyncId);
            summary.newCMDTCount = changedCount;

            System.debug('🚀 CMDT Upsert: ' + changedCount + ' records changed. Async ID: ' + asyncId);
        } else {
            System.debug('✅ No CMDT changes detected.');
        }

        return summary;
    }
}