@isTest
private class EmailTemplateSyncServiceTest {

    @isTest
    static void testSyncAllTemplates_success() {
        // 🧪 Mock EmailTemplateDTO
        EmailTemplateDTO emailTemplateDTO = new EmailTemplateDTO();
        emailTemplateDTO.name = 'Welcome_Email';
        emailTemplateDTO.developerName = 'Welcome_Email';
        emailTemplateDTO.subject = 'Welcome!';
        emailTemplateDTO.folder = 'Mock Folder';
        emailTemplateDTO.isActive = true;
        emailTemplateDTO.commType = 'Welcome';

        EmailTemplateRepository.setMockDtos(new List<EmailTemplateDTO>{ emailTemplateDTO });

        // 🧪 Mock existing Communication Template (for update case)
        CommunicationTemplateRepository.setMockTemplates(new Map<String, Communication_Template__c>{
            'Welcome_Email' => new Communication_Template__c(
                Name = 'Welcome_Email',
                DeveloperName__c = 'Welcome_Email',
                Email_Subject__c = 'Old Subject',
                Communication_Type__c = 'Welcome',
                Active__c = false
            )
        });

        // 🧪 Mock CMDT catalog (none exists so one should be created)
        EmailCatalogCMDTRepository.setMockCatalogs(new Map<String, Email_Template_Catalog__mdt>());

        Test.startTest();
        EmailTemplateSyncService service = new EmailTemplateSyncService();
        EmailSyncSummaryDTO summary = service.syncAllTemplates(null);
        Test.stopTest();

        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assert(summary.updatedCount > 0 || summary.insertedCount > 0 || summary.newCMDTCount > 0,
            'Expected at least one sync operation: insert, update, or CMDT');
    }

    @isTest
    static void testSyncAllTemplates_handlesEmpty() {
        EmailTemplateRepository.setMockDtos(new List<EmailTemplateDTO>());
        CommunicationTemplateRepository.setMockTemplates(new Map<String, Communication_Template__c>());
        EmailCatalogCMDTRepository.setMockCatalogs(new Map<String, Email_Template_Catalog__mdt>());

        Test.startTest();
        EmailTemplateSyncService service = new EmailTemplateSyncService();
        EmailSyncSummaryDTO summary = service.syncAllTemplates(null);
        Test.stopTest();

        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assertEquals(0, summary.insertedCount, 'Expected 0 inserted templates');
        System.assertEquals(0, summary.updatedCount, 'Expected 0 updated templates');
        System.assertEquals(0, summary.newCMDTCount, 'Expected 0 new CMDT entries');
    }
}
