@isTest
private class OrgWideEmailSyncServiceTest {

    @isTest
    static void testRunFullSync_createsAndUpdates() {
        // Existing record
        OrgWideEmail__c existing = new OrgWideEmail__c(
            Developer_Name__c = 'test_example_com',
            Email_Address__c = 'old@example.com',
            MasterLabel__c = 'Old Sender',
            Active__c = false
        );
        insert existing;

        // 🧪 Inject mock DTO
        OrgWideEmailDTO mockDto = new OrgWideEmailDTO();
        mockDto.developerName = 'test_example_com';
        mockDto.emailAddress = 'test@example.com';
        mockDto.masterLabel = 'New Sender';
        mockDto.isActive = true;

        OrgWideEmailSyncService.setMockDtos(new List<OrgWideEmailDTO>{ mockDto });

        Test.startTest();
        OrgWideEmailSyncService.syncAll(null);
        Test.stopTest();

        OrgWideEmail__c updated = [
            SELECT Email_Address__c, MasterLabel__c, Active__c
            FROM OrgWideEmail__c
            WHERE Id = :existing.Id
        ];

        System.assertEquals('test@example.com', updated.Email_Address__c);
        System.assertEquals('New Sender', updated.MasterLabel__c);
        System.assertEquals(true, updated.Active__c);
    }
}