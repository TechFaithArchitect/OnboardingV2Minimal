public with sharing class OrgWideEmailSyncService {
    @TestVisible 
    private static List<OrgWideEmailDTO> testMockDtos;
    public static void setMockDtos(List<OrgWideEmailDTO> dtos) {
        testMockDtos = dtos;
    }

    public static EmailSyncSummaryDTO syncAll(Id jobId) {
        Datetime start = Datetime.now();
        EmailSyncSummaryDTO summary = new EmailSyncSummaryDTO();
        summary.jobId = jobId;
        summary.jobName = 'Org-Wide Email Sync';
        summary.manualRun = false;

        // 🔹 Get Source Data
        List<OrgWideEmailDTO> dtos = new List<OrgWideEmailDTO>();
        if (Test.isRunningTest() && testMockDtos != null) {
            dtos = testMockDtos;
        } else {
            List<OrgWideEmailAddress> orgWideEmails = OrgWideEmailAddressRepository.getAll();
            for (OrgWideEmailAddress owa : orgWideEmails) {
                dtos.add(new OrgWideEmailDTO(owa));
            }
        }        

        // 🔹 Sync to OrgWideEmail__c
        List<OrgWideEmail__c> sobjects = new List<OrgWideEmail__c>();
        for (OrgWideEmailDTO orgWideEmailDTO : dtos) {
            sobjects.add(orgWideEmailDTO.toSObject());
        }
        OrgWideEmailRepository.upsertEmails(sobjects);

        // 🔹 Sync to CMDT
        Id asyncId = OrgWideEmailCMDTRepository.upsertCMDTs(dtos);
        summary.asyncOperationId = asyncId;
        summary.newCMDTCount = dtos.size();
        summary.durationSeconds = (Datetime.now().getTime() - start.getTime()) / EmailSyncServiceConstants.MILLISECONDS_TO_SECONDS;

        return summary;
    }
}