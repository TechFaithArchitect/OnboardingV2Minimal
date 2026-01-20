public with sharing class VendorOnboardingController {
  /**
   * Gets eligible vendor options for a given account.
   * Used by Flows, LWC, and adapters.
   */
  public static List<VendorOptionDTO> getEligibleVendorOptions(Id accountId) {
    List<Id> accountIds = new List<Id>{ accountId };

    List<List<VendorOptionDTO>> results = VendorOnboardingService.getEligibleVendors(
      accountIds
    );

    // Return first result if available
    return results.isEmpty() ? new List<VendorOptionDTO>() : results[0];
  }

  /**
   * Gets eligible vendor options for multiple accounts.
   * Used internally by Flow Adapter that supports bulk input.
   */
  public static List<List<VendorOptionDTO>> getEligibleVendorOptionsForAccounts(
    List<Id> accountIds
  ) {
    return VendorOnboardingService.getEligibleVendors(accountIds);
  }

  /**
   * Returns JSON string of eligible vendor options for a given account.
   * Used by LWC-friendly Flow Adapters.
   */
  public static String getEligibleVendorOptionsAsJson(Id accountId) {
    List<VendorOptionDTO> options = getEligibleVendorOptions(accountId);
    return JSON.serialize(options);
  }
}
