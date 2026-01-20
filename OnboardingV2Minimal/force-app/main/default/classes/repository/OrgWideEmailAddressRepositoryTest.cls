@isTest
private class OrgWideEmailAddressRepositoryTest {

    @isTest
    static void testGetAll() {
        Test.startTest();
        List<OrgWideEmailAddress> result = OrgWideEmailAddressRepository.getAll();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result list should not be null');
    }
}