@IsTest
private class OnboardingBackgroundRetryServiceTest {
    @IsTest
    static void captureFault_upsertsAndProcessesToCompleted() {
        Onboarding__c onboarding = createOnboarding();

        OnboardingBackgroundRetryService.CaptureInput input =
            new OnboardingBackgroundRetryService.CaptureInput();
        input.onboardingIdText = String.valueOf(onboarding.Id);
        input.contextKey = String.valueOf(onboarding.Id);
        input.sourceFlowApiName = 'BLL_Onboarding_RCD_Logical_Process';
        input.sourceElementApiName = 'Create_Onboarding_Requirements';
        input.interviewGuid = 'iv-001';
        input.technicalDetail = 'unit-test fault';

        OnboardingBackgroundRetryService.CaptureOutcome capture =
            OnboardingBackgroundRetryService.captureFault(input);
        System.assertEquals(true, capture.queued, 'Expected fault capture to queue retry.');
        System.assertNotEquals(null, capture.jobId, 'Expected retry job id.');

        OnboardingBackgroundRetryService.TEST_BYPASS_REPLAY = true;
        OnboardingBackgroundRetryService.TEST_REPLAY_SUCCESS = true;
        OnboardingBackgroundRetryService.TEST_REPLAY_MESSAGE = 'ok';

        Test.startTest();
        Integer processed = OnboardingBackgroundRetryService.processDueJobs(10);
        Test.stopTest();

        System.assertEquals(1, processed, 'Expected one due job to process.');

        Onboarding_Background_Job__c refreshed = [
            SELECT Status__c, Attempt_Count__c, Last_Error__c
            FROM Onboarding_Background_Job__c
            WHERE Id = :capture.jobId
            LIMIT 1
        ];
        System.assertEquals(
            OnboardingBackgroundRetryService.STATUS_COMPLETED,
            refreshed.Status__c,
            'Expected job to complete after successful replay.'
        );
        System.assertEquals(1, Integer.valueOf(refreshed.Attempt_Count__c));
        System.assertEquals(null, refreshed.Last_Error__c);

        resetReplayTestFlags();
    }

    @IsTest
    static void captureFault_isIdempotentByOnboarding() {
        Onboarding__c onboarding = createOnboarding();

        OnboardingBackgroundRetryService.CaptureInput first =
            new OnboardingBackgroundRetryService.CaptureInput();
        first.onboardingIdText = String.valueOf(onboarding.Id);
        first.sourceFlowApiName = 'FLOW_A';
        first.sourceElementApiName = 'ELEMENT_A';

        OnboardingBackgroundRetryService.CaptureInput second =
            new OnboardingBackgroundRetryService.CaptureInput();
        second.onboardingIdText = String.valueOf(onboarding.Id);
        second.sourceFlowApiName = 'FLOW_B';
        second.sourceElementApiName = 'ELEMENT_B';

        OnboardingBackgroundRetryService.CaptureOutcome firstOutcome =
            OnboardingBackgroundRetryService.captureFault(first);
        OnboardingBackgroundRetryService.CaptureOutcome secondOutcome =
            OnboardingBackgroundRetryService.captureFault(second);

        System.assertEquals(firstOutcome.jobId, secondOutcome.jobId, 'Expected one idempotent job row.');
        Integer jobCount = [
            SELECT COUNT()
            FROM Onboarding_Background_Job__c
            WHERE Onboarding__c = :onboarding.Id
        ];
        System.assertEquals(1, jobCount, 'Expected only one retry job row for onboarding.');

        Onboarding_Background_Job__c refreshed = [
            SELECT Source_Flow_Api_Name__c, Source_Element_Api_Name__c
            FROM Onboarding_Background_Job__c
            WHERE Id = :firstOutcome.jobId
            LIMIT 1
        ];
        System.assertEquals('FLOW_B', refreshed.Source_Flow_Api_Name__c);
        System.assertEquals('ELEMENT_B', refreshed.Source_Element_Api_Name__c);
    }

    @IsTest
    static void processDueJobs_movesToDeadWhenMaxAttemptsReached() {
        Onboarding__c onboarding = createOnboarding();

        OnboardingBackgroundRetryService.CaptureInput input =
            new OnboardingBackgroundRetryService.CaptureInput();
        input.onboardingIdText = String.valueOf(onboarding.Id);
        OnboardingBackgroundRetryService.CaptureOutcome capture =
            OnboardingBackgroundRetryService.captureFault(input);
        System.assertNotEquals(null, capture.jobId);

        update new Onboarding_Background_Job__c(
            Id = capture.jobId,
            Max_Attempts__c = 1
        );

        OnboardingBackgroundRetryService.TEST_BYPASS_REPLAY = true;
        OnboardingBackgroundRetryService.TEST_REPLAY_SUCCESS = false;
        OnboardingBackgroundRetryService.TEST_REPLAY_MESSAGE = 'forced replay failure';

        Test.startTest();
        Integer processed = OnboardingBackgroundRetryService.processDueJobs(10);
        Test.stopTest();

        System.assertEquals(1, processed);
        Onboarding_Background_Job__c refreshed = [
            SELECT Status__c, Attempt_Count__c, Last_Error__c
            FROM Onboarding_Background_Job__c
            WHERE Id = :capture.jobId
            LIMIT 1
        ];
        System.assertEquals(OnboardingBackgroundRetryService.STATUS_DEAD, refreshed.Status__c);
        System.assertEquals(1, Integer.valueOf(refreshed.Attempt_Count__c));
        System.assert(
            refreshed.Last_Error__c != null && refreshed.Last_Error__c.contains('forced replay failure'),
            'Expected terminal error message.'
        );

        resetReplayTestFlags();
    }

    @IsTest
    static void captureFault_skipsWhenNoOnboardingContext() {
        OnboardingBackgroundRetryService.CaptureInput input =
            new OnboardingBackgroundRetryService.CaptureInput();
        input.contextKey = 'NOT_AN_ID';
        input.sourceFlowApiName = 'FLOW';

        OnboardingBackgroundRetryService.CaptureOutcome outcome =
            OnboardingBackgroundRetryService.captureFault(input);

        System.assertEquals(false, outcome.queued);
        System.assert(
            outcome.message != null && outcome.message.contains('No onboarding replay operation mapped'),
            'Expected no-op message when onboarding context is absent.'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Onboarding_Background_Job__c],
            'Expected no retry rows.'
        );
    }

    @IsTest
    static void workerAndScheduler_delegateToRetryService() {
        Onboarding__c onboarding = createOnboarding();
        OnboardingBackgroundRetryService.CaptureInput input =
            new OnboardingBackgroundRetryService.CaptureInput();
        input.onboardingIdText = String.valueOf(onboarding.Id);
        OnboardingBackgroundRetryService.CaptureOutcome capture =
            OnboardingBackgroundRetryService.captureFault(input);

        OnboardingBackgroundRetryService.TEST_BYPASS_REPLAY = true;
        OnboardingBackgroundRetryService.TEST_REPLAY_SUCCESS = true;
        OnboardingBackgroundRetryService.TEST_REPLAY_MESSAGE = 'ok';

        Test.startTest();
        System.enqueueJob(new OnboardingBackgroundRetryWorker());
        System.schedule(
            'OnboardingBackgroundRetrySchedulerTest',
            '0 0 0 1 1 ? 2050',
            new OnboardingBackgroundRetryScheduler()
        );
        Test.stopTest();

        Onboarding_Background_Job__c refreshed = [
            SELECT Status__c
            FROM Onboarding_Background_Job__c
            WHERE Id = :capture.jobId
            LIMIT 1
        ];
        System.assertEquals(OnboardingBackgroundRetryService.STATUS_COMPLETED, refreshed.Status__c);
        resetReplayTestFlags();
    }

    private static Onboarding__c createOnboarding() {
        Account accountRecord = TestAccountFactory.create('Retry Onboarding', true);
        TestDataFactoryWrapper.VendorCustomizationWrapper vendorWrapper =
            TestVendorProgramFactory.createVendorWithCustomization(true);
        return TestOnboardingFactory.create(accountRecord, vendorWrapper.customization, true);
    }

    private static void resetReplayTestFlags() {
        OnboardingBackgroundRetryService.TEST_BYPASS_REPLAY = false;
        OnboardingBackgroundRetryService.TEST_REPLAY_SUCCESS = true;
        OnboardingBackgroundRetryService.TEST_REPLAY_MESSAGE = null;
    }
}
