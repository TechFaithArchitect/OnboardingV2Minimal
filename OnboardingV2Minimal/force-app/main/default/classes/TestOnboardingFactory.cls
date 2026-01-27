@isTest
public class TestOnboardingFactory {
  public static Onboarding__c create(
    Account accountRecord,
    Vendor_Customization__c vendorProgram,
    Boolean doInsert
  ) {
    Onboarding__c onboarding = new Onboarding__c(
      Account__c = accountRecord.Id,
      Vendor_Customization__c = vendorProgram.Id
    );
    if (doInsert)
      insert onboarding;
    return onboarding;
  }
}
