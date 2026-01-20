public with sharing class OnboardingOrderController {
  public class OrderInfo {
    @AuraEnabled
    public Id orderId;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String orderNumber;
    @AuraEnabled
    public Date effectiveDate;
    @AuraEnabled
    public Datetime activatedDate;
  }

  @AuraEnabled(cacheable=true)
  public static List<OrderInfo> getOrderStatus(Id onboardingId) {
    Onboarding__c ob = [
      SELECT Opportunity__c
      FROM Onboarding__c
      WHERE Id = :onboardingId
      LIMIT 1
    ];

    if (ob.Opportunity__c == null)
      return new List<OrderInfo>();

    List<Order> orders = [
      SELECT Id, Status, OrderNumber, EffectiveDate, ActivatedDate
      FROM Order
      WHERE OpportunityId = :ob.Opportunity__c
      ORDER BY CreatedDate DESC
      LIMIT 10
    ];

    List<OrderInfo> results = new List<OrderInfo>();
    for (Order o : orders) {
      OrderInfo info = new OrderInfo();
      info.orderId = o.Id;
      info.status = o.Status;
      info.orderNumber = o.OrderNumber;
      info.effectiveDate = o.EffectiveDate;
      info.activatedDate = o.ActivatedDate;
      results.add(info);
    }

    return results;
  }
}
