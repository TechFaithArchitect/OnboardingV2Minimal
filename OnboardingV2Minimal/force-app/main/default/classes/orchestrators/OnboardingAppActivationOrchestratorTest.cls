@isTest
public class OnboardingAppActivationOrchestratorTest {
  // NOTE: This test class now tests OnboardingAppActivationService.activate()
  // after consolidating OnboardingAppActivationOrchestrator into the service

  @isTest
  static void testActivate_forVendorCustomization() {
    Vendor__c vendor = TestDataFactory.createVendor(true);
    Vendor_Customization__c draftRecord = TestDataFactory.createVendorCustomization(
      vendor,
      'Draft',
      false,
      null,
      true
    );

    Test.startTest();
    OnboardingAppActivationService.activate(
      draftRecord.Id,
      'Vendor_Customization__c'
    );
    Test.stopTest();

    Vendor_Customization__c updated = [
      SELECT Status__c, Active__c
      FROM Vendor_Customization__c
      WHERE Id = :draftRecord.Id
    ];

    System.assertEquals('Active', updated.Status__c);
    System.assertEquals(true, updated.Active__c);
  }

  @isTest
  static void testActivate_forGenericNonVersionedObject() {
    Communication_Template__c template = TestDataFactory.createCommunicationTemplate(
      false,
      true
    );

    Test.startTest();
    OnboardingAppActivationService.activate(
      template.Id,
      'Communication_Template__c'
    );
    Test.stopTest();

    Communication_Template__c updated = [
      SELECT Active__c
      FROM Communication_Template__c
      WHERE Id = :template.Id
    ];
    System.assertEquals(true, updated.Active__c);
  }

  @isTest
  static void testActivate_withMissingParams() {
    Test.startTest();
    try {
      OnboardingAppActivationService.activate(null, null);
      System.assert(false, 'Expected AuraHandledException');
    } catch (AuraHandledException auraHandledException) {
      System.assertEquals(
        'Script-thrown exception',
        auraHandledException.getMessage()
      );
    }
    Test.stopTest();
  }
}
