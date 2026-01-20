/**
 * Sample Data Script: Seed Onboarding Process
 * 
 * This script creates a sample onboarding process with stages for testing and demos.
 * Run this in Developer Console (Execute Anonymous) or via Salesforce CLI.
 * 
 * Usage:
 * 1. Open Developer Console
 * 2. Go to Debug > Open Execute Anonymous Window
 * 3. Paste this script
 * 4. Check "Open Log" and click Execute
 * 
 * Or via CLI:
 * sf apex run --file scripts/sample-data/seed-onboarding-process.apex
 */

// Step 1: Create Component Library Entries
List<Onboarding_Component_Library__c> components = new List<Onboarding_Component_Library__c>{
    new Onboarding_Component_Library__c(
        Name = 'Vendor Selection',
        Component_API_Name__c = 'vendorProgramOnboardingVendor',
        Description__c = 'Component for selecting or creating a vendor account'
    ),
    new Onboarding_Component_Library__c(
        Name = 'Vendor Program Search or Create',
        Component_API_Name__c = 'vendorProgramOnboardingVendorProgramSearchOrCreate',
        Description__c = 'Component for searching or creating vendor programs'
    ),
    new Onboarding_Component_Library__c(
        Name = 'Vendor Program Create',
        Component_API_Name__c = 'vendorProgramOnboardingVendorProgramCreate',
        Description__c = 'Component for creating new vendor programs'
    ),
    new Onboarding_Component_Library__c(
        Name = 'Vendor Program Group',
        Component_API_Name__c = 'vendorProgramOnboardingVendorProgramGroup',
        Description__c = 'Component for configuring vendor program groups'
    ),
    new Onboarding_Component_Library__c(
        Name = 'Vendor Program Requirement Group',
        Component_API_Name__c = 'vendorProgramOnboardingVendorProgramRequirementGroup',
        Description__c = 'Component for configuring requirement groups'
    ),
    new Onboarding_Component_Library__c(
        Name = 'Vendor Program Recipient Group',
        Component_API_Name__c = 'vendorProgramOnboardingVendorProgramRecipientGroup',
        Description__c = 'Component for configuring recipient groups'
    ),
    new Onboarding_Component_Library__c(
        Name = 'Required Credentials',
        Component_API_Name__c = 'vendorProgramOnboardingRequiredCredentials',
        Description__c = 'Component for managing required credentials'
    ),
    new Onboarding_Component_Library__c(
        Name = 'Training Requirements',
        Component_API_Name__c = 'vendorProgramOnboardingTrainingRequirements',
        Description__c = 'Component for managing training requirements'
    )
};

insert components;
System.debug('Created ' + components.size() + ' component library entries');

// Step 2: Create Onboarding Process
Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
    Name = 'Standard Vendor Onboarding Process',
    Description__c = 'Standard onboarding process for vendor programs',
    Active__c = true
);
insert process;
System.debug('Created onboarding process: ' + process.Id);

// Step 3: Create Stages
List<Onboarding_Application_Stage__c> stages = new List<Onboarding_Application_Stage__c>{
    new Onboarding_Application_Stage__c(
        Onboarding_Application_Process__c = process.Id,
        Onboarding_Component_Library__c = components[0].Id,
        Display_Order__c = 1,
        Label__c = 'Vendor Selection',
        Required__c = true
    ),
    new Onboarding_Application_Stage__c(
        Onboarding_Application_Process__c = process.Id,
        Onboarding_Component_Library__c = components[1].Id,
        Display_Order__c = 2,
        Label__c = 'Program Setup',
        Required__c = true
    ),
    new Onboarding_Application_Stage__c(
        Onboarding_Application_Process__c = process.Id,
        Onboarding_Component_Library__c = components[3].Id,
        Display_Order__c = 3,
        Label__c = 'Program Groups',
        Required__c = true
    ),
    new Onboarding_Application_Stage__c(
        Onboarding_Application_Process__c = process.Id,
        Onboarding_Component_Library__c = components[4].Id,
        Display_Order__c = 4,
        Label__c = 'Requirement Groups',
        Required__c = true
    ),
    new Onboarding_Application_Stage__c(
        Onboarding_Application_Process__c = process.Id,
        Onboarding_Component_Library__c = components[5].Id,
        Display_Order__c = 5,
        Label__c = 'Recipient Groups',
        Required__c = false
    ),
    new Onboarding_Application_Stage__c(
        Onboarding_Application_Process__c = process.Id,
        Onboarding_Component_Library__c = components[6].Id,
        Display_Order__c = 6,
        Label__c = 'Required Credentials',
        Required__c = false
    ),
    new Onboarding_Application_Stage__c(
        Onboarding_Application_Process__c = process.Id,
        Onboarding_Component_Library__c = components[7].Id,
        Display_Order__c = 7,
        Label__c = 'Training Requirements',
        Required__c = false
    )
};

insert stages;
System.debug('Created ' + stages.size() + ' stages');

// Link stages sequentially (each stage's Next_Stage__c points to the next)
for (Integer i = 0; i < stages.size() - 1; i++) {
    stages[i].Next_Stage__c = stages[i + 1].Id;
}
update stages;

System.debug('✓ Onboarding process setup complete!');
System.debug('Process ID: ' + process.Id);
System.debug('Process Name: ' + process.Name);
System.debug('Number of Stages: ' + stages.size());

