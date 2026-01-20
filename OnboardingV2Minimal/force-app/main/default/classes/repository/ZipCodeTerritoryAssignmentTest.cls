@isTest
private class ZipCodeTerritoryAssignmentTest {

    @isTest
    static void testConstructor_WithAllParameters() {
        Id testOwnerId = UserInfo.getUserId();
        String division = 'West';
        String region = 'California';
        String territory = 'LA';

        Test.startTest();
        ZipCodeTerritoryAssignment assignment = new ZipCodeTerritoryAssignment(
            testOwnerId, division, region, territory
        );
        Test.stopTest();

        System.assertEquals(testOwnerId, assignment.ownerId, 'Owner ID should be set');
        System.assertEquals(division, assignment.division, 'Division should be set');
        System.assertEquals(region, assignment.region, 'Region should be set');
        System.assertEquals(territory, assignment.territory, 'Territory should be set');
    }

    @isTest
    static void testConstructor_WithNullValues() {
        Test.startTest();
        ZipCodeTerritoryAssignment assignment = new ZipCodeTerritoryAssignment(
            null, null, null, null
        );
        Test.stopTest();

        System.assertEquals(null, assignment.ownerId, 'Owner ID can be null');
        System.assertEquals(null, assignment.division, 'Division can be null');
        System.assertEquals(null, assignment.region, 'Region can be null');
        System.assertEquals(null, assignment.territory, 'Territory can be null');
    }
}