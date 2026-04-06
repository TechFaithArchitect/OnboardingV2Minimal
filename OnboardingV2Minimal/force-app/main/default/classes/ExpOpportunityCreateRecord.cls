public with sharing class ExpOpportunityCreateRecord {
    private static final String CONFIG_CONTACT_ON_ACCOUNT = 'CONTACT_ON_ACCOUNT';
    private static final String CONFIG_CONTACT_ON_OPPORTUNITY = 'CONTACT_ON_OPPORTUNITY';

    private static final String FLOW_GET_ONBOARDING_RECORDS = 'DOMAIN_OmniSObject_SFL_GET_Onboarding_Records';
    private static final String FLOW_GET_CONTACT_RECORDS = 'DOMAIN_OmniSObject_SFL_GET_Contact_Record';
    private static final String FLOW_BRE_EVALUATE = 'BLL_BRE_Evaluate_Business_Rules';

    private static final String BRE_CONTEXT_ONBOARDING_ORCHESTRATOR = 'OnboardingOrchestrator';
    private static final String PROGRAM_OPPORTUNITY_RECORD_TYPE_NAME = 'Program Opportunity';

    private static final Integer DEFAULT_OPPORTUNITY_CLOSE_DAYS = 30;
    private static final String DEFAULT_STAGE = 'Prospecting';
    private static final String DEFAULT_PROGRAM_TYPE = 'NDA/Program Base App';
    private static final String DEFAULT_PROGRAM_BASE_SELECTION = 'Program Base Application - without Chuzo';
    private static final String DEFAULT_VENDOR_PATH_PROGRAM_BASE_SELECTION = 'Not Applicable';
    private static final String PROGRAM_BASE_SELECTION_WITH_CHUZO_NO_PG =
        'Program Base Application - with Chuzo (No Personal Guarantee)';
    private static final String DEFAULT_OPPORTUNITY_TYPE = 'New Business';
    private static final String SPECIAL_CHUZO_PERMISSION_SET_API_NAME =
        'Onboarding_Can_Send_Special_Chuzo_Agreement';

    @TestVisible
    private static String testVendorOptionsJson;
    @TestVisible
    private static String testProgramOpportunityRecordTypeId;
    @TestVisible
    private static Boolean testIsUserSpecialOverride;
    @TestVisible
    private static Map<String, String> testEditorJsonByConfig;
    @TestVisible
    private static Map<String, List<String>> testUpsertErrorsByConfig;
    @TestVisible
    private static Map<String, Object> testOnboardingFlowOutputOverride;
    @TestVisible
    private static Map<String, Object> testBreFlowOutputOverride;
    @TestVisible
    private static Map<String, Object> testAllContactsFlowOutputOverride;
    @TestVisible
    private static Map<String, Object> testSignerContactsFlowOutputOverride;
    @TestVisible
    private static List<ExpOpportunityCreateAsyncService.QueueResult> testQueueResultsOverride;
    @TestVisible
    private static Vendor_Customization__c testDefaultVendorProgramOverride;
    @TestVisible
    private static String testDefaultVendorProgramErrorOverride;

    @TestVisible
    static void resetTestOverrides() {
        testVendorOptionsJson = null;
        testProgramOpportunityRecordTypeId = null;
        testIsUserSpecialOverride = null;
        testEditorJsonByConfig = null;
        testUpsertErrorsByConfig = null;
        testOnboardingFlowOutputOverride = null;
        testBreFlowOutputOverride = null;
        testAllContactsFlowOutputOverride = null;
        testSignerContactsFlowOutputOverride = null;
        testQueueResultsOverride = null;
        testDefaultVendorProgramOverride = null;
        testDefaultVendorProgramErrorOverride = null;
    }

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class LoadContextResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;

        @AuraEnabled public Account accountRecord;
        @AuraEnabled public String contactRecordsJson;
        @AuraEnabled public String opportunityContactSeedJson;
        @AuraEnabled public Integer contactCount;
        @AuraEnabled public Integer signerContactCount;

        @AuraEnabled public String availableVendorOptionString;

        @AuraEnabled public Boolean hasAnyOnboardingForAccount;
        @AuraEnabled public Boolean hasChuzoOnboardingForOpportunity;
        @AuraEnabled public Boolean hasNdaOnboardingForOpportunity;
        @AuraEnabled public Boolean hasNonChuzoOnboardingForOpportunity;
        @AuraEnabled public Boolean isUserSpecial;
        @AuraEnabled public String finalNextAction;
        @AuraEnabled public Boolean showAgreementChoice;
        @AuraEnabled public Boolean showPersonalGuarantee;
        @AuraEnabled public Boolean showVendorSelector;
        @AuraEnabled public Boolean showVerifyAccount;
        @AuraEnabled public String ruleErrorMessage;

        @AuraEnabled public String opportunityRecordTypeId;
        @AuraEnabled public String defaultCloseDate;
        @AuraEnabled public String defaultNextStepDate;
        @AuraEnabled public String defaultStageName;
        @AuraEnabled public String defaultProgramType;
        @AuraEnabled public String defaultProgramBaseSelection;
        @AuraEnabled public String defaultLeadSource;
        @AuraEnabled public String defaultOpportunitySource;
        @AuraEnabled public String defaultOwnerRole;
        @AuraEnabled public String defaultType;

        @AuraEnabled public List<PicklistOption> stageOptions;
        @AuraEnabled public List<PicklistOption> programTypeOptions;
        @AuraEnabled public List<PicklistOption> leadSourceOptions;
        @AuraEnabled public List<PicklistOption> opportunitySourceOptions;
        @AuraEnabled public List<PicklistOption> ownerRoleOptions;
        @AuraEnabled public List<PicklistOption> typeOptions;
    }

    public class SaveContactsRequest {
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public String contactsJson { get; set; }
    }

    public class SaveContactsResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public List<String> errorMessages;
        @AuraEnabled public String diagnostics;

        @AuraEnabled public String contactRecordsJson;
        @AuraEnabled public String opportunityContactSeedJson;
        @AuraEnabled public Integer contactCount;
        @AuraEnabled public Integer signerContactCount;
    }

    public class SubmitRequest {
        @AuraEnabled public Id accountId { get; set; }

        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String accountPhone { get; set; }
        @AuraEnabled public String billingStreet { get; set; }
        @AuraEnabled public String billingCity { get; set; }
        @AuraEnabled public String billingState { get; set; }
        @AuraEnabled public String billingPostalCode { get; set; }
        @AuraEnabled public String billingCountry { get; set; }
        @AuraEnabled public String shippingStreet { get; set; }
        @AuraEnabled public String shippingCity { get; set; }
        @AuraEnabled public String shippingState { get; set; }
        @AuraEnabled public String shippingPostalCode { get; set; }
        @AuraEnabled public String shippingCountry { get; set; }

        @AuraEnabled public String contactsJson { get; set; }
        @AuraEnabled public String opportunityContactsJson { get; set; }

        @AuraEnabled public String finalNextAction { get; set; }

        @AuraEnabled public String opportunityCloseDate { get; set; }
        @AuraEnabled public String opportunityStageName { get; set; }
        @AuraEnabled public String opportunityProgramType { get; set; }
        @AuraEnabled public String opportunityProgramBaseSelection { get; set; }
        @AuraEnabled public Boolean opportunityDocumentsReady { get; set; }
        @AuraEnabled public String opportunityLeadSource { get; set; }
        @AuraEnabled public String opportunitySource { get; set; }
        @AuraEnabled public String opportunityNextStep { get; set; }
        @AuraEnabled public String opportunityNextStepDate { get; set; }
        @AuraEnabled public String opportunityOwnerRole { get; set; }
        @AuraEnabled public String opportunityRecordTypeId { get; set; }
        @AuraEnabled public String opportunityType { get; set; }

        @AuraEnabled public String selectedVendorProgramId { get; set; }
        @AuraEnabled public String selectedVendorId { get; set; }
        @AuraEnabled public String selectedRetailOption { get; set; }
        @AuraEnabled public String selectedBusinessVertical { get; set; }
    }

    public class SubmitResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public List<String> stageErrors;
        @AuraEnabled public String diagnostics;
    }

    private class OnboardingFlags {
        Boolean hasAnyOnboardingForAccount = false;
        Boolean hasChuzoOnboardingForOpportunity = false;
        Boolean hasNdaOnboardingForOpportunity = false;
        Boolean hasNonChuzoOnboardingForOpportunity = false;
    }

    private class ContactPayload {
        List<Contact> contacts = new List<Contact>();
        List<AccountContactRelation> relationships = new List<AccountContactRelation>();
        String flowErrorMessage;
    }

    private class VendorProgramResolutionResult {
        Vendor_Customization__c vendorProgramRecord;
        String errorMessage;
    }

    @AuraEnabled(cacheable=false)
    public static LoadContextResponse loadContext(Id accountId, String preloadedContextJson) {
        LoadContextResponse response = new LoadContextResponse();
        response.success = false;

        if (accountId == null) {
            response.errorMessage = 'Account Id is required.';
            return response;
        }

        try {
            Map<String, Object> preloadedContext = parsePreloadedContext(preloadedContextJson);
            Account accountRecord = [
                SELECT
                    Id,
                    Name,
                    Phone,
                    BillingStreet,
                    BillingCity,
                    BillingState,
                    BillingStateCode,
                    BillingPostalCode,
                    BillingCountry,
                    BillingCountryCode,
                    ShippingStreet,
                    ShippingCity,
                    ShippingState,
                    ShippingStateCode,
                    ShippingPostalCode,
                    ShippingCountry,
                    ShippingCountryCode
                FROM Account
                WHERE Id = :accountId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            response.accountRecord = accountRecord;
            String preloadedVendorOptions = asString(preloadedContext.get('availableVendorOptionString'));
            response.availableVendorOptionString = String.isBlank(preloadedVendorOptions)
                ? loadVendorOptionsJson(accountId)
                : preloadedVendorOptions;

            ContactPayload allContactPayload = loadContactsForAccount(accountRecord, false);
            response.contactRecordsJson = buildEditorJson(
                CONFIG_CONTACT_ON_ACCOUNT,
                allContactPayload.contacts,
                allContactPayload.relationships
            );
            response.contactCount = allContactPayload.contacts.size();

            ContactPayload signerPayload = loadContactsForAccount(accountRecord, true);
            response.opportunityContactSeedJson = buildEditorJson(
                CONFIG_CONTACT_ON_OPPORTUNITY,
                signerPayload.contacts,
                new List<AccountContactRelation>()
            );
            response.signerContactCount = signerPayload.contacts.size();

            OnboardingFlags onboardingFlags = resolveOnboardingFlags(accountRecord, preloadedContext);
            response.hasAnyOnboardingForAccount = onboardingFlags.hasAnyOnboardingForAccount;
            response.hasChuzoOnboardingForOpportunity = onboardingFlags.hasChuzoOnboardingForOpportunity;
            response.hasNdaOnboardingForOpportunity = onboardingFlags.hasNdaOnboardingForOpportunity;
            response.hasNonChuzoOnboardingForOpportunity = onboardingFlags.hasNonChuzoOnboardingForOpportunity;
            response.isUserSpecial = resolveIsUserSpecial();

            Map<String, Object> routing = resolveRouting(onboardingFlags, response.isUserSpecial, preloadedContext);
            response.finalNextAction = asString(routing.get('finalNextAction'));
            response.showAgreementChoice = asBoolean(routing.get('showAgreementChoice'));
            response.showPersonalGuarantee = asBoolean(routing.get('showPersonalGuarantee'));
            response.showVendorSelector = asBoolean(routing.get('showVendorSelector'));
            response.showVerifyAccount = asBoolean(routing.get('showVerifyAccount'));
            response.ruleErrorMessage = asString(routing.get('ruleErrorMessage'));

            String preloadedRecordTypeId = asString(preloadedContext.get('opportunityRecordTypeId'));
            response.opportunityRecordTypeId = String.isBlank(preloadedRecordTypeId)
                ? getProgramOpportunityRecordTypeId()
                : preloadedRecordTypeId;
            response.defaultCloseDate = String.valueOf(Date.today().addDays(DEFAULT_OPPORTUNITY_CLOSE_DAYS));
            response.defaultNextStepDate = String.valueOf(Date.today().addDays(DEFAULT_OPPORTUNITY_CLOSE_DAYS));

            response.stageOptions = getPicklistOptions(Opportunity.StageName);
            response.programTypeOptions = getPicklistOptions(Opportunity.Program_Type__c);
            response.leadSourceOptions = getPicklistOptions(Opportunity.LeadSource);
            response.opportunitySourceOptions = getPicklistOptions(Opportunity.Opportunity__c);
            response.ownerRoleOptions = getPicklistOptions(Opportunity.Owner__c);
            response.typeOptions = getPicklistOptions(Opportunity.Type);

            response.defaultStageName = firstPreferredValue(response.stageOptions, DEFAULT_STAGE);
            response.defaultProgramType = firstPreferredValue(response.programTypeOptions, DEFAULT_PROGRAM_TYPE);
            response.defaultProgramBaseSelection = DEFAULT_PROGRAM_BASE_SELECTION;
            response.defaultLeadSource = firstValue(response.leadSourceOptions);
            response.defaultOpportunitySource = firstValue(response.opportunitySourceOptions);
            response.defaultOwnerRole = firstValue(response.ownerRoleOptions);
            response.defaultType = firstPreferredValue(response.typeOptions, DEFAULT_OPPORTUNITY_TYPE);

            response.success = true;
            return response;
        } catch (Exception ex) {
            response.errorMessage = ExceptionUtil.unexpectedUserMessage(
                'ExpOpportunityCreateRecord.loadContext',
                ex,
                'Unable to load onboarding create context.'
            );
            return response;
        }
    }

    @AuraEnabled(cacheable=false)
    public static SaveContactsResponse saveContactsAndPrepareOcr(SaveContactsRequest request) {
        SaveContactsResponse response = new SaveContactsResponse();
        response.success = false;
        response.errorMessages = new List<String>();
        Map<String, Object> diagnostics = new Map<String, Object>{
            'method' => 'saveContactsAndPrepareOcr',
            'requestIsNull' => (request == null),
            'requestAccountId' => request == null ? null : String.valueOf(request.accountId),
            'contactsJsonLength' => request == null || request.contactsJson == null
                ? null
                : request.contactsJson.length(),
            'contactsJsonPreview' => truncateForDiagnostics(
                request == null ? null : request.contactsJson
            ),
            'phase' => 'validate_request'
        };

        if (request == null) {
            response.errorMessage = 'Account Id is required.';
            response.diagnostics = serializeDiagnostics(diagnostics);
            return response;
        }
        if (String.isBlank(request.contactsJson)) {
            response.errorMessage = 'Contacts JSON is required.';
            diagnostics.put('phase', 'validation_contacts_json_blank');
            response.diagnostics = serializeDiagnostics(diagnostics);
            return response;
        }

        Id resolvedAccountId = resolveEffectiveAccountId(request.accountId, request.contactsJson);
        diagnostics.put(
            'resolvedAccountId',
            resolvedAccountId == null ? null : String.valueOf(resolvedAccountId)
        );
        if (resolvedAccountId == null) {
            response.errorMessage = 'Account Id is required.';
            diagnostics.put('phase', 'validation_resolved_account_missing');
            response.diagnostics = serializeDiagnostics(diagnostics);
            return response;
        }

        try {
            diagnostics.put('phase', 'upsert_contact_payload');
            List<String> saveErrors = upsertRecordCollectionJson(CONFIG_CONTACT_ON_ACCOUNT, request.contactsJson);
            if (!saveErrors.isEmpty()) {
                response.errorMessages.addAll(saveErrors);
                response.errorMessage = String.join(saveErrors, ' | ');
                diagnostics.put('phase', 'upsert_contact_payload_failed');
                diagnostics.put('errorCount', saveErrors.size());
                diagnostics.put('firstError', saveErrors[0]);
                response.diagnostics = serializeDiagnostics(diagnostics);
                return response;
            }

            Account accountRecord = new Account(Id = resolvedAccountId);

            ContactPayload allContactPayload = loadContactsForAccount(accountRecord, false);
            response.contactRecordsJson = buildEditorJson(
                CONFIG_CONTACT_ON_ACCOUNT,
                allContactPayload.contacts,
                allContactPayload.relationships
            );
            response.contactCount = allContactPayload.contacts.size();

            ContactPayload signerPayload = loadContactsForAccount(accountRecord, true);
            response.opportunityContactSeedJson = buildEditorJson(
                CONFIG_CONTACT_ON_OPPORTUNITY,
                signerPayload.contacts,
                new List<AccountContactRelation>()
            );
            response.signerContactCount = signerPayload.contacts.size();

            response.success = true;
            diagnostics.put('phase', 'success');
            diagnostics.put('contactCount', response.contactCount);
            diagnostics.put('signerContactCount', response.signerContactCount);
            response.diagnostics = serializeDiagnostics(diagnostics);
            return response;
        } catch (Exception ex) {
            response.errorMessage = ExceptionUtil.unexpectedUserMessage(
                'ExpOpportunityCreateRecord.saveContactsAndPrepareOcr',
                ex,
                'Unable to save contacts.'
            );
            diagnostics.put('phase', 'exception');
            diagnostics.put('exceptionMessage', ex.getMessage());
            response.diagnostics = serializeDiagnostics(diagnostics);
            return response;
        }
    }

    @AuraEnabled(cacheable=false)
    public static SubmitResponse submitCreateRecord(SubmitRequest request) {
        SubmitResponse response = new SubmitResponse();
        response.success = false;
        response.stageErrors = new List<String>();
        Map<String, Object> diagnostics = new Map<String, Object>{
            'method' => 'submitCreateRecord',
            'requestIsNull' => (request == null),
            'requestAccountId' => request == null ? null : String.valueOf(request.accountId),
            'contactsJsonLength' => request == null || request.contactsJson == null
                ? null
                : request.contactsJson.length(),
            'opportunityContactsJsonLength' => request == null || request.opportunityContactsJson == null
                ? null
                : request.opportunityContactsJson.length(),
            'phase' => 'validate_request'
        };

        if (request == null) {
            response.errorMessage = 'Account Id is required.';
            response.diagnostics = serializeDiagnostics(diagnostics);
            return response;
        }
        if (String.isBlank(request.contactsJson)) {
            response.errorMessage = 'Contacts must be saved before submission.';
            diagnostics.put('phase', 'validation_contacts_json_blank');
            response.diagnostics = serializeDiagnostics(diagnostics);
            return response;
        }
        if (String.isBlank(request.opportunityContactsJson)) {
            response.errorMessage = 'Opportunity contact roles are required.';
            diagnostics.put('phase', 'validation_ocr_json_blank');
            response.diagnostics = serializeDiagnostics(diagnostics);
            return response;
        }

        Id resolvedAccountId = resolveEffectiveAccountId(request.accountId, request.contactsJson);
        diagnostics.put(
            'resolvedAccountId',
            resolvedAccountId == null ? null : String.valueOf(resolvedAccountId)
        );
        if (resolvedAccountId == null) {
            response.errorMessage = 'Account Id is required.';
            diagnostics.put('phase', 'validation_resolved_account_missing');
            response.diagnostics = serializeDiagnostics(diagnostics);
            return response;
        }

        if (
            PROGRAM_BASE_SELECTION_WITH_CHUZO_NO_PG == request.opportunityProgramBaseSelection &&
            resolveIsUserSpecial() != true
        ) {
            response.errorMessage =
                'Program Base App with Chuzo (No Personal Guarantee) requires ' +
                SPECIAL_CHUZO_PERMISSION_SET_API_NAME + '.';
            diagnostics.put('phase', 'validation_special_chuzo_permission_missing');
            response.diagnostics = serializeDiagnostics(diagnostics);
            return response;
        }

        try {
            diagnostics.put('phase', 'upsert_contact_payload');
            List<String> contactErrors = upsertRecordCollectionJson(CONFIG_CONTACT_ON_ACCOUNT, request.contactsJson);
            if (!contactErrors.isEmpty()) {
                response.stageErrors.addAll(contactErrors);
                response.errorMessage = String.join(contactErrors, ' | ');
                diagnostics.put('phase', 'upsert_contact_payload_failed');
                diagnostics.put('errorCount', contactErrors.size());
                diagnostics.put('firstError', contactErrors[0]);
                response.diagnostics = serializeDiagnostics(diagnostics);
                return response;
            }

            updateAccountFromRequest(resolvedAccountId, request);

            Vendor_Customization__c vendorProgramRecord = buildVendorProgramFromRequest(request);
            if (
                vendorProgramRecord == null &&
                !hasAnyVendorSelectionInputs(request)
            ) {
                VendorProgramResolutionResult defaultVendorResult =
                    resolveDefaultVendorProgram(request.finalNextAction);
                if (!String.isBlank(defaultVendorResult.errorMessage)) {
                    response.errorMessage = defaultVendorResult.errorMessage;
                    response.stageErrors.add(defaultVendorResult.errorMessage);
                    return response;
                }
                vendorProgramRecord = defaultVendorResult.vendorProgramRecord;
            }

            ExpOpportunityCreateAsyncService.QueueRequest chainRequest =
                new ExpOpportunityCreateAsyncService.QueueRequest();
            chainRequest.AccountRecord = new Account(Id = resolvedAccountId);
            chainRequest.OpportunityRecord = buildOpportunityFromRequest(request);
            chainRequest.VendorProgramRecord = vendorProgramRecord;
            chainRequest.ContactsToCreateJSONString = request.contactsJson;
            chainRequest.OpportunityContactRecordsJSON = request.opportunityContactsJson;
            chainRequest.CreateContactsInQueue = false;

            List<ExpOpportunityCreateAsyncService.QueueResult> results =
                queueOpportunityCreateChain(
                    new List<ExpOpportunityCreateAsyncService.QueueRequest>{ chainRequest }
                );

            if (results == null || results.isEmpty()) {
                response.errorMessage = 'Create chain returned no result.';
                diagnostics.put('phase', 'queue_result_missing');
                response.diagnostics = serializeDiagnostics(diagnostics);
                return response;
            }

            ExpOpportunityCreateAsyncService.QueueResult chainResult = results[0];
            response.message = chainResult.message;

            if (chainResult.queued == true) {
                response.success = true;
                diagnostics.put('phase', 'success');
                diagnostics.put('queueMessage', chainResult.message);
                response.diagnostics = serializeDiagnostics(diagnostics);
                return response;
            }

            response.errorMessage = String.isBlank(chainResult.message)
                ? 'Create chain failed.'
                : chainResult.message;
            response.stageErrors.add(response.errorMessage);
            diagnostics.put('phase', 'queue_result_not_queued');
            diagnostics.put('queueMessage', chainResult.message);
            response.diagnostics = serializeDiagnostics(diagnostics);
            return response;
        } catch (Exception ex) {
            response.errorMessage = ExceptionUtil.unexpectedUserMessage(
                'ExpOpportunityCreateRecord.submitCreateRecord',
                ex,
                'Unable to complete onboarding create request.'
            );
            diagnostics.put('phase', 'exception');
            diagnostics.put('exceptionMessage', ex.getMessage());
            response.diagnostics = serializeDiagnostics(diagnostics);
            return response;
        }
    }

    private static String loadVendorOptionsJson(Id accountId) {
        if (isTestOverrideActive(testVendorOptionsJson)) {
            return testVendorOptionsJson;
        }
        List<String> jsonRows = VendorOnboardingService.getVendorsAsJson(new List<Id>{ accountId });
        if (jsonRows == null || jsonRows.isEmpty() || String.isBlank(jsonRows[0])) {
            return '[]';
        }
        return jsonRows[0];
    }

    private static OnboardingFlags loadOnboardingFlags(Account accountRecord) {
        OnboardingFlags flags = new OnboardingFlags();
        if (isTestOverrideActive(testOnboardingFlowOutputOverride)) {
            flags.hasAnyOnboardingForAccount = asBoolean(testOnboardingFlowOutputOverride.get('HasAnyOboardingForAccount'));
            flags.hasChuzoOnboardingForOpportunity =
                asBoolean(testOnboardingFlowOutputOverride.get('HasChuzoOnboardingForOpportunity'));
            flags.hasNdaOnboardingForOpportunity =
                asBoolean(testOnboardingFlowOutputOverride.get('HasNDAOnboardingForOpportunity'));
            flags.hasNonChuzoOnboardingForOpportunity =
                asBoolean(testOnboardingFlowOutputOverride.get('HasNonChuzoOnboardingForOpportunity'));
            return flags;
        }

        Map<String, Object> inputs = new Map<String, Object>{
            'AccountRecord' => accountRecord
        };
        Flow.Interview interview = Flow.Interview.createInterview(FLOW_GET_ONBOARDING_RECORDS, inputs);
        interview.start();

        flags.hasAnyOnboardingForAccount = asBoolean(interview.getVariableValue('HasAnyOboardingForAccount'));
        flags.hasChuzoOnboardingForOpportunity =
            asBoolean(interview.getVariableValue('HasChuzoOnboardingForOpportunity'));
        flags.hasNdaOnboardingForOpportunity =
            asBoolean(interview.getVariableValue('HasNDAOnboardingForOpportunity'));
        flags.hasNonChuzoOnboardingForOpportunity =
            asBoolean(interview.getVariableValue('HasNonChuzoOnboardingForOpportunity'));

        return flags;
    }

    private static OnboardingFlags resolveOnboardingFlags(
        Account accountRecord,
        Map<String, Object> preloadedContext
    ) {
        if (
            preloadedContext != null &&
            preloadedContext.containsKey('hasAnyOnboardingForAccount') &&
            preloadedContext.containsKey('hasChuzoOnboardingForOpportunity') &&
            preloadedContext.containsKey('hasNdaOnboardingForOpportunity') &&
            preloadedContext.containsKey('hasNonChuzoOnboardingForOpportunity')
        ) {
            OnboardingFlags flags = new OnboardingFlags();
            flags.hasAnyOnboardingForAccount = asBoolean(preloadedContext.get('hasAnyOnboardingForAccount'));
            flags.hasChuzoOnboardingForOpportunity = asBoolean(preloadedContext.get('hasChuzoOnboardingForOpportunity'));
            flags.hasNdaOnboardingForOpportunity = asBoolean(preloadedContext.get('hasNdaOnboardingForOpportunity'));
            flags.hasNonChuzoOnboardingForOpportunity =
                asBoolean(preloadedContext.get('hasNonChuzoOnboardingForOpportunity'));
            return flags;
        }
        return loadOnboardingFlags(accountRecord);
    }

    private static Map<String, Object> resolveRouting(
        OnboardingFlags flags,
        Boolean isUserSpecial,
        Map<String, Object> preloadedContext
    ) {
        if (
            preloadedContext != null &&
            preloadedContext.containsKey('finalNextAction') &&
            preloadedContext.containsKey('showAgreementChoice') &&
            preloadedContext.containsKey('showPersonalGuarantee') &&
            preloadedContext.containsKey('showVendorSelector') &&
            preloadedContext.containsKey('showVerifyAccount')
        ) {
            Map<String, Object> routing = new Map<String, Object>();
            routing.put('finalNextAction', preloadedContext.get('finalNextAction'));
            routing.put('showAgreementChoice', preloadedContext.get('showAgreementChoice'));
            routing.put('showPersonalGuarantee', preloadedContext.get('showPersonalGuarantee'));
            routing.put('showVendorSelector', preloadedContext.get('showVendorSelector'));
            routing.put('showVerifyAccount', preloadedContext.get('showVerifyAccount'));
            routing.put('ruleErrorMessage', preloadedContext.get('ruleErrorMessage'));
            return routing;
        }

        Map<String, Object> breRouting = evaluateOrchestratorRouting(flags, isUserSpecial);
        Map<String, Object> resolvedRouting = new Map<String, Object>();
        resolvedRouting.put('finalNextAction', breRouting.get('FinalNextAction'));
        resolvedRouting.put('showAgreementChoice', breRouting.get('ShowAgreementChoice'));
        resolvedRouting.put('showPersonalGuarantee', breRouting.get('ShowPersonalGuarantee'));
        resolvedRouting.put('showVendorSelector', breRouting.get('ShowVendorSelector'));
        resolvedRouting.put('showVerifyAccount', breRouting.get('ShowVerifyAccount'));
        resolvedRouting.put('ruleErrorMessage', breRouting.get('ErrorMessage'));
        return resolvedRouting;
    }

    private static Map<String, Object> evaluateOrchestratorRouting(
        OnboardingFlags flags,
        Boolean isUserSpecial
    ) {
        if (isTestOverrideActive(testBreFlowOutputOverride)) {
            return new Map<String, Object>(testBreFlowOutputOverride);
        }

        Map<String, Object> outputs = new Map<String, Object>();
        Map<String, Object> inputs = new Map<String, Object>{
            'RuleContext' => BRE_CONTEXT_ONBOARDING_ORCHESTRATOR,
            'HasAnyOnboardingForAccount' => flags.hasAnyOnboardingForAccount,
            'HasChuzoOnboardingForOpportunity' => flags.hasChuzoOnboardingForOpportunity,
            'HasNDAOnboardingForOpportunity' => flags.hasNdaOnboardingForOpportunity,
            'HasNonChuzoOnboardingForOpportunity' => flags.hasNonChuzoOnboardingForOpportunity,
            'IsUserSpecial' => isUserSpecial,
            'IsCoreOnboardingComplete' =>
                (flags.hasChuzoOnboardingForOpportunity && flags.hasNdaOnboardingForOpportunity)
        };

        Flow.Interview interview = Flow.Interview.createInterview(FLOW_BRE_EVALUATE, inputs);
        interview.start();

        outputs.put('FinalNextAction', interview.getVariableValue('FinalNextAction'));
        outputs.put('ShowAgreementChoice', interview.getVariableValue('ShowAgreementChoice'));
        outputs.put('ShowPersonalGuarantee', interview.getVariableValue('ShowPersonalGuarantee'));
        outputs.put('ShowVendorSelector', interview.getVariableValue('ShowVendorSelector'));
        outputs.put('ShowVerifyAccount', interview.getVariableValue('ShowVerifyAccount'));
        outputs.put('ErrorMessage', interview.getVariableValue('ErrorMessage'));
        return outputs;
    }

    private static ContactPayload loadContactsForAccount(Account accountRecord, Boolean filterForSigners) {
        ContactPayload payload = new ContactPayload();
        Map<String, Object> overrideValues = resolveContactFlowOverride(filterForSigners);
        if (overrideValues != null) {
            payload.contacts = toContactList(overrideValues.get('ContactRecordCollection'));
            payload.relationships = toAccountContactRelationList(overrideValues.get('AccountContactRelationshipCollection'));
            payload.flowErrorMessage = asString(overrideValues.get('errorMessage'));
            return payload;
        }

        Map<String, Object> inputs = new Map<String, Object>{
            'AccountRecord' => accountRecord,
            'FilterForSigners' => filterForSigners
        };

        Flow.Interview interview = Flow.Interview.createInterview(FLOW_GET_CONTACT_RECORDS, inputs);
        interview.start();

        payload.contacts = toContactList(interview.getVariableValue('ContactRecordCollection'));
        payload.relationships =
            toAccountContactRelationList(interview.getVariableValue('AccountContactRelationshipCollection'));
        payload.flowErrorMessage = asString(interview.getVariableValue('errorMessage'));
        return payload;
    }

    private static String buildEditorJson(
        String configKey,
        List<Contact> contacts,
        List<AccountContactRelation> relationships
    ) {
        if (
            Test.isRunningTest() &&
            testEditorJsonByConfig != null &&
            testEditorJsonByConfig.containsKey(configKey)
        ) {
            String overrideValue = testEditorJsonByConfig.get(configKey);
            return String.isBlank(overrideValue) ? '[]' : overrideValue;
        }

        if (contacts == null || contacts.isEmpty()) {
            return '[]';
        }

        RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest jsonRequest =
            new RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest();
        jsonRequest.configKey = configKey;
        jsonRequest.records = toSObjectListFromContacts(contacts);
        if (relationships != null && !relationships.isEmpty()) {
            jsonRequest.relationshipRecords = toSObjectListFromAcr(relationships);
        }

        List<RecordCollectionEditorGetRecordsService.GetRecordsJsonResult> results =
            RecordCollectionEditorGetRecordsService.getRecordsJsonForEditor(
                new List<RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest>{ jsonRequest }
            );

        if (results == null || results.isEmpty()) {
            return '[]';
        }

        RecordCollectionEditorGetRecordsService.GetRecordsJsonResult resultRow = results[0];
        if (!String.isBlank(resultRow.errorMessage)) {
            return '[]';
        }

        return String.isBlank(resultRow.recordsJson) ? '[]' : resultRow.recordsJson;
    }

    private static List<String> upsertRecordCollectionJson(String configKey, String recordsJson) {
        List<String> errors = new List<String>();
        if (
            Test.isRunningTest() &&
            testUpsertErrorsByConfig != null &&
            testUpsertErrorsByConfig.containsKey(configKey)
        ) {
            return copyStringList(testUpsertErrorsByConfig.get(configKey));
        }

        if (String.isBlank(recordsJson)) {
            errors.add('Records JSON is required.');
            return errors;
        }

        RecordCollectionEditorConfigService.CreateFromJsonRequest createRequest =
            new RecordCollectionEditorConfigService.CreateFromJsonRequest();
        createRequest.configKey = configKey;
        createRequest.recordsJson = recordsJson;

        List<RecordCollectionEditorConfigService.CreateFromJsonResult> results =
            RecordCollectionEditorConfigService.createRecordsFromJson(
                new List<RecordCollectionEditorConfigService.CreateFromJsonRequest>{ createRequest }
            );

        if (results == null || results.isEmpty()) {
            errors.add('Record create request did not return a result.');
            return errors;
        }

        if (results[0].errorMessages != null && !results[0].errorMessages.isEmpty()) {
            errors.addAll(results[0].errorMessages);
        }
        return errors;
    }

    private static void updateAccountFromRequest(Id accountId, SubmitRequest request) {
        Account accountToUpdate = new Account(Id = accountId);
        accountToUpdate.Name = request.accountName;
        accountToUpdate.Phone = request.accountPhone;

        accountToUpdate.BillingStreet = request.billingStreet;
        accountToUpdate.BillingCity = request.billingCity;
        accountToUpdate.BillingPostalCode = request.billingPostalCode;
        assignAddressCountryAndState(
            accountToUpdate,
            true,
            request.billingCountry,
            request.billingState
        );

        accountToUpdate.ShippingStreet = request.shippingStreet;
        accountToUpdate.ShippingCity = request.shippingCity;
        accountToUpdate.ShippingPostalCode = request.shippingPostalCode;
        assignAddressCountryAndState(
            accountToUpdate,
            false,
            request.shippingCountry,
            request.shippingState
        );
        List<SObject> sanitizedForUpdate = Security.stripInaccessible(
            AccessType.UPDATABLE,
            new List<Account>{ accountToUpdate }
        ).getRecords();
        if (!sanitizedForUpdate.isEmpty()) {
            update (List<Account>) sanitizedForUpdate;
        }
    }

    private static Id resolveEffectiveAccountId(Id explicitAccountId, String contactsJson) {
        if (explicitAccountId != null) {
            return explicitAccountId;
        }
        return extractAccountIdFromContactsJson(contactsJson);
    }

    private static Id extractAccountIdFromContactsJson(String contactsJson) {
        if (String.isBlank(contactsJson)) {
            return null;
        }

        try {
            Object parsed = JSON.deserializeUntyped(contactsJson);
            if (!(parsed instanceof List<Object>)) {
                return null;
            }

            List<Object> rows = (List<Object>) parsed;
            for (Object rowRaw : rows) {
                Id candidate = extractAccountIdFromContactsRow(rowRaw);
                if (candidate != null) {
                    return candidate;
                }
            }
        } catch (Exception ex) {
            return null;
        }
        return null;
    }

    private static Id extractAccountIdFromContactsRow(Object rowRaw) {
        if (!(rowRaw instanceof Map<String, Object>)) {
            return null;
        }

        Map<String, Object> row = (Map<String, Object>) rowRaw;
        Id directCandidate = coerceToId(row.get('AccountId'));
        if (directCandidate != null) {
            return directCandidate;
        }

        Id lowercaseCandidate = coerceToId(row.get('accountId'));
        if (lowercaseCandidate != null) {
            return lowercaseCandidate;
        }

        Object childRaw = row.get('child');
        if (!(childRaw instanceof Map<String, Object>)) {
            return null;
        }

        Map<String, Object> child = (Map<String, Object>) childRaw;
        Id childCandidate = coerceToId(child.get('AccountId'));
        if (childCandidate != null) {
            return childCandidate;
        }

        return coerceToId(child.get('accountId'));
    }

    private static Id coerceToId(Object rawValue) {
        if (rawValue == null) {
            return null;
        }

        String candidate = String.valueOf(rawValue).trim();
        if (String.isBlank(candidate)) {
            return null;
        }
        if (!Pattern.matches('^[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?$', candidate)) {
            return null;
        }

        try {
            return (Id) candidate;
        } catch (Exception ex) {
            return null;
        }
    }

    private static void assignAddressCountryAndState(
        Account accountRecord,
        Boolean isBilling,
        String countryInput,
        String stateInput
    ) {
        String normalizedCountry = normalizeAddressToken(countryInput);
        String normalizedState = normalizeAddressToken(stateInput);
        Boolean hasCountry = !String.isBlank(normalizedCountry);
        Boolean hasState = !String.isBlank(normalizedState);
        Boolean countryIsCode = hasCountry && looksLikeCountryCode(normalizedCountry);
        Boolean stateIsCode = hasState && looksLikeStateCode(normalizedState);

        if (isBilling) {
            if (hasCountry) {
                if (countryIsCode) {
                    accountRecord.BillingCountryCode = normalizedCountry;
                } else {
                    accountRecord.BillingCountry = normalizedCountry;
                }
            }
            if (hasState) {
                if (stateIsCode && (countryIsCode || !hasCountry)) {
                    accountRecord.BillingStateCode = normalizedState;
                } else {
                    accountRecord.BillingState = normalizedState;
                }
            }
            return;
        }

        if (hasCountry) {
            if (countryIsCode) {
                accountRecord.ShippingCountryCode = normalizedCountry;
            } else {
                accountRecord.ShippingCountry = normalizedCountry;
            }
        }
        if (hasState) {
            if (stateIsCode && (countryIsCode || !hasCountry)) {
                accountRecord.ShippingStateCode = normalizedState;
            } else {
                accountRecord.ShippingState = normalizedState;
            }
        }
    }

    private static String normalizeAddressToken(String rawValue) {
        if (String.isBlank(rawValue)) {
            return null;
        }
        return rawValue.trim();
    }

    private static Boolean looksLikeCountryCode(String rawValue) {
        if (String.isBlank(rawValue)) {
            return false;
        }
        String candidate = rawValue.trim();
        return Pattern.matches('^[A-Z]{2}$', candidate);
    }

    private static Boolean looksLikeStateCode(String rawValue) {
        if (String.isBlank(rawValue)) {
            return false;
        }
        String candidate = rawValue.trim();
        return Pattern.matches('^[A-Z0-9]{1,3}$', candidate);
    }

    private static Opportunity buildOpportunityFromRequest(SubmitRequest request) {
        Date closeDate = parseDateOrDefault(
            request.opportunityCloseDate,
            Date.today().addDays(DEFAULT_OPPORTUNITY_CLOSE_DAYS)
        );
        Date nextStepDate = parseDateOrDefault(
            request.opportunityNextStepDate,
            Date.today().addDays(DEFAULT_OPPORTUNITY_CLOSE_DAYS)
        );

        Opportunity opportunityRecord = new Opportunity();
        opportunityRecord.CloseDate = closeDate;
        opportunityRecord.StageName = String.isBlank(request.opportunityStageName)
            ? DEFAULT_STAGE
            : request.opportunityStageName;
        opportunityRecord.Program_Type__c = String.isBlank(request.opportunityProgramType)
            ? DEFAULT_PROGRAM_TYPE
            : request.opportunityProgramType;
        opportunityRecord.Program_Base_App_Selection__c =
            String.isBlank(request.opportunityProgramBaseSelection)
                ? DEFAULT_PROGRAM_BASE_SELECTION
                : request.opportunityProgramBaseSelection;
        opportunityRecord.Documents_Ready__c = request.opportunityDocumentsReady == true;
        opportunityRecord.LeadSource = request.opportunityLeadSource;
        opportunityRecord.Opportunity__c = request.opportunitySource;
        opportunityRecord.NextStep = request.opportunityNextStep;
        opportunityRecord.Next_Step_Date__c = nextStepDate;
        opportunityRecord.RecordTypeId = String.isBlank(request.opportunityRecordTypeId)
            ? getProgramOpportunityRecordTypeId()
            : request.opportunityRecordTypeId;
        opportunityRecord.Type = request.opportunityType;
        opportunityRecord.Owner__c = request.opportunityOwnerRole;

        if (isVendorProgramPath(request) && String.isBlank(request.opportunityProgramBaseSelection)) {
            opportunityRecord.Program_Base_App_Selection__c = DEFAULT_VENDOR_PATH_PROGRAM_BASE_SELECTION;
        }

        return opportunityRecord;
    }

    private static Vendor_Customization__c buildVendorProgramFromRequest(SubmitRequest request) {
        if (!String.isBlank(request.selectedVendorProgramId)) {
            return new Vendor_Customization__c(Id = request.selectedVendorProgramId);
        }

        if (
            String.isBlank(request.selectedVendorId) ||
            String.isBlank(request.selectedRetailOption) ||
            String.isBlank(request.selectedBusinessVertical)
        ) {
            return null;
        }

        return new Vendor_Customization__c(
            Vendor__c = request.selectedVendorId,
            Retail_Option__c = request.selectedRetailOption,
            Business_Vertical__c = request.selectedBusinessVertical
        );
    }

    private static Boolean isVendorProgramPath(SubmitRequest request) {
        if (request == null || String.isBlank(request.finalNextAction)) {
            return false;
        }
        return request.finalNextAction == 'CREATE_VENDOR_PROGRAM_ONBOARDING';
    }

    private static Boolean hasAnyVendorSelectionInputs(SubmitRequest request) {
        if (request == null) {
            return false;
        }
        return
            !String.isBlank(request.selectedVendorProgramId) ||
            !String.isBlank(request.selectedVendorId) ||
            !String.isBlank(request.selectedRetailOption) ||
            !String.isBlank(request.selectedBusinessVertical);
    }

    private static VendorProgramResolutionResult resolveDefaultVendorProgram(String scenarioKey) {
        VendorProgramResolutionResult result = new VendorProgramResolutionResult();

        if (String.isBlank(scenarioKey)) {
            return result;
        }

        if (Test.isRunningTest()) {
            if (!String.isBlank(testDefaultVendorProgramErrorOverride)) {
                result.errorMessage = testDefaultVendorProgramErrorOverride;
                return result;
            }
            if (testDefaultVendorProgramOverride != null) {
                result.vendorProgramRecord = testDefaultVendorProgramOverride;
                return result;
            }
        }

        try {
            OnboardingDefaultVendorProgramInvocable.ScenarioRequest requestRow =
                new OnboardingDefaultVendorProgramInvocable.ScenarioRequest();
            requestRow.scenarioKey = scenarioKey;

            List<OnboardingDefaultVendorProgramInvocable.VendorProgramResult> outputs =
                OnboardingDefaultVendorProgramInvocable.getDefaultVendorProgram(
                    new List<OnboardingDefaultVendorProgramInvocable.ScenarioRequest>{ requestRow }
                );

            if (outputs == null || outputs.isEmpty()) {
                result.errorMessage =
                    'Unable to resolve default Vendor Program for scenario: ' + scenarioKey;
                return result;
            }

            OnboardingDefaultVendorProgramInvocable.VendorProgramResult outputRow = outputs[0];
            if (!String.isBlank(outputRow.errorMessage)) {
                result.errorMessage = outputRow.errorMessage;
                return result;
            }

            result.vendorProgramRecord = outputRow.vendorProgramRecord;
            return result;
        } catch (Exception ex) {
            result.errorMessage = ExceptionUtil.unexpectedUserMessage(
                'ExpOpportunityCreateRecord.resolveDefaultVendorProgram',
                ex,
                'Unable to resolve default Vendor Program.'
            );
            return result;
        }
    }

    private static String getProgramOpportunityRecordTypeId() {
        if (isTestOverrideActive(testProgramOpportunityRecordTypeId)) {
            return testProgramOpportunityRecordTypeId;
        }

        List<RecordType> rows = [
            SELECT Id
            FROM RecordType
            WHERE SobjectType = 'Opportunity'
              AND Name = :PROGRAM_OPPORTUNITY_RECORD_TYPE_NAME
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return rows.isEmpty() ? null : String.valueOf(rows[0].Id);
    }

    private static Date parseDateOrDefault(String rawDate, Date fallbackDate) {
        if (String.isBlank(rawDate)) {
            return fallbackDate;
        }
        try {
            return Date.valueOf(rawDate.trim());
        } catch (Exception ex) {
            return fallbackDate;
        }
    }

    private static List<PicklistOption> getPicklistOptions(Schema.SObjectField fieldRef) {
        List<PicklistOption> options = new List<PicklistOption>();
        if (fieldRef == null) {
            return options;
        }

        for (Schema.PicklistEntry entry : fieldRef.getDescribe().getPicklistValues()) {
            if (!entry.isActive()) {
                continue;
            }
            options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
        }
        return options;
    }

    private static String firstPreferredValue(List<PicklistOption> options, String preferredValue) {
        if (options == null || options.isEmpty()) {
            return null;
        }
        if (!String.isBlank(preferredValue)) {
            for (PicklistOption option : options) {
                if (option.value == preferredValue) {
                    return option.value;
                }
            }
        }
        return options[0].value;
    }

    private static String firstValue(List<PicklistOption> options) {
        return (options == null || options.isEmpty()) ? null : options[0].value;
    }

    private static List<Contact> toContactList(Object rawValue) {
        List<Contact> contacts = new List<Contact>();
        if (rawValue == null) {
            return contacts;
        }
        try {
            List<SObject> rows = (List<SObject>) rawValue;
            for (SObject row : rows) {
                contacts.add((Contact) row);
            }
        } catch (Exception ex) {
            return contacts;
        }
        return contacts;
    }

    private static List<AccountContactRelation> toAccountContactRelationList(Object rawValue) {
        List<AccountContactRelation> rowsOut = new List<AccountContactRelation>();
        if (rawValue == null) {
            return rowsOut;
        }
        try {
            List<SObject> rows = (List<SObject>) rawValue;
            for (SObject row : rows) {
                rowsOut.add((AccountContactRelation) row);
            }
        } catch (Exception ex) {
            return rowsOut;
        }
        return rowsOut;
    }

    private static List<SObject> toSObjectListFromContacts(List<Contact> contacts) {
        List<SObject> rows = new List<SObject>();
        if (contacts == null) {
            return rows;
        }
        for (Contact row : contacts) {
            rows.add(row);
        }
        return rows;
    }

    private static List<SObject> toSObjectListFromAcr(List<AccountContactRelation> relations) {
        List<SObject> rows = new List<SObject>();
        if (relations == null) {
            return rows;
        }
        for (AccountContactRelation row : relations) {
            rows.add(row);
        }
        return rows;
    }

    private static Map<String, Object> parsePreloadedContext(String preloadedContextJson) {
        if (String.isBlank(preloadedContextJson)) {
            return new Map<String, Object>();
        }

        try {
            Object parsedValue = JSON.deserializeUntyped(preloadedContextJson);
            if (parsedValue instanceof Map<String, Object>) {
                return (Map<String, Object>) parsedValue;
            }
        } catch (Exception ex) {
            return new Map<String, Object>();
        }

        return new Map<String, Object>();
    }

    private static Boolean asBoolean(Object rawValue) {
        if (rawValue == null) {
            return false;
        }
        if (rawValue instanceof Boolean) {
            return (Boolean) rawValue;
        }
        return 'true'.equalsIgnoreCase(String.valueOf(rawValue));
    }

    private static String asString(Object rawValue) {
        return rawValue == null ? null : String.valueOf(rawValue);
    }

    private static Boolean resolveIsUserSpecial() {
        if (Test.isRunningTest() && testIsUserSpecialOverride != null) {
            return testIsUserSpecialOverride;
        }
        Integer assignmentCount = [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSet.Name = :SPECIAL_CHUZO_PERMISSION_SET_API_NAME
            WITH SECURITY_ENFORCED
        ];
        return assignmentCount > 0;
    }

    private static Map<String, Object> resolveContactFlowOverride(Boolean filterForSigners) {
        if (!Test.isRunningTest()) {
            return null;
        }

        if (filterForSigners == true && testSignerContactsFlowOutputOverride != null) {
            return new Map<String, Object>(testSignerContactsFlowOutputOverride);
        }
        if (filterForSigners != true && testAllContactsFlowOutputOverride != null) {
            return new Map<String, Object>(testAllContactsFlowOutputOverride);
        }
        return null;
    }

    private static List<ExpOpportunityCreateAsyncService.QueueResult> queueOpportunityCreateChain(
        List<ExpOpportunityCreateAsyncService.QueueRequest> requests
    ) {
        if (Test.isRunningTest() && testQueueResultsOverride != null) {
            return new List<ExpOpportunityCreateAsyncService.QueueResult>(testQueueResultsOverride);
        }

        return ExpOpportunityCreateAsyncService.queueOpportunityCreateChain(requests);
    }

    private static List<String> copyStringList(List<String> source) {
        if (source == null) {
            return new List<String>();
        }
        return new List<String>(source);
    }

    private static Boolean isTestOverrideActive(Object overrideValue) {
        return Test.isRunningTest() && overrideValue != null;
    }

    private static String truncateForDiagnostics(String rawValue) {
        if (String.isBlank(rawValue)) {
            return rawValue;
        }
        Integer maxLength = 250;
        return rawValue.length() <= maxLength
            ? rawValue
            : rawValue.substring(0, maxLength) + '...';
    }

    private static String serializeDiagnostics(Map<String, Object> diagnostics) {
        if (diagnostics == null) {
            return null;
        }
        try {
            return JSON.serialize(diagnostics);
        } catch (Exception ex) {
            return '{"error":"Unable to serialize diagnostics"}';
        }
    }
}
