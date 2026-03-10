public with sharing class VendorOnboardingFlowService {
  @InvocableMethod(label='Get Eligible Vendors for Onboarding')
  public static List<List<VendorOptionDTO>> getEligibleVendors(
    List<Id> accountIds
  ) {
    return VendorOnboardingService.getEligibleVendors(accountIds);
  }
}
