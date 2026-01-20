/**
 * Service for Vendor Onboarding operations
 * Consolidates VendorOnboardingFlowService, VendorOnboardingServiceLWC, VendorOnboardingJsonService,
 * VendorOnboardingLWCAdapter, VendorOnboardingJsonAdapter, VendorOnboardingFlowAdapter
 * Phase 3: Adapter Consolidation
 */
public with sharing class VendorOnboardingService {
  /**
   * Core business logic to determine eligible vendors.
   * Accepts one or many accountIds.
   * Consolidates VendorOnboardingFlowService - removed duplicate service
   * Note: Not @InvocableMethod - use getEligibleVendorsForFlow for Flow integration
   */
  public static List<List<VendorOptionDTO>> getEligibleVendors(
    List<Id> accountIds
  ) {
    List<List<VendorOptionDTO>> allResults = new List<List<VendorOptionDTO>>();

    VendorPrerequisiteEvaluator.PrereqMap prereqMap = VendorPrerequisiteEvaluator.getActivePrerequisites();

    for (Id accountId : accountIds) {
      allResults.add(getEligibleVendorsForSingleAccount(accountId, prereqMap));
    }

    return allResults;
  }

  // --- PRIVATE: Handles logic for one account ---
  private static List<VendorOptionDTO> getEligibleVendorsForSingleAccount(
    Id accountId,
    VendorPrerequisiteEvaluator.PrereqMap prereqMap
  ) {
    List<VendorOptionDTO> vendorOptionDTOList = new List<VendorOptionDTO>();

    // Get already onboarded vendor program IDs and vendor IDs
    Set<Id> onboardedVendorIds = new Set<Id>();
    Set<Id> onboardedCustomizationIds = new Set<Id>();

    for (Onboarding__c onboardingRecord : [
      SELECT Vendor_Customization__c, Vendor_Customization__r.Vendor__c
      FROM Onboarding__c
      WHERE Account__c = :accountId AND Vendor_Customization__c != NULL
    ]) {
      onboardedCustomizationIds.add(onboardingRecord.Vendor_Customization__c);

      if (onboardingRecord.Vendor_Customization__r.Vendor__c != null) {
        onboardedVendorIds.add(
          onboardingRecord.Vendor_Customization__r.Vendor__c
        );
      }
    }

    // Get eligible vendors (not onboarded yet)
    List<Vendor__c> eligibleVendors = [
      SELECT Id, Name
      FROM Vendor__c
      WHERE Active__c = TRUE AND Id NOT IN :onboardedVendorIds
    ];

    Map<Id, Vendor__c> vendorMap = new Map<Id, Vendor__c>(eligibleVendors);

    // Build customization → retail options → verticals map
    Map<Id, Map<String, Set<String>>> vendorRetailMap = new Map<Id, Map<String, Set<String>>>();

    for (Vendor_Customization__c vendorCustomization : [
      SELECT Id, Vendor__c, Retail_Option__c, Business_Vertical__c
      FROM Vendor_Customization__c
      WHERE Vendor__c IN :eligibleVendors
    ]) {
      // Prereq logic unchanged
      if (
        !VendorPrerequisiteEvaluator.isCustomizationEligible(
          vendorCustomization.Id,
          onboardedCustomizationIds,
          prereqMap
        )
      ) {
        continue;
      }

      if (String.isBlank(vendorCustomization.Retail_Option__c))
        continue;

      if (!vendorRetailMap.containsKey(vendorCustomization.Vendor__c)) {
        vendorRetailMap.put(
          vendorCustomization.Vendor__c,
          new Map<String, Set<String>>()
        );
      }

      Map<String, Set<String>> retailToVerticals = vendorRetailMap.get(
        vendorCustomization.Vendor__c
      );

      if (
        !retailToVerticals.containsKey(vendorCustomization.Retail_Option__c)
      ) {
        retailToVerticals.put(
          vendorCustomization.Retail_Option__c,
          new Set<String>()
        );
      }

      if (!String.isBlank(vendorCustomization.Business_Vertical__c)) {
        retailToVerticals.get(vendorCustomization.Retail_Option__c)
          .add(vendorCustomization.Business_Vertical__c);
      }
    }

    // Build DTOs
    for (Id vendorId : vendorRetailMap.keySet()) {
      Vendor__c vendorRecord = vendorMap.get(vendorId);
      Map<String, Set<String>> retailOptions = vendorRetailMap.get(vendorId);

      for (String retailOption : retailOptions.keySet()) {
        VendorOptionDTO vendorOptionDTO = new VendorOptionDTO();
        vendorOptionDTO.vendorId = vendorRecord.Id;
        vendorOptionDTO.vendorName = vendorRecord.Name;
        vendorOptionDTO.retailOption = retailOption;
        vendorOptionDTO.businessVerticals = new List<String>(
          retailOptions.get(retailOption)
        );
        vendorOptionDTOList.add(vendorOptionDTO);
      }
    }

    return vendorOptionDTOList;
  }

  // ============================================
  // LWC ADAPTER METHODS
  // Consolidates VendorOnboardingLWCAdapter and VendorOnboardingServiceLWC
  // ============================================

  /**
   * Gets vendor options for a single account (LWC-friendly)
   * Consolidates VendorOnboardingLWCAdapter.getVendorOptions
   */
  @AuraEnabled(cacheable=true)
  public static List<VendorOptionDTO> getVendorOptions(Id accountId) {
    if (accountId == null) {
      return new List<VendorOptionDTO>();
    }

    List<List<VendorOptionDTO>> allResults = getEligibleVendors(
      new List<Id>{ accountId }
    );

    return allResults.isEmpty() ? new List<VendorOptionDTO>() : allResults[0];
  }

  // ============================================
  // JSON ADAPTER METHODS
  // Consolidates VendorOnboardingJsonAdapter and VendorOnboardingJsonService
  // ============================================

  /**
   * Gets eligible vendors as JSON string (for Flow/LWC)
   * Consolidates VendorOnboardingJsonAdapter.getVendorsAsJson
   * Note: This method can be called from Flow but uses @InvocableMethod wrapper in separate action class
   */
  @InvocableMethod(label='Get Eligible Vendors as JSON')
  public static List<String> getVendorsAsJson(List<Id> accountIds) {
    if (accountIds == null || accountIds.isEmpty()) {
      return new List<String>{ '[]' };
    }

    // This service handles bulk accounts, but we expect only 1 here
    List<List<VendorOptionDTO>> results = getEligibleVendors(accountIds);

    List<VendorOptionDTO> flattened = results.isEmpty()
      ? new List<VendorOptionDTO>()
      : results[0];

    String json = JSON.serialize(flattened);
    return new List<String>{ json };
  }

  // ============================================
  // FLOW ADAPTER METHODS
  // Consolidates VendorOnboardingFlowAdapter
  // ============================================

  /**
   * Gets eligible vendors for Flow (grouped by vendor)
   * Consolidates VendorOnboardingFlowAdapter.getEligibleVendorsForFlow
   * Note: Removed @InvocableMethod - use getVendorsAsJson for Flow integration
   */
  public static List<VendorOnboardingDTO> getEligibleVendorsForFlow(
    List<Id> accountIds
  ) {
    List<VendorOnboardingDTO> results = new List<VendorOnboardingDTO>();

    if (accountIds == null || accountIds.isEmpty()) {
      return results;
    }

    List<List<VendorOptionDTO>> perAccountResults = getEligibleVendors(
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
