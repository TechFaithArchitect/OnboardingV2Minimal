public with sharing class VendorOnboardingServiceLWC {
  @AuraEnabled(cacheable=true)
  public static List<VendorOptionDTO> getVendorOptions(Id accountId) {
    // ✅ Use centralized service logic
    List<List<VendorOptionDTO>> allResults = VendorOnboardingFlowService.getEligibleVendors(
      new List<Id>{ accountId }
    );

    // ✅ Return first result or empty list
    return allResults.isEmpty() ? new List<VendorOptionDTO>() : allResults[0];
  }
}