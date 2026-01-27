public with sharing class VendorOnboardingWizardRepository {
  // -------------------------------
  // Vendor
  // -------------------------------

  public static List<Vendor__c> searchVendors(String vendorName) {
    if (String.isBlank(vendorName)) {
      return new List<Vendor__c>();
    }
    return [
      SELECT Id, Name
      FROM Vendor__c
      WHERE Name LIKE :('%' + vendorName + '%')
      LIMIT 10
    ];
  }

  public static Id insertVendor(Vendor__c vendor) {
    // Clone to avoid issues if record already has an Id
    Vendor__c vendorToInsert = vendor.Id != null
      ? vendor.clone(false, true, false, false)
      : vendor;
    insert vendorToInsert;
    return vendorToInsert.Id;
  }

  /**
   * Gets all vendors with their associated vendor programs for hierarchical display.
   * Returns vendors with their programs in a structure suitable for tree-grid.
   */
  public static List<Vendor__c> getVendorsWithPrograms() {
    return [
      SELECT
        Id,
        Name,
        Active__c,
        CreatedDate,
        LastModifiedDate,
        (
          SELECT
            Id,
            Name,
            Status__c,
            Active__c,
            Label__c,
            Retail_Option__c,
            Business_Vertical__c,
            CreatedDate,
            LastModifiedDate,
            LastModifiedBy.Name
          FROM Vendor_Customizations__r
          ORDER BY LastModifiedDate DESC
        )
      FROM Vendor__c
      ORDER BY Name
      LIMIT 200
    ];
  }

  /**
   * Gets vendors with programs filtered by search text.
   */
  public static List<Vendor__c> searchVendorsWithPrograms(String searchText) {
    String searchPattern = '%' + searchText + '%';
    return [
      SELECT
        Id,
        Name,
        Active__c,
        CreatedDate,
        LastModifiedDate,
        (
          SELECT
            Id,
            Name,
            Status__c,
            Active__c,
            Label__c,
            Retail_Option__c,
            Business_Vertical__c,
            CreatedDate,
            LastModifiedDate,
            LastModifiedBy.Name
          FROM Vendor_Customizations__r
          WHERE Name LIKE :searchPattern OR Label__c LIKE :searchPattern
          ORDER BY LastModifiedDate DESC
        )
      FROM Vendor__c
      WHERE Name LIKE :searchPattern
      ORDER BY Name
      LIMIT 200
    ];
  }

  // -------------------------------
  // Vendor Program
  // -------------------------------

  public static List<Vendor_Customization__c> searchVendorPrograms(
    String vendorProgramName
  ) {
    if (String.isBlank(vendorProgramName)) {
      return new List<Vendor_Customization__c>();
    }
    return [
      SELECT Id, Name, Vendor__r.Name, Status__c, CreatedDate
      FROM Vendor_Customization__c
      WHERE Name LIKE :('%' + vendorProgramName + '%')
      ORDER BY CreatedDate DESC
      LIMIT 10
    ];
  }

  /**
   * Account-aware vendor program search with eligibility gating.
   * If eligibilityPassed is false/null, only returns programs where Vendor__r.Name = 'PerfectVision'.
   * If true, returns programs where Vendor__r.Name != 'PerfectVision'.
   * AccountId is reserved for future filtering (e.g., NDA/Base Application checks).
   */
  public static List<Vendor_Customization__c> searchVendorProgramsForAccount(
    Id accountId,
    String vendorProgramName,
    Boolean eligibilityPassed,
    Boolean accountHasNda,
    Boolean accountHasProgramBase
  ) {
    if (String.isBlank(vendorProgramName)) {
      return new List<Vendor_Customization__c>();
    }

    Boolean eligible = eligibilityPassed == null ? false : eligibilityPassed;
    String nameFilter = '%' + vendorProgramName + '%';

    Boolean hasNda = accountHasNda == null ? false : accountHasNda;
    Boolean hasProgramBase = accountHasProgramBase == null
      ? false
      : accountHasProgramBase;

    List<Vendor_Customization__c> programs = [
      SELECT
        Id,
        Name,
        Vendor__r.Name,
        Status__c,
        Active__c,
        CreatedDate,
        Vendor_Program_Group__r.Requires_NDA__c,
        Vendor_Program_Group__r.Requires_Program_Base__c
      FROM Vendor_Customization__c
      WHERE Name LIKE :nameFilter AND Status__c = 'Active' AND Active__c = TRUE
      ORDER BY CreatedDate DESC
      LIMIT 50
    ];

    List<Vendor_Customization__c> filtered = new List<Vendor_Customization__c>();
    for (Vendor_Customization__c vendorProgram : programs) {
      Boolean isPerfectVision =
        vendorProgram.Vendor__r != null &&
        vendorProgram.Vendor__r.Name == 'PerfectVision';
      if (!eligible) {
        if (isPerfectVision) {
          filtered.add(vendorProgram);
        }
        continue;
      }

      if (isPerfectVision) {
        continue;
      }

      Boolean requiresNda =
        vendorProgram.Vendor_Program_Group__r != null &&
        vendorProgram.Vendor_Program_Group__r.Requires_NDA__c;
      Boolean requiresBase =
        vendorProgram.Vendor_Program_Group__r != null &&
        vendorProgram.Vendor_Program_Group__r.Requires_Program_Base__c;
      Boolean ndaOk = !requiresNda || hasNda;
      Boolean baseOk = !requiresBase || hasProgramBase;
      if (ndaOk && baseOk) {
        filtered.add(vendorProgram);
      }
    }

    return filtered;
  }

  /**
   * Gets recent vendor programs ordered by LastModifiedDate.
   * Returns the most recently viewed/modified vendor programs.
   */
  public static List<Vendor_Customization__c> getRecentVendorPrograms(
    Integer limitCount
  ) {
    if (limitCount == null || limitCount <= 0) {
      limitCount = 10; // Default limit
    }
    return [
      SELECT Id, Name, Vendor__r.Name, Status__c, CreatedDate, LastModifiedDate
      FROM Vendor_Customization__c
      ORDER BY LastModifiedDate DESC
      LIMIT :limitCount
    ];
  }

  public class AccountEligibility {
    public Boolean hasNda;
    public Boolean hasProgramBase;
  }

  /**
   * Returns NDA / Program Base Application completion flags for an Account.
   * NDA: Contract__r.Contract_Type__c = 'NDA' and Onboarding_Status__c != 'Cancelled'
   * Program Base Application: Contract__r.Contract_Type__c LIKE '%Program Base Application%' AND Onboarding_Status__c = 'Setup Complete'
   */
  public static AccountEligibility getAccountOnboardingEligibility(
    Id accountId
  ) {
    AccountEligibility eligibility = new AccountEligibility();

    Integer ndaCount = [
      SELECT COUNT()
      FROM Onboarding__c
      WHERE
        Account__c = :accountId
        AND Contract__r.Contract_Type__c = 'NDA'
        AND Onboarding_Status__c = 'Setup Complete'
    ];

    Integer programBaseCount = [
      SELECT COUNT()
      FROM Onboarding__c
      WHERE
        Account__c = :accountId
        AND Contract__r.Contract_Type__c LIKE '%Program Base Application%'
        AND Onboarding_Status__c = 'Setup Complete'
    ];

    eligibility.hasNda = ndaCount > 0;
    eligibility.hasProgramBase = programBaseCount > 0;
    return eligibility;
  }

  /**
   * Creates Onboarding__c and seeds Onboarding_Requirement__c records from Vendor_Program_Requirement__c.
   */
  public static OnboardingWithRequirementsResult createOnboardingWithRequirements(
    Id accountId,
    Id vendorProgramId,
    Id opportunityId
  ) {
    String onboardingStatus = PicklistHelper.getValidPicklistValue(
      'Onboarding__c',
      'Onboarding_Status__c',
      'Not Started'
    );
    String requirementStatus = PicklistHelper.getValidPicklistValue(
      'Onboarding_Requirement__c',
      'Status__c',
      'Not Started'
    );

    Onboarding__c onboarding = new Onboarding__c(
      Account__c = accountId,
      Vendor_Customization__c = vendorProgramId,
      Opportunity__c = opportunityId,
      Onboarding_Status__c = onboardingStatus
    );
    insert onboarding;

    List<Vendor_Program_Requirement__c> vprs = fetchRecentVendorProgramRequirements(
      vendorProgramId
    );
    List<Onboarding_Requirement__c> onboardingReqs = new List<Onboarding_Requirement__c>();
    for (Vendor_Program_Requirement__c vendorProgramRequirement : vprs) {
      Onboarding_Requirement__c onboardingRequirement = new Onboarding_Requirement__c(
        Onboarding__c = onboarding.Id,
        Vendor_Program_Requirement__c = vendorProgramRequirement.Id,
        Status__c = requirementStatus
      );
      onboardingReqs.add(onboardingRequirement);
    }
    if (!onboardingReqs.isEmpty()) {
      insert onboardingReqs;
    }

    OnboardingWithRequirementsResult onboardingWithRequirementsResult = new OnboardingWithRequirementsResult();
    onboardingWithRequirementsResult.onboardingId = onboarding.Id;
    onboardingWithRequirementsResult.requirementCount = onboardingReqs.size();
    return onboardingWithRequirementsResult;
  }

  public class OnboardingWithRequirementsResult {
    public Id onboardingId;
    public Integer requirementCount;
  }

  public class ContactRoleInfo {
    public Id contactId;
    public String name;
    public String email;
    public String role;
    public Boolean hasAcr;
  }

  /**
   * Returns contacts for an Account with their active AccountContactRelation role (if any).
   */
  public static List<ContactRoleInfo> getAccountContactsWithRoles(
    Id accountId
  ) {
    List<Contact> contacts = [
      SELECT Id, Name, Email
      FROM Contact
      WHERE AccountId = :accountId AND IsDeleted = FALSE
    ];

    Map<Id, String> contactIdToRole = new Map<Id, String>();
    for (AccountContactRelation acr : [
      SELECT Id, ContactId, Roles
      FROM AccountContactRelation
      WHERE AccountId = :accountId AND IsActive = TRUE
    ]) {
      if (!contactIdToRole.containsKey(acr.ContactId)) {
        contactIdToRole.put(acr.ContactId, acr.Roles);
      }
    }

    List<ContactRoleInfo> contactRoleInfoList = new List<ContactRoleInfo>();
    for (Contact contactRecord : contacts) {
      ContactRoleInfo contactRoleInfo = new ContactRoleInfo();
      contactRoleInfo.contactId = contactRecord.Id;
      contactRoleInfo.name = contactRecord.Name;
      contactRoleInfo.email = contactRecord.Email;
      contactRoleInfo.role = contactIdToRole.get(contactRecord.Id);
      contactRoleInfo.hasAcr = contactIdToRole.containsKey(contactRecord.Id);
      contactRoleInfoList.add(contactRoleInfo);
    }
    return contactRoleInfoList;
  }

  /**
   * Upserts an active AccountContactRelation for the given Account/Contact/Role.
   */
  public static Id upsertAccountContactRelation(
    Id accountId,
    Id contactId,
    String role
  ) {
    AccountContactRelation acr;
    try {
      acr = [
        SELECT Id
        FROM AccountContactRelation
        WHERE
          AccountId = :accountId
          AND ContactId = :contactId
          AND IsActive = TRUE
        LIMIT 1
      ];
    } catch (QueryException qe) {
      acr = null;
    }

    if (acr == null) {
      acr = new AccountContactRelation(
        AccountId = accountId,
        ContactId = contactId,
        IsActive = true
      );
    }
    acr.Roles = role;
    upsert acr;
    return acr.Id;
  }

  public static Id insertVendorProgram(Vendor_Customization__c vendorProgram) {
    // If record already has an Id and exists in database, return it
    if (vendorProgram.Id != null) {
      try {
        Vendor_Customization__c existing = [
          SELECT Id
          FROM Vendor_Customization__c
          WHERE Id = :vendorProgram.Id
          LIMIT 1
        ];
        return existing.Id;
      } catch (QueryException queryEx) {
        // Record doesn't exist, clone and insert
      }
    }
    // Clone to avoid issues if record already has an Id but doesn't exist
    Vendor_Customization__c programToInsert = vendorProgram.Id != null
      ? vendorProgram.clone(false, true, false, false)
      : vendorProgram;
    insert programToInsert;
    // Update the Id on the original object if it was null
    if (vendorProgram.Id == null) {
      vendorProgram.Id = programToInsert.Id;
    }
    return programToInsert.Id;
  }

  // -------------------------------
  // Vendor Program Group
  // -------------------------------

  public static List<Vendor_Program_Group__c> searchVendorProgramGroups(
    String vendorProgramGroupName
  ) {
    if (String.isBlank(vendorProgramGroupName)) {
      return new List<Vendor_Program_Group__c>();
    }
    return [
      SELECT Id, Name, Label__c, Logic_Type__c
      FROM Vendor_Program_Group__c
      WHERE Name LIKE :('%' + vendorProgramGroupName + '%')
      LIMIT 10
    ];
  }

  public static List<Vendor_Program_Group__c> getAllVendorProgramGroups() {
    return [
      SELECT Id, Name, Label__c, Logic_Type__c
      FROM Vendor_Program_Group__c
      ORDER BY Name
      LIMIT 100
    ];
  }

  public static Id getVendorProgramGroupForVendorProgram(Id vendorProgramId) {
    if (vendorProgramId == null) {
      return null;
    }
    try {
      Vendor_Customization__c vendorProgram = [
        SELECT Id, Vendor_Program_Group__c
        FROM Vendor_Customization__c
        WHERE Id = :vendorProgramId
        LIMIT 1
      ];
      return vendorProgram.Vendor_Program_Group__c;
    } catch (Exception ex) {
      System.debug(
        'Error getting Vendor Program Group for Vendor Program: ' +
        ex.getMessage()
      );
      return null;
    }
  }

  public static Id insertVendorProgramGroup(
    Vendor_Program_Group__c vendorProgramGroup
  ) {
    // If record already has an Id and exists in database, return it
    if (vendorProgramGroup.Id != null) {
      try {
        Vendor_Program_Group__c existing = [
          SELECT Id
          FROM Vendor_Program_Group__c
          WHERE Id = :vendorProgramGroup.Id
          LIMIT 1
        ];
        return existing.Id;
      } catch (QueryException queryEx) {
        // Record doesn't exist, clone and insert
      }
    }
    // Clone to avoid issues if record already has an Id but doesn't exist
    Vendor_Program_Group__c groupToInsert = vendorProgramGroup.Id != null
      ? vendorProgramGroup.clone(false, true, false, false)
      : vendorProgramGroup;
    insert groupToInsert;
    return groupToInsert.Id;
  }

  public static void linkVendorProgramToGroups(
    Id vendorProgramId,
    Id vendorId,
    Id vendorProgramGroupId
  ) {
    if (vendorProgramId == null) {
      throw new IllegalArgumentException('Vendor Program ID is required.');
    }
    List<Vendor_Customization__c> vendorPrograms = [
      SELECT
        Id,
        Vendor__c,
        Vendor_Program_Group__c
      FROM Vendor_Customization__c
      WHERE Id = :vendorProgramId
      LIMIT 1
    ];

    if (vendorPrograms.isEmpty()) {
      throw new IllegalArgumentException(
        'Vendor Program not found: ' + vendorProgramId
      );
    }

    Vendor_Customization__c vendorProgram = vendorPrograms[0];

    // Update Vendor_Program_Group__c
    vendorProgram.Vendor_Program_Group__c = vendorProgramGroupId;

    // Try to update Vendor__c if it's different
    // Note: Vendor__c is a MasterDetail field and may not be updateable after creation
    // If the field is not writeable, we'll skip updating it
    if (vendorProgram.Vendor__c != vendorId) {
      // Check if the field is updateable using describe
      Schema.DescribeFieldResult vendorFieldDescribe = Vendor_Customization__c.Vendor__c.getDescribe();
      if (vendorFieldDescribe.isUpdateable()) {
        vendorProgram.Vendor__c = vendorId;
      }
    }

    update vendorProgram;
  }

  // -------------------------------
  // Vendor Program Requirement
  // -------------------------------

  public static List<Vendor_Program_Requirement__c> searchVendorProgramRequirements(
    String vendorProgramRequirements
  ) {
    if (String.isBlank(vendorProgramRequirements)) {
      return new List<Vendor_Program_Requirement__c>();
    }
    return [
      SELECT
        Id,
        Name,
        Vendor_Program__c,
        Status__c,
        Is_Required__c,
        Sequence__c
      FROM Vendor_Program_Requirement__c
      WHERE Name LIKE :('%' + vendorProgramRequirements + '%')
      LIMIT 10
    ];
  }

  public static List<Vendor_Program_Requirement__c> fetchRecentVendorProgramRequirements(
    Id vendorProgramId
  ) {
    if (vendorProgramId == null) {
      return new List<Vendor_Program_Requirement__c>();
    }

    List<Vendor_Program_Requirement__c> requirements = [
      SELECT
        Id,
        Name,
        Vendor_Program__c,
        Status__c,
        Is_Required__c,
        Sequence__c,
        CreatedDate
      FROM Vendor_Program_Requirement__c
      WHERE Vendor_Program__c = :vendorProgramId
      ORDER BY Sequence__c NULLS LAST, CreatedDate DESC
      LIMIT 100
    ];

    return requirements;
  }

  public static Id insertVendorProgramRequirement(
    Vendor_Program_Requirement__c vendorProgramRequirement
  ) {
    insert vendorProgramRequirement;
    return vendorProgramRequirement.Id;
  }

  public static List<Vendor_Program_Requirement__c> bulkInsertVendorProgramRequirements(
    List<Vendor_Program_Requirement__c> requirements
  ) {
    if (requirements == null || requirements.isEmpty()) {
      return new List<Vendor_Program_Requirement__c>();
    }
    insert requirements;
    return requirements;
  }

  public static void updateRequirementSequences(
    List<Vendor_Program_Requirement__c> requirements
  ) {
    if (requirements == null || requirements.isEmpty()) {
      return;
    }
    update requirements;
  }

  public static void deleteVendorProgramRequirement(Id requirementId) {
    if (requirementId == null) {
      return;
    }
    try {
      Vendor_Program_Requirement__c requirementToDelete = [
        SELECT Id
        FROM Vendor_Program_Requirement__c
        WHERE Id = :requirementId
        LIMIT 1
      ];
      delete requirementToDelete;
    } catch (Exception ex) {
      throw new AuraHandledException(
        'Failed to delete requirement: ' + ex.getMessage()
      );
    }
  }

  // -------------------------------
  // Onboarding Status Rules Engine
  // -------------------------------

  public static List<Onboarding_Status_Rules_Engine__c> searchStatusRulesEngines(
    String nameSearchText
  ) {
    if (String.isBlank(nameSearchText)) {
      return new List<Onboarding_Status_Rules_Engine__c>();
    }
    return [
      SELECT Id, Name, Vendor_Program_Group__c
      FROM Onboarding_Status_Rules_Engine__c
      WHERE Name LIKE :('%' + nameSearchText + '%')
      LIMIT 10
    ];
  }

  public static Onboarding_Status_Rules_Engine__c getStatusRulesEngineById(
    Id engineId
  ) {
    if (engineId == null) {
      return null;
    }
    List<Onboarding_Status_Rules_Engine__c> engines = [
      SELECT
        Id,
        Name,
        Evaluation_Logic__c,
        Required_Status__c,
        Target_Onboarding_Status__c,
        Active__c
      FROM Onboarding_Status_Rules_Engine__c
      WHERE Id = :engineId
      LIMIT 1
    ];
    return engines.isEmpty() ? null : engines[0];
  }

  public static Id insertOnboardingStatusRulesEngine(
    Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine
  ) {
    insert onboardingStatusRulesEngine;
    return onboardingStatusRulesEngine.Id;
  }

  // -------------------------------
  // Onboarding Status Rules
  // -------------------------------

  public static Id insertStatusRule(Onboarding_Status_Rule__c statusRuleRecord) {
    // Clone to avoid issues if record already has an Id
    Onboarding_Status_Rule__c statusRuleToInsert = statusRuleRecord.Id != null
      ? statusRuleRecord.clone(false, true, false, false)
      : statusRuleRecord;
    insert statusRuleToInsert;
    return statusRuleToInsert.Id;
  }

  public static List<Onboarding_Status_Rule__c> searchStatusRules(
    String nameSearchText
  ) {
    if (String.isBlank(nameSearchText)) {
      return new List<Onboarding_Status_Rule__c>();
    }
    return [
      SELECT Id, Name, Parent_Rule__c, Requirement__c
      FROM Onboarding_Status_Rule__c
      WHERE Name LIKE :('%' + nameSearchText + '%')
      LIMIT 10
    ];
  }

  // -------------------------------
  // Communication Templates
  // -------------------------------

  public static List<Communication_Template__c> fetchCommunicationTemplates() {
    return [
      SELECT Id, Name
      FROM Communication_Template__c
      ORDER BY Name
      LIMIT 100
    ];
  }

  public static void linkCommunicationTemplate(
    Id vendorProgramId,
    Id templateId
  ) {
    if (templateId == null) {
      throw new IllegalArgumentException('Template ID is required.');
    }
    List<Communication_Template__c> communicationTemplates = [
      SELECT Id, Vendor_Program__c
      FROM Communication_Template__c
      WHERE Id = :templateId
      LIMIT 1
    ];

    if (communicationTemplates.isEmpty()) {
      throw new IllegalArgumentException(
        'Communication Template not found: ' + templateId
      );
    }

    Communication_Template__c communicationTemplate = communicationTemplates[0];
    communicationTemplate.Vendor_Program__c = vendorProgramId;
    update communicationTemplate;
  }

  public static String getVendorProgramLabel(Id vendorProgramId) {
    if (vendorProgramId == null) {
      return null;
    }
    List<Vendor_Customization__c> vendorCustomizationRecords = [
      SELECT Label__c
      FROM Vendor_Customization__c
      WHERE Id = :vendorProgramId
      LIMIT 1
    ];
    return vendorCustomizationRecords.isEmpty() ? null : vendorCustomizationRecords[0].Label__c;
  }

  // -------------------------------
  // Misc: Assignable Users, Roles, Groups
  // -------------------------------

  public static List<Territory_Role_Assignment__c> getTerritoryRoleAssignments() {
    return [
      SELECT Id, Name, Role__c
      FROM Territory_Role_Assignment__c
      ORDER BY Name
      LIMIT 1000
    ];
  }

  public static List<User> getAssignableUsers() {
    return [
      SELECT Id, Name
      FROM User
      WHERE IsActive = TRUE
      ORDER BY Name
      LIMIT 1000
    ];
  }

  public static List<Group> getPublicGroups() {
    return [
      SELECT Id, Name
      FROM Group
      ORDER BY Name
      LIMIT 1000
    ];
  }

}
