@isTest
public class TestDataFactory {

    // ------------------------------------------------------------------------------------------
    // GLOBAL CONFIG / LABELS
    // ------------------------------------------------------------------------------------------

    static String DirecTV = Label.DIRECTV;
    private static final String DEFAULT_TIMEZONE = 'America/New_York';

    // ------------------------------------------------------------------------------------------
    // ACCOUNT / CONTACT / COMMUNICATION
    // ------------------------------------------------------------------------------------------

    public static Account createAccount(String name, Boolean doInsert) {
        return TestAccountFactory.create(name, doInsert);
    }

    public static Contact createContact(String firstName, String lastName, Boolean doInsert, Account account) {
        return TestContactFactory.create(firstName, lastName, account, doInsert);
    }

    public static Recipient_Group__c createRecipientGroup(Boolean doInsert, Boolean isActive) {
        Recipient_Group__c recipientGroup = TestRecipientGroupFactory.create(false);
        recipientGroup.Is_Active__c = isActive;
        TestDataFactoryUtil.maybeInsert(recipientGroup, doInsert);
        return recipientGroup;
    }

    public static Recipient_Group_Member__c createRecipientGroupMember(Boolean doInsert, Recipient_Group__c recipientGroup, User user) {
        Recipient_Group_Member__c member = new Recipient_Group_Member__c(
            Recipient_Group__c = recipientGroup != null ? recipientGroup.Id : null,
            Member_Type__c = 'User',
            Recipient_Type__c = 'To',
            Recipient_User__c = user != null ? user.Id : null
        );
        TestDataFactoryUtil.maybeInsert(member, doInsert);
        return member;
    }

    public static Recipient_Group_Member__c createRecipientGroupMember(Boolean doInsert, Recipient_Group__c recipientGroup, User user, String memberType, String recipientType) {
        Recipient_Group_Member__c member = new Recipient_Group_Member__c(
            Recipient_Group__c = recipientGroup != null ? recipientGroup.Id : null,
            Member_Type__c = memberType,
            Recipient_Type__c = recipientType != null ? recipientType : 'To'
        );
        if (memberType == 'User') {
            member.Recipient_User__c = user != null ? user.Id : null;
        } else if (memberType == 'Group') {
            // OwnerId would be set separately for Group type
        }
        TestDataFactoryUtil.maybeInsert(member, doInsert);
        return member;
    }

    public static Communication_Template__c createCommTemplate(Boolean doInsert) {
        return TestCommTemplateFactory.createTemplate(doInsert);
    }

    public static Communication_Template__c createCommunicationTemplate(Boolean isActive, Boolean doInsert) {
        Communication_Template__c template = TestCommTemplateFactory.createTemplate(false);
        template.Active__c = isActive;
        TestDataFactoryUtil.maybeInsert(template, doInsert);
        return template;
    }

    // ------------------------------------------------------------------------------------------
    // PRODUCT
    // ------------------------------------------------------------------------------------------

    public static Product2 createProduct(Boolean doInsert, Boolean isSerialized, String productName) {
        return TestProductFactory.create(doInsert, isSerialized, productName).product;
    }

    // ------------------------------------------------------------------------------------------
    // FIELD SERVICE / TERRITORY / OPERATING HOURS / WORK / RESOURCES
    // ------------------------------------------------------------------------------------------

    public static OperatingHours createOperatingHours(String name, Boolean doInsert) {
        return TestWorkFactory.createOperatingHours(name, doInsert);
    }

    public static WorkOrder createWorkOrder(User usr, WorkType wt, Boolean doInsert) {
        return TestWorkFactory.createWorkOrder(usr, wt, doInsert);
    }

    public static WorkType createWorkType(String name, Boolean doInsert) {
        return TestWorkFactory.createWorkType(name, doInsert);
    }

    public static ServiceResource createServiceResource(Boolean doInsert, Account acc, Contact con, User usr) {
        return TestServiceResourceFactory.create(doInsert, acc, con, usr).serviceResource;
    }

    public static ServiceTerritory createParentServiceTerritory(Boolean doInsert, String name, OperatingHours opHrs) {
        return TestServiceResourceFactory.createParentTerritory(doInsert, name, opHrs);
    }

    public static ServiceTerritory createServiceTerritoryForAccount(Boolean doInsert, Account acc, ServiceTerritory parent) {
        return TestServiceResourceFactory.createChildTerritory(doInsert, acc, parent);
    }

    public static ServiceTerritoryMember createServiceTerritoryMember(Boolean doInsert, ServiceResource sr, ServiceTerritory st, String type) {
        return TestServiceResourceFactory.createTerritoryMember(doInsert, sr, st, type);
    }

    public static TestDataFactoryWrapper.TerritorySetupWrapper createTerritorySetup(Boolean doInsert) {
        return TestTerritoryFactory.createSetup(doInsert);
    }

    // ------------------------------------------------------------------------------------------
    // USERS / PERMISSIONS
    // ------------------------------------------------------------------------------------------

    public static User createStandardUser(Boolean doInsert) {
        return TestUserFactory.createStandardUser(doInsert);
    }

    public static User createTechnicianUser(Boolean doInsert, Contact con) {
        return TestUserFactory.createTechnicianUser(doInsert, con);
    }

    public static TestDataFactoryWrapper.TechnicianUserWrapper createTechnicianUserWithSetup(Boolean doInsert) {
        return TestTechnicianFactory.create(doInsert);
    }

    public static PermissionSetAssignment assignPermissionSetGroupToUser(Boolean doInsert, User user, String groupName) {
        return TestPermissionFactory.assignPermissionSetGroupToUser(user, groupName, doInsert);
    }

    public static TestDataFactoryWrapper.PermissionedUserWrapper createUserWithGroup(String groupName, Boolean doInsert) {
        User user = createStandardUser(doInsert);
        return TestPermissionFactory.assignGroupAndReturnWrapper(user, groupName, doInsert);
    }

    public static Territory_Assignments__c createTerritoryAssignmentWithUser(User user, String userFieldApiName, Boolean doInsert) {
        Territory_Assignments__c territoryAssignment = new Territory_Assignments__c(
            Division__c = 'Infra',
            Region__c = 'PNW',
            Territory__c = 'PORTLAND'
        );
        territoryAssignment.put(userFieldApiName, user.Id);
        TestDataFactoryUtil.maybeInsert(territoryAssignment, doInsert);
        return territoryAssignment;
    }

    // ------------------------------------------------------------------------------------------
    // WRAPPER-BASED BUILDERS
    // ------------------------------------------------------------------------------------------

    public static TestDataFactoryWrapper.WorkOrderSetupWrapper createWorkOrderSetup(Boolean doInsert) {
        return TestWorkOrderFactory.createWithTechnician(doInsert);
    }

    // ------------------------------------------------------------------------------------------
    // ONBOARDING
    // ------------------------------------------------------------------------------------------
    public static Onboarding__c createOnboarding(Account account, Vendor_Customization__c vendorProgram, Boolean doInsert) {
        return TestOnboardingFactory.create(account, vendorProgram, doInsert);
    }

    public static Onboarding_Application_Process__c createOnboardingApplicationProcessWithStages(Integer numStages, Boolean doInsert) {
        return TestOnboardingStageDependencyFactory.createProcessWithStages(numStages, doInsert);
    }

    public static Onboarding_Application_Stage_Dependency__c createOnboardingStageDependency(
        Id targetStageId,
        Id requiredStageId,
        Boolean required,
        Boolean doInsert
    ) {
        return TestOnboardingStageDependencyFactory.createStageDependency(
            doInsert,
            targetStageId,
            requiredStageId,
            required
        );
    }

    public static Onboarding_Application_Stage_Dependency__c createOnboardingStageDependency(
        Id targetStageId,
        List<Id> requiredStageIds,
        String logicType,
        Boolean required,
        Boolean doInsert
    ) {
        return TestOnboardingStageDependencyFactory.createStageDependency(
            doInsert,
            targetStageId,
            requiredStageIds,
            logicType,
            required
        );
    }

    public static Onboarding_Application_Stage_Completion__c createOnboardingStageCompletion(
        Id vendorProgramId,
        Id processId,
        Id stageId,
        Boolean doInsert
    ) {
        return TestOnboardingStageDependencyFactory.createStageCompletion(doInsert, vendorProgramId, processId, stageId);
    }

    // ------------------------------------------------------------------------------------------
    // VENDOR / VENDOR PROGRAM
    // ------------------------------------------------------------------------------------------
    public static Vendor__c createVendor(Boolean doInsert) {
        return TestVendorFactory.createVendor(doInsert);
    }

    public static Vendor_Customization__c createVendorCustomization(
        Vendor__c vendor, String status, Boolean isActive, Id parentVersionId, Boolean doInsert
    ) {
        return TestVendorProgramFactory.createVendorCustomization(vendor, status, isActive, parentVersionId, doInsert);
    }

    public static Vendor_Customization__c createRootAndActiveChildCustomization(Vendor__c vendor, Boolean doInsert) {
        return TestVendorProgramFactory.createRootAndActiveChildCustomization(vendor, doInsert);
    }

    public static Required_Credential__c createRequiredCredential(Vendor_Customization__c vendorProgram, Boolean doInsert) {
        return TestRequiredCredentialFactory.create(doInsert, vendorProgram);
    }

    public static Training_System__c createTrainingSystem(Boolean doInsert) {
        return TestTrainingSystemFactory.create(doInsert);
    }

    public static Training_Requirement__c createTrainingRequirement(Vendor_Customization__c vendorProgram, Training_System__c trainingSystem, Boolean doInsert) {
        return TestTrainingRequirementFactory.create(doInsert, vendorProgram, trainingSystem);
    }

    public static Vendor_Program_Requirement__c createVendorProgramRequirement(Vendor_Customization__c vendorProgram, Boolean isActive, Boolean doInsert) {
        return TestVendorProgramRequirementFactory.create(vendorProgram, isActive, doInsert);
    }


    // ------------------------------------------------------------------------------------------
    // EMAIL TESTING / COMMUNICATION CONTEXT (IN PROGRESS TO CLEAN UP)
    // ------------------------------------------------------------------------------------------

    public static OrgWideEmailDTO createOrgWideEmailDTO(String devName) {
        return TestDataFactoryWrapper.createOrgWideEmailDTO(devName).dto;
    }

    // ------------------------------------------------------------------------------------------
    // WRAPPER METHODS (delegating to TestDataFactoryWrapper)
    // ------------------------------------------------------------------------------------------
    public static TestDataFactoryWrapper.AccountContactWrapper createAccountContact(Boolean doInsert) {
        return TestDataFactoryWrapper.createAccountContact(doInsert);
    }

    public static TestDataFactoryWrapper.VendorCustomizationWrapper createDraftVendorCustomizationWrapper(Boolean doInsert) {
        return TestDataFactoryWrapper.createDraftVendorCustomizationWrapper(doInsert);
    }

    public static TestDataFactoryWrapper.ECCTestWrapper createECCTestWrapper(Boolean doInsert) {
        return TestDataFactoryWrapper.createECCScenario(doInsert);
    }

    // ------------------------------------------------------------------------------------------
    // ONBOARDING RULES BUILDERS
    // ------------------------------------------------------------------------------------------
    public static TestDataFactoryWrapper.OnboardingRulesSetupWrapper createAllOnboardingRule(
        Onboarding__c onboarding,
        Integer ruleCount,
        String expectedStatus,
        Boolean createRequirements,
        Boolean doInsert
    ) {
        return TestDataFactoryWrapper.createAllOnboardingRule(onboarding, ruleCount, expectedStatus, createRequirements, doInsert);
    }

    public static TestDataFactoryWrapper.OnboardingRulesSetupWrapper createAnyOnboardingRule(
        Onboarding__c onboarding,
        Integer ruleCount,
        String targetStatus,
        Boolean createRequirements,
        Boolean doInsert
    ) {
        return TestDataFactoryWrapper.createAnyOnboardingRule(onboarding, ruleCount, targetStatus, createRequirements, doInsert);
    }

    public static TestDataFactoryWrapper.OnboardingRulesSetupWrapper createCustomOnboardingRule(
        Onboarding__c onboarding,
        List<String> expectedStatuses,
        String customLogic,
        String targetStatus,
        Boolean overrideStatus,
        Boolean createRequirements,
        Integer ruleCount
    ) {
        return TestDataFactoryWrapper.createCustomOnboardingRule(
            onboarding, expectedStatuses, customLogic, targetStatus, overrideStatus, createRequirements, ruleCount
        );
    }

    public static Vendor_Program_Requirement_Group__c createVendorProgramRequirementGroup(String name, Boolean doInsert) {
        return TestVendorProgramRequirementGroupFactory.create(doInsert, name);
    }

    public static Onboarding_Status_Rule__c createOnboardingStatusRule(Boolean doInsert) {
        // Create a parent rule engine first since Parent_Rule__c may be required
        Onboarding_Status_Rules_Engine__c parentEngine = TestOnboardingRulesEngineFactory.create(doInsert);
        Vendor_Program_Requirement__c requirement = TestVendorProgramRequirementFactory.create(doInsert);
        
        Onboarding_Status_Rule__c onboardingStatusRule = TestOnboardingRulesFactory.create(
            false,
            parentEngine,
            requirement,
            'New',
            1
        );
        onboardingStatusRule.Active__c = true;
        TestDataFactoryUtil.maybeInsert(onboardingStatusRule, doInsert);
        return onboardingStatusRule;
    }

    public static Vendor_Program_Onboarding_Req_Template__c createOnboardingRequirementTemplate(
        Id requirementSetId,
        Boolean doInsert
    ) {
        Onboarding_Requirement_Set__c requirementSet = requirementSetId != null 
            ? new Onboarding_Requirement_Set__c(Id = requirementSetId) 
            : null;
        Vendor_Program_Onboarding_Req_Template__c vendorProgramRequirementTemplate = 
            TestVdrPrgrmOnboardingReqTemplateFactory.create(false, requirementSet, null);
        // Use valid picklist value instead of hardcoded 'Credential'
        String validRequirementType = TestDataFactoryUtil.getFirstPicklistValue(
            Vendor_Program_Onboarding_Req_Template__c.SObjectType,
            'Requirement_Type__c'
        );
        vendorProgramRequirementTemplate.Requirement_Type__c = validRequirementType != null ? validRequirementType : 'Document';
        vendorProgramRequirementTemplate.Status__c = 'Draft';
        vendorProgramRequirementTemplate.Active__c = true;
        TestDataFactoryUtil.maybeInsert(vendorProgramRequirementTemplate, doInsert);
        if (doInsert && requirementSetId != null && vendorProgramRequirementTemplate.Id != null) {
            Requirement_Set_Template__c junction = new Requirement_Set_Template__c(
                Requirement_Template__c = vendorProgramRequirementTemplate.Id,
                Onboarding_Requirement_Set__c = requirementSetId
            );
            insert junction;
        }
        return vendorProgramRequirementTemplate;
    }

    public static Vendor_Program_Group__c createVendorProgramGroup(Boolean doInsert) {
        return TestDataFactoryWrapper.createVendorProgramGroup(doInsert);
    }

    // ------------------------------------------------------------------------------------------
    // ACCOUNT VENDOR PROGRAM ONBOARDING (AVO)
    // ------------------------------------------------------------------------------------------
    public static Account_Vendor_Program_Onboarding__c createAccountVendorProgramOnboarding(
        Account account,
        Onboarding__c onboarding,
        String status,
        Boolean doInsert
    ) {
        return TestAVOFactory.create(account, onboarding, status, doInsert);
    }

    public static Account_Vendor_Program_Onboarding__c createAccountVendorProgramOnboarding(
        Account account,
        Onboarding__c onboarding,
        Boolean doInsert
    ) {
        return TestAVOFactory.create(account, onboarding, null, doInsert);
    }

    // ------------------------------------------------------------------------------------------
    // REQUIREMENT FIELD VALUE
    // ------------------------------------------------------------------------------------------
    public static Requirement_Field_Value__c createRequirementFieldValue(
        Requirement_Field__c requirementField,
        Onboarding_Requirement__c onboardingRequirement,
        String value,
        String validationStatus,
        Boolean doInsert
    ) {
        return TestRequirementFieldValueFactory.create(requirementField, onboardingRequirement, value, validationStatus, doInsert);
    }

    public static Requirement_Field_Value__c createRequirementFieldValue(
        Requirement_Field__c requirementField,
        Onboarding_Requirement__c onboardingRequirement,
        Boolean doInsert
    ) {
        return TestRequirementFieldValueFactory.create(requirementField, onboardingRequirement, doInsert);
    }

    public static Requirement_Field_Value__c createRequirementFieldValue(
        Requirement_Field__c requirementField,
        Onboarding_Requirement__c onboardingRequirement,
        String value,
        Boolean doInsert
    ) {
        return TestRequirementFieldValueFactory.create(requirementField, onboardingRequirement, value, doInsert);
    }

    // ------------------------------------------------------------------------------------------
    // REQUIREMENT FIELD
    // ------------------------------------------------------------------------------------------
    public static Requirement_Field__c createRequirementField(
        String fieldApiName,
        String validationType,
        Boolean required,
        Boolean doInsert
    ) {
        return TestRequirementFieldFactory.create(fieldApiName, validationType, required, doInsert);
    }

    public static Requirement_Field__c createRequirementField(
        String fieldApiName,
        Boolean doInsert
    ) {
        return TestRequirementFieldFactory.create(fieldApiName, doInsert);
    }

    // ------------------------------------------------------------------------------------------
    // VENDOR PROGRAM RECIPIENT GROUP
    // ------------------------------------------------------------------------------------------
    public static Vendor_Program_Recipient_Group__c createVendorProgramRecipientGroup(
        Vendor_Customization__c vendorProgram,
        Recipient_Group__c recipientGroup,
        Boolean doInsert
    ) {
        return TestVendorProgramRecipientGroupFactory.create(vendorProgram, recipientGroup, doInsert);
    }

    public static Vendor_Program_Recipient_Group__c createVendorProgramRecipientGroup(Boolean doInsert) {
        return TestVendorProgramRecipientGroupFactory.create(doInsert);
    }

    public static Vendor_Program_Recipient_Group__c createVendorProgramRecipientGroup(
        Vendor_Customization__c vendorProgram,
        Recipient_Group__c recipientGroup,
        String status,
        String version,
        Boolean isActive,
        Id parentVersionId,
        Boolean doInsert
    ) {
        return TestVendorProgramRecipientGroupFactory.create(
            vendorProgram,
            recipientGroup,
            status,
            version,
            isActive,
            parentVersionId,
            doInsert
        );
    }
}