@isTest
private class EmailCatalogCMDTRepositoryTest {

    @isTest
    static void testBuildAndDeployCMDT() {
        EmailTemplate mockEmail = new EmailTemplate(
            Name = 'Test Template',
            DeveloperName = 'Test_Template',
            Subject = 'Test Subject',
            IsActive = true
        );

        EmailTemplateDTO emailTemplateDTO = new EmailTemplateDTO(mockEmail);
        emailTemplateDTO.folder = 'Public';
        emailTemplateDTO.commType = 'Custom';

        // Validate CMDT construction
        Metadata.CustomMetadata record = EmailCatalogCMDTRepository.buildCMDT(emailTemplateDTO, null);
        System.assertEquals('Email_Template_Catalog.Test_Template', record.fullName);
        System.assertNotEquals(0, record.values.size());

        // Test deploy (mocked)
        Test.startTest();
        Id asyncId = EmailCatalogCMDTRepository.deployMetadata(new List<Metadata.CustomMetadata>{record});
        Test.stopTest();

        System.assertNotEquals(null, asyncId, 'Async Id should not be null');
        String asyncIdStr = String.valueOf(asyncId);
        System.assert(
            asyncIdStr.length() == 15 || asyncIdStr.length() == 18,
            'Async Id should be 15 or 18 characters in length'
        );

    }

    @isTest
    static void testUpsertCMDTs() {
        EmailTemplate mockEmail = new EmailTemplate(
            Name = 'Welcome Email',
            DeveloperName = 'Welcome_Email',
            Subject = 'Welcome!',
            IsActive = true
        );

        EmailTemplateDTO emailTemplateDTO = new EmailTemplateDTO(mockEmail);
        emailTemplateDTO.folder = 'Public';
        emailTemplateDTO.commType = 'Welcome';

        Test.startTest();
        EmailSyncSummaryDTO summary = EmailCatalogCMDTRepository.upsertCMDTs(new List<EmailTemplateDTO>{ emailTemplateDTO }, null);
        Test.stopTest();

        System.assertNotEquals(null, summary, 'Summary should not be null');
    }
}