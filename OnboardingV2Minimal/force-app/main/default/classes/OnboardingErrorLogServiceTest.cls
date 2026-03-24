@IsTest
private class OnboardingErrorLogServiceTest {
    @IsTest
    static void persistFault_nullInput_doesNotThrow() {
        OnboardingErrorLogService.FaultOutcome outcome = OnboardingErrorLogService.persistFault(null);
        System.assertNotEquals(null, outcome.userFacingMessage);
        if (outcome.insertSucceeded == true) {
            System.assertNotEquals(null, outcome.errorLogId);
            System.assert(outcome.userFacingMessage.contains('Error Log Id:'), outcome.userFacingMessage);
        } else {
            System.assert(
                outcome.userFacingMessage.contains('logging unavailable'),
                outcome.userFacingMessage
            );
        }
    }

    @IsTest
    static void persistFault_invalidPicklistSubtype_doesNotThrow() {
        OnboardingErrorLogService.FaultInput input = new OnboardingErrorLogService.FaultInput();
        input.technicalDetail = 'technical';
        input.userMessageBase = 'user';
        input.sourceFlowApiName = 'Flow_X';
        input.sourceElementApiName = 'El_Y';
        input.providerSubtypeOverrideText = 'INVALID_SUBTYPE_VALUE_XYZ';

        OnboardingErrorLogService.FaultOutcome outcome = OnboardingErrorLogService.persistFault(input);
        System.assertEquals(false, outcome.insertSucceeded);
        System.assert(outcome.userFacingMessage.contains('logging unavailable'), outcome.userFacingMessage);
    }
}
