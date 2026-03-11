public with sharing class ExperienceOpportunityCreateAsyncService {
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
        description='Queues post-screen processing for Contact, Opportunity, and Opportunity Contact Role creation using existing DOMAIN flows.'
    )
    public static List<QueueResult> queueOpportunityCreateChain(List<QueueRequest> requests) {
        List<QueueResult> results = new List<QueueResult>();
        if (requests == null) {
            return results;
        }

        for (QueueRequest requestItem : requests) {
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

            Id jobId = System.enqueueJob(
                new OpportunityCreateChainQueueable(
                    cloneAccount(requestItem.AccountRecord),
                    cloneOpportunity(requestItem.OpportunityRecord),
                    cloneVendorProgram(requestItem.VendorProgramRecord),
                    requestItem.ContactsToCreateJSONString,
                    requestItem.OpportunityContactRecordsJSON,
                    requestItem.CreateContactsInQueue
                )
            );

            resultItem.queued = true;
            resultItem.message = 'Queued async create chain job: ' + String.valueOf(jobId);
            results.add(resultItem);
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

    private class OpportunityCreateChainQueueable implements Queueable {
        private final Account accountRecord;
        private final Opportunity opportunityRecord;
        private final Vendor_Customization__c vendorProgramRecord;
        private final String contactsToCreateJson;
        private final String opportunityContactsJson;
        private final Boolean createContactsInQueue;

        OpportunityCreateChainQueueable(
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

        public void execute(QueueableContext context) {
            List<String> stageErrors = new List<String>();
            Opportunity createdOpportunity;

            if (createContactsInQueue == true && String.isNotBlank(contactsToCreateJson)) {
                try {
                    runCreateContactFlow(contactsToCreateJson);
                } catch (Exception ex) {
                    stageErrors.add('Contact create failed: ' + summarizeException(ex));
                }
            }

            try {
                createdOpportunity = runCreateOpportunityFlow(
                    accountRecord,
                    opportunityRecord,
                    vendorProgramRecord
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

            if (!stageErrors.isEmpty()) {
                LoggingUtil.error(
                    'ExperienceOpportunityCreateAsyncService queue execution errors. '
                    + 'AccountId=' + String.valueOf(accountRecord == null ? null : accountRecord.Id)
                    + ', OpportunityId=' + String.valueOf(createdOpportunity == null ? null : createdOpportunity.Id)
                    + ', Details=' + String.join(stageErrors, ' | ')
                );
            }
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

        Map<String, Object> inputs = new Map<String, Object>{
            'AccountRecord' => accountRecord,
            'OpportunityRecord' => opportunityInput,
            'VendorProgramRecord' => resolvedVendorProgramRecord
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
                SELECT Id, Name, Vendor__c, Retail_Option__c, Business_Vertical__c
                FROM Vendor_Customization__c
                WHERE Vendor__c = :vendorProgramRecord.Vendor__c
                  AND Retail_Option__c = :vendorProgramRecord.Retail_Option__c
                  AND Business_Vertical__c = :vendorProgramRecord.Business_Vertical__c
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
            SELECT Id, Name, Vendor__c
            FROM Vendor_Customization__c
            WHERE Vendor__r.Name = 'PerfectVision'
              AND Name = :programSelection
            LIMIT 1
        ];

        if (!perfectVisionMatches.isEmpty()) {
            return perfectVisionMatches[0];
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
