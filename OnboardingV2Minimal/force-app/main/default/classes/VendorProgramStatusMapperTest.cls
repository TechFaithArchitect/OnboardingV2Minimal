@isTest
private class VendorProgramStatusMapperTest {

    @isTest
    static void testGetUserFacingStage_ForAdmin_ReturnsTechnicalStatus() {
        Test.startTest();
        String result = VendorProgramStatusMapper.getUserFacingStage('Draft', true);
        Test.stopTest();

        System.assertEquals('Draft', result, 'Admin should see technical status');
    }

    @isTest
    static void testGetUserFacingStage_ForEndUser_MapsToInProgress() {
        Test.startTest();
        String result1 = VendorProgramStatusMapper.getUserFacingStage('Draft', false);
        String result2 = VendorProgramStatusMapper.getUserFacingStage('In Process', false);
        String result3 = VendorProgramStatusMapper.getUserFacingStage('InProgress', false);
        Test.stopTest();

        System.assertEquals('In Progress', result1, 'Draft should map to In Progress');
        System.assertEquals('In Progress', result2, 'In Process should map to In Progress');
        System.assertEquals('In Progress', result3, 'InProgress should map to In Progress');
    }

    @isTest
    static void testGetUserFacingStage_ForEndUser_MapsToReviewPending() {
        Test.startTest();
        String result1 = VendorProgramStatusMapper.getUserFacingStage('Pending Review', false);
        String result2 = VendorProgramStatusMapper.getUserFacingStage('Pending Approval', false);
        String result3 = VendorProgramStatusMapper.getUserFacingStage('Awaiting Review', false);
        String result4 = VendorProgramStatusMapper.getUserFacingStage('Under Review', false);
        Test.stopTest();

        System.assertEquals('Review Pending', result1, 'Pending Review should map to Review Pending');
        System.assertEquals('Review Pending', result2, 'Pending Approval should map to Review Pending');
        System.assertEquals('Review Pending', result3, 'Awaiting Review should map to Review Pending');
        System.assertEquals('Review Pending', result4, 'Under Review should map to Review Pending');
    }

    @isTest
    static void testGetUserFacingStage_ForEndUser_MapsToCompleted() {
        Test.startTest();
        String result1 = VendorProgramStatusMapper.getUserFacingStage('Complete', false);
        String result2 = VendorProgramStatusMapper.getUserFacingStage('Completed', false);
        String result3 = VendorProgramStatusMapper.getUserFacingStage('Approved', false);
        Test.stopTest();

        System.assertEquals('Completed', result1, 'Complete should map to Completed');
        System.assertEquals('Completed', result2, 'Completed should map to Completed');
        System.assertEquals('Completed', result3, 'Approved should map to Completed');
    }

    @isTest
    static void testGetUserFacingStage_WithNull_ReturnsInProgress() {
        Test.startTest();
        String result1 = VendorProgramStatusMapper.getUserFacingStage(null, false);
        String result2 = VendorProgramStatusMapper.getUserFacingStage('', false);
        String result3 = VendorProgramStatusMapper.getUserFacingStage(null, true);
        Test.stopTest();

        System.assertEquals('In Progress', result1, 'Null should default to In Progress for end user');
        System.assertEquals('In Progress', result2, 'Blank should default to In Progress');
        System.assertEquals('In Progress', result3, 'Null should default to In Progress for admin');
    }

    @isTest
    static void testGetUserFacingStage_UnknownStatus_ReturnsInProgress() {
        Test.startTest();
        String result = VendorProgramStatusMapper.getUserFacingStage('Unknown Status', false);
        Test.stopTest();

        System.assertEquals('In Progress', result, 'Unknown status should default to In Progress');
    }

    @isTest
    static void testGetStatusVariant() {
        Test.startTest();
        String variant1 = VendorProgramStatusMapper.getStatusVariant('In Progress');
        String variant2 = VendorProgramStatusMapper.getStatusVariant('Review Pending');
        String variant3 = VendorProgramStatusMapper.getStatusVariant('Completed');
        String variant4 = VendorProgramStatusMapper.getStatusVariant(null);
        String variant5 = VendorProgramStatusMapper.getStatusVariant('Unknown');
        Test.stopTest();

        System.assertEquals('brand', variant1, 'In Progress should return brand variant');
        System.assertEquals('warning', variant2, 'Review Pending should return warning variant');
        System.assertEquals('success', variant3, 'Completed should return success variant');
        System.assertEquals('brand', variant4, 'Null should return brand variant');
        System.assertEquals('brand', variant5, 'Unknown should return brand variant');
    }

    @isTest
    static void testGetStatusIcon() {
        Test.startTest();
        String icon1 = VendorProgramStatusMapper.getStatusIcon('In Progress');
        String icon2 = VendorProgramStatusMapper.getStatusIcon('Review Pending');
        String icon3 = VendorProgramStatusMapper.getStatusIcon('Completed');
        String icon4 = VendorProgramStatusMapper.getStatusIcon(null);
        String icon5 = VendorProgramStatusMapper.getStatusIcon('Unknown');
        Test.stopTest();

        System.assertEquals('utility:clock', icon1, 'In Progress should return clock icon');
        System.assertEquals('utility:approval', icon2, 'Review Pending should return approval icon');
        System.assertEquals('utility:check', icon3, 'Completed should return check icon');
        System.assertEquals('utility:clock', icon4, 'Null should return clock icon');
        System.assertEquals('utility:clock', icon5, 'Unknown should return clock icon');
    }

    @isTest
    static void testIsCurrentUserAdmin() {
        Test.startTest();
        Boolean isAdmin = VendorProgramStatusMapper.isCurrentUserAdmin();
        Test.stopTest();

        // Just verify it doesn't throw and returns a boolean
        System.assertNotEquals(null, isAdmin, 'Should return a boolean value');
    }

    @isTest
    static void testGetUserFacingStageForCurrentUser() {
        Test.startTest();
        String result = VendorProgramStatusMapper.getUserFacingStageForCurrentUser('Draft');
        Test.stopTest();

        // Just verify it doesn't throw and returns a string
        System.assertNotEquals(null, result, 'Should return a string value');
    }
}