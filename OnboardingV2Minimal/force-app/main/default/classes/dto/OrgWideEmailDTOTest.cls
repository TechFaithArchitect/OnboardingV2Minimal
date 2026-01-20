@isTest
private class OrgWideEmailDTOTest {

    @isTest
    static void testHasChanges() {
        OrgWideEmailDTO orgWideEmailDTO = new OrgWideEmailDTO();
        orgWideEmailDTO.emailAddress = 'test@example.com';
        orgWideEmailDTO.masterLabel = 'Test Label';
        orgWideEmailDTO.isActive = true;

        OrgWideEmail__c existingOrgWideEmail = new OrgWideEmail__c(
            Email_Address__c = 'test@example.com',
            MasterLabel__c = 'Test Label',
            Active__c = true
        );

        System.assert(!orgWideEmailDTO.hasChanges(existingOrgWideEmail), 'Should detect no changes');

        existingOrgWideEmail.Active__c = false;
        System.assert(orgWideEmailDTO.hasChanges(existingOrgWideEmail), 'Should detect a change in Active');
    }

    @isTest
    static void testGenerateDeveloperName() {
        OrgWideEmailDTO orgWideEmailDTO = new OrgWideEmailDTO();
        String developerName = orgWideEmailDTO.generateDeveloperName('abc+123@example.com');
        System.assertEquals('abc_123_example_com', developerName, 'Expected special characters to be replaced');
    }
}