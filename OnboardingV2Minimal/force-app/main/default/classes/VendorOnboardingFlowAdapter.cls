public with sharing class VendorOnboardingFlowAdapter {
  @InvocableMethod(label='Get Eligible Vendors for Flow')
  public static List<VendorOnboardingDTO> getEligibleVendorsForFlow(
    List<Id> accountIds
  ) {
    List<VendorOnboardingDTO> results = new List<VendorOnboardingDTO>();

    if (accountIds == null || accountIds.isEmpty()) {
      return results;
    }

    List<List<VendorOptionDTO>> perAccountResults = VendorOnboardingService.getEligibleVendors(
      accountIds
    );

    // Expecting only 1 account at a time in screen flow
    List<VendorOptionDTO> flatList = perAccountResults.isEmpty()
      ? new List<VendorOptionDTO>()
      : perAccountResults[0];

    // Group vendor options by vendorId
    Map<Id, VendorOnboardingDTO> dtoMap = new Map<Id, VendorOnboardingDTO>();

    for (VendorOptionDTO opt : flatList) {
      if (!dtoMap.containsKey(opt.vendorId)) {
        VendorOnboardingDTO dto = new VendorOnboardingDTO();
        dto.vendorId = opt.vendorId;
        dto.vendorName = opt.vendorName;
        dto.availableRetailOptions = new List<String>();
        dto.retailOptionGroups = new List<VendorRetailOptionGroupDTO>();
        dtoMap.put(opt.vendorId, dto);
      }

      VendorOnboardingDTO existing = dtoMap.get(opt.vendorId);

      if (!existing.availableRetailOptions.contains(opt.retailOption)) {
        existing.availableRetailOptions.add(opt.retailOption);
      }

      VendorRetailOptionGroupDTO retailGroup = new VendorRetailOptionGroupDTO();
      retailGroup.retailOption = opt.retailOption;
      retailGroup.businessVerticals = opt.businessVerticals;

      existing.retailOptionGroups.add(retailGroup);
    }

    return dtoMap.values();
  }
}