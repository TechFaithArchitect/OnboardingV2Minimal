public class TestDataFactoryWrapper {
  // ----------------------------------------------------------------------------------
  // WRAPPERS
  // ----------------------------------------------------------------------------------

  // -------- Account & Contact --------
  public class AccountContactWrapper {
    public Account account;
    public Contact contact;
    public AccountContactWrapper(Account account, Contact contact) {
      this.account = account;
      this.contact = contact;
    }
  }

  // -------- Vendor & Program --------
  public class VendorCustomizationWrapper {
    public Vendor__c vendor;
    public Vendor_Customization__c customization;
    public VendorCustomizationWrapper(
      Vendor__c vendor,
      Vendor_Customization__c customization
    ) {
      this.vendor = vendor;
      this.customization = customization;
    }
  }

  // -------- Onboarding & Communication --------
  public class EmailTestContextWrapper {
    public Account account;
    public Contact contact;
    public Communication_Template__c template;
    public Onboarding__c onboarding;
    public EmailTestContextWrapper(
      Account account,
      Contact contact,
      Communication_Template__c template,
      Onboarding__c onboarding
    ) {
      this.account = account;
      this.contact = contact;
      this.template = template;
      this.onboarding = onboarding;
    }
  }

  // -------- Users & Permissions --------
  public class PermissionedUserWrapper {
    public User user;
    public PermissionSetAssignment psa;
    public PermissionedUserWrapper(User user, PermissionSetAssignment psa) {
      this.user = user;
      this.psa = psa;
    }
  }

  // -------- Technician & Work Orders --------
  public class TechnicianUserWrapper {
    public User user;
    public Contact contact;
    public ServiceResource serviceResource;
    public ServiceTerritoryMember territoryMember;
    public TechnicianUserWrapper(
      User user,
      Contact contact,
      ServiceResource serviceResource,
      ServiceTerritoryMember territoryMember
    ) {
      this.user = user;
      this.contact = contact;
      this.serviceResource = serviceResource;
      this.territoryMember = territoryMember;
    }
  }

  public class WorkOrderSetupWrapper {
    public WorkOrder workOrder;
    public WorkType workType;
    public User technicianUser;
    public WorkOrderSetupWrapper(
      WorkOrder workOrder,
      WorkType workType,
      User technicianUser
    ) {
      this.workOrder = workOrder;
      this.workType = workType;
      this.technicianUser = technicianUser;
    }
  }

  // -------- Territory --------
  public class TerritorySetupWrapper {
    public ServiceTerritory parentTerritory;
    public ServiceTerritory childTerritory;
    public ServiceTerritoryMember member;
    public TerritorySetupWrapper(
      ServiceTerritory parentTerritory,
      ServiceTerritory childTerritory,
      ServiceTerritoryMember member
    ) {
      this.parentTerritory = parentTerritory;
      this.childTerritory = childTerritory;
      this.member = member;
    }
  }

  public class TerritoryAssignmentWrapper {
    public User user;
    public Territory_Assignments__c assignment;
    public TerritoryAssignmentWrapper(
      User user,
      Territory_Assignments__c assignment
    ) {
      this.user = user;
      this.assignment = assignment;
    }
  }

  // -------- Rules Engines --------
  public class OnboardingRulesSetupWrapper {
    public Onboarding_Status_Rules_Engine__c ruleEngine;
    public List<Onboarding_Requirement__c> requirements;
    public List<Onboarding_Status_Rule__c> rules;
    public OnboardingRulesSetupWrapper(
      Onboarding_Status_Rules_Engine__c ruleEngine,
      List<Onboarding_Requirement__c> requirements,
      List<Onboarding_Status_Rule__c> rules
    ) {
      this.ruleEngine = ruleEngine;
      this.requirements = requirements;
      this.rules = rules;
    }
  }

  // -------- Vendor Program Version Chain --------
  public class VendorProgramVersionWrapper {
    public Vendor__c vendor;
    public Vendor_Customization__c parentVersion;
    public Vendor_Customization__c childVersion;

    public VendorProgramVersionWrapper(
      Vendor__c vendor,
      Vendor_Customization__c parentVersion,
      Vendor_Customization__c childVersion
    ) {
      this.vendor = vendor;
      this.parentVersion = parentVersion;
      this.childVersion = childVersion;
    }
  }

  public class OrgWideEmailWrapper {
    public OrgWideEmailDTO dto;
    public OrgWideEmailWrapper(OrgWideEmailDTO dto) {
      this.dto = dto;
    }
  }

  public class ECCTestWrapper {
    public Contact principalContact;
    public Contact secondaryContact;
    public External_Contact_Credential_Type__c primaryCredentialType;
    public POE_External_Contact_Credential__c principalExternalContactCredential;
    public POE_External_Contact_Credential__c secondaryExternalContactCredential;
    public ECC_Field_Configuration_Group__c eccFieldConfigurationGroup;
    public List<ECC_Field_Display_Configuration__c> displayConfigurations;

    public ECCTestWrapper(
      Contact principalContact,
      Contact secondaryContact,
      External_Contact_Credential_Type__c primaryCredentialType,
      POE_External_Contact_Credential__c principalExternalContactCredential,
      POE_External_Contact_Credential__c secondaryExternalContactCredential,
      ECC_Field_Configuration_Group__c eccFieldConfigurationGroup,
      List<ECC_Field_Display_Configuration__c> displayConfigurations
    ) {
      this.principalContact = principalContact;
      this.secondaryContact = secondaryContact;
      this.primaryCredentialType = primaryCredentialType;
      this.principalExternalContactCredential = principalExternalContactCredential;
      this.secondaryExternalContactCredential = secondaryExternalContactCredential;
      this.eccFieldConfigurationGroup = eccFieldConfigurationGroup;
      this.displayConfigurations = displayConfigurations;
    }
  }

  public class TrainingSetupWrapper {
    public Training_System__c trainingSystem;
    public Training_Requirement__c trainingRequirement;
    public TrainingSetupWrapper(
      Training_System__c trainingSystem,
      Training_Requirement__c trainingRequirement
    ) {
      this.trainingSystem = trainingSystem;
      this.trainingRequirement = trainingRequirement;
    }
  }

  // ----------------------------------------------------------------------------------
  // BUILDERS
  // ----------------------------------------------------------------------------------

  // -------- Account & Contact --------
  public static AccountContactWrapper createAccountContact(Boolean doInsert) {
    Account account = TestAccountFactory.create('Test Account', doInsert);
    Contact contact = TestContactFactory.create(
      'First',
      'Last',
      account,
      doInsert
    );
    return new AccountContactWrapper(account, contact);
  }

  // -------- Vendor & Vendor Program --------
  public static VendorCustomizationWrapper createVendorCustomizationWrapper(
    Boolean doInsert
  ) {
    Vendor__c vendor = TestVendorFactory.createVendorInternal(doInsert);
    Vendor_Customization__c customization = TestVendorFactory.createCustomizationInternal(
      vendor,
      'Draft',
      false,
      null,
      doInsert
    );
    return new VendorCustomizationWrapper(vendor, customization);
  }

  public static VendorCustomizationWrapper createVendorProgram(
    Boolean doInsert
  ) {
    return TestVendorProgramFactory.createVendorWithCustomization(doInsert);
  }

  public static VendorCustomizationWrapper createDraftVendorCustomizationWrapper(
    Boolean doInsert
  ) {
    return createVendorCustomizationWrapper(doInsert);
  }

  public static VendorProgramVersionWrapper createVersionedProgram(
    Boolean doInsert
  ) {
    TestVendorProgramFactory.VersionChainWrapper internal = TestVendorProgramFactory.createVersionChain(
      doInsert
    );
    return new VendorProgramVersionWrapper(
      internal.vendor,
      internal.parentVersion,
      internal.childVersion
    );
  }

  public static OnboardingRulesSetupWrapper createRulesVersionChain(
    Boolean doInsert
  ) {
    TestOnboardingRulesFactory.VersionChainWrapper rulesVersionChain = TestOnboardingRulesFactory.createVersionChain(
      doInsert
    );

    // Convert Vendor_Program_Requirement__c to Onboarding_Requirement__c
    // Note: This method doesn't create Onboarding_Requirement__c records since we don't have an Onboarding__c
    // If you need Onboarding_Requirement__c records, use createAllOnboardingRule or similar methods instead
    List<Onboarding_Requirement__c> onboardingRequirements = new List<Onboarding_Requirement__c>();

    return new OnboardingRulesSetupWrapper(
      rulesVersionChain.engine,
      onboardingRequirements, // Empty list since we don't have an Onboarding__c to link to
      rulesVersionChain.rules
    );
  }

  // -------- ECC Wrappers --------
  public static ECCTestWrapper createECCScenario(Boolean doInsert) {
    VendorCustomizationWrapper vendorCustomizationWrapper = createVendorCustomizationWrapper(
      doInsert
    );
    AccountContactWrapper accountContactWrapper = createAccountContact(
      doInsert
    );

    Contact principalContact = accountContactWrapper.contact;
    principalContact.POE_Commercial_Programs__c = 'Verizon Fios D2D';
    principalContact.Principal_Owner__c = true;
    update principalContact;

    Contact secondaryContact = TestContactFactory.create(
      'Other',
      'Contact',
      accountContactWrapper.account,
      doInsert
    );
    secondaryContact.Principal_Owner__c = false;
    update secondaryContact;

    External_Contact_Credential_Type__c mainExternalContactCredentialType = TestCredentialFactory.createCredentialType(
      'Main Credential',
      1,
      vendorCustomizationWrapper.customization,
      true,
      doInsert
    );
    External_Contact_Credential_Type__c dependentExternalContactCredentialType = TestCredentialFactory.createCredentialType(
      'Dependent Credential',
      2,
      vendorCustomizationWrapper.customization,
      true,
      doInsert
    );

    TestCredentialFactory.createDependency(
      mainExternalContactCredentialType,
      dependentExternalContactCredentialType,
      vendorCustomizationWrapper.customization,
      doInsert
    );
    TestCredentialFactory.createRequiredCredential(
      mainExternalContactCredentialType,
      vendorCustomizationWrapper.customization,
      true,
      doInsert
    );

    POE_External_Contact_Credential__c principalExternalContactCredential = TestECCFactory.createExternalContactCredential(
      principalContact,
      'principal_user',
      'Verizon Fios D2D',
      'In Progress',
      mainExternalContactCredentialType,
      doInsert
    );
    POE_External_Contact_Credential__c secondaryExternalContactCredential = TestECCFactory.createExternalContactCredential(
      secondaryContact,
      'other_user',
      'Verizon Fios D2D',
      'New',
      mainExternalContactCredentialType,
      doInsert
    );

    ECC_Field_Configuration_Group__c eccFieldConfigurationGroup = TestECCFactory.createFieldConfigurationGroup(
      'Default Group',
      doInsert
    );
    TestECCFactory.createGroupMapping(
      eccFieldConfigurationGroup,
      vendorCustomizationWrapper.customization,
      doInsert
    );

    List<ECC_Field_Display_Configuration__c> eccFieldDisplayConfigurations = new List<ECC_Field_Display_Configuration__c>{
      TestECCFactory.createDisplayConfiguration(
        eccFieldConfigurationGroup,
        'POE_Process_Status__c',
        'Process Status',
        false,
        true,
        doInsert
      ),
      TestECCFactory.createDisplayConfiguration(
        eccFieldConfigurationGroup,
        'Hidden_Field__c',
        'Hidden Field',
        true,
        false,
        doInsert
      )
    };

    return new ECCTestWrapper(
      principalContact,
      secondaryContact,
      mainExternalContactCredentialType,
      principalExternalContactCredential,
      secondaryExternalContactCredential,
      eccFieldConfigurationGroup,
      eccFieldDisplayConfigurations
    );
  }

  // -------- Onboarding Rules Builders (for specific test scenarios) --------
  public static TrainingSetupWrapper createTrainingSetup(
    Boolean doInsert,
    Vendor_Customization__c vendorProgram
  ) {
    Training_System__c trainingSystem = TestTrainingSystemFactory.create(
      doInsert
    );
    Training_Requirement__c trainingRequirement = TestTrainingRequirementFactory.create(
      doInsert,
      vendorProgram,
      trainingSystem
    );
    return new TrainingSetupWrapper(trainingSystem, trainingRequirement);
  }

  public static OnboardingRulesSetupWrapper createAllOnboardingRule(
    Onboarding__c onboarding,
    Integer ruleCount,
    String expectedStatus,
    Boolean createRequirements,
    Boolean doInsert
  ) {
    Vendor_Program_Group__c vendorProgramGroup = createVendorProgramGroupForOnboarding(
      onboarding,
      doInsert
    );
    String resolvedTargetStatus = resolveTargetStatus(expectedStatus);
    String resolvedExpectedStatus = resolveExpectedStatus(expectedStatus);
    String initialRequirementStatus = resolveRequirementStatus('New');

    // Create rules engine with ALL logic
    Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(
      doInsert,
      null, // requirementGroup
      vendorProgramGroup,
      'ALL',
      null, // requiredStatus
      resolvedTargetStatus
    );

    // Create vendor program requirements
    List<Vendor_Program_Requirement__c> vendorProgramRequirements = new List<Vendor_Program_Requirement__c>();
    List<Onboarding_Requirement__c> onboardingRequirements = new List<Onboarding_Requirement__c>();
    List<Onboarding_Status_Rule__c> statusRules = new List<Onboarding_Status_Rule__c>();

    for (Integer i = 0; i < ruleCount; i++) {
      Vendor_Program_Requirement__c vendorProgramRequirement = createVendorProgramRequirementForOnboarding(
        onboarding,
        doInsert
      );
      vendorProgramRequirements.add(vendorProgramRequirement);

      if (createRequirements) {
        Onboarding_Requirement__c onboardingRequirement = TestOnboardingRequirementFactory.create(
          doInsert,
          onboarding,
          vendorProgramRequirement
        );
        if (String.isNotBlank(initialRequirementStatus)) {
          onboardingRequirement.Status__c = initialRequirementStatus;
        }
        if (doInsert) {
          update onboardingRequirement;
        }
        onboardingRequirements.add(onboardingRequirement);
      }

      Onboarding_Status_Rule__c statusRule = TestOnboardingRulesFactory.create(
        doInsert,
        engine,
        vendorProgramRequirement,
        resolvedExpectedStatus,
        i + 1
      );
      statusRules.add(statusRule);
    }

    return new OnboardingRulesSetupWrapper(
      engine,
      onboardingRequirements,
      statusRules
    );
  }

  public static OnboardingRulesSetupWrapper createAnyOnboardingRule(
    Onboarding__c onboarding,
    Integer ruleCount,
    String targetStatus,
    Boolean createRequirements,
    Boolean doInsert
  ) {
    Vendor_Program_Group__c vendorProgramGroup = createVendorProgramGroupForOnboarding(
      onboarding,
      doInsert
    );
    String resolvedTargetStatus = resolveTargetStatus(targetStatus);
    String initialRequirementStatus = resolveRequirementStatus('New');

    // Create rules engine with ANY logic
    Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(
      doInsert,
      null,
      vendorProgramGroup,
      'ANY',
      null,
      resolvedTargetStatus
    );

    List<Vendor_Program_Requirement__c> vendorProgramRequirements = new List<Vendor_Program_Requirement__c>();
    List<Onboarding_Requirement__c> onboardingRequirements = new List<Onboarding_Requirement__c>();
    List<Onboarding_Status_Rule__c> statusRules = new List<Onboarding_Status_Rule__c>();

    // Create rules with different expected statuses for ANY logic
    List<String> validExpectedStatuses = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Status_Rule__c.SObjectType,
      'Expected_Status__c'
    );
    String setupCompleteStatus = validExpectedStatuses.contains(
        'Setup Complete'
      )
      ? 'Setup Complete'
      : validExpectedStatuses[0];
    String inProcessStatus = validExpectedStatuses.contains('In Process')
      ? 'In Process'
      : (validExpectedStatuses.size() > 1
          ? validExpectedStatuses[1]
          : validExpectedStatuses[0]);
    List<String> expectedStatuses = new List<String>{
      setupCompleteStatus,
      inProcessStatus
    };

    for (Integer i = 0; i < ruleCount; i++) {
      Vendor_Program_Requirement__c vendorProgramRequirement = createVendorProgramRequirementForOnboarding(
        onboarding,
        doInsert
      );
      vendorProgramRequirements.add(vendorProgramRequirement);

      if (createRequirements) {
        Onboarding_Requirement__c onboardingRequirement = TestOnboardingRequirementFactory.create(
          doInsert,
          onboarding,
          vendorProgramRequirement
        );
        if (String.isNotBlank(initialRequirementStatus)) {
          onboardingRequirement.Status__c = initialRequirementStatus;
        }
        if (doInsert) {
          update onboardingRequirement;
        }
        onboardingRequirements.add(onboardingRequirement);
      }

      String expectedStatus = expectedStatuses[
        Math.mod(i, expectedStatuses.size())
      ];
      Onboarding_Status_Rule__c statusRule = TestOnboardingRulesFactory.create(
        doInsert,
        engine,
        vendorProgramRequirement,
        expectedStatus,
        i + 1
      );
      statusRules.add(statusRule);
    }

    return new OnboardingRulesSetupWrapper(
      engine,
      onboardingRequirements,
      statusRules
    );
  }

  public static OnboardingRulesSetupWrapper createCustomOnboardingRule(
    Onboarding__c onboarding,
    List<String> expectedStatuses,
    String customLogic,
    String targetStatus,
    Boolean overrideStatus,
    Boolean createRequirements,
    Integer ruleCount
  ) {
    Vendor_Program_Group__c vendorProgramGroup = createVendorProgramGroupForOnboarding(
      onboarding,
      true
    );
    String resolvedTargetStatus = resolveTargetStatus(targetStatus);
    String initialRequirementStatus = resolveRequirementStatus('New');

    // Create rules engine with CUSTOM logic
    List<String> evaluationLogics = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Status_Rules_Engine__c.SObjectType,
      'Evaluation_Logic__c'
    );
    String customLogicValue = evaluationLogics.contains('CUSTOM')
      ? 'CUSTOM'
      : evaluationLogics[0];
    List<String> resolvedExpectedStatuses = new List<String>();
    if (expectedStatuses != null) {
      for (String status : expectedStatuses) {
        resolvedExpectedStatuses.add(resolveExpectedStatus(status));
      }
    }
    if (resolvedExpectedStatuses.isEmpty()) {
      resolvedExpectedStatuses.add(resolveExpectedStatus(null));
    }

    // Create engine without inserting first, so we can set Custom_Evaluation_Logic__c before insert
    Onboarding_Status_Rules_Engine__c engine = TestOnboardingRulesEngineFactory.create(
      false,
      null,
      vendorProgramGroup,
      customLogicValue,
      null,
      resolvedTargetStatus
    );
    // Only set Custom_Evaluation_Logic__c if Evaluation_Logic__c supports it
    if (customLogicValue == 'CUSTOM') {
      engine.Custom_Evaluation_Logic__c = customLogic;
    }
    engine.Override_Status__c = overrideStatus;
    insert engine;

    List<Vendor_Program_Requirement__c> vendorProgramRequirements = new List<Vendor_Program_Requirement__c>();
    List<Onboarding_Requirement__c> onboardingRequirements = new List<Onboarding_Requirement__c>();
    List<Onboarding_Status_Rule__c> statusRules = new List<Onboarding_Status_Rule__c>();

    for (Integer i = 0; i < ruleCount; i++) {
      Vendor_Program_Requirement__c vendorProgramRequirement = createVendorProgramRequirementForOnboarding(
        onboarding,
        true
      );
      vendorProgramRequirements.add(vendorProgramRequirement);

      if (createRequirements) {
        Onboarding_Requirement__c onboardingRequirement = TestOnboardingRequirementFactory.create(
          true,
          onboarding,
          vendorProgramRequirement
        );
        if (String.isNotBlank(initialRequirementStatus)) {
          onboardingRequirement.Status__c = initialRequirementStatus;
        }
        update onboardingRequirement;
        onboardingRequirements.add(onboardingRequirement);
      }

      String expectedStatus = resolvedExpectedStatuses[
        Math.mod(i, resolvedExpectedStatuses.size())
      ];
      Onboarding_Status_Rule__c statusRule = TestOnboardingRulesFactory.create(
        true,
        engine,
        vendorProgramRequirement,
        expectedStatus,
        i + 1
      );
      statusRules.add(statusRule);
    }

    return new OnboardingRulesSetupWrapper(
      engine,
      onboardingRequirements,
      statusRules
    );
  }

  private static Vendor_Program_Group__c createVendorProgramGroupForOnboarding(
    Onboarding__c onboarding,
    Boolean doInsert
  ) {
    Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(
      doInsert
    );
    if (
      doInsert &&
      onboarding != null &&
      onboarding.Vendor_Customization__c != null
    ) {
      Vendor_Customization__c vendorProgram = new Vendor_Customization__c(
        Id = onboarding.Vendor_Customization__c
      );
      TestVendorProgramGroupMemberFactory.create(
        true,
        vendorProgramGroup,
        vendorProgram,
        null,
        true
      );
    }
    return vendorProgramGroup;
  }

  private static Vendor_Program_Requirement__c createVendorProgramRequirementForOnboarding(
    Onboarding__c onboarding,
    Boolean doInsert
  ) {
    if (onboarding != null && onboarding.Vendor_Customization__c != null) {
      Vendor_Customization__c vendorProgram = new Vendor_Customization__c(
        Id = onboarding.Vendor_Customization__c
      );
      return TestVendorProgramRequirementFactory.create(
        vendorProgram,
        true,
        doInsert
      );
    }
    return TestVendorProgramRequirementFactory.create(doInsert);
  }

  private static String resolveExpectedStatus(String preferredStatus) {
    List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Status_Rule__c.SObjectType,
      'Expected_Status__c'
    );
    if (
      String.isNotBlank(preferredStatus) &&
      validStatuses.contains(preferredStatus)
    ) {
      return preferredStatus;
    }
    return validStatuses.isEmpty() ? null : validStatuses[0];
  }

  private static String resolveTargetStatus(String preferredStatus) {
    List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Status_Rules_Engine__c.SObjectType,
      'Target_Onboarding_Status__c'
    );
    if (
      String.isNotBlank(preferredStatus) &&
      validStatuses.contains(preferredStatus)
    ) {
      return preferredStatus;
    }
    return validStatuses.isEmpty() ? null : validStatuses[0];
  }

  private static String resolveRequirementStatus(String preferredStatus) {
    List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
      Onboarding_Requirement__c.SObjectType,
      'Status__c'
    );
    if (
      String.isNotBlank(preferredStatus) &&
      validStatuses.contains(preferredStatus)
    ) {
      return preferredStatus;
    }
    return validStatuses.isEmpty() ? null : validStatuses[0];
  }

  public static TerritoryAssignmentWrapper createTerritoryAssignmentWithUser(
    Boolean doInsert
  ) {
    User user = TestUserFactory.createStandardUser(doInsert);
    Territory_Assignments__c assignment = TestDataFactory.createTerritoryAssignmentWithUser(
      user,
      'Recruiter__c',
      doInsert
    );
    return new TerritoryAssignmentWrapper(user, assignment);
  }

  // -------- Communication --------
  public static EmailTestContextWrapper createEmailTestContext(
    Boolean doInsert
  ) {
    VendorCustomizationWrapper vendorCustomizationWrapper = createVendorProgram(
      doInsert
    );
    Account account = TestDataFactory.createAccount('Email Account', doInsert);
    Contact contact = TestDataFactory.createContact(
      'Email',
      'User',
      doInsert,
      account
    );
    Onboarding__c onboarding = TestOnboardingFactory.create(
      account,
      vendorCustomizationWrapper.customization,
      doInsert
    );
    Communication_Template__c template = TestCommTemplateFactory.createTemplate(
      doInsert
    );
    return new EmailTestContextWrapper(account, contact, template, onboarding);
  }

  public static Vendor_Program_Group__c createVendorProgramGroup(
    Boolean doInsert
  ) {
    return TestVendorProgramGroupFactory.create(doInsert);
  }

  // -------- Org-Wide Email Address --------
  public static OrgWideEmailWrapper createOrgWideEmailDTO(String devName) {
    return new OrgWideEmailWrapper(TestOrgWideEmailDTOFactory.create(devName));
  }

  // -------- Territory --------
  public static TerritorySetupWrapper createTerritorySetup(Boolean doInsert) {
    return TestTerritoryFactory.createSetup(doInsert);
  }
}
