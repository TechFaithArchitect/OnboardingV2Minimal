public with sharing class VendorFilterController {
  @InvocableMethod(
    label='Get Available Vendors Controller'
    description='Retrieve vendors without onboarding records for a given account.'
  )
  public static List<String> getVendorsAsJson(List<Id> accountIds) {
    if (accountIds == null || accountIds.isEmpty()) {
      return new List<String>{ '[]' };
    }

    // This service handles bulk accounts, but we expect only 1 here
    List<List<VendorOptionDTO>> results = VendorOnboardingService.getEligibleVendors(
      accountIds
    );

    List<VendorOptionDTO> flattened = results.isEmpty()
      ? new List<VendorOptionDTO>()
      : results[0];

    String json = JSON.serialize(flattened);
    return new List<String>{ json };
  }
}
