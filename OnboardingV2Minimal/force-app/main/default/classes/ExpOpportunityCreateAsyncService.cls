public with sharing class ExpOpportunityCreateAsyncService {
    private class FlowOutputException extends Exception {}
    private class QueuePayload {
        Account accountRecord;
        Opportunity opportunityRecord;
        Vendor_Customization__c vendorProgramRecord;
        String contactsToCreateJson;
        String opportunityContactsJson;
        Boolean createContactsInQueue;

        QueuePayload(
            Account accountRecord,
            Opportunity opportunityRecord,
            Vendor_Customization__c vendorProgramRecord,
            String contactsToCreateJson,
            String opportunityContactsJson,
            Boolean createContactsInQueue
        ) {
            this.accountRecord = accountRecord;
            this.opportunityRecord = opportunityRecord;
            this.vendorProgramRecord = vendorProgramRecord;
            this.contactsToCreateJson = contactsToCreateJson;
            this.opportunityContactsJson = opportunityContactsJson;
            this.createContactsInQueue = createContactsInQueue;
        }
    }

    public class QueueRequest {
        @InvocableVariable(required=true label='Account Record')
        public Account AccountRecord;

        @InvocableVariable(required=true label='Opportunity Record')
        public Opportunity OpportunityRecord;

        @InvocableVariable(label='Vendor Program Record')
        public Vendor_Customization__c VendorProgramRecord;

        @InvocableVariable(label='Contacts To Create JSON')
        public String ContactsToCreateJSONString;

        @InvocableVariable(label='Opportunity Contact Records JSON')
        public String OpportunityContactRecordsJSON;

        @InvocableVariable(label='Create Contacts In Queue')
        public Boolean CreateContactsInQueue;
    }

    public class QueueResult {
        @InvocableVariable(label='Queued')
        public Boolean queued;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(
        label='Queue Opportunity Create Chain'
        description='Runs the post-screen Opportunity/OCR/Contract/Onboarding create chain synchronously by default; optional async queueing remains available when CreateContactsInQueue is true.'
    )
    public static List<QueueResult> queueOpportunityCreateChain(List<QueueRequest> requests) {
        List<QueueResult> results = new List<QueueResult>();
        if (requests == null) {
            return results;
        }

        List<QueuePayload> asyncPayloads = new List<QueuePayload>();
        List<Integer> asyncResultIndexes = new List<Integer>();

        for (Integer requestIndex = 0; requestIndex < requests.size(); requestIndex++) {
            QueueRequest requestItem = requests[requestIndex];
            QueueResult resultItem = new QueueResult();
            resultItem.queued = false;

            if (requestItem == null || requestItem.AccountRecord == null || requestItem.OpportunityRecord == null) {
                resultItem.message = 'AccountRecord and OpportunityRecord are required.';
                results.add(resultItem);
                continue;
            }

            if (requestItem.AccountRecord.Id == null) {
                resultItem.message = 'AccountRecord.Id is required.';
                results.add(resultItem);
                continue;
            }

            if (requestItem.CreateContactsInQueue == true) {
                asyncPayloads.add(new QueuePayload(
                    cloneAccount(requestItem.AccountRecord),
                    cloneOpportunity(requestItem.OpportunityRecord),
                    cloneVendorProgram(requestItem.VendorProgramRecord),
                    requestItem.ContactsToCreateJSONString,
                    requestItem.OpportunityContactRecordsJSON,
                    requestItem.CreateContactsInQueue
                ));
                asyncResultIndexes.add(requestIndex);
                resultItem.queued = true;
                resultItem.message = 'Queued async create chain job: pending id.';
            } else {
                List<String> stageErrors = executeCreateChain(
                    cloneAccount(requestItem.AccountRecord),
                    cloneOpportunity(requestItem.OpportunityRecord),
                    cloneVendorProgram(requestItem.VendorProgramRecord),
                    requestItem.ContactsToCreateJSONString,
                    requestItem.OpportunityContactRecordsJSON,
                    requestItem.CreateContactsInQueue
                );

                if (stageErrors.isEmpty()) {
                    resultItem.queued = true;
                    resultItem.message = 'Create chain completed synchronously.';
                } else {
                    resultItem.queued = false;
                    resultItem.message = 'Create chain failed: ' + String.join(stageErrors, ' | ');
                }
            }
            results.add(resultItem);
        }

        if (!asyncPayloads.isEmpty()) {
            Id jobId = System.enqueueJob(new OpportunityCreateChainQueueable(asyncPayloads));
            for (Integer resultIndex : asyncResultIndexes) {
                results[resultIndex].message = 'Queued async create chain job: ' + String.valueOf(jobId);
            }
        }

        return results;
    }

    private static Account cloneAccount(Account source) {
        return source == null ? null : (Account) source.clone(true, true, false, false);
    }

    private static Opportunity cloneOpportunity(Opportunity source) {
        return source == null ? null : (Opportunity) source.clone(false, true, false, false);
    }

    private static Vendor_Customization__c cloneVendorProgram(Vendor_Customization__c source) {
        return source == null ? null : (Vendor_Customization__c) source.clone(true, true, false, false);
    }

    private class OpportunityCreateChainQueueable implements Queueable, Finalizer {
        private final List<QueuePayload> payloads;

        OpportunityCreateChainQueueable(List<QueuePayload> payloads) {
            this.payloads = new List<QueuePayload>();
            if (payloads != null) {
                this.payloads.addAll(payloads);
            }
        }

        public void execute(QueueableContext context) {
            System.attachFinalizer(this);
            for (QueuePayload payload : payloads) {
                if (payload == null) {
                    continue;
                }
                List<String> stageErrors = executeCreateChain(
                    payload.accountRecord,
                    payload.opportunityRecord,
                    payload.vendorProgramRecord,
                    payload.contactsToCreateJson,
                    payload.opportunityContactsJson,
                    payload.createContactsInQueue
                );

                if (!stageErrors.isEmpty()) {
                    LoggingUtil.error(
                        'ExpOpportunityCreateAsyncService.OpportunityCreateChainQueueable handled stage errors. '
                        + 'AccountId=' + String.valueOf(payload.accountRecord == null ? null : payload.accountRecord.Id)
                        + ', RequestedOpportunityId=' + String.valueOf(payload.opportunityRecord == null ? null : payload.opportunityRecord.Id)
                        + ', Errors=' + String.join(stageErrors, ' | ')
                    );
                }
            }
        }

        public void execute(FinalizerContext context) {
            if (context == null || context.getResult() != ParentJobResult.UNHANDLED_EXCEPTION) {
                return;
            }
            Exception ex = context.getException();
            LoggingUtil.error(
                'ExpOpportunityCreateAsyncService.OpportunityCreateChainQueueable finalizer captured unhandled exception: '
                + (ex == null ? 'Unknown error.' : ex.getTypeName() + ': ' + ex.getMessage())
            );
        }
    }

    @TestVisible
    private static String summarizeException(Exception ex) {
        if (ex == null) {
            return 'Unknown exception.';
        }
        return ex.getTypeName() + ': ' + ex.getMessage();
    }

    @TestVisible
    private static List<String> executeCreateChain(
        Account accountRecord,
        Opportunity opportunityRecord,
        Vendor_Customization__c vendorProgramRecord,
        String contactsToCreateJson,
        String opportunityContactsJson,
        Boolean createContactsInQueue
    ) {
        List<String> stageErrors = new List<String>();
        Opportunity createdOpportunity;
        OpportunityContactRole primaryOpportunityContact;
        Contract contractRecord;
        Onboarding__c onboardingRecord;
        Vendor_Customization__c resolvedVendorProgramRecord = vendorProgramRecord;

        if (createContactsInQueue == true && String.isNotBlank(contactsToCreateJson)) {
            try {
                runCreateContactFlow(contactsToCreateJson);
            } catch (Exception ex) {
                stageErrors.add('Contact create failed: ' + summarizeException(ex));
            }
        }

        try {
            resolvedVendorProgramRecord = resolveVendorProgramForCreate(opportunityRecord, vendorProgramRecord);
        } catch (Exception ex) {
            stageErrors.add('Vendor program resolution failed: ' + summarizeException(ex));
        }

        try {
            resolvedVendorProgramRecord = hydrateVendorProgramForContractCreate(resolvedVendorProgramRecord);
        } catch (Exception ex) {
            stageErrors.add('Vendor program hydration failed: ' + summarizeException(ex));
        }

        try {
            createdOpportunity = runCreateOpportunityFlow(
                accountRecord,
                opportunityRecord,
                resolvedVendorProgramRecord
            );
            if (createdOpportunity == null || createdOpportunity.Id == null) {
                stageErrors.add('Opportunity create returned no OpportunityRecord.Id.');
            }
        } catch (Exception ex) {
            stageErrors.add('Opportunity create failed: ' + summarizeException(ex));
        }

        if (
            createdOpportunity != null &&
            createdOpportunity.Id != null &&
            String.isNotBlank(opportunityContactsJson)
        ) {
            try {
                runCreateOpportunityContactRoleFlow(
                    applyOpportunityId(opportunityContactsJson, createdOpportunity.Id)
                );
            } catch (Exception ex) {
                stageErrors.add('Opportunity contact role create failed: ' + summarizeException(ex));
            }
        }

        if (createdOpportunity != null && createdOpportunity.Id != null) {
            try {
                primaryOpportunityContact = runGetPrimaryOpportunityContactFlow(createdOpportunity);
            } catch (Exception ex) {
                stageErrors.add('Primary opportunity contact lookup failed: ' + summarizeException(ex));
            }
        }

        if (createdOpportunity != null && createdOpportunity.Id != null) {
            try {
                contractRecord = runCreateContractFlow(
                    accountRecord,
                    createdOpportunity,
                    resolvedVendorProgramRecord,
                    primaryOpportunityContact
                );
                if (contractRecord == null || contractRecord.Id == null) {
                    stageErrors.add('Contract create returned no ContractRecord.Id.');
                }
            } catch (Exception ex) {
                stageErrors.add('Contract create failed: ' + summarizeException(ex));
            }
        }

        if (
            createdOpportunity != null &&
            createdOpportunity.Id != null &&
            contractRecord != null &&
            contractRecord.Id != null
        ) {
            try {
                onboardingRecord = runCreateOnboardingFlow(
                    accountRecord,
                    createdOpportunity,
                    resolvedVendorProgramRecord,
                    contractRecord
                );
                if (onboardingRecord == null || onboardingRecord.Id == null) {
                    stageErrors.add('Onboarding create returned no OnboardingRecord.Id.');
                }
            } catch (Exception ex) {
                stageErrors.add('Onboarding create failed: ' + summarizeException(ex));
            }
        } else if (createdOpportunity != null && createdOpportunity.Id != null) {
            stageErrors.add('Onboarding create skipped because contract was not resolved.');
        }

        return stageErrors;
    }

    @TestVisible
    private static void runCreateContactFlow(String contactsJson) {
        Map<String, Object> inputs = new Map<String, Object>{
            'contactsToCreateJSONString' => contactsJson
        };

        Flow.Interview interview = Flow.Interview.createInterview(
            'DOMAIN_OmniSObject_SFL_Create_Contact',
            inputs
        );
        interview.start();
    }

    /**
     * Candidates for DOMAIN_OmniSObject_SFL_CREATE_Opportunity reuse detection (same Account +
     * Vendor Program). Terminal stages (Closed Lost, Denied, Canceled) are excluded in the flow filter.
     */
    @TestVisible
    private static List<Opportunity> loadExistingOpportunitiesForAccountAndVendorProgram(
        Account accountRecord,
        Vendor_Customization__c vendorProgramRecord
    ) {
        if (accountRecord == null || accountRecord.Id == null) {
            return new List<Opportunity>();
        }
        if (vendorProgramRecord == null || vendorProgramRecord.Id == null) {
            return new List<Opportunity>();
        }
        return [
            SELECT Id, Vendor_Customization__c, StageName
            FROM Opportunity
            WHERE AccountId = :accountRecord.Id
              AND Vendor_Customization__c = :vendorProgramRecord.Id
            WITH SECURITY_ENFORCED
        ];
    }

    @TestVisible
    private static Opportunity runCreateOpportunityFlow(
        Account accountRecord,
        Opportunity opportunityRecord,
        Vendor_Customization__c vendorProgramRecord
    ) {
        Opportunity opportunityInput = opportunityRecord == null
            ? new Opportunity()
            : (Opportunity) opportunityRecord.clone(false, true, false, false);

        opportunityInput.Id = null;
        if (accountRecord != null && accountRecord.Id != null) {
            opportunityInput.AccountId = accountRecord.Id;
        }

        Vendor_Customization__c resolvedVendorProgramRecord =
            resolveVendorProgramForCreate(opportunityInput, vendorProgramRecord);

        if (resolvedVendorProgramRecord != null && resolvedVendorProgramRecord.Id != null) {
            opportunityInput.Vendor_Customization__c = resolvedVendorProgramRecord.Id;
        }

        List<Opportunity> opportunityRecordCollection =
            loadExistingOpportunitiesForAccountAndVendorProgram(accountRecord, resolvedVendorProgramRecord);

        Map<String, Object> inputs = new Map<String, Object>{
            'AccountRecord' => accountRecord,
            'OpportunityRecord' => opportunityInput,
            'VendorProgramRecord' => resolvedVendorProgramRecord,
            'OpportunityRecordCollection' => opportunityRecordCollection
        };

        Flow.Interview interview = Flow.Interview.createInterview(
            'DOMAIN_OmniSObject_SFL_CREATE_Opportunity',
            inputs
        );
        interview.start();

        Object outputValue = interview.getVariableValue('OpportunityRecord');
        if (outputValue == null) {
            return null;
        }

        if (outputValue instanceof Opportunity) {
            return (Opportunity) outputValue;
        }

        if (outputValue instanceof SObject) {
            return (Opportunity) outputValue;
        }

        return null;
    }

    @TestVisible
    private static Vendor_Customization__c resolveVendorProgramForCreate(
        Opportunity opportunityRecord,
        Vendor_Customization__c vendorProgramRecord
    ) {
        if (vendorProgramRecord != null && vendorProgramRecord.Id != null) {
            return vendorProgramRecord;
        }

        // First preference: resolve from selected vendor attributes passed from the EXP screenflow.
        if (
            vendorProgramRecord != null &&
            vendorProgramRecord.Vendor__c != null &&
            String.isNotBlank(vendorProgramRecord.Retail_Option__c) &&
            String.isNotBlank(vendorProgramRecord.Business_Vertical__c)
        ) {
            List<Vendor_Customization__c> vendorMatches = [
                SELECT Id,
                    Name,
                    Vendor__c,
                    Retail_Option__c,
                    Business_Vertical__c,
                    Associated_Agreement_Template__c,
                    Contract_Record_Type__c,
                    Contract_Record_Type__r.RecordTypeId__c,
                    Opportunity__c,
                    Opportunity__r.Program_Base_App_Selection__c
                FROM Vendor_Customization__c
                WHERE Vendor__c = :vendorProgramRecord.Vendor__c
                  AND Retail_Option__c = :vendorProgramRecord.Retail_Option__c
                  AND Business_Vertical__c = :vendorProgramRecord.Business_Vertical__c
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (!vendorMatches.isEmpty()) {
                return vendorMatches[0];
            }
        }

        // Required fallback: default to PerfectVision and use the Opportunity program selection.
        String programSelection = normalizeProgramSelectionForFallback(
            opportunityRecord == null ? null : opportunityRecord.Program_Base_App_Selection__c
        );
        if (String.isBlank(programSelection)) {
            return vendorProgramRecord;
        }

        List<Vendor_Customization__c> perfectVisionMatches = [
            SELECT Id,
                Name,
                Vendor__c,
                Retail_Option__c,
                Business_Vertical__c,
                Associated_Agreement_Template__c,
                Contract_Record_Type__c,
                Contract_Record_Type__r.RecordTypeId__c,
                Opportunity__c,
                Opportunity__r.Program_Base_App_Selection__c
            FROM Vendor_Customization__c
            WHERE Vendor__r.Name = 'PerfectVision'
              AND Name = :programSelection
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (!perfectVisionMatches.isEmpty()) {
            return perfectVisionMatches[0];
        }

        return vendorProgramRecord;
    }

    @TestVisible
    private static Vendor_Customization__c hydrateVendorProgramForContractCreate(
        Vendor_Customization__c vendorProgramRecord
    ) {
        if (vendorProgramRecord == null || vendorProgramRecord.Id == null) {
            return vendorProgramRecord;
        }

        List<Vendor_Customization__c> hydrated = [
            SELECT Id,
                Name,
                Vendor__c,
                Retail_Option__c,
                Business_Vertical__c,
                Associated_Agreement_Template__c,
                Contract_Record_Type__c,
                Contract_Record_Type__r.RecordTypeId__c,
                Opportunity__c,
                Opportunity__r.Program_Base_App_Selection__c
            FROM Vendor_Customization__c
            WHERE Id = :vendorProgramRecord.Id
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (!hydrated.isEmpty()) {
            return hydrated[0];
        }

        return vendorProgramRecord;
    }

    @TestVisible
    private static String normalizeProgramSelectionForFallback(String sourceSelection) {
        if (String.isBlank(sourceSelection)) {
            return null;
        }
        if (sourceSelection == 'Base Application - Infrastructure') {
            return 'Program Base Application - with Chuzo (No Personal Guarantee)';
        }
        if (sourceSelection == 'Not Applicable') {
            return 'Program Base Application - without Chuzo';
        }
        return sourceSelection;
    }

    @TestVisible
    private static void runCreateOpportunityContactRoleFlow(String opportunityContactsJsonWithParent) {
        Map<String, Object> inputs = new Map<String, Object>{
            'opportunityContactRecordsJSON' => opportunityContactsJsonWithParent
        };

        Flow.Interview interview = Flow.Interview.createInterview(
            'DOMAIN_OmniSObject_SFL_CREATE_Opportunity_Contact_Role',
            inputs
        );
        interview.start();
    }

    @TestVisible
    private static OpportunityContactRole runGetPrimaryOpportunityContactFlow(Opportunity opportunityRecord) {
        Map<String, Object> inputs = new Map<String, Object>{
            'OpportunityRecord' => opportunityRecord
        };

        Flow.Interview interview = Flow.Interview.createInterview(
            'DOMAIN_OmniSObject_SFL_GET_Primary_Opportunity_Contact',
            inputs
        );
        interview.start();

        Object outputValue = interview.getVariableValue('OpportunityContactRecord');
        if (outputValue == null) {
            return null;
        }

        if (outputValue instanceof OpportunityContactRole) {
            return (OpportunityContactRole) outputValue;
        }

        if (outputValue instanceof SObject) {
            return (OpportunityContactRole) outputValue;
        }

        return null;
    }

    @TestVisible
    private static Contract runCreateContractFlow(
        Account accountRecord,
        Opportunity opportunityRecord,
        Vendor_Customization__c vendorProgramRecord,
        OpportunityContactRole opportunityContactRoleRecord
    ) {
        Map<String, Object> inputs = new Map<String, Object>{
            'AccountRecord' => accountRecord,
            'OpportunityRecord' => opportunityRecord,
            'VendorProgram' => vendorProgramRecord,
            'OpportunityContactRole' => opportunityContactRoleRecord
        };

        Flow.Interview interview = Flow.Interview.createInterview(
            'DOMAIN_OmniSObject_SFL_CREATE_Contract',
            inputs
        );
        interview.start();

        Object outputValue = interview.getVariableValue('ContractRecord');
        Object errorValue = interview.getVariableValue('errorMessage');
        if (outputValue == null) {
            if (errorValue != null && String.isNotBlank(String.valueOf(errorValue))) {
                throw new FlowOutputException(
                    'DOMAIN_OmniSObject_SFL_CREATE_Contract returned no ContractRecord. '
                    + String.valueOf(errorValue)
                );
            }
            return null;
        }

        if (outputValue instanceof Contract) {
            return (Contract) outputValue;
        }

        if (outputValue instanceof SObject) {
            return (Contract) outputValue;
        }

        return null;
    }

    @TestVisible
    private static Onboarding__c runCreateOnboardingFlow(
        Account accountRecord,
        Opportunity opportunityRecord,
        Vendor_Customization__c vendorProgramRecord,
        Contract contractRecord
    ) {
        Map<String, Object> inputs = new Map<String, Object>{
            'AccountRecord' => accountRecord,
            'OpportunityRecord' => opportunityRecord,
            'VendorProgramRecord' => vendorProgramRecord,
            'ContractRecord' => contractRecord
        };

        Flow.Interview interview = Flow.Interview.createInterview(
            'DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record',
            inputs
        );
        interview.start();

        Object outputValue = interview.getVariableValue('OnboardingRecord');
        Object errorValue = interview.getVariableValue('errorMessage');
        if (outputValue == null) {
            if (errorValue != null && String.isNotBlank(String.valueOf(errorValue))) {
                throw new FlowOutputException(
                    'DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record returned no OnboardingRecord. '
                    + String.valueOf(errorValue)
                );
            }
            return null;
        }

        if (outputValue instanceof Onboarding__c) {
            return (Onboarding__c) outputValue;
        }

        if (outputValue instanceof SObject) {
            return (Onboarding__c) outputValue;
        }

        return null;
    }

    @TestVisible
    private static String applyOpportunityId(String recordsJson, Id opportunityId) {
        if (String.isBlank(recordsJson) || opportunityId == null) {
            return recordsJson;
        }

        List<Object> rawRecords = (List<Object>) JSON.deserializeUntyped(recordsJson);
        if (rawRecords == null) {
            return recordsJson;
        }

        for (Integer i = 0; i < rawRecords.size(); i++) {
            Object rawItem = rawRecords[i];
            if (!(rawItem instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> row = (Map<String, Object>) rawItem;
            row.put('OpportunityId', (String) opportunityId);
        }

        return JSON.serialize(rawRecords);
    }
}
