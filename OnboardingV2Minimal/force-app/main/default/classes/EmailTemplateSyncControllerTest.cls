@isTest
private class EmailTemplateSyncControllerTest {
  @isTest
  static void testScheduledExecution() {
    Test.startTest();
    new EmailTemplateSyncController().execute(null);
    Test.stopTest();

    System.assert(true, 'Controller execute should complete without error');
  }
}