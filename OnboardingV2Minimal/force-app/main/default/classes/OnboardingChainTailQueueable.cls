/**
 * Runs DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record outside the screen-flow interview to shorten user-visible wait.
 */
public with sharing class OnboardingChainTailQueueable implements Queueable, Finalizer {
    private final Id contractId;
    private final Id opportunityId;
    private final Id vendorProgramId;
    private final Id accountId;
    private final String correlationKey;

    public OnboardingChainTailQueueable(
        Id contractId,
        Id opportunityId,
        Id vendorProgramId,
        Id accountId,
        String correlationKey
    ) {
        this.contractId = contractId;
        this.opportunityId = opportunityId;
        this.vendorProgramId = vendorProgramId;
        this.accountId = accountId;
        this.correlationKey = correlationKey;
    }

    public void execute(QueueableContext context) {
        System.attachFinalizer(this);
        String contractStr = contractId == null ? null : String.valueOf(contractId);
        String opportunityStr = opportunityId == null ? null : String.valueOf(opportunityId);
        String accountStr = accountId == null ? null : String.valueOf(accountId);
        String vendorStr = vendorProgramId == null ? null : String.valueOf(vendorProgramId);

        publishChainEvent('DEFERRED_ONBOARDING_TAIL_START', contractStr, opportunityStr, accountStr, vendorStr);

        try {
            List<Contract> contracts = [
                SELECT Id, AccountId, Opportunity_to_Contract__c
                FROM Contract
                WHERE Id = :contractId
                WITH USER_MODE
                LIMIT 1
            ];
            if (contracts.isEmpty()) {
                LoggingUtil.error(
                    'OnboardingChainTailQueueable: Contract not found ' + String.valueOf(contractId)
                );
                return;
            }
            Contract contractRecord = contracts[0];

            List<Opportunity> opps = queryOpportunityFull(opportunityId);
            if (opps.isEmpty()) {
                LoggingUtil.error(
                    'OnboardingChainTailQueueable: Opportunity not found ' + String.valueOf(opportunityId)
                );
                return;
            }
            Opportunity opportunityRecord = opps[0];

            List<Account> accounts = queryAccountFull(accountId);
            if (accounts.isEmpty()) {
                LoggingUtil.error(
                    'OnboardingChainTailQueueable: Account not found ' + String.valueOf(accountId)
                );
                return;
            }
            Account accountRecord = accounts[0];

            Vendor_Customization__c vendorProgramRecord;
            if (vendorProgramId != null) {
                List<Vendor_Customization__c> vps = [
                    SELECT Id, Vendor__c
                    FROM Vendor_Customization__c
                    WHERE Id = :vendorProgramId
                    WITH USER_MODE
                    LIMIT 1
                ];
                vendorProgramRecord = vps.isEmpty() ? new Vendor_Customization__c() : vps[0];
            } else {
                vendorProgramRecord = new Vendor_Customization__c();
            }

            Map<String, Object> flowInputs = new Map<String, Object>{
                'ContractRecord' => contractRecord,
                'OpportunityRecord' => opportunityRecord,
                'VendorProgramRecord' => vendorProgramRecord,
                'AccountRecord' => accountRecord
            };

            Flow.Interview flowInterview = Flow.Interview.createInterview(
                'DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record',
                flowInputs
            );
            flowInterview.start();

            publishChainEvent(
                'DEFERRED_ONBOARDING_TAIL_FLOW_FINISHED',
                contractStr,
                opportunityStr,
                accountStr,
                vendorStr
            );
        } catch (Exception ex) {
            LoggingUtil.error(
                'OnboardingChainTailQueueable failed: ' + ex.getTypeName() + ' ' + ex.getMessage()
            );
        }
    }

    public void execute(FinalizerContext context) {
        if (context == null || context.getResult() != ParentJobResult.UNHANDLED_EXCEPTION) {
            return;
        }
        Exception ex = context.getException();
        LoggingUtil.error(
            'OnboardingChainTailQueueable finalizer captured unhandled exception: '
            + (ex == null ? 'Unknown error.' : ex.getTypeName() + ': ' + ex.getMessage())
        );
    }

    private static List<Opportunity> queryOpportunityFull(Id opportunityKey) {
        try {
            return (List<Opportunity>) Database.query(
                'SELECT FIELDS(ALL) FROM Opportunity WHERE Id = :opportunityKey WITH USER_MODE LIMIT 1'
            );
        } catch (Exception ex) {
            LoggingUtil.warn(
                'OnboardingChainTailQueueable: FIELDS(ALL) Opportunity fallback — ' + ex.getMessage()
            );
            return [
                SELECT Id
                FROM Opportunity
                WHERE Id = :opportunityKey
                WITH USER_MODE
                LIMIT 1
            ];
        }
    }

    private static List<Account> queryAccountFull(Id accountKey) {
        try {
            return (List<Account>) Database.query(
                'SELECT FIELDS(ALL) FROM Account WHERE Id = :accountKey WITH USER_MODE LIMIT 1'
            );
        } catch (Exception ex) {
            LoggingUtil.warn(
                'OnboardingChainTailQueueable: FIELDS(ALL) Account fallback — ' + ex.getMessage()
            );
            return [
                SELECT Id
                FROM Account
                WHERE Id = :accountKey
                WITH USER_MODE
                LIMIT 1
            ];
        }
    }

    private void publishChainEvent(
        String payloadType,
        String contractStr,
        String opportunityStr,
        String accountStr,
        String vendorStr
    ) {
        if (!OnboardingPerformanceSettings.isPublishChainProgressEventsEnabled()) {
            return;
        }
        EventBus.publish(
            new Onboarding_Opportunity_Chain__e(
                Payload_Type__c = payloadType,
                Contract_Id__c = contractStr,
                Opportunity_Id__c = opportunityStr,
                Account_Id__c = accountStr,
                Vendor_Program_Id__c = vendorStr,
                Correlation_Key__c = correlationKey
            )
        );
    }
}
