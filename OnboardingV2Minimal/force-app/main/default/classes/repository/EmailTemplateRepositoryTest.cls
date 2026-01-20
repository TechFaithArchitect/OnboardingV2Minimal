@isTest
private class EmailTemplateRepositoryTest {

    @isTest
    static void testGetAllActiveTemplates_withData() {
        // 🧪 Create mock EmailTemplateDTO
        EmailTemplateDTO mockDto = new EmailTemplateDTO();
        mockDto.name = 'TEST_Reminder_Template';
        mockDto.developerName = 'TEST_Reminder_Template';
        mockDto.subject = 'Test Subject';
        mockDto.folder = 'Test Folder';
        mockDto.isActive = true;
        mockDto.commType = 'Reminder';

        // 🧪 Inject mock
        EmailTemplateRepository.setMockDtos(new List<EmailTemplateDTO>{ mockDto });

        Test.startTest();
        List<EmailTemplateDTO> dtos = EmailTemplateRepository.getAllActiveTemplates();
        Test.stopTest();

        System.assertEquals(1, dtos.size());
        System.assertEquals('Reminder', dtos[0].commType);
    }

    @isTest
    static void testGetAllActiveTemplates_empty() {
        // 🧪 Inject empty list
        EmailTemplateRepository.setMockDtos(new List<EmailTemplateDTO>());

        Test.startTest();
        List<EmailTemplateDTO> dtos = EmailTemplateRepository.getAllActiveTemplates();
        Test.stopTest();

        System.assertEquals(0, dtos.size());
    }
}