@IsTest
private class ExpOpportunityCreateRecordTest {
    private static final String CONFIG_CONTACT_ON_ACCOUNT = 'CONTACT_ON_ACCOUNT';
    private static final String CONFIG_CONTACT_ON_OPPORTUNITY = 'CONTACT_ON_OPPORTUNITY';

    private static void resetOverrides() {
        ExpOpportunityCreateRecord.resetTestOverrides();
    }

    private static Account createAccountRecord(String name) {
        Account accountRecord = new Account(Name = name);
        insert accountRecord;
        return accountRecord;
    }

    private static void seedLoadContextOverrides(Boolean isUserSpecial) {
        List<SObject> allContacts = new List<SObject>{
            new Contact(FirstName = 'Taylor', LastName = 'Signer'),
            new Contact(FirstName = 'Alex', LastName = 'Support')
        };
        List<SObject> signerContacts = new List<SObject>{
            new Contact(FirstName = 'Taylor', LastName = 'Signer')
        };
        List<SObject> acrRows = new List<SObject>{
            new AccountContactRelation(Roles = 'Primary Contact')
        };

        ExpOpportunityCreateRecord.testVendorOptionsJson = '[{"id":"a0V000000000001","label":"Vendor A"}]';
        ExpOpportunityCreateRecord.testIsUserSpecialOverride = isUserSpecial;
        ExpOpportunityCreateRecord.testProgramOpportunityRecordTypeId = '012000000000000AAA';
        ExpOpportunityCreateRecord.testEditorJsonByConfig = new Map<String, String>{
            CONFIG_CONTACT_ON_ACCOUNT => '[{"Contact":{"FirstName":"Taylor","LastName":"Signer"}}]',
            CONFIG_CONTACT_ON_OPPORTUNITY => '[{"OpportunityContactRole":{"Role":"Owner"}}]'
        };
        ExpOpportunityCreateRecord.testAllContactsFlowOutputOverride = new Map<String, Object>{
            'ContactRecordCollection' => allContacts,
            'AccountContactRelationshipCollection' => acrRows,
            'errorMessage' => null
        };
        ExpOpportunityCreateRecord.testSignerContactsFlowOutputOverride = new Map<String, Object>{
            'ContactRecordCollection' => signerContacts,
            'AccountContactRelationshipCollection' => new List<SObject>(),
            'errorMessage' => null
        };
        ExpOpportunityCreateRecord.testOnboardingFlowOutputOverride = new Map<String, Object>{
            'HasAnyOboardingForAccount' => false,
            'HasChuzoOnboardingForOpportunity' => false,
            'HasNDAOnboardingForOpportunity' => false,
            'HasNonChuzoOnboardingForOpportunity' => false
        };
        ExpOpportunityCreateRecord.testBreFlowOutputOverride = new Map<String, Object>{
            'FinalNextAction' => 'OFFER_CHUZO_CREATE',
            'ShowAgreementChoice' => true,
            'ShowPersonalGuarantee' => isUserSpecial,
            'ShowVendorSelector' => true,
            'ShowVerifyAccount' => true,
            'ErrorMessage' => null
        };
    }

    @IsTest
    static void loadContext_requiresAccountId() {
        resetOverrides();
        Test.startTest();
        ExpOpportunityCreateRecord.LoadContextResponse response =
            ExpOpportunityCreateRecord.loadContext(null, null);
        Test.stopTest();

        System.assertEquals(false, response.success, 'Expected loadContext to fail without Account Id.');
        System.assertEquals('Account Id is required.', response.errorMessage, 'Expected required Account Id message.');
    }

    @IsTest
    static void loadContext_happyPath_withOverrides() {
        resetOverrides();
        Account accountRecord = createAccountRecord(' Load Context Account');
        seedLoadContextOverrides(true);

        Test.startTest();
        ExpOpportunityCreateRecord.LoadContextResponse response =
            ExpOpportunityCreateRecord.loadContext(accountRecord.Id, null);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Expected loadContext success.');
        System.assertEquals(accountRecord.Id, response.accountRecord.Id);
        System.assertEquals(2, response.contactCount, 'Expected all contacts count.');
        System.assertEquals(1, response.signerContactCount, 'Expected signer contacts count.');
        System.assertEquals('OFFER_CHUZO_CREATE', response.finalNextAction);
        System.assertEquals(true, response.showAgreementChoice);
        System.assertEquals(true, response.showVendorSelector);
        System.assertEquals(true, response.showVerifyAccount);
        System.assertEquals(true, response.isUserSpecial);
        System.assertEquals('012000000000000AAA', response.opportunityRecordTypeId);
        System.assertNotEquals(null, response.defaultCloseDate);
        System.assertNotEquals(null, response.defaultProgramType);
        System.assertNotEquals(null, response.stageOptions);
        System.assertNotEquals(null, response.leadSourceOptions);

        resetOverrides();
    }

    @IsTest
    static void loadContext_handlesMissingAccountRecord() {
        resetOverrides();

        Test.startTest();
        ExpOpportunityCreateRecord.LoadContextResponse response =
            ExpOpportunityCreateRecord.loadContext(Id.valueOf('001000000000000AAA'), null);
        Test.stopTest();

        System.assertEquals(false, response.success);
        System.assertNotEquals(null, response.errorMessage);
    }

    @IsTest
    static void loadContext_usesPreloadedFlowContextWhenProvided() {
        resetOverrides();
        Account accountRecord = createAccountRecord(' Preloaded Flow Context Account');
        seedLoadContextOverrides(false);

        String preloadedContextJson = JSON.serialize(
            new Map<String, Object>{
                'finalNextAction' => 'NO_ACTION',
                'showAgreementChoice' => false,
                'showPersonalGuarantee' => false,
                'showVendorSelector' => true,
                'showVerifyAccount' => true,
                'isUserSpecial' => true,
                'availableVendorOptionString' => '[{"id":"a0VFLOW","label":"Flow Vendor"}]',
                'hasAnyOnboardingForAccount' => true,
                'hasChuzoOnboardingForOpportunity' => false,
                'hasNdaOnboardingForOpportunity' => true,
                'hasNonChuzoOnboardingForOpportunity' => false,
                'opportunityRecordTypeId' => '012FLOW000000000AAA',
                'ruleErrorMessage' => 'Flow supplied rule message.'
            }
        );

        Test.startTest();
        ExpOpportunityCreateRecord.LoadContextResponse response =
            ExpOpportunityCreateRecord.loadContext(accountRecord.Id, preloadedContextJson);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Expected loadContext success.');
        System.assertEquals('NO_ACTION', response.finalNextAction);
        System.assertEquals(false, response.showAgreementChoice);
        System.assertEquals(true, response.showVendorSelector);
        System.assertEquals(true, response.showVerifyAccount);
        System.assertEquals(true, response.isUserSpecial);
        System.assertEquals(true, response.hasAnyOnboardingForAccount);
        System.assertEquals(true, response.hasNdaOnboardingForOpportunity);
        System.assertEquals(
            '[{"id":"a0VFLOW","label":"Flow Vendor"}]',
            response.availableVendorOptionString
        );
        System.assertEquals('012FLOW000000000AAA', response.opportunityRecordTypeId);
        System.assertEquals('Flow supplied rule message.', response.ruleErrorMessage);

        resetOverrides();
    }

    @IsTest
    static void saveContacts_requiresValidInputs() {
        resetOverrides();
        Test.startTest();
        ExpOpportunityCreateRecord.SaveContactsResponse nullRequestResponse =
            ExpOpportunityCreateRecord.saveContactsAndPrepareOcr(null);
        Test.stopTest();

        System.assertEquals(false, nullRequestResponse.success, 'Expected null request to fail.');
        System.assertEquals('Account Id is required.', nullRequestResponse.errorMessage);

        Account accountRecord = new Account(Name = ' Facade Test Account');
        insert accountRecord;

        ExpOpportunityCreateRecord.SaveContactsRequest missingJsonRequest =
            new ExpOpportunityCreateRecord.SaveContactsRequest();
        missingJsonRequest.accountId = accountRecord.Id;
        missingJsonRequest.contactsJson = null;

        ExpOpportunityCreateRecord.SaveContactsResponse missingJsonResponse =
            ExpOpportunityCreateRecord.saveContactsAndPrepareOcr(missingJsonRequest);

        System.assertEquals(false, missingJsonResponse.success, 'Expected missing contacts JSON to fail.');
        System.assertEquals('Contacts JSON is required.', missingJsonResponse.errorMessage);
    }

    @IsTest
    static void saveContacts_success_withOverrides() {
        resetOverrides();
        Account accountRecord = createAccountRecord(' Save Contacts Account');
        seedLoadContextOverrides(false);
        ExpOpportunityCreateRecord.testUpsertErrorsByConfig = new Map<String, List<String>>{
            CONFIG_CONTACT_ON_ACCOUNT => new List<String>()
        };

        ExpOpportunityCreateRecord.SaveContactsRequest requestItem =
            new ExpOpportunityCreateRecord.SaveContactsRequest();
        requestItem.accountId = accountRecord.Id;
        requestItem.contactsJson = '[{"Contact":{"LastName":"Signer"}}]';

        Test.startTest();
        ExpOpportunityCreateRecord.SaveContactsResponse response =
            ExpOpportunityCreateRecord.saveContactsAndPrepareOcr(requestItem);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Expected saveContactsAndPrepareOcr success.');
        System.assertEquals(2, response.contactCount);
        System.assertEquals(1, response.signerContactCount);
        System.assertNotEquals(null, response.contactRecordsJson);
        System.assertNotEquals(null, response.opportunityContactSeedJson);

        resetOverrides();
    }

    @IsTest
    static void saveContacts_surfacesCollectionErrors() {
        resetOverrides();
        Account accountRecord = new Account(Name = ' Facade Error Account');
        insert accountRecord;

        ExpOpportunityCreateRecord.SaveContactsRequest invalidJsonRequest =
            new ExpOpportunityCreateRecord.SaveContactsRequest();
        invalidJsonRequest.accountId = accountRecord.Id;
        invalidJsonRequest.contactsJson = '[{"badJson":}';

        Test.startTest();
        ExpOpportunityCreateRecord.SaveContactsResponse response =
            ExpOpportunityCreateRecord.saveContactsAndPrepareOcr(invalidJsonRequest);
        Test.stopTest();

        System.assertEquals(false, response.success, 'Expected invalid JSON request to fail.');
        System.assertNotEquals(null, response.errorMessage, 'Expected error message to be returned.');
    }

    @IsTest
    static void submit_requiresPayloads() {
        resetOverrides();
        ExpOpportunityCreateRecord.SubmitResponse nullSubmitResponse =
            ExpOpportunityCreateRecord.submitCreateRecord(null);
        System.assertEquals(false, nullSubmitResponse.success);
        System.assertEquals('Account Id is required.', nullSubmitResponse.errorMessage);

        ExpOpportunityCreateRecord.SubmitRequest missingAccountRequest =
            new ExpOpportunityCreateRecord.SubmitRequest();
        missingAccountRequest.contactsJson = '[]';
        missingAccountRequest.opportunityContactsJson = '[]';

        ExpOpportunityCreateRecord.SubmitResponse missingAccountResponse =
            ExpOpportunityCreateRecord.submitCreateRecord(missingAccountRequest);
        System.assertEquals(false, missingAccountResponse.success);
        System.assertEquals('Account Id is required.', missingAccountResponse.errorMessage);

        ExpOpportunityCreateRecord.SubmitRequest missingContactPayloadRequest =
            new ExpOpportunityCreateRecord.SubmitRequest();
        missingContactPayloadRequest.accountId = UserInfo.getUserId();
        missingContactPayloadRequest.contactsJson = null;
        missingContactPayloadRequest.opportunityContactsJson = '[]';

        ExpOpportunityCreateRecord.SubmitResponse missingContactPayloadResponse =
            ExpOpportunityCreateRecord.submitCreateRecord(missingContactPayloadRequest);
        System.assertEquals(false, missingContactPayloadResponse.success);
        System.assertEquals(
            'Contacts must be saved before submission.',
            missingContactPayloadResponse.errorMessage
        );

        Account accountRecord = createAccountRecord('Missing OCR Payload Account');
        ExpOpportunityCreateRecord.SubmitRequest missingOcrPayloadRequest =
            new ExpOpportunityCreateRecord.SubmitRequest();
        missingOcrPayloadRequest.accountId = accountRecord.Id;
        missingOcrPayloadRequest.contactsJson = '[{"Contact":{"LastName":"Signer"}}]';
        missingOcrPayloadRequest.opportunityContactsJson = null;

        ExpOpportunityCreateRecord.SubmitResponse missingOcrPayloadResponse =
            ExpOpportunityCreateRecord.submitCreateRecord(missingOcrPayloadRequest);
        System.assertEquals(false, missingOcrPayloadResponse.success);
        System.assertEquals(
            'Opportunity contact roles are required.',
            missingOcrPayloadResponse.errorMessage
        );
    }

    @IsTest
    static void submit_success_whenQueueResultQueued() {
        resetOverrides();
        Account accountRecord = createAccountRecord('Original Name');

        ExpOpportunityCreateRecord.testUpsertErrorsByConfig = new Map<String, List<String>>{
            CONFIG_CONTACT_ON_ACCOUNT => new List<String>()
        };
        ExpOpportunityCreateAsyncService.QueueResult queueResult =
            new ExpOpportunityCreateAsyncService.QueueResult();
        queueResult.queued = true;
        queueResult.message = 'Create chain completed synchronously.';
        ExpOpportunityCreateRecord.testQueueResultsOverride =
            new List<ExpOpportunityCreateAsyncService.QueueResult>{ queueResult };

        ExpOpportunityCreateRecord.SubmitRequest requestItem =
            new ExpOpportunityCreateRecord.SubmitRequest();
        requestItem.accountId = accountRecord.Id;
        requestItem.accountName = 'Updated Name';
        requestItem.accountPhone = '555-222-1111';
        requestItem.contactsJson = '[{"Contact":{"LastName":"Signer"}}]';
        requestItem.opportunityContactsJson = '[{"OpportunityContactRole":{"Role":"Owner"}}]';

        Test.startTest();
        ExpOpportunityCreateRecord.SubmitResponse response =
            ExpOpportunityCreateRecord.submitCreateRecord(requestItem);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Expected successful submit response.');
        System.assertEquals('Create chain completed synchronously.', response.message);

        Account updatedAccount = [
            SELECT
                Name,
                Phone,
                BillingStreet,
                BillingCity,
                BillingState,
                BillingPostalCode,
                BillingCountry,
                ShippingStreet,
                ShippingCity,
                ShippingState,
                ShippingPostalCode,
                ShippingCountry
            FROM Account
            WHERE Id = :accountRecord.Id
            LIMIT 1
        ];
        System.assertEquals('Updated Name', updatedAccount.Name);
        System.assertEquals('555-222-1111', updatedAccount.Phone);

        resetOverrides();
    }

    @IsTest
    static void submit_queueFailure_withFilledOpportunityAndVendorFields() {
        resetOverrides();
        Account accountRecord = createAccountRecord('Queue Filled Payload');

        ExpOpportunityCreateRecord.testUpsertErrorsByConfig = new Map<String, List<String>>{
            CONFIG_CONTACT_ON_ACCOUNT => new List<String>()
        };
        ExpOpportunityCreateAsyncService.QueueResult queueResult =
            new ExpOpportunityCreateAsyncService.QueueResult();
        queueResult.queued = false;
        queueResult.message = 'Queue returned false for filled payload.';
        ExpOpportunityCreateRecord.testQueueResultsOverride =
            new List<ExpOpportunityCreateAsyncService.QueueResult>{ queueResult };

        ExpOpportunityCreateRecord.SubmitRequest requestItem =
            new ExpOpportunityCreateRecord.SubmitRequest();
        requestItem.accountId = accountRecord.Id;
        requestItem.accountName = 'Queue Filled Payload Updated';
        requestItem.contactsJson = '[{"Contact":{"LastName":"Signer"}}]';
        requestItem.opportunityContactsJson = '[{"OpportunityContactRole":{"Role":"Owner"}}]';
        requestItem.finalNextAction = 'CREATE_VENDOR_PROGRAM_ONBOARDING';
        requestItem.opportunityCloseDate = String.valueOf(Date.today().addDays(3));
        requestItem.opportunityStageName = 'Prospecting';
        requestItem.opportunityProgramType = 'NDA/Program Base App';
        requestItem.opportunityProgramBaseSelection = 'Program Base Application - with Chuzo';
        requestItem.opportunityDocumentsReady = true;
        requestItem.opportunityLeadSource = 'Web';
        requestItem.opportunitySource = 'Inbound';
        requestItem.opportunityNextStep = 'Call merchant';
        requestItem.opportunityNextStepDate = String.valueOf(Date.today().addDays(6));
        requestItem.opportunityOwnerRole = 'Sales Rep';
        requestItem.opportunityRecordTypeId = '012000000000000AAA';
        requestItem.opportunityType = 'New Customer';
        requestItem.selectedVendorId = accountRecord.Id;
        requestItem.selectedRetailOption = 'Retail';
        requestItem.selectedBusinessVertical = 'Consumer';

        Test.startTest();
        ExpOpportunityCreateRecord.SubmitResponse response =
            ExpOpportunityCreateRecord.submitCreateRecord(requestItem);
        Test.stopTest();

        System.assertEquals(false, response.success);
        System.assertNotEquals(null, response.errorMessage);

        resetOverrides();
    }

    @IsTest
    static void submit_returnsQueueFailureAsError() {
        resetOverrides();
        Account accountRecord = createAccountRecord('Queue Failure Account');

        ExpOpportunityCreateRecord.testUpsertErrorsByConfig = new Map<String, List<String>>{
            CONFIG_CONTACT_ON_ACCOUNT => new List<String>()
        };
        ExpOpportunityCreateAsyncService.QueueResult queueResult =
            new ExpOpportunityCreateAsyncService.QueueResult();
        queueResult.queued = false;
        queueResult.message = 'Create chain failed: OCR required.';
        ExpOpportunityCreateRecord.testQueueResultsOverride =
            new List<ExpOpportunityCreateAsyncService.QueueResult>{ queueResult };

        ExpOpportunityCreateRecord.SubmitRequest requestItem =
            new ExpOpportunityCreateRecord.SubmitRequest();
        requestItem.accountId = accountRecord.Id;
        requestItem.accountName = 'Queue Failure Account Updated';
        requestItem.contactsJson = '[{"Contact":{"LastName":"Signer"}}]';
        requestItem.opportunityContactsJson = '[{"OpportunityContactRole":{"Role":"Owner"}}]';
        requestItem.finalNextAction = 'CREATE_VENDOR_PROGRAM_ONBOARDING';
        requestItem.opportunityCloseDate = 'not-a-date';
        requestItem.opportunityNextStepDate = 'still-not-a-date';
        requestItem.opportunityProgramBaseSelection = null;
        requestItem.selectedVendorId = accountRecord.Id;
        requestItem.selectedRetailOption = null;
        requestItem.selectedBusinessVertical = 'Consumer';

        Test.startTest();
        ExpOpportunityCreateRecord.SubmitResponse response =
            ExpOpportunityCreateRecord.submitCreateRecord(requestItem);
        Test.stopTest();

        System.assertEquals(false, response.success, 'Expected submit failure when chain reports not queued.');
        System.assertEquals('Create chain failed: OCR required.', response.errorMessage);
        System.assertEquals(1, response.stageErrors.size());

        resetOverrides();
    }

    @IsTest
    static void submit_returnsErrorWhenQueueResultMissing() {
        resetOverrides();
        Account accountRecord = createAccountRecord('Queue Empty Result');

        ExpOpportunityCreateRecord.testUpsertErrorsByConfig = new Map<String, List<String>>{
            CONFIG_CONTACT_ON_ACCOUNT => null
        };
        ExpOpportunityCreateRecord.testQueueResultsOverride =
            new List<ExpOpportunityCreateAsyncService.QueueResult>();

        ExpOpportunityCreateRecord.SubmitRequest requestItem =
            new ExpOpportunityCreateRecord.SubmitRequest();
        requestItem.accountId = accountRecord.Id;
        requestItem.accountName = 'Queue Empty Result Updated';
        requestItem.contactsJson = '[{"Contact":{"LastName":"Signer"}}]';
        requestItem.opportunityContactsJson = '[{"OpportunityContactRole":{"Role":"Owner"}}]';

        Test.startTest();
        ExpOpportunityCreateRecord.SubmitResponse response =
            ExpOpportunityCreateRecord.submitCreateRecord(requestItem);
        Test.stopTest();

        System.assertEquals(false, response.success);
        System.assertEquals('Create chain returned no result.', response.errorMessage);

        resetOverrides();
    }

    @IsTest
    static void submit_usesDefaultErrorWhenQueueMessageBlank() {
        resetOverrides();
        Account accountRecord = createAccountRecord('Queue Blank Message');

        ExpOpportunityCreateRecord.testUpsertErrorsByConfig = new Map<String, List<String>>{
            CONFIG_CONTACT_ON_ACCOUNT => new List<String>()
        };
        ExpOpportunityCreateAsyncService.QueueResult queueResult =
            new ExpOpportunityCreateAsyncService.QueueResult();
        queueResult.queued = false;
        queueResult.message = null;
        ExpOpportunityCreateRecord.testQueueResultsOverride =
            new List<ExpOpportunityCreateAsyncService.QueueResult>{ queueResult };

        ExpOpportunityCreateRecord.SubmitRequest requestItem =
            new ExpOpportunityCreateRecord.SubmitRequest();
        requestItem.accountId = accountRecord.Id;
        requestItem.accountName = 'Queue Blank Message Updated';
        requestItem.contactsJson = '[{"Contact":{"LastName":"Signer"}}]';
        requestItem.opportunityContactsJson = '[{"OpportunityContactRole":{"Role":"Owner"}}]';

        Test.startTest();
        ExpOpportunityCreateRecord.SubmitResponse response =
            ExpOpportunityCreateRecord.submitCreateRecord(requestItem);
        Test.stopTest();

        System.assertEquals(false, response.success);
        System.assertEquals('Create chain failed.', response.errorMessage);
        System.assertEquals(1, response.stageErrors.size());

        resetOverrides();
    }

    @IsTest
    static void submit_surfacesContactUpsertErrors() {
        resetOverrides();
        Account accountRecord = createAccountRecord('Upsert Error Account');

        ExpOpportunityCreateRecord.testUpsertErrorsByConfig = new Map<String, List<String>>{
            CONFIG_CONTACT_ON_ACCOUNT => new List<String>{ 'Contact row invalid' }
        };

        ExpOpportunityCreateRecord.SubmitRequest requestItem =
            new ExpOpportunityCreateRecord.SubmitRequest();
        requestItem.accountId = accountRecord.Id;
        requestItem.contactsJson = '[{"Contact":{"LastName":"Signer"}}]';
        requestItem.opportunityContactsJson = '[{"OpportunityContactRole":{"Role":"Owner"}}]';

        Test.startTest();
        ExpOpportunityCreateRecord.SubmitResponse response =
            ExpOpportunityCreateRecord.submitCreateRecord(requestItem);
        Test.stopTest();

        System.assertEquals(false, response.success);
        System.assertEquals('Contact row invalid', response.errorMessage);
        System.assertEquals(1, response.stageErrors.size());

        resetOverrides();
    }

    @IsTest
    static void submit_surfacesDefaultVendorProgramError() {
        resetOverrides();
        Account accountRecord = createAccountRecord('Default Vendor Program Error Account');

        ExpOpportunityCreateRecord.testUpsertErrorsByConfig = new Map<String, List<String>>{
            CONFIG_CONTACT_ON_ACCOUNT => new List<String>()
        };
        ExpOpportunityCreateRecord.testDefaultVendorProgramErrorOverride =
            'No default Vendor Program configured for scenario.';

        ExpOpportunityCreateRecord.SubmitRequest requestItem =
            new ExpOpportunityCreateRecord.SubmitRequest();
        requestItem.accountId = accountRecord.Id;
        requestItem.accountName = 'Default Vendor Program Error Account Updated';
        requestItem.contactsJson = '[{"Contact":{"LastName":"Signer"}}]';
        requestItem.opportunityContactsJson = '[{"OpportunityContactRole":{"Role":"Owner"}}]';
        requestItem.finalNextAction = 'REQUIRE_NDA';

        Test.startTest();
        ExpOpportunityCreateRecord.SubmitResponse response =
            ExpOpportunityCreateRecord.submitCreateRecord(requestItem);
        Test.stopTest();

        System.assertEquals(false, response.success);
        System.assertEquals(
            'No default Vendor Program configured for scenario.',
            response.errorMessage
        );
        System.assertEquals(1, response.stageErrors.size());

        resetOverrides();
    }

    @IsTest
    static void submit_usesDefaultVendorProgramWhenNoVendorSelection() {
        resetOverrides();
        Account accountRecord = createAccountRecord('Default Vendor Program Success Account');

        ExpOpportunityCreateRecord.testUpsertErrorsByConfig = new Map<String, List<String>>{
            CONFIG_CONTACT_ON_ACCOUNT => new List<String>()
        };
        ExpOpportunityCreateRecord.testDefaultVendorProgramOverride =
            new Vendor_Customization__c(Id = Id.valueOf('aDF000000000001'));

        ExpOpportunityCreateAsyncService.QueueResult queueResult =
            new ExpOpportunityCreateAsyncService.QueueResult();
        queueResult.queued = true;
        queueResult.message = 'Default vendor fallback succeeded.';
        ExpOpportunityCreateRecord.testQueueResultsOverride =
            new List<ExpOpportunityCreateAsyncService.QueueResult>{ queueResult };

        ExpOpportunityCreateRecord.SubmitRequest requestItem =
            new ExpOpportunityCreateRecord.SubmitRequest();
        requestItem.accountId = accountRecord.Id;
        requestItem.accountName = 'Default Vendor Program Success Account Updated';
        requestItem.contactsJson = '[{"Contact":{"LastName":"Signer"}}]';
        requestItem.opportunityContactsJson = '[{"OpportunityContactRole":{"Role":"Owner"}}]';
        requestItem.finalNextAction = 'REQUIRE_NDA';

        Test.startTest();
        ExpOpportunityCreateRecord.SubmitResponse response =
            ExpOpportunityCreateRecord.submitCreateRecord(requestItem);
        Test.stopTest();

        System.assertEquals(true, response.success);
        System.assertEquals('Default vendor fallback succeeded.', response.message);

        resetOverrides();
    }
}
