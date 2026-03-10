@isTest
private class VendorOnboardingFlowAdapterTest {
  private static final Set<String> NON_BLOCKING_STATUSES = new Set<String>{
    'DENIED',
    'CANCELED',
    'CANCELLED'
  };
  private static final Set<String> COMPLETED_STATUSES = new Set<String>{
    'COMPLETE',
    'COMPLETED',
    'SETUP COMPLETE',
    'SETUP COMPLETED'
  };

  @isTest
  static void testGetEligibleVendorsForFlow() {
    // Setup test Account
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    // Setup test Vendor
    Vendor__c vendor = new Vendor__c(Name = 'Test Vendor', Active__c = true);
    insert vendor;

    // Setup Customization
    Vendor_Customization__c vc = new Vendor_Customization__c(
      Vendor__c = vendor.Id,
      Active__c = true,
      Retail_Option__c = 'National Agent',
      Business_Vertical__c = 'D2D'
    );
    setVendorCustomizationStatuses(new List<Vendor_Customization__c>{ vc });
    insert vc;

    // Mock prerequisites — skip logic for now unless testing the full evaluator
    Test.startTest();
    List<Id> accountIds = new List<Id>{ acct.Id };
    List<VendorOnboardingDTO> results = VendorOnboardingService.getEligibleVendorsForFlow(
      accountIds
    );
    Test.stopTest();

    System.assertNotEquals(
      0,
      results.size(),
      'Expected at least one DTO returned'
    );
    VendorOnboardingDTO dto = results[0];
    System.assertEquals(vendor.Id, dto.vendorId);
    System.assertEquals(vendor.Name, dto.vendorName);
    System.assert(dto.availableRetailOptions.contains('National Agent'));
  }

  @isTest
  static void testCanceledAndDeniedDoNotBlockEligibility() {
    Account acct = new Account(Name = 'Eligibility Status Account');
    insert acct;

    Vendor__c activeVendor = new Vendor__c(
      Name = 'Eligible Vendor',
      Active__c = true
    );
    Vendor__c inactiveVendor = new Vendor__c(
      Name = 'Inactive Vendor',
      Active__c = false
    );
    insert new List<Vendor__c>{ activeVendor, inactiveVendor };

    Vendor_Customization__c deniedProgram = new Vendor_Customization__c(
      Vendor__c = activeVendor.Id,
      Active__c = true,
      Retail_Option__c = 'National Agent',
      Business_Vertical__c = 'D2D'
    );
    Vendor_Customization__c canceledProgram = new Vendor_Customization__c(
      Vendor__c = activeVendor.Id,
      Active__c = true,
      Retail_Option__c = 'National Retail',
      Business_Vertical__c = 'National Retail'
    );
    Vendor_Customization__c inactiveProgram = new Vendor_Customization__c(
      Vendor__c = activeVendor.Id,
      Active__c = false,
      Retail_Option__c = 'N/A',
      Business_Vertical__c = 'N/A'
    );
    Vendor_Customization__c inactiveVendorProgram = new Vendor_Customization__c(
      Vendor__c = inactiveVendor.Id,
      Active__c = true,
      Retail_Option__c = 'Amendment',
      Business_Vertical__c = 'D2D'
    );
    List<Vendor_Customization__c> statusPrograms = new List<Vendor_Customization__c>{
      deniedProgram,
      canceledProgram,
      inactiveProgram,
      inactiveVendorProgram
    };
    setVendorCustomizationStatuses(statusPrograms);
    insert statusPrograms;

    List<String> validStatuses = getPicklistValues(
      Onboarding__c.Onboarding_Status__c
    );
    String deniedStatus = pickFirstAvailableStatus(
      validStatuses,
      new List<String>{ 'Denied' }
    );
    String canceledStatus = pickFirstAvailableStatus(
      validStatuses,
      new List<String>{ 'Canceled', 'Cancelled' }
    );
    insert new List<Onboarding__c>{
      new Onboarding__c(
        Account__c = acct.Id,
        Vendor_Customization__c = deniedProgram.Id,
        Onboarding_Status__c = deniedStatus
      ),
      new Onboarding__c(
        Account__c = acct.Id,
        Vendor_Customization__c = canceledProgram.Id,
        Onboarding_Status__c = canceledStatus
      )
    };

    Test.startTest();
    List<VendorOnboardingDTO> results = VendorOnboardingFlowAdapter.getEligibleVendorsForFlow(
      new List<Id>{ acct.Id }
    );
    Test.stopTest();

    System.assertEquals(
      1,
      results.size(),
      'Only active vendors with eligible programs should be returned'
    );

    Set<String> retailOptions = new Set<String>(results[0].availableRetailOptions);
    System.assert(
      retailOptions.contains('National Agent'),
      'Denied onboarding should not block this vendor program'
    );
    System.assert(
      retailOptions.contains('National Retail'),
      'Canceled onboarding should not block this vendor program'
    );
    System.assert(
      !retailOptions.contains('N/A'),
      'Inactive vendor programs should not be eligible'
    );
  }

  @isTest
  static void testUnorderedVendorBlocksDuplicateProgramOptionsAndKeepsOtherPrograms() {
    Account acct = new Account(Name = 'Single Vendor Rule Account');
    insert acct;

    Vendor__c verizonVendor = new Vendor__c(Name = 'Verizon', Active__c = true);
    Vendor__c perfectVisionVendor = new Vendor__c(
      Name = 'PerfectVision',
      Active__c = true
    );
    Vendor__c frontierVendor = new Vendor__c(Name = 'Frontier', Active__c = true);
    insert new List<Vendor__c>{ verizonVendor, perfectVisionVendor, frontierVendor };

    List<String> businessVerticalValues = getPicklistValues(
      Vendor_Customization__c.Business_Vertical__c
    );
    System.assert(
      !businessVerticalValues.isEmpty(),
      'Expected at least one business vertical picklist value'
    );
    String businessVerticalValue = businessVerticalValues[0];

    Vendor_Customization__c verizonProgram = new Vendor_Customization__c(
      Vendor__c = verizonVendor.Id,
      Active__c = true,
      Retail_Option__c = 'Fios',
      Business_Vertical__c = businessVerticalValue
    );
    Vendor_Customization__c perfectVisionCompletedProgram = new Vendor_Customization__c(
      Vendor__c = perfectVisionVendor.Id,
      Active__c = true,
      Retail_Option__c = 'N/A',
      Business_Vertical__c = businessVerticalValue
    );
    Vendor_Customization__c perfectVisionExtraProgram = new Vendor_Customization__c(
      Vendor__c = perfectVisionVendor.Id,
      Active__c = true,
      Retail_Option__c = 'N/A',
      Business_Vertical__c = businessVerticalValue
    );
    Vendor_Customization__c frontierRequiredProgram = new Vendor_Customization__c(
      Vendor__c = frontierVendor.Id,
      Active__c = true,
      Retail_Option__c = 'Nation Agent',
      Business_Vertical__c = businessVerticalValue
    );
    Vendor_Customization__c frontierTargetProgram = new Vendor_Customization__c(
      Vendor__c = frontierVendor.Id,
      Active__c = true,
      Retail_Option__c = 'Frontier Amendment',
      Business_Vertical__c = businessVerticalValue
    );
    List<Vendor_Customization__c> unorderedPrograms = new List<Vendor_Customization__c>{
      verizonProgram,
      perfectVisionCompletedProgram,
      perfectVisionExtraProgram,
      frontierRequiredProgram,
      frontierTargetProgram
    };
    setVendorCustomizationStatuses(unorderedPrograms);
    insert unorderedPrograms;

    List<String> logicTypeValues = getPicklistValues(
      Vendor_Program_Group__c.Logic_Type__c
    );
    String groupLogicType = logicTypeValues.contains('OR')
      ? 'OR'
      : logicTypeValues[0];

    Vendor_Program_Group__c programGroup = new Vendor_Program_Group__c(
      Name = 'Frontier Reopen Group',
      Label__c = 'Frontier Reopen Group',
      Active__c = true,
      Logic_Type__c = groupLogicType
    );
    insert programGroup;

    insert new List<Vendor_Program_Group_Member__c>{
      buildGroupMember(programGroup.Id, frontierTargetProgram.Id, true),
      buildGroupMember(programGroup.Id, frontierRequiredProgram.Id, false)
    };

    List<String> onboardingStatuses = getPicklistValues(
      Onboarding__c.Onboarding_Status__c
    );
    String canceledStatus = pickFirstAvailableStatus(
      onboardingStatuses,
      new List<String>{ 'Canceled', 'Cancelled' }
    );
    String completedStatus = pickCompletedStatus(onboardingStatuses);
    String blockingNonCompletedStatus = pickBlockingNonCompletedStatus(
      onboardingStatuses
    );

    insert new List<Onboarding__c>{
      new Onboarding__c(
        Account__c = acct.Id,
        Vendor_Customization__c = verizonProgram.Id,
        Onboarding_Status__c = canceledStatus
      ),
      new Onboarding__c(
        Account__c = acct.Id,
        Vendor_Customization__c = perfectVisionCompletedProgram.Id,
        Onboarding_Status__c = completedStatus
      ),
      new Onboarding__c(
        Account__c = acct.Id,
        Vendor_Customization__c = frontierRequiredProgram.Id,
        Onboarding_Status__c = blockingNonCompletedStatus
      )
    };

    Test.startTest();
    List<VendorOnboardingDTO> results = VendorOnboardingFlowAdapter.getEligibleVendorsForFlow(
      new List<Id>{ acct.Id }
    );
    Test.stopTest();

    Set<String> vendorNames = new Set<String>();
    for (VendorOnboardingDTO dto : results) {
      vendorNames.add(dto.vendorName);
    }

    System.assertEquals(1, vendorNames.size(), 'Expected one eligible vendor');
    System.assert(vendorNames.contains('Verizon'));
    System.assert(
      !vendorNames.contains('PerfectVision'),
      'PerfectVision should be hidden because any blocking onboarding for N/A blocks all N/A customizations for that vendor'
    );
    System.assert(
      !vendorNames.contains('Frontier'),
      'Frontier should remain hidden until target prerequisite completion unlocks it'
    );
  }

  @isTest
  static void testPrerequisitesRequireCompletedStatus() {
    Account acct = new Account(Name = 'Prereq Completion Account');
    insert acct;

    Vendor__c frontierVendor = new Vendor__c(Name = 'Frontier', Active__c = true);
    insert frontierVendor;

    List<String> businessVerticalValues = getPicklistValues(
      Vendor_Customization__c.Business_Vertical__c
    );
    System.assert(
      !businessVerticalValues.isEmpty(),
      'Expected at least one business vertical picklist value'
    );
    String businessVerticalValue = businessVerticalValues[0];

    Vendor_Customization__c requiredProgram = new Vendor_Customization__c(
      Vendor__c = frontierVendor.Id,
      Active__c = true,
      Retail_Option__c = 'Nation Agent',
      Business_Vertical__c = businessVerticalValue
    );
    Vendor_Customization__c targetProgram = new Vendor_Customization__c(
      Vendor__c = frontierVendor.Id,
      Active__c = true,
      Retail_Option__c = 'Frontier Amendment',
      Business_Vertical__c = businessVerticalValue
    );
    List<Vendor_Customization__c> prereqPrograms = new List<Vendor_Customization__c>{
      requiredProgram,
      targetProgram
    };
    setVendorCustomizationStatuses(prereqPrograms);
    insert prereqPrograms;

    List<String> logicTypeValues = getPicklistValues(
      Vendor_Program_Group__c.Logic_Type__c
    );
    String groupLogicType = logicTypeValues.contains('OR')
      ? 'OR'
      : logicTypeValues[0];

    Vendor_Program_Group__c programGroup = new Vendor_Program_Group__c(
      Name = 'Frontier Nation Agent Group',
      Label__c = 'Frontier National Agent',
      Active__c = true,
      Logic_Type__c = groupLogicType
    );
    insert programGroup;

    insert new List<Vendor_Program_Group_Member__c>{
      buildGroupMember(programGroup.Id, targetProgram.Id, true),
      buildGroupMember(programGroup.Id, requiredProgram.Id, false)
    };

    List<String> validStatuses = getPicklistValues(
      Onboarding__c.Onboarding_Status__c
    );
    String inProgressBlockingStatus = pickBlockingNonCompletedStatus(
      validStatuses
    );
    String completedStatus = pickCompletedStatus(validStatuses);

    Onboarding__c onboardingRecord = new Onboarding__c(
      Account__c = acct.Id,
      Vendor_Customization__c = requiredProgram.Id,
      Onboarding_Status__c = inProgressBlockingStatus
    );
    insert onboardingRecord;

    List<VendorOnboardingDTO> inProgressResults = VendorOnboardingFlowAdapter.getEligibleVendorsForFlow(
      new List<Id>{ acct.Id }
    );

    Set<String> inProgressRetailOptions = flattenRetailOptions(
      inProgressResults
    );
    System.assert(
      !inProgressRetailOptions.contains('Frontier Amendment'),
      'Target program should not be eligible until prerequisites are completed'
    );

    insert new Onboarding__c(
      Account__c = acct.Id,
      Vendor_Customization__c = requiredProgram.Id,
      Onboarding_Status__c = completedStatus
    );

    List<VendorOnboardingDTO> completedResults = VendorOnboardingFlowAdapter.getEligibleVendorsForFlow(
      new List<Id>{ acct.Id }
    );

    Set<String> completedRetailOptions = flattenRetailOptions(completedResults);
    System.assert(
      completedRetailOptions.contains('Frontier Amendment'),
      'Target program should become eligible when a prerequisite reaches completed status'
    );
  }

  private static String pickFirstAvailableStatus(
    List<String> statuses,
    List<String> preferredValues
  ) {
    System.assert(
      statuses != null && !statuses.isEmpty(),
      'Expected at least one onboarding status value'
    );
    for (String preferredValue : preferredValues) {
      if (statuses.contains(preferredValue)) {
        return preferredValue;
      }
    }
    return statuses[0];
  }

  private static String pickBlockingNonCompletedStatus(List<String> statuses) {
    for (String statusValue : statuses) {
      if (String.isBlank(statusValue)) {
        continue;
      }

      String normalizedStatus = statusValue.trim().toUpperCase();
      if (
        !NON_BLOCKING_STATUSES.contains(normalizedStatus) &&
        !COMPLETED_STATUSES.contains(normalizedStatus)
      ) {
        return statusValue;
      }
    }

    System.assert(
      false,
      'Expected at least one blocking onboarding status that is not completed'
    );
    return null;
  }

  private static String pickCompletedStatus(List<String> statuses) {
    for (String statusValue : statuses) {
      if (String.isBlank(statusValue)) {
        continue;
      }

      if (COMPLETED_STATUSES.contains(statusValue.trim().toUpperCase())) {
        return statusValue;
      }
    }

    System.assert(false, 'Expected at least one completed onboarding status');
    return null;
  }

  private static Set<String> flattenRetailOptions(
    List<VendorOnboardingDTO> results
  ) {
    Set<String> retailOptions = new Set<String>();

    for (VendorOnboardingDTO vendorResult : results) {
      retailOptions.addAll(vendorResult.availableRetailOptions);
    }

    return retailOptions;
  }

  private static Vendor_Program_Group_Member__c buildGroupMember(
    Id groupId,
    Id requiredProgramId,
    Boolean isTarget
  ) {
    Vendor_Program_Group_Member__c member = new Vendor_Program_Group_Member__c(
      Vendor_Program_Group__c = groupId,
      Is_Target__c = isTarget,
      Active__c = true
    );
    member.put(getRequiredProgramFieldApiName(), requiredProgramId);
    return member;
  }

  private static String getRequiredProgramFieldApiName() {
    Map<String, Schema.SObjectField> fields = Vendor_Program_Group_Member__c.SObjectType
      .getDescribe()
      .fields
      .getMap();

    if (fields.containsKey('Required_Program__c')) {
      return 'Required_Program__c';
    }
    if (fields.containsKey('Required_Customization__c')) {
      return 'Required_Customization__c';
    }

    System.assert(
      false,
      'Vendor_Program_Group_Member__c must have Required_Program__c or Required_Customization__c'
    );
    return null;
  }

  private static List<String> getPicklistValues(Schema.SObjectField fieldRef) {
    List<String> values = new List<String>();

    for (Schema.PicklistEntry entry : fieldRef.getDescribe().getPicklistValues()) {
      values.add(entry.getValue());
    }

    return values;
  }

  private static void setVendorCustomizationStatuses(
    List<Vendor_Customization__c> programs
  ) {
    if (programs == null || programs.isEmpty()) {
      return;
    }

    String activeStatus = pickVendorCustomizationStatus(true);
    String inactiveStatus = pickVendorCustomizationStatus(false);

    for (Vendor_Customization__c program : programs) {
      if (program == null) {
        continue;
      }
      Boolean isActive = program.Active__c == true;
      program.Status__c = isActive ? activeStatus : inactiveStatus;
    }
  }

  private static String pickVendorCustomizationStatus(Boolean wantActive) {
    List<String> statuses = getPicklistValues(Vendor_Customization__c.Status__c);
    if (statuses.isEmpty()) {
      return null;
    }

    String activeStatus;
    String inactiveStatus;
    for (String status : statuses) {
      if (String.isBlank(status)) {
        continue;
      }
      String normalized = status.trim().toUpperCase();
      if (
        activeStatus == null &&
        (normalized == 'ACTIVE' ||
        (normalized.contains('ACTIVE') && !normalized.contains('INACTIVE')))
      ) {
        activeStatus = status;
      }
      if (inactiveStatus == null && normalized.contains('INACTIVE')) {
        inactiveStatus = status;
      }
    }

    if (wantActive) {
      return activeStatus == null ? statuses[0] : activeStatus;
    }

    if (inactiveStatus != null) {
      return inactiveStatus;
    }

    if (activeStatus != null) {
      for (String status : statuses) {
        if (status != activeStatus) {
          return status;
        }
      }
    }

    return statuses[0];
  }
}
