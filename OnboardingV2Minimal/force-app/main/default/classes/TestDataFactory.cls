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

}
