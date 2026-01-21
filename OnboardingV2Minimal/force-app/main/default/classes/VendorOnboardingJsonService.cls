public with sharing class VendorOnboardingJsonService {
  @InvocableMethod(label='Get Eligible Vendors (JSON for LWC)')
  public static List<String> getVendorsAsJson(List<Id> accountIds) {
    List<List<VendorOptionDTO>> vendorDTOsPerAccount = VendorOnboardingFlowService.getEligibleVendors(
      accountIds
    );

    List<VendorOptionDTO> singleAccountList = vendorDTOsPerAccount.isEmpty()
      ? new List<VendorOptionDTO>()
      : vendorDTOsPerAccount[0];

    String json = JSON.serialize(singleAccountList);
    return new List<String>{ json };
  }
}