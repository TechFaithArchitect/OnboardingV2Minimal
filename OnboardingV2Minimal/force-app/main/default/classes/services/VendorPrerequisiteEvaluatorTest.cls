@isTest
private class VendorPrerequisiteEvaluatorTest {
  @isTest
  static void testIsCustomizationEligible_WithNoPrerequisites_ReturnsTrue() {
    Id customizationId = createDummyCustomization();

    Set<Id> onboarded = new Set<Id>();
    VendorPrerequisiteEvaluator.PrereqMap prereqMap = new VendorPrerequisiteEvaluator.PrereqMap();

    Boolean result = VendorPrerequisiteEvaluator.isCustomizationEligible(
      customizationId,
      onboarded,
      prereqMap
    );
    System.assertEquals(
      true,
      result,
      'Customization with no prereqs should be eligible'
    );
  }

  @isTest
  static void testIsCustomizationEligible_AlreadyOnboarded_ReturnsFalse() {
    Id customizationId = createDummyCustomization();
    Set<Id> onboarded = new Set<Id>{ customizationId };

    VendorPrerequisiteEvaluator.PrereqMap prereqMap = new VendorPrerequisiteEvaluator.PrereqMap();

    Boolean result = VendorPrerequisiteEvaluator.isCustomizationEligible(
      customizationId,
      onboarded,
      prereqMap
    );
    System.assertEquals(
      false,
      result,
      'Already onboarded customization should be ineligible'
    );
  }

  @isTest
  static void testIsCustomizationEligible_WithUnmetANDPrerequisites_ReturnsFalse() {
    Id customizationId = createDummyCustomization();
    Id prereq1 = createDummyCustomization();
    Id prereq2 = createDummyCustomization();

    Vendor_Program_Group__c groupRec = new Vendor_Program_Group__c(
      Name = 'AND Group',
      Logic_Type__c = 'AND',
      Label__c = 'AND Group Label',
      Active__c = true
    );
    insert groupRec;

    insert new List<Vendor_Program_Group_Member__c>{
      new Vendor_Program_Group_Member__c(
        Vendor_Program_Group__c = groupRec.Id,
        Required_Program__c = prereq1,
        Active__c = true,
        Is_Target__c = false
      ),
      new Vendor_Program_Group_Member__c(
        Vendor_Program_Group__c = groupRec.Id,
        Required_Program__c = prereq2,
        Active__c = true,
        Is_Target__c = false
      ),
      new Vendor_Program_Group_Member__c(
        Vendor_Program_Group__c = groupRec.Id,
        Required_Program__c = customizationId,
        Active__c = true,
        Is_Target__c = true
      )
    };

    Test.startTest();
    VendorPrerequisiteEvaluator.PrereqMap prereqMap = VendorPrerequisiteEvaluator.getActivePrerequisites();
    Test.stopTest();

    Set<Id> onboarded = new Set<Id>(); // No prerequisites met
    Boolean result = VendorPrerequisiteEvaluator.isCustomizationEligible(
      customizationId,
      onboarded,
      prereqMap
    );
    System.assertEquals(
      false,
      result,
      'Should be ineligible if AND prereqs not met'
    );
  }

  @isTest
  static void testIsCustomizationEligible_WithMetORPrerequisites_ReturnsTrue() {
    Id customizationId = createDummyCustomization();
    Id prereq1 = createDummyCustomization();
    Id prereq2 = createDummyCustomization();

    Vendor_Program_Group__c groupRec = new Vendor_Program_Group__c(
      Name = 'OR Group',
      Logic_Type__c = 'OR',
      Label__c = 'OR Group Label',
      Active__c = true
    );
    insert groupRec;

    insert new List<Vendor_Program_Group_Member__c>{
      new Vendor_Program_Group_Member__c(
        Vendor_Program_Group__c = groupRec.Id,
        Required_Program__c = prereq1,
        Active__c = true,
        Is_Target__c = false
      ),
      new Vendor_Program_Group_Member__c(
        Vendor_Program_Group__c = groupRec.Id,
        Required_Program__c = prereq2,
        Active__c = true,
        Is_Target__c = false
      ),
      new Vendor_Program_Group_Member__c(
        Vendor_Program_Group__c = groupRec.Id,
        Required_Program__c = customizationId,
        Active__c = true,
        Is_Target__c = true
      )
    };

    Test.startTest();
    VendorPrerequisiteEvaluator.PrereqMap prereqMap = VendorPrerequisiteEvaluator.getActivePrerequisites();
    Test.stopTest();

    Set<Id> onboarded = new Set<Id>{ prereq2 }; // One OR prereq met
    Boolean result = VendorPrerequisiteEvaluator.isCustomizationEligible(
      customizationId,
      onboarded,
      prereqMap
    );
    System.assertEquals(
      true,
      result,
      'Should be eligible if one OR prereq is met'
    );
  }

  // Helper method to create dummy customization
  private static Id createDummyCustomization() {
    Vendor__c vendor = new Vendor__c(Name = 'Test Vendor');
    insert vendor;

    Vendor_Customization__c customization = new Vendor_Customization__c(
      Vendor__c = vendor.Id
    );
    insert customization;

    return customization.Id;
  }
}
