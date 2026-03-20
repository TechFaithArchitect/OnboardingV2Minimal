/**
 * End-to-end simulation: Account -> Opportunity -> Onboarding -> Requirements
 *
 * Usage:
 * sf apex run --target-org <org-alias> --file scripts/simulation/account-onboarding-through-opportunity.apex
 *
 * Behavior:
 * 1) Creates isolated simulation data (Account, Vendor, Vendor Program, Vendor Program Requirement)
 * 2) Executes DOMAIN_OmniSObject_SFL_CREATE_Opportunity
 * 3) Executes DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record
 * 4) Verifies Onboarding and Onboarding_Requirement__c records were created
 * 5) Emits SIMULATION_RESULT_JSON in debug output
 *
 * The script throws assertions when a critical step fails.
 */

String runKey = 'SIM-' + DateTime.now().formatGmt('yyyyMMddHHmmssSSS');
System.debug(LoggingLevel.ERROR, 'SIMULATION_START=' + runKey);

// Pick a valid Opportunity stage.
String opportunityStage = null;
for (Schema.PicklistEntry entry : Opportunity.StageName.getDescribe().getPicklistValues()) {
    if (entry.isActive() && entry.getValue() == 'Prospecting') {
        opportunityStage = entry.getValue();
        break;
    }
}
if (String.isBlank(opportunityStage)) {
    for (Schema.PicklistEntry entry : Opportunity.StageName.getDescribe().getPicklistValues()) {
        if (entry.isActive()) {
            opportunityStage = entry.getValue();
            break;
        }
    }
}
System.assert(String.isNotBlank(opportunityStage), 'Simulation failed: no active Opportunity StageName found.');

// Pick a usable Vendor Program status.
String vendorProgramStatus = null;
for (Schema.PicklistEntry entry : Vendor_Customization__c.Status__c.getDescribe().getPicklistValues()) {
    if (!entry.isActive()) {
        continue;
    }
    String normalized = entry.getValue() == null ? '' : entry.getValue().trim().toUpperCase();
    if (normalized == 'ACTIVE' || (normalized.contains('ACTIVE') && !normalized.contains('INACTIVE'))) {
        vendorProgramStatus = entry.getValue();
        break;
    }
}
if (String.isBlank(vendorProgramStatus)) {
    for (Schema.PicklistEntry entry : Vendor_Customization__c.Status__c.getDescribe().getPicklistValues()) {
        if (entry.isActive()) {
            vendorProgramStatus = entry.getValue();
            break;
        }
    }
}
System.assert(String.isNotBlank(vendorProgramStatus), 'Simulation failed: no active Vendor_Customization__c.Status__c value found.');

// Pick a requirement type that maps cleanly in DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements.
String requirementType = null;
for (Schema.PicklistEntry entry : Vendor_Program_Requirement__c.Requirement_Type__c.getDescribe().getPicklistValues()) {
    if (entry.isActive() && entry.getValue() == 'Agreement') {
        requirementType = entry.getValue();
        break;
    }
}
if (String.isBlank(requirementType)) {
    for (Schema.PicklistEntry entry : Vendor_Program_Requirement__c.Requirement_Type__c.getDescribe().getPicklistValues()) {
        if (entry.isActive()) {
            requirementType = entry.getValue();
            break;
        }
    }
}
System.assert(String.isNotBlank(requirementType), 'Simulation failed: no active Requirement_Type__c value found.');

// Optional picklist values used by existing screen/flow paths.
String businessVertical = null;
for (Schema.PicklistEntry entry : Vendor_Customization__c.Business_Vertical__c.getDescribe().getPicklistValues()) {
    if (entry.isActive()) {
        businessVertical = entry.getValue();
        break;
    }
}

String retailOption = null;
for (Schema.PicklistEntry entry : Vendor_Customization__c.Retail_Option__c.getDescribe().getPicklistValues()) {
    if (entry.isActive()) {
        retailOption = entry.getValue();
        break;
    }
}

String programBaseSelection = null;
for (Schema.PicklistEntry entry : Opportunity.Program_Base_App_Selection__c.getDescribe().getPicklistValues()) {
    if (entry.isActive() && entry.getValue() == 'Not Applicable') {
        programBaseSelection = entry.getValue();
        break;
    }
}
if (String.isBlank(programBaseSelection)) {
    for (Schema.PicklistEntry entry : Opportunity.Program_Base_App_Selection__c.getDescribe().getPicklistValues()) {
        if (entry.isActive()) {
            programBaseSelection = entry.getValue();
            break;
        }
    }
}

String programType = null;
for (Schema.PicklistEntry entry : Opportunity.Program_Type__c.getDescribe().getPicklistValues()) {
    if (entry.isActive()) {
        programType = entry.getValue();
        break;
    }
}

// Step 1: Create simulation data.
Account simulationAccount = new Account(
    Name = 'Simulation Account ' + runKey,
    Available_FSL_Vendors__c = Label.DIRECTV
);
insert simulationAccount;

Vendor__c simulationVendor = new Vendor__c(
    Name = 'Simulation Vendor ' + runKey,
    Active__c = true
);
insert simulationVendor;

Vendor_Customization__c simulationVendorProgram = new Vendor_Customization__c(
    Name = 'Simulation Vendor Program ' + runKey,
    Vendor__c = simulationVendor.Id,
    Active__c = true,
    Status__c = vendorProgramStatus,
    Retail_Option__c = retailOption,
    Business_Vertical__c = businessVertical
);
insert simulationVendorProgram;

Vendor_Program_Requirement__c simulationRequirement = new Vendor_Program_Requirement__c(
    Vendor_Program__c = simulationVendorProgram.Id,
    Is_Required__c = true,
    Active__c = true,
    Sequence__c = 1,
    Requirement_Type__c = requirementType
);
insert simulationRequirement;

// Step 2: Run DOMAIN_OmniSObject_SFL_CREATE_Opportunity.
Opportunity opportunityInput = new Opportunity(
    AccountId = simulationAccount.Id,
    StageName = opportunityStage,
    CloseDate = Date.today().addDays(14),
    Vendor_Customization__c = simulationVendorProgram.Id,
    Program_Base_App_Selection__c = programBaseSelection,
    Program_Type__c = programType
);

Map<String, Object> opportunityFlowInputs = new Map<String, Object>{
    'AccountRecord' => new Account(Id = simulationAccount.Id),
    'OpportunityRecord' => opportunityInput,
    'VendorProgramRecord' => new Vendor_Customization__c(
        Id = simulationVendorProgram.Id,
        Vendor__c = simulationVendor.Id,
        Name = simulationVendorProgram.Name
    )
};

Flow.Interview opportunityInterview = Flow.Interview.createInterview(
    'DOMAIN_OmniSObject_SFL_CREATE_Opportunity',
    opportunityFlowInputs
);
opportunityInterview.start();

String opportunityFlowError = String.valueOf(opportunityInterview.getVariableValue('errorMessage'));
if (opportunityFlowError == 'null') {
    opportunityFlowError = null;
}
System.assert(String.isBlank(opportunityFlowError), 'Simulation failed in opportunity flow: ' + opportunityFlowError);

Opportunity createdOpportunity = (Opportunity) opportunityInterview.getVariableValue('OpportunityRecord');
Id createdOpportunityId = createdOpportunity == null ? null : createdOpportunity.Id;
if (createdOpportunityId == null) {
    List<Opportunity> fallbackOpportunities = [
        SELECT Id
        FROM Opportunity
        WHERE AccountId = :simulationAccount.Id
          AND Vendor_Customization__c = :simulationVendorProgram.Id
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    if (!fallbackOpportunities.isEmpty()) {
        createdOpportunityId = fallbackOpportunities[0].Id;
    }
}
System.assert(createdOpportunityId != null, 'Simulation failed: Opportunity was not created.');

// Step 3: Run DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record.
Map<String, Object> onboardingFlowInputs = new Map<String, Object>{
    'OpportunityRecord' => new Opportunity(
        Id = createdOpportunityId,
        AccountId = simulationAccount.Id
    ),
    'VendorProgramRecord' => new Vendor_Customization__c(
        Id = simulationVendorProgram.Id,
        Vendor__c = simulationVendor.Id
    )
};

Flow.Interview onboardingInterview = Flow.Interview.createInterview(
    'DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record',
    onboardingFlowInputs
);
onboardingInterview.start();

String onboardingFlowError = String.valueOf(onboardingInterview.getVariableValue('errorMessage'));
if (onboardingFlowError == 'null') {
    onboardingFlowError = null;
}
System.assert(String.isBlank(onboardingFlowError), 'Simulation failed in onboarding flow: ' + onboardingFlowError);

Onboarding__c createdOnboarding = (Onboarding__c) onboardingInterview.getVariableValue('OnboardingRecord');
Id createdOnboardingId = createdOnboarding == null ? null : createdOnboarding.Id;
if (createdOnboardingId == null) {
    List<Onboarding__c> fallbackOnboardings = [
        SELECT Id
        FROM Onboarding__c
        WHERE Opportunity__c = :createdOpportunityId
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    if (!fallbackOnboardings.isEmpty()) {
        createdOnboardingId = fallbackOnboardings[0].Id;
    }
}
System.assert(createdOnboardingId != null, 'Simulation failed: Onboarding record was not created.');

// Step 4: Verify seeded requirement + subject creation.
Onboarding__c onboardingSnapshot = [
    SELECT Id,
           Account__c,
           Vendor_Customization__c,
           Opportunity__c,
           Onboarding_Status__c,
           Creation_of_Record_Completed__c
    FROM Onboarding__c
    WHERE Id = :createdOnboardingId
    LIMIT 1
];

System.assertEquals(simulationAccount.Id, onboardingSnapshot.Account__c, 'Onboarding account link mismatch.');
System.assertEquals(simulationVendorProgram.Id, onboardingSnapshot.Vendor_Customization__c, 'Onboarding vendor program link mismatch.');
System.assertEquals(createdOpportunityId, onboardingSnapshot.Opportunity__c, 'Onboarding opportunity link mismatch.');
System.assertEquals(true, onboardingSnapshot.Creation_of_Record_Completed__c, 'Onboarding requirement/subject creation did not complete.');

List<Onboarding_Requirement__c> onboardingRequirements = [
    SELECT Id,
           Vendor_Program_Requirement__c,
           Requirement_Type__c,
           Status__c
    FROM Onboarding_Requirement__c
    WHERE Onboarding__c = :createdOnboardingId
    ORDER BY CreatedDate ASC
];
System.assert(!onboardingRequirements.isEmpty(), 'Simulation failed: no Onboarding_Requirement__c records were created.');

Boolean matchedSeededRequirement = false;
Set<Id> onboardingRequirementIds = new Set<Id>();
for (Onboarding_Requirement__c requirementRecord : onboardingRequirements) {
    onboardingRequirementIds.add(requirementRecord.Id);
    if (requirementRecord.Vendor_Program_Requirement__c == simulationRequirement.Id) {
        matchedSeededRequirement = true;
    }
}
System.assertEquals(true, matchedSeededRequirement, 'Simulation failed: seeded Vendor_Program_Requirement__c was not propagated.');

Integer subjectCount = 0;
if (!onboardingRequirementIds.isEmpty()) {
    subjectCount = [
        SELECT COUNT()
        FROM Onboarding_Requirement_Subject__c
        WHERE Onboarding_Requirement__c IN :onboardingRequirementIds
    ];
}

Map<String, Object> simulationResult = new Map<String, Object>{
    'runKey' => runKey,
    'accountId' => simulationAccount.Id,
    'vendorId' => simulationVendor.Id,
    'vendorProgramId' => simulationVendorProgram.Id,
    'vendorProgramRequirementId' => simulationRequirement.Id,
    'opportunityId' => createdOpportunityId,
    'onboardingId' => createdOnboardingId,
    'onboardingStatus' => onboardingSnapshot.Onboarding_Status__c,
    'creationCompleted' => onboardingSnapshot.Creation_of_Record_Completed__c,
    'onboardingRequirementCount' => onboardingRequirements.size(),
    'onboardingRequirementSubjectCount' => subjectCount
};

System.debug(LoggingLevel.ERROR, 'SIMULATION_RESULT_JSON=' + JSON.serialize(simulationResult));
System.debug(LoggingLevel.ERROR, 'SIMULATION_COMPLETE=' + runKey);
