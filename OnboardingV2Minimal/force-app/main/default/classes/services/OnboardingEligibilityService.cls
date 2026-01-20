/**
 * Service for determining vendor eligibility for onboarding by Account.
 * Encapsulates vendor/program filtering so controllers avoid unpackaged dependencies.
 */
public with sharing class OnboardingEligibilityService {
  /**
   * Gets eligible vendor counts for the provided accounts using active vendor programs.
   * @param accountIds Account IDs to evaluate
   * @param vendorIds Optional vendor filter
   * @param programIds Optional vendor program filter
   * @return Map of Account Id to eligible vendor count
   */
  public static Map<Id, Integer> getEligibleVendorCountsByAccount(
    List<Id> accountIds,
    List<Id> vendorIds,
    List<Id> programIds
  ) {
    Map<Id, Integer> accountToVendorCount = new Map<Id, Integer>();

    if (accountIds == null || accountIds.isEmpty()) {
      return accountToVendorCount;
    }

    List<Vendor_Customization__c> activePrograms = VendorCustomizationRepository.getActiveVendorPrograms(
      vendorIds,
      programIds
    );

    if (activePrograms.isEmpty()) {
      return accountToVendorCount;
    }

    // Count distinct vendors from the active programs so UI shows vendor availability, not program count.
    Set<Id> eligibleVendors = new Set<Id>();
    for (Vendor_Customization__c vendorProgram : activePrograms) {
      if (vendorProgram.Vendor__c != null) {
        eligibleVendors.add(vendorProgram.Vendor__c);
      }
    }

    if (eligibleVendors.isEmpty()) {
      return accountToVendorCount;
    }

    Integer vendorCount = eligibleVendors.size();
    Set<Id> uniqueAccountIds = new Set<Id>(accountIds);
    for (Id accountId : uniqueAccountIds) {
      accountToVendorCount.put(accountId, vendorCount);
    }

    return accountToVendorCount;
  }
}
