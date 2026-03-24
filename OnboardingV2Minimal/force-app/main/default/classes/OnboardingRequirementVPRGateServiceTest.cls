@IsTest
private class OnboardingRequirementVPRGateServiceTest {
  @IsTest
  static void noBlock_returnsAllMissingInOrder() {
    Id onboardId = fakeId(Onboarding__c.SObjectType);
    Id progId = fakeId(Vendor_Customization__c.SObjectType);

    Vendor_Program_Requirement__c v1 = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 1),
      Sequence__c = 1,
      Requirement_Type__c = 'Contract',
      Vendor_Program__c = progId
    );
    Vendor_Program_Requirement__c v2 = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 2),
      Sequence__c = 2,
      Requirement_Type__c = 'Agreement',
      Vendor_Program__c = progId
    );

    OnboardingRequirementVPRGateService.testVendorProgramApprovalPolicyKeyStubActive = true;
    OnboardingRequirementVPRGateService.testVendorProgramApprovalPolicyKeyStubValue = 'K1';
    OnboardingRequirementVPRGateService.testPoliciesOverride = new List<Vendor_Program_Approval_Policy__mdt>{
      new Vendor_Program_Approval_Policy__mdt(
        Policy_Key__c = 'K1',
        Type__c = 'Agreement',
        Block_Action__c = false,
        Active__c = true,
        Priority__c = 10
      )
    };
    OnboardingRequirementVPRGateService.testAllVprOverride = new List<Vendor_Program_Requirement__c>{ v1, v2 };
    OnboardingRequirementVPRGateService.testExistingVprIdsOverride = new Set<Id>();

    try {
      OnboardingRequirementVPRGateService.GateOutcome o = OnboardingRequirementVPRGateService.buildGateOutcome(
        onboardId,
        progId
      );
      System.assertEquals(2, o.vendorProgramRequirementsToCreate.size());
      System.assertEquals(false, o.deferredRequirementsRemain);
      System.assertEquals(false, o.gateStoppedThisBatch);
    } finally {
      OnboardingRequirementVPRGateService.clearTestStubs();
    }
  }

  @IsTest
  static void blankProgramPolicyKey_doesNotMatchCmdt_allRequirementsCreated() {
    Id onboardId = fakeId(Onboarding__c.SObjectType);
    Id progId = fakeId(Vendor_Customization__c.SObjectType);

    Vendor_Program_Requirement__c v0 = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 0),
      Sequence__c = 1,
      Requirement_Type__c = 'Contract',
      Vendor_Program__c = progId
    );
    Vendor_Program_Requirement__c v1 = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 1),
      Sequence__c = 2,
      Requirement_Type__c = 'Agreement',
      Vendor_Program__c = progId
    );
    Vendor_Program_Requirement__c v2 = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 2),
      Sequence__c = 3,
      Requirement_Type__c = 'Training',
      Vendor_Program__c = progId
    );

    OnboardingRequirementVPRGateService.testPoliciesOverride = new List<Vendor_Program_Approval_Policy__mdt>{
      new Vendor_Program_Approval_Policy__mdt(
        Policy_Key__c = 'VERIZON_FIOS',
        Type__c = 'Agreement',
        Block_Action__c = true,
        Active__c = true,
        Priority__c = 10
      )
    };
    OnboardingRequirementVPRGateService.testAllVprOverride = new List<Vendor_Program_Requirement__c>{
      v0,
      v1,
      v2
    };
    OnboardingRequirementVPRGateService.testExistingVprIdsOverride = new Set<Id>();

    try {
      OnboardingRequirementVPRGateService.GateOutcome o = OnboardingRequirementVPRGateService.buildGateOutcome(
        onboardId,
        progId
      );
      System.assertEquals(3, o.vendorProgramRequirementsToCreate.size());
      System.assertEquals(false, o.deferredRequirementsRemain);
      System.assertEquals(false, o.gateStoppedThisBatch);
    } finally {
      OnboardingRequirementVPRGateService.clearTestStubs();
    }
  }

  @IsTest
  static void programApprovalPolicyKey_gatesBeforeAgreement() {
    Id onboardId = fakeId(Onboarding__c.SObjectType);
    Id progId = fakeId(Vendor_Customization__c.SObjectType);

    Vendor_Program_Requirement__c v0 = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 0),
      Sequence__c = 1,
      Requirement_Type__c = 'Contract',
      Vendor_Program__c = progId
    );
    Vendor_Program_Requirement__c v1 = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 1),
      Sequence__c = 2,
      Requirement_Type__c = 'Agreement',
      Vendor_Program__c = progId
    );
    Vendor_Program_Requirement__c v2 = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 2),
      Sequence__c = 3,
      Requirement_Type__c = 'Training',
      Vendor_Program__c = progId
    );

    OnboardingRequirementVPRGateService.testVendorProgramApprovalPolicyKeyStubActive = true;
    OnboardingRequirementVPRGateService.testVendorProgramApprovalPolicyKeyStubValue = 'VERIZON_FIOS';
    OnboardingRequirementVPRGateService.testPoliciesOverride = new List<Vendor_Program_Approval_Policy__mdt>{
      new Vendor_Program_Approval_Policy__mdt(
        Policy_Key__c = 'VERIZON_FIOS',
        Type__c = 'Agreement',
        Block_Action__c = true,
        Active__c = true,
        Priority__c = 10
      )
    };
    OnboardingRequirementVPRGateService.testAllVprOverride = new List<Vendor_Program_Requirement__c>{
      v0,
      v1,
      v2
    };
    OnboardingRequirementVPRGateService.testExistingVprIdsOverride = new Set<Id>();

    try {
      OnboardingRequirementVPRGateService.GateOutcome o = OnboardingRequirementVPRGateService.buildGateOutcome(
        onboardId,
        progId
      );
      System.assertEquals(1, o.vendorProgramRequirementsToCreate.size());
      System.assertEquals(v0.Id, o.vendorProgramRequirementsToCreate[0].Id);
      System.assertEquals(true, o.deferredRequirementsRemain);
      System.assertEquals(true, o.gateStoppedThisBatch);
    } finally {
      OnboardingRequirementVPRGateService.clearTestStubs();
    }
  }

  @IsTest
  static void blockAction_stopsAfterFirstNewAndDefersRest() {
    Id onboardId = fakeId(Onboarding__c.SObjectType);
    Id progId = fakeId(Vendor_Customization__c.SObjectType);

    Vendor_Program_Requirement__c v1 = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 1),
      Sequence__c = 1,
      Requirement_Type__c = 'Agreement',
      Vendor_Program__c = progId
    );
    Vendor_Program_Requirement__c v2 = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 2),
      Sequence__c = 2,
      Requirement_Type__c = 'Training',
      Vendor_Program__c = progId
    );

    OnboardingRequirementVPRGateService.testVendorProgramApprovalPolicyKeyStubActive = true;
    OnboardingRequirementVPRGateService.testVendorProgramApprovalPolicyKeyStubValue = 'VERIZON_FIOS';
    OnboardingRequirementVPRGateService.testPoliciesOverride = new List<Vendor_Program_Approval_Policy__mdt>{
      new Vendor_Program_Approval_Policy__mdt(
        Policy_Key__c = 'VERIZON_FIOS',
        Type__c = 'Agreement',
        Block_Action__c = true,
        Active__c = true,
        Priority__c = 10
      )
    };
    OnboardingRequirementVPRGateService.testAllVprOverride = new List<Vendor_Program_Requirement__c>{ v1, v2 };
    OnboardingRequirementVPRGateService.testExistingVprIdsOverride = new Set<Id>();

    try {
      OnboardingRequirementVPRGateService.GateOutcome o = OnboardingRequirementVPRGateService.buildGateOutcome(
        onboardId,
        progId
      );
      System.assertEquals(0, o.vendorProgramRequirementsToCreate.size());
      System.assertEquals(true, o.deferredRequirementsRemain);
      System.assertEquals(true, o.gateStoppedThisBatch);
    } finally {
      OnboardingRequirementVPRGateService.clearTestStubs();
    }
  }

  @IsTest
  static void blockAction_whenOnboardingApproved_includesBlockingRow() {
    Id onboardId = fakeId(Onboarding__c.SObjectType);
    Id progId = fakeId(Vendor_Customization__c.SObjectType);

    Id contractVprId = fakeId(Vendor_Program_Requirement__c.SObjectType, 1);
    Vendor_Program_Requirement__c vAgreement = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 2),
      Sequence__c = 2,
      Requirement_Type__c = 'Agreement',
      Vendor_Program__c = progId
    );
    Vendor_Program_Requirement__c vTraining = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 3),
      Sequence__c = 3,
      Requirement_Type__c = 'Training',
      Vendor_Program__c = progId
    );

    OnboardingRequirementVPRGateService.testVendorProgramApprovalPolicyKeyStubActive = true;
    OnboardingRequirementVPRGateService.testVendorProgramApprovalPolicyKeyStubValue = 'VERIZON_FIOS';
    OnboardingRequirementVPRGateService.testPoliciesOverride = new List<Vendor_Program_Approval_Policy__mdt>{
      new Vendor_Program_Approval_Policy__mdt(
        Policy_Key__c = 'VERIZON_FIOS',
        Type__c = 'Agreement',
        Block_Action__c = true,
        Active__c = true,
        Priority__c = 10
      )
    };
    OnboardingRequirementVPRGateService.testAllVprOverride = new List<Vendor_Program_Requirement__c>{
      vAgreement,
      vTraining
    };
    OnboardingRequirementVPRGateService.testExistingVprIdsOverride = new Set<Id>{ contractVprId };
    OnboardingRequirementVPRGateService.testOnboardingStatusOverride = 'Approved';

    try {
      OnboardingRequirementVPRGateService.GateOutcome o = OnboardingRequirementVPRGateService.buildGateOutcome(
        onboardId,
        progId
      );
      System.assertEquals(1, o.vendorProgramRequirementsToCreate.size());
      System.assertEquals(vAgreement.Id, o.vendorProgramRequirementsToCreate[0].Id);
      System.assertEquals(true, o.deferredRequirementsRemain);
      System.assertEquals(true, o.gateStoppedThisBatch);
    } finally {
      OnboardingRequirementVPRGateService.clearTestStubs();
    }
  }

  @IsTest
  static void skipsExistingOnboardingRequirements() {
    Id onboardId = fakeId(Onboarding__c.SObjectType);
    Id progId = fakeId(Vendor_Customization__c.SObjectType);
    Id v1Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 1);
    Vendor_Program_Requirement__c v1 = new Vendor_Program_Requirement__c(
      Id = v1Id,
      Sequence__c = 1,
      Requirement_Type__c = 'Agreement',
      Vendor_Program__c = progId
    );
    Vendor_Program_Requirement__c v2 = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 2),
      Sequence__c = 2,
      Requirement_Type__c = 'Training',
      Vendor_Program__c = progId
    );

    OnboardingRequirementVPRGateService.testVendorProgramApprovalPolicyKeyStubActive = true;
    OnboardingRequirementVPRGateService.testVendorProgramApprovalPolicyKeyStubValue = 'VERIZON_FIOS';
    OnboardingRequirementVPRGateService.testPoliciesOverride = new List<Vendor_Program_Approval_Policy__mdt>{
      new Vendor_Program_Approval_Policy__mdt(
        Policy_Key__c = 'VERIZON_FIOS',
        Type__c = 'Agreement',
        Block_Action__c = true,
        Active__c = true,
        Priority__c = 10
      )
    };
    OnboardingRequirementVPRGateService.testAllVprOverride = new List<Vendor_Program_Requirement__c>{ v1, v2 };
    OnboardingRequirementVPRGateService.testExistingVprIdsOverride = new Set<Id>{ v1Id };

    try {
      OnboardingRequirementVPRGateService.GateOutcome o = OnboardingRequirementVPRGateService.buildGateOutcome(
        onboardId,
        progId
      );
      System.assertEquals(1, o.vendorProgramRequirementsToCreate.size());
      System.assertEquals(v2.Id, o.vendorProgramRequirementsToCreate[0].Id);
      System.assertEquals(false, o.deferredRequirementsRemain);
      System.assertEquals(false, o.gateStoppedThisBatch);
    } finally {
      OnboardingRequirementVPRGateService.clearTestStubs();
    }
  }

  @IsTest
  static void invocable_nullRequestList_returnsEmpty() {
    System.assertEquals(
      0,
      OnboardingRequirementVPRGateInvocable.filterForGate(null).size()
    );
  }

  @IsTest
  static void invocable_nullIds_returnsEmptyRequirements() {
    OnboardingRequirementVPRGateInvocable.Request req = new OnboardingRequirementVPRGateInvocable.Request();
    List<OnboardingRequirementVPRGateInvocable.Result> results = OnboardingRequirementVPRGateInvocable.filterForGate(
      new List<OnboardingRequirementVPRGateInvocable.Request>{ req }
    );
    System.assertEquals(1, results.size());
    System.assertEquals(0, results[0].vendorProgramRequirements.size());
    System.assertEquals(false, results[0].deferredRequirementsRemain);
    System.assertEquals(false, results[0].gateStoppedThisBatch);
  }

  @IsTest
  static void invocable_delegatesToServiceWithStubs() {
    Id onboardId = fakeId(Onboarding__c.SObjectType);
    Id progId = fakeId(Vendor_Customization__c.SObjectType);
    Vendor_Program_Requirement__c v1 = new Vendor_Program_Requirement__c(
      Id = fakeId(Vendor_Program_Requirement__c.SObjectType, 1),
      Sequence__c = 1,
      Requirement_Type__c = 'Contract',
      Vendor_Program__c = progId
    );
    OnboardingRequirementVPRGateService.testAllVprOverride = new List<Vendor_Program_Requirement__c>{ v1 };
    OnboardingRequirementVPRGateService.testExistingVprIdsOverride = new Set<Id>();
    OnboardingRequirementVPRGateService.testPoliciesOverride = new List<Vendor_Program_Approval_Policy__mdt>();
    try {
      OnboardingRequirementVPRGateInvocable.Request req = new OnboardingRequirementVPRGateInvocable.Request();
      req.onboardingId = onboardId;
      req.vendorProgramId = progId;
      List<OnboardingRequirementVPRGateInvocable.Result> results = OnboardingRequirementVPRGateInvocable.filterForGate(
        new List<OnboardingRequirementVPRGateInvocable.Request>{ req }
      );
      System.assertEquals(1, results.size());
      System.assertEquals(1, results[0].vendorProgramRequirements.size());
      System.assertEquals(v1.Id, results[0].vendorProgramRequirements[0].Id);
    } finally {
      OnboardingRequirementVPRGateService.clearTestStubs();
    }
  }

  private static Id fakeId(SObjectType typ) {
    return fakeId(typ, 0);
  }

  private static Id fakeId(SObjectType typ, Integer suffix) {
    String p = typ.getDescribe().getKeyPrefix();
    String n = String.valueOf(Math.abs(suffix == null ? 0 : suffix));
    String pad = '000000000000';
    String tail = (pad + n).substring((pad + n).length() - 12);
    return (Id) (p + tail);
  }
}
