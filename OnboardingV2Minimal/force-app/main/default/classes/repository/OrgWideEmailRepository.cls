public with sharing class OrgWideEmailRepository {
    @TestVisible private static Map<String, OrgWideEmail__c> testMockEmails;

    public static void setMockEmails(Map<String, OrgWideEmail__c> mocks) {
        testMockEmails = mocks;
    }

    public static Map<String, OrgWideEmail__c> getAll() {
        if (Test.isRunningTest() && testMockEmails != null) {
            return testMockEmails;
        }

        Map<String, OrgWideEmail__c> orgWideEmailMap = new Map<String, OrgWideEmail__c>();
        for (OrgWideEmail__c orgWideEmail : [
            SELECT Id, Developer_Name__c, Email_Address__c, MasterLabel__c, Active__c
            FROM OrgWideEmail__c
        ]) {
            if (String.isNotBlank(orgWideEmail.Developer_Name__c)) {
                orgWideEmailMap.put(orgWideEmail.Developer_Name__c, orgWideEmail);
            }
        }
        return orgWideEmailMap;
    }

    public static void upsertEmails(List<OrgWideEmail__c> orgWideEmailRecords) {
        if (orgWideEmailRecords == null || orgWideEmailRecords.isEmpty()) return;

        List<OrgWideEmail__c> toInsert = new List<OrgWideEmail__c>();
        List<OrgWideEmail__c> toUpdate = new List<OrgWideEmail__c>();

        Map<String, OrgWideEmail__c> existing = getAll();

        for (OrgWideEmail__c orgWideEmailRecord : orgWideEmailRecords) {
            String developerNameKey = orgWideEmailRecord.Developer_Name__c;
            if (existing.containsKey(developerNameKey)) {
                OrgWideEmail__c existingOrgWideEmail = existing.get(developerNameKey);
                if (orgWideEmailRecord.Email_Address__c != existingOrgWideEmail.Email_Address__c ||
                    orgWideEmailRecord.MasterLabel__c != existingOrgWideEmail.MasterLabel__c ||
                    orgWideEmailRecord.Active__c != existingOrgWideEmail.Active__c) {
                    orgWideEmailRecord.Id = existingOrgWideEmail.Id;
                    toUpdate.add(orgWideEmailRecord);
                }
            } else {
                toInsert.add(orgWideEmailRecord);
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }
}