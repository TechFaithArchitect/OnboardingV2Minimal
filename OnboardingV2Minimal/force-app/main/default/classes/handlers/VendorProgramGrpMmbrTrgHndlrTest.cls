@isTest
public class VendorProgramGrpMmbrTrgHndlrTest {
  @TestSetup
  static void setup() {
    Vendor__c vendor = TestDataFactory.createVendor(true);
    vendor.Active__c = true;
    update vendor;

    Vendor_Program_Requirement_Group__c requirementGroup = TestVendorProgramRequirementGroupFactory.create(
      true,
      'Test Requirement Group'
    );

    TestVendorProgramGroupFactory.create(
      true,
      'Test Program Group',
      requirementGroup,
      null
    );

    TestDataFactory.createVendorCustomization(
      vendor,
      'Active',
      true,
      null,
      true
    );
    TestDataFactory.createVendorCustomization(
      vendor,
      'Active',
      true,
      null,
      true
    );
  }

  @isTest
  static void testSingleTargetAllowed() {
    Vendor_Program_Group__c vendorProgramGroup = [
      SELECT Id
      FROM Vendor_Program_Group__c
      LIMIT 1
    ];
    Vendor_Customization__c customization = [
      SELECT Id
      FROM Vendor_Customization__c
      LIMIT 1
    ];

    Vendor_Program_Group_Member__c member = TestVendorProgramGroupMemberFactory.create(
      false,
      vendorProgramGroup,
      customization,
      null,
      true
    );

    Test.startTest();
    insert member;
    Test.stopTest();
  }

  @isTest
  static void testSecondTargetFails() {
    Vendor_Program_Group__c vendorProgramGroup = [
      SELECT Id
      FROM Vendor_Program_Group__c
      LIMIT 1
    ];
    List<Vendor_Customization__c> customizations = [
      SELECT Id
      FROM Vendor_Customization__c
      ORDER BY CreatedDate ASC
      LIMIT 2
    ];
    System.assertEquals(
      2,
      customizations.size(),
      'Expected two vendor customizations'
    );

    Vendor_Program_Group_Member__c member1 = TestVendorProgramGroupMemberFactory.create(
      false,
      vendorProgramGroup,
      customizations[0],
      null,
      true
    );

    Vendor_Program_Group_Member__c member2 = TestVendorProgramGroupMemberFactory.create(
      false,
      vendorProgramGroup,
      customizations[1],
      null,
      true
    );

    Test.startTest();
    insert member1;
    Database.SaveResult result = Database.insert(member2, false);
    Test.stopTest();

    System.assertEquals(
      false,
      result.isSuccess(),
      'Second member should fail due to duplicate target.'
    );
    System.assert(
      result.getErrors()[0]
        .getMessage()
        .contains(Label.Vendor_Program_Group_Target_Message),
      'Expected error message to contain: ' +
      Label.Vendor_Program_Group_Target_Message
    );
  }
}
