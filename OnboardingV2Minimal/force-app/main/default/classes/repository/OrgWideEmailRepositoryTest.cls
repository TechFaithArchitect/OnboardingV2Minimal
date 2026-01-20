@isTest
private class OrgWideEmailRepositoryTest {

    @isTest
    static void testUpsertEmails_insertAndUpdate() {
        OrgWideEmail__c existing = new OrgWideEmail__c(
            Developer_Name__c = 'test_existing',
            Email_Address__c = 'existing@example.com',
            MasterLabel__c = 'Existing',
            Active__c = false
        );
        insert existing;

        OrgWideEmail__c updated = new OrgWideEmail__c(
            Developer_Name__c = 'test_existing',
            Email_Address__c = 'updated@example.com',
            MasterLabel__c = 'Updated',
            Active__c = true
        );

        OrgWideEmail__c newRec = new OrgWideEmail__c(
            Developer_Name__c = 'test_new',
            Email_Address__c = 'new@example.com',
            MasterLabel__c = 'New',
            Active__c = true
        );

        Test.startTest();
        OrgWideEmailRepository.upsertEmails(new List<OrgWideEmail__c>{ updated, newRec });
        Test.stopTest();

        List<OrgWideEmail__c> results = [
            SELECT Developer_Name__c, Email_Address__c FROM OrgWideEmail__c
        ];
        System.assertEquals(2, results.size(), 'Should have 2 records total');
    }

    @isTest
    static void testGetAll_withMock() {
        OrgWideEmail__c mock = new OrgWideEmail__c(
            Developer_Name__c = 'mock_name',
            Email_Address__c = 'mock@example.com',
            MasterLabel__c = 'Mock',
            Active__c = true
        );
        OrgWideEmailRepository.setMockEmails(new Map<String, OrgWideEmail__c>{
            'mock_name' => mock
        });

        Test.startTest();
        Map<String, OrgWideEmail__c> result = OrgWideEmailRepository.getAll();
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('mock@example.com', result.get('mock_name').Email_Address__c);
    }

    @isTest
    static void testGetAll_withRealDataFromFactory() {
        // Arrange using the factory wrapper
        OrgWideEmailDTO dto = TestDataFactory.createOrgWideEmailDTO('real_test');

        // Convert DTO to actual OrgWideEmail__c record
        // Don't set orgWideEmailAddressId if it's a fake ID to avoid validation errors
        OrgWideEmail__c email = new OrgWideEmail__c(
            Developer_Name__c = dto.developerName,
            Email_Address__c = dto.emailAddress,
            MasterLabel__c = dto.masterLabel,
            Active__c = dto.isActive
        );
        // Only set OrgWideEmailAddressId__c if it's a valid ID (not a fake test ID)
        if (dto.orgWideEmailAddressId != null && String.valueOf(dto.orgWideEmailAddressId).length() == 18) {
            email.OrgWideEmailAddressId__c = dto.orgWideEmailAddressId;
        }
        insert email;

        // Ensure mock path is skipped
        OrgWideEmailRepository.setMockEmails(null);

        // Act
        Test.startTest();
        Map<String, OrgWideEmail__c> results = OrgWideEmailRepository.getAll();
        Test.stopTest();

        // Assert
        System.assert(results.containsKey('real_test'), 'Expected real_test key to exist');
        System.assertEquals(dto.emailAddress, results.get('real_test').Email_Address__c);
    }

}