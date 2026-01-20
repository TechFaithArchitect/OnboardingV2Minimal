/**
 * Sample Data Script: Seed Vendor Program
 * 
 * This script creates a sample vendor program with groups for testing and demos.
 * Run this in Developer Console (Execute Anonymous) or via Salesforce CLI.
 * 
 * Prerequisites:
 * - Account record must exist (or create one first)
 * - Vendor__c record type must exist
 * 
 * Usage:
 * 1. Open Developer Console
 * 2. Go to Debug > Open Execute Anonymous Window
 * 3. Paste this script
 * 4. Check "Open Log" and click Execute
 * 
 * Or via CLI:
 * sf apex run --file scripts/sample-data/seed-vendor-program.apex
 */

// Step 1: Get or Create Account
Account vendorAccount;
List<Account> existingAccounts = [
    SELECT Id, Name 
    FROM Account 
    WHERE Name = 'Sample Vendor Account' 
    LIMIT 1
];

if (existingAccounts.isEmpty()) {
    vendorAccount = new Account(
        Name = 'Sample Vendor Account',
        Type = 'Vendor'
    );
    insert vendorAccount;
    System.debug('Created account: ' + vendorAccount.Id);
} else {
    vendorAccount = existingAccounts[0];
    System.debug('Using existing account: ' + vendorAccount.Id);
}

// Step 2: Get or Create Vendor Record
Vendor__c vendor;
List<Vendor__c> existingVendors = [
    SELECT Id, Name 
    FROM Vendor__c 
    WHERE Name = 'Sample Vendor' 
    LIMIT 1
];

if (existingVendors.isEmpty()) {
    vendor = new Vendor__c(
        Name = 'Sample Vendor',
        Account__c = vendorAccount.Id
    );
    insert vendor;
    System.debug('Created vendor: ' + vendor.Id);
} else {
    vendor = existingVendors[0];
    System.debug('Using existing vendor: ' + vendor.Id);
}

// Step 3: Create Vendor Program Group
Vendor_Program_Group__c programGroup = new Vendor_Program_Group__c(
    Name = 'Sample Program Group',
    Label__c = 'Sample Program Group',
    Active__c = true,
    Logic_Type__c = 'AND'
);
insert programGroup;
System.debug('Created vendor program group: ' + programGroup.Id);

// Step 4: Create Vendor Program Requirement Group
Vendor_Program_Requirement_Group__c requirementGroup = new Vendor_Program_Requirement_Group__c(
    Name = 'Sample Requirement Group',
    Status__c = 'Active',
    Active__c = true
);
insert requirementGroup;
System.debug('Created requirement group: ' + requirementGroup.Id);

// Step 5: Create Vendor Customization (Vendor Program)
Vendor_Customization__c vendorProgram = new Vendor_Customization__c(
    Name = 'Sample Vendor Program',
    Vendor__c = vendor.Id,
    Vendor_Program_Group__c = programGroup.Id,
    Vendor_Program_Requirement_Group__c = requirementGroup.Id,
    Active__c = true
);
insert vendorProgram;
System.debug('Created vendor program: ' + vendorProgram.Id);

// Step 6: Create Vendor Program Group Member
Vendor_Program_Group_Member__c groupMember = new Vendor_Program_Group_Member__c(
    Name = 'Sample Group Member',
    Vendor_Program_Group__c = programGroup.Id,
    Required_Program__c = vendorProgram.Id,
    Is_Target__c = true,
    Active__c = true
);
insert groupMember;
System.debug('Created group member: ' + groupMember.Id);

// Step 7: Link to Onboarding Process (if process exists)
List<Onboarding_Application_Process__c> processes = [
    SELECT Id, Name 
    FROM Onboarding_Application_Process__c 
    WHERE Active__c = true 
    LIMIT 1
];

if (!processes.isEmpty()) {
    Onboarding_Application_Progress__c progress = new Onboarding_Application_Progress__c(
        Onboarding_Application_Process__c = processes[0].Id,
        Vendor_Program__c = vendorProgram.Id,
        Current_Stage__c = null
    );
    insert progress;
    System.debug('Linked vendor program to onboarding process: ' + processes[0].Name);
}

System.debug('✓ Vendor program setup complete!');
System.debug('Vendor Account ID: ' + vendorAccount.Id);
System.debug('Vendor ID: ' + vendor.Id);
System.debug('Vendor Program ID: ' + vendorProgram.Id);
System.debug('Program Group ID: ' + programGroup.Id);
System.debug('Requirement Group ID: ' + requirementGroup.Id);

