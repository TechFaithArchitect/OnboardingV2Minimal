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
                    requestItem.OpportunityContactRecordsJSON
                )
            );

            resultItem.queued = true;
            resultItem.message = 'Queued async create chain job: ' + String.valueOf(jobId);
            results.add(resultItem);
        }

        return results;
    }

    private static Account cloneAccount(Account source) {
        return source == null ? null : (Account) source.clone(false, true, false, false);
    }

    private static Opportunity cloneOpportunity(Opportunity source) {
        return source == null ? null : (Opportunity) source.clone(false, true, false, false);
    }

    private static Vendor_Customization__c cloneVendorProgram(Vendor_Customization__c source) {
        return source == null ? null : (Vendor_Customization__c) source.clone(false, true, false, false);
    }

    private class OpportunityCreateChainQueueable implements Queueable {
        private final Account accountRecord;
        private final Opportunity opportunityRecord;
        private final Vendor_Customization__c vendorProgramRecord;
        private final String contactsToCreateJson;
        private final String opportunityContactsJson;

        OpportunityCreateChainQueueable(
            Account accountRecord,
            Opportunity opportunityRecord,
            Vendor_Customization__c vendorProgramRecord,
            String contactsToCreateJson,
            String opportunityContactsJson
        ) {
            this.accountRecord = accountRecord;
            this.opportunityRecord = opportunityRecord;
            this.vendorProgramRecord = vendorProgramRecord;
            this.contactsToCreateJson = contactsToCreateJson;
            this.opportunityContactsJson = opportunityContactsJson;
        }

        public void execute(QueueableContext context) {
            try {
                if (String.isNotBlank(contactsToCreateJson)) {
                    runCreateContactFlow(contactsToCreateJson);
                }

                Opportunity createdOpportunity = runCreateOpportunityFlow(
                    accountRecord,
                    opportunityRecord,
                    vendorProgramRecord
                );

                if (
                    createdOpportunity != null &&
                    createdOpportunity.Id != null &&
                    String.isNotBlank(opportunityContactsJson)
                ) {
                    runCreateOpportunityContactRoleFlow(
                        applyOpportunityId(opportunityContactsJson, createdOpportunity.Id)
                    );
                }
            } catch (Exception ex) {
                System.debug(
                    LoggingLevel.ERROR,
                    'ExperienceOpportunityCreateAsyncService queue execution failed: ' + ex.getMessage()
                );
            }
        }
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

        Map<String, Object> inputs = new Map<String, Object>{
            'AccountRecord' => accountRecord,
            'OpportunityRecord' => opportunityInput,
            'VendorProgramRecord' => vendorProgramRecord
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
