@isTest
private class OnboardingOrderControllerTest {
  @isTest
  static void testGetOrderStatus_withData() {
    // Create required Account
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    // Create Opportunity
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      AccountId = acct.Id
    );
    insert opp;

    // Create Onboarding__c with lookup to Opportunity
    Onboarding__c onboarding = new Onboarding__c(
      Account__c = acct.Id, // Assuming this is the MD field
      Opportunity__c = opp.Id // Lookup field to Opportunity
    );
    insert onboarding;

    // Create related Order
    Order ord = new Order(
      AccountId = acct.Id,
      OpportunityId = opp.Id,
      Status = 'Draft',
      EffectiveDate = Date.today()
    );
    insert ord;

    // Refresh Order to get auto-generated fields
    ord = [
      SELECT Id, OrderNumber, Status, EffectiveDate, ActivatedDate
      FROM Order
      WHERE Id = :ord.Id
    ];

    // Call the method
    Test.startTest();
    List<OnboardingOrderController.OrderInfo> result = OnboardingOrderController.getOrderStatus(
      onboarding.Id
    );
    Test.stopTest();

    // Validate
    System.assertEquals(1, result.size(), 'Should return one order');
    System.assertEquals(ord.Id, result[0].orderId);
    System.assertEquals(ord.Status, result[0].status);
    System.assertEquals(ord.OrderNumber, result[0].orderNumber);
    System.assertEquals(ord.EffectiveDate, result[0].effectiveDate);
    System.assertEquals(ord.ActivatedDate, result[0].activatedDate);
  }

  @isTest
  static void testGetOrderStatus_noOpportunity() {
    // Create Account
    Account acct = new Account(Name = 'No Opp Account');
    insert acct;

    // Create Onboarding__c without linking an Opportunity
    Onboarding__c onboarding = new Onboarding__c(Account__c = acct.Id);
    insert onboarding;

    Test.startTest();
    List<OnboardingOrderController.OrderInfo> result = OnboardingOrderController.getOrderStatus(
      onboarding.Id
    );
    Test.stopTest();

    System.assertEquals(
      0,
      result.size(),
      'Should return no orders if no opportunity linked'
    );
  }

  @isTest
  static void testGetOrderStatus_noOrders() {
    // Create Account
    Account acct = new Account(Name = 'No Orders Account');
    insert acct;

    // Create Opportunity
    Opportunity opp = new Opportunity(
      Name = 'No Orders Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      AccountId = acct.Id
    );
    insert opp;

    // Onboarding with Opportunity
    Onboarding__c onboarding = new Onboarding__c(
      Account__c = acct.Id,
      Opportunity__c = opp.Id
    );
    insert onboarding;

    Test.startTest();
    List<OnboardingOrderController.OrderInfo> result = OnboardingOrderController.getOrderStatus(
      onboarding.Id
    );
    Test.stopTest();

    System.assertEquals(
      0,
      result.size(),
      'Should return empty list if no orders found'
    );
  }
}
