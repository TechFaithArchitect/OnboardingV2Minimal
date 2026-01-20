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
  public static VendorOnboardingWizardController.OnboardingWithRequirementsResult createOnboardingWithRequirements(
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

    VendorOnboardingWizardController.OnboardingWithRequirementsResult onboardingWithRequirementsResult = new VendorOnboardingWizardController.OnboardingWithRequirementsResult();
    onboardingWithRequirementsResult.onboardingId = onboarding.Id;
    onboardingWithRequirementsResult.requirementCount = onboardingReqs.size();
    return onboardingWithRequirementsResult;
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

  public static Id getVendorProgramRequirementGroupForVendorProgram(
    Id vendorProgramId
  ) {
    if (vendorProgramId == null) {
      return null;
    }
    try {
      Vendor_Customization__c vendorProgram = [
        SELECT Id, Vendor_Program_Requirement_Group__c
        FROM Vendor_Customization__c
        WHERE Id = :vendorProgramId
        LIMIT 1
      ];
      return vendorProgram.Vendor_Program_Requirement_Group__c;
    } catch (Exception ex) {
      System.debug(
        'Error getting Vendor Program Requirement Group for Vendor Program: ' +
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

  // -------------------------------
  // Vendor Program Requirement Group
  // -------------------------------

  public static List<Vendor_Program_Requirement_Group__c> searchVendorProgramRequirementGroups(
    String requirementGroupName
  ) {
    if (String.isBlank(requirementGroupName)) {
      return new List<Vendor_Program_Requirement_Group__c>();
    }
    return [
      SELECT Id, Name
      FROM Vendor_Program_Requirement_Group__c
      WHERE Name LIKE :('%' + requirementGroupName + '%')
      LIMIT 10
    ];
  }

  public static List<Vendor_Program_Requirement_Group__c> getAllVendorProgramRequirementGroups() {
    return [
      SELECT Id, Name, Status__c, Active__c
      FROM Vendor_Program_Requirement_Group__c
      WHERE Active__c = TRUE
      ORDER BY Name
      LIMIT 100
    ];
  }

  public static Id insertVendorProgramRequirementGroup(
    Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup
  ) {
    insert vendorProgramRequirementGroup;
    return vendorProgramRequirementGroup.Id;
  }

  public static Id insertVendorProgramGroupMember(
    Vendor_Program_Group_Member__c member
  ) {
    insert member;
    return member.Id;
  }

  public static List<Vendor_Program_Group_Member__c> getHistoricalGroupMembers(
    Id requirementSetId
  ) {
    if (requirementSetId == null) {
      return new List<Vendor_Program_Group_Member__c>();
    }
    // Get historical Vendor_Program_Group_Member__c records from the Requirement Set's Vendor Program
    // This is used when linking from historical values (5a)
    // Get vendor programs via junction object
    List<Id> vendorProgramIds = VendorProgramRequirementSetService.getVendorProgramsForRequirementSet(
      requirementSetId
    );

    if (vendorProgramIds.isEmpty()) {
      return new List<Vendor_Program_Group_Member__c>();
    }

    // Use first vendor program (for compatibility, but ideally should handle multiple)
    Id vendorProgramId = vendorProgramIds[0];

    return [
      SELECT
        Id,
        Vendor_Program_Group__c,
        Required_Program__c,
        Inherited_Program_Requirement_Group__c,
        Is_Target__c,
        Active__c,
        Vendor_Program_Group__r.Label__c,
        Inherited_Program_Requirement_Group__r.Name
      FROM Vendor_Program_Group_Member__c
      WHERE Required_Program__c = :vendorProgramId AND Active__c = TRUE
      ORDER BY CreatedDate DESC
      LIMIT 10
    ];
  }

  public static List<Onboarding_Status_Rules_Engine__c> getHistoricalStatusRulesEngines(
    Id requirementSetId
  ) {
    if (requirementSetId == null) {
      return new List<Onboarding_Status_Rules_Engine__c>();
    }
    // Get historical Status Rules Engines from the Requirement Set's Vendor Program
    // This is used when selecting from previous Requirement Set (8b)
    // Use junction object to get vendor programs
    List<Id> vendorProgramIds = VendorProgramRequirementSetService.getVendorProgramsForRequirementSet(
      requirementSetId
    );

    if (vendorProgramIds.isEmpty()) {
      return new List<Onboarding_Status_Rules_Engine__c>();
    }

    // Use first vendor program (for compatibility, but ideally should handle multiple)
    Id vendorProgramId = vendorProgramIds[0];

    // Get Vendor Program Groups for this Vendor Program
    List<Id> vendorProgramGroupIds = new List<Id>();
    for (Vendor_Program_Group_Member__c groupMember : [
      SELECT Vendor_Program_Group__c
      FROM Vendor_Program_Group_Member__c
      WHERE Required_Program__c = :vendorProgramId AND Active__c = TRUE
    ]) {
      vendorProgramGroupIds.add(groupMember.Vendor_Program_Group__c);
    }

    if (vendorProgramGroupIds.isEmpty()) {
      return new List<Onboarding_Status_Rules_Engine__c>();
    }

    return [
      SELECT
        Id,
        Name,
        Evaluation_Logic__c,
        Required_Status__c,
        Target_Onboarding_Status__c,
        Active__c,
        Requirement_Group__c,
        Vendor_Program_Group__c
      FROM Onboarding_Status_Rules_Engine__c
      WHERE
        Vendor_Program_Group__c IN :vendorProgramGroupIds
        AND Active__c = TRUE
      ORDER BY CreatedDate DESC
      LIMIT 10
    ];
  }

  public static void linkVendorProgramToGroups(
    Id vendorProgramId,
    Id vendorId,
    Id vendorProgramGroupId,
    Id vendorProgramRequirementGroupId
  ) {
    if (vendorProgramId == null) {
      throw new IllegalArgumentException('Vendor Program ID is required.');
    }
    List<Vendor_Customization__c> vendorPrograms = [
      SELECT
        Id,
        Vendor__c,
        Vendor_Program_Group__c,
        Vendor_Program_Requirement_Group__c
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

    // Update Vendor_Program_Group__c and Vendor_Program_Requirement_Group__c
    vendorProgram.Vendor_Program_Group__c = vendorProgramGroupId;
    vendorProgram.Vendor_Program_Requirement_Group__c = vendorProgramRequirementGroupId;

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
        Inherited_From_Group__c,
        Requirement_Group_Member__c,
        Requirement_Template__c
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
        Inherited_From_Group__c,
        Requirement_Group_Member__c,
        Requirement_Template__c,
        Requirement_Template__r.Requirement_Label__c,
        Status__c,
        Is_Required__c,
        Sequence__c,
        CreatedDate
      FROM Vendor_Program_Requirement__c
      WHERE Vendor_Program__c = :vendorProgramId
      ORDER BY Sequence__c NULLS LAST, CreatedDate DESC
      LIMIT 100
    ];

    // Handle null relationship safely
    for (
      Vendor_Program_Requirement__c vendorProgramRequirement : requirements
    ) {
      if (vendorProgramRequirement.Requirement_Template__r == null) {
        // This shouldn't happen, but handle gracefully
        System.debug(
          'Warning: Requirement ' +
            vendorProgramRequirement.Id +
            ' has no Requirement_Template__r'
        );
      }
    }

    return requirements;
  }

  public static List<Vendor_Program_Requirement__c> getRequirementsByGroup(
    Id requirementGroupId
  ) {
    if (requirementGroupId == null) {
      return new List<Vendor_Program_Requirement__c>();
    }
    // Requirements are linked to templates, and templates are linked to groups
    // So we need to find requirements that use templates linked to this group
    Set<Id> templateIds = new Set<Id>();
    for (Vendor_Program_Onboarding_Req_Template__c requirementTemplate : [
      SELECT Id
      FROM Vendor_Program_Onboarding_Req_Template__c
      WHERE Category_Group__c = :requirementGroupId
    ]) {
      templateIds.add(requirementTemplate.Id);
    }

    if (templateIds.isEmpty()) {
      return new List<Vendor_Program_Requirement__c>();
    }

    return [
      SELECT
        Id,
        Name,
        Vendor_Program__c,
        Requirement_Template__c,
        Status__c,
        Is_Required__c,
        Sequence__c
      FROM Vendor_Program_Requirement__c
      WHERE Requirement_Template__c IN :templateIds
      ORDER BY Sequence__c NULLS LAST, CreatedDate DESC
      LIMIT 100
    ];
  }

  public static List<Vendor_Program_Onboarding_Req_Template__c> getTemplatesByGroup(
    Id requirementGroupId
  ) {
    if (requirementGroupId == null) {
      return new List<Vendor_Program_Onboarding_Req_Template__c>();
    }
    return [
      SELECT
        Id,
        Requirement_Label__c,
        Requirement_Type__c,
        Status__c,
        Category_Group__c
      FROM Vendor_Program_Onboarding_Req_Template__c
      WHERE
        Category_Group__c = :requirementGroupId
        AND Is_Current_Version__c = TRUE
      ORDER BY Requirement_Label__c
    ];
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

  public static List<Vendor_Program_Requirement__c> getExistingRequirementsForTemplates(
    Id vendorProgramId,
    Set<Id> templateIds
  ) {
    if (
      vendorProgramId == null ||
      templateIds == null ||
      templateIds.isEmpty()
    ) {
      return new List<Vendor_Program_Requirement__c>();
    }
    return [
      SELECT Id, Requirement_Template__c, Vendor_Program__c
      FROM Vendor_Program_Requirement__c
      WHERE
        Vendor_Program__c = :vendorProgramId
        AND Requirement_Template__c IN :templateIds
    ];
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
      SELECT Id, Name, Requirement_Group__c, Vendor_Program_Group__c
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

  public static Id insertStatusRule(
    Onboarding_Status_Rule__c statusRuleRecord
  ) {
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

  // -------------------------------
  // Onboarding Requirement Set
  // -------------------------------

  public static Id insertOnboardingRequirementSet(
    Onboarding_Requirement_Set__c requirementSet
  ) {
    insert requirementSet;
    return requirementSet.Id;
  }

  public static List<Onboarding_Requirement_Set__c> fetchOnboardingRequirementSets() {
    return [
      SELECT Id, Name, Status__c
      FROM Onboarding_Requirement_Set__c
      ORDER BY CreatedDate DESC
      LIMIT 100
    ];
  }

  /**
   * Searches for requirement sets. If vendorProgramId is provided, uses junction object.
   */
  public static List<Onboarding_Requirement_Set__c> searchOnboardingRequirementSets(
    String searchText,
    Id vendorProgramId
  ) {
    String searchPattern = '%' + searchText + '%';

    if (vendorProgramId != null) {
      // Use junction object to find requirement sets for this vendor program
      Set<Id> requirementSetIds = new Set<Id>();
      for (Vendor_Program_Requirement_Set__c junction : [
        SELECT Onboarding_Requirement_Set__c
        FROM Vendor_Program_Requirement_Set__c
        WHERE Vendor_Program__c = :vendorProgramId
      ]) {
        requirementSetIds.add(junction.Onboarding_Requirement_Set__c);
      }

      if (!requirementSetIds.isEmpty()) {
        return [
          SELECT Id, Name, Status__c
          FROM Onboarding_Requirement_Set__c
          WHERE
            Id IN :requirementSetIds
            AND (Name LIKE :searchPattern
            OR Display_Label__c LIKE :searchPattern)
          ORDER BY Name
          LIMIT 50
        ];
      }

      return new List<Onboarding_Requirement_Set__c>();
    } else {
      return [
        SELECT Id, Name, Status__c
        FROM Onboarding_Requirement_Set__c
        WHERE Name LIKE :searchPattern OR Display_Label__c LIKE :searchPattern
        ORDER BY Name
        LIMIT 50
      ];
    }
  }

  /**
   * Gets all Requirement Sets with their associated Templates for hierarchical display.
   * Returns Requirement Sets with their Templates in a structure suitable for tree-grid.
   */
  /**
   * Gets Requirement Sets with their Templates using junction objects.
   * Note: Junction objects don't support relationship queries, so we query separately.
   */
  public static List<Onboarding_Requirement_Set__c> getRequirementSetsWithTemplates() {
    List<Onboarding_Requirement_Set__c> requirementSets = [
      SELECT
        Id,
        Name,
        Display_Label__c,
        Status__c,
        CreatedDate,
        LastModifiedDate
      FROM Onboarding_Requirement_Set__c
      ORDER BY Name
      LIMIT 200
    ];

    // Get templates via junction for each requirement set
    // Note: In practice, you'd want to batch this query for performance
    // For now, using the service method which handles this efficiently
    return requirementSets;
  }

  /**
   * Gets Requirement Sets with Templates filtered by search text.
   * Note: Cannot use OR with semi-join sub-selects in SOQL, so we query separately and combine.
   */
  public static List<Onboarding_Requirement_Set__c> searchRequirementSetsWithTemplates(
    String searchText
  ) {
    String searchPattern = '%' + searchText + '%';
    Set<Id> requirementSetIds = new Set<Id>();

    // Step 1: Find Requirement Sets where Name or Display_Label__c matches
    List<Onboarding_Requirement_Set__c> matchingRequirementSetsByNameOrLabel = [
      SELECT Id
      FROM Onboarding_Requirement_Set__c
      WHERE Name LIKE :searchPattern OR Display_Label__c LIKE :searchPattern
      LIMIT 200
    ];
    for (
      Onboarding_Requirement_Set__c reqSet : matchingRequirementSetsByNameOrLabel
    ) {
      requirementSetIds.add(reqSet.Id);
    }

    // Step 2: Find Templates where Requirement_Label__c matches and get their Requirement Set IDs via junction
    Set<Id> matchingTemplateIds = new Set<Id>();
    List<Vendor_Program_Onboarding_Req_Template__c> matchingTemplates = [
      SELECT Id
      FROM Vendor_Program_Onboarding_Req_Template__c
      WHERE Requirement_Label__c LIKE :searchPattern
      LIMIT 200
    ];
    for (
      Vendor_Program_Onboarding_Req_Template__c requirementTemplate : matchingTemplates
    ) {
      matchingTemplateIds.add(requirementTemplate.Id);
    }

    // Get requirement set IDs via junction object
    if (!matchingTemplateIds.isEmpty()) {
      List<Requirement_Set_Template__c> junctions = [
        SELECT Onboarding_Requirement_Set__c
        FROM Requirement_Set_Template__c
        WHERE Requirement_Template__c IN :matchingTemplateIds
      ];
      for (Requirement_Set_Template__c junction : junctions) {
        requirementSetIds.add(junction.Onboarding_Requirement_Set__c);
      }
    }

    // Step 3: Query Requirement Sets (templates will be fetched separately via junction)
    if (requirementSetIds.isEmpty()) {
      return new List<Onboarding_Requirement_Set__c>();
    }

    return [
      SELECT
        Id,
        Name,
        Display_Label__c,
        Status__c,
        CreatedDate,
        LastModifiedDate
      FROM Onboarding_Requirement_Set__c
      WHERE Id IN :requirementSetIds
      ORDER BY Name
      LIMIT 200
    ];
  }

  // -------------------------------
  // Onboarding Requirement Templates
  // -------------------------------

  public static Id insertOnboardingRequirementTemplate(
    Vendor_Program_Onboarding_Req_Template__c template
  ) {
    insert template;
    return template.Id;
  }

  public static void updateOnboardingRequirementTemplate(
    Vendor_Program_Onboarding_Req_Template__c requirementTemplate
  ) {
    try {
      update requirementTemplate;
    } catch (DmlException dmlEx) {
      System.debug('DML Error updating template: ' + dmlEx.getMessage());
      System.debug('Fields on template: ' + requirementTemplate);
      throw new AuraHandledException(
        'Error updating template: ' + dmlEx.getDmlMessage(0)
      );
    } catch (Exception ex) {
      System.debug('General Error updating template: ' + ex.getMessage());
      System.debug('Stack trace: ' + ex.getStackTraceString());
      throw new AuraHandledException(
        'Error updating template: ' + ex.getMessage()
      );
    }
  }

  public static void insertRequirementTemplates(
    List<Vendor_Program_Onboarding_Req_Template__c> templates
  ) {
    if (templates != null && !templates.isEmpty()) {
      insert templates;
    }
  }

  public static List<Vendor_Program_Onboarding_Req_Template__c> fetchOnboardingRequirementTemplates(
    Id requirementSetId
  ) {
    return getTemplatesForRequirementSet(requirementSetId);
  }

  /**
   * Gets requirement set with templates using junction object.
   * Note: Templates are fetched via junction, not direct relationship.
   */
  public static Onboarding_Requirement_Set__c getRequirementSetWithTemplates(
    Id requirementSetId
  ) {
    if (requirementSetId == null) {
      return null;
    }
    Onboarding_Requirement_Set__c reqSet = getRequirementSetById(
      requirementSetId
    );
    if (reqSet == null) {
      return null;
    }

    // Templates are fetched via junction - use service method for this
    // This method now just returns the requirement set
    // Service layer will handle template fetching
    return reqSet;
  }

  public static Onboarding_Requirement_Set__c getRequirementSetById(
    Id requirementSetId
  ) {
    if (requirementSetId == null) {
      return null;
    }
    List<Onboarding_Requirement_Set__c> reqSets = [
      SELECT Id, Name, Status__c
      FROM Onboarding_Requirement_Set__c
      WHERE Id = :requirementSetId
      LIMIT 1
    ];
    return reqSets.isEmpty() ? null : reqSets[0];
  }

  /**
   * Gets templates for a requirement set using the junction object.
   */
  public static List<Vendor_Program_Onboarding_Req_Template__c> getTemplatesForRequirementSet(
    Id requirementSetId
  ) {
    if (requirementSetId == null) {
      return new List<Vendor_Program_Onboarding_Req_Template__c>();
    }

    // Use junction object to get template IDs
    Set<Id> templateIds = new Set<Id>();
    for (Requirement_Set_Template__c junction : [
      SELECT Requirement_Template__c
      FROM Requirement_Set_Template__c
      WHERE Onboarding_Requirement_Set__c = :requirementSetId
    ]) {
      templateIds.add(junction.Requirement_Template__c);
    }

    if (templateIds.isEmpty()) {
      return new List<Vendor_Program_Onboarding_Req_Template__c>();
    }

    // Query templates using junction IDs
    return [
      SELECT
        Id,
        Requirement_Label__c,
        Requirement_Type__c,
        Status__c,
        Is_Current_Version__c,
        Category_Group__c,
        Onboarding_Status_Field_API_Name__c,
        Onboarding_Status_Value_When_Complete__c,
        Onboarding_Status_Value_When_Denied__c,
        Description__c,
        Default_Status_Options__c,
        Version__c,
        Previous_Version__c,
        Active__c
      FROM Vendor_Program_Onboarding_Req_Template__c
      WHERE Id IN :templateIds
      ORDER BY Requirement_Label__c
    ];
  }

  public static void updateRequirementTemplateGroupLinks(
    Id requirementGroupId,
    List<Id> templateIdsToLink,
    List<Id> templateIdsToUnlink
  ) {
    List<Vendor_Program_Onboarding_Req_Template__c> templatesToUpdate = new List<Vendor_Program_Onboarding_Req_Template__c>();

    // Link templates to the group
    if (templateIdsToLink != null && !templateIdsToLink.isEmpty()) {
      for (Id templateId : templateIdsToLink) {
        templatesToUpdate.add(
          new Vendor_Program_Onboarding_Req_Template__c(
            Id = templateId,
            Category_Group__c = requirementGroupId
          )
        );
      }
    }

    // Unlink templates from the group
    if (templateIdsToUnlink != null && !templateIdsToUnlink.isEmpty()) {
      for (Id templateId : templateIdsToUnlink) {
        templatesToUpdate.add(
          new Vendor_Program_Onboarding_Req_Template__c(
            Id = templateId,
            Category_Group__c = null
          )
        );
      }
    }

    if (!templatesToUpdate.isEmpty()) {
      update templatesToUpdate;
    }
  }

  /**
   * Links a requirement set to a vendor program using the junction object.
   */
  public static void linkRequirementSetToVendorProgram(
    Id requirementSetId,
    Id vendorProgramId
  ) {
    VendorProgramRequirementSetService.linkVendorProgramToRequirementSet(
      vendorProgramId,
      requirementSetId
    );
  }

  public static Vendor_Program_Onboarding_Req_Template__c getRequirementTemplate(
    Id templateId
  ) {
    if (templateId == null) {
      return null;
    }
    List<Vendor_Program_Onboarding_Req_Template__c> requirementTemplates = [
      SELECT
        Id,
        Requirement_Label__c,
        Requirement_Type__c,
        Status__c,
        Is_Current_Version__c
      FROM Vendor_Program_Onboarding_Req_Template__c
      WHERE Id = :templateId
      LIMIT 1
    ];
    return requirementTemplates.isEmpty() ? null : requirementTemplates[0];
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
    return vendorCustomizationRecords.isEmpty()
      ? null
      : vendorCustomizationRecords[0].Label__c;
  }

  public static void assignRequirementTemplatesToRequirementGroup(
    Id requirementGroupId,
    List<Id> templateIds
  ) {
    if (requirementGroupId == null) {
      throw new IllegalArgumentException('Requirement Group ID is required.');
    }
    if (templateIds == null || templateIds.isEmpty()) {
      return; // Nothing to assign
    }
    List<Vendor_Program_Onboarding_Req_Template__c> requirementTemplates = [
      SELECT Id
      FROM Vendor_Program_Onboarding_Req_Template__c
      WHERE Id IN :templateIds
    ];

    for (
      Vendor_Program_Onboarding_Req_Template__c requirementTemplate : requirementTemplates
    ) {
      requirementTemplate.Category_Group__c = requirementGroupId;
    }

    update requirementTemplates;
  }

  // -------------------------------
  // Recipient Groups
  // -------------------------------

  public static List<Recipient_Group__c> searchRecipientGroups(
    String recipientGroupName
  ) {
    if (String.isBlank(recipientGroupName)) {
      return new List<Recipient_Group__c>();
    }
    return [
      SELECT Id, Name
      FROM Recipient_Group__c
      WHERE Name LIKE :('%' + recipientGroupName + '%')
      LIMIT 10
    ];
  }

  public static Id insertRecipientGroup(Recipient_Group__c recipientGroup) {
    insert recipientGroup;
    return recipientGroup.Id;
  }

  public static Id insertRecipientGroupMember(
    Recipient_Group_Member__c recipientGroupMember
  ) {
    insert recipientGroupMember;
    return recipientGroupMember.Id;
  }

  // -------------------------------
  // Vendor Program Recipient Groups
  // -------------------------------

  public static List<Vendor_Program_Recipient_Group__c> searchVendorProgramRecipientGroups(
    String vprgName
  ) {
    if (String.isBlank(vprgName)) {
      return new List<Vendor_Program_Recipient_Group__c>();
    }
    // Search by Recipient Group name through the relationship
    return [
      SELECT Id, Name, Recipient_Group__r.Name
      FROM Vendor_Program_Recipient_Group__c
      WHERE Recipient_Group__r.Name LIKE :('%' + vprgName + '%')
      LIMIT 10
    ];
  }

  public static Id insertVendorProgramRecipientGroupLink(
    Id vendorProgramId,
    Id recipientGroupId
  ) {
    String defaultStatus = PicklistHelper.getValidPicklistValue(
      'Vendor_Program_Recipient_Group__c',
      'Status__c',
      'Draft'
    );
    Vendor_Program_Recipient_Group__c link = new Vendor_Program_Recipient_Group__c(
      Vendor_Program__c = vendorProgramId,
      Recipient_Group__c = recipientGroupId,
      Status__c = defaultStatus
    );
    insert link;
    return link.Id;
  }

  public static Id insertVendorProgramRecipientGroup(
    Vendor_Program_Recipient_Group__c link
  ) {
    insert link;
    return link.Id;
  }

  public static List<Vendor_Program_Recipient_Group__c> getRecipientGroupsForVendorProgram(
    Id vendorProgramId
  ) {
    if (vendorProgramId == null) {
      return new List<Vendor_Program_Recipient_Group__c>();
    }
    return [
      SELECT
        Id,
        Name,
        Recipient_Group__c,
        Recipient_Group__r.Name,
        Status__c,
        Is_Active__c
      FROM Vendor_Program_Recipient_Group__c
      WHERE Vendor_Program__c = :vendorProgramId
      ORDER BY CreatedDate DESC
    ];
  }

  public static List<Recipient_Group_Member__c> getRecipientGroupMembers(
    Id recipientGroupId
  ) {
    if (recipientGroupId == null) {
      return new List<Recipient_Group_Member__c>();
    }
    return [
      SELECT
        Id,
        Name,
        Recipient_User__c,
        Recipient_User__r.Name,
        Recipient_User__r.Email,
        Member_Type__c,
        Recipient_Type__c
      FROM Recipient_Group_Member__c
      WHERE Recipient_Group__c = :recipientGroupId
      ORDER BY CreatedDate DESC
    ];
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

  // -------------------------------
  // Onboarding Component Library
  // -------------------------------

  public static void upsertOnboardingComponents(
    List<String> componentApiNames
  ) {
    List<Onboarding_Component_Library__c> toUpsert = new List<Onboarding_Component_Library__c>();

    for (String apiName : componentApiNames) {
      String displayName = apiName
        .replace('vendorProgramOnboarding', '')
        .replaceAll('([A-Z])', ' $1')
        .trim();

      toUpsert.add(
        new Onboarding_Component_Library__c(
          Name = displayName,
          Component_API_Name__c = apiName,
          Component_Type__c = 'LWC', // You can customize if needed
          Active__c = true
        )
      );
    }

    upsert toUpsert Component_API_Name__c;
  }

  /**
   * Gets all active component library entries by their API name.
   * Returns a map of Component_API_Name__c to Id.
   */
  public static Map<String, Id> getComponentLibraryByApiName() {
    Map<String, Id> componentMap = new Map<String, Id>();

    List<Onboarding_Component_Library__c> components = [
      SELECT Id, Component_API_Name__c
      FROM Onboarding_Component_Library__c
      WHERE Active__c = TRUE
    ];

    for (Onboarding_Component_Library__c component : components) {
      componentMap.put(component.Component_API_Name__c, component.Id);
    }

    return componentMap;
  }
}
