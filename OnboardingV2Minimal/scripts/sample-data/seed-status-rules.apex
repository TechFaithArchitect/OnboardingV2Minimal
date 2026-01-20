/**
 * Sample Data Script: Seed Status Rules
 * 
 * This script creates sample status rules for testing and demos.
 * Run this in Developer Console (Execute Anonymous) or via Salesforce CLI.
 * 
 * Prerequisites:
 * - Vendor Program Group must exist
 * - Vendor Program Requirement Group must exist
 * - Vendor Program Requirements must exist (or create them first)
 * 
 * Usage:
 * 1. Open Developer Console
 * 2. Go to Debug > Open Execute Anonymous Window
 * 3. Paste this script
 * 4. Check "Open Log" and click Execute
 * 
 * Or via CLI:
 * sf apex run --file scripts/sample-data/seed-status-rules.apex
 */

// Step 1: Get Vendor Program Group (or create if doesn't exist)
Vendor_Program_Group__c programGroup;
List<Vendor_Program_Group__c> existingGroups = [
    SELECT Id, Name 
    FROM Vendor_Program_Group__c 
    WHERE Name = 'Sample Program Group' 
    LIMIT 1
];

if (existingGroups.isEmpty()) {
    programGroup = new Vendor_Program_Group__c(
        Name = 'Sample Program Group',
        Label__c = 'Sample Program Group',
        Active__c = true,
        Logic_Type__c = 'AND'
    );
    insert programGroup;
    System.debug('Created vendor program group: ' + programGroup.Id);
} else {
    programGroup = existingGroups[0];
    System.debug('Using existing program group: ' + programGroup.Id);
}

// Step 2: Get Requirement Group (or create if doesn't exist)
Vendor_Program_Requirement_Group__c requirementGroup;
List<Vendor_Program_Requirement_Group__c> existingReqGroups = [
    SELECT Id, Name 
    FROM Vendor_Program_Requirement_Group__c 
    WHERE Name = 'Sample Requirement Group' 
    LIMIT 1
];

if (existingReqGroups.isEmpty()) {
    requirementGroup = new Vendor_Program_Requirement_Group__c(
        Name = 'Sample Requirement Group',
        Status__c = 'Active',
        Active__c = true
    );
    insert requirementGroup;
    System.debug('Created requirement group: ' + requirementGroup.Id);
} else {
    requirementGroup = existingReqGroups[0];
    System.debug('Using existing requirement group: ' + requirementGroup.Id);
}

// Step 3: Get or Create Vendor Program Requirements
List<Vendor_Program_Requirement__c> requirements = [
    SELECT Id, Name 
    FROM Vendor_Program_Requirement__c 
    WHERE Name LIKE 'Sample Requirement%' 
    LIMIT 3
];

if (requirements.isEmpty()) {
    // Get a vendor program to link requirements to
    List<Vendor_Customization__c> vendorPrograms = [
        SELECT Id 
        FROM Vendor_Customization__c 
        LIMIT 1
    ];
    
    if (!vendorPrograms.isEmpty()) {
        requirements = new List<Vendor_Program_Requirement__c>{
            new Vendor_Program_Requirement__c(
                Name = 'Sample Requirement 1',
                Vendor_Program__c = vendorPrograms[0].Id,
                Active__c = true
            ),
            new Vendor_Program_Requirement__c(
                Name = 'Sample Requirement 2',
                Vendor_Program__c = vendorPrograms[0].Id,
                Active__c = true
            ),
            new Vendor_Program_Requirement__c(
                Name = 'Sample Requirement 3',
                Vendor_Program__c = vendorPrograms[0].Id,
                Active__c = true
            )
        };
        insert requirements;
        System.debug('Created ' + requirements.size() + ' vendor program requirements');
    } else {
        System.debug('⚠️ No vendor programs found. Please create a vendor program first.');
        return;
    }
} else {
    System.debug('Using existing requirements: ' + requirements.size());
}

// Step 4: Create Rules Engine with ALL Logic
Onboarding_Status_Rules_Engine__c rulesEngineAll = new Onboarding_Status_Rules_Engine__c(
    Name = 'Sample Rules Engine - ALL Logic',
    Vendor_Program_Group__c = programGroup.Id,
    Requirement_Group__c = requirementGroup.Id,
    Target_Onboarding_Status__c = 'Approved',
    Evaluation_Logic__c = 'ALL',
    Active__c = true
);
insert rulesEngineAll;
System.debug('Created rules engine (ALL): ' + rulesEngineAll.Id);

// Step 5: Create Rules for ALL Logic Engine
List<Onboarding_Status_Rule__c> rulesAll = new List<Onboarding_Status_Rule__c>{
    new Onboarding_Status_Rule__c(
        Name = 'Rule 1 - Requirement 1 Complete',
        Parent_Rule__c = rulesEngineAll.Id,
        Requirement__c = requirements[0].Id,
        Expected_Status__c = 'Complete',
        Rule_Number__c = 1
    ),
    new Onboarding_Status_Rule__c(
        Name = 'Rule 2 - Requirement 2 Complete',
        Parent_Rule__c = rulesEngineAll.Id,
        Requirement__c = requirements[1].Id,
        Expected_Status__c = 'Complete',
        Rule_Number__c = 2
    )
};
insert rulesAll;
System.debug('Created ' + rulesAll.size() + ' rules for ALL logic engine');

// Step 6: Create Rules Engine with ANY Logic
Onboarding_Status_Rules_Engine__c rulesEngineAny = new Onboarding_Status_Rules_Engine__c(
    Name = 'Sample Rules Engine - ANY Logic',
    Vendor_Program_Group__c = programGroup.Id,
    Requirement_Group__c = requirementGroup.Id,
    Target_Onboarding_Status__c = 'In Process',
    Evaluation_Logic__c = 'ANY',
    Active__c = true
);
insert rulesEngineAny;
System.debug('Created rules engine (ANY): ' + rulesEngineAny.Id);

// Step 7: Create Rules for ANY Logic Engine
List<Onboarding_Status_Rule__c> rulesAny = new List<Onboarding_Status_Rule__c>{
    new Onboarding_Status_Rule__c(
        Name = 'Rule 1 - Requirement 1 or 2 Complete',
        Parent_Rule__c = rulesEngineAny.Id,
        Requirement__c = requirements[0].Id,
        Expected_Status__c = 'Complete',
        Rule_Number__c = 1
    ),
    new Onboarding_Status_Rule__c(
        Name = 'Rule 2 - Requirement 2 or 3 Complete',
        Parent_Rule__c = rulesEngineAny.Id,
        Requirement__c = requirements[1].Id,
        Expected_Status__c = 'Complete',
        Rule_Number__c = 2
    )
};
insert rulesAny;
System.debug('Created ' + rulesAny.size() + ' rules for ANY logic engine');

// Step 8: Create Rules Engine with CUSTOM Logic
Onboarding_Status_Rules_Engine__c rulesEngineCustom = new Onboarding_Status_Rules_Engine__c(
    Name = 'Sample Rules Engine - CUSTOM Logic',
    Vendor_Program_Group__c = programGroup.Id,
    Requirement_Group__c = requirementGroup.Id,
    Target_Onboarding_Status__c = 'Ready for Review',
    Evaluation_Logic__c = 'CUSTOM',
    Custom_Evaluation_Logic__c = '(1 AND 2) OR 3',
    Active__c = true
);
insert rulesEngineCustom;
System.debug('Created rules engine (CUSTOM): ' + rulesEngineCustom.Id);

// Step 9: Create Rules for CUSTOM Logic Engine
List<Onboarding_Status_Rule__c> rulesCustom = new List<Onboarding_Status_Rule__c>{
    new Onboarding_Status_Rule__c(
        Name = 'Rule 1 - Requirement 1',
        Parent_Rule__c = rulesEngineCustom.Id,
        Requirement__c = requirements[0].Id,
        Expected_Status__c = 'Complete',
        Rule_Number__c = 1
    ),
    new Onboarding_Status_Rule__c(
        Name = 'Rule 2 - Requirement 2',
        Parent_Rule__c = rulesEngineCustom.Id,
        Requirement__c = requirements[1].Id,
        Expected_Status__c = 'Complete',
        Rule_Number__c = 2
    ),
    new Onboarding_Status_Rule__c(
        Name = 'Rule 3 - Requirement 3',
        Parent_Rule__c = rulesEngineCustom.Id,
        Requirement__c = requirements[2].Id,
        Expected_Status__c = 'Approved',
        Rule_Number__c = 3
    )
};
insert rulesCustom;
System.debug('Created ' + rulesCustom.size() + ' rules for CUSTOM logic engine');

System.debug('✓ Status rules setup complete!');
System.debug('Rules Engine (ALL) ID: ' + rulesEngineAll.Id);
System.debug('Rules Engine (ANY) ID: ' + rulesEngineAny.Id);
System.debug('Rules Engine (CUSTOM) ID: ' + rulesEngineCustom.Id);
System.debug('Total Rules Created: ' + (rulesAll.size() + rulesAny.size() + rulesCustom.size()));

