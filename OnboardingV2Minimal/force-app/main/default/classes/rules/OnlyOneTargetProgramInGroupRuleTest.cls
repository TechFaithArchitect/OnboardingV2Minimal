@IsTest
private class OnlyOneTargetProgramInGroupRuleTest {
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

  @IsTest
  static void testSecondTargetFailsWhenExistingTarget() {
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

    System.assert(
      !result.isSuccess(),
      'Second target should fail due to existing target.'
    );
    System.assert(
      TestDataFactoryUtil.saveResultHasError(
        result,
        Label.Vendor_Program_Group_Target_Message
      ),
      'Expected error message to contain target message. Errors: ' +
      TestDataFactoryUtil.joinErrorMessages(result)
    );
  }

  @IsTest
  static void testSecondTargetFailsInSameTransaction() {
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
    Database.SaveResult[] results = Database.insert(
      new List<Vendor_Program_Group_Member__c>{ member1, member2 },
      false
    );
    Test.stopTest();

    System.assert(
      results[0].isSuccess(),
      'First target should insert successfully.'
    );
    System.assert(
      !results[1].isSuccess(),
      'Second target should fail in the same transaction.'
    );
    System.assert(
      TestDataFactoryUtil.saveResultHasError(
        results[1],
        Label.Vendor_Program_Group_Target_Message
      ),
      'Expected error message to contain target message. Errors: ' +
      TestDataFactoryUtil.joinErrorMessages(results[1])
    );
  }

  @IsTest
  static void testNonTargetAllowedWithExistingTarget() {
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

    Vendor_Program_Group_Member__c targetMember = TestVendorProgramGroupMemberFactory.create(
      false,
      vendorProgramGroup,
      customizations[0],
      null,
      true
    );
    Vendor_Program_Group_Member__c nonTargetMember = TestVendorProgramGroupMemberFactory.create(
      false,
      vendorProgramGroup,
      customizations[1],
      null,
      false
    );

    Test.startTest();
    insert targetMember;
    Database.SaveResult result = Database.insert(nonTargetMember, false);
    Test.stopTest();

    System.assert(
      result.isSuccess(),
      'Non-target member should be allowed when a target exists.'
    );
  }
}
