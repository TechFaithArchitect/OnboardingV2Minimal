@isTest
private class AccountVendorOnboardingSyncInvocableTest {
    @isTest
    static void createsAvoAndSetsPrimaryContact() {
        Account accountRecord = TestDataFactory.createAccount('AVO Sync Account', true);
        Contact primaryContact = TestDataFactory.createContact('Primary', 'Owner', true, accountRecord);

        Opportunity opportunity = new Opportunity(
            Name = 'AVO Sync Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(7),
            AccountId = accountRecord.Id
        );
        insert opportunity;

        OpportunityContactRole primaryRole = new OpportunityContactRole(
            OpportunityId = opportunity.Id,
            ContactId = primaryContact.Id,
            IsPrimary = true,
            Role = 'Owner'
        );
        insert primaryRole;

        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Onboarding__c onboardingRecord = TestDataFactory.createOnboarding(accountRecord, vendorProgram, true);
        onboardingRecord.Opportunity__c = opportunity.Id;
        onboardingRecord.Onboarding_Status__c = preferredOnboardingStatus(new List<String>{ 'In Progress', 'Intake' });
        update onboardingRecord;

        AccountVendorOnboardingSyncInvocable.Request req =
            new AccountVendorOnboardingSyncInvocable.Request();
        req.onboardingId = onboardingRecord.Id;

        Test.startTest();
        List<AccountVendorOnboardingSyncInvocable.Response> results =
            AccountVendorOnboardingSyncInvocable.sync(
                new List<AccountVendorOnboardingSyncInvocable.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'One response should be returned.');
        System.assertEquals(onboardingRecord.Id, results[0].onboardingId, 'Response should match onboarding.');
        System.assertEquals(true, results[0].created, 'First sync should create AVO.');
        System.assertNotEquals(null, results[0].accountVendorProgramOnboardingId, 'Created AVO Id should be present.');

        Account_Vendor_Program_Onboarding__c avo = [
            SELECT Account__c, Onboarding__c, Opportunity__c, Primary_Contact__c, Status__c, Is_Active__c
            FROM Account_Vendor_Program_Onboarding__c
            WHERE Id = :results[0].accountVendorProgramOnboardingId
            LIMIT 1
        ];

        System.assertEquals(accountRecord.Id, avo.Account__c, 'Account should sync from Onboarding.');
        System.assertEquals(onboardingRecord.Id, avo.Onboarding__c, 'Onboarding link should be set.');
        System.assertEquals(opportunity.Id, avo.Opportunity__c, 'Opportunity should sync from Onboarding.');
        System.assertEquals(primaryContact.Id, avo.Primary_Contact__c, 'Primary contact should come from primary OCR.');
        System.assertNotEquals(null, avo.Status__c, 'Status should be populated.');
        System.assertEquals(true, avo.Is_Active__c, 'Non-terminal status should be active.');
    }

    @isTest
    static void updatesExistingAvoWithoutCreatingDuplicate() {
        Account accountRecord = TestDataFactory.createAccount('AVO Update Account', true);
        Contact firstContact = TestDataFactory.createContact('First', 'Owner', true, accountRecord);
        Contact secondContact = TestDataFactory.createContact('Second', 'Owner', true, accountRecord);

        Opportunity opportunity = new Opportunity(
            Name = 'AVO Update Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = accountRecord.Id
        );
        insert opportunity;

        insert new OpportunityContactRole(
            OpportunityId = opportunity.Id,
            ContactId = firstContact.Id,
            IsPrimary = true,
            Role = 'Owner'
        );

        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Onboarding__c onboardingRecord = TestDataFactory.createOnboarding(accountRecord, vendorProgram, true);
        onboardingRecord.Opportunity__c = opportunity.Id;
        onboardingRecord.Onboarding_Status__c = preferredOnboardingStatus(new List<String>{ 'In Progress', 'Intake' });
        update onboardingRecord;

        AccountVendorOnboardingSyncInvocable.Request req =
            new AccountVendorOnboardingSyncInvocable.Request();
        req.onboardingId = onboardingRecord.Id;

        AccountVendorOnboardingSyncInvocable.sync(
            new List<AccountVendorOnboardingSyncInvocable.Request>{ req }
        );

        // Change primary contact and move onboarding status toward completion.
        delete [
            SELECT Id
            FROM OpportunityContactRole
            WHERE OpportunityId = :opportunity.Id
            AND IsPrimary = true
        ];
        insert new OpportunityContactRole(
            OpportunityId = opportunity.Id,
            ContactId = secondContact.Id,
            IsPrimary = true,
            Role = 'Authorized Signer'
        );

        String completedStatus = preferredOnboardingStatus(new List<String>{ 'Completed', 'Complete', 'In Progress' });
        if (String.isNotBlank(completedStatus)) {
            onboardingRecord.Onboarding_Status__c = completedStatus;
            update onboardingRecord;
        }

        Test.startTest();
        List<AccountVendorOnboardingSyncInvocable.Response> results =
            AccountVendorOnboardingSyncInvocable.sync(
                new List<AccountVendorOnboardingSyncInvocable.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'One response should be returned.');
        System.assertEquals(false, results[0].created, 'Second sync should update existing record.');

        Integer avoCount = [
            SELECT COUNT()
            FROM Account_Vendor_Program_Onboarding__c
            WHERE Onboarding__c = :onboardingRecord.Id
        ];
        System.assertEquals(1, avoCount, 'Sync must remain idempotent per onboarding.');

        Account_Vendor_Program_Onboarding__c avo = [
            SELECT Primary_Contact__c, Status__c, Is_Active__c
            FROM Account_Vendor_Program_Onboarding__c
            WHERE Onboarding__c = :onboardingRecord.Id
            LIMIT 1
        ];
        System.assertEquals(secondContact.Id, avo.Primary_Contact__c, 'Primary contact should update from OCR change.');
        System.assert(
            avo.Status__c == 'Completed' || avo.Status__c == 'Complete' || avo.Status__c == 'In Progress' || avo.Status__c == 'Intake',
            'Status should remain in supported values after sync.'
        );
    }

    @isTest
    static void doesNotForceClosedLostWithoutReason() {
        Account accountRecord = TestDataFactory.createAccount('AVO Closed Lost Account', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Onboarding__c onboardingRecord = TestDataFactory.createOnboarding(accountRecord, vendorProgram, true);
        onboardingRecord.Onboarding_Status__c = preferredOnboardingStatus(new List<String>{ 'In Progress', 'Intake' });
        update onboardingRecord;

        AccountVendorOnboardingSyncInvocable.Request req =
            new AccountVendorOnboardingSyncInvocable.Request();
        req.onboardingId = onboardingRecord.Id;
        AccountVendorOnboardingSyncInvocable.sync(
            new List<AccountVendorOnboardingSyncInvocable.Request>{ req }
        );

        String closedLostStatus = preferredOnboardingStatus(new List<String>{ 'Closed Lost' });
        if (String.isBlank(closedLostStatus)) {
            System.assert(true, 'Closed Lost onboarding status not available in this org.');
            return;
        }

        onboardingRecord.Onboarding_Status__c = closedLostStatus;
        update onboardingRecord;

        Test.startTest();
        AccountVendorOnboardingSyncInvocable.sync(
            new List<AccountVendorOnboardingSyncInvocable.Request>{ req }
        );
        Test.stopTest();

        Account_Vendor_Program_Onboarding__c avo = [
            SELECT Status__c, Reason_for_Return__c
            FROM Account_Vendor_Program_Onboarding__c
            WHERE Onboarding__c = :onboardingRecord.Id
            LIMIT 1
        ];

        if (String.isBlank(avo.Reason_for_Return__c)) {
            System.assertNotEquals('Closed Lost', avo.Status__c, 'Closed Lost should not be auto-set without reason.');
        }
    }

    private static String preferredOnboardingStatus(List<String> preferredValues) {
        List<String> available = TestDataFactoryUtil.getPicklistValues(
            Onboarding__c.SObjectType,
            'Onboarding_Status__c'
        );
        for (String preferred : preferredValues) {
            if (available.contains(preferred)) {
                return preferred;
            }
        }
        return available.isEmpty() ? null : available[0];
    }
}
