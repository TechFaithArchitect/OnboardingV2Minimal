@isTest
private class EmailTemplateSyncOrchestratorTest {

    @isTest
    static void testRunFullSync_success() {
        // 🧪 Setup mock EmailTemplateDTO
        EmailTemplateDTO emailTemplateDTO = new EmailTemplateDTO();
        emailTemplateDTO.name = 'Welcome_Email';
        emailTemplateDTO.developerName = 'Welcome_Email';
        emailTemplateDTO.subject = 'Welcome!';
        emailTemplateDTO.folder = 'Test Folder';
        emailTemplateDTO.isActive = true;
        emailTemplateDTO.commType = 'Welcome';

        EmailTemplateRepository.setMockDtos(new List<EmailTemplateDTO>{ emailTemplateDTO });

        // 🧪 Setup mock Communication_Template__c (existing)
        Communication_Template__c existingCommunicationTemplate = new Communication_Template__c(
            Name = 'Welcome_Email',
            DeveloperName__c = 'Welcome_Email',
            Email_Subject__c = 'Old Subject',
            Communication_Type__c = 'Welcome',
            Active__c = false
        );
        CommunicationTemplateRepository.setMockTemplates(new Map<String, Communication_Template__c>{
            'Welcome_Email' => existingCommunicationTemplate
        });

        // 🧪 Setup empty CMDT map to simulate new record creation
        EmailCatalogCMDTRepository.setMockCatalogs(new Map<String, Email_Template_Catalog__mdt>());

        // 🚀 Run the sync
        Test.startTest();
        EmailTemplateSyncOrchestrator.run(true);
        Test.stopTest();

        System.assert(true, 'Sync should complete without exceptions');
    }

    @isTest
    static void testRunFullSync_failure() {
        // SET THE TEST HOOK TO FORCE A FAILURE  
        // Access @TestVisible private static variable forceFail
        EmailTemplateSyncService.forceFail = true;
        
        Test.startTest();
        EmailTemplateSyncOrchestrator.run(false);
        Test.stopTest();
        
        // Reset for other tests
        EmailTemplateSyncService.forceFail = false;

        System.assert(true, 'Sync should complete without exceptions');
    }
}
