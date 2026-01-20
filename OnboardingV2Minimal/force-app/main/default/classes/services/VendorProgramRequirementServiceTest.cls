@isTest
private class VendorProgramRequirementServiceTest {
  @isTest
  static void testSearchVendorProgramRequirements() {
    Vendor__c vendor = TestDataFactory.createVendor(true);
    Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
      vendor,
      'Active',
      true,
      null,
      true
    );
    Vendor_Program_Requirement__c req = TestDataFactory.createVendorProgramRequirement(
      vendorProgram,
      true,
      true
    );

    Test.startTest();
    List<Vendor_Program_Requirement__c> results = RequirementDomainService.searchVendorProgramRequirements(
      'Test'
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testCreateVendorProgramRequirement() {
    Vendor__c vendor = TestDataFactory.createVendor(true);
    Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
      vendor,
      'Active',
      true,
      null,
      true
    );
    Vendor_Program_Onboarding_Req_Template__c template = TestVdrPrgrmOnboardingReqTemplateFactory.create(
      true
    );

    List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
      Vendor_Program_Requirement__c.SObjectType,
      'Status__c'
    );
    String activeStatus = validStatuses.contains('Active')
      ? 'Active'
      : validStatuses[0];

    Vendor_Program_Requirement__c req = new Vendor_Program_Requirement__c(
      Vendor_Program__c = vendorProgram.Id,
      Requirement_Template__c = template.Id,
      Status__c = activeStatus,
      Is_Required__c = true,
      Sequence__c = 1
    );

    Test.startTest();
    Id reqId = RequirementDomainService.createVendorProgramRequirement(req);
    Test.stopTest();

    System.assertNotEquals(null, reqId, 'Requirement ID should be returned');
  }

  @isTest
  static void testCreateVendorProgramRequirement_NullRecord_Throws() {
    Test.startTest();
    try {
      RequirementDomainService.createVendorProgramRequirement(null);
      System.assert(false, 'Should throw exception for null record');
    } catch (AuraHandledException e) {
      System.assert(
        e != null,
        'AuraHandledException should be thrown for null record'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testBulkCreateRequirementsFromTemplates() {
    Vendor__c vendor = TestDataFactory.createVendor(true);
    Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
      vendor,
      'Active',
      true,
      null,
      true
    );
    Vendor_Program_Onboarding_Req_Template__c template1 = TestVdrPrgrmOnboardingReqTemplateFactory.create(
      true
    );
    Vendor_Program_Onboarding_Req_Template__c template2 = TestVdrPrgrmOnboardingReqTemplateFactory.create(
      true
    );
    String statusValue = TestDataFactoryUtil.getDefaultPicklistValue(
      Vendor_Program_Requirement__c.SObjectType,
      'Status__c'
    );

    Test.startTest();
    RequirementDomainService.BulkCreateRequirementsResult result = RequirementDomainService.bulkCreateRequirementsFromTemplates(
      vendorProgram.Id,
      new List<Id>{ template1.Id, template2.Id },
      statusValue,
      true
    );
    Test.stopTest();

    System.assertEquals(true, result.success, 'Bulk create should succeed');
    System.assert(
      result.createdRequirementIds.size() > 0,
      'Should create requirements'
    );
  }

  @isTest
  static void testBulkCreateRequirementsFromTemplates_WithExisting_ShouldSkip() {
    Vendor__c vendor = TestDataFactory.createVendor(true);
    Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
      vendor,
      'Active',
      true,
      null,
      true
    );
    Vendor_Program_Onboarding_Req_Template__c template = TestVdrPrgrmOnboardingReqTemplateFactory.create(
      true
    );
    String statusValue = TestDataFactoryUtil.getDefaultPicklistValue(
      Vendor_Program_Requirement__c.SObjectType,
      'Status__c'
    );

    // Create existing requirement
    Vendor_Program_Requirement__c existing = TestDataFactory.createVendorProgramRequirement(
      vendorProgram,
      true,
      true
    );
    existing.Requirement_Template__c = template.Id;
    update existing;

    Test.startTest();
    RequirementDomainService.BulkCreateRequirementsResult result = RequirementDomainService.bulkCreateRequirementsFromTemplates(
      vendorProgram.Id,
      new List<Id>{ template.Id },
      statusValue,
      true
    );
    Test.stopTest();

    System.assertEquals(true, result.success, 'Bulk create should succeed');
    System.assertEquals(
      0,
      result.createdRequirementIds.size(),
      'Should not create duplicate'
    );
    System.assertEquals(
      1,
      result.skippedTemplateIds.size(),
      'Should skip existing template'
    );
  }

  @isTest
  static void testUpdateRequirementSequences() {
    Vendor_Program_Requirement__c req1 = TestVendorProgramRequirementFactory.create(
      true
    );
    Vendor_Program_Requirement__c req2 = TestVendorProgramRequirementFactory.create(
      true
    );
    req1.Sequence__c = 1;
    req2.Sequence__c = 2;

    Test.startTest();
    RequirementDomainService.updateRequirementSequences(
      new List<Vendor_Program_Requirement__c>{ req1, req2 }
    );
    Test.stopTest();

    // Verify sequences were updated
    Vendor_Program_Requirement__c updated1 = [
      SELECT Sequence__c
      FROM Vendor_Program_Requirement__c
      WHERE Id = :req1.Id
    ];
    System.assertEquals(1, updated1.Sequence__c, 'Sequence should be updated');
  }

  @isTest
  static void testGetRecentVendorProgramRequirements() {
    Vendor__c vendor = TestDataFactory.createVendor(true);
    Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
      vendor,
      'Active',
      true,
      null,
      true
    );
    Vendor_Program_Requirement__c req = TestDataFactory.createVendorProgramRequirement(
      vendorProgram,
      true,
      true
    );

    Test.startTest();
    List<Vendor_Program_Requirement__c> results = RequirementDomainService.getRecentVendorProgramRequirements(
      vendorProgram.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testGetRequirementsByGroup() {
    Vendor_Program_Requirement_Group__c requirementGroup = TestDataFactory.createVendorProgramRequirementGroup(
      'Test Group',
      true
    );
    Vendor__c vendor = TestDataFactory.createVendor(true);
    Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
      vendor,
      'Active',
      true,
      null,
      true
    );
    Vendor_Program_Onboarding_Req_Template__c template = TestVdrPrgrmOnboardingReqTemplateFactory.create(
      true,
      null,
      requirementGroup
    );
    Vendor_Program_Requirement__c req = new Vendor_Program_Requirement__c(
      Vendor_Program__c = vendorProgram.Id,
      Requirement_Template__c = template.Id,
      Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
        Vendor_Program_Requirement__c.SObjectType,
        'Status__c'
      ),
      Is_Required__c = true,
      Sequence__c = 1
    );
    insert req;

    Test.startTest();
    List<Vendor_Program_Requirement__c> results = RequirementDomainService.getRequirementsByGroup(
      requirementGroup.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  @isTest
  static void testDeleteVendorProgramRequirement() {
    Vendor_Program_Requirement__c req = TestVendorProgramRequirementFactory.create(
      true
    );

    Test.startTest();
    RequirementDomainService.deleteVendorProgramRequirement(req.Id);
    Test.stopTest();

    // Verify requirement was deleted
    List<Vendor_Program_Requirement__c> remaining = [
      SELECT Id
      FROM Vendor_Program_Requirement__c
      WHERE Id = :req.Id
    ];
    System.assertEquals(0, remaining.size(), 'Requirement should be deleted');
  }
}
