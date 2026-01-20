public with sharing class EmailTemplateRepository {
    @TestVisible private static List<EmailTemplateDTO> testMockDtos;

    public static void setMockDtos(List<EmailTemplateDTO> mockDtos) {
        testMockDtos = mockDtos;
    }

    public static List<EmailTemplateDTO> getAllActiveTemplates() {
        if (Test.isRunningTest() && testMockDtos != null) {
            return testMockDtos;
        }

        List<EmailTemplateDTO> dtos = new List<EmailTemplateDTO>();
        for (EmailTemplate emailTemplate : [
            SELECT Id, DeveloperName, Name, FolderName, Subject, IsActive
            FROM EmailTemplate
            WHERE IsActive = true
        ]) {
            dtos.add(new EmailTemplateDTO(emailTemplate));
        }
        return dtos;
    }
}