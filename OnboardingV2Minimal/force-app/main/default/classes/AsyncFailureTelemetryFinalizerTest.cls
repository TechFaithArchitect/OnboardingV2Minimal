@IsTest
private class AsyncFailureTelemetryFinalizerTest {
    @IsTest
    static void buildFailureTelemetryMessage_includesContextAndExceptionSummary() {
        Exception capturedException;
        try {
            Integer value = 1 / 0;
            System.assertEquals(1, value, 'Unreachable.');
        } catch (Exception ex) {
            capturedException = ex;
        }

        String message = AsyncFailureTelemetryFinalizer.buildFailureTelemetryMessage(
            'OperationX',
            (Id) '707000000000000AAA',
            ParentJobResult.UNHANDLED_EXCEPTION,
            capturedException,
            'AccountId=001000000000000AAA'
        );

        System.assert(message.contains('Async queueable failed.'), 'Expected failure prefix.');
        System.assert(message.contains('Operation=OperationX'), 'Expected operation context.');
        System.assert(message.contains('JobId=707000000000000AAA'), 'Expected job id context.');
        System.assert(message.contains('Result=UNHANDLED_EXCEPTION'), 'Expected finalizer result context.');
        System.assert(message.contains('Exception='), 'Expected exception summary context.');
    }

    @IsTest
    static void buildHandledFailureMessage_normalizesBlankValues() {
        String message = AsyncFailureTelemetryFinalizer.buildHandledFailureMessage(
            null,
            null,
            null,
            'Handled failure'
        );

        System.assert(message.contains('Handled failure.'), 'Expected supplied reason.');
        System.assert(message.contains('Operation=UnknownOperation'), 'Expected normalized operation.');
        System.assert(message.contains('Context=none'), 'Expected normalized context.');
        System.assert(message.contains('Exception=None'), 'Expected null exception marker.');
    }

    @IsTest
    static void attachAndHandledFailureLogging_doNotThrow() {
        Test.startTest();
        AsyncFailureTelemetryFinalizer.attach('OperationY', 'ConfigKey=CONTACT_ON_ACCOUNT');
        AsyncFailureTelemetryFinalizer.logHandledFailure(
            'OperationY',
            'ConfigKey=CONTACT_ON_ACCOUNT',
            null,
            'Handled async failure'
        );
        Test.stopTest();

        System.assert(true, 'No exception expected when invoking telemetry helpers.');
    }
}
