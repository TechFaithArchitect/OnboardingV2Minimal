@IsTest
private class FlowAdminGuardServiceTest {
    @IsTest
    static void failFastThrowsProvidedMessage() {
        FlowAdminGuardService.Request req = new FlowAdminGuardService.Request();
        req.message = 'Missing mapping for type: Vendor Order Entry';

        try {
            FlowAdminGuardService.failFast(new List<FlowAdminGuardService.Request>{ req });
            System.assert(false, 'Expected exception was not thrown.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Missing mapping for type: Vendor Order Entry'));
        }
    }

    @IsTest
    static void failFastThrowsDefaultMessageWhenInputBlank() {
        FlowAdminGuardService.Request req = new FlowAdminGuardService.Request();
        req.message = null;

        try {
            FlowAdminGuardService.failFast(new List<FlowAdminGuardService.Request>{ req });
            System.assert(false, 'Expected exception was not thrown.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Flow configuration error.'));
        }
    }
}
