@isTest
private class EmailAttachmentRepositoryTest {

    @isTest
    static void testGetLegacyAttachments() {
        // Arrange
        Account acc = TestDataFactory.createAccount('Legacy Attachment Test Acc', true);

        Attachment att = new Attachment(
            ParentId = acc.Id,
            Name = 'TestAttachment.txt',
            Body = Blob.valueOf('Test Content'),
            ContentType = 'text/plain'
        );
        insert att;

        // Act
        Test.startTest();
        List<Attachment> results = EmailAttachmentRepository.getLegacyAttachments(new List<Id>{ att.Id });
        Test.stopTest();

        // Assert
        System.assertEquals(1, results.size(), 'Should return the inserted Attachment');
        System.assertEquals(att.Id, results[0].Id, 'Attachment Id should match');
    }

    @isTest
    static void testGetContentVersions() {
        // Arrange
        ContentVersion contentVersion = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Version Data')
        );
        insert contentVersion;

        // Get associated ContentDocumentId
        ContentVersion inserted = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];

        // Act
        Test.startTest();
        List<ContentVersion> results = EmailAttachmentRepository.getContentVersions(new List<Id>{ inserted.ContentDocumentId });
        Test.stopTest();

        // Assert
        System.assertEquals(1, results.size(), 'Should return the inserted ContentVersion');
        System.assertEquals('TestFile', results[0].Title, 'Title should match');
    }

    @isTest
    static void testNullAndEmptyInputs() {
        Test.startTest();
        System.assertEquals(0, EmailAttachmentRepository.getLegacyAttachments(null).size(), 'Null input should return empty list');
        System.assertEquals(0, EmailAttachmentRepository.getLegacyAttachments(new List<Id>()).size(), 'Empty list should return empty list');
        System.assertEquals(0, EmailAttachmentRepository.getContentVersions(null).size(), 'Null input should return empty list');
        System.assertEquals(0, EmailAttachmentRepository.getContentVersions(new List<Id>()).size(), 'Empty list should return empty list');
        Test.stopTest();
    }
}