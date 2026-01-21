public with sharing class VendorOnboardingLWCAdapter {
  @AuraEnabled(cacheable=true)
  public static List<VendorOptionDTO> getVendorOptions(Id accountId) {
    if (accountId == null)
      return new List<VendorOptionDTO>();

    List<List<VendorOptionDTO>> allResults = VendorOnboardingService.getEligibleVendors(
      new List<Id>{ accountId }
    );

    return allResults.isEmpty() ? new List<VendorOptionDTO>() : allResults[0];
  }
}