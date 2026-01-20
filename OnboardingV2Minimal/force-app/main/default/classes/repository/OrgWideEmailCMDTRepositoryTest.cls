@isTest
private class OrgWideEmailCMDTRepositoryTest {

    private static OrgWideEmailDTO buildTestDTO(String devName) {
        OrgWideEmailDTO orgWideEmailDTO = new OrgWideEmailDTO();
        orgWideEmailDTO.developerName = devName;
        orgWideEmailDTO.masterLabel = 'Test Sender';
        orgWideEmailDTO.emailAddress = devName + '@example.com';
        orgWideEmailDTO.orgWideEmailAddressId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        orgWideEmailDTO.isActive = true;
        return orgWideEmailDTO;
    }

    private static Org_Wide_Email__mdt buildMockCMDT(String devName) {
        return new Org_Wide_Email__mdt(
            Developer_Name__c = devName,
            MasterLabel = 'Mock Label',
            OrgWideEmailAddressId__c = TestDataFactoryIdUtil.fakeIdForSObject(OrgWideEmailAddress.SObjectType),
            Email_Address__c = devName + '@example.com',
            Active__c = true
        );
    }

    @isTest
    static void testSetMockCatalogs_andGetAll() {
        // 🧪 Prepare & set mock data
        String developerName = 'mock_dev';
        OrgWideEmailCMDTRepository.setMockCatalogs(new Map<String, Org_Wide_Email__mdt>{
            developerName => buildMockCMDT(developerName)
        });

        // ✅ Act
        Map<String, Org_Wide_Email__mdt> result = OrgWideEmailCMDTRepository.getAllOrgWideEmails();

        // ✅ Assert
        System.assertEquals(1, result.size());
        System.assertEquals(developerName + '@example.com', result.get(developerName).Email_Address__c);
    }

    @isTest
    static void testBuildCMDT() {
        OrgWideEmailDTO orgWideEmailDTO = buildTestDTO('unit_test_dev');

        Metadata.CustomMetadata customMetadata = OrgWideEmailCMDTRepository.buildCMDT(orgWideEmailDTO);

        System.assertEquals('Org_Wide_Email.' + orgWideEmailDTO.developerName, customMetadata.fullName);
        System.assertEquals(orgWideEmailDTO.masterLabel, customMetadata.label);
        System.assertEquals(4, customMetadata.values.size());

        // Assert all expected fields and values
        Map<String, Object> actual = new Map<String, Object>();
        for (Metadata.CustomMetadataValue value : customMetadata.values) {
            actual.put(value.field, value.value);
        }

        System.assertEquals(orgWideEmailDTO.developerName, actual.get('Developer_Name__c'));
        System.assertEquals(orgWideEmailDTO.emailAddress, actual.get('Email_Address__c'));
        System.assertEquals(orgWideEmailDTO.orgWideEmailAddressId, actual.get('OrgWideEmailAddressId__c'));
        System.assertEquals(orgWideEmailDTO.isActive, actual.get('Active__c'));
    }


    @isTest
    static void testUpsertCMDTs_inTestContext_skipsDeployment() {
        OrgWideEmailCMDTRepository.setMockCatalogs(new Map<String, Org_Wide_Email__mdt>());

        OrgWideEmailDTO orgWideEmailDTO = buildTestDTO('upsert_test');

        Test.startTest();
        Id fakeId = OrgWideEmailCMDTRepository.upsertCMDTs(new List<OrgWideEmailDTO>{ orgWideEmailDTO });
        Test.stopTest();

        // ✅ Now we expect null, since deployMetadata is skipped in tests
        System.assertEquals(null, fakeId, 'Expected no async deployment ID in test context.');
    }
}