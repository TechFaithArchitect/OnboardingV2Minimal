/**
 * Enqueues asynchronous run of DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record with freshly queried inputs.
 */
public with sharing class OnboardingEnqueueOnboardingTailInvocable {
    @InvocableMethod(label='Onboarding - enqueue deferred onboarding tail')
    public static List<OnboardingEnqueueOnboardingTailResponse> enqueue(
        List<OnboardingEnqueueOnboardingTailRequest> requests
    ) {
        OnboardingEnqueueOnboardingTailResponse result = new OnboardingEnqueueOnboardingTailResponse();
        result.jobEnqueued = false;
        if (requests == null || requests.isEmpty()) {
            result.errorMessage = 'No request row.';
            return new List<OnboardingEnqueueOnboardingTailResponse>{ result };
        }
        OnboardingEnqueueOnboardingTailRequest row = requests[0];
        try {
            if (String.isBlank(row.contractId) || String.isBlank(row.opportunityId) || String.isBlank(row.accountId)) {
                result.errorMessage = 'contractId, opportunityId, and accountId are required.';
                return new List<OnboardingEnqueueOnboardingTailResponse>{ result };
            }
            Id contractKey = Id.valueOf(row.contractId.trim());
            Id opportunityKey = Id.valueOf(row.opportunityId.trim());
            Id accountKey = Id.valueOf(row.accountId.trim());
            Id vendorKey = String.isBlank(row.vendorProgramId)
                ? null
                : Id.valueOf(row.vendorProgramId.trim());

            System.enqueueJob(
                new OnboardingChainTailQueueable(
                    contractKey,
                    opportunityKey,
                    vendorKey,
                    accountKey,
                    row.correlationKey
                )
            );
            result.jobEnqueued = true;
        } catch (Exception ex) {
            result.errorMessage = ex.getTypeName() + ': ' + ex.getMessage();
            LoggingUtil.error('OnboardingEnqueueOnboardingTailInvocable: ' + result.errorMessage);
        }
        return new List<OnboardingEnqueueOnboardingTailResponse>{ result };
    }
}