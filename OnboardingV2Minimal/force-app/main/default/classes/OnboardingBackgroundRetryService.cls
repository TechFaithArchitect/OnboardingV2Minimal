public without sharing class OnboardingBackgroundRetryService {
    public static final String OP_REPLAY_ONBOARDING_BACKGROUND_CHAIN = 'Replay Onboarding Background Chain';

    public static final String STATUS_PENDING = 'Pending';
    public static final String STATUS_IN_PROGRESS = 'In Progress';
    public static final String STATUS_RETRYABLE_FAILED = 'Retryable Failed';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_DEAD = 'Dead';

    private static final Integer DEFAULT_MAX_ATTEMPTS = 5;
    private static final Integer DEFAULT_BATCH_SIZE = 25;
    private static final Integer MAX_ERROR_CHARS = 32768;
    private static final Integer MAX_PAYLOAD_CHARS = 131072;

    private static final String FLOW_CREATE_ONBOARDING_REQUIREMENTS =
        'DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements';
    private static final String FLOW_CREATE_RELATED_ONBOARDING_REQUIREMENTS =
        'DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records';
    private static final String EVENT_SETUP_COMPLETE = 'SetupComplete';
    private static final String EVENT_LEARNUPON_TRIGGERED = 'LearnUponTriggered';

    @TestVisible
    static Boolean TEST_BYPASS_REPLAY = false;
    @TestVisible
    static Boolean TEST_REPLAY_SUCCESS = true;
    @TestVisible
    static String TEST_REPLAY_MESSAGE;

    public class CaptureInput {
        public String onboardingIdText;
        public String contextKey;
        public String sourceFlowApiName;
        public String sourceElementApiName;
        public String interviewGuid;
        public String technicalDetail;
        public String errorLogIdText;
    }

    public class CaptureOutcome {
        public Boolean queued;
        public Id jobId;
        public String operationType;
        public String idempotencyKey;
        public String message;
    }

    private class OperationResolution {
        public String operationType;
        public Id onboardingId;
        public Id onboardingRequirementId;
    }

    private class ReplayOutcome {
        public Boolean success;
        public String message;
    }

    private class ReplayDependencies {
        public Onboarding__c onboarding;
        public Account accountRecord;
        public Opportunity opportunityRecord;
        public OpportunityContactRole opportunityContactRoleRecord;
        public Vendor_Customization__c vendorProgramRecord;
    }

    public static CaptureOutcome captureFault(CaptureInput input) {
        CaptureOutcome outcome = new CaptureOutcome();
        outcome.queued = false;
        if (input == null) {
            outcome.message = 'Input is required.';
            return outcome;
        }

        OperationResolution resolution = resolveOperation(input);
        if (resolution == null || String.isBlank(resolution.operationType) || resolution.onboardingId == null) {
            outcome.message = 'No onboarding replay operation mapped.';
            return outcome;
        }

        String idempotencyKey = buildIdempotencyKey(resolution);
        outcome.idempotencyKey = idempotencyKey;
        outcome.operationType = resolution.operationType;

        if (!Schema.sObjectType.Onboarding_Background_Job__c.isAccessible()) {
            outcome.message = 'Missing read access to Onboarding_Background_Job__c.';
            return outcome;
        }
        Onboarding_Background_Job__c existing = null;
        List<Onboarding_Background_Job__c> existingRows = [
            SELECT Id, Attempt_Count__c, Status__c
            FROM Onboarding_Background_Job__c
            WHERE Idempotency_Key__c = :idempotencyKey
            LIMIT 1
        ];
        if (!existingRows.isEmpty()) {
            existing = existingRows[0];
        }

        if (existing != null && existing.Status__c == STATUS_IN_PROGRESS) {
            outcome.queued = true;
            outcome.jobId = existing.Id;
            outcome.message = 'Replay job is already in progress.';
            return outcome;
        }

        Onboarding_Background_Job__c job = existing == null
            ? new Onboarding_Background_Job__c()
            : new Onboarding_Background_Job__c(Id = existing.Id);

        job.Idempotency_Key__c = idempotencyKey;
        job.Operation_Type__c = resolution.operationType;
        job.Status__c = STATUS_PENDING;
        job.Onboarding__c = resolution.onboardingId;
        job.Onboarding_Requirement__c = resolution.onboardingRequirementId;
        job.Source_Flow_Api_Name__c = truncate(input.sourceFlowApiName, 255);
        job.Source_Element_Api_Name__c = truncate(input.sourceElementApiName, 255);
        job.Context_Key__c = truncate(input.contextKey, 255);
        job.Correlation_Id__c = truncate(input.interviewGuid, 255);
        job.Last_Error__c = truncate(input.technicalDetail, MAX_ERROR_CHARS);
        job.Payload_JSON__c = truncate(
            JSON.serialize(new Map<String, Object>{
                'onboardingId' => resolution.onboardingId,
                'onboardingRequirementId' => resolution.onboardingRequirementId,
                'sourceFlowApiName' => input.sourceFlowApiName,
                'sourceElementApiName' => input.sourceElementApiName,
                'contextKey' => input.contextKey,
                'interviewGuid' => input.interviewGuid
            }),
            MAX_PAYLOAD_CHARS
        );
        job.Next_Run_At__c = System.now();
        job.Last_Error_Log__c = tryParseId(input.errorLogIdText, Error_Log__c.SObjectType);

        if (existing == null || existing.Status__c == STATUS_COMPLETED || existing.Status__c == STATUS_DEAD) {
            job.Attempt_Count__c = 0;
        }

        if (existing == null && !Schema.sObjectType.Onboarding_Background_Job__c.isCreateable()) {
            outcome.message = 'Missing create access to Onboarding_Background_Job__c.';
            return outcome;
        }
        if (existing != null && !Schema.sObjectType.Onboarding_Background_Job__c.isUpdateable()) {
            outcome.message = 'Missing update access to Onboarding_Background_Job__c.';
            return outcome;
        }
        Database.UpsertResult upsertResult = Database.upsert(
            job,
            Onboarding_Background_Job__c.Fields.Idempotency_Key__c,
            false
        );

        if (!upsertResult.isSuccess()) {
            outcome.message = summarizeErrors(upsertResult.getErrors());
            return outcome;
        }

        outcome.jobId = upsertResult.getId();
        outcome.queued = true;
        outcome.message = 'Replay job queued.';

        if (!Test.isRunningTest()) {
            ensureScheduler();
            try {
                System.enqueueJob(new OnboardingBackgroundRetryWorker());
            } catch (Exception ex) {
                outcome.message = 'Replay job saved, but queue dispatch failed: ' + ex.getMessage();
            }
        }

        return outcome;
    }

    public static Integer processDueJobs(Integer requestedBatchSize) {
        Integer batchSize = requestedBatchSize == null || requestedBatchSize <= 0
            ? DEFAULT_BATCH_SIZE
            : Math.min(requestedBatchSize, 100);

        if (
            !Schema.sObjectType.Onboarding_Background_Job__c.isAccessible() ||
            !Schema.sObjectType.Onboarding_Background_Job__c.isUpdateable()
        ) {
            return 0;
        }
        DateTime now = System.now();
        List<Onboarding_Background_Job__c> jobs = [
            SELECT
                Id,
                Attempt_Count__c,
                Max_Attempts__c,
                Status__c,
                Operation_Type__c,
                Onboarding__c,
                Onboarding_Requirement__c,
                Source_Flow_Api_Name__c,
                Source_Element_Api_Name__c,
                Last_Error__c,
                Next_Run_At__c
            FROM Onboarding_Background_Job__c
            WHERE Status__c IN :new List<String>{ STATUS_PENDING, STATUS_RETRYABLE_FAILED }
                AND (Next_Run_At__c = null OR Next_Run_At__c <= :now)
            LIMIT :batchSize
            FOR UPDATE
        ];

        if (jobs.isEmpty()) {
            return 0;
        }

        Map<Id, Integer> attemptsByJobId = new Map<Id, Integer>();
        for (Onboarding_Background_Job__c job : jobs) {
            Integer attempts = (job.Attempt_Count__c == null ? 0 : Integer.valueOf(job.Attempt_Count__c)) + 1;
            attemptsByJobId.put(job.Id, attempts);
            job.Attempt_Count__c = attempts;
            job.Status__c = STATUS_IN_PROGRESS;
            job.Last_Processed_At__c = now;
        }
        Database.update(jobs, false, AccessLevel.SYSTEM_MODE);

        for (Onboarding_Background_Job__c job : jobs) {
            ReplayOutcome replay;
            try {
                replay = executeJob(job);
            } catch (Exception ex) {
                replay = failure(
                    'Unhandled replay exception: ' + ex.getTypeName() + ': ' + ex.getMessage()
                );
            }
            if (replay.success == true) {
                job.Status__c = STATUS_COMPLETED;
                job.Next_Run_At__c = null;
                job.Last_Error__c = null;
                continue;
            }

            Integer maxAttempts = resolveMaxAttempts(job.Max_Attempts__c);
            Integer attempts = attemptsByJobId.get(job.Id);
            job.Last_Error__c = truncate(replay.message, MAX_ERROR_CHARS);
            if (attempts >= maxAttempts) {
                job.Status__c = STATUS_DEAD;
                job.Next_Run_At__c = null;
            } else {
                job.Status__c = STATUS_RETRYABLE_FAILED;
                job.Next_Run_At__c = now.addMinutes(computeBackoffMinutes(attempts));
            }
        }
        Database.update(jobs, false, AccessLevel.SYSTEM_MODE);

        if (!Test.isRunningTest() && hasDueJobs(now)) {
            try {
                System.enqueueJob(new OnboardingBackgroundRetryWorker());
            } catch (Exception ex) {
                LoggingUtil.warn('OnboardingBackgroundRetryService.processDueJobs enqueue follow-up failed: ' + ex.getMessage());
            }
        }

        return jobs.size();
    }

    private static ReplayOutcome executeJob(Onboarding_Background_Job__c job) {
        if (Test.isRunningTest() && TEST_BYPASS_REPLAY == true) {
            ReplayOutcome testResult = new ReplayOutcome();
            testResult.success = TEST_REPLAY_SUCCESS;
            testResult.message = TEST_REPLAY_MESSAGE;
            return testResult;
        }

        if (job == null) {
            return failure('Retry job was null.');
        }

        if (job.Operation_Type__c != OP_REPLAY_ONBOARDING_BACKGROUND_CHAIN) {
            return failure('Unsupported operation type: ' + String.valueOf(job.Operation_Type__c));
        }

        if (job.Onboarding__c == null) {
            return failure('Onboarding Id is required for replay.');
        }

        return replayOnboardingBackgroundChain(
            job.Onboarding__c,
            job.Onboarding_Requirement__c,
            job.Source_Flow_Api_Name__c,
            job.Source_Element_Api_Name__c
        );
    }

    private static ReplayOutcome replayOnboardingBackgroundChain(
        Id onboardingId,
        Id scopedRequirementId,
        String sourceFlowApiName,
        String sourceElementApiName
    ) {
        Onboarding__c onboarding = OnboardingRecordFlowSupport.loadOnboardingForFlow(onboardingId);
        if (onboarding == null) {
            return failure('Onboarding record not found for replay.');
        }

        List<String> replayErrors = new List<String>();
        List<String> replayWarnings = new List<String>();
        Integer requirementsProcessed = 0;

        String alignmentError = tryAlignOnboardingOpportunity(onboarding);
        if (!String.isBlank(alignmentError)) {
            replayErrors.add(alignmentError);
        }

        onboarding = OnboardingRecordFlowSupport.loadOnboardingForFlow(onboardingId);
        if (onboarding == null) {
            return failure('Onboarding record not found after alignment replay.');
        }

        if (onboarding.Vendor_Customization__c == null) {
            replayErrors.add('Onboarding is missing Vendor_Customization__c.');
        } else {
            ReplayOutcome requirementReplay = replayRequirementCreationAndRelatedRecords(
                onboarding,
                scopedRequirementId
            );
            if (requirementReplay.success == true) {
                if (Schema.sObjectType.Onboarding_Requirement__c.isAccessible()) {
                    requirementsProcessed = [
                        SELECT COUNT()
                        FROM Onboarding_Requirement__c
                        WHERE Onboarding__c = :onboardingId
                    ];
                } else {
                    replayWarnings.add('Missing read access to Onboarding_Requirement__c for replay count.');
                }
                if (!String.isBlank(requirementReplay.message)) {
                    replayWarnings.add(requirementReplay.message);
                }
            } else {
                replayErrors.add(requirementReplay.message);
            }
        }

        String nextStepError = applyNextStepRules(onboardingId);
        if (!String.isBlank(nextStepError)) {
            replayErrors.add(nextStepError);
        }

        OnboardingStatusEvaluatorInvocable.EvaluateResult evalResult = evaluateOnboardingStatus(onboardingId);
        if (evalResult != null && !String.isBlank(evalResult.errorMessage)) {
            replayErrors.add('Status reevaluation failed: ' + evalResult.errorMessage);
        }

        if (shouldReplayCommunicationPath(sourceFlowApiName, sourceElementApiName)) {
            String communicationReplayError = replayCommunicationPath(onboardingId);
            if (!String.isBlank(communicationReplayError)) {
                replayErrors.add(communicationReplayError);
            }
        }

        if (!replayErrors.isEmpty()) {
            return failure(String.join(replayErrors, ' | '));
        }

        String successMessage =
            'Replay completed successfully for onboarding ' + String.valueOf(onboardingId) +
            '. Requirements processed: ' + String.valueOf(requirementsProcessed);
        if (!replayWarnings.isEmpty()) {
            successMessage += ' | Notes: ' + String.join(replayWarnings, ' | ');
        }
        return success(successMessage);
    }

    private static ReplayOutcome replayRequirementCreationAndRelatedRecords(
        Onboarding__c onboarding,
        Id scopedRequirementId
    ) {
        Id onboardingId = onboarding == null ? null : onboarding.Id;
        if (onboardingId == null) {
            return failure('Onboarding Id is required for requirement replay.');
        }
        if (!Schema.sObjectType.Onboarding_Requirement__c.isAccessible()) {
            return failure('Missing read access to Onboarding_Requirement__c for replay.');
        }

        OnboardingRequirementVPRGateService.GateOutcome gate = OnboardingRequirementVPRGateService.buildGateOutcome(
            onboardingId,
            onboarding.Vendor_Customization__c
        );

        Map<String, Object> createInputs = new Map<String, Object>{
            'OnboardingRecord' => onboarding,
            'VendorProgramRequirements' => gate == null || gate.vendorProgramRequirementsToCreate == null
                ? new List<Vendor_Program_Requirement__c>()
                : gate.vendorProgramRequirementsToCreate,
            'Approval_Gate_Deferred_Remain' => gate != null && gate.deferredRequirementsRemain == true
        };

        OnboardingRecordFlowSupport.InterviewRunResult createResult =
            OnboardingRecordFlowSupport.runAutolaunchedFlow(FLOW_CREATE_ONBOARDING_REQUIREMENTS, createInputs);
        if (createResult.succeeded != true) {
            return failure('Create onboarding requirements replay failed: ' + createResult.errorMessage);
        }

        String createError = asString(createResult.getVariableValue('errorMessage'));
        if (!String.isBlank(createError)) {
            return failure('Create onboarding requirements replay returned error: ' + createError);
        }

        List<Onboarding_Requirement__c> requirements = scopedRequirementId == null
            ? [
                SELECT Id, Onboarding__c, Requirement_Type__c
                FROM Onboarding_Requirement__c
                WHERE Onboarding__c = :onboardingId
                ORDER BY Sequence__c ASC NULLS LAST, CreatedDate ASC, Id ASC
            ]
            : [
                SELECT Id, Onboarding__c, Requirement_Type__c
                FROM Onboarding_Requirement__c
                WHERE Id = :scopedRequirementId
                LIMIT 1
            ];

        if (requirements.isEmpty()) {
            return success('No onboarding requirements to reconcile.');
        }

        ReplayDependencies deps = loadReplayDependencies(onboarding);
        Integer failed = 0;
        List<String> sampleErrors = new List<String>();

        for (Onboarding_Requirement__c requirement : requirements) {
            Map<String, Object> relatedInputs = new Map<String, Object>{
                'OnboardingRequirementRecord' => requirement,
                'OnboardingRecord' => deps.onboarding,
                'AccountRecord' => deps.accountRecord,
                'OpportunityRecord' => deps.opportunityRecord,
                'OpportunityContactRoleRecord' => deps.opportunityContactRoleRecord,
                'VendorProgramRecord' => deps.vendorProgramRecord
            };

            OnboardingRecordFlowSupport.InterviewRunResult relatedResult =
                OnboardingRecordFlowSupport.runAutolaunchedFlow(
                    FLOW_CREATE_RELATED_ONBOARDING_REQUIREMENTS,
                    relatedInputs
                );

            String relatedError = relatedResult.succeeded == true
                ? asString(relatedResult.getVariableValue('errorMessage'))
                : relatedResult.errorMessage;

            if (!String.isBlank(relatedError)) {
                failed++;
                if (sampleErrors.size() < 3) {
                    sampleErrors.add(String.valueOf(requirement.Id) + ': ' + relatedError);
                }
            }
        }

        if (failed > 0) {
            return failure(
                'Replay completed with ' + String.valueOf(failed) +
                ' failure(s). ' + String.join(sampleErrors, ' | ')
            );
        }

        return success(
            'Requirements replay completed for onboarding ' + String.valueOf(onboardingId) +
            '. Requirements processed: ' + String.valueOf(requirements.size())
        );
    }

    private static String tryAlignOnboardingOpportunity(Onboarding__c onboarding) {
        if (onboarding == null || onboarding.Id == null || onboarding.Contract__c == null) {
            return null;
        }
        if (!Schema.sObjectType.Contract.isAccessible()) {
            return null;
        }

        List<Contract> contracts = [
            SELECT Id, Opportunity_to_Contract__c
            FROM Contract
            WHERE Id = :onboarding.Contract__c
            LIMIT 1
        ];
        if (contracts.isEmpty()) {
            return null;
        }

        Id contractOpportunityId = contracts[0].Opportunity_to_Contract__c;
        if (contractOpportunityId == null || contractOpportunityId == onboarding.Opportunity__c) {
            return null;
        }
        if (!Schema.sObjectType.Onboarding__c.isUpdateable()) {
            return 'Missing update access to Onboarding__c for opportunity alignment replay.';
        }

        try {
            Database.update(new Onboarding__c(
                Id = onboarding.Id,
                Opportunity__c = contractOpportunityId
            ), false, AccessLevel.SYSTEM_MODE);
            return null;
        } catch (Exception ex) {
            return 'Onboarding opportunity alignment replay failed: ' + ex.getMessage();
        }
    }

    private static String applyNextStepRules(Id onboardingId) {
        if (onboardingId == null) {
            return null;
        }

        OnboardingNextStepRuleInvocable.Request req = new OnboardingNextStepRuleInvocable.Request();
        req.onboardingId = onboardingId;
        List<OnboardingNextStepRuleInvocable.Result> results =
            OnboardingNextStepRuleInvocable.applyAfterSetupComplete(
                new List<OnboardingNextStepRuleInvocable.Request>{ req }
            );
        if (results == null || results.isEmpty()) {
            return null;
        }
        OnboardingNextStepRuleInvocable.Result first = results[0];
        return String.isBlank(first.errorMessage)
            ? null
            : 'Onboarding next-step rule replay failed: ' + first.errorMessage;
    }

    private static Boolean shouldReplayCommunicationPath(
        String sourceFlowApiName,
        String sourceElementApiName
    ) {
        List<String> communicationKeywords = new List<String>{
            'communication',
            'dispatch',
            'training',
            'learnupon',
            'setup_complete',
            'setup complete'
        };
        return containsKeyword(sourceFlowApiName, communicationKeywords) ||
            containsKeyword(sourceElementApiName, communicationKeywords);
    }

    private static Boolean containsKeyword(String text, List<String> keywords) {
        if (String.isBlank(text) || keywords == null || keywords.isEmpty()) {
            return false;
        }
        String normalized = text.toLowerCase();
        for (String keyword : keywords) {
            if (!String.isBlank(keyword) && normalized.contains(keyword.toLowerCase())) {
                return true;
            }
        }
        return false;
    }

    private static String replayCommunicationPath(Id onboardingId) {
        if (onboardingId == null) {
            return null;
        }
        if (!Schema.sObjectType.Onboarding__c.isAccessible()) {
            return 'Missing read access to Onboarding__c for communication replay.';
        }

        List<Onboarding__c> onboardingRows = [
            SELECT Id, Vendor_Customization__c, Onboarding_Status__c, LearnUpon_Triggered__c
            FROM Onboarding__c
            WHERE Id = :onboardingId
            LIMIT 1
        ];
        if (onboardingRows.isEmpty()) {
            return 'Onboarding not found for communication replay.';
        }

        Onboarding__c onboarding = onboardingRows[0];
        if (onboarding.Vendor_Customization__c == null) {
            return null;
        }

        List<String> errors = new List<String>();
        if (onboarding.LearnUpon_Triggered__c == true) {
            String trainingError = runCommunicationGateAndDispatch(
                onboarding.Id,
                onboarding.Vendor_Customization__c,
                EVENT_LEARNUPON_TRIGGERED,
                'LearnUponTriggered'
            );
            if (!String.isBlank(trainingError)) {
                errors.add(trainingError);
            }
        }

        if (onboarding.Onboarding_Status__c == 'Setup Complete') {
            String setupCompleteError = runCommunicationGateAndDispatch(
                onboarding.Id,
                onboarding.Vendor_Customization__c,
                EVENT_SETUP_COMPLETE,
                'SetupComplete'
            );
            if (!String.isBlank(setupCompleteError)) {
                errors.add(setupCompleteError);
            }
        }

        return errors.isEmpty() ? null : String.join(errors, ' | ');
    }

    private static String runCommunicationGateAndDispatch(
        Id onboardingId,
        Id vendorProgramId,
        String eventKey,
        String eventLabel
    ) {
        OnboardingRecordBREGateInvocable.Request gateReq = new OnboardingRecordBREGateInvocable.Request();
        gateReq.eventKey = eventKey;
        gateReq.vendorProgramId = vendorProgramId;

        List<OnboardingRecordBREGateInvocable.Result> gateResults =
            OnboardingRecordBREGateInvocable.evaluate(
                new List<OnboardingRecordBREGateInvocable.Request>{ gateReq }
            );
        if (gateResults == null || gateResults.isEmpty()) {
            return eventLabel + ' communication replay: BRE gate returned no result.';
        }

        OnboardingRecordBREGateInvocable.Result gateResult = gateResults[0];
        if (!String.isBlank(gateResult.diagnosticMessage)) {
            return eventLabel + ' communication replay: BRE gate failed. ' + gateResult.diagnosticMessage;
        }
        if (gateResult.dispatchAllowed != true) {
            return null;
        }

        OnboardingRecordFlowSupport.DispatchByEventRequest dispatchReq =
            new OnboardingRecordFlowSupport.DispatchByEventRequest();
        dispatchReq.eventKey = eventKey;
        dispatchReq.onboardingId = onboardingId;
        dispatchReq.vendorProgramId = vendorProgramId;

        List<OnboardingRecordFlowSupport.DispatchByEventResult> dispatchResults =
            OnboardingRecordFlowSupport.dispatchCommunicationByEvent(
                new List<OnboardingRecordFlowSupport.DispatchByEventRequest>{ dispatchReq }
            );
        if (dispatchResults == null || dispatchResults.isEmpty()) {
            return eventLabel + ' communication replay: dispatch returned no result.';
        }

        OnboardingRecordFlowSupport.DispatchByEventResult dispatchResult = dispatchResults[0];
        if (dispatchResult.ranSuccessfully == true) {
            return null;
        }
        return eventLabel + ' communication replay: dispatch failed. ' + dispatchResult.diagnosticMessage;
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    private static ReplayDependencies loadReplayDependencies(Onboarding__c onboarding) {
        ReplayDependencies deps = new ReplayDependencies();
        deps.onboarding = onboarding;

        deps.accountRecord = (Account) loadRecordForFlow(Account.SObjectType, onboarding.Account__c);
        deps.opportunityRecord = (Opportunity) loadRecordForFlow(
            Opportunity.SObjectType,
            onboarding.Opportunity__c
        );
        deps.vendorProgramRecord = (Vendor_Customization__c) loadRecordForFlow(
            Vendor_Customization__c.SObjectType,
            onboarding.Vendor_Customization__c
        );

        if (deps.opportunityRecord != null && deps.opportunityRecord.Id != null) {
            String ocrCols = commaSeparatedQueryableFields(OpportunityContactRole.SObjectType);
            if (!String.isBlank(ocrCols)) {
                List<OpportunityContactRole> ocrRows = Database.query(
                    'SELECT ' + ocrCols +
                    ' FROM OpportunityContactRole' +
                    ' WHERE OpportunityId = :deps.opportunityRecord.Id AND IsPrimary = true' +
                    ' ORDER BY LastModifiedDate DESC, Id DESC LIMIT 1'
                );
                if (!ocrRows.isEmpty()) {
                    deps.opportunityContactRoleRecord = ocrRows[0];
                }
            }
        }

        return deps;
    }

    private static OnboardingStatusEvaluatorInvocable.EvaluateResult evaluateOnboardingStatus(Id onboardingId) {
        if (onboardingId == null) {
            return null;
        }
        OnboardingStatusEvaluatorInvocable.EvaluateRequest req =
            new OnboardingStatusEvaluatorInvocable.EvaluateRequest();
        req.onboardingId = onboardingId;
        req.applyUpdates = true;

        List<OnboardingStatusEvaluatorInvocable.EvaluateResult> results =
            OnboardingStatusEvaluatorInvocable.evaluate(
                new List<OnboardingStatusEvaluatorInvocable.EvaluateRequest>{ req }
            );
        if (results == null || results.isEmpty()) {
            return null;
        }
        return results[0];
    }

    private static OperationResolution resolveOperation(CaptureInput input) {
        OperationResolution resolved = new OperationResolution();
        resolved.operationType = OP_REPLAY_ONBOARDING_BACKGROUND_CHAIN;

        Id onboardingId = tryParseId(input.onboardingIdText, Onboarding__c.SObjectType);
        Id contextOnboardingId = tryParseId(input.contextKey, Onboarding__c.SObjectType);
        Id contextRequirementId = tryParseId(input.contextKey, Onboarding_Requirement__c.SObjectType);

        if (onboardingId == null && contextOnboardingId != null) {
            onboardingId = contextOnboardingId;
        }

        if (contextRequirementId != null) {
            if (!Schema.sObjectType.Onboarding_Requirement__c.isAccessible()) {
                return null;
            }
            List<Onboarding_Requirement__c> reqRows = [
                SELECT Id, Onboarding__c
                FROM Onboarding_Requirement__c
                WHERE Id = :contextRequirementId
                LIMIT 1
            ];
            if (!reqRows.isEmpty()) {
                resolved.onboardingRequirementId = reqRows[0].Id;
                if (onboardingId == null) {
                    onboardingId = reqRows[0].Onboarding__c;
                }
            }
        }

        resolved.onboardingId = onboardingId;
        if (resolved.onboardingId == null) {
            return null;
        }
        return resolved;
    }

    private static String buildIdempotencyKey(OperationResolution resolved) {
        return resolved.operationType + '|' + String.valueOf(resolved.onboardingId);
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    private static SObject loadRecordForFlow(Schema.SObjectType typeToken, Id recordId) {
        if (typeToken == null || recordId == null) {
            return null;
        }
        String cols = commaSeparatedQueryableFields(typeToken);
        if (String.isBlank(cols)) {
            return null;
        }

        List<SObject> rows = Database.query(
            'SELECT ' + cols +
            ' FROM ' + typeToken.getDescribe().getName() +
            ' WHERE Id = :recordId LIMIT 1'
        );
        return rows.isEmpty() ? null : rows[0];
    }

    private static String commaSeparatedQueryableFields(Schema.SObjectType typeToken) {
        List<String> parts = new List<String>();
        for (Schema.SObjectField f : typeToken.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult fr = f.getDescribe();
            if (!fr.isAccessible()) {
                continue;
            }
            parts.add(fr.getName());
        }
        return String.join(parts, ',');
    }

    private static ReplayOutcome success(String message) {
        ReplayOutcome out = new ReplayOutcome();
        out.success = true;
        out.message = message;
        return out;
    }

    private static ReplayOutcome failure(String message) {
        ReplayOutcome out = new ReplayOutcome();
        out.success = false;
        out.message = message;
        return out;
    }

    private static Boolean hasDueJobs(DateTime now) {
        if (!Schema.sObjectType.Onboarding_Background_Job__c.isAccessible()) {
            return false;
        }
        Integer countDue = [
            SELECT COUNT()
            FROM Onboarding_Background_Job__c
            WHERE Status__c IN :new List<String>{ STATUS_PENDING, STATUS_RETRYABLE_FAILED }
                AND (Next_Run_At__c = null OR Next_Run_At__c <= :now)
        ];
        return countDue > 0;
    }

    private static Integer resolveMaxAttempts(Decimal value) {
        if (value == null || value <= 0) {
            return DEFAULT_MAX_ATTEMPTS;
        }
        return Integer.valueOf(value);
    }

    private static Integer computeBackoffMinutes(Integer attempt) {
        Integer effectiveAttempt = attempt == null || attempt <= 1 ? 1 : attempt;
        Integer minutes = 5;
        for (Integer i = 1; i < effectiveAttempt; i++) {
            minutes *= 2;
            if (minutes >= 60) {
                return 60;
            }
        }
        return Math.min(minutes, 60);
    }

    private static Id tryParseId(String raw, Schema.SObjectType expectedType) {
        if (String.isBlank(raw)) {
            return null;
        }
        try {
            Id parsed = Id.valueOf(raw.trim());
            if (expectedType == null || parsed.getSObjectType() == expectedType) {
                return parsed;
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    private static String asString(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static String truncate(String value, Integer maxLen) {
        if (value == null || maxLen == null || maxLen <= 0 || value.length() <= maxLen) {
            return value;
        }
        return value.substring(0, maxLen);
    }

    private static String summarizeErrors(List<Database.Error> errors) {
        if (errors == null || errors.isEmpty()) {
            return 'Unknown DML error.';
        }
        List<String> parts = new List<String>();
        for (Database.Error err : errors) {
            parts.add(err.getStatusCode() + ': ' + err.getMessage());
        }
        return String.join(parts, '; ');
    }

    private static void ensureScheduler() {
        String jobName = OnboardingBackgroundRetryScheduler.JOB_NAME;
        if (!Schema.sObjectType.CronTrigger.isAccessible()) {
            return;
        }
        List<CronTrigger> existing = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            return;
        }
        try {
            System.schedule(
                jobName,
                OnboardingBackgroundRetryScheduler.CRON_EVERY_10_MIN,
                new OnboardingBackgroundRetryScheduler()
            );
        } catch (Exception ex) {
            LoggingUtil.warn('OnboardingBackgroundRetryService.ensureScheduler failed: ' + ex.getMessage());
        }
    }
}
