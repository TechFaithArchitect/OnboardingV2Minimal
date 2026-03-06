public with sharing class VendorOnboardingFlowService {
  private static final Set<String> NON_BLOCKING_ONBOARDING_STATUSES = new Set<String>{
    'CANCELED',
    'CANCELLED',
    'DENIED'
  };
  private static final Set<String> COMPLETED_ONBOARDING_STATUSES = new Set<String>{
    'COMPLETE',
    'COMPLETED',
    'SETUP COMPLETE',
    'SETUP COMPLETED'
  };

  @InvocableMethod(label='Get Eligible Vendors for Onboarding')
  public static List<List<VendorOptionDTO>> getEligibleVendors(
    List<Id> accountIds
  ) {
    List<List<VendorOptionDTO>> allResults = new List<List<VendorOptionDTO>>();
    VendorPrerequisiteEvaluator.PrereqMap prereqMap = VendorPrerequisiteEvaluator.getActivePrerequisites();

    for (Id accountId : accountIds) {
      List<VendorOptionDTO> vendorOptionDTOList = new List<VendorOptionDTO>();

      // Track vendor programs already onboarded for this account.
      // Canceled/Denied records should not block the program from being shown again.
      Set<Id> blockedCustomizationIds = new Set<Id>();
      Set<Id> completedCustomizationIds = new Set<Id>();
      Set<Id> blockedVendorIds = new Set<Id>();

      for (Onboarding__c onboardingRecord : [
        SELECT Vendor_Customization__c, Vendor_Customization__r.Vendor__c, Onboarding_Status__c
        FROM Onboarding__c
        WHERE Account__c = :accountId AND Vendor_Customization__c != NULL
      ]) {
        if (isNonBlockingOnboardingStatus(onboardingRecord.Onboarding_Status__c)) {
          continue;
        }
        blockedCustomizationIds.add(onboardingRecord.Vendor_Customization__c);
        if (onboardingRecord.Vendor_Customization__r.Vendor__c != null) {
          blockedVendorIds.add(onboardingRecord.Vendor_Customization__r.Vendor__c);
        }
        if (isCompletedOnboardingStatus(onboardingRecord.Onboarding_Status__c)) {
          completedCustomizationIds.add(onboardingRecord.Vendor_Customization__c);
        }
      }

      // Vendors must be active to be eligible.
      List<Vendor__c> eligibleVendors = [
        SELECT Id, Name
        FROM Vendor__c
        WHERE Active__c = TRUE
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
        AND Active__c = TRUE
      ]) {
        if (blockedCustomizationIds.contains(vendorCustomization.Id)) {
          continue;
        }

        if (
          blockedVendorIds.contains(vendorCustomization.Vendor__c) &&
          !VendorPrerequisiteEvaluator.hasPrerequisites(
            vendorCustomization.Id,
            prereqMap
          )
        ) {
          continue;
        }

        // ✅ Prerequisite check
        if (
          !VendorPrerequisiteEvaluator.isCustomizationEligible(
            vendorCustomization.Id,
            completedCustomizationIds,
            blockedCustomizationIds,
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

  private static Boolean isNonBlockingOnboardingStatus(String onboardingStatus) {
    String normalizedOnboardingStatus = normalizeOnboardingStatus(
      onboardingStatus
    );
    return normalizedOnboardingStatus != null &&
      NON_BLOCKING_ONBOARDING_STATUSES.contains(normalizedOnboardingStatus);
  }

  private static Boolean isCompletedOnboardingStatus(String onboardingStatus) {
    String normalizedOnboardingStatus = normalizeOnboardingStatus(
      onboardingStatus
    );
    return normalizedOnboardingStatus != null &&
      COMPLETED_ONBOARDING_STATUSES.contains(normalizedOnboardingStatus);
  }

  private static String normalizeOnboardingStatus(String onboardingStatus) {
    return String.isBlank(onboardingStatus)
      ? null
      : onboardingStatus.trim().toUpperCase();
  }
}
