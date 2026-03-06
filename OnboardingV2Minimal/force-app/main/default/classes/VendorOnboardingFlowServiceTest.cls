@isTest
private class VendorOnboardingFlowServiceTest {
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
  static void testReturnsEligibleOptionsForActiveVendor() {
    Account acct = new Account(Name = 'Flow Service Account');
    insert acct;

    Vendor__c vendorRecord = new Vendor__c(
      Name = 'Flow Service Vendor',
      Active__c = true
    );
    insert vendorRecord;

    List<String> businessVerticalValues = getPicklistValues(
      Vendor_Customization__c.Business_Vertical__c
    );
    String businessVertical = businessVerticalValues.isEmpty()
      ? null
      : businessVerticalValues[0];

    Vendor_Customization__c program = new Vendor_Customization__c(
      Vendor__c = vendorRecord.Id,
      Active__c = true,
      Retail_Option__c = 'National Agent',
      Business_Vertical__c = businessVertical
    );
    insert program;

    Test.startTest();
    List<VendorOptionDTO> options = getOptionsForAccount(acct.Id);
    Test.stopTest();

    System.assertEquals(1, options.size(), 'Expected one eligible vendor option');
    System.assertEquals(vendorRecord.Id, options[0].vendorId);
    System.assertEquals('Flow Service Vendor', options[0].vendorName);
    System.assertEquals('National Agent', options[0].retailOption);
  }

  @isTest
  static void testCanceledAndDeniedDoNotBlockEligibility() {
    Account acct = new Account(Name = 'Flow Service Status Account');
    insert acct;

    Vendor__c vendorRecord = new Vendor__c(Name = 'Status Vendor', Active__c = true);
    insert vendorRecord;

    List<String> businessVerticalValues = getPicklistValues(
      Vendor_Customization__c.Business_Vertical__c
    );
    String businessVertical = businessVerticalValues.isEmpty()
      ? null
      : businessVerticalValues[0];

    Vendor_Customization__c deniedProgram = new Vendor_Customization__c(
      Vendor__c = vendorRecord.Id,
      Active__c = true,
      Retail_Option__c = 'National Agent',
      Business_Vertical__c = businessVertical
    );
    Vendor_Customization__c canceledProgram = new Vendor_Customization__c(
      Vendor__c = vendorRecord.Id,
      Active__c = true,
      Retail_Option__c = 'National Retail',
      Business_Vertical__c = businessVertical
    );
    insert new List<Vendor_Customization__c>{ deniedProgram, canceledProgram };

    List<String> onboardingStatuses = getPicklistValues(
      Onboarding__c.Onboarding_Status__c
    );
    String deniedStatus = pickFirstAvailableStatus(
      onboardingStatuses,
      new List<String>{ 'Denied' }
    );
    String canceledStatus = pickFirstAvailableStatus(
      onboardingStatuses,
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
    List<VendorOptionDTO> options = getOptionsForAccount(acct.Id);
    Test.stopTest();

    Set<String> retailOptions = new Set<String>();
    for (VendorOptionDTO option : options) {
      retailOptions.add(option.retailOption);
    }

    System.assert(
      retailOptions.contains('National Agent'),
      'Denied should not block this option'
    );
    System.assert(
      retailOptions.contains('National Retail'),
      'Canceled should not block this option'
    );
  }

  @isTest
  static void testOneVendorShownWhenOthersAreBlockedWithoutCompletedPrereq() {
    Account acct = new Account(Name = 'Flow Service Single Vendor Account');
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
      'Expected at least one business vertical value'
    );
    String businessVertical = businessVerticalValues[0];

    Vendor_Customization__c verizonProgram = new Vendor_Customization__c(
      Vendor__c = verizonVendor.Id,
      Active__c = true,
      Retail_Option__c = 'Fios',
      Business_Vertical__c = businessVertical
    );
    Vendor_Customization__c perfectVisionCompleteProgram = new Vendor_Customization__c(
      Vendor__c = perfectVisionVendor.Id,
      Active__c = true,
      Retail_Option__c = 'N/A',
      Business_Vertical__c = businessVertical
    );
    Vendor_Customization__c perfectVisionOtherProgram = new Vendor_Customization__c(
      Vendor__c = perfectVisionVendor.Id,
      Active__c = true,
      Retail_Option__c = 'National Agent',
      Business_Vertical__c = businessVertical
    );
    Vendor_Customization__c frontierRequiredProgram = new Vendor_Customization__c(
      Vendor__c = frontierVendor.Id,
      Active__c = true,
      Retail_Option__c = 'Nation Agent',
      Business_Vertical__c = businessVertical
    );
    Vendor_Customization__c frontierTargetProgram = new Vendor_Customization__c(
      Vendor__c = frontierVendor.Id,
      Active__c = true,
      Retail_Option__c = 'Frontier Amendment',
      Business_Vertical__c = businessVertical
    );
    insert new List<Vendor_Customization__c>{
      verizonProgram,
      perfectVisionCompleteProgram,
      perfectVisionOtherProgram,
      frontierRequiredProgram,
      frontierTargetProgram
    };

    Vendor_Program_Group__c prereqGroup = new Vendor_Program_Group__c(
      Name = 'Flow Service Frontier Group',
      Label__c = 'Flow Service Frontier Group',
      Active__c = true,
      Logic_Type__c = pickLogicType()
    );
    insert prereqGroup;

    insert new List<Vendor_Program_Group_Member__c>{
      buildGroupMember(prereqGroup.Id, frontierTargetProgram.Id, true),
      buildGroupMember(prereqGroup.Id, frontierRequiredProgram.Id, false)
    };

    List<String> onboardingStatuses = getPicklistValues(
      Onboarding__c.Onboarding_Status__c
    );

    insert new List<Onboarding__c>{
      new Onboarding__c(
        Account__c = acct.Id,
        Vendor_Customization__c = verizonProgram.Id,
        Onboarding_Status__c = pickFirstAvailableStatus(
          onboardingStatuses,
          new List<String>{ 'Canceled', 'Cancelled' }
        )
      ),
      new Onboarding__c(
        Account__c = acct.Id,
        Vendor_Customization__c = perfectVisionCompleteProgram.Id,
        Onboarding_Status__c = pickCompletedStatus(onboardingStatuses)
      ),
      new Onboarding__c(
        Account__c = acct.Id,
        Vendor_Customization__c = frontierRequiredProgram.Id,
        Onboarding_Status__c = pickBlockingNonCompletedStatus(onboardingStatuses)
      )
    };

    Test.startTest();
    List<VendorOptionDTO> options = getOptionsForAccount(acct.Id);
    Test.stopTest();

    Set<String> vendorNames = new Set<String>();
    for (VendorOptionDTO option : options) {
      vendorNames.add(option.vendorName);
    }

    System.assertEquals(1, vendorNames.size(), 'Expected one eligible vendor');
    System.assert(vendorNames.contains('Verizon'), 'Only Verizon should be visible');
  }

  @isTest
  static void testPrerequisiteTargetRequiresCompletedStatus() {
    Account acct = new Account(Name = 'Flow Service Prereq Account');
    insert acct;

    Vendor__c frontierVendor = new Vendor__c(Name = 'Frontier', Active__c = true);
    insert frontierVendor;

    List<String> businessVerticalValues = getPicklistValues(
      Vendor_Customization__c.Business_Vertical__c
    );
    System.assert(
      !businessVerticalValues.isEmpty(),
      'Expected at least one business vertical value'
    );
    String businessVertical = businessVerticalValues[0];

    Vendor_Customization__c requiredProgram = new Vendor_Customization__c(
      Vendor__c = frontierVendor.Id,
      Active__c = true,
      Retail_Option__c = 'Nation Agent',
      Business_Vertical__c = businessVertical
    );
    Vendor_Customization__c targetProgram = new Vendor_Customization__c(
      Vendor__c = frontierVendor.Id,
      Active__c = true,
      Retail_Option__c = 'Frontier Amendment',
      Business_Vertical__c = businessVertical
    );
    insert new List<Vendor_Customization__c>{ requiredProgram, targetProgram };

    Vendor_Program_Group__c prereqGroup = new Vendor_Program_Group__c(
      Name = 'Flow Service Completion Group',
      Label__c = 'Flow Service Completion Group',
      Active__c = true,
      Logic_Type__c = pickLogicType()
    );
    insert prereqGroup;

    insert new List<Vendor_Program_Group_Member__c>{
      buildGroupMember(prereqGroup.Id, targetProgram.Id, true),
      buildGroupMember(prereqGroup.Id, requiredProgram.Id, false)
    };

    List<String> onboardingStatuses = getPicklistValues(
      Onboarding__c.Onboarding_Status__c
    );

    Onboarding__c onboardingRecord = new Onboarding__c(
      Account__c = acct.Id,
      Vendor_Customization__c = requiredProgram.Id,
      Onboarding_Status__c = pickBlockingNonCompletedStatus(onboardingStatuses)
    );
    insert onboardingRecord;

    List<VendorOptionDTO> inProgressOptions = getOptionsForAccount(acct.Id);
    Set<String> inProgressRetailOptions = new Set<String>();
    for (VendorOptionDTO option : inProgressOptions) {
      inProgressRetailOptions.add(option.retailOption);
    }
    System.assert(
      !inProgressRetailOptions.contains('Frontier Amendment'),
      'Target should not be visible until prerequisite is completed'
    );

    onboardingRecord.Onboarding_Status__c = pickCompletedStatus(onboardingStatuses);
    update onboardingRecord;

    List<VendorOptionDTO> completedOptions = getOptionsForAccount(acct.Id);
    Set<String> completedRetailOptions = new Set<String>();
    for (VendorOptionDTO option : completedOptions) {
      completedRetailOptions.add(option.retailOption);
    }
    System.assert(
      completedRetailOptions.contains('Frontier Amendment'),
      'Target should become visible after prerequisite is completed'
    );
  }

  private static List<VendorOptionDTO> getOptionsForAccount(Id accountId) {
    List<List<VendorOptionDTO>> results = VendorOnboardingFlowService.getEligibleVendors(
      new List<Id>{ accountId }
    );
    return results.isEmpty() ? new List<VendorOptionDTO>() : results[0];
  }

  private static String pickLogicType() {
    List<String> logicTypes = getPicklistValues(Vendor_Program_Group__c.Logic_Type__c);
    return logicTypes.contains('OR') ? 'OR' : logicTypes[0];
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

  private static String pickFirstAvailableStatus(
    List<String> statuses,
    List<String> preferredStatuses
  ) {
    System.assert(
      statuses != null && !statuses.isEmpty(),
      'Expected onboarding status picklist values'
    );

    for (String preferredStatus : preferredStatuses) {
      if (statuses.contains(preferredStatus)) {
        return preferredStatus;
      }
    }

    return statuses[0];
  }

  private static String pickCompletedStatus(List<String> statuses) {
    for (String status : statuses) {
      if (String.isBlank(status)) {
        continue;
      }

      if (COMPLETED_STATUSES.contains(status.trim().toUpperCase())) {
        return status;
      }
    }

    System.assert(false, 'Expected a completed onboarding status');
    return null;
  }

  private static String pickBlockingNonCompletedStatus(List<String> statuses) {
    for (String status : statuses) {
      if (String.isBlank(status)) {
        continue;
      }

      String normalizedStatus = status.trim().toUpperCase();
      if (
        !NON_BLOCKING_STATUSES.contains(normalizedStatus) &&
        !COMPLETED_STATUSES.contains(normalizedStatus)
      ) {
        return status;
      }
    }

    System.assert(false, 'Expected a blocking non-completed onboarding status');
    return null;
  }

  private static List<String> getPicklistValues(Schema.SObjectField fieldRef) {
    List<String> values = new List<String>();
    for (Schema.PicklistEntry entry : fieldRef.getDescribe().getPicklistValues()) {
      values.add(entry.getValue());
    }
    return values;
  }
}
