@IsTest
private class OnboardingErrorLogInvocableTest {
    @IsTest
    static void logFault_insertsErrorLog_andReturnsId() {
        OnboardingErrorLogInvocable.LogRequest req = new OnboardingErrorLogInvocable.LogRequest();
        req.technicalDetail = 'Fault | Flow=Test_Flow | Element=Test_Element';
        req.userMessageBase = 'Something went wrong.';
        req.sourceFlowApiName = 'BLL_Onboarding_SFL_Dispatch_Communication_By_Context';
        req.sourceElementApiName = 'Send_Message';
        req.contextKey = 'CTX1';
        req.interviewGuid = 'interview-guid-123';

        Test.startTest();
        List<OnboardingErrorLogInvocable.LogResult> results = OnboardingErrorLogInvocable.logFault(
            new List<OnboardingErrorLogInvocable.LogRequest>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one result row.');
        OnboardingErrorLogInvocable.LogResult res = results[0];
        System.assertEquals(true, res.insertSucceeded, 'Expected successful insert.');
        System.assertNotEquals(null, res.errorLogId, 'Expected Error Log Id.');
        System.assert(
            res.userFacingMessage != null && res.userFacingMessage.contains('Error Log Id:'),
            'Expected user message to include log id token.'
        );

        Error_Log__c row = [
            SELECT
                Type__c,
                Provider_Subtype__c,
                Provider__c,
                Component__c,
                Endpoint__c,
                Error__c,
                Request__c
            FROM Error_Log__c
            WHERE Id = :res.errorLogId
        ];
        System.assertEquals('Flow', row.Type__c);
        System.assertEquals('Communication Dispatch', row.Provider_Subtype__c);
        System.assertEquals(OnboardingErrorLogService.PROVIDER_ONBOARDING_V2, row.Provider__c);
        System.assertEquals(req.sourceFlowApiName, row.Component__c);
        System.assertEquals(req.sourceElementApiName, row.Endpoint__c);
        System.assert(row.Error__c != null && row.Error__c.contains('Test_Flow'), 'Expected technical detail.');
        System.assert(row.Request__c != null && row.Request__c.contains('ErrorLogId='), 'Expected request body.');
    }

    @IsTest
    static void logFault_screenFlowType_fromScrInName() {
        OnboardingErrorLogInvocable.LogRequest req = new OnboardingErrorLogInvocable.LogRequest();
        req.technicalDetail = 'x';
        req.userMessageBase = 'Screen issue.';
        req.sourceFlowApiName = 'EXP_Opportunity_SCR_Create_Record';
        req.sourceElementApiName = 'Step';

        Test.startTest();
        OnboardingErrorLogInvocable.LogResult res = OnboardingErrorLogInvocable.logFault(
            new List<OnboardingErrorLogInvocable.LogRequest>{ req }
        )[0];
        Test.stopTest();

        System.assertEquals(true, res.insertSucceeded);
        Error_Log__c row = [SELECT Type__c FROM Error_Log__c WHERE Id = :res.errorLogId];
        System.assertEquals('Screen Flow', row.Type__c);
    }

    @IsTest
    static void logFault_bulkTwoRows() {
        List<OnboardingErrorLogInvocable.LogRequest> reqs = new List<OnboardingErrorLogInvocable.LogRequest>();
        for (Integer i = 0; i < 2; i++) {
            OnboardingErrorLogInvocable.LogRequest r = new OnboardingErrorLogInvocable.LogRequest();
            r.technicalDetail = 't' + i;
            r.userMessageBase = 'u' + i;
            r.sourceFlowApiName = 'DOMAIN_Omni_Test';
            r.sourceElementApiName = 'El';
            reqs.add(r);
        }

        Test.startTest();
        List<OnboardingErrorLogInvocable.LogResult> results = OnboardingErrorLogInvocable.logFault(reqs);
        Test.stopTest();

        System.assertEquals(2, results.size());
        System.assertEquals(true, results[0].insertSucceeded);
        System.assertEquals(true, results[1].insertSucceeded);
        System.assertNotEquals(results[0].errorLogId, results[1].errorLogId);
    }

    @IsTest
    static void logFault_setsOnboardingAndOpportunityLookups() {
        Account acc = TestAccountFactory.create('ErrLogOnb', true);
        Opportunity opp = new Opportunity(
            Name = 'Err Log Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Program_Base_App_Selection__c = 'Program Base Application - with Chuzo'
        );
        insert opp;
        TestDataFactoryWrapper.VendorCustomizationWrapper vpw = TestVendorProgramFactory.createVendorWithCustomization(true);
        Onboarding__c onb = new Onboarding__c(
            Account__c = acc.Id,
            Vendor_Customization__c = vpw.customization.Id,
            Onboarding_Status__c = 'Setup Complete',
            Opportunity__c = opp.Id
        );
        insert onb;

        OnboardingErrorLogInvocable.LogRequest req = new OnboardingErrorLogInvocable.LogRequest();
        req.technicalDetail = 'detail';
        req.userMessageBase = 'friendly';
        req.onboardingId = String.valueOf(onb.Id);
        req.opportunityId = String.valueOf(opp.Id);
        req.sourceFlowApiName = 'Custom_Flow';
        req.sourceElementApiName = 'Custom_Element';
        req.errorLogType = 'Integration';
        req.providerSubtypeOverrideText = 'General';

        Test.startTest();
        OnboardingErrorLogInvocable.LogResult res = OnboardingErrorLogInvocable.logFault(
            new List<OnboardingErrorLogInvocable.LogRequest>{ req }
        )[0];
        Test.stopTest();

        System.assertEquals(true, res.insertSucceeded);
        System.assertEquals(true, res.retryQueued, 'Expected onboarding retry capture to queue.');
        System.assertNotEquals(null, res.retryJobId, 'Expected retry job id.');
        Error_Log__c row = [
            SELECT Onboarding__c, Opportunity__c, Type__c, Provider_Subtype__c
            FROM Error_Log__c
            WHERE Id = :res.errorLogId
        ];
        System.assertEquals(onb.Id, row.Onboarding__c);
        System.assertEquals(opp.Id, row.Opportunity__c);
        System.assertEquals('Integration', row.Type__c);
        System.assertEquals('General', row.Provider_Subtype__c);

        Onboarding_Background_Job__c retryJob = [
            SELECT Onboarding__c, Operation_Type__c, Status__c, Last_Error_Log__c
            FROM Onboarding_Background_Job__c
            WHERE Id = :res.retryJobId
            LIMIT 1
        ];
        System.assertEquals(onb.Id, retryJob.Onboarding__c);
        System.assertEquals(
            OnboardingBackgroundRetryService.OP_REPLAY_ONBOARDING_BACKGROUND_CHAIN,
            retryJob.Operation_Type__c
        );
        System.assertEquals(OnboardingBackgroundRetryService.STATUS_PENDING, retryJob.Status__c);
        System.assertEquals(res.errorLogId, String.valueOf(retryJob.Last_Error_Log__c));
    }
}
