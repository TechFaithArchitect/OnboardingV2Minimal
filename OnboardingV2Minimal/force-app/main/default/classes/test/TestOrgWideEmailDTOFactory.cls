@isTest
public class TestOrgWideEmailDTOFactory {

    /**
     * Creates an OrgWideEmailDTO for testing.
     * In test context, creates test data instead of querying for real OrgWideEmailAddress records.
     * This avoids dependency on actual OrgWideEmailAddress records existing in the org.
     * 
     * @param developerName The developer name to use for the DTO
     * @return OrgWideEmailDTO with test data
     */
    public static OrgWideEmailDTO create(String developerName) {
        OrgWideEmailDTO orgWideEmailDTO = new OrgWideEmailDTO();
        orgWideEmailDTO.developerName = developerName;
        orgWideEmailDTO.emailAddress = developerName + '@example.com';
        orgWideEmailDTO.masterLabel = 'Test ' + developerName.replace('_', ' ');
        orgWideEmailDTO.isActive = true;
        // Use a fake ID for the orgWideEmailAddressId since we're in test context
        // Use safeFakeIdForSObject which properly handles Id conversion
        orgWideEmailDTO.orgWideEmailAddressId = TestDataFactoryIdUtil.safeFakeIdForSObject(OrgWideEmailAddress.SObjectType);

        return orgWideEmailDTO;
    }
}