@isTest
private class OnboardingAppECCServiceTest {
  @isTest
  static void testPassThroughMethods() {
    // Arrange
    Vendor__c vendor = TestDataFactory.createVendor(true);
    Vendor_Customization__c customization = TestDataFactory.createVendorCustomization(
      vendor,
      'Active',
      true,
      null,
      true
    );
    External_Contact_Credential_Type__c type1 = TestCredentialFactory.createCredentialType(
      'Type A',
      1,
      customization,
      true,
      true
    );
    Required_Credential__c rc = TestCredentialFactory.createRequiredCredential(
      type1,
      customization,
      true,
      true
    );

    // Act - just call the service methods for coverage
    OnboardingAppECCService.getRequiredCredentials(customization.Id);
    OnboardingAppECCService.getAvailableCredentialTypes();

    // Create credential type using object parameter
    External_Contact_Credential_Type__c credentialTypeInput = new External_Contact_Credential_Type__c();
    credentialTypeInput.Name = 'Type B';
    credentialTypeInput.Sort_Order__c = 2;
    credentialTypeInput.Vendor_Customization__c = customization.Id;
    credentialTypeInput.Active__c = true;
    OnboardingAppECCService.createCredentialType(credentialTypeInput);

    OnboardingAppECCService.linkCredentialTypeToRequiredCredential(
      rc.Id,
      type1.Id
    );
  }
}
