/**
 * Facade service that delegates to domain-specific services
 * Maintains backward compatibility while improving code organization
 * @deprecated Use domain-specific services directly (VendorService, VendorProgramService, etc.)
 */
public with sharing class VendorOnboardingWizardService {
  // -------------------------------
  // Vendor - Delegates to VendorService
  // -------------------------------

  public static List<Vendor__c> searchVendors(String vendorName) {
    return VendorService.searchVendors(vendorName);
  }

  public static Id createVendor(Vendor__c vendor) {
    return VendorService.createVendor(vendor);
  }

  /**
   * Gets all vendors with their associated vendor programs for hierarchical display.
   */
  public static List<Vendor__c> getVendorsWithPrograms() {
    return VendorService.getVendorsWithPrograms();
  }

  /**
   * Gets vendors with programs filtered by search text.
   */
  public static List<Vendor__c> searchVendorsWithPrograms(String searchText) {
    return VendorService.searchVendorsWithPrograms(searchText);
  }

  // -------------------------------
  // Vendor Program - Delegates to VendorProgramService
  // -------------------------------

  public static List<Vendor_Customization__c> searchVendorPrograms(
    String vendorProgramName
  ) {
    return VendorProgramService.searchVendorPrograms(vendorProgramName);
  }

  /**
   * Account-aware vendor program search with eligibility gating.
   * @param accountId Account context for future gating/metrics.
   * @param vendorProgramName Search text.
   * @param eligibilityPassed If false/null, only PerfectVision is returned; if true, PerfectVision is excluded.
   */
  public static List<Vendor_Customization__c> searchVendorProgramsForAccount(
    Id accountId,
    String vendorProgramName,
    Boolean eligibilityPassed,
    Boolean accountHasNda,
    Boolean accountHasProgramBase
  ) {
    return VendorProgramService.searchVendorProgramsForAccount(
      accountId,
      vendorProgramName,
      eligibilityPassed,
      accountHasNda,
      accountHasProgramBase
    );
  }

  /**
   * Returns NDA / Program Base Application eligibility for an Account.
   */
  @AuraEnabled
  public static VendorProgramEligibilityResult getVendorProgramEligibilityForAccount(
    Id accountId
  ) {
    ValidationHelper.requireId(accountId, 'Account ID');
    VendorOnboardingWizardRepository.AccountEligibility eligibility = VendorOnboardingWizardRepository.getAccountOnboardingEligibility(
      accountId
    );

    Boolean eligible = eligibility.hasNda && eligibility.hasProgramBase;
    String message;
    if (eligible) {
      message = 'Eligible for all vendor programs.';
    } else if (!eligibility.hasNda && !eligibility.hasProgramBase) {
      message = 'NDA and Program Base Application must be completed.';
    } else if (!eligibility.hasNda) {
      message = 'NDA must be completed.';
    } else {
      message = 'Program Base Application must be completed.';
    }

    VendorProgramEligibilityResult eligibilityResult = new VendorProgramEligibilityResult();
    eligibilityResult.eligibilityPassed = eligible;
    eligibilityResult.hasNda = eligibility.hasNda;
    eligibilityResult.hasProgramBase = eligibility.hasProgramBase;
    eligibilityResult.message = message;
    return eligibilityResult;
  }

  // Contacts + ACR roles
  @AuraEnabled(cacheable=true)
  public static List<ContactRoleDTO> getAccountContactsWithRoles(Id accountId) {
    ValidationHelper.requireId(accountId, 'Account ID');
    List<VendorOnboardingWizardRepository.ContactRoleInfo> infos = VendorOnboardingWizardRepository.getAccountContactsWithRoles(
      accountId
    );
    List<ContactRoleDTO> contactRoleDTOList = new List<ContactRoleDTO>();
    for (
      VendorOnboardingWizardRepository.ContactRoleInfo contactRoleInfo : infos
    ) {
      ContactRoleDTO contactRoleDTO = new ContactRoleDTO();
      contactRoleDTO.contactId = contactRoleInfo.contactId;
      contactRoleDTO.name = contactRoleInfo.name;
      contactRoleDTO.email = contactRoleInfo.email;
      contactRoleDTO.role = contactRoleInfo.role;
      contactRoleDTO.hasAcr = contactRoleInfo.hasAcr;
      contactRoleDTOList.add(contactRoleDTO);
    }
    return contactRoleDTOList;
  }

  @AuraEnabled
  public static Id upsertAccountContactRelation(
    Id accountId,
    Id contactId,
    String role
  ) {
    ValidationHelper.requireId(accountId, 'Account ID');
    ValidationHelper.requireId(contactId, 'Contact ID');
    if (String.isBlank(role)) {
      throw new AuraHandledException(
        'Role is required for Contact ' + String.valueOf(contactId)
      );
    }
    return VendorOnboardingWizardRepository.upsertAccountContactRelation(
      accountId,
      contactId,
      role
    );
  }

  public class ContactRoleDTO {
    @AuraEnabled
    public Id contactId;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String email;
    @AuraEnabled
    public String role;
    @AuraEnabled
    public Boolean hasAcr;
  }

  // Onboarding creation with requirements
  @AuraEnabled
  public static OnboardingWithRequirementsResult createOnboardingWithRequirements(
    Id accountId,
    Id vendorProgramId,
    Id opportunityId
  ) {
    ValidationHelper.requireId(accountId, 'Account ID');
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
    return VendorOnboardingWizardRepository.createOnboardingWithRequirements(
      accountId,
      vendorProgramId,
      opportunityId
    );
  }

  public class OnboardingWithRequirementsResult {
    @AuraEnabled
    public Id onboardingId;
    @AuraEnabled
    public Integer requirementCount;
  }

  public class VendorProgramEligibilityResult {
    @AuraEnabled
    public Boolean eligibilityPassed;
    @AuraEnabled
    public Boolean hasNda;
    @AuraEnabled
    public Boolean hasProgramBase;
    @AuraEnabled
    public String message;
  }

  // -------------------------------
  // Onboarding Opportunity + OCR + AVO
  // -------------------------------
  @AuraEnabled
  public static Id createOnboardingOpportunity(
    Id accountId,
    String name,
    String stageName,
    Date closeDate,
    Id recordTypeId
  ) {
    ValidationHelper.requireId(accountId, 'Account ID');
    if (String.isBlank(name)) {
      throw new AuraHandledException('Opportunity Name is required.');
    }
    Opportunity opp = new Opportunity(
      AccountId = accountId,
      Name = name,
      StageName = stageName,
      CloseDate = closeDate
    );
    if (recordTypeId != null) {
      opp.RecordTypeId = recordTypeId;
    }
    opp = DefaultValueHelper.applyOnboardingOpportunityDefaults(opp);
    insert opp;
    return opp.Id;
  }

  @AuraEnabled
  public static Id upsertOpportunityContactRole(
    Id opportunityId,
    Id contactId,
    String role,
    Boolean isPrimary
  ) {
    ValidationHelper.requireId(opportunityId, 'Opportunity ID');
    ValidationHelper.requireId(contactId, 'Contact ID');
    OpportunityContactRole ocr = new OpportunityContactRole(
      OpportunityId = opportunityId,
      ContactId = contactId,
      Role = role,
      IsPrimary = isPrimary == null ? false : isPrimary
    );
    insert ocr;
    return ocr.Id;
  }

  @AuraEnabled
  public static Id createAccountVendorProgramOnboarding(
    Id accountId,
    Id onboardingId,
    Id opportunityId,
    String status,
    Id primaryContactId
  ) {
    ValidationHelper.requireId(accountId, 'Account ID');
    ValidationHelper.requireId(onboardingId, 'Onboarding ID');
    Account_Vendor_Program_Onboarding__c avo = new Account_Vendor_Program_Onboarding__c(
      Account__c = accountId,
      Onboarding__c = onboardingId,
      Opportunity__c = opportunityId,
      Status__c = String.isNotBlank(status) ? status : 'Intake',
      Primary_Contact__c = primaryContactId
    );
    insert avo;
    return avo.Id;
  }

  public static List<Vendor_Customization__c> getRecentVendorPrograms(
    Integer limitCount
  ) {
    return VendorProgramService.getRecentVendorPrograms(limitCount);
  }

  public static Id createVendorProgram(
    Vendor_Customization__c vendorProgram,
    Id vendorId
  ) {
    return VendorProgramService.createVendorProgram(vendorProgram, vendorId);
  }

  // -------------------------------
  // Vendor Program Group - Delegates to VendorProgramGroupService
  // -------------------------------

  public static List<Vendor_Program_Group__c> searchVendorProgramGroups(
    String vendorProgramGroupName
  ) {
    return VendorProgramGroupService.searchVendorProgramGroups(
      vendorProgramGroupName
    );
  }

  public static List<Vendor_Program_Group__c> getAllVendorProgramGroups() {
    return VendorProgramGroupService.getAllVendorProgramGroups();
  }

  public static Id getVendorProgramGroupForVendorProgram(Id vendorProgramId) {
    return VendorProgramService.getVendorProgramGroupForVendorProgram(
      vendorProgramId
    );
  }

  public static Id getVendorProgramRequirementGroupForVendorProgram(
    Id vendorProgramId
  ) {
    return VendorProgramService.getVendorProgramRequirementGroupForVendorProgram(
      vendorProgramId
    );
  }

  public static Id createVendorProgramGroup(
    Vendor_Program_Group__c vendorProgramGroup
  ) {
    return VendorProgramGroupService.createVendorProgramGroup(
      vendorProgramGroup
    );
  }

  /**
   * Gets a default Logic_Type__c value for Vendor_Program_Group__c.
   * Tries to get the default picklist value, falls back to 'ALL'.
   */
  private static String getDefaultLogicType() {
    return VendorProgramGroupService.getDefaultLogicType();
  }

  // -------------------------------
  // Vendor Program Requirement Group - Delegates to VendorProgramRequirementGroupService
  // -------------------------------

  public static List<Vendor_Program_Requirement_Group__c> searchVendorProgramRequirementGroups(
    String requirementGroupName
  ) {
    return VendorProgramRequirementGroupService.searchVendorProgramRequirementGroups(
      requirementGroupName
    );
  }

  public static List<Vendor_Program_Requirement_Group__c> getAllVendorProgramRequirementGroups() {
    return VendorProgramRequirementGroupService.getAllVendorProgramRequirementGroups();
  }

  public static Id createVendorProgramRequirementGroup(
    Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup
  ) {
    return VendorProgramRequirementGroupService.createVendorProgramRequirementGroup(
      vendorProgramRequirementGroup
    );
  }

  public static void finalizeVendorProgram(
    Id vendorProgramId,
    Id vendorId,
    Id vendorProgramGroupId,
    Id vendorProgramRequirementGroupId
  ) {
    VendorProgramService.finalizeVendorProgram(
      vendorProgramId,
      vendorId,
      vendorProgramGroupId,
      vendorProgramRequirementGroupId
    );
  }

  // -------------------------------
  // Vendor Program Requirement - Delegates to VendorProgramRequirementService
  // -------------------------------

  public static List<Vendor_Program_Requirement__c> searchVendorProgramRequirements(
    String vendorProgramRequirements
  ) {
    return VendorProgramRequirementService.searchVendorProgramRequirements(
      vendorProgramRequirements
    );
  }

  public static Id createVendorProgramRequirement(
    Vendor_Program_Requirement__c vendorProgramRequirement
  ) {
    return VendorProgramRequirementService.createVendorProgramRequirement(
      vendorProgramRequirement
    );
  }

  public static BulkCreateRequirementsResult bulkCreateRequirementsFromTemplates(
    Id vendorProgramId,
    List<Id> templateIds,
    String defaultStatus,
    Boolean defaultIsRequired
  ) {
    VendorProgramRequirementService.BulkCreateRequirementsResult serviceResult = VendorProgramRequirementService.bulkCreateRequirementsFromTemplates(
      vendorProgramId,
      templateIds,
      defaultStatus,
      defaultIsRequired
    );

    // Convert service result to facade result for backward compatibility
    BulkCreateRequirementsResult bulkCreateRequirementsResult = new BulkCreateRequirementsResult();
    bulkCreateRequirementsResult.success = serviceResult.success;
    bulkCreateRequirementsResult.createdRequirementIds = serviceResult.createdRequirementIds;
    bulkCreateRequirementsResult.skippedTemplateIds = serviceResult.skippedTemplateIds;
    bulkCreateRequirementsResult.errorMessage = serviceResult.errorMessage;

    return bulkCreateRequirementsResult;
  }

  public static void updateRequirementSequences(
    List<Vendor_Program_Requirement__c> requirements
  ) {
    VendorProgramRequirementService.updateRequirementSequences(requirements);
  }

  /**
   * Result class for bulk create operations
   * Delegates to VendorProgramRequirementService.BulkCreateRequirementsResult
   */
  public class BulkCreateRequirementsResult {
    public Boolean success = false;
    public List<Id> createdRequirementIds = new List<Id>();
    public List<Id> skippedTemplateIds = new List<Id>();
    public String errorMessage;
  }

  public static List<Vendor_Program_Requirement__c> getRecentVendorProgramRequirements(
    Id vendorProgramId
  ) {
    return VendorProgramRequirementService.getRecentVendorProgramRequirements(
      vendorProgramId
    );
  }

  public static List<Vendor_Program_Requirement__c> getRequirementsByGroup(
    Id requirementGroupId
  ) {
    return VendorProgramRequirementService.getRequirementsByGroup(
      requirementGroupId
    );
  }

  public static List<Vendor_Program_Onboarding_Req_Template__c> getTemplatesByGroup(
    Id requirementGroupId
  ) {
    return OnboardingRequirementSetService.getTemplatesByGroup(
      requirementGroupId
    );
  }

  public static void deleteVendorProgramRequirement(Id requirementId) {
    VendorProgramRequirementService.deleteVendorProgramRequirement(
      requirementId
    );
  }

  // -------------------------------
  // Onboarding Status Rules Engine - Delegates to StatusRulesEngineService
  // -------------------------------

  public static List<Onboarding_Status_Rules_Engine__c> searchStatusRulesEngines(
    String onboardingStatusRulesEngine
  ) {
    return StatusRulesEngineService.searchStatusRulesEngines(
      onboardingStatusRulesEngine
    );
  }

  public static Id createOnboardingStatusRulesEngine(
    Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine
  ) {
    return StatusRulesEngineService.createOnboardingStatusRulesEngine(
      onboardingStatusRulesEngine
    );
  }

  public static Onboarding_Status_Rules_Engine__c getStatusRulesEngineById(
    Id engineId
  ) {
    return StatusRulesEngineService.getStatusRulesEngineById(engineId);
  }

  // -------------------------------
  // Onboarding Status Rules - Delegates to StatusRulesEngineService
  // -------------------------------

  public static Id createStatusRule(Onboarding_Status_Rule__c statusRuleRecord) {
    return StatusRulesEngineService.createStatusRule(statusRuleRecord);
  }

  public static List<Onboarding_Status_Rule__c> searchStatusRules(
    String nameSearchText
  ) {
    return StatusRulesEngineService.searchStatusRules(nameSearchText);
  }

  // -------------------------------
  // Communication Templates - Delegates to CommunicationTemplateService
  // -------------------------------

  public static List<Communication_Template__c> getCommunicationTemplates() {
    return CommunicationTemplateService.getCommunicationTemplates();
  }

  public static void linkCommunicationTemplateToVendorProgram(
    Id vendorProgramId,
    Id templateId
  ) {
    CommunicationTemplateService.linkCommunicationTemplateToVendorProgram(
      vendorProgramId,
      templateId
    );
  }

  // -------------------------------
  // Onboarding Requirement Set - Delegates to OnboardingRequirementSetService
  // -------------------------------

  public static Id createOnboardingRequirementSet(
    Onboarding_Requirement_Set__c requirementSet
  ) {
    return OnboardingRequirementSetService.createOnboardingRequirementSet(
      requirementSet
    );
  }

  public static List<Onboarding_Requirement_Set__c> getOnboardingRequirementSets() {
    return OnboardingRequirementSetService.getOnboardingRequirementSets();
  }

  public static List<Onboarding_Requirement_Set__c> searchOnboardingRequirementSets(
    String searchText,
    Id vendorProgramId
  ) {
    return OnboardingRequirementSetService.searchOnboardingRequirementSets(
      searchText,
      vendorProgramId
    );
  }

  /**
   * Gets all Requirement Sets with their associated Templates for hierarchical display.
   */
  public static List<Onboarding_Requirement_Set__c> getRequirementSetsWithTemplates() {
    return OnboardingRequirementSetService.getRequirementSetsWithTemplates();
  }

  /**
   * Gets Requirement Sets with Templates filtered by search text.
   */
  public static List<Onboarding_Requirement_Set__c> searchRequirementSetsWithTemplates(
    String searchText
  ) {
    return OnboardingRequirementSetService.searchRequirementSetsWithTemplates(
      searchText
    );
  }

  public static void linkRequirementSetToVendorProgram(
    Id requirementSetId,
    Id vendorProgramId
  ) {
    OnboardingRequirementSetService.linkRequirementSetToVendorProgram(
      requirementSetId,
      vendorProgramId
    );
  }

  public static Id createRequirementSetFromExisting(
    Id existingRequirementSetId,
    Id vendorProgramId
  ) {
    return OnboardingRequirementSetService.createRequirementSetFromExisting(
      existingRequirementSetId,
      vendorProgramId
    );
  }

  public static List<Vendor_Program_Onboarding_Req_Template__c> getTemplatesForRequirementSet(
    Id requirementSetId
  ) {
    return OnboardingRequirementSetService.getTemplatesForRequirementSet(
      requirementSetId
    );
  }

  public static Id createRequirementFromTemplate(
    Id templateId,
    Id vendorProgramId
  ) {
    return OnboardingRequirementSetService.createRequirementFromTemplate(
      templateId,
      vendorProgramId
    );
  }

  // -------------------------------
  // Requirement Group Linking (Step 5) - Delegates to OnboardingRequirementSetService
  // -------------------------------

  public static List<Vendor_Program_Group_Member__c> getHistoricalGroupMembers(
    Id requirementSetId
  ) {
    return OnboardingRequirementSetService.getHistoricalGroupMembers(
      requirementSetId
    );
  }

  public static List<Onboarding_Status_Rules_Engine__c> getHistoricalStatusRulesEngines(
    Id requirementSetId
  ) {
    return OnboardingRequirementSetService.getHistoricalStatusRulesEngines(
      requirementSetId
    );
  }

  public static Id createRequirementGroupComponents(
    Id vendorProgramId,
    Id requirementSetId,
    Boolean useHistorical
  ) {
    return OnboardingRequirementSetService.createRequirementGroupComponents(
      vendorProgramId,
      requirementSetId,
      useHistorical
    );
  }

  // -------------------------------
  // Onboarding Requirement Templates - Delegates to OnboardingRequirementSetService
  // -------------------------------

  public static Id createOnboardingRequirementTemplate(
    Vendor_Program_Onboarding_Req_Template__c template
  ) {
    // Delegate to service which handles junction linking
    // Note: Requirement sets must be linked via junction after template creation
    return OnboardingRequirementSetService.createOnboardingRequirementTemplate(
      template,
      new List<Id>()
    );
  }

  public static void updateOnboardingRequirementTemplate(
    Vendor_Program_Onboarding_Req_Template__c template
  ) {
    OnboardingRequirementSetService.updateOnboardingRequirementTemplate(
      template
    );
  }

  public static List<Map<String, Object>> getAvailableOnboardingStatusFields() {
    return OnboardingRequirementSetService.getAvailableOnboardingStatusFields();
  }

  public static List<Map<String, Object>> getAvailableOnboardingStatusFields(
    Id excludeTemplateId
  ) {
    return OnboardingRequirementSetService.getAvailableOnboardingStatusFields(
      excludeTemplateId
    );
  }

  public static List<Map<String, String>> getPicklistValuesForOnboardingField(
    String fieldApiName
  ) {
    return OnboardingRequirementSetService.getPicklistValuesForOnboardingField(
      fieldApiName
    );
  }

  public static List<Vendor_Program_Onboarding_Req_Template__c> getRequirementTemplatesForSet(
    Id requirementSetId
  ) {
    return OnboardingRequirementSetService.getRequirementTemplatesForSet(
      requirementSetId
    );
  }

  public static void updateRequirementTemplateGroupLinks(
    Id requirementGroupId,
    List<Id> templateIdsToLink,
    List<Id> templateIdsToUnlink
  ) {
    OnboardingRequirementSetService.updateRequirementTemplateGroupLinks(
      requirementGroupId,
      templateIdsToLink,
      templateIdsToUnlink
    );
  }

  /**
   * Gets a requirement set by ID for display when resuming/navigating back.
   */
  public static Onboarding_Requirement_Set__c getRequirementSetById(
    Id requirementSetId
  ) {
    return OnboardingRequirementSetService.getRequirementSetById(
      requirementSetId
    );
  }

  /**
   * Gets context data for resuming the onboarding flow.
   * Retrieves requirementSetId and other context from the vendor program.
   */
  public static Map<String, Object> getOnboardingContext(Id vendorProgramId) {
    return OnboardingRequirementSetService.getOnboardingContext(
      vendorProgramId
    );
  }

  public static void assignTemplatesToRequirementGroup(
    Id requirementGroupId,
    List<Id> templateIds
  ) {
    OnboardingRequirementSetService.assignTemplatesToRequirementGroup(
      requirementGroupId,
      templateIds
    );
  }

  // -------------------------------
  // Recipient Groups - Delegates to RecipientGroupService
  // -------------------------------

  public static List<Recipient_Group__c> searchRecipientGroups(
    String recipientGroupName
  ) {
    return RecipientGroupService.searchRecipientGroups(recipientGroupName);
  }

  public static Id createRecipientGroup(Recipient_Group__c recipientGroup) {
    return RecipientGroupService.createRecipientGroup(recipientGroup);
  }

  public static Id createRecipientGroupMember(
    Recipient_Group_Member__c recipientGroupMember
  ) {
    return RecipientGroupService.createRecipientGroupMember(
      recipientGroupMember
    );
  }

  // -------------------------------
  // Vendor Program Recipient Groups - Delegates to RecipientGroupService
  // -------------------------------

  public static List<Vendor_Program_Recipient_Group__c> searchVendorProgramRecipientGroups(
    String vprgName
  ) {
    return RecipientGroupService.searchVendorProgramRecipientGroups(vprgName);
  }

  public static Id createVendorProgramRecipientGroupLink(
    Id vendorProgramId,
    Id recipientGroupId
  ) {
    return RecipientGroupService.createVendorProgramRecipientGroupLink(
      vendorProgramId,
      recipientGroupId
    );
  }

  public static List<Vendor_Program_Recipient_Group__c> getRecipientGroupsForVendorProgram(
    Id vendorProgramId
  ) {
    return RecipientGroupService.getRecipientGroupsForVendorProgram(
      vendorProgramId
    );
  }

  public static List<Recipient_Group_Member__c> getRecipientGroupMembers(
    Id recipientGroupId
  ) {
    return RecipientGroupService.getRecipientGroupMembers(recipientGroupId);
  }

  public static Id createVendorProgramRecipientGroupWithTemplate(
    Id vendorProgramId,
    Id recipientGroupId,
    Id communicationTemplateId,
    String triggerCondition
  ) {
    return RecipientGroupService.createVendorProgramRecipientGroupWithTemplate(
      vendorProgramId,
      recipientGroupId,
      communicationTemplateId,
      triggerCondition
    );
  }

  // -------------------------------
  // Misc: Assignable Users, Roles, Groups
  // -------------------------------
  public static List<Territory_Role_Assignment__c> getTerritoryRoleAssignments() {
    return VendorOnboardingWizardRepository.getTerritoryRoleAssignments();
  }

  public static List<User> getAssignableUsers() {
    return VendorOnboardingWizardRepository.getAssignableUsers();
  }

  public static List<Group> getPublicGroups() {
    return VendorOnboardingWizardRepository.getPublicGroups();
  }

  // -------------------------------
  // Onboarding Component Library
  // -------------------------------

  public static void syncComponentLibrary() {
    List<String> components = new List<String>{
      'vendorProgramOnboardingVendor',
      'vendorProgramOnboardingVendorProgramSearchOrCreate',
      'vendorProgramOnboardingRequirementSetOrCreate',
      'vendorProgramOnboardingRequirementGroupLinking',
      'vendorProgramOnboardingRequiredCredentials',
      'vendorProgramOnboardingTrainingRequirements',
      'vendorProgramOnboardingStatusRulesEngine',
      'vendorProgramOnboardingRecipientGroup',
      'vendorProgramOnboardingCommunicationTemplate',
      'vendorProgramOnboardingFinalize'
    };

    VendorOnboardingWizardRepository.upsertOnboardingComponents(components);
  }

  // -------------------------------
  // Default Onboarding Process Setup
  // -------------------------------

  /**
   * Creates the default "Vendor Program Onboarding" process if it doesn't exist.
   * Also creates all 10 stages linked to the component library entries in the correct order.
   * This is an admin utility function to initialize the default onboarding flow.
   */
  public static Id initializeDefaultVendorProgramOnboardingProcess() {
    // Step 1: Check if process already exists
    List<Onboarding_Application_Process__c> existingProcesses = OnboardingApplicationRepository.fetchActiveProcessesByName(
      'Vendor Program Onboarding'
    );
    if (existingProcesses != null && !existingProcesses.isEmpty()) {
      return existingProcesses[0].Id;
    }

    // Step 2: Ensure component library is synced first
    syncComponentLibrary();

    // Step 3: Get component library entries
    Map<String, Id> componentLibraryMap = VendorOnboardingWizardRepository.getComponentLibraryByApiName();

    // Step 4: Create the process
    Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
      Name = 'Vendor Program Onboarding',
      Description__c = 'Default onboarding process for vendor programs. Includes the streamlined 10-step wizard.',
      Active__c = true
    );
    OnboardingApplicationRepository.insertProcess(process);

    // Step 5: Define stages in order with labels
    List<StageDefinition> stageDefinitions = new List<StageDefinition>{
      new StageDefinition(
        1,
        'Select Vendor',
        'vendorProgramOnboardingVendor',
        true
      ),
      new StageDefinition(
        2,
        'Search or Create Vendor Program',
        'vendorProgramOnboardingVendorProgramSearchOrCreate',
        true
      ),
      new StageDefinition(
        3,
        'Requirement Set or Create',
        'vendorProgramOnboardingRequirementSetOrCreate',
        true
      ),
      new StageDefinition(
        4,
        'Requirement Group Linking',
        'vendorProgramOnboardingRequirementGroupLinking',
        true
      ),
      new StageDefinition(
        5,
        'Required Credentials',
        'vendorProgramOnboardingRequiredCredentials',
        true
      ),
      new StageDefinition(
        6,
        'Training Requirements',
        'vendorProgramOnboardingTrainingRequirements',
        true
      ),
      new StageDefinition(
        7,
        'Status Rules Engine',
        'vendorProgramOnboardingStatusRulesEngine',
        true
      ),
      new StageDefinition(
        8,
        'Recipient Group',
        'vendorProgramOnboardingRecipientGroup',
        true
      ),
      new StageDefinition(
        9,
        'Communication Template',
        'vendorProgramOnboardingCommunicationTemplate',
        true
      ),
      new StageDefinition(
        10,
        'Finalize Vendor Program',
        'vendorProgramOnboardingFinalize',
        true
      )
    };

    // Step 6: Create stages
    List<Onboarding_Application_Stage__c> stages = new List<Onboarding_Application_Stage__c>();

    for (StageDefinition stageDef : stageDefinitions) {
      Id componentLibraryId = componentLibraryMap.get(
        stageDef.componentApiName
      );

      if (componentLibraryId == null) {
        System.debug(
          LoggingLevel.WARN,
          'Component library entry not found for: ' + stageDef.componentApiName
        );
        continue;
      }

      Onboarding_Application_Stage__c onboardingStage = new Onboarding_Application_Stage__c(
        Name = stageDef.label,
        Label__c = stageDef.label,
        Display_Order__c = stageDef.displayOrder,
        Onboarding_Application_Process__c = process.Id,
        Onboarding_Component_Library__c = componentLibraryId,
        Required__c = stageDef.required
        // Next_Stage__c will be set after insert
      );

      stages.add(onboardingStage);
    }

    // Step 7: Insert stages (first pass without Next_Stage links)
    OnboardingApplicationRepository.insertStages(stages);

    // Step 8: Update Next_Stage links (each stage points to the next one in sequence)
    // Stage at index stageIndex points to stage at index stageIndex+1
    for (Integer stageIndex = 0; stageIndex < stages.size() - 1; stageIndex++) {
      stages[stageIndex].Next_Stage__c = stages[stageIndex + 1].Id;
    }
    // Last stage (index stages.size()-1) has no next stage (remains null)

    OnboardingApplicationRepository.updateStages(stages);

    return process.Id;
  }

  /**
   * Inner class to define stage metadata
   */
  private class StageDefinition {
    Integer displayOrder;
    String label;
    String componentApiName;
    Boolean required;

    StageDefinition(
      Integer displayOrder,
      String label,
      String componentApiName,
      Boolean required
    ) {
      this.displayOrder = displayOrder;
      this.label = label;
      this.componentApiName = componentApiName;
      this.required = required;
    }
  }
}