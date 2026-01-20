public with sharing class OrgWideEmailCMDTRepository {
    
    @TestVisible private static Map<String, Org_Wide_Email__mdt> testMockCatalogs;

    public static void setMockCatalogs(Map<String, Org_Wide_Email__mdt> mockData) {
        testMockCatalogs = mockData;
    }

    // 🔹 Get all existing CMDT records
    public static Map<String, Org_Wide_Email__mdt> getAllOrgWideEmails() {
        if (Test.isRunningTest() && testMockCatalogs != null) {
            return testMockCatalogs;
        }

        Map<String, Org_Wide_Email__mdt> orgWideEmailCMDTMap = new Map<String, Org_Wide_Email__mdt>();
        for (Org_Wide_Email__mdt orgWideEmailCMDT : [
            SELECT Developer_Name__c, MasterLabel, OrgWideEmailAddressId__c,
                   Email_Address__c, Active__c
            FROM Org_Wide_Email__mdt
        ]) {
            orgWideEmailCMDTMap.put(orgWideEmailCMDT.Developer_Name__c, orgWideEmailCMDT);
        }
        return orgWideEmailCMDTMap;
    }

    // 🔹 Build a CMDT record from a DTO
    public static Metadata.CustomMetadata buildCMDT(OrgWideEmailDTO orgWideEmailDTO) {
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = 'Org_Wide_Email.' + orgWideEmailDTO.developerName;
        customMetadata.label = orgWideEmailDTO.masterLabel;
        customMetadata.values = new List<Metadata.CustomMetadataValue>();

        addValue(customMetadata, 'Developer_Name__c', orgWideEmailDTO.developerName);
        addValue(customMetadata, 'OrgWideEmailAddressId__c', orgWideEmailDTO.orgWideEmailAddressId);
        addValue(customMetadata, 'Email_Address__c', orgWideEmailDTO.emailAddress);
        addValue(customMetadata, 'Active__c', orgWideEmailDTO.isActive);

        return customMetadata;
    }

    // 🔹 Add a field:value to the CMDT record
    private static void addValue(Metadata.CustomMetadata customMetadata, String fieldName, Object value) {
        Metadata.CustomMetadataValue customMetadataValue = new Metadata.CustomMetadataValue();
        customMetadataValue.field = fieldName;
        customMetadataValue.value = value;
        customMetadata.values.add(customMetadataValue);
    }

    // 🔹 Deploy CMDTs via Metadata API
    public static Id deployMetadata(List<Metadata.Metadata> metadataRecords) {
        if (metadataRecords == null || metadataRecords.isEmpty()) return null;

        if (Test.isRunningTest()) {
            System.debug('⚠️ Skipping Metadata deployment during test context.');
            // 👉 Return null instead of fake 0Af Id to avoid StringException
            return null;
        }

        Metadata.DeployContainer container = new Metadata.DeployContainer();
        for (Metadata.Metadata metadataRecord : metadataRecords) {
            container.addMetadata(metadataRecord);
        }

        return Metadata.Operations.enqueueDeployment(container, null);
    }


    // 🔹 Upsert CMDTs with diff check
    public static Id upsertCMDTs(List<OrgWideEmailDTO> dtos) {
        if (dtos == null || dtos.isEmpty()) return null;

        Map<String, Org_Wide_Email__mdt> existing = getAllOrgWideEmails();
        Metadata.DeployContainer container = new Metadata.DeployContainer();

        for (OrgWideEmailDTO orgWideEmailDTO : dtos) {
            Org_Wide_Email__mdt match = existing.get(orgWideEmailDTO.developerName);

            Boolean unchanged = match != null &&
                match.Email_Address__c == orgWideEmailDTO.emailAddress &&
                match.Active__c == orgWideEmailDTO.isActive;

            if (!unchanged) {
                container.addMetadata(buildCMDT(orgWideEmailDTO));
            }
        }

        return container.getMetadata().isEmpty()
            ? null
            : deployMetadata(container.getMetadata());
    }
}