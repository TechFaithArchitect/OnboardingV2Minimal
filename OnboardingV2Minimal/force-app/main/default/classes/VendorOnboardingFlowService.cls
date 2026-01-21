public with sharing class VendorOnboardingFlowService {
  @InvocableMethod(label='Get Eligible Vendors for Onboarding')
  public static List<List<VendorOptionDTO>> getEligibleVendors(
    List<Id> accountIds
  ) {
    List<List<VendorOptionDTO>> allResults = new List<List<VendorOptionDTO>>();
    VendorPrerequisiteEvaluator.PrereqMap prereqMap = VendorPrerequisiteEvaluator.getActivePrerequisites();

    for (Id accountId : accountIds) {
      List<VendorOptionDTO> vendorOptionDTOList = new List<VendorOptionDTO>();

      // ✅ Get already onboarded vendor program IDs and the associated vendor IDs
      Set<Id> onboardedVendorIds = new Set<Id>();
      Set<Id> onboardedCustomizationIds = new Set<Id>();

      for (Onboarding__c onboardingRecord : [
        SELECT Vendor_Customization__r.Vendor__c, Vendor_Customization__c
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

      // ✅ Get eligible vendors (not onboarded yet)
      List<Vendor__c> eligibleVendors = [
        SELECT Id, Name
        FROM Vendor__c
        WHERE Active__c = TRUE AND Id NOT IN :onboardedVendorIds
      ];

      Map<Id, Vendor__c> vendorMap = new Map<Id, Vendor__c>();
      for (Vendor__c vendorRecord : eligibleVendors) {
        vendorMap.put(vendorRecord.Id, vendorRecord);
      }

      // ✅ Map retail options to business verticals per vendor
      Map<Id, Map<String, Set<String>>> vendorRetailMap = new Map<Id, Map<String, Set<String>>>();

      for (Vendor_Customization__c vendorCustomization : [
        SELECT Id, Vendor__c, Retail_Option__c, Business_Vertical__c
        FROM Vendor_Customization__c
        WHERE Vendor__c IN :eligibleVendors
      ]) {
        // ✅ Prerequisite check
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

      // ✅ Build DTOs
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

      allResults.add(vendorOptionDTOList);
    }

    return allResults;
  }
}