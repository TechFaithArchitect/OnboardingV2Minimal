@isTest
public class TestOrgWideEmailFactory {
    public static OrgWideEmailDTO create(String devName) {
        OrgWideEmailDTO orgWideEmailDTO = new OrgWideEmailDTO();
        orgWideEmailDTO.developerName = devName;
        orgWideEmailDTO.masterLabel = 'Test Sender';
        orgWideEmailDTO.emailAddress = devName + '@example.com';
        orgWideEmailDTO.orgWideEmailAddressId = String.valueOf(Id.valueOf(TestDataFactoryIdUtil.fakeIdForSObject(OrgWideEmailAddress.SObjectType)));
        orgWideEmailDTO.isActive = true;
        return orgWideEmailDTO;
    }
}